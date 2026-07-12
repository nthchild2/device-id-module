// swift-tools-version: 5.9
// This package exists only to unit-test the pure Swift identifier logic
// (KeychainStore + DeviceIdentifierProvider) with `swift test`, without
// needing the generated example/ios Xcode project or a simulator.
// It is not part of the published pod: the podspec compiles ios/*.swift
// directly, and this manifest plus Tests/ are excluded from the npm package.
import PackageDescription

let package = Package(
  name: "FintechSecurityCore",
  platforms: [.iOS(.v15), .macOS(.v12)],
  targets: [
    .target(
      name: "FintechSecurityCore",
      path: "ios",
      sources: ["KeychainStore.swift", "DeviceIdentifierProvider.swift"]
    ),
    .testTarget(
      name: "FintechSecurityCoreTests",
      dependencies: ["FintechSecurityCore"],
      path: "Tests/FintechSecurityCoreTests"
    ),
  ]
)
