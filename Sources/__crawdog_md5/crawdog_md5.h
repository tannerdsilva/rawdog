// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef __CRAWDOG_MD5_H
#define __CRAWDOG_MD5_H

#include <stdint.h>
#include <stdio.h>

#define __CRAWDOG_MD5_HASH_SIZE				16
#define __CRAWDOG_MD5_BLOCK_SIZE			16

typedef struct {
    uint32_t     lo;
    uint32_t     hi;
    uint32_t     a;
    uint32_t     b;
    uint32_t     c;
    uint32_t     d;
    uint8_t      buffer[64];
    uint32_t     block[__CRAWDOG_MD5_BLOCK_SIZE];
} __crawdog_md5_context;


typedef struct {
    uint8_t      bytes [__CRAWDOG_MD5_HASH_SIZE];
} __crawdog_md5_output;

void __crawdog_md5_init(__crawdog_md5_context* Context);

void __crawdog_md5_update(__crawdog_md5_context* Context, void const* Buffer, uint32_t BufferSize);

void __crawdog_md5_finish(__crawdog_md5_context* Context, __crawdog_md5_output* Digest);

#endif // __CRAWDOG_MD5_H