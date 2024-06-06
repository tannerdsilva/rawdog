// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
/*
 * In:  b =   2^5 - 2^0
 * Out: b = 2^250 - 2^0
 */
static void
__crawdog_curve25519_pow_two5mtwo0_two250mtwo0(bignum25519 b) {
	bignum25519 ALIGN(16) t0,c;

	/* 2^5  - 2^0 */ /* b */
	/* 2^10 - 2^5 */ __crawdog_curve25519_square_times(t0, b, 5);
	/* 2^10 - 2^0 */ __crawdog_curve25519_mul_noinline(b, t0, b);
	/* 2^20 - 2^10 */ __crawdog_curve25519_square_times(t0, b, 10);
	/* 2^20 - 2^0 */ __crawdog_curve25519_mul_noinline(c, t0, b);
	/* 2^40 - 2^20 */ __crawdog_curve25519_square_times(t0, c, 20);
	/* 2^40 - 2^0 */ __crawdog_curve25519_mul_noinline(t0, t0, c);
	/* 2^50 - 2^10 */ __crawdog_curve25519_square_times(t0, t0, 10);
	/* 2^50 - 2^0 */ __crawdog_curve25519_mul_noinline(b, t0, b);
	/* 2^100 - 2^50 */ __crawdog_curve25519_square_times(t0, b, 50);
	/* 2^100 - 2^0 */ __crawdog_curve25519_mul_noinline(c, t0, b);
	/* 2^200 - 2^100 */ __crawdog_curve25519_square_times(t0, c, 100);
	/* 2^200 - 2^0 */ __crawdog_curve25519_mul_noinline(t0, t0, c);
	/* 2^250 - 2^50 */ __crawdog_curve25519_square_times(t0, t0, 50);
	/* 2^250 - 2^0 */ __crawdog_curve25519_mul_noinline(b, t0, b);
}

/*
 * z^(p - 2) = z(2^255 - 21)
 */
static void
__crawdog_curve25519_recip(bignum25519 out, const bignum25519 z) {
	bignum25519 ALIGN(16) a,t0,b;

	/* 2 */ __crawdog_curve25519_square_times(a, z, 1); /* a = 2 */
	/* 8 */ __crawdog_curve25519_square_times(t0, a, 2);
	/* 9 */ __crawdog_curve25519_mul_noinline(b, t0, z); /* b = 9 */
	/* 11 */ __crawdog_curve25519_mul_noinline(a, b, a); /* a = 11 */
	/* 22 */ __crawdog_curve25519_square_times(t0, a, 1);
	/* 2^5 - 2^0 = 31 */ __crawdog_curve25519_mul_noinline(b, t0, b);
	/* 2^250 - 2^0 */ __crawdog_curve25519_pow_two5mtwo0_two250mtwo0(b);
	/* 2^255 - 2^5 */ __crawdog_curve25519_square_times(b, b, 5);
	/* 2^255 - 21 */ __crawdog_curve25519_mul_noinline(out, b, a);
}

/*
 * z^((p-5)/8) = z^(2^252 - 3)
 */
static void
__crawdog_curve25519_pow_two252m3(bignum25519 two252m3, const bignum25519 z) {
	bignum25519 ALIGN(16) b,c,t0;

	/* 2 */ __crawdog_curve25519_square_times(c, z, 1); /* c = 2 */
	/* 8 */ __crawdog_curve25519_square_times(t0, c, 2); /* t0 = 8 */
	/* 9 */ __crawdog_curve25519_mul_noinline(b, t0, z); /* b = 9 */
	/* 11 */ __crawdog_curve25519_mul_noinline(c, b, c); /* c = 11 */
	/* 22 */ __crawdog_curve25519_square_times(t0, c, 1);
	/* 2^5 - 2^0 = 31 */ __crawdog_curve25519_mul_noinline(b, t0, b);
	/* 2^250 - 2^0 */ __crawdog_curve25519_pow_two5mtwo0_two250mtwo0(b);
	/* 2^252 - 2^2 */ __crawdog_curve25519_square_times(b, b, 2);
	/* 2^252 - 3 */ __crawdog_curve25519_mul_noinline(two252m3, b, z);
}
