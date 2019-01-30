// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "createTOC",
    products: [.library(name: "MarathonDependencies", type: .dynamic, targets: ["createTOC"])],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Files.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "createTOC",
            dependencies: ["CreateTOCCore"]),
        .target(
            name: "CreateTOCCore",
            dependencies: ["Files"]),
        .testTarget(
            name: "createTOCTests",
            dependencies: ["createTOC"]),
        ],
    swiftLanguageVersions: [.version("4.1")]
)
