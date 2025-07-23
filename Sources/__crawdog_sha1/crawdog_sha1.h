// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef __CRAWDOG_SHA1_H
#define __CRAWDOG_SHA1_H

#include <stdint.h>
#include <stdio.h>

#define __CRAWDOG_SHA1_HASH_SIZE					( 160 / 8 )
#define __CRAWDOG_SHA1_BLOCK_SIZE 		64
typedef struct {
    uint32_t        State[5];
    uint32_t        Count[2];
    uint8_t         Buffer[64];
} __crawdog_sha1_context;


typedef struct {
    uint8_t      bytes [__CRAWDOG_SHA1_HASH_SIZE];
} __crawdog_sha1_output;

// initialize the hasher
void __crawdog_sha1_init(__crawdog_sha1_context* Context);

// update the hasher with new date
void __crawdog_sha1_update(__crawdog_sha1_context* Context, void const* Buffer, uint32_t BufferSize);

// finish the hasher
void __crawdog_sha1_finish(__crawdog_sha1_context* Context, __crawdog_sha1_output* Digest);

#endif // __CRAWDOG_SHA1_H