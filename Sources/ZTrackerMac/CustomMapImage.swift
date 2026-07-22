import Foundation
import ImageIO
import CoreGraphics

/// Loads a user-imported custom overworld map image (T-167), memoized per path.
///
/// The map is drawn as a single image stretched across the whole 16×8 grid rather than
/// pre-sliced into 128 screen crops: slicing required the source to be an exact multiple
/// of 16×8 NES screens, and any other resolution truncated and drifted. Stretching maps
/// screen N onto cell N for any input.
@MainActor
enum CustomMapImage {
    private static var cache: [String: CGImage?] = [:]

    /// The full image at `path` (memoized; nil if it can't be read/decoded).
    static func full(_ path: String) -> CGImage? {
        if let hit = cache[path] { return hit }
        let img: CGImage? = {
            let url = URL(fileURLWithPath: path)
            guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
            return cg
        }()
        cache[path] = img
        return img
    }

    /// Drop a path's cached image (e.g. after re-importing a different map).
    static func invalidate(_ path: String) { cache[path] = nil }
}
