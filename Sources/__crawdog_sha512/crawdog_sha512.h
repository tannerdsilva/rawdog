// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef __CRAWDOG_SHA512_H
#define __CRAWDOG_SHA512_H

#include <stdint.h>
#include <stdio.h>

#define __CRAWDOG_SHA512_HASH_SIZE			( 512 / 8 )
#define __CRAWDOG_SHA512_BLOCK_SIZE			128

typedef struct __crawdog_sha512_context {
	uint64_t length;
	uint64_t state[8];
	uint32_t curlen;
	uint8_t buf[__CRAWDOG_SHA512_BLOCK_SIZE];
} __crawdog_sha512_context;

// structure representing a 64 byte hash.
typedef struct {
	uint8_t bytes[__CRAWDOG_SHA512_HASH_SIZE];
} __crawdog_sha512_output;

// init
void __crawdog_sha512_init(__crawdog_sha512_context *Context);

// update with new bytes
void __crawdog_sha512_update(__crawdog_sha512_context* Context, void const* Buffer, uint32_t BufferSize);

// finish
void __crawdog_sha512_finish(__crawdog_sha512_context* Context, __crawdog_sha512_output* Digest);

#endif // __CRAWDOG_SHA512_H