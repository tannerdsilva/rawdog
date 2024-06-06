// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
DONNA_INLINE static void
ge25519_p1p1_to_partial(ge25519 *r, const ge25519_p1p1 *p) {
	__crawdog_curve25519_mul(r->x, p->x, p->t);
	__crawdog_curve25519_mul(r->y, p->y, p->z);
	__crawdog_curve25519_mul(r->z, p->z, p->t); 
}

DONNA_INLINE static void
ge25519_p1p1_to_full(ge25519 *r, const ge25519_p1p1 *p) {
	__crawdog_curve25519_mul(r->x, p->x, p->t);
	__crawdog_curve25519_mul(r->y, p->y, p->z);
	__crawdog_curve25519_mul(r->z, p->z, p->t); 
	__crawdog_curve25519_mul(r->t, p->x, p->y); 
}

static void
ge25519_full_to_pniels(ge25519_pniels *p, const ge25519 *r) {
	__crawdog_curve25519_sub(p->ysubx, r->y, r->x);
	__crawdog_curve25519_add(p->xaddy, r->y, r->x);
	__crawdog_curve25519_copy(p->z, r->z);
	__crawdog_curve25519_mul(p->t2d, r->t, ge25519_ec2d);
}

/*
	adding & doubling
*/

static void
ge25519_add_p1p1(ge25519_p1p1 *r, const ge25519 *p, const ge25519 *q) {
	bignum25519 a,b,c,d,t,u;

	__crawdog_curve25519_sub(a, p->y, p->x);
	__crawdog_curve25519_add(b, p->y, p->x);
	__crawdog_curve25519_sub(t, q->y, q->x);
	__crawdog_curve25519_add(u, q->y, q->x);
	__crawdog_curve25519_mul(a, a, t);
	__crawdog_curve25519_mul(b, b, u);
	__crawdog_curve25519_mul(c, p->t, q->t);
	__crawdog_curve25519_mul(c, c, ge25519_ec2d);
	__crawdog_curve25519_mul(d, p->z, q->z);
	__crawdog_curve25519_add(d, d, d);
	__crawdog_curve25519_sub(r->x, b, a);
	__crawdog_curve25519_add(r->y, b, a);
	__crawdog_curve25519_add_after_basic(r->z, d, c);
	__crawdog_curve25519_sub_after_basic(r->t, d, c);
}


static void
ge25519_double_p1p1(ge25519_p1p1 *r, const ge25519 *p) {
	bignum25519 a,b,c;

	__crawdog_curve25519_square(a, p->x);
	__crawdog_curve25519_square(b, p->y);
	__crawdog_curve25519_square(c, p->z);
	__crawdog_curve25519_add_reduce(c, c, c);
	__crawdog_curve25519_add(r->x, p->x, p->y);
	__crawdog_curve25519_square(r->x, r->x);
	__crawdog_curve25519_add(r->y, b, a);
	__crawdog_curve25519_sub(r->z, b, a);
	__crawdog_curve25519_sub_after_basic(r->x, r->x, r->y);
	__crawdog_curve25519_sub_after_basic(r->t, c, r->z);
}

static void
ge25519_nielsadd2_p1p1(ge25519_p1p1 *r, const ge25519 *p, const ge25519_niels *q, unsigned char signbit) {
	const bignum25519 *qb = (const bignum25519 *)q;
	bignum25519 *rb = (bignum25519 *)r;
	bignum25519 a,b,c;

	__crawdog_curve25519_sub(a, p->y, p->x);
	__crawdog_curve25519_add(b, p->y, p->x);
	__crawdog_curve25519_mul(a, a, qb[signbit]); /* x for +, y for - */
	__crawdog_curve25519_mul(r->x, b, qb[signbit^1]); /* y for +, x for - */
	__crawdog_curve25519_add(r->y, r->x, a);
	__crawdog_curve25519_sub(r->x, r->x, a);
	__crawdog_curve25519_mul(c, p->t, q->t2d);
	__crawdog_curve25519_add_reduce(r->t, p->z, p->z);
	__crawdog_curve25519_copy(r->z, r->t);
	__crawdog_curve25519_add(rb[2+signbit], rb[2+signbit], c); /* z for +, t for - */
	__crawdog_curve25519_sub(rb[2+(signbit^1)], rb[2+(signbit^1)], c); /* t for +, z for - */
}

