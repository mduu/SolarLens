import CarPlay
import UIKit

/// Builds and drives the CarPlay UI for Solar Lens.
///
/// CarPlay is strictly template-based — there is no SwiftUI rendering — so this
/// manager translates the shared `CurrentBuildingState` / `OverviewData` model
/// into CarPlay templates. It owns its own `CurrentBuildingState` instance which
/// talks to the same `SolarManager.shared` session (and therefore the same
/// Keychain credentials) as the phone app, so no separate login is required.
///
/// Data auto-refreshes on a timer while the scene is connected (the driver
/// never taps "refresh"); user actions (mode switch, priority move) update the
/// affected template in place so the selected tab is never disturbed.
@MainActor
final class CarPlayManager {
    static let shared = CarPlayManager()

    /// How often the CarPlay UI re-pulls data while connected.
    private static let autoRefreshInterval: TimeInterval = 15

    private var interfaceController: CPInterfaceController?
    private let buildingState = CurrentBuildingState(
        energyManagerClient: SolarManager.shared
    )

    private var tabBarTemplate: CPTabBarTemplate?
    private var overviewTemplate: CPInformationTemplate?
    private var chargingTemplate: CPListTemplate?
    private var devicesTemplate: CPListTemplate?
    private var refreshTimer: Timer?

    private init() {}

    // MARK: - Scene lifecycle

    func connect(_ interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController

        if buildingState.loginCredentialsExists {
            interfaceController.setRootTemplate(
                makeTabBar(), animated: false, completion: nil
            )
            startAutoRefresh()
            Task { await refresh() }
        } else {
            interfaceController.setRootTemplate(
                makeLoggedOutTemplate(), animated: false, completion: nil
            )
        }
    }

    func disconnect() {
        stopAutoRefresh()
        interfaceController = nil
        tabBarTemplate = nil
        overviewTemplate = nil
        chargingTemplate = nil
        devicesTemplate = nil
    }

    /// Called when the CarPlay scene becomes active again — re-pull data so the
    /// numbers reflect anything that changed while we were backgrounded.
    func sceneDidBecomeActive() {
        guard interfaceController != nil else { return }

        // The user may have logged in on the phone since we showed the
        // logged-out screen — swap to the real UI if so.
        buildingState.checkForCredentions()
        if buildingState.loginCredentialsExists, tabBarTemplate == nil {
            interfaceController?.setRootTemplate(
                makeTabBar(), animated: false, completion: nil
            )
            startAutoRefresh()
        }

        Task { await refresh() }
    }

    // MARK: - Data

