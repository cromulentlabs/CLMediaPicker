// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "CLMediaPicker",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CLMediaPicker",
            targets: ["CLMediaPicker"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CLMediaPicker",
            dependencies: [],
            path: "CLMediaPicker",
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit"),
                .linkedFramework("MediaPlayer"),
            ]
        )
    ]
)
