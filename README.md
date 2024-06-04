# rawdog

Rawdog is a lean, dependency-free Swift package created to simplify and expedite the binary encoding and decoding process for programming objects.

## Documentation 

I apologize for the lackluster documentation. I plan on giving this a thorough write-up and docc treatment after I'm more confident in how the API has settled.

### Inspiration

The fundamental components of the `RAW` module draw their inspiration from the LMDB and its `MDB_val` structure. Over time, I found immense value in this structure and the protocols built around it, initially developed in my [QuickLMDB library](https://github.com/tannerdsilva/QuickLMDB), and implemented them in numerous Swift projects. 

As I increasingly incorporated this structure and its related protocols from QuickLMDB into my regular coding routines, I decided to create a separate library – rawdog and its `RAW` module – by forking QuickLMDB and its data handling protocols. This decision aimed to help projects standardize, secure, and simplify data transfer methods, fostering an environment that equally accommodates Swift and C programming languages.

### Crypto

This is not a crypto library, however, certain cryptographic implementations have been very easy to package into this project without complex dependency structures.

### Versioning

This project follows the tagging semantics outlined in [SemVer 2.0.0](https://semver.org/#semantic-versioning-200).