static void
ge25519_pnielsadd_p1p1(ge25519_p1p1 *r, const ge25519 *p, const ge25519_pniels *q, unsigned char signbit) {
	const bignum25519 *qb = (const bignum25519 *)q;
	bignum25519 *rb = (bignum25519 *)r;
	bignum25519 a,b,c;

	__crawdog_curve25519_sub(a, p->y, p->x);
	__crawdog_curve25519_add(b, p->y, p->x);
	__crawdog_curve25519_mul(a, a, qb[signbit]); /* ysubx for +, xaddy for - */
	__crawdog_curve25519_mul(r->x, b, qb[signbit^1]); /* xaddy for +, ysubx for - */
	__crawdog_curve25519_add(r->y, r->x, a);
	__crawdog_curve25519_sub(r->x, r->x, a);
	__crawdog_curve25519_mul(c, p->t, q->t2d);
	__crawdog_curve25519_mul(r->t, p->z, q->z);
	__crawdog_curve25519_add_reduce(r->t, r->t, r->t);
	__crawdog_curve25519_copy(r->z, r->t);
	__crawdog_curve25519_add(rb[2+signbit], rb[2+signbit], c); /* z for +, t for - */
	__crawdog_curve25519_sub(rb[2+(signbit^1)], rb[2+(signbit^1)], c); /* t for +, z for - */
}

static void
ge25519_double_partial(ge25519 *r, const ge25519 *p) {
	ge25519_p1p1 t;
	ge25519_double_p1p1(&t, p);
	ge25519_p1p1_to_partial(r, &t);
}

static void
ge25519_double(ge25519 *r, const ge25519 *p) {
	ge25519_p1p1 t;
	ge25519_double_p1p1(&t, p);
	ge25519_p1p1_to_full(r, &t);
}

static void
ge25519_add(ge25519 *r, const ge25519 *p,  const ge25519 *q) {
	ge25519_p1p1 t;
	ge25519_add_p1p1(&t, p, q);
	ge25519_p1p1_to_full(r, &t);
}

static void
ge25519_nielsadd2(ge25519 *r, const ge25519_niels *q) {
	bignum25519 a,b,c,e,f,g,h;

	__crawdog_curve25519_sub(a, r->y, r->x);
	__crawdog_curve25519_add(b, r->y, r->x);
	__crawdog_curve25519_mul(a, a, q->ysubx);
	__crawdog_curve25519_mul(e, b, q->xaddy);
	__crawdog_curve25519_add(h, e, a);
	__crawdog_curve25519_sub(e, e, a);
	__crawdog_curve25519_mul(c, r->t, q->t2d);
	__crawdog_curve25519_add(f, r->z, r->z);
	__crawdog_curve25519_add_after_basic(g, f, c);
	__crawdog_curve25519_sub_after_basic(f, f, c);
	__crawdog_curve25519_mul(r->x, e, f);
	__crawdog_curve25519_mul(r->y, h, g);
	__crawdog_curve25519_mul(r->z, g, f);
	__crawdog_curve25519_mul(r->t, e, h);
}

static void
ge25519_pnielsadd(ge25519_pniels *r, const ge25519 *p, const ge25519_pniels *q) {
	bignum25519 a,b,c,x,y,z,t;

	__crawdog_curve25519_sub(a, p->y, p->x);
	__crawdog_curve25519_add(b, p->y, p->x);
	__crawdog_curve25519_mul(a, a, q->ysubx);
	__crawdog_curve25519_mul(x, b, q->xaddy);
	__crawdog_curve25519_add(y, x, a);
	__crawdog_curve25519_sub(x, x, a);
	__crawdog_curve25519_mul(c, p->t, q->t2d);
	__crawdog_curve25519_mul(t, p->z, q->z);
	__crawdog_curve25519_add(t, t, t);
	__crawdog_curve25519_add_after_basic(z, t, c);
	__crawdog_curve25519_sub_after_basic(t, t, c);
	__crawdog_curve25519_mul(r->xaddy, x, t);
	__crawdog_curve25519_mul(r->ysubx, y, z);
	__crawdog_curve25519_mul(r->z, z, t);
	__crawdog_curve25519_mul(r->t2d, x, y);
	__crawdog_curve25519_copy(y, r->ysubx);
	__crawdog_curve25519_sub(r->ysubx, r->ysubx, r->xaddy);
	__crawdog_curve25519_add(r->xaddy, r->xaddy, y);
	__crawdog_curve25519_mul(r->t2d, r->t2d, ge25519_ec2d);
}


