import Combine
import Foundation

class SolarManagerApi: RestClient {

    private let apiBaseUrl: String = "https://cloud.solar-manager.ch"

    init() {
        super.init(baseUrl: apiBaseUrl)
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        do {
            if let loginResponse: LoginResponse? = try await post(
                serviceUrl: "/v1/oauth/login",
                requestBody: LoginRequest(email: email, password: password),
                useAccessToken: false
            ) {
                storeLogin(
                    accessToken: loginResponse!.accessToken,
                    refreshToken: loginResponse!.refreshToken
                )

                return loginResponse!
            }

            throw SolarManagerApiClientError.communicationError

        } catch {
            clearLogin()

            print(
                "Login failed! Error: \(error). Email: \(email), Passwort: \(password)"
            )
            throw SolarManagerApiClientError.communicationError
        }
    }

    func refresh(refreshToken: String) async throws -> RefreshResponse {
        do {
            if let refreshResponse: RefreshResponse? = try await post(
                serviceUrl: "/v1/oauth/refresh",
                requestBody: RefreshRequest(refreshToken: refreshToken),
                useAccessToken: false
            ) {
                storeLogin(
                    accessToken: refreshResponse!.accessToken,
                    refreshToken: refreshResponse!.refreshToken
                )

                return refreshResponse!
            }

            throw SolarManagerApiClientError.communicationError

        } catch {
            clearLogin()

            print(
                "Refresh failed! Error: \(error)"
            )
            throw SolarManagerApiClientError.communicationError
        }
    }

    func getV1Chart(solarManagerId smId: String) async throws
        -> GetV1ChartResponse?
    {
        let response: GetV1ChartResponse? = try await get(
            serviceUrl: "/v1/chart/gateway/\(smId)"
        )

        return response
    }

    func getV1Users() async throws -> [V1User]? {
        let response: [V1User]? = try await get(
            serviceUrl: "/v1/users"
        )

        return response
    }

    func getV1Overview() async throws -> OverviewV1Response? {
        let response: OverviewV1Response? = try await get(
            serviceUrl: "/v1/overview"
        )

        return response
    }

    func getV1InfoSensors(solarManagerId smId: String) async throws
        -> [SensorInfosV1Response]?
    {
        let response: [SensorInfosV1Response]? = try await get(
            serviceUrl: "/v1/info/sensors/\(smId)"
        )

        return response
    }

    func getV1InfoGateway(solarManagerId smId: String) async throws
    -> GetV1InfoGatewayResponse?
    {
        let response: GetV1InfoGatewayResponse? = try await get(
            serviceUrl: "/v1/info/gateway/\(smId)"
        )
        
        return response
    }

    func getV3UserTariffs(solarManagerId smId: String) async throws
    -> TariffSettingsResponseArray?
    {
        let response: TariffSettingsResponseArray? = try await get(
            serviceUrl: "/v1/users/\(smId)/tariffs"
        )

        return response
    }

    func getV1StreamGateway(solarManagerId smId: String) async throws
        -> StreamSensorsV1Response?
    {
        let response: StreamSensorsV1Response? = try await get(
            serviceUrl: "/v1/stream/gateway/\(smId)"
        )

        return response
    }

    func getV1ConsumptionSensor(sensorId: String, period: Period = .day)
        async throws -> SensorConsumptionV1Response?
    {
        let response: SensorConsumptionV1Response? = try await get(
            serviceUrl: "/v1/consumption/sensor/\(sensorId)?period=\(period)"
        )

        return response
    }

    func getV1Statistics(
        solarManagerId smId: String,
        from: Date,
        to: Date,
        accuracy: Accuracy
    ) async throws -> StatisticsV1Response? {
        let fromIso = RestDateHelper.string(from: from)
        let toIso = RestDateHelper.string(from: to)

        let response: StatisticsV1Response? = try await get(
            serviceUrl:
                "/v1/statistics/gateways/\(smId)?from=\(fromIso)&to=\(toIso)&accuracy=\(accuracy)"
        )

        return response
    }

    func getV3ForecastGateway(solarManagerId smId: String) async throws
        -> ForecastV3Response?
    {
        let response: ForecastV3Response? = try await get(
            serviceUrl: "/v3/users/\(smId)/data/forecast"
        )

        return response
    }

    func getV1GatewayConsumption(
        solarManagerId smId: String,
        from: Date,
        to: Date
    ) async throws
        -> GatewayIntervalConsumption?
    {
        let fromIso = RestDateHelper.string(from: from)
        let toIso = RestDateHelper.string(from: to)

        let response: GatewayIntervalConsumption? = try await get(
            serviceUrl:
                "/v1/consumption/gateway/\(smId)/range?from=\(fromIso)&to=\(toIso)&interval=300"
        )

        return response
    }

    func getV1SensorData(
        sensor id: String,
        from: Date,
        to: Date,
        interval: Int = 300
    ) async throws -> [SensorDataV1Response]? {
        let fromIso = RestDateHelper.string(from: from)
        let toIso = RestDateHelper.string(from: to)

        let response: [SensorDataV1Response]? = try await get(
            serviceUrl:
                "/v1/data/sensor/\(id)/range?from=\(fromIso)&to=\(toIso)&interval=\(interval)"
        )

        return response
    }

    func putControlCarCharger(
        sensorId: String,
        control: ControlCarChargingRequest
    ) async throws {
        var _: NoContentResponse? = try await put(
            serviceUrl: "/v1/control/car-charger/\(sensorId)",
            requestBody: control
        )

        return
    }

    func putConfigurationSensorPriority(
        sensorId: String,
        priority: PutSensorPriorityRequest
    ) async throws {
        var _: NoContentResponse? = try await put(
            serviceUrl: "/v1/configure/sensor-priority/\(sensorId)",
            requestBody: priority
        )

        return
    }

    func putControlBattery(sensorId: String, control: ControlBatteryV2Request)
        async throws
    {
        var _: NoContentResponse? = try await put(
            serviceUrl: "/v2/control/battery/\(sensorId)",
            requestBody: control
        )

        return
    }

    private func storeLogin(accessToken: String, refreshToken: String) {
        KeychainHelper.accessToken = accessToken
        KeychainHelper.refreshToken = refreshToken
    }

    private func clearLogin() {
        KeychainHelper.accessToken = nil
        KeychainHelper.refreshToken = nil
    }
}
