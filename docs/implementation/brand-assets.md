# Supplied Mogul artwork

The user supplied these logo files for use in the native app. Originals are bundled unchanged in the root Xcode target’s `Mogul Club/Assets.xcassets`:

- `MogulLogoLight`: Desktop `0x0.png`, black horizontal wordmark on white.
- `MogulLogoDark`: Desktop `twitter-image.png`, white horizontal wordmark on black.
- `MogulProfile`: Desktop `download.jpg`, stacked logo on ivory.

`MogulLogo` crops surrounding canvas in SwiftUI without changing the source artwork or stretching its proportions, selects the appropriate artwork for system appearance, and exposes a Mogul accessibility label. Welcome and Discover share this component. Account displays the square artwork beside the explicit Demo guest label.

The light source is only 400 × 300 pixels; a vector or higher-resolution original would improve sharpness on high-density displays. This update covers in-app branding; the launcher AppIcon and broader screen redesign remain separate work.
