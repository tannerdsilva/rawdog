// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef __CRAWDOG_SHA256_H
#define __CRAWDOG_SHA256_H

#include <stdint.h>
#include <stdio.h>

typedef struct {
    uint64_t    length;
    uint32_t    state[8];
    uint32_t    curlen;
    uint8_t     buf[64];
} __crawdog_sha256_context;

#define SHA256_HASH_SIZE           ( 256 / 8 )

typedef struct {
    uint8_t      bytes [SHA256_HASH_SIZE];
} SHA256_HASH;

// initialize a hash
void __crawdog_sha256_init(__crawdog_sha256_context* Context);

// update the hasher with new date
void __crawdog_sha256_update(__crawdog_sha256_context* Context, void const* Buffer, uint32_t BufferSize);

// finish hashing
void __crawdog_sha256_finish(__crawdog_sha256_context* Context, SHA256_HASH* Digest);

#endif // __CRAWDOG_SHA256_H