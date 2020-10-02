# LiquidAwsS3Driver

AWS S3 driver for the Liquid file storage, based on the [Soto for AWS](https://github.com/soto-project/soto) project.


## Usage example

Add dependencies:

```swift
// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "myProject",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.30.0"),
        .package(url: "https://github.com/binarybirds/liquid.git", from: "1.0.0"),
        .package(url: "https://github.com/binarybirds/liquid-aws-s3-driver.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "Liquid", package: "liquid"),
            .product(name: "LiquidAwsS3Driver", package: "liquid-aws-s3-driver"),
        ]),
    ]
)
```

## Configuring credentials

It is possible to configure credentials via multiple methods, by default the driver will try to load the credentials from the shared credential file.

You can read more about the configuration in the AWS SDK Swift [readme](https://github.com/swift-aws/aws-sdk-swift).

To get started with a default shared credential file, place the following values into the `~/.aws/credentials` file.

```ini
[default]
aws_access_key_id = YOUR_AWS_ACCESS_KEY_ID
aws_secret_access_key = YOUR_AWS_SECRET_ACCESS_KEY
```

## Driver configuration

```swift
import Liquid
import LiquidAwsS3Driver

public func configure(_ app: Application) throws {

    app.fileStorages.use(.awsS3(region: .uswest1, bucket: "vaportestbucket"), as: .awsS3)
}
```

## File upload example

```swift

func testUpload(req: Request) -> EventLoopFuture<String> {
    let data: Data! = //...
    let key = "path/to/my/file.txt"
    return req.fs.upload(key: key, data: data)
    // returns the full public url of the uploaded image
}

// resolve public url based on a key
// func resolve(key: String) -> String
req.fs.resolve(key: myImageKey)

// delete file based on a key
// func delete(key: String) -> EventLoopFuture<Void>
req.fs.delete(key: myImageKey)
```


## License

[WTFPL](LICENSE) - Do what the fuck you want to.
