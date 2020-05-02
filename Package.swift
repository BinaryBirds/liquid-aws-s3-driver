// swift-tools-version:5.2
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
        .package(url: "https://github.com/swift-aws/aws-sdk-swift.git", from: "5.0.0-alpha"),
    ],
    targets: [
        .target(name: "LiquidAwsS3Driver", dependencies: [
            .product(name: "LiquidKit", package: "liquid-kit"),
            .product(name: "AWSS3", package: "aws-sdk-swift"),
        ]),
        .testTarget(name: "LiquidAwsS3DriverTests", dependencies: ["LiquidAwsS3Driver"]),
    ]
)
