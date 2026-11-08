// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "xfetch",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "xfetch",
            targets: ["xfetch"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "xfetch",
            dependencies: [],
            path: "Sources/App"
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["xfetch"],
            path: "Tests/AppTests"
        )
    ]
)
