// MIT LICENSE
// (c) 2024 tanner silva. all rights reserved.
#ifndef __CRAWDOG_CHACHA_H
#define __CRAWDOG_CHACHA_H

#include <sys/types.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define __CRAWDOG_CHACHA_MINKEYLEN	16
#define __CRAWDOG_CHACHA_NONCELEN		8
#define __CRAWDOG_CHACHA_CTRLEN		8
#define __CRAWDOG_CHACHA_STATELEN		(__CRAWDOG_CHACHA_NONCELEN+__CRAWDOG_CHACHA_CTRLEN)
#define __CRAWDOG_CHACHA_BLOCKLEN		64

/* use memcpy() to copy blocks of memory (typically faster) */
#define USE_MEMCPY          1
/* use unaligned little-endian load/store (can be faster) */
#define USE_UNALIGNED       0

struct chacha_ctx {
	uint32_t input[16];
};

void __crawdog_chacha_keysetup(struct chacha_ctx *x, const unsigned char *k,
        uint32_t kbits);
void __crawdog_chacha_ivsetup(struct chacha_ctx *x, const unsigned char *iv,
        const unsigned char *ctr);
void __crawdog_chacha_encrypt_bytes(struct chacha_ctx *x, const unsigned char *m,
        unsigned char *c, uint32_t bytes);

#endif	/* __CRAWDOG_CHACHA_H */