    private func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: Self.autoRefreshInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
    }

    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    /// Re-fetch and update every tab in place.
    ///
    /// The tab bar is first built from the seeded cache (so CarPlay has a root
    /// promptly), which can be stale. Each tab then updates in place as fresh
    /// data arrives — the charging list flags the active mode with a checkmark
    /// rather than by row order, so an in-place section update is enough and the
    /// selected tab is never disturbed (no jarring reset back to the Energy tab).
    private func refresh() async {
        guard buildingState.loginCredentialsExists else { return }
        await buildingState.fetchServerData(force: true)
        await buildingState.fetchSolarDetails()

        overviewTemplate?.items = overviewItems()
        chargingTemplate?.updateSections(chargingSections())
        devicesTemplate?.updateSections(deviceSections())
    }

    // MARK: - Root

    private func makeTabBar() -> CPTabBarTemplate {
        let overview = makeOverviewTemplate()

        // Each tab keeps its label via `tabTitle`, but the on-screen nav-bar
        // `title` is left empty so the name doesn't appear twice (once in the
        // tab bar, once as a redundant header above the content).
        let charging = CPListTemplate(title: "", sections: chargingSections())
        charging.tabTitle = String(localized: "Charging")
        charging.tabImage = UIImage(systemName: "ev.charger")
        chargingTemplate = charging

        let devices = CPListTemplate(title: "", sections: deviceSections())
        devices.tabTitle = String(localized: "Priorities")
        devices.tabImage = UIImage(systemName: "arrow.up.arrow.down")
        devicesTemplate = devices

        let tabBar = CPTabBarTemplate(templates: [overview, charging, devices])
        tabBarTemplate = tabBar
        return tabBar
    }

    private func makeLoggedOutTemplate() -> CPListTemplate {
        let item = CPListItem(
            text: String(localized: "Please log in on your iPhone"),
            detailText: String(
                localized: "Open Solar Lens on your phone and sign in to use CarPlay."
            )
        )
        return CPListTemplate(
            title: String(localized: "Solar Lens"),
            sections: [CPListSection(items: [item])]
        )
    }

    // MARK: - Overview screen

    /// Compact two-column read-out of the current values. `CPInformationTemplate`
    /// packs label/value pairs far denser than a row-per-value list and has no
    /// per-row icons. No "refresh" action — the data auto-refreshes on a timer.
    private func makeOverviewTemplate() -> CPInformationTemplate {
        let template = CPInformationTemplate(
            title: "",
            layout: .twoColumn,
            items: overviewItems(),
            actions: []
        )
        template.tabTitle = String(localized: "Energy")
        template.tabImage = UIImage(systemName: "bolt.fill")
        overviewTemplate = template
        return template
    }

    private func overviewItems() -> [CPInformationItem] {
        let data = buildingState.overviewData

        var items: [CPInformationItem] = [
            CPInformationItem(
                title: String(localized: "Solar"),
                detail: data.currentSolarProduction
                    .formatWattsAsKiloWatts(widthUnit: true)
            ),
            CPInformationItem(
                title: String(localized: "Consumption"),
                detail: data.currentOverallConsumption
                    .formatWattsAsKiloWatts(widthUnit: true)
            ),
            CPInformationItem(
                title: String(localized: "Grid"),
                detail: gridDetail(data)
            ),
        ]

        if let level = data.currentBatteryLevel {
            items.append(
                CPInformationItem(
                    title: String(localized: "Battery"),
                    detail: batteryDetail(level: level, rate: data.currentBatteryChargeRate)
                )
            )
        }

        // Solar forecast, one labelled row per day (today / tomorrow / day
        // after) so the values are self-explanatory — the previous single
        // "0.1 / 58.3 kWh" slash line was hard to parse.
        let solar = buildingState.solarDetailsData
        let forecasts: [(LocalizedStringResource, Double?)] = [
            ("Today", solar?.forecastToday?.expected),
            ("Tomorrow", solar?.forecastTomorrow?.expected),
            ("Day after tomorrow", solar?.forecastDayAfterTomorrow?.expected),
        ]
        for (title, expected) in forecasts {
            guard let expected else { continue }
            items.append(
                CPInformationItem(
                    title: String(localized: title),
                    detail: String(format: "%.1f kWh", expected)
                )
            )
        }

        return items
    }

    private func gridDetail(_ data: OverviewData) -> String {
        if data.isFlowGridToHouse() {
            return String(
                localized: "Import \(data.currentGridToHouse.formatWattsAsKiloWatts(widthUnit: true))"
            )
        }
        if data.isFlowSolarToGrid() {
            return String(
                localized: "Export \(data.currentSolarToGrid.formatWattsAsKiloWatts(widthUnit: true))"
            )
        }
        return "–"
    }

    /// Single-line battery read-out, e.g. `86% ↓1.2 kW` (↑ charging, ↓
    /// discharging). Kept terse so it never wraps onto a second row.
    private func batteryDetail(level: Int, rate: Int?) -> String {
        guard let rate, abs(rate) >= 100 else { return "\(level)%" }
        let arrow = rate > 0 ? "↑" : "↓"
        return "\(level)% \(arrow)\(abs(rate).formatWattsAsKiloWatts(widthUnit: true))"
    }

    // MARK: - Charging screen

    private func chargingSections() -> [CPListSection] {
        let stations = buildingState.overviewData.chargingStations

        guard !stations.isEmpty else {
            let empty = CPListItem(
                text: String(localized: "No charging stations"),
                detailText: nil
            )
            return [CPListSection(items: [empty])]
        }

        // Single station: skip the station-selection level and show the modes
        // directly, exactly as the backlog asks for.
        if stations.count == 1, let station = stations.first {
            return modeSections(for: station)
        }

        let items = stations.map { station -> CPListItem in
            let item = CPListItem(
                text: station.name,
                detailText: String(localized: station.chargingMode.localizedTitleLong)
            )
            item.accessoryType = .disclosureIndicator
            item.handler = { [weak self] _, completion in
                self?.pushModeList(for: station)
                completion()
            }
            return item
        }
        return [CPListSection(items: items)]
    }

    private func pushModeList(for station: ChargingStation) {
        let template = CPListTemplate(
            title: station.name,
            sections: modeSections(for: station)
        )
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    /// Lists the simple charging modes (those needing no extra configuration)
    /// in a **fixed canonical order**, with the active mode flagged by a
    /// trailing checkmark (and named in the section header). Marking the
    /// selection explicitly — rather than sorting the active mode to the top —
    /// keeps the right row flagged even before the first data refresh and means
    /// the list never visibly re-sorts when fresh data arrives.
    ///
    /// Full mode names are used (`localizedTitleLong`) since a CarPlay row has
    /// the whole width available; the short `localizedTitle` would needlessly
    /// abbreviate (e.g. "Solar & Tarifopt."). No leading icons: CarPlay renders
    /// list-item images as flat monochrome glyphs (black on the dashboard), so
    /// we use a name + description layout instead.
    ///
    /// Modes that require extra parameters (constant current, minimum quantity,
    /// target SoC) are intentionally omitted — CarPlay templates can't host
    /// that configuration; a non-simple current mode is still named in the
    /// header.
    private func modeSections(for station: ChargingStation) -> [CPListSection] {
        let current = station.chargingMode
        let simple = ChargingMode.allCases.filter { $0.isSimpleChargingMode() }

        let items = simple.map { mode -> CPListItem in
            let item = CPListItem(
                text: String(localized: mode.localizedTitleLong),
                detailText: chargingModeDescription(mode),
                image: nil,
                accessoryImage: mode == current
                    ? UIImage(systemName: "checkmark")
                    : nil,
                accessoryType: .none
            )
            item.handler = { [weak self] _, completion in
                self?.selectMode(mode, for: station)
                completion()
            }
            return item
        }

        // No "Current: …" header — the checkmark already marks the active mode.
        return [CPListSection(items: items)]
    }

    private func selectMode(_ mode: ChargingMode, for station: ChargingStation) {
        // Optimistic UI first — mirror iOS/watchOS so the new mode shows as
        // selected instantly instead of after the network round-trip. Update
        // the charging tab in place (no tab-bar reset).
        let isMultiStation = buildingState.overviewData.chargingStations.count > 1
        buildingState.applyOptimisticChargingMode(sensorId: station.id, mode: mode)
        chargingTemplate?.updateSections(chargingSections())
        if isMultiStation {
            interfaceController?.popTemplate(animated: true, completion: nil)
        }

        // Then push the change to the backend; reconcile when it returns.
        Task {
            await buildingState.setCarCharging(
                sensorId: station.id,
                newCarCharging: ControlCarChargingRequest(chargingMode: mode)
            )
            chargingTemplate?.updateSections(chargingSections())
        }
    }

    /// One-line description shown as each mode's subtitle. Only the simple
    /// modes are ever listed, so the others fall through to an empty string.
    private func chargingModeDescription(_ mode: ChargingMode) -> String {
        switch mode {
        case .withSolarPower: return String(localized: "Charge from solar surplus only")
        case .withSolarOrLowTariff: return String(localized: "Solar surplus or low tariff")
        case .alwaysCharge: return String(localized: "Charge at full power")
        case .minimalAndSolar: return String(localized: "Minimum charge, then solar")
        case .off: return String(localized: "Do not charge")
        default: return ""
        }
    }

    // MARK: - Device priorities screen

    private func deviceSections() -> [CPListSection] {
        let devices = buildingState.overviewData.devices
            .sorted(by: { $0.priority < $1.priority })

        guard !devices.isEmpty else {
            let empty = CPListItem(
                text: String(localized: "No devices"),
                detailText: nil
            )
            return [CPListSection(items: [empty])]
        }

        // One action per row, mirroring the watchOS DeviceRow: the top device
        // moves *down*, every other device moves *up*. A CPListItem has only a
        // single (whole-row) tap and can't host a separate button, but that
        // matches watchOS's one-button-per-row model exactly — so the row tap
        // *is* the move, with a trailing arrow showing the direction. No sheet
        // or drill-down needed.
        let lastIndex = devices.count - 1
        let items = devices.enumerated().map { index, device -> CPListItem in
            let movesDown = index == 0
            let target = movesDown ? min(index + 1, lastIndex) : index - 1
            let item = CPListItem(
                text: device.name,
                detailText: String(localized: "Priority \(index + 1)"),
                image: nil,
                accessoryImage: UIImage(
                    systemName: movesDown ? "arrow.down.circle" : "arrow.up.circle"
                ),
                accessoryType: .none
            )
            item.handler = { [weak self] _, completion in
                Task {
                    await self?.moveDevice(device, to: target)
                    completion()
                }
            }
            return item
        }

        // No header — the arrows already convey the per-row action, and the
        // list is self-evidently ordered by priority.
        return [CPListSection(items: items)]
    }

    /// Moves `device` to `targetIndex` in the priority order and reassigns a
    /// clean 1…N permutation — the same model the iOS `DevicePrioritySheet`
    /// uses for drag-to-reorder. A no-op when the device is already there (e.g.
    /// a single-device list). Updates the devices tab in place.
    private func moveDevice(_ device: Device, to targetIndex: Int) async {
        var ordered = buildingState.overviewData.devices
            .sorted(by: { $0.priority < $1.priority })
        guard let index = ordered.firstIndex(where: { $0.id == device.id }),
            ordered.indices.contains(targetIndex),
            index != targetIndex
        else { return }

        let moved = ordered.remove(at: index)
        ordered.insert(moved, at: targetIndex)

        let updates: [(sensorId: String, priority: Int)] =
            ordered.enumerated().compactMap { idx, dev in
                let newPriority = idx + 1
                return dev.priority == newPriority
                    ? nil
                    : (sensorId: dev.id, priority: newPriority)
            }

        await buildingState.setSensorPriorities(updates)
        devicesTemplate?.updateSections(deviceSections())
    }

}
