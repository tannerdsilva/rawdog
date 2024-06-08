// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
// copyright (c) 2015 mehdi sotoodeh
#ifndef __CRAWDOG_CURVE25519_DH_KEY_EXCHANGE_H
#define __CRAWDOG_CURVE25519_DH_KEY_EXCHANGE_H

void __crawdog_curve25519_calculate_public_key(
	unsigned char *pk,			// [32-bytes] OUT: Public key */
	unsigned char *sk);         /* [32-bytes] IN/OUT: Your secret key */

void __crawdog_curve25519_calculate_shared_key(
	unsigned char *shared,      /* [32-bytes] OUT: Created shared key */
	const unsigned char *pk,    /* [32-bytes] IN: Other side's public key */
	unsigned char *sk);         /* [32-bytes] IN/OUT: Your secret key */

#endif // __CRAWDOG_CURVE25519_DH_KEY_EXCHANGE_H