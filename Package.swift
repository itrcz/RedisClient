// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Redis Client",
    dependencies: [
        .package(url: "https://github.com/NozeIO/swift-nio-redis-client.git",
                 from: "0.10.0")
    ],
    targets: [
        .target    (name: "RedisClient", dependencies: [ "Redis" ]),
    ]
)
