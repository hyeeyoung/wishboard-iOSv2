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
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.5.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0"),
    ],
    targets: [
        .target(
            name: "ApplicationLibrary",
            dependencies: ["SnapKit", "Then", "Kingfisher",
                           .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                           .product(name: "Lottie", package: "lottie-spm")
                          ]),
        .testTarget(
            name: "ApplicationLibraryTests",
            dependencies: ["ApplicationLibrary"]),
    ]
)
