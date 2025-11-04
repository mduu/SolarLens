import SwiftUI

actor SolarManager: EnergyManager {
    private static var _instance: SolarManager? = nil
    static func instance() -> SolarManager {
        if _instance == nil {
            _instance = SolarManager()
        }

        return _instance!
    }

    @MainActor private var expireAt: Date?
    @MainActor private var accessClaims: [String]?
    @MainActor private var solarManagerApi = SolarManagerApi()
    @MainActor private var systemInformation: V1User?
    @MainActor private var sensorInfos: [SensorInfosV1Response]?
    @MainActor private var sensorInfosUpdatedAt: Date?

    func login(username: String, password: String) async -> Bool {
        return await doLogin(email: username, password: password)
    }

    @MainActor
    func fetchOverviewData(lastOverviewData: OverviewData?) async throws
        -> OverviewData
    {
        try await ensureSensorInfosAreCurrent()

        guard let systemInformation else {
            return lastOverviewData ?? OverviewData.empty()
        }

        if let chart = try await solarManagerApi.getV1Chart(
            solarManagerId: systemInformation.sm_id
        ) {
            let batteryChargingRate =
                chart.battery != nil
                ? chart.battery!.batteryCharging
                    - chart.battery!.batteryDischarging
                : nil

            let lastUpdated = parseSolarManagerDateTime(chart.lastUpdate)

            let streamSensorInfos =
                try await solarManagerApi.getV1StreamGateway(
                    solarManagerId: systemInformation.sm_id
                )

            let todayGatewayStatistics =
                try await solarManagerApi.getV1Statistics(
                    solarManagerId: systemInformation.sm_id,
                    from: Date.todayStartOfDay(),
                    to: Date.todayEndOfDay(),
                    accuracy: .high
                )

            let isAnyCarCharing = getIsAnyCarCharing(
                streamSensors: streamSensorInfos
            )

            return OverviewData.init(
                currentSolarProduction: chart.production,
                currentOverallConsumption: chart.consumption,
                currentBatteryLevel: chart.battery?.capacity ?? 0,
                currentBatteryChargeRate: batteryChargingRate,
                currentSolarToGrid: chart
                    .arrows?.first(
                        where: { $0.direction == .fromPVToGrid }
                    )?.value ?? 0,
                currentGridToHouse: chart
                    .arrows?.first(
                        where: { $0.direction == .fromGridToConsumer }
                    )?.value ?? 0,
                currentSolarToHouse: chart
                    .arrows?.first(
                        where: { $0.direction == .fromPVToConsumer }
                    )?.value ?? 0,
                solarProductionMax: (systemInformation.kWp ?? 0.0) * 1000,
                hasConnectionError: false,
                lastUpdated: lastUpdated,
                lastSuccessServerFetch: Date(),
                isAnyCarCharing: isAnyCarCharing,
                chargingStations: sensorInfos == nil
                    ? []
                    : sensorInfos!
                        .filter { $0.isCarCharging() }
                        .map {
                            let streamInfo = streamSensorInfos?.deviceById(
                                $0._id
                            )

                            return ChargingStation.init(
                                id: $0._id,
                                name: $0.getSensorName(),
                                chargingMode: streamInfo?.currentMode
                                    ?? ChargingMode.off,
                                priority: $0.priority,
                                currentPower: streamInfo?.currentPower ?? 0,
                                signal: $0.signal
                            )
                        },
                devices: sensorInfos == nil
                    ? []
                    : sensorInfos!
                        .filter { sensorInfo in sensorInfo.isDevice() }
                        .map { sensorInfo in
                            let id = sensorInfo._id
                            let streamInfo = streamSensorInfos?.devices.first {
                                streamInfo in
                                streamInfo._id == id
                            }

                            return mapDevice(sensorInfo, streamInfo)
                        },
                todaySelfConsumption: todayGatewayStatistics?.selfConsumption,
                todaySelfConsumptionRate: todayGatewayStatistics?
                    .selfConsumptionRate,
                todayAutarchyDegree: todayGatewayStatistics?.autarchyDegree,
                todayProduction: todayGatewayStatistics?.production,
                todayConsumption: todayGatewayStatistics?.consumption,
                todayGridImported: nil,
                todayGridExported: nil,
                cars: mapCars(streamSensorInfos: streamSensorInfos)
            )
        }

        let errorOverviewData =
            lastOverviewData
            ?? OverviewData.empty()

        errorOverviewData.hasConnectionError = true

        return errorOverviewData
    }

    @MainActor
    func fetchChargingData() async throws -> CharingInfoData {
        try await ensureLoggedIn()
        try await ensureSmId()
        try await ensureSensorInfosAreCurrent()

        let chargingStationSensorIds = getCharingStationSensorIds()
        var total: Double? = nil

        // Get todays charing amount from all charging stations
        for chargingStationSensorId in chargingStationSensorIds {
            let chargingStationSensorData =
                try? await solarManagerApi.getV1ConsumptionSensor(
                    sensorId: chargingStationSensorId
                )

            if chargingStationSensorData != nil {
                total =
                    (total ?? 0) + chargingStationSensorData!.totalConsumption
            }
        }

        // Get current charging power
        let overviewData = try? await fetchOverviewData(lastOverviewData: nil)

        var current: Int? = nil
        if overviewData != nil {
            current = overviewData!.chargingStations
                .map { station in station.currentPower }
                .reduce(0, +)
        }

        print(
            "Got charging data: 24h: \(String(describing: total)), current: \(String(describing: current))"
        )

        return .init(totalCharedToday: total, currentCharging: current)
    }

    @MainActor
    func fetchSolarDetails() async throws -> SolarDetailsData {
        try await ensureSmId()

        async let todayStatisticsResult = solarManagerApi.getV1Statistics(
            solarManagerId: systemInformation!.sm_id,
            from: Date.todayStartOfDay(),
            to: Date.todayEndOfDay(),
            accuracy: .high
        )

        async let forecastResult = solarManagerApi.getV3ForecastGateway(
            solarManagerId: systemInformation!.sm_id
        )

        let todayStatistics = try? await todayStatisticsResult
        let forecast: ForecastV3Response? = try? await forecastResult

        let dailyForecast = getCumSumPerLocalStartOfDay(
            data: forecast?.data ?? []
        )

        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        let tomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: now)!
        )
        let afterTomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 2, to: now)!
        )

        let todaysData =
            dailyForecast[today] ?? ForecastItem(min: 0, max: 0, expected: 0)
        let tomorrowData =
            dailyForecast[tomorrow] ?? ForecastItem(min: 0, max: 0, expected: 0)
        let afterTomorrowData =
            dailyForecast[afterTomorrow]
            ?? ForecastItem(min: 0, max: 0, expected: 0)

        return SolarDetailsData(
            todaySolarProduction: todayStatistics?.production,
            forecastToday: todaysData,
            forecastTomorrow: tomorrowData,
            forecastDayAfterTomorrow: afterTomorrowData
        )

    }

    @MainActor
    func fetchMainData(from: Date, to: Date, interval: Int = 300) async throws -> MainData {
        try await ensureSmId()

        print("Fetching gateway consumptions&productions ...")

        let mainData = try await solarManagerApi.getV3UserDataRange(
            solarManagerId: systemInformation!.sm_id,
            from: from,
            to: to,
            interval: interval
        )

        print("Fetched gateway consumptions&productions.")

        return MainData(
            data: mainData?.data
                .map {
                    MainDataItem.init(
                        date: RestDateHelper.date(from: $0.t) ?? Date(),
                        consumptionWatts: Int($0.cW),
                        productionWatts: Int($0.pW),
                        batteryLevel: $0.soc
                    )
                }
                ?? []
        )
    }

    @MainActor
    func fetchTodaysBatteryHistory() async throws -> [BatteryHistory] {
        try await ensureSensorInfosAreCurrent()

        guard let sensorInfos = self.sensorInfos else {
            return []
        }

        let batterySensorIds =
            sensorInfos
            .filter { $0.isBattery() }
            .map { $0._id }

        guard !batterySensorIds.isEmpty else {
            return []
        }

        let todayStart = Date.todayStartOfDay()
        let todayEnd = Date.todayEndOfDay()

        var result: [BatteryHistory] = []  // Array to hold the results
        for batterySensorId in batterySensorIds {
            let data = try await solarManagerApi.getV1SensorData(
                sensor: batterySensorId,
                from: todayStart,
                to: todayEnd
            )

            let items =
                data?.map { sensorData in
                    BatteryHistoryItem(
                        date: RestDateHelper.date(from: sensorData.date)
                            ?? Date(),
                        energyDischargedWh: sensorData.bdWh ?? 0,
                        energyChargedWh: sensorData.bcWh ?? 0,
                        averagePowerDischargedW: sensorData.bdW ?? 0,
                        averagePowerChargedW: sensorData.bcW ?? 0
                    )
                } ?? []

            let batteryHistory = BatteryHistory(
                batterySensorId: batterySensorId,
                items: items
            )

            result.append(batteryHistory)
        }

        return result
    }

    @MainActor
    func fetchServerInfo() async throws -> ServerInfo {
        try await ensureSystemInfomation()

        guard let systemInformation = systemInformation else {
            throw EnergyManagerClientError.systemInformationNotFound
        }

        return ServerInfo(
            status: systemInformation.status,
            language: systemInformation.language,
            lastname: systemInformation.last_name,
            firstname: systemInformation.first_name,
            email: systemInformation.email,
            country: systemInformation.country,
            license: systemInformation.license,
            city: systemInformation.city,
            street: systemInformation.street,
            zip: systemInformation.zip,
            kWp: systemInformation.kWp,
            energyAssistantEnable: systemInformation.energy_assistant_enable,
            userId: systemInformation.user_id,
            registrationDate: parseSolarManagerDateTime(
                systemInformation.registration_date
            ),
            deviceCount: systemInformation.device_count,
            carCount: systemInformation.car_count,
            smId: systemInformation.sm_id,
            gatewayId: systemInformation.gateway_id,
            installationFinished: systemInformation.installation_finished,
            hardwareVersion: systemInformation.hardware_version,
            softwareVersion: systemInformation.firmware_version,
            signal: systemInformation.signal == "connected",
            installer: systemInformation.installer
        )
    }

    func fetchEnergyOverview() async throws -> EnergyOverview {
        try await ensureSystemInfomation()

        let response = try? await solarManagerApi.getV1Overview()
        guard let response else {
            return await EnergyOverview()
        }

        return EnergyOverview(
            loaded: true,
            plants: response.plants,
            supportContracts: response.supportContracts,
            production: EnergyProduction(
                today: response.production?.today,
                last7Days: response.production?.last7Days,
                thisMonth: response.production?.thisMonth,
                thisYear: response.production?.thisYear
            ),
            consumption: EnergyConsumption(
                today: response.consumption?.today,
                last7Days: response.consumption?.last7Days,
                thisMonth: response.consumption?.thisMonth,
                thisYear: response.consumption?.thisYear,
                lastMonth: response.consumption?.lastMonth,
                lastYear: response.consumption?.lastYear,
                overall: response.consumption?.overall
            ),
            autarchy: EnergyAutarchy(
                last24hr: response.autarchy?.last24hr ?? 0,
                lastMonth: response.autarchy?.lastMonth ?? 0,
                lastYear: response.autarchy?.lastYear ?? 0,
                overall: response.autarchy?.overall ?? 0
            ),
            totalEnergy: EnergyTotalEnergy(
                carChargers: EnergyCarChargers(
                    total: response.totalEnergy?.carChargers?.total ?? 0,
                    today: response.totalEnergy?.carChargers?.today ?? 0,
                    last7Days: response.totalEnergy?.carChargers?.last7Days ?? 0
                ),
                waterHeaters: EnergyWaterHeaters(
                    total: response.totalEnergy?.waterHeaters?.total ?? 0,
                    today: response.totalEnergy?.waterHeaters?.today ?? 0,
                    last7Days: response.totalEnergy?.waterHeaters?.last7Days ?? 0
                ),
                heatpumps: EnergyHeadpumps(
                    total: response.totalEnergy?.heatpumps?.total ?? 0,
                    today: response.totalEnergy?.heatpumps?.today ?? 0,
                    last7Days: response.totalEnergy?.heatpumps?.last7Days ?? 0
                ),
                v2xChargers: EnergyV2xChargers(
                    total: response.totalEnergy?.v2xChargers?.total ?? 0,
                    charged: EnergyChargingInfo(
                        today: response.totalEnergy?.v2xChargers?.charged.today ?? 0,
                        last7Days: response.totalEnergy?.v2xChargers?.charged.last7Days ?? 0
                    ),
                    discharged: EnergyChargingInfo(
                        today: response.totalEnergy?.v2xChargers?.discharged.today ?? 0,
                        last7Days: response.totalEnergy?.v2xChargers?.discharged.last7Days ?? 0
                    )
                )
            )
        )
    }

    @MainActor
    func fetchStatisticsOverview() async throws -> StatisticsOverview {
        try await ensureSystemInfomation()

        let now = Date()
        let calendar = Calendar.current

        async let last7Days = fetchStatistics(
            from: calendar.date(byAdding: .day, value: -7, to: now)!,
            to: Date(),
            accuracy: .medium
        )

        async let last30Days = fetchStatistics(
            from: calendar.date(byAdding: .month, value: -1, to: now)!,
            to: Date(),
            accuracy: .medium
        )

        async let last365Days = fetchStatistics(
            from: calendar.date(byAdding: .year, value: -1, to: now)!,
            to: Date(),
            accuracy: .low
        )

        async let overallStatsTask = fetchStatistics(
            from: systemInformation!.registrationDate,
            to: Date(),
            accuracy: .high
        )

        return StatisticsOverview(
            week: (try? await last7Days) ?? Statistics(),
            month: (try? await last30Days) ?? Statistics(),
            year: (try? await last365Days) ?? Statistics(),
            overall: (try? await overallStatsTask) ?? Statistics()
        )
    }

    @MainActor
    func fetchStatistics(from: Date, to: Date, accuracy: Accuracy) async throws -> Statistics {
        try await ensureSmId()

        let result = try? await solarManagerApi.getV1Statistics(
            solarManagerId: systemInformation!.sm_id,
            from: from,
            to: to,
            accuracy: accuracy
        )

        guard let result else {
            return Statistics()
        }

        return Statistics(
            consumption: result.consumption,
            production: result.production,
            selfConsumption: result.selfConsumption,
            selfConsumptionRate: result.selfConsumptionRate,
            autarchyDegree: result.autarchyDegree
        )
    }

    func setCarChargingMode(
        sensorId: String,
        carCharging: ControlCarChargingRequest
    ) async throws
        -> Bool
    {
        try await ensureSensorInfosAreCurrent()

        do {
            try await solarManagerApi.putControlCarCharger(
                sensorId: sensorId,
                control: carCharging
            )
            return true
        } catch {
            return false
        }
    }

    @MainActor
    func setSensorPriority(
        sensorId: String,
        priority: Int
    ) async throws -> Bool {
        try await ensureLoggedIn()
        try await ensureSmId()
        try await ensureSensorInfosAreCurrent()

        do {
            try await solarManagerApi.putConfigurationSensorPriority(
                sensorId: sensorId,
                priority: .init(priority: priority)
            )
            return true
        } catch {
            return false
        }
    }

    @MainActor
    func setBatteryMode(
        sensorId: String,
        batteryModeInfo: BatteryModeInfo
    ) async throws -> Bool {
        try await ensureLoggedIn()
        try await ensureSmId()
        try await ensureSensorInfosAreCurrent()

        let controlBody = ControlBatteryV2Request(
            batteryMode: batteryModeInfo.batteryMode.rawValue,
            batteryManualMode: batteryModeInfo.batteryManualMode.rawValue,
            upperSocLimit: batteryModeInfo.upperSocLimit,
            lowerSocLimit: batteryModeInfo.lowerSocLimit,
            powerCharge: batteryModeInfo.powerCharge,
            powerDischarge: batteryModeInfo.powerDischarge,
            dischargeSocLimit: batteryModeInfo.dischargeSocLimit,
            chargingSocLimit: batteryModeInfo.chargingSocLimit,
            morningSocLimit: batteryModeInfo.morningSocLimit,
            peakShavingSocDischargeLimit: batteryModeInfo.peakShavingSocDischargeLimit,
            peakShavingSocMaxLimit: batteryModeInfo.peakShavingSocMaxLimit,
            peakShavingMaxGridPower: batteryModeInfo.peakShavingMaxGridPower,
            peakShavingRechargePower: batteryModeInfo.peakShavingRechargePower,
            tariffPriceLimit: batteryModeInfo.tariffPriceLimit,
            tariffPriceLimitSocMax: batteryModeInfo.tariffPriceLimitSocMax,
            tariffPriceLimitForecast: batteryModeInfo.tariffPriceLimitForecast,
            standardStandaloneAllowed: batteryModeInfo.standardStandaloneAllowed,
            standardLowerSocLimit: batteryModeInfo.standardLowerSocLimit,
            standardUpperSocLimit: batteryModeInfo.standardUpperSocLimit,
        )

        do {
            try await solarManagerApi.putControlBattery(
                sensorId: sensorId,
                control: controlBody
            )

            return true
        } catch {
            return false
        }
    }

    @MainActor
    private func ensureLoggedIn() async throws {
        let accessToken = KeychainHelper.accessToken
        let refreshToken = KeychainHelper.refreshToken

        if accessToken != nil && expireAt != nil && expireAt! > Date() {
            return
        }

        if let refreshToken = refreshToken {
            print("Refresh token exists. Refreshing access-token...")

            do {
                let refreshResponse = try await solarManagerApi.refresh(
                    refreshToken: refreshToken
                )

                self.expireAt =
                    refreshResponse.expiresIn > 0
                    ? Date().addingTimeInterval(
                        TimeInterval(refreshResponse.expiresIn)
                    )
                    : Date().addingTimeInterval(86400)

                self.accessClaims = refreshResponse.accessClaims

                if expireAt != nil && expireAt! > Date() {
                    print(
                        "Refresh auth-token succeeded. Token will expire at \(expireAt!)"
                    )

                    return
                }

                print("Refresh access-token succeeded.")
            } catch {
                print(
                    "Refresh access-token failed. Will performan a regular login."
                )
            }
        }

        let credentials = KeychainHelper.loadCredentials()
        if (credentials.username?.isEmpty ?? true)
            || (credentials.password?.isEmpty ?? true)
        {
            print("No credentials found!")
            throw EnergyManagerClientError.loginFailed
        }

        print("Performe login")

        let loginSuccess = await doLogin(
            email: credentials.username!,
            password: credentials.password!
        )

        if !loginSuccess {
            throw EnergyManagerClientError.loginFailed
        }
    }

    @MainActor
    private func ensureSmId() async throws {
        try await ensureSystemInfomation()
    }

    @MainActor
    private func ensureSystemInfomation() async throws {
        if self.systemInformation != nil {
            return
        }

        print("Requesting System Information ...")

        try await ensureLoggedIn()

        let users = try await solarManagerApi.getV1Users()
        let firstUser = users?.first
        if firstUser == nil {
            throw EnergyManagerClientError.systemInformationNotFound
        }

        self.systemInformation = firstUser
        print(
            "System Informaton loaded. SMID: \(self.systemInformation?.sm_id ?? "<NONE>")"
        )
    }

    @MainActor
    private func ensureSensorInfosAreCurrent() async throws {
        try await ensureLoggedIn()
        try await ensureSmId()

        if sensorInfos != nil && sensorInfosUpdatedAt != nil
            && Date.now < sensorInfosUpdatedAt!.addingTimeInterval(60)
        {
            print("Reuse existing sensor infos")
            return
        }

        sensorInfos = try await solarManagerApi.getV1InfoSensors(
            solarManagerId: systemInformation!.sm_id
        )
    }

    @MainActor
    private func getIsAnyCarCharing(streamSensors: StreamSensorsV1Response?)
        -> Bool
    {
        guard streamSensors != nil else { return false }
        guard sensorInfos != nil else { return false }

        let chargingSensorIds = getCharingStationSensorIds()

        let charingPower = streamSensors!.devices
            .filter { chargingSensorIds.contains($0._id) }
            .map { $0.currentPower ?? 0 }
            .reduce(0, +)

        return charingPower > 0
    }

    @MainActor
    private func getCharingStationSensorIds() -> [String] {
        return
            sensorInfos != nil
            ? sensorInfos!
                .filter { $0.isCarCharging() }
                .map { $0._id }
            : []
    }

    @MainActor
    private func mapDevice(
        _ sensorInfo: SensorInfosV1Response,
        _ streamInfo: StreamSensorsV1Device?
    ) -> Device {
        return Device.init(
            id: sensorInfo._id,
            deviceType: Device.mapStringToDeviceType(
                stringValue: sensorInfo.type
            ),
            name: sensorInfo.getSensorName(),

            priority: sensorInfo.priority,
            currentPowerInWatts: streamInfo?.currentPower ?? 0,
            color: sensorInfo.tag?.color,
            signal: sensorInfo.signal,
            hasError: sensorInfo.hasErrors(),
            batteryInfo: sensorInfo.isBattery()
                ? mapBatteryInfo(battery: sensorInfo.data)
                : nil
        )
    }

    @MainActor
    private func mapBatteryInfo(battery: SensorInfosV1Data?) -> BatteryInfo? {
        guard let battery = battery else {
            return nil
        }

        return BatteryInfo(
            favorite: battery.favorite ?? false,
            maxDischargePower: battery.maxDischargePower
                ?? 1000,
            maxChargePower: battery.maxChargePower ?? 1000,
            batteryCapacityKwh: battery.batteryCapacity ?? 5,
            modeInfo: BatteryModeInfo(
                batteryChargingMode:
                    BatteryChargingMode
                    .from(battery.batteryChargingMode),
                batteryMode:
                    BatteryMode
                    .from(battery.batteryMode),
                batteryManualMode:
                    BatteryManualMode
                    .from(battery.batteryManualMode ?? 0),

                // Manual
                upperSocLimit: battery.upperSocLimit ?? 95,
                lowerSocLimit: battery.lowerSocLimit ?? 15,

                // Eco
                dischargeSocLimit: battery.dischargeSocLimit ?? 30,
                chargingSocLimit: battery.chargingSocLimit ?? 100,
                morningSocLimit: battery.morningSocLimit ?? 80,

                // Peak shaving
                peakShavingSocDischargeLimit: battery
                    .peakShavingSocDischargeLimit
                    ?? 10,
                peakShavingSocMaxLimit: battery.peakShavingSocMaxLimit ?? 40,
                peakShavingMaxGridPower: battery.peakShavingMaxGridPower ?? 0,
                peakShavingRechargePower: battery.peakShavingRechargePower ?? 0,

                // Tariff optimized
                tariffPriceLimitSocMax: battery.tariffPriceLimitSocMax ?? 0,
                tariffPriceLimit: battery.tariffPriceLimit ?? 0,
                tariffPriceLimitForecast: battery.tariffPriceLimitForecast
                    ?? false,

                // Standard
                standardStandaloneAllowed: battery.standardStandaloneAllowed
                    ?? false,
                standardLowerSocLimit: battery.standardLowerSocLimit ?? 10,
                standardUpperSocLimit: battery.standardUpperSocLimit ?? 90,

                powerCharge: battery.powerCharge ?? 0,
                powerDischarge: battery.powerDischarge ?? 0
            )
        )
    }

    @MainActor
    private func mapCars(streamSensorInfos: StreamSensorsV1Response?) -> [Car] {
        guard let sensorInfos = sensorInfos else {
            return []
        }

        let localIsoDateFormatter = ISO8601DateFormatter()
        localIsoDateFormatter.timeZone = TimeZone.current
        localIsoDateFormatter.formatOptions = [
            .withFullDate,
            .withTime,
            .withDashSeparatorInDate,
            .withColonSeparatorInTime,
        ]

        return
            sensorInfos
            .filter { (sensor: SensorInfosV1Response) -> Bool in sensor.isCar()
            }
            .map { sensorInfo -> Car in
                let streamInfo = streamSensorInfos?.deviceById(sensorInfo._id)
                let dateString: String = streamInfo?.lastUpdate ?? ""
                let lastUpdate =
                    streamInfo?.lastUpdate != nil
                    ? localIsoDateFormatter.date(from: dateString)
                    : nil

                return Car.init(
                    id: sensorInfo._id,
                    name: sensorInfo.getSensorName(),
                    priority: sensorInfo.priority,
                    batteryPercent: sensorInfo.soc,
                    batteryCapacity: sensorInfo.data?.batteryCapacity,
                    remainingDistance: streamInfo?.remainingDistance,
                    lastUpdate: lastUpdate,
                    signal: sensorInfo.signal,
                    currentPowerInWatts: streamInfo?.currentPower
                        ?? 0,
                    hasError: sensorInfo.hasErrors()
                )
            }
    }

    @MainActor
    private func doLogin(email: String, password: String) async -> Bool {
        do {
            let loginSuccess = try await solarManagerApi.login(
                email: email,
                password: password
            )

            KeychainHelper
                .saveCredentials(username: email, password: password)

            self.expireAt = Date().addingTimeInterval(
                TimeInterval(loginSuccess.expiresIn)
            )
            self.systemInformation = nil

            print("Login succeeded. Token will expire at \(expireAt!)")

            return true
        } catch {
            print("Login failed!")
            return false
        }
    }

    @MainActor
    private func getCumSumPerLocalStartOfDay(data: [ForecastItemV3Response])
        -> [Date: ForecastItem?]
    {
        var dailyKWh: [Date: ForecastItem] = [:]
        let calendar = Calendar.current

        for solarData in data {
            guard let timeStamp = solarData.timeStamp else {
                continue
            }
            let startOfDay = calendar.startOfDay(for: timeStamp)

            // Accumulate energy consumption for the day
            var forecast = dailyKWh[startOfDay]

            let minKWh = solarData.pWmin / 1000 / 4
            let maxKWh = solarData.pWmax / 1000 / 4
            let expectedKWh = solarData.pW / 1000 / 4

            if forecast == nil {
                forecast = ForecastItem(
                    min: minKWh,
                    max: maxKWh,
                    expected: expectedKWh
                )
            } else {
                forecast = ForecastItem(
                    min: forecast!.min + minKWh,
                    max: forecast!.max + maxKWh,
                    expected: forecast!.expected + expectedKWh
                )
            }

            dailyKWh[startOfDay] = forecast
        }

        return dailyKWh
    }

    @MainActor
    func parseSolarManagerDateTime(_ solarManagerDateTime: String?) -> Date? {
        guard let dateTime = solarManagerDateTime else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")  // Ensures the formatter correctly interprets the 'Z' as UTC.
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)  // Explicitly set to UTC if 'Z' should be treated as UTC, which is common.

        return dateFormatter.date(from: dateTime)
    }

}
