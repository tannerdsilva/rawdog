// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef __CRAWDOG_XCHACHAPOLY_H
#define __CRAWDOG_XCHACHAPOLY_H

#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define XCHACHA_NONCE_SIZE 24
#define CHACHA_NONCE_SIZE 12
#define XCHACHA_KEY_SIZE 32

// constants for return values
#define __CRAWDOG_XCHACHAPOLY_OK 0
#define __CRAWDOG_XCHACHAPOLY_INVALID_MAC -1

typedef struct __crawdog_xchachapoly_ctx {
	uint8_t key[XCHACHA_KEY_SIZE];
} __crawdog_xchachapoly_ctx;

/// @brief initialize the xchachapoly context
/// @param ctx the context to initialize
/// @param key the key to use
void __crawdog_xchachapoly_init(__crawdog_xchachapoly_ctx *ctx, const void *key);

/// @brief encrypt or decrypt with xchachapoly
/// @param ctx the context to use
/// @param nonce the 24 byte nonce to use
/// @param ad the associated data
/// @param ad_len the length of the associated data
int __crawdog_xchachapoly_crypt(__crawdog_xchachapoly_ctx *ctx, const void *nonce, const void *ad, int ad_len, const void *input, int input_len, void *output, void *tag, int tag_len, int encrypt);

#endif // __CRAWDOG_XCHACHAPOLY_H
