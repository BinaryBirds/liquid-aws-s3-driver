// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "liquid-s3-driver",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "LiquidS3Driver",
            targets: [
                "LiquidS3Driver"
            ]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/binarybirds/liquid-kit",
            branch: "dev"
        ),
        .package(
            url: "https://github.com/soto-project/soto",
            from: "6.4.0"
        ),
    ],
    targets: [
        .target(
            name: "LiquidS3Driver",
            dependencies: [
                .product(
                    name: "LiquidKit",
                    package: "liquid-kit"
                ),
                .product(
                    name: "SotoS3",
                    package: "soto"
                ),
            ]
        ),
        .testTarget(
            name: "LiquidS3DriverTests",
            dependencies: [
                .target(
                    name: "LiquidS3Driver"
                ),
            ]
        ),
    ]
)
