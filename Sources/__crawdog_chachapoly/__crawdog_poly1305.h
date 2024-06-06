// MIT LICENSE
// (c) 2024 tanner silva. all rights reserved.
#ifndef __CRAWDOG_POLY1305_H
#define __CRAWDOG_POLY1305_H

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define __CRAWDOG_POLY1305_KEYLEN     32
#define __CRAWDOG_POLY1305_TAGLEN     16
#define __CRAWDOG_POLY1305_BLOCK_SIZE 16

/* use memcpy() to copy blocks of memory (typically faster) */
#define USE_MEMCPY          1
/* use unaligned little-endian load/store (can be faster) */
#define USE_UNALIGNED       0

struct __crawdog_poly1305_context {
    uint32_t r[5];
    uint32_t h[5];
    uint32_t pad[4];
    size_t leftover;
    unsigned char buffer[__CRAWDOG_POLY1305_BLOCK_SIZE];
    unsigned char final;
};

void __crawdog_poly1305_init(struct __crawdog_poly1305_context *ctx, const unsigned char key[32]);
void __crawdog_poly1305_update(struct __crawdog_poly1305_context *ctx, const unsigned char *m, size_t bytes);
void __crawdog_poly1305_finish(struct __crawdog_poly1305_context *ctx, unsigned char mac[16]);
void __crawdog_poly1305_auth(unsigned char mac[16], const unsigned char *m, size_t bytes, const unsigned char key[32]);

#endif /* __CRAWDOG_POLY1305_H */

