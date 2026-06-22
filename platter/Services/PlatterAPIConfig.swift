import Foundation

enum PlatterAPIConfig {
    /// Production API on Railway. For local dev, swap to http://127.0.0.1:8000 (simulator)
    /// or http://<your-mac-ip>:8000 (device on same Wi‑Fi).
    private static let productionBaseURL = "https://theplatter-production.up.railway.app"

    static var baseURL: URL {
        URL(string: productionBaseURL)!
    }

    /// When false, the app uses on-device mock parse + local optimizer.
    static let useBackend = true

    static let fallbackToLocalOnError = false
}
