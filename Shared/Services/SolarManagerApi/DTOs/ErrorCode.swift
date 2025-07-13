struct ErrorCode : Codable {
    var errorCode: String?
    var errorDetails: String?
    var errorType: Int?
    var ticket: String?
    var isPushNotificationSent: Bool?
    var createdAt: Int?
    var updatedAt: Int?
    var sensor: String?
    var showInEndUserView: Bool?
    var showInMonitoring: Bool?
    var streamPushNotificationMarker: Bool?
    var deviceActivity: String?
    var errorLabel: String?
    var errorDescription: String?
}
