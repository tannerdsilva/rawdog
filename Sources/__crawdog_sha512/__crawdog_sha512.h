// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef __CRAWDOG_SHA512_H
#define __CRAWDOG_SHA512_H

#include <stdint.h>
#include <stdio.h>

typedef struct {
	uint64_t length;
	uint64_t state[8];
	uint32_t curlen;
	uint8_t buf[128];
} __crawdog_sha512_context;

#define SHA512_HASH_SIZE	( 512 / 8 )

// structure representing a 64 byte hash.
typedef struct {
	uint8_t bytes[SHA512_HASH_SIZE];
} SHA512_HASH;

// init
void __crawdog_sha512_init(__crawdog_sha512_context *Context);

// update with new bytes
void __crawdog_sha512_update(__crawdog_sha512_context* Context, void const* Buffer, uint32_t BufferSize);

// finish
void __crawdog_sha512_finish(__crawdog_sha512_context* Context, SHA512_HASH* Digest);

#endif // __CRAWDOG_SHA512_H