import CarPlay

/// Scene delegate for the CarPlay scene. Declared in `Solar-Lens-Info.plist`
/// under the `CPTemplateApplicationSceneSessionRoleApplication` role.
///
/// The SwiftUI `App` lifecycle keeps managing the phone's window scene; this
/// delegate only handles the separate CarPlay scene and forwards its lifecycle
/// to the shared `CarPlayManager`.
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        CarPlayManager.shared.connect(interfaceController)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        CarPlayManager.shared.disconnect()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        CarPlayManager.shared.sceneDidBecomeActive()
    }
}
