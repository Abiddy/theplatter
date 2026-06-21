import Foundation

enum PlatterAPIConfig {
    /// Your Mac's LAN IP — run `ipconfig getifaddr en0` if this changes.
    private static let macLANIP = "10.0.0.15"

    static var baseURL: URL {
        #if targetEnvironment(simulator)
        URL(string: "http://127.0.0.1:8000")!
        #else
        URL(string: "http://\(macLANIP):8000")!
        #endif
    }

    /// When false, the app uses on-device mock parse + local optimizer.
    static let useBackend = true

    static let fallbackToLocalOnError = false
}
