// MIT LICENSE
// (c) 2024 tanner silva. all rights reserved.
// Copyright (c) 2015 Grigori Goronzy <goronzy@kinoho.net>

#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>

#include "__crawdog_chachapoly.h"

#define U8V(x) ((unsigned char)(x))

#if (USE_UNALIGNED == 1)
#define U8TO32_LITTLE(p) \
    (*((uint32_t *)(p)))
#define U32TO8_LITTLE(p, v) \
    do { \
      *((uint32_t *)(p)) = v; \
    } while (0)
#define U8TO64_LITTLE(p) \
    (*((uint64_t *)(p)))
#define U64TO8_LITTLE(p, v) \
    do { \
      *((uint64_t *)(p)) = v; \
    } while (0)
#else
#define U8TO32_LITTLE(p) \
  (((uint32_t)((p)[0])      ) | \
   ((uint32_t)((p)[1]) <<  8) | \
   ((uint32_t)((p)[2]) << 16) | \
   ((uint32_t)((p)[3]) << 24))
#define U32TO8_LITTLE(p, v) \
  do { \
    (p)[0] = U8V((v)      ); \
    (p)[1] = U8V((v) >>  8); \
    (p)[2] = U8V((v) >> 16); \
    (p)[3] = U8V((v) >> 24); \
  } while (0)
#define U8TO64_LITTLE(p) \
  (((uint64_t)((p)[0])       ) | \
   ((uint64_t)((p)[1]) <<  8) | \
   ((uint64_t)((p)[2]) << 16) | \
   ((uint64_t)((p)[3]) << 24) | \
   ((uint64_t)((p)[4]) << 32) | \
   ((uint64_t)((p)[5]) << 40) | \
   ((uint64_t)((p)[6]) << 48) | \
   ((uint64_t)((p)[7]) << 56))
#define U64TO8_LITTLE(p, v) \
  do { \
    (p)[0] = U8V((v)       ); \
    (p)[1] = U8V((v) >>  8 ); \
    (p)[2] = U8V((v) >> 16 ); \
    (p)[3] = U8V((v) >> 24 ); \
    (p)[4] = U8V((v) >> 32 ); \
    (p)[5] = U8V((v) >> 40 ); \
    (p)[6] = U8V((v) >> 48 ); \
    (p)[7] = U8V((v) >> 56 ); \
  } while (0)
#endif
/**
 * Constant-time memory compare. This should help to protect against
 * side-channel attacks.
 *
 * \param av input 1
 * \param bv input 2
 * \param n bytes to compare
 * \return 0 if inputs are equal
 */
static int memcmp_eq(const void *av, const void *bv, int n)
{
    const unsigned char *a = (const unsigned char*) av;
    const unsigned char *b = (const unsigned char*) bv;
    unsigned char res = 0;
    int i;

    for (i = 0; i < n; i++) {
        res |= *a ^ *b;
        a++;
        b++;
    }

    return res;
}

/**
 * Poly1305 tag generation. This concatenates a string according to the rules
 * outlined in RFC 7539 and calculates the tag.
 *
 * \param poly_key 32 byte secret one-time key for poly1305
 * \param ad associated data
 * \param ad_len associated data length in bytes
 * \param ct ciphertext
 * \param ct_len ciphertext length in bytes
 * \param tag pointer to 16 bytes for tag storage
 */
static void poly1305_get_tag(unsigned char *poly_key, const void *ad,
        int ad_len, const void *ct, int ct_len, unsigned char *tag)
{
    struct __crawdog_poly1305_context poly;
    unsigned left_over;
    uint64_t len;
    unsigned char pad[16];
    unsigned char len_bytes[8];

    __crawdog_poly1305_init(&poly, poly_key);
    memset(&pad, 0, sizeof(pad)); 

    /* associated data and padding */
    __crawdog_poly1305_update(&poly, ad, ad_len);
    left_over = ad_len % 16;
    if (left_over)
        __crawdog_poly1305_update(&poly, pad, 16 - left_over);

    /* payload and padding */
    __crawdog_poly1305_update(&poly, ct, ct_len);
    left_over = ct_len % 16;
    if (left_over)
        __crawdog_poly1305_update(&poly, pad, 16 - left_over);
    
    /* lengths */
    len = ad_len;
    U64TO8_LITTLE(len_bytes, len);
    __crawdog_poly1305_update(&poly, len_bytes, 8);

    len = ct_len;
    U64TO8_LITTLE(len_bytes, len);
    __crawdog_poly1305_update(&poly, len_bytes, 8);

    __crawdog_poly1305_finish(&poly, tag);
}

