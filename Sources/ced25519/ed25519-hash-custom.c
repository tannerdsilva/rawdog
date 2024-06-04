#include "ed25519-hash-custom.h"

#include <string.h>

// Initialize the hash context for ED25519 using SHA512
void ed25519_hash_init(ed25519_hash_context *ctx) {
    _crawdog_sha512_init(&ctx->sha_ctx);  // Initialize the SHA512 context
}

// Update the hash context with input data
void ed25519_hash_update(ed25519_hash_context *ctx, const uint8_t *in, size_t inlen) {
    _crawdog_sha512_update(&ctx->sha_ctx, in, inlen);  // Update the SHA512 context with input data
}

// Finalize the hashing process and produce the final hash
void ed25519_hash_final(ed25519_hash_context *ctx, uint8_t *hash) {
    SHA512_HASH digest;
    _crawdog_sha512_finish(&ctx->sha_ctx, &digest);  // Finalize and retrieve the hash
    memcpy(hash, digest.bytes, SHA512_HASH_SIZE);  // Copy the hash to the output buffer
}

// Utility function to compute the hash of given input using ED25519 with SHA512
void ed25519_hash(uint8_t *hash, const uint8_t *in, size_t inlen) {
    ed25519_hash_context ctx;
    ed25519_hash_init(&ctx);
    ed25519_hash_update(&ctx, in, inlen);
    ed25519_hash_final(&ctx, hash);
}