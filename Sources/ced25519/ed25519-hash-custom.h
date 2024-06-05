#ifndef ED25519_HASH_CUSTOM_H
#define ED25519_HASH_CUSTOM_H

#include <stdint.h>
#include <stddef.h>
#include "__crawdog_sha512.h"

typedef struct {
    Sha512Context sha_ctx;	// SHA512 context
} ed25519_hash_context;

void ed25519_hash_init(ed25519_hash_context *ctx);
void ed25519_hash_update(ed25519_hash_context *ctx, const uint8_t *in, size_t inlen);
void ed25519_hash_final(ed25519_hash_context *ctx, uint8_t *hash);
void ed25519_hash(uint8_t *hash, const uint8_t *in, size_t inlen);

#endif