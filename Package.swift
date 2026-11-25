// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Batuta",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Batuta", targets: ["Batuta"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.10.1")
    ],
    targets: [
        .executableTarget(
            name: "Batuta",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "BatutaTests",
            dependencies: ["Batuta"],
            path: "Tests/BatutaTests"
        )
    ]
)
