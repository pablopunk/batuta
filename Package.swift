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
    targets: [
        .executableTarget(
            name: "Batuta",
            path: "Sources"
        ),
        .testTarget(
            name: "BatutaTests",
            dependencies: ["Batuta"],
            path: "Tests/BatutaTests"
        )
    ]
)
