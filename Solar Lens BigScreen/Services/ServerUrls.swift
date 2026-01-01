class ServerUrls {

    static let shared = ServerUrls()

    func getImageDownloadApiBaseUrl() -> String {
        #if DEBUG
            "http://localhost:7071/api"
        #else
            "https://solarlens-upload-func.azurewebsites.net/api"
        #endif
    }

    func getImageUploadWebBaseUrl() -> String {
        #if DEBUG
            "https://localhost:8000"
        #else
            "https://gentle-glacier-018c0d203.2.azurestaticapps.net"
        #endif
    }
}
