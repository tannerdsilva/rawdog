# rawdog

rawdog is a lean, dependency-free* Swift package created to simplify and expedite the binary encoding and decoding process for programming objects.

the primary utility of this library comes in its ability to express statically allocated memoryspace, while automatically handling alignment, endianness, and initialization to and from other types.

in c, the following syntax is common and efficient `uint8_t[1024]`. in swift, trying to achieve a similar result (unaligned memory allocations with static length) is a nightmare....tuple literals are radically more verbose and notably less flexable than the c equivalent in syntax. this is the swift-specific problem that rawdog solves and builds on, while maintaining a rational but powerful pattern around type strictness and memory safety that Swift syntax is known for.

## Documentation 

I'm really happy with the structure and clarity of the code itself but documentation coverage is incomplete.

## Crypto

rawdog distributes and builds its own source material (in c) for all cryptographic functions, including:

- blake2 hashing (keyed and unkeyed in all variants)
- SHA1,256,512 hashing
- MD5 hashing
- ed25519 signature scheme
- curve25519 keys
- bcrypt blowfish password hashing
- chachapoly AEAD
- argon2 KDF

these sources come with a complete suite of tests that tested to pass on x86 and ARM, macOS and Linux. the code is also expected to handle endianness natively, although admittedly I do not have the means of verifying the 

### Cryptographic Attributions

rawdog cryptography is built on various open source contributions written in c. these references were taken as offered from their original authors in either MIT, ISC, or public domain licenses. All sources obtained have been heavily modified redistributed in this rawdog package with its MIT license.

- cryptographic sources modified and redistributed in June 2024

	- blake2 hashing - [claimed from public domain](https://github.com/BLAKE2/BLAKE2/blob/ed1974ea83433eba7b2d95c5dcd9ac33cb847913/COPYING#L1) with test vectors referenced in Swift XCTest. Thank you Jean-Philippe Aumasson, Samuel Neves, Zooko Wilcox-O’Hearn, Christian Winnerlein.

	- curve25519 key pairs with ed25519 signatures - [claimed with MIT license](https://github.com/msotoodeh/curve25519/blob/23a656c5234758f50d0576b49e0e9eecff68063b/license.txt#L1) with unit tests maintained in modification. Thank you Mehdi Sotoodeh.

	- crypt_blowfish - [claimed from public domain](https://github.com/openwall/crypt_blowfish/blob/3354bb81eea489e972b0a7c63231514ab34f73a0/crypt.h#L3C70-L4C11) with unit tests mainted in modification. Thank you Solar Designer.

	- chacha, poly1305, & chachapoly - [claimed with MIT license](https://github.com/grigorig/chachapoly/blob/ec7d8e03c6f715995b2015e9662a39277b994a74/README.md?plain=1#L11C233-L11C284) with unit tests maintained in modification. Thank you Grigori Goronzy.

	- SHA (implementations 1, 256, 512) & MD5 hashing - [claimed from public domain](https://github.com/WaterJuice/WjCryptLib/blob/e39760a85015b88820d7a2de832155a7c8ff2c88/UNLICENSE#L1) with unit tests maintained in modification. Thank you WaterJuice.

	- Argon2 KDF - [claimed from public domain](https://github.com/P-H-C/phc-winner-argon2/blob/f57e61e19229e23c4445b85494dbf7c07de721cb/LICENSE#L19) with unit tests maintained in modification. Thank you Daniel Dinu, Dmitry Khovratovich, Jean-Philippe Aumasson, and Samuel Neves.

	- hchacha20 - [claimed with ISC license](https://github.com/jedisct1/libsodium/blob/4a15ab7cd0a4b78a7356e5f488d5345b8d314549/LICENSE#L2) with unit tests maintained in modification. Thank you Frank Denis.

### Versioning

This project follows the tagging semantics outlined in [SemVer 2.0.0](https://semver.org/#semantic-versioning-200).

### Requirements

Given the critical use of macros in this suite, rawdog requires Swift language v5.9.0 or above to build and deploy successfully.

### License

rawdog and the entirety of its source is offered without warranty or support under the MIT license.