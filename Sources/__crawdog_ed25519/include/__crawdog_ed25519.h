// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef __CRAWDOG_ED25519_H
#define __CRAWDOG_ED25519_H

#include <stdlib.h>

#if defined(__cplusplus)
extern "C" {
#endif

typedef unsigned char __crawdog_ed25519_signature[64];
typedef unsigned char __crawdog_ed25519_public_key[32];
typedef unsigned char __crawdog_ed25519_secret_key[32];

typedef unsigned char __crawdog_curved25519_key[32];

void __crawdog_ed25519_publickey(const __crawdog_ed25519_secret_key sk, __crawdog_ed25519_public_key pk);
int __crawdog_ed25519_sign_open(const unsigned char *m, size_t mlen, const __crawdog_ed25519_public_key pk, const __crawdog_ed25519_signature RS);
void __crawdog_ed25519_sign(const unsigned char *m, size_t mlen, const __crawdog_ed25519_secret_key sk, const __crawdog_ed25519_public_key pk, __crawdog_ed25519_signature RS);

int __crawdog_ed25519_sign_open_batch(const unsigned char **m, size_t *mlen, const unsigned char **pk, const unsigned char **RS, size_t num, int *valid);

void __crawdog_ed25519_randombytes_unsafe(void *out, size_t count);

void __crawdog_curved25519_scalarmult_basepoint(__crawdog_curved25519_key pk, const __crawdog_curved25519_key e);

#if defined(__cplusplus)
}
#endif

#endif // __CRAWDOG_ED25519_H