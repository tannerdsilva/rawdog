// swift-tools-version: 5.9
import PackageDescription
import CompilerPluginSupport

#if RAWDOG_LOG
let rawTargetDependencies:[Target.Dependency] = [
	"CRAW",
	"RAW_macros"
	.product(name:"Logging", package:"swift-log")
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
		.product(name: "Logging", package:"swift-log")
	]
	#else
	return [
		"RAW",
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
		.macOS(.v10_15)
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
			targets: ["RAW_blake2"]),
		.library(
			name: "RAW_bcrypt_blowfish",
			targets: ["RAW_bcrypt_blowfish"]),
		.library(
			name:"RAW_dh25519",
			targets: ["RAW_dh25519"]),
		.library(
			name:"RAW_chachapoly",
			targets: ["RAW_chachapoly"]),
		.library(
			name:"RAW_xchachapoly",
			targets: ["RAW_xchachapoly"]),
		.library(
			name:"RAW_argon2",
			targets: ["RAW_argon2"]),
		.library(
			name:"RAW_hmac",
			targets:["RAW_hmac"]),
		.library(
			name:"RAW_md5",
			targets:["RAW_md5"]),
		.library(
			name:"RAW_sha1",
			targets:["RAW_sha1"]),
		.library(
			name:"RAW_sha256",
			targets:["RAW_sha256"]),
		.library(
			name:"RAW_sha512",
			targets:["RAW_sha512"])
	],
	dependencies: [
		.package(url:"https://github.com/apple/swift-syntax.git", "509.0.1"..<"510.0.1"),
		.package(url:"https://github.com/apple/swift-log.git", "1.0.0"..<"2.0.0")
	],
	targets: [
		// the macros in this package are implemented here.
		.macro(name:"RAW_macros", dependencies:[
			.product(name:"SwiftSyntax", package:"swift-syntax"),
			.product(name:"SwiftSyntaxMacros", package:"swift-syntax"),
			.product(name:"SwiftOperators", package:"swift-syntax"),
			.product(name:"SwiftParser", package:"swift-syntax"),
			.product(name:"SwiftParserDiagnostics", package:"swift-syntax"),
			.product(name:"SwiftCompilerPlugin", package:"swift-syntax"),
			.product(name:"Logging", package:"swift-log")
		], swiftSettings:[]),

		// raw targets
		.target(name:"RAW_xchachapoly", dependencies:["RAW", "__crawdog_hchacha20", "__crawdog_chachapoly", "RAW_chachapoly", "__crawdog_xchachapoly"]),
		.target(name:"RAW_mnemonic", dependencies:["RAW", "RAW_blake2"]),
		.target(name:"RAW_argon2", dependencies:["RAW", "__crawdog_argon2"]),
		.target(name:"RAW_hmac", dependencies: ["RAW"]),
		.target(name:"RAW_kdf", dependencies: ["RAW_hmac", "RAW"]),
		.target(name:"RAW_md5", dependencies:["RAW", "__crawdog_md5"]),
		.target(name:"RAW_sha1", dependencies:["RAW", "__crawdog_sha1"]),
		.target(name:"RAW_sha256", dependencies:["RAW", "__crawdog_sha256"]),
		.target(name:"RAW_sha512", dependencies:["RAW", "__crawdog_sha512"]),
		.target(name:"RAW_chachapoly", dependencies:["RAW", "__crawdog_chachapoly"]),
		.target(name:"RAW_dh25519", dependencies:["RAW", "__crawdog_curve25519"]),
		.target(name:"RAW_bcrypt_blowfish", dependencies:["RAW", "__crawdog_crypt_blowfish"]),
		.target(name:"RAW_blake2", dependencies:["RAW", "__crawdog_blake2"]),
		.target(name:"RAW_base64", dependencies:rawBase64Dependencies()),
		.target(name:"RAW_hex", dependencies:rawHexDependencies()),
		.target(name:"RAW", dependencies:rawTargetDependencies),

		// c implementations
		.target(
			name:"__crawdog_argon2",
			dependencies:[
				"__crawdog_blake2",
				"RAW"
			]
		),
		.target(
			name:"__crawdog_chacha",
			dependencies:[],
			publicHeadersPath:"."
		),
		.target(
			name:"__crawdog_poly1305",
			dependencies:[],
			publicHeadersPath:"."
		),
		.target(
			name:"__crawdog_hchacha20-tests",
			dependencies:["__crawdog_hchacha20"],
			path:"Tests/__crawdog_hchacha20-tests",
			publicHeadersPath:"."
		),
		.target(
			name:"__crawdog_hchacha20",
			dependencies:["__crawdog_endianness"],
			publicHeadersPath:"."
		),
		.target(
			name:"__crawdog_xchachapoly",
			dependencies:["RAW", "__crawdog_chachapoly", "__crawdog_hchacha20"],
			publicHeadersPath:"."
		),
		.target(
			name:"__crawdog_endianness",
			dependencies:[],
			publicHeadersPath:"."
		),
		.target(
			name:"__crawdog_crypt_blowfish"
		),
		.target(
			name:"__crawdog_crypt_blowfish-tests",
			path:"Tests/__crawdog_crypt_blowfish-tests",
			publicHeadersPath:"include",
			cSettings: [.define("TEST")]
		),
		.target(
			name:"CRAW",
			publicHeadersPath:"."
		),
		.target(
			name:"CRAW_base64",
			path:"Tests/CRAW_base64"
		),
		.target(name:"__crawdog_blake2",
			publicHeadersPath:"include"
		),
		.target(
			name: "__crawdog_chachapoly",
			dependencies:["__crawdog_endianness", "__crawdog_chacha", "__crawdog_poly1305"],
			publicHeadersPath:"."
		),
		.target(
			name: "__crawdog_chachapoly-tests",
			dependencies: ["__crawdog_chachapoly"],
			path:"Tests/__crawdog_chachapoly-tests",
			publicHeadersPath:"."
		),
		.target(
			name:"__crawdog_argon2-tests",
			dependencies:["__crawdog_argon2"],
			path:"Tests/__crawdog_argon2-tests",
			publicHeadersPath:"."
		),
		.target(
			name:"__crawdog_hmac-tests",
			dependencies:[],
			path:"Tests/__crawdog_hmac-tests",
			publicHeadersPath:"."
		),
		.target(
			name:"__crawdog_hkdf-tests",
			dependencies:["syslibsodium"],
			path:"Tests/__crawdog_hkdf-tests",
			publicHeadersPath:"."
		),
		.target(
			name:"__crawdog_sha512",
			publicHeadersPath:"."
		),
		.target(
			name:"__crawdog_sha256",
			publicHeadersPath:"."
		),
		.target(
			name:"__crawdog_sha1",
			publicHeadersPath:"."
		),
		.target(
			name:"__crawdog_md5",
			publicHeadersPath:"."
		),
		.target(
			name:"__crawdog_curve25519",
			dependencies:[
				"__crawdog_sha512"
			],
			publicHeadersPath:"include",
			cSettings:[]
		),
		.target(
			name:"__crawdog_curve25519-tests",
			dependencies:[
				"__crawdog_curve25519"
			],
			path:"Tests/__crawdog_curve25519-tests",
			publicHeadersPath:"include"
		),
		.target(
			name:"__crawdog_hashing-tests",
			dependencies:[
				"__crawdog_sha512",
				"__crawdog_sha256",
				"__crawdog_sha1",
				"__crawdog_md5"
			],
			path:"Tests/__crawdog_hashing-tests",
			publicHeadersPath:"."
		),
		// system library for testing
		.systemLibrary(
			name:"syslibsodium",
			path:"Tests/syslibsodium",
			pkgConfig:"libsodium",
			providers: [
				.brew(["libsodium"]),
				.apt(["libsodium-dev"])
			]
		),
		
		// tests for raw and c targets
		.testTarget(name:"FullTestHarness", dependencies:["RAW_kdf", "__crawdog_hkdf-tests", "__crawdog_xchachapoly", "RAW_xchachapoly", "__crawdog_hchacha20-tests", "__crawdog_argon2-tests", "__crawdog_argon2", "RAW", "RAW_base64", "RAW_macros", "RAW_blake2", "RAW_hex", "CRAW_base64", "RAW_chachapoly", "__crawdog_crypt_blowfish-tests", "__crawdog_chachapoly-tests", "__crawdog_hashing-tests", "__crawdog_curve25519-tests", "__crawdog_hmac-tests", "RAW_hmac", "RAW_sha1", "RAW_sha256", "RAW_sha512"], resources:[.process("blake2-kat.json")], swiftSettings:[.define("ED25519_TEST"), .define("TEST")])
	]
)
