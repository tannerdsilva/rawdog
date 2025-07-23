// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#include "hmac_sha256.h"
#include "crawdog_sha256.h"

void hmac_sha256(const uint8_t* key, const uint32_t keysize, const uint8_t* msg, const uint32_t msgsize, uint8_t* output) {
	__crawdog_sha256_context outer, inner;
	uint8_t tmp;
	
	__crawdog_sha256_init(&outer);
	__crawdog_sha256_init(&inner);
	uint8_t normalized_key[__CRAWDOG_SHA256_HASH_SIZE];
	const uint8_t* key_ptr = key;
	uint32_t ks = keysize;

	// ←–– Insert hashing of over-long keys here
	if (ks > __CRAWDOG_SHA256_BLOCK_SIZE) {
		__crawdog_sha256_context keyctx;
		__crawdog_sha256_init(&keyctx);
		__crawdog_sha256_update(&keyctx, key_ptr, ks);
		__crawdog_sha256_finish(&keyctx, (__crawdog_sha256_output*)normalized_key);
		key_ptr = normalized_key;
		ks = __CRAWDOG_SHA256_HASH_SIZE;
	}

	// Now safe to init contexts and proceed
	__crawdog_sha256_init(&outer);
	__crawdog_sha256_init(&inner);

	// iPad/oPad processing using key_ptr and length ks...
	for (uint32_t i = 0; i < ks; ++i) {
		tmp = key_ptr[i] ^ 0x5c;
		__crawdog_sha256_update(&outer, &tmp, 1);
		tmp = key_ptr[i] ^ 0x36;
		__crawdog_sha256_update(&inner, &tmp, 1);
	}
	for (uint32_t i = ks; i < __CRAWDOG_SHA256_BLOCK_SIZE; ++i) {
		tmp = 0x5c;
		__crawdog_sha256_update(&outer, &tmp, 1);
		tmp = 0x36;
		__crawdog_sha256_update(&inner, &tmp, 1);
	}

	// Finish inner, then outer
	__crawdog_sha256_update(&inner, msg, msgsize);
	__crawdog_sha256_finish(&inner, (__crawdog_sha256_output*)output);

	__crawdog_sha256_update(&outer, output, __CRAWDOG_SHA256_HASH_SIZE);
	__crawdog_sha256_finish(&outer, (__crawdog_sha256_output*)output);
}