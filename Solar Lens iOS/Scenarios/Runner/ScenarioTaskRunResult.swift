public struct ScenarioTaskRunResult {
    let nextRunAfter: Date?
    let newStatus: ScenarioTaskStatus
    let newState: any ScenarioTaskState
}
