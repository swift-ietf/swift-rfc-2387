// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-2387",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
    ],
    products: [
        .library(
            name: "RFC 2387",
            targets: ["RFC 2387"]
        ),
        .library(
            name: "RFC 2387 Foundation Integration",
            targets: ["RFC 2387 Foundation Integration"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-byte.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-2045.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-2046.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-5322.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "RFC 2387",
            dependencies: [
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2046", package: "swift-rfc-2046"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
            ]
        ),
        .target(
            name: "RFC 2387 Foundation Integration",
            dependencies: [
                .target(name: "RFC 2387"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(
                    name: "RFC 2045 Foundation Integration",
                    package: "swift-rfc-2045"
                ),
                .product(name: "RFC 2046", package: "swift-rfc-2046"),
                .product(
                    name: "RFC 2046 Foundation Integration",
                    package: "swift-rfc-2046"
                ),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
                .product(
                    name: "RFC 5322 Foundation Integration",
                    package: "swift-rfc-5322"
                ),
            ]
        ),
        .testTarget(
            name: "RFC 2387 Tests",
            dependencies: [
                .target(name: "RFC 2387"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2046", package: "swift-rfc-2046"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
            ]
        ),
        .testTarget(
            name: "RFC 2387 Foundation Integration Tests",
            dependencies: [
                .target(name: "RFC 2387"),
                .target(name: "RFC 2387 Foundation Integration"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2046", package: "swift-rfc-2046"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
