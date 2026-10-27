// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "AdSurgeADNAdapterForTopOn",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "AdSurgeADNAdapterForTopOn",
      targets: ["AdSurgeADNAdapterForTopOn"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/ODCFrontend/adsurge-adn-ios.git", exact: "2.0.1"),
  ],
  targets: [
    .target(
      name: "AdSurgeADNAdapterForTopOn",
      dependencies: [
        .product(name: "AdSurgeSDK", package: "adsurge-adn-ios"),
      ],
      path: "AdSurgeADNAdapterForTopOn",
      publicHeadersPath: "."
    )
  ]
)
