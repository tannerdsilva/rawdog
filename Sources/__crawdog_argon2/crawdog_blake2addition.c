// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#include "crawdog_blake2addition.h"
#include "crawdog_blake2.h"
#include "crawdog_blake2-impl.h"
#include "crawdog_core.h"
#include <string.h>

int __crawdog_blake2b_long(void *pout, size_t outlen, const void *in, size_t inlen) {
    uint8_t *out = (uint8_t *)pout;
    __crawdog_blake2b_state blake_state;
    uint8_t outlen_bytes[sizeof(uint32_t)] = {0};
    int ret = -1;

    if (outlen > UINT32_MAX) {
        goto fail;
    }

    /* Ensure little-endian byte order! */
    store32(outlen_bytes, (uint32_t)outlen);

#define TRY(statement)                                                         \
    do {                                                                       \
        ret = statement;                                                       \
        if (ret < 0) {                                                         \
            goto fail;                                                         \
        }                                                                      \
    } while ((void)0, 0)

    if (outlen <= __CRAWDOG_BLAKE2B_OUTBYTES) {
        TRY(__crawdog_blake2b_init(&blake_state, outlen));
        TRY(__crawdog_blake2b_update(&blake_state, outlen_bytes, sizeof(outlen_bytes)));
        TRY(__crawdog_blake2b_update(&blake_state, in, inlen));
        TRY(__crawdog_blake2b_final(&blake_state, out, outlen));
    } else {
        uint32_t toproduce;
        uint8_t out_buffer[__CRAWDOG_BLAKE2B_OUTBYTES];
        uint8_t in_buffer[__CRAWDOG_BLAKE2B_OUTBYTES];
        TRY(__crawdog_blake2b_init(&blake_state, __CRAWDOG_BLAKE2B_OUTBYTES));
        TRY(__crawdog_blake2b_update(&blake_state, outlen_bytes, sizeof(outlen_bytes)));
        TRY(__crawdog_blake2b_update(&blake_state, in, inlen));
        TRY(__crawdog_blake2b_final(&blake_state, out_buffer, __CRAWDOG_BLAKE2B_OUTBYTES));
        memcpy(out, out_buffer, __CRAWDOG_BLAKE2B_OUTBYTES / 2);
        out += __CRAWDOG_BLAKE2B_OUTBYTES / 2;
        toproduce = (uint32_t)outlen - __CRAWDOG_BLAKE2B_OUTBYTES / 2;

        while (toproduce > __CRAWDOG_BLAKE2B_OUTBYTES) {
            memcpy(in_buffer, out_buffer, __CRAWDOG_BLAKE2B_OUTBYTES);
            TRY(__crawdog_blake2b(out_buffer, __CRAWDOG_BLAKE2B_OUTBYTES, in_buffer,
                        __CRAWDOG_BLAKE2B_OUTBYTES, NULL, 0));
            memcpy(out, out_buffer, __CRAWDOG_BLAKE2B_OUTBYTES / 2);
            out += __CRAWDOG_BLAKE2B_OUTBYTES / 2;
            toproduce -= __CRAWDOG_BLAKE2B_OUTBYTES / 2;
        }

        memcpy(in_buffer, out_buffer, __CRAWDOG_BLAKE2B_OUTBYTES);
        TRY(__crawdog_blake2b(out_buffer, toproduce, in_buffer, __CRAWDOG_BLAKE2B_OUTBYTES, NULL,
                    0));
        memcpy(out, out_buffer, toproduce);
    }
fail:
    clear_internal_memory(&blake_state, sizeof(blake_state));
    return ret;
#undef TRY
}