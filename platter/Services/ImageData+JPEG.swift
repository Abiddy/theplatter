import UIKit

extension UIImage {
    func jpegDataForUpload(maxBytes: Int = 1_500_000) -> Data? {
        var compression: CGFloat = 0.85
        guard var data = jpegData(compressionQuality: compression) else { return nil }

        while data.count > maxBytes, compression > 0.2 {
            compression -= 0.1
            guard let smaller = jpegData(compressionQuality: compression) else { break }
            data = smaller
        }
        return data
    }
}
