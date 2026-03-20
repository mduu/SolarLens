internal import Foundation
import SwiftUI

class PinnedDevicesConfiguration: ObservableObject {
    @AppStorage("pinnedDeviceIds") private var pinnedDeviceIdsData: Data?

    @Published var pinnedDeviceIds: Set<String> = []

    init() {
        decodeData()
    }

    func isPinned(deviceId: String) -> Bool {
        pinnedDeviceIds.contains(deviceId)
    }

    func togglePin(deviceId: String) {
        if pinnedDeviceIds.contains(deviceId) {
            pinnedDeviceIds.remove(deviceId)
        } else {
            pinnedDeviceIds.insert(deviceId)
        }
        persist()
    }

    private func persist() {
        if let encodedData = try? JSONEncoder().encode(pinnedDeviceIds) {
            pinnedDeviceIdsData = encodedData
        }
    }

    private func decodeData() {
        if let data = pinnedDeviceIdsData,
            let decodedData = try? JSONDecoder().decode(Set<String>.self, from: data)
        {
            pinnedDeviceIds = decodedData
        }
    }
}
