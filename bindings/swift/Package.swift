// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TabletBindings",
    platforms: [.iOS("26.0")],
    products: [
        .library(name: "TabletBindings", targets: ["TabletBindings"]),
    ],
    targets: [
        .binaryTarget(name: "TabletFFI", path: "TabletFFI.xcframework"),
        .target(
            name: "TabletBindings",
            dependencies: ["TabletFFI"],
            path: "Sources/TabletBindings"
        ),
    ],
    swiftLanguageModes: [.v6]
)
