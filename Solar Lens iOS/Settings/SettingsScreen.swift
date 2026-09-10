import SwiftUI

struct SettingsScreen: View {
    @Environment(\.energyManager) var energyManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState

    @State var settings = AppSettings()

    @State private var isLoading = false
    @State private var serverInfo: ServerInfo?
    @State private var serverInfoLoadFailed = false
    @State private var showLogoutConfirmation = false
    @State private var showResetConfirmation = false

    private var isLandscape: Bool { verticalSizeClass == .compact }

    var body: some View {
        Group {
            if isLandscape {
                landscapeContent
            } else {
                portraitContent
            }
        }
        .selectionDisabled()
        .scrollContentBackground(.hidden)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Label("Close", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.indigo)
                }

            }
        }
        .onAppear {
            loadServerInfo()
        }
    }

    /// Load the server info behind a timeout so a hanging request (e.g. a
    /// stale/wrong stored password that never authenticates) surfaces a
    /// retryable failure state instead of spinning the "Solar Manager" tile
    /// forever.
    private func loadServerInfo() {
        isLoading = true
        serverInfoLoadFailed = false
        Task {
            defer {
                isLoading = false
            }

            do {
                serverInfo = try await withFetchTimeout(
                    CurrentBuildingState.fetchTimeoutSeconds
                ) { [energyManager] in
                    try await energyManager.fetchServerInfo()
                }
            } catch {
                serverInfoLoadFailed = true
            }
        }
    }

    // MARK: - Portrait

    private var portraitContent: some View {
        List {
            appInfoSection

            serverSectionContent

            Section(header: Text("Eco impact")) {
                ecoSectionContent
            }

            Section(header: Text("Integrations")) {
                integrationsSectionContent
            }

            Section {
                automationsSectionContent
            } header: {
                Text("Automations")
            } footer: {
                automationsSectionFooter
            }

            Section(header: Text("Appearance")) {
                appearanceSectionContent
            }

            Section(header: Text("Diagnostics")) {
                diagnosticsSectionContent
            }
        }
        .listStyle(.grouped)
    }

    // MARK: - Landscape

    private var landscapeContent: some View {
        HStack(alignment: .top, spacing: 0) {
            List {
                appInfoSection
                serverSectionContent
            }
            .listStyle(.grouped)

            List {
                Section(header: Text("Eco impact")) {
                    ecoSectionContent
                }

                Section(header: Text("Integrations")) {
                    integrationsSectionContent
                }

                Section {
                    automationsSectionContent
                } header: {
                    Text("Automations")
                } footer: {
                    automationsSectionFooter
                }

                Section(header: Text("Appearance")) {
                    appearanceSectionContent
                }

                Section(header: Text("Diagnostics")) {
                    diagnosticsSectionContent
                }
            }
            .listStyle(.grouped)
        }
    }

    // MARK: - Shared Sections

    private var appInfoSection: some View {
        VStack(alignment: .leading) {
            Text(verbatim: "Solar Lens")
                .font(.headline)

            HStack {
                Text(
                    "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")"
                )

                Text(
                    "#\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")"
                )
            }
        }
        .listRowSeparator(.hidden, edges: [.all])
        .padding(.vertical, 0)
    }

    @ViewBuilder
    private var serverSectionContent: some View {
        ConnectionInfoView(
            serverInfo: serverInfo,
            loadFailed: serverInfoLoadFailed,
            onRetry: { loadServerInfo() }
        )
        .listRowSeparator(
            .hidden,
            edges: [.all]
        )

        SettingNavigationItem(
            imageName: "info.circle",
            text: "Server Info",
            color: .blue,
            disabled: serverInfo == nil
        ) {
            ServerInfoView(serverInfo: serverInfo)
        }

        Button {
            showLogoutConfirmation = true
        } label: {
            HStack {
                SettingsItemCaption(
                    imageName: "rectangle.portrait.and.arrow.right",
                    text: "Logout",
                    color: .red
                )
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .alert(
            "Are you sure to logout?",
            isPresented: $showLogoutConfirmation
        ) {
            Button("Logout", role: .destructive) {
                buildingState.logout()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to sign in again to use Solar Lens.")
        }

        Button {
            showResetConfirmation = true
        } label: {
            HStack {
                SettingsItemCaption(
                    imageName: "arrow.counterclockwise",
                    text: "Reset app",
                    color: .red
                )
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .alert(
            "Reset Solar Lens?",
            isPresented: $showResetConfirmation
        ) {
            Button("Reset", role: .destructive) {
                buildingState.resetApp()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This removes your saved login and resets all settings to their defaults. Use this if the app is stuck and you need to sign in again."
            )
        }
    }

    @ViewBuilder
    /// Which grid the CO₂ and tree figures are credited against. Lives here
    /// as well as behind the tree explanation, because someone who already
    /// knows their grid should not have to find the explanation first.
    private var ecoSectionContent: some View {
        SettingNavigationItem(
            imageName: "leaf.fill",
            text: "Grid region",
            color: .green
        ) {
            GridCarbonRegionPicker()
        }
    }

    private var appearanceSectionContent: some View {
        SettingsToggleItem(
            imageName: "sun.max.trianglebadge.exclamationmark",
            text: "Background effects",
            color: .orange,
            isOn: settings.appearanceUseWarmBackgroundWithDefault
        )
    }

    @ViewBuilder
    private var automationsSectionContent: some View {
        SettingsToggleItem(
            imageName: "clock.badge.checkmark",
            text: "Server-assisted timing",
            color: .blue,
            isOn: serverAssistedTimingBinding
        )

    }

    /// `SettingsItemCaption` is a bare icon plus a `Text` with no container —
    /// fine inside a row's HStack, but dropped straight into a List it became
    /// two rows, and the icon read as a broken menu item of its own. This is
    /// what it was always meant to be: the section's footnote.
    private var automationsSectionFooter: some View {
        Text(
            "Lets Solar Lens run automations with a fixed end time exactly on time, even when the app is closed. Only a notification token and the end time are sent to the Solar Lens server — never your Solar Manager login, your devices or any measurements."
        )
    }

    /// Wraps the stored setting so turning it off also removes whatever this
    /// device has registered on the server, instead of leaving rows behind
    /// that would keep pushing.
    private var serverAssistedTimingBinding: Binding<Bool> {
        Binding<Bool>(
            get: { settings.serverAssistedTimingWithDefault.wrappedValue },
            set: { newValue in
                settings.serverAssistedTimingWithDefault.wrappedValue = newValue
                if newValue {
                    PushRegistrar.registerIfAuthorized()
                    AutomationManager.shared.resyncWakeSchedule()
                    // `resyncWakeSchedule` only covers automations. A device
                    // whose only reason for a window is a notification monitor
                    // would otherwise stay unregistered until the next tick.
                    WakeWindowCoordinator.shared.refresh(force: true)
                } else {
                    // Drop the local record first: `forgetDevice` clears the
                    // server, and a coordinator still believing it is
                    // registered would decline to register again.
                    WakeWindowCoordinator.shared.invalidate()
                    Task { await WakeScheduleClient.forgetDevice() }
                }
            }
        )
    }

    @ViewBuilder
    private var diagnosticsSectionContent: some View {
        SettingNavigationItem(
            imageName: "applewatch.radiowaves.left.and.right",
            text: "Activity log from Watch",
            color: .gray,
            disabled: false
        ) {
            WatchLogsView()
        }
    }

    @ViewBuilder
    private var integrationsSectionContent: some View {
        SettingNavigationItem(
            imageName: "microphone.fill",
            text: "Siri",
            color: .yellow,
            disabled: serverInfo == nil
        ) {
            SiriInfoView()
        }

        SettingNavigationItem(
            imageName: "flowchart.fill",
            text: "Shortcuts for automation",
            color: .yellow,
            disabled: serverInfo == nil
        ) {
            ShortcutsView()
        }
    }
}

#Preview {
    SettingsScreen()
        .environment(CurrentBuildingState.fake())
}
