// swift-tools-version: 5.8

import PackageDescription
let package = Package(
	name: "rawdog",
	platforms:[
		.macOS(.v11)
	],
	products: [
		.library(
			name: "RAW",
			targets: ["RAW"]),
	],
	targets: [
		.target(name:"RAW_base64", dependencies:["CRAW", "RAW"]),
		.target(
			name: "RAW",
			dependencies: ["CRAW"]),
		.target(
			name: "CRAW"),
		.testTarget(name:"PrimitiveTests", dependencies:["RAW", "RAW_base64"]),
	]
)
