// MIT LICENSE
// (c) 2024 tanner silva. all rights reserved.
// Copyright (c) 2015 Grigori Goronzy <goronzy@kinoho.net>

#include <stdio.h>
#include "crawdog_chachapoly.h"
#include "testf.h"

/* AEAD test vector from RFC 7539 */
int __crawdog_chachapoly_test_rfc7539(void)
{
    unsigned char tag[16];
    unsigned char ct[114];
    int i, ret;
    struct __crawdog_chachapoly_ctx ctx;

    unsigned char key[32] = {
        0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
        0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f
    };
    unsigned char ad[12] = {
        0x50, 0x51, 0x52, 0x53, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7
    };
    unsigned char pt[114];
    memcpy(pt, "Ladies and Gentlemen of the class of '99: If I could offer you "
               "only one tip for the future, sunscreen would be it.", 114);
    unsigned char nonce[12] = {
        0x07, 0x00, 0x00, 0x00,
        0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47
    };
    unsigned char tag_verify[16] = {
        0x1a, 0xe1, 0x0b, 0x59, 0x4f, 0x09, 0xe2, 0x6a, 0x7e, 0x90, 0x2e, 0xcb, 0xd0, 0x60, 0x06, 0x91
    };
    unsigned char ct_verify[114] = {
        0xd3, 0x1a, 0x8d, 0x34, 0x64, 0x8e, 0x60, 0xdb, 0x7b, 0x86, 0xaf, 0xbc, 0x53, 0xef, 0x7e, 0xc2,
        0xa4, 0xad, 0xed, 0x51, 0x29, 0x6e, 0x08, 0xfe, 0xa9, 0xe2, 0xb5, 0xa7, 0x36, 0xee, 0x62, 0xd6,
        0x3d, 0xbe, 0xa4, 0x5e, 0x8c, 0xa9, 0x67, 0x12, 0x82, 0xfa, 0xfb, 0x69, 0xda, 0x92, 0x72, 0x8b,
        0x1a, 0x71, 0xde, 0x0a, 0x9e, 0x06, 0x0b, 0x29, 0x05, 0xd6, 0xa5, 0xb6, 0x7e, 0xcd, 0x3b, 0x36,
        0x92, 0xdd, 0xbd, 0x7f, 0x2d, 0x77, 0x8b, 0x8c, 0x98, 0x03, 0xae, 0xe3, 0x28, 0x09, 0x1b, 0x58,
        0xfa, 0xb3, 0x24, 0xe4, 0xfa, 0xd6, 0x75, 0x94, 0x55, 0x85, 0x80, 0x8b, 0x48, 0x31, 0xd7, 0xbc,
        0x3f, 0xf4, 0xde, 0xf0, 0x8e, 0x4b, 0x7a, 0x9d, 0xe5, 0x76, 0xd2, 0x65, 0x86, 0xce, 0xc6, 0x4b,
        0x61, 0x16
    };

    __crawdog_chachapoly_init(&ctx, key, 32);
    __crawdog_chachapoly_crypt(&ctx, nonce, ad, 12, pt, 114, ct, tag, 16, 1);

    for (i = 0; i < 114; i++) {
        if (ct[i] != ct_verify[i]) {
            return -2;
        }
    }

    for (i = 0; i < 16; i++) {
        if (tag[i] != tag_verify[i]) {
            return -3;
        }
    }

    ret = __crawdog_chachapoly_crypt(&ctx, nonce, ad, 12, ct, 114, pt, tag, 16, 0);

    return ret;
}

/* AEAD auth-only case */
int __crawdog_chachapoly_test_auth_only(void)
{
    unsigned char tag[16];
    int i, ret;
    struct __crawdog_chachapoly_ctx ctx;

    unsigned char key[32] = {
        0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
        0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f
    };
    unsigned char pt[114];
    memcpy(pt, "Ladies and Gentlemen of the class of '99: If I could offer you "
               "only one tip for the future, sunscreen would be it.", 114);
    unsigned char nonce[12] = {
        0x07, 0x00, 0x00, 0x00,
        0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47
    };
    unsigned char tag_verify[16] = {
        0x03, 0xDC, 0xD0, 0x84, 0x04, 0x67, 0x80, 0xE6, 0x39, 0x50, 0x67, 0x0D, 0x3B, 0xBC, 0xC8, 0x95
    };

    __crawdog_chachapoly_init(&ctx, key, 32);
    __crawdog_chachapoly_crypt(&ctx, nonce, pt, 114, NULL, 0, NULL, tag, 16, 1);

    for (i = 0; i < 16; i++) {
        if (tag[i] != tag_verify[i]) {
            return -3;
        }
    }

    ret = __crawdog_chachapoly_crypt(&ctx, nonce, pt, 114, NULL, 0, NULL, tag, 16, 0);

    return ret;
}