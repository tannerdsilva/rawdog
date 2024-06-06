# rawdog

Rawdog is a lean, dependency-free Swift package created to simplify and expedite the binary encoding and decoding process for programming objects.

## Documentation 

I apologize for the lackluster documentation. I plan on giving this a thorough write-up and docc treatment after I'm more confident in how the API has settled.

### Inspiration

The fundamental components of the `RAW` module draw their inspiration from the LMDB and its `MDB_val` structure. Over time, I found immense value in this structure and the protocols built around it, initially developed in my [QuickLMDB library](https://github.com/tannerdsilva/QuickLMDB), and implemented them in numerous Swift projects. 

As I increasingly incorporated this structure and its related protocols from QuickLMDB into my regular coding routines, I decided to create a separate library – rawdog and its `RAW` module – by forking QuickLMDB and its data handling protocols. This decision aimed to help projects standardize, secure, and simplify data transfer methods, fostering an environment that equally accommodates Swift and C programming languages.

## Crypto

rawdog distributes source material for all cryptographic functions that are offered, including:

- blake2 hashing (keyed and unkeyed in all variants)
- SHA512 hashing
- ed25519 signature scheme
- bcrypt blowfish password hashing
- chachapoly AEAD

these sources come with a complete suite of tests that tested to pass on x86 and ARM, macOS and Linux. the code is also expected to handle endianness natively, although admittedly I do not have the means of verifying the 

### Cryptographic Attributions

rawdog cryptography is built on various open source contributions written in c. these references were taken as offered from their original authors in either MIT or public domain licenses, and redistributed in this rawdog package with its MIT license.

- cryptographic sources captured and redistributed in June 2024

	- blake2 hashing - [claimed from public domain](https://github.com/BLAKE2/BLAKE2/blob/ed1974ea83433eba7b2d95c5dcd9ac33cb847913/COPYING#L1). Thank you Jean-Philippe Aumasson, Samuel Neves, Zooko Wilcox-O’Hearn, Christian Winnerlein.

	- ed25519 - [claimed from public domain](https://github.com/floodyberry/ed25519-donna/blob/8757bd4cd209cb032853ece0ce413f122eef212c/ed25519.c#L2) with unit tests maintained in modification. Thank you Andrew M.

	- crypt_blowfish - [claimed from public domain](https://github.com/openwall/crypt_blowfish/blob/3354bb81eea489e972b0a7c63231514ab34f73a0/crypt.h#L3C70-L4C11) with unit tests mainted in modification. Thank you Solar Designer.

	- chachapoly - [claimed with MIT license](https://github.com/grigorig/chachapoly/blob/ec7d8e03c6f715995b2015e9662a39277b994a74/README.md?plain=1#L11C233-L11C284) with unit test maintained in modification. Thank you Grigori Goronzy.

### Versioning

This project follows the tagging semantics outlined in [SemVer 2.0.0](https://semver.org/#semantic-versioning-200).

### License

rawdog and the entirety of its source is offered without warranty under the MIT license.