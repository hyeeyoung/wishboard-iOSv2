// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "ApplicationLibrary",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ApplicationLibrary",
            targets: ["ApplicationLibrary"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.0.0"),
        .package(url: "https://github.com/devxoul/Then.git", from: "2.7.0"),
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "ApplicationLibrary",
            dependencies: ["SnapKit", "Then", "Moya",
                           .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
                          ]),
        .testTarget(
            name: "ApplicationLibraryTests",
            dependencies: ["ApplicationLibrary"]),
    ]
)
