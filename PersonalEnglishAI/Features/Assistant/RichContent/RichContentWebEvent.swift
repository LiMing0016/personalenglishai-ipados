import Foundation
import CoreGraphics

enum RichContentWebEvent: Equatable {
    case heightChanged(CGFloat)
    case linkTapped(URL)
    case copyRequested(String)
    case graphFullscreenRequested(String)
    case renderError(String)
}
