// swift-tools-version: 5.9
import PackageDescription
import CompilerPluginSupport

#if RAWDOG_LOG
let rawTargetDependencies:[Target.Dependency] = [
	"CRAW",
	"RAW_macros"
	.product(name: "Logging", package:"swift-log")
]
#else
let rawTargetDependencies:[Target.Dependency] = [
	"CRAW",
	"RAW_macros"
]
#endif

fileprivate func rawHexDependencies() -> [Target.Dependency] {
	#if RAWDOG_HEX_LOG
	return [
		"RAW",
		// "CRAW_hex",
		.product(name: "Logging", package:"swift-log")
	]
	#else
	return [
		"RAW",
		// "CRAW_hex"
	]
	#endif
}

fileprivate func rawBase64Dependencies() -> [Target.Dependency] {
	#if RAWDOG_BASE64_LOG
	return [
		"RAW",
		.product(name: "Logging", package:"swift-log")
	]
	#else
	return [
		"RAW",
	]
	#endif
}

let package = Package(
	name: "rawdog",
	platforms:[
		.macOS(.v11)
	],
	products: [
		.library(
			name: "RAW",
			targets: ["RAW"]),
		.library(
			name: "RAW_hex",
			targets: ["RAW_hex"]),
		.library(
			name: "RAW_base64",
			targets: ["RAW_base64"]),
		.library(
			name: "RAW_blake2",
			targets: ["RAW_blake2"])
	],
	dependencies: [
		.package(url:"https://github.com/apple/swift-syntax.git", from:"509.0.1"),
		.package(url:"https://github.com/apple/swift-log.git", from:"1.4.2")
	],
	targets: [
		// the macros in this package are implemented here.
		.macro(name:"RAW_macros", dependencies:[
			.product(name: "SwiftSyntax", package: "swift-syntax"),
			.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
			.product(name: "SwiftOperators", package: "swift-syntax"),
			.product(name: "SwiftParser", package: "swift-syntax"),
			.product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
			.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
			.product(name: "Logging", package:"swift-log")
		]),

		// raw targets
		.target(name:"RAW_blake2", dependencies:["RAW", "cblake2"]),
		.target(name:"RAW_base64", dependencies:rawBase64Dependencies(), swiftSettings:[/*.define("RAWDOG_BASE64_LOG")*/]),
		.target(name:"RAW_hex", dependencies:rawHexDependencies(), swiftSettings: [/*.define("RAWDOG_HEX_LOG")*/]),
		.target(name:"RAW", dependencies:rawTargetDependencies),

		// c implementations
		.target(name:"CRAW"),
		.target(name:"CRAW_base64", dependencies:[.product(name:"Logging", package:"swift-log")]),
		// .target(name:"CRAW_hex"),
		.target(name:"cblake2"),

		// tests for raw and c targets
		.testTarget(name:"PrimitiveTests", dependencies:["RAW", "RAW_base64", "RAW_macros", "RAW_blake2", "RAW_hex", "CRAW_base64"], resources:[.process("blake2-kat.json")]),
	]
)
