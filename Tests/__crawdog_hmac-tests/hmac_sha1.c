// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#include "hmac_sha1.h"
#include "crawdog_sha1.h"

void hmac_sha1(const uint8_t* key, const uint32_t keysize, const uint8_t* msg, const uint32_t msgsize, uint8_t* output) {
	__crawdog_sha1_context outer, inner;
	uint8_t tmp;
	
	__crawdog_sha1_init(&outer);
	__crawdog_sha1_init(&inner);
	
	uint32_t i;
	for (i = 0; i < keysize; ++i) {
		tmp = key[i] ^ 0x5C;
		__crawdog_sha1_update(&outer, &tmp, 1);
		tmp = key[i] ^ 0x36;
		__crawdog_sha1_update(&inner, &tmp, 1);
	}
	for (; i < 64; ++i) {
		tmp = 0x5C;
		__crawdog_sha1_update(&outer, &tmp, 1);
		tmp = 0x36;
		__crawdog_sha1_update(&inner, &tmp, 1);
	}
	__crawdog_sha1_update(&inner, msg, msgsize);
	__crawdog_sha1_finish(&inner, (__crawdog_sha1_output*)output);
	
	__crawdog_sha1_update(&outer, output, __CRAWDOG_SHA1_HASH_SIZE);
	__crawdog_sha1_finish(&outer, (__crawdog_sha1_output*)output);
}