/*
	pack & unpack
*/

static void
ge25519_pack(unsigned char r[32], const ge25519 *p) {
	bignum25519 tx, ty, zi;
	unsigned char parity[32];
	__crawdog_curve25519_recip(zi, p->z);
	__crawdog_curve25519_mul(tx, p->x, zi);
	__crawdog_curve25519_mul(ty, p->y, zi);
	__crawdog_curve25519_contract(r, ty);
	__crawdog_curve25519_contract(parity, tx);
	r[31] ^= ((parity[0] & 1) << 7);
}

static int
ge25519_unpack_negative_vartime(ge25519 *r, const unsigned char p[32]) {
	static const unsigned char zero[32] = {0};
	static const bignum25519 one = {1};
	unsigned char parity = p[31] >> 7;
	unsigned char check[32];
	bignum25519 t, root, num, den, d3;

	__crawdog_curve25519_expand(r->y, p);
	__crawdog_curve25519_copy(r->z, one);
	__crawdog_curve25519_square(num, r->y); /* x = y^2 */
	__crawdog_curve25519_mul(den, num, ge25519_ecd); /* den = dy^2 */
	__crawdog_curve25519_sub_reduce(num, num, r->z); /* x = y^1 - 1 */
	__crawdog_curve25519_add(den, den, r->z); /* den = dy^2 + 1 */

	/* Computation of sqrt(num/den) */
	/* 1.: computation of num^((p-5)/8)*den^((7p-35)/8) = (num*den^7)^((p-5)/8) */
	__crawdog_curve25519_square(t, den);
	__crawdog_curve25519_mul(d3, t, den);
	__crawdog_curve25519_square(r->x, d3);
	__crawdog_curve25519_mul(r->x, r->x, den);
	__crawdog_curve25519_mul(r->x, r->x, num);
	__crawdog_curve25519_pow_two252m3(r->x, r->x);

	/* 2. computation of r->x = num * den^3 * (num*den^7)^((p-5)/8) */
	__crawdog_curve25519_mul(r->x, r->x, d3);
	__crawdog_curve25519_mul(r->x, r->x, num);

	/* 3. Check if either of the roots works: */
	__crawdog_curve25519_square(t, r->x);
	__crawdog_curve25519_mul(t, t, den);
	__crawdog_curve25519_sub_reduce(root, t, num);
	__crawdog_curve25519_contract(check, root);
	if (!__crawdog_ed25519_verify(check, zero, 32)) {
		__crawdog_curve25519_add_reduce(t, t, num);
		__crawdog_curve25519_contract(check, t);
		if (!__crawdog_ed25519_verify(check, zero, 32))
			return 0;
		__crawdog_curve25519_mul(r->x, r->x, ge25519_sqrtneg1);
	}

	__crawdog_curve25519_contract(check, r->x);
	if ((check[0] & 1) == parity) {
		__crawdog_curve25519_copy(t, r->x);
		__crawdog_curve25519_neg(r->x, t);
	}
	__crawdog_curve25519_mul(r->t, r->x, r->y);
	return 1;
}


/*
	scalarmults
*/

#define S1_SWINDOWSIZE 5
#define S1_TABLE_SIZE (1<<(S1_SWINDOWSIZE-2))
#define S2_SWINDOWSIZE 7
#define S2_TABLE_SIZE (1<<(S2_SWINDOWSIZE-2))

