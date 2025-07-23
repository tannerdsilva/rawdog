// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef __CRAWDOG_HMAC_SHA256_HASH_TESTS
#define __CRAWDOG_HMAC_SHA256_HASH_TESTS

#include <stdint.h>

void hmac_sha256(const uint8_t* key, const uint32_t keysize, const uint8_t* msg, const uint32_t msgsize, uint8_t* output);

#endif // __CRAWDOG_HMAC_SHA256_HASH_TESTS