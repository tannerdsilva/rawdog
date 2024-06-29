// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
// copyright (c) 2015 mehdi sotoodeh
#ifndef __CRAWDOG_CURVE25519_DH_KEY_EXCHANGE_H
#define __CRAWDOG_CURVE25519_DH_KEY_EXCHANGE_H
#include <stdint.h>

void __crawdog_curve25519_calculate_public_key(
	uint8_t *pk,				// [32-bytes] OUT: public key
	const uint8_t *sk);        // [32-bytes] IN/OUT: secret key

void __crawdog_curve25519_forge_private_key(
	uint8_t *rand);				// [32-bytes] IN/OUT: cryptographically secure random bits. this is basically the secret key, but it will get slightly masked, hence the need to mutate and the term 'forge'*/

void __crawdog_curve25519_calculate_shared_key(
	unsigned char *shared,		/* [32-bytes] OUT: shared key */
	const unsigned char *pk,	/* [32-bytes] IN: other side's public key */
	const unsigned char *sk);	/* [32-bytes] IN: your secret key */

#endif // __CRAWDOG_CURVE25519_DH_KEY_EXCHANGE_H