/* computes [s1]p1 + [s2]basepoint */
static void 
ge25519_double_scalarmult_vartime(ge25519 *r, const ge25519 *p1, const bignum256modm s1, const bignum256modm s2) {
	signed char slide1[256], slide2[256];
	ge25519_pniels pre1[S1_TABLE_SIZE];
	ge25519 d1;
	ge25519_p1p1 t;
	int32_t i;

	contract256_slidingwindow_modm(slide1, s1, S1_SWINDOWSIZE);
	contract256_slidingwindow_modm(slide2, s2, S2_SWINDOWSIZE);

	ge25519_double(&d1, p1);
	ge25519_full_to_pniels(pre1, p1);
	for (i = 0; i < S1_TABLE_SIZE - 1; i++)
		ge25519_pnielsadd(&pre1[i+1], &d1, &pre1[i]);

	/* set neutral */
	memset(r, 0, sizeof(ge25519));
	r->y[0] = 1;
	r->z[0] = 1;

	i = 255;
	while ((i >= 0) && !(slide1[i] | slide2[i]))
		i--;

	for (; i >= 0; i--) {
		ge25519_double_p1p1(&t, r);

		if (slide1[i]) {
			ge25519_p1p1_to_full(r, &t);
			ge25519_pnielsadd_p1p1(&t, r, &pre1[abs(slide1[i]) / 2], (unsigned char)slide1[i] >> 7);
		}

		if (slide2[i]) {
			ge25519_p1p1_to_full(r, &t);
			ge25519_nielsadd2_p1p1(&t, r, &ge25519_niels_sliding_multiples[abs(slide2[i]) / 2], (unsigned char)slide2[i] >> 7);
		}

		ge25519_p1p1_to_partial(r, &t);
	}
}



#if !defined(HAVE_GE25519_SCALARMULT_BASE_CHOOSE_NIELS)

static uint32_t
ge25519_windowb_equal(uint32_t b, uint32_t c) {
	return ((b ^ c) - 1) >> 31;
}

static void
ge25519_scalarmult_base_choose_niels(ge25519_niels *t, const uint8_t table[256][96], uint32_t pos, signed char b) {
	bignum25519 neg;
	uint32_t sign = (uint32_t)((unsigned char)b >> 7);
	uint32_t mask = ~(sign - 1);
	uint32_t u = (b + mask) ^ mask;
	uint32_t i;

	/* ysubx, xaddy, t2d in packed form. initialize to ysubx = 1, xaddy = 1, t2d = 0 */
	uint8_t packed[96] = {0};
	packed[0] = 1;
	packed[32] = 1;

	for (i = 0; i < 8; i++)
		__crawdog_curve25519_move_conditional_bytes(packed, table[(pos * 8) + i], ge25519_windowb_equal(u, i + 1));

	/* expand in to t */
	__crawdog_curve25519_expand(t->ysubx, packed +  0);
	__crawdog_curve25519_expand(t->xaddy, packed + 32);
	__crawdog_curve25519_expand(t->t2d  , packed + 64);

	/* adjust for sign */
	__crawdog_curve25519_swap_conditional(t->ysubx, t->xaddy, sign);
	__crawdog_curve25519_neg(neg, t->t2d);
	__crawdog_curve25519_swap_conditional(t->t2d, neg, sign);
}

#endif /* HAVE_GE25519_SCALARMULT_BASE_CHOOSE_NIELS */


/* computes [s]basepoint */
static void
ge25519_scalarmult_base_niels(ge25519 *r, const uint8_t basepoint_table[256][96], const bignum256modm s) {
	signed char b[64];
	uint32_t i;
	ge25519_niels t;

	contract256_window4_modm(b, s);

	ge25519_scalarmult_base_choose_niels(&t, basepoint_table, 0, b[1]);
	__crawdog_curve25519_sub_reduce(r->x, t.xaddy, t.ysubx);
	__crawdog_curve25519_add_reduce(r->y, t.xaddy, t.ysubx);
	memset(r->z, 0, sizeof(bignum25519));
	__crawdog_curve25519_copy(r->t, t.t2d);
	r->z[0] = 2;	
	for (i = 3; i < 64; i += 2) {
		ge25519_scalarmult_base_choose_niels(&t, basepoint_table, i / 2, b[i]);
		ge25519_nielsadd2(r, &t);
	}
	ge25519_double_partial(r, r);
	ge25519_double_partial(r, r);
	ge25519_double_partial(r, r);
	ge25519_double(r, r);
	ge25519_scalarmult_base_choose_niels(&t, basepoint_table, 0, b[0]);
	__crawdog_curve25519_mul(t.t2d, t.t2d, ge25519_ecd);
	ge25519_nielsadd2(r, &t);
	for(i = 2; i < 64; i += 2) {
		ge25519_scalarmult_base_choose_niels(&t, basepoint_table, i / 2, b[i]);
		ge25519_nielsadd2(r, &t);
	}
}

