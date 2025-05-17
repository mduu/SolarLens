import SwiftUI

actor SolarManager: EnergyManager {
    private static var _instance: SolarManager? = nil
    static func instance() -> SolarManager {
        if _instance == nil {
            _instance = SolarManager()
        }

        return _instance!
    }

    private var expireAt: Date?
    private var accessClaims: [String]?
    private var solarManagerApi = SolarManagerApi()
    private var systemInformation: V1User?
    private var sensorInfos: [SensorInfosV1Response]?
    private var sensorInfosUpdatedAt: Date?

    func login(username: String, password: String) async -> Bool {
        return await doLogin(email: username, password: password)
    }

    func fetchOverviewData(lastOverviewData: OverviewData?) async throws
        -> OverviewData
    {
        try await ensureSensorInfosAreCurrent()

        guard systemInformation != nil else {
            return lastOverviewData ?? OverviewData.empty()
        }

        async let streamSensorInfosResult =
            try await solarManagerApi.getV1StreamGateway(
                solarManagerId: systemInformation!.sm_id
            )

        async let todayGatewayStatisticsResult =
            try await solarManagerApi.getV1Statistics(
                solarManagerId: systemInformation!.sm_id,
                from: Date.todayStartOfDay(),
                to: Date.todayEndOfDay(),
                accuracy: .high
            )

        if let chart = try await solarManagerApi.getV1Chart(
            solarManagerId: systemInformation!.sm_id
        ) {
            let batteryChargingRate =
                chart.battery != nil
                ? chart.battery!.batteryCharging
                    - chart.battery!.batteryDischarging
                : nil

            let lastUpdated = parseSolarManagerDateTime(chart.lastUpdate)
            let streamSensorInfos = try await streamSensorInfosResult
            let todayGatewayStatistics = try await todayGatewayStatisticsResult
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
                solarProductionMax: (systemInformation?.kWp ?? 0.0) * 1000,
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
                        .filter { $0.isDevice() }
                        .map {
                            let id = $0._id
                            let streamInfo = streamSensorInfos?.devices.first {
                                $0._id == id
                            }

                            return Device.init(
                                id: $0._id,
                                deviceType: Device.mapStringToDeviceType(
                                    stringValue: $0.type
                                ),
                                name: $0.getSensorName(),

                                priority: $0.priority,
                                currentPowerInWatts: streamInfo?.currentPower
                                    ?? 0,
                                color: $0.tag?.color,
                                signal: $0.signal,
                                hasError: $0.hasErrors()
                            )
                        },
                todaySelfConsumption: todayGatewayStatistics?.selfConsumption,
                todaySelfConsumptionRate: todayGatewayStatistics?
                    .selfConsumptionRate,
                todayAutarchyDegree: todayGatewayStatistics?.autarchyDegree,
                todayProduction: todayGatewayStatistics?.production,
                todayConsumption: todayGatewayStatistics?.consumption,
                todayGridImported: nil,
                todayGridExported: nil,
                cars: mapChars(streamSensorInfos: streamSensorInfos)
            )
        }

        let errorOverviewData =
            lastOverviewData
            ?? OverviewData.empty()

        errorOverviewData.hasConnectionError = true

        return errorOverviewData
    }

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

    func fetchSolarDetails() async throws -> SolarDetailsData {
        try await ensureSmId()

        async let todayStatisticsResult = solarManagerApi.getV1Statistics(
            solarManagerId: systemInformation!.sm_id,
            from: Date.todayStartOfDay(),
            to: Date.todayEndOfDay(),
            accuracy: .high
        )

        async let forecastResult = solarManagerApi.getV1ForecastGateway(
            solarManagerId: systemInformation!.sm_id
        )

        let todayStatistics = try? await todayStatisticsResult
        let forecast = (try? await forecastResult) ?? []

        let dailyForecast = getCumSumPerLocalStartOfDay(data: forecast)

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

    func fetchConsumptions(from: Date, to: Date) async throws -> ConsumptionData
    {
        try await ensureSmId()

        print("Fetching gateway consumptions&productions ...")

        let consumptions = try await solarManagerApi.getV1GatewayConsumption(
            solarManagerId: systemInformation!.sm_id,
            from: from,
            to: to
        )

        print("Fetched gateway consumptions&productions.")

        return ConsumptionData(
            from: RestDateHelper.date(from: consumptions?.from),
            to: RestDateHelper.date(from: consumptions?.to),
            interval: consumptions?.interval ?? 300,
            data: consumptions?.data
                .map {
                    ConsumptionItem.init(
                        date: RestDateHelper.date(from: $0.date) ?? Date(),
                        consumptionWatts: $0.cW,
                        productionWatts: $0.pW
                    )
                }
                ?? []
        )
    }

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

    func setCarChargingMode(
        sensorId: String,
        carCharging: ControlCarChargingRequest
    ) async throws
        -> Bool
    {
        try await ensureLoggedIn()
        try await ensureSmId()
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

                self.expireAt = Date().addingTimeInterval(
                    TimeInterval(refreshResponse.expiresIn)
                )
                self.accessClaims = refreshResponse.accessClaims

                if accessToken != nil && expireAt != nil && expireAt! > Date() {
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

    private func ensureSmId() async throws {
        try await ensureLoggedIn()
        try await ensureSystemInfomation()
    }

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

    private func getCharingStationSensorIds() -> [String] {
        return
            sensorInfos != nil
            ? sensorInfos!
                .filter { $0.isCarCharging() }
                .map { $0._id }
            : []
    }

    private func mapChars(streamSensorInfos: StreamSensorsV1Response?) -> [Car]
    {
        guard let sensorInfos = sensorInfos else {
            return []
        }

        return
            sensorInfos
            .filter { (sensor: SensorInfosV1Response) -> Bool in sensor.isCar()
            }
            .map { sensorInfo -> Car in
                let streamInfo = streamSensorInfos?.deviceById(sensorInfo._id)

                return Car.init(
                    id: sensorInfo._id,
                    name: sensorInfo.getSensorName(),
                    priority: sensorInfo.priority,
                    batteryPercent: sensorInfo.soc,
                    batteryCapacity: sensorInfo.data?.batteryCapacity,
                    signal: sensorInfo.signal,
                    currentPowerInWatts: streamInfo?.currentPower
                        ?? 0,
                    hasError: sensorInfo.hasErrors()
                )
            }
    }

    private func doLogin(email: String, password: String) async -> Bool {
        do {
            let loginSuccess = try await solarManagerApi.login(
                email: email,
                password: password
            )

            KeychainHelper.saveCredentials(username: email, password: password)
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

    private func getCumSumPerLocalStartOfDay(data: [ForecastItemV1Response])
        -> [Date: ForecastItem?]
    {
        var dailyKWh: [Date: ForecastItem] = [:]
        let calendar = Calendar.current

        for solarData in data {
            let date = Date(timeIntervalSince1970: solarData.timestamp / 1000)
            let startOfDay = calendar.startOfDay(for: date)

            // Accumulate energy consumption for the day
            var forecast = dailyKWh[startOfDay]

            let minKWh = solarData.min / 1000 / 4
            let maxKWh = solarData.max / 1000 / 4
            let expectedKWh = solarData.expected / 1000 / 4

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
