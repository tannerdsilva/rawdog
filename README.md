# rawdog

Rawdog is a lean, dependency-free Swift package created to simplify and expedite the binary encoding and decoding process for programming objects.

## RAW Target

The `RAW` target serves as the central feature of this library, encompassing core protocols, extensions, and essential documentation for the effective use of `rawdog`.

Every aspect of the `RAW` module is thoroughly documented using `swift-docc` for user-friendly accessibility. To offer a quick snapshot, the module's structure is as follows:

### Inspiration

The fundamental components of the `RAW` module draw their inspiration from the LMDB and its `MDB_val` structure. Over time, I found immense value in this structure and the protocols built around it, initially developed in my [QuickLMDB library](https://github.com/tannerdsilva/QuickLMDB), and implemented them in numerous Swift projects. 

As I increasingly incorporated this structure and its related protocols from QuickLMDB into my regular coding routines, I decided to create a separate library – rawdog and its `RAW` module – by forking QuickLMDB and its data handling protocols. This decision aimed to help projects standardize, secure, and simplify data transfer methods, fostering an environment that equally accommodates Swift and C programming languages.

### Versioning

This project follows the tagging semantics outlined in [SemVer 2.0.0](https://semver.org/#semantic-versioning-200).