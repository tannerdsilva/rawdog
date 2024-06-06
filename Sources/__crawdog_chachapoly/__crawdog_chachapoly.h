// MIT LICENSE
// (c) 2024 tanner silva. all rights reserved.
// Copyright (c) 2015 Grigori Goronzy <goronzy@kinoho.net>

#ifndef __CRAWDOG_CHACHAPOLY_H
#define __CRAWDOG_CHACHAPOLY_H

#include "__crawdog_chacha.h"
#include "__crawdog_poly1305.h"

#define __CRAWDOG_CHACHAPOLY_OK           0
#define __CRAWDOG_CHACHAPOLY_INVALID_MAC  -1

struct __crawdog_chachapoly_ctx {
    struct chacha_ctx cha_ctx;
};

/**
 * Initialize ChaCha20-Poly1305 AEAD.
 * For RFC 7539 conformant AEAD, 256 bit keys must be used.
 *
 * \param ctx context data
 * \param key 16 or 32 bytes of key material
 * \param key_len key length, 256 or 512 bits
 * \return success if 0
 */
int __crawdog_chachapoly_init(struct __crawdog_chachapoly_ctx *ctx, const void *key, int key_len);

/**
 * Encrypt or decrypt with ChaCha20-Poly1305. The AEAD construction conforms
 * to RFC 7539.
 *
 * \param ctx context data
 * \param nonce nonce (12 bytes)
 * \param ad associated data
 * \param ad_len associated data length in bytes
 * \param input plaintext/ciphertext input
 * \param input_len input length in bytes;
 * \param output plaintext/ciphertext output
 * \param tag tag output
 * \param tag_len tag length in bytes (0-16);
          if 0, authentification is skipped
 * \param encrypt decrypt if 0, else encrypt
 * \return __CRAWDOG_CHACHAPOLY_OK if no error, __CRAWDOG_CHACHAPOLY_INVALID_MAC if auth
 *         failed when decrypting
 */
int __crawdog_chachapoly_crypt(struct __crawdog_chachapoly_ctx *ctx, const void *nonce,
        const void *ad, int ad_len, void *input, int input_len,
        void *output, void *tag, int tag_len, int encrypt);

/**
 * Encrypt or decrypt with Chacha20-Poly1305 for short messages.
 * The AEAD construction is different from chachapoly_crypt, but more
 * efficient for small messages. Up to 32 bytes can be encrypted. The size
 * of associated data is not restricted. The interface is similar to
 * chachapoly_crypt.
 */
int __crawdog_chachapoly_crypt_short(struct __crawdog_chachapoly_ctx *ctx, const void *nonce,
        const void *ad, int ad_len, void *input, int input_len,
        void *output, void *tag, int tag_len, int encrypt);

#endif
