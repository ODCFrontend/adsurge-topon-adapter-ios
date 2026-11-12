// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "AdSurgeADNAdapterForTopOn",
  platforms: [
    .iOS(.v12)
  ],
  products: [
    .library(
      name: "AdSurgeADNAdapterForTopOn",
      targets: ["AdSurgeADNAdapterForTopOnTarget"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/ODCFrontend/adsurge-adn-ios.git", exact: "2.0.2"),
  ],
  targets: [
    .target(
      name: "AdSurgeADNAdapterForTopOnTarget",
      dependencies: [
        .target(name: "AdSurgeADNAdapterForTopOn"),
        .product(name: "AdSurgeSDK", package: "adsurge-adn-ios"),
      ],
      path: "AdSurgeADNAdapterForTopOnTarget"
    ),
    .binaryTarget(
      name: "AdSurgeADNAdapterForTopOn",
      url:
        "https://github.com/ODCFrontend/adsurge-topon-adapter-ios/releases/download/2.0.200/AdSurgeADNAdapterForTopOn.zip",
      checksum: "ba4346548a6f853568b1c6c519b0dcb216c82e096b95cfac3fb08db0066a0eb7"
    ),
  ]
)
