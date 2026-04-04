import SwiftUI

struct SettingsScreen: View {
    @Environment(\.energyManager) var energyManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState

    @State var settings = AppSettings()

    @State private var isLoading = false
    @State private var serverInfo: ServerInfo?
    @State private var showLogoutConfirmation = false

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
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.indigo)
                }

            }
        }
        .onAppear {
            isLoading = true
            Task {
                defer {
                    isLoading = false
                }

                do {
                    serverInfo = try await energyManager.fetchServerInfo()
                } catch {
                    var _ = Alert(
                        title: Text("Connection error"),
                        message: Text(
                            "Something went wrong! Please try again later."
                        )
                    )
                }
            }
        }
    }

    // MARK: - Portrait

    private var portraitContent: some View {
        List {
            appInfoSection

            serverSectionContent

            Section(header: Text("Appearance")) {
                appearanceSectionContent
            }

            Section(header: Text("Integrations")) {
                integrationsSectionContent
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
                Section(header: Text("Appearance")) {
                    appearanceSectionContent
                }

                Section(header: Text("Integrations")) {
                    integrationsSectionContent
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
            serverInfo: serverInfo
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
        .disabled(serverInfo == nil || !(serverInfo?.signal ?? false))
        .listRowBackground(Color.clear)
        .alert(
            "Are you sure to logout?",
            isPresented: $showLogoutConfirmation
        ) {
            Button("Logout", role: .destructive) {
                buildingState.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to sign in again to use Solar Lens.")
        }
    }

    @ViewBuilder
    private var appearanceSectionContent: some View {
        SettingsToggleItem(
            imageName: "sun.max.trianglebadge.exclamationmark",
            text: "Background effects",
            color: .orange,
            isOn: settings.appearanceUseWarmBackgroundWithDefault
        )
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
