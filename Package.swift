// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "KeySwitch",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "KeySwitchCore"),
        .executableTarget(
            name: "KeySwitch",
            dependencies: ["KeySwitchCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "KeySwitchCoreTests",
            dependencies: ["KeySwitchCore"],
            exclude: ["Fixtures"]
        ),
    ]
)
