// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef __CRAWDOG_SHA256_H
#define __CRAWDOG_SHA256_H

#include <stdint.h>
#include <stdio.h>

#define __CRAWDOG_SHA256_HASH_SIZE           ( 256 / 8 )
#define __CRAWDOG_SHA256_BLOCK_SIZE          64

typedef struct {
    uint64_t    length;
    uint32_t    state[8];
    uint32_t    curlen;
    uint8_t     buf[__CRAWDOG_SHA256_BLOCK_SIZE];
} __crawdog_sha256_context;


typedef struct {
    uint8_t      bytes [__CRAWDOG_SHA256_HASH_SIZE];
} __crawdog_sha256_output;

// initialize a hash
void __crawdog_sha256_init(__crawdog_sha256_context* Context);

// update the hasher with new date
void __crawdog_sha256_update(__crawdog_sha256_context* Context, void const* Buffer, uint32_t BufferSize);

// finish hashing
void __crawdog_sha256_finish(__crawdog_sha256_context* Context, __crawdog_sha256_output* Digest);

#endif // __CRAWDOG_SHA256_H