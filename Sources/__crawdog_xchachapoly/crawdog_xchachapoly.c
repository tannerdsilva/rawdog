// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#include "crawdog_xchachapoly.h"
#include "crawdog_chachapoly.h"
#include "crawdog_hchacha20.h"

/**
 * Initialize ChaCha20-Poly1305 AEAD.
 * For RFC 7539 conformant AEAD, 32 byte must be used.
 *
 * \param ctx context data
 * \param key 32 bytes of key material
 * \return success if 0
 */
void __crawdog_xchachapoly_init(__crawdog_xchachapoly_ctx *ctx, const void *key) {
	memcpy(&ctx->key, key, XCHACHA_KEY_SIZE);
}

/**
 * Encrypt or decrypt with XChaCha20-Poly1305. This extends the AEAD construction
 * to use a longer nonce.
 *
 * \param ctx context data
 * \param nonce nonce (24 bytes)
 * \param ad associated data
 * \param ad_len associated data length in bytes
 * \param input plaintext/ciphertext input
 * \param input_len input length in bytes
 * \param output plaintext/ciphertext output
 * \param tag tag output
 * \param tag_len tag length in bytes (0-16); if 0, authentication is skipped
 * \param encrypt decrypt if 0, else encrypt
 * \return __CRAWDOG_XCHACHAPOLY_OK if no error, __CRAWDOG_XCHACHAPOLY_INVALID_MAC if auth
 *         failed when decrypting
 */
int __crawdog_xchachapoly_crypt(__crawdog_xchachapoly_ctx *ctx, const void *nonce, const void *ad, int ad_len, const void *input, int input_len, void *output, void *tag, int tag_len, int encrypt) {
    
	unsigned char subkey[XCHACHA_KEY_SIZE];
	unsigned char chacha_nonce[CHACHA_NONCE_SIZE];

	// derive subkey using HChaCha20
	int result = __crawdog_hchacha20(subkey, nonce, ctx->key, (const unsigned char *)"expand 32-byte k");
	if (result != 0) {
		return -1;
	}

	struct __crawdog_chachapoly_ctx chacha_ctx;

    // initialize ChaCha20-Poly1305 with derived subkey
    __crawdog_chachapoly_init(&chacha_ctx, subkey, XCHACHA_KEY_SIZE);

    // prepare nonce for ChaCha20-Poly1305 (last 8 bytes of the original nonce)
    memcpy(chacha_nonce + 4, ((const unsigned char*)nonce) + 16, 8);
	memset(chacha_nonce, 0, 4);

    // perform the actual encryption or decryption
    return __crawdog_chachapoly_crypt(&chacha_ctx, chacha_nonce, ad, ad_len, input, input_len, output, tag, tag_len, encrypt);
}