// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-rfc-2387",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(
            name: "RFC 2387",
            targets: ["RFC 2387"]
        )
    ],
    dependencies: [
        .package(path: "../../swift-primitives/swift-ascii-serializer-primitives"),
        .package(path: "../swift-rfc-2045"),
        .package(path: "../swift-rfc-2046"),
        .package(path: "../swift-rfc-5322")
    ],
    targets: [
        .target(
            name: "RFC 2387",
            dependencies: [
                .product(name: "ASCII Serializer Primitives", package: "swift-ascii-serializer-primitives"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2046", package: "swift-rfc-2046"),
                .product(name: "RFC 5322", package: "swift-rfc-5322")
    ]
        ),
        .testTarget(
            name: "RFC 2387 Tests",
            dependencies: [
                "RFC 2387",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
