// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
// copyright (c) frank denis 2013-2024. all rights reserved.
#ifndef __CRAWDOG_HCHACHA20_H
#define __CRAWDOG_HCHACHA20_H

#include <stddef.h>

#define __CRAWDOG_HCHACHA20_OUTPUTBYTES 32U
size_t __crawdog_hchacha20_outputbytes(void);

#define __CRAWDOG_HCHACHA20_INPUTBYTES 16U
size_t __crawdog_hchacha20_inputbytes(void);

#define __CRAWDOG_HCHACHA20_KEYBYTES 32U
size_t __crawdog_hchacha20_keybytes(void);

#define __CRAWDOG_HCHACHA20_CONSTBYTES 16U
size_t __crawdog_hchacha20_constbytes(void);

/**
 * The __crawdog_hchacha20 function performs the HChaCha20 core operation.
 * HChaCha20 is a variant of the ChaCha20 stream cipher, but instead of
 * generating a keystream, it mixes input key material to produce a derived key.
 * 
 * @param out A pointer to the buffer where the output (derived key) will be stored.
 *          The output buffer should be at least 32 bytes long.
 * @param in A pointer to the 16-byte input nonce.
 * @param k A pointer to the 32-byte key used for the HChaCha20 operation.
 * @param c A pointer to a 16-byte constant ("expand 32-byte k" by default).
 *          This constant is part of the ChaCha20 algorithm specification and is used
 *          to distinguish different applications and users of the same key.
 * 
 * @return This function returns 0 if the operation is successful.
 *         Any non-zero return value indicates a failure in the operation.
 * 
 * @note The 'out' buffer should not overlap with the 'in', 'k', or 'c' buffers.
 */
int __crawdog_hchacha20(unsigned char *out, const unsigned char *in,
						const unsigned char *k, const unsigned char *c)
			__attribute__ ((nonnull(1, 2, 3)));


#endif // __CRAWDOG_HCHACHA20_H
