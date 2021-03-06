# LiquidAwsS3Driver

AWS S3 driver implementation for the [LiquidKit](https://github.com/BinaryBirds/liquid-kit) file storage solution, based on the [Soto for AWS](https://github.com/soto-project/soto) project.

LiquidKit and the AWS S3 driver is also compatible with Vapor 4 through the [Liquid](https://github.com/BinaryBirds/liquid) repository, that contains Vapor specific extensions.


## Key resolution for S3 objects

Keys are being resolved using a the bucket and the region name, with the standard AWS structure:

- url = "https://" + [bucket name] + ".s3-" + [region name] + "amazonaws.com/" + [key]

Alternatively you can use a custom endpoint. In that case the endpoint will be extended with the bucket name and key.

- url = [custom endpoint] + [bucket name] + [key]


e.g. 

- bucketName = "testbucket"
- regionName = "us-west-1"
- key = "test.txt"

- resolvedUrl = "https://testbucket.s3-us-west-1.amazonaws.com/test.txt"


## Credentials

It is possible to configure credentials via multiple methods, by default the driver will try to load the credentials from the shared credential file.

You can read more about the configuration in the AWS SDK Swift [readme](https://github.com/swift-aws/aws-sdk-swift).

To get started with a default shared credential file, place the following values into the `~/.aws/credentials` file.

```ini
[default]
aws_access_key_id = YOUR_AWS_ACCESS_KEY_ID
aws_secret_access_key = YOUR_AWS_SECRET_ACCESS_KEY
```


## Usage with SwiftNIO


Add the required dependencies using SPM:

```swift
// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "myProject",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/binarybirds/liquid", from: "1.2.0"),
        .package(url: "https://github.com/binarybirds/liquid-aws-s3-driver", from: "1.2.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Liquid", package: "liquid"),
            .product(name: "LiquidAwsS3Driver", package: "liquid-aws-s3-driver"),
        ]),
    ]
)
```

A basic usage example with SwiftNIO:

```swift
/// setup thread pool
let elg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let pool = NIOThreadPool(numberOfThreads: 1)
pool.start()

/// create fs  
let fileio = NonBlockingFileIO(threadPool: pool)
let storages = FileStorages(fileio: fileio)
storages.use(.awsS3(region: .uswest1, bucket: "testbucket"), as: .awsS3)
let fs = storages.fileStorage(.awsS3, logger: .init(label: "[test-logger]"), on: elg.next())!

/// test file upload
let key = "test.txt"
let data = Data("file storage test".utf8)
let res = try fs.upload(key: key, data: data).wait()

/// https://testbucket.s3-us-west-1.amazonaws.com/test.txt
let url = req.fs.resolve(key: key)

/// delete key
try req.fs.delete(key: key).wait()

```
