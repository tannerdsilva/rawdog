// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef ED25519_HASH_CUSTOM_H
#define ED25519_HASH_CUSTOM_H

#include <stdint.h>
#include <stddef.h>
#include "__crawdog_sha512.h"

typedef struct {
    __crawdog_sha512_context sha_ctx;
} __crawdog_ed25519_hash_context;

void __crawdog_ed25519_hash_init(__crawdog_ed25519_hash_context *ctx);
void __crawdog_ed25519_hash_update(__crawdog_ed25519_hash_context *ctx, const uint8_t *in, size_t inlen);
void __crawdog_ed25519_hash_final(__crawdog_ed25519_hash_context *ctx, uint8_t *hash);
void __crawdog_ed25519_hash(uint8_t *hash, const uint8_t *in, size_t inlen);

#endif