int __crawdog_chachapoly_init(struct __crawdog_chachapoly_ctx *ctx, const void *key, int key_len)
{
    assert (key_len == 128 || key_len == 256);

    memset(ctx, 0, sizeof(*ctx));
    __crawdog_chacha_keysetup(&ctx->cha_ctx, key, key_len);
    return __CRAWDOG_CHACHAPOLY_OK;
}

int __crawdog_chachapoly_crypt(struct __crawdog_chachapoly_ctx *ctx, const void *nonce,
        const void *ad, int ad_len, void *input, int input_len,
        void *output, void *tag, int tag_len, int encrypt)
{
    unsigned char poly_key[__CRAWDOG_CHACHA_BLOCKLEN];
    unsigned char calc_tag[__CRAWDOG_POLY1305_TAGLEN];
    const unsigned char one[4] = { 1, 0, 0, 0 };

    /* initialize keystream and generate poly1305 key */
    memset(poly_key, 0, sizeof(poly_key));
    __crawdog_chacha_ivsetup(&ctx->cha_ctx, nonce, NULL);
    __crawdog_chacha_encrypt_bytes(&ctx->cha_ctx, poly_key, poly_key, sizeof(poly_key));

    /* check tag if decrypting */
    if (encrypt == 0 && tag_len) {
        poly1305_get_tag(poly_key, ad, ad_len, input, input_len, calc_tag);
        if (memcmp_eq(calc_tag, tag, tag_len) != 0) {
            return __CRAWDOG_CHACHAPOLY_INVALID_MAC;
        }
    }

    /* crypt data */
    __crawdog_chacha_ivsetup(&ctx->cha_ctx, nonce, one);
    __crawdog_chacha_encrypt_bytes(&ctx->cha_ctx, (unsigned char *)input,
                         (unsigned char *)output, input_len);

    /* add tag if encrypting */
    if (encrypt && tag_len) {
        poly1305_get_tag(poly_key, ad, ad_len, output, input_len, calc_tag);
        memcpy(tag, calc_tag, tag_len);
    }

    return __CRAWDOG_CHACHAPOLY_OK;
}

int __crawdog_chachapoly_crypt_short(struct __crawdog_chachapoly_ctx *ctx, const void *nonce,
        const void *ad, int ad_len, void *input, int input_len,
        void *output, void *tag, int tag_len, int encrypt)
{
    unsigned char keystream[__CRAWDOG_CHACHA_BLOCKLEN];
    unsigned char calc_tag[__CRAWDOG_POLY1305_TAGLEN];
    int i;

    assert(input_len <= 32);

    /* initialize keystream and generate poly1305 key */
    memset(keystream, 0, sizeof(keystream));
    __crawdog_chacha_ivsetup(&ctx->cha_ctx, nonce, NULL);
    __crawdog_chacha_encrypt_bytes(&ctx->cha_ctx, keystream, keystream,
            sizeof(keystream));

    /* check tag if decrypting */
    if (encrypt == 0 && tag_len) {
        poly1305_get_tag(keystream, ad, ad_len, input, input_len, calc_tag);
        if (memcmp_eq(calc_tag, tag, tag_len) != 0) {
            return __CRAWDOG_CHACHAPOLY_INVALID_MAC;
        }
    }

    /* crypt data */
    for (i = 0; i < input_len; i++) {
        ((unsigned char *)output)[i] =
            ((unsigned char *)input)[i] ^ keystream[32 + i];
    }

    /* add tag if encrypting */
    if (encrypt && tag_len) {
        poly1305_get_tag(keystream, ad, ad_len, output, input_len, calc_tag);
        memcpy(tag, calc_tag, tag_len);
    }

    return __CRAWDOG_CHACHAPOLY_OK;
}
