import BackgroundTasks
import Foundation

class ScenarionRegistry {
    public static func registerScenarioTasks() {
        ScenarioBatteryToCar().register()
    }
}
