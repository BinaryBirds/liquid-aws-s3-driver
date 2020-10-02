// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "liquid-aws-s3-driver",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "LiquidAwsS3Driver", targets: ["LiquidAwsS3Driver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/binarybirds/liquid-kit.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.30.0"),
        .package(url: "https://github.com/soto-project/soto.git", from: "5.0.0-beta.1")
    ],
    targets: [
        .target(name: "LiquidAwsS3Driver", dependencies: [
            .product(name: "LiquidKit", package: "liquid-kit"),
            .product(name: "SotoS3", package: "soto"),
        ]),
        .testTarget(name: "LiquidAwsS3DriverTests", dependencies: [
            .target(name: "LiquidAwsS3Driver"),
            .product(name: "Vapor", package: "vapor"),
        ]),
    ]
)
