# LiquidS3Driver

S3 driver implementation for the [LiquidKit](https://github.com/BinaryBirds/liquid-kit) file storage solution, based on the [Soto for AWS](https://github.com/soto-project/soto) project.

## S3 driver compatible object storages

- [AWS](https://aws.amazon.com/s3/)
- [MinIO](https://min.io/product/overview)
- [Scaleway](https://www.scaleway.com/en/object-storage/)
- [LocalStack](https://docs.localstack.cloud/user-guide/aws/s3/)

## Key resolution for S3 objects

Keys are being resolved using the [standard AWS structure](https://docs.aws.amazon.com/general/latest/gr/s3.html), if no custom endpoint is provided:

- for the useast1 region: "https:// + [bucketName] + ".s3.amazonaws.com"
- other regions: "https://" + [bucket name] + ".s3-" + [region name] + "amazonaws.com/" + [key]

For custom public endpoints, the url is going to be resolved the following way:

- url = [custom public endpoint] + [key]

example: 

- bucketName = "testbucket"
- regionName = "us-west-1"
- key = "test.txt"
- no custom endpoint

- resolvedUrl: "https://testbucket.s3-us-west-1.amazonaws.com/test.txt"


## Credentials

It is possible to configure credentials via multiple methods, by default the driver will try to load the credentials from the shared credential file.

You can read more about the configuration in the AWS SDK Swift [readme](https://github.com/swift-aws/aws-sdk-swift).

To get started with a default shared credential file, place the following values into the `~/.aws/credentials` file.

```ini
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET
```

## Usage with SwiftNIO

Add the required dependencies using SPM:

```swift
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "myProject",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        .package(
            url: "https://github.com/binarybirds/liquid-s3-driver", 
            from: "2.0.0"
        ),
    ],
    targets: [
        .target(
            name: "App", 
            dependencies: [
                .product(
                    name: "LiquidS3Driver", 
                    package: "liquid-aws-s3-driver"
                ),
            ]
        ),
    ]
)
```

A basic usage example with SwiftNIO only:

```swift
import LiquidKit
import Logging
import NIO
import LiquidS3Driver

let logger = Logger(label: "test-logger")
let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let pool = NIOThreadPool(numberOfThreads: 1)
let fileio = NonBlockingFileIO(threadPool: pool)
pool.start()

let storage = FileStorageDriverFactoryStorage(
    eventLoopGroup: eventLoopGroup,
    byteBufferAllocator: .init(),
    fileio: fileio
)

storage.use(
    .s3(
        credentialProvider: .static(
            accessKeyId: "YOUR_ACCESS_KEY",
            secretAccessKey: "YOUR_SECRET"
        ),
        region: .init(rawValue: "YOUR_REGION"),
        bucket: .init(name: "YOUR_BUCKET"),
        endpoint: "YOUR_ENDPOINT",
        publicEndpoint: "YOUR_PUBLIC_ENDPOINT"
    ),
    as: .s3
)

let fs = storage.makeDriver(
    logger: logger,
    on: storage.eventLoopGroup.next()
)
    
defer { storage.shutdown() }
let key = "test-01.txt"
let data = Data("file storage test 01".utf8)
let res = try await fs.upload(key: key, data: data)

```

## Using with Vapor 4 

LiquidKit and the S3 driver is also compatible with Vapor 4 through the [Liquid](https://github.com/BinaryBirds/liquid) repository, that contains Vapor specific extensions.
