/* The MIT License (MIT)
 * 
 * Copyright (c) 2015 mehdi sotoodeh
 * 
 * Permission is hereby granted, free of charge, to any person obtaining 
 * a copy of this software and associated documentation files (the 
 * "Software"), to deal in the Software without restriction, including 
 * without limitation the rights to use, copy, modify, merge, publish, 
 * distribute, sublicense, and/or sell copies of the Software, and to 
 * permit persons to whom the Software is furnished to do so, subject to 
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included 
 * in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include "crawdog_external_calls.h"
#include "crawdog_curve25519_mehdi.h"
#include "curve25519_donna.h"
#include "crawdog_curve25519_dh.h"
#include "crawdog_ed25519_signature.h"

#include <stdint.h>  // For uint32_t, uint64_t

#if defined(_MSC_VER)
#include <intrin.h>
uint64_t readTSC() 
{ 
    return __rdtsc();
}
#elif defined(__aarch64__)  // ARMv8
static inline uint64_t readTSC()
{
    uint64_t tsc;
    asm volatile("mrs %0, cntvct_el0" : "=r" (tsc));
    return tsc;
}
#elif defined(__ARM_ARCH_7A__)  // ARMv7
static inline uint32_t readTSC()
{
    uint32_t value;
    // Enable the cycle counter
    uint32_t pmcr;
    asm volatile("mrc p15, 0, %0, c9, c12, 0" : "=r" (pmcr));
    pmcr |= 1;
    asm volatile("mcr p15, 0, %0, c9, c12, 0" : : "r" (pmcr));

    asm volatile("mrc p15, 0, %0, c9, c13, 0" : "=r" (value));
    return value;
}
#else
uint64_t readTSC()
{
    uint64_t tsc;
    __asm__ volatile(".byte 0x0f,0x31" : "=A" (tsc));
    return tsc;
}
#endif

void ecp_PrintBytes(IN const char *name, IN const uint8_t *data, IN U32 size)
{
    U32 i;
    printf("\nstatic const unsigned char %s[%d] =\n  { 0x%02X", name, size, *data++);
    for (i = 1; i < size; i++)
    {
        if ((i & 15) == 0)
            printf(",\n    0x%02X", *data++);
        else
            printf(",0x%02X", *data++);
    }
    printf(" };\n");
}

void ecp_PrintHexBytes(IN const char *name, IN const uint8_t *data, IN U32 size)
{
    printf("%s = 0x", name);
    while (size > 0) printf("%02X", data[--size]);
    printf("\n");
}

#ifdef WORDSIZE_64
void ecp_PrintWords(IN const char *name, IN const U64 *data, IN U32 size)
{
    U32 i;
    printf("\nstatic const U64 %s[%d] =\n  { 0x%016llX", name, size, *data++);
    for (i = 1; i < size; i++)
    {
        if ((i & 3) == 0)
            printf(",\n    0x%016llX", *data++);
        else
            printf(",0x%016llX", *data++);
    }
    printf(" };\n");
}

void ecp_PrintHexWords(IN const char *name, IN const U64 *data, IN U32 size)
{
    printf("%s = 0x", name);
    while (size > 0) printf("%016llX", data[--size]);
    printf("\n");
}
#else
void ecp_PrintWords(IN const char *name, IN const U32 *data, IN U32 size)
{
    U32 i;
    printf("\nstatic const U32 %s[%d] = \n  { 0x%08X", name, size, *data++);
    for (i = 1; i < size; i++)
    {
        if ((i & 3) == 0)
            printf(",\n    0x%08X", *data++);
        else
            printf(",0x%08X", *data++);
    }
    printf(" };\n");
}

void ecp_PrintHexWords(IN const char *name, IN const U32 *data, IN U32 size)
{
    printf("%s = 0x", name);
    while (size > 0) printf("%08X", data[--size]);
    printf("\n");
}
#endif

/* Needed for donna */
extern void ecp_TrimSecretKey(uint8_t *X);
const unsigned char BasePoint[32] = {9};

unsigned char secret_blind[32] =
{
    0xea,0x30,0xb1,0x6d,0x83,0x9e,0xa3,0x1a,0x86,0x34,0x01,0x9d,0x4a,0xf3,0x36,0x93,
    0x6d,0x54,0x2b,0xa1,0x63,0x03,0x93,0x85,0xcc,0x03,0x0a,0x7d,0xe1,0xae,0xa7,0xbb
};

int speed_test(int loops)
{
    U64 t1, t2, tovr = 0, td = (U64)(-1), tm = (U64)(-1);
    uint8_t secret_key[32], donna_publickey[32], mehdi_publickey[32];
    unsigned char pubkey[32], privkey[64], sig[64];
    void *ver_context = 0;
    void *blinding = 0;
    int i;

    /* generate key */
    mem_fill(secret_key, 0x42, 32);
    ecp_TrimSecretKey(secret_key);

    /* Make sure both generate identical public key */
    curve25519_donna(donna_publickey, secret_key, BasePoint);
    __crawdog_curve25519_calculate_public_key(mehdi_publickey, secret_key);

    if (memcmp(mehdi_publickey, donna_publickey, 32) != 0)
    {
        ecp_PrintHexBytes("sk", secret_key, 32);
        ecp_PrintHexBytes("mehdi_pk", mehdi_publickey, 32);
        ecp_PrintHexBytes("donna_pk", donna_publickey, 32);
        return 1;
    }

    /* Timing values that we measure includes some random CPU activity overhead */
    /* We try to get the minimum time as the more accurate time */

    t1 = readTSC();
    tovr = readTSC() - t1; /* t2-t1 = readTSC() overhead */
    for (i = 0; i < 100; i++)
    {
        t1 = readTSC();
        t2 = readTSC() - t1; /* t2-t1 = readTSC() overhead */
        if (t2 < tovr) tovr = t2;
    }

    /* --------------------------------------------------------------------- */
    /* Go Donna, go  */
    /* --------------------------------------------------------------------- */
    for (i = 0; i < loops; ++i) 
    {
        t1 = readTSC();
        curve25519_donna(donna_publickey, secret_key, BasePoint);
        t2 = readTSC() - t1;
        if (t2 < td) td = t2;
    }
    td -= tovr;

    /* --------------------------------------------------------------------- */
    /* Ready, set, go  */
    /* --------------------------------------------------------------------- */
    for (i = 0; i < loops; i++)
    {
        t1 = readTSC();
        __crawdog_curve25519_calculate_public_key(mehdi_publickey, secret_key);
        t2 = readTSC() - t1;
        if (t2 < tm) tm = t2;
    }
    tm -= tovr;

    /* --------------------------------------------------------------------- */
    /* Faster implementation using folding of 8 */
    /* --------------------------------------------------------------------- */
    for (i = 0; i < loops; i++)
    {
        t1 = readTSC();
        __crawdog_curve25519_calculate_public_key(mehdi_publickey, secret_key);
        t2 = readTSC() - t1;
        if (t2 < tm) tm = t2;
    }
    tm -= tovr;

    /* --------------------------------------------------------------------- */
    /* Speed measurement for ed25519 keygen, sign and verify */
    /* --------------------------------------------------------------------- */
    tm = (U64)(-1);
    for (i = 0; i < loops; i++)
    {
        t1 = readTSC();
        __crawdog_ed25519_create_keypair(pubkey, privkey, 0, secret_key);
        t2 = readTSC() - t1;
        if (t2 < tm) tm = t2;
    }
    tm -= tovr;

    /* --------------------------------------------------------------------- */
    tm = (U64)(-1);
    for (i = 0; i < loops; i++)
    {
        t1 = readTSC();
        __crawdog_ed25519_sign_message(sig, privkey, 0, (const unsigned char*)"abc", 3);
        t2 = readTSC() - t1;
        if (t2 < tm) tm = t2;
    }
    tm -= tovr;

    /* --------------------------------------------------------------------- */
    /* Speed measurement for ed25519 keygen, sign using blinding */
    /* --------------------------------------------------------------------- */
    blinding = __crawdog_ed25519_blinding_init(blinding, secret_blind, sizeof(secret_blind));

    tm = (U64)(-1);
    for (i = 0; i < loops; i++)
    {
        t1 = readTSC();
        __crawdog_ed25519_create_keypair(pubkey, privkey, blinding, secret_key);
        t2 = readTSC() - t1;
        if (t2 < tm) tm = t2;
    }
    tm -= tovr;

    /* --------------------------------------------------------------------- */
    tm = (U64)(-1);
    for (i = 0; i < loops; i++)
    {
        t1 = readTSC();
        __crawdog_ed25519_sign_message(sig, privkey, blinding, (const unsigned char*)"abc", 3);
        t2 = readTSC() - t1;
        if (t2 < tm) tm = t2;
    }
    tm -= tovr;

    __crawdog_ed25519_blinding_finish(blinding);

    /* --------------------------------------------------------------------- */
    tm = (U64)(-1);
    for (i = 0; i < loops; i++)
    {
        t1 = readTSC();
        __crawdog_ed25519_verify_signature(sig, pubkey, (const unsigned char*)"abc", 3);
        t2 = readTSC() - t1;
        if (t2 < tm) tm = t2;
    }
    tm -= tovr;

    /* --------------------------------------------------------------------- */
    tm = (U64)(-1);
    for (i = 0; i < loops; i++)
    {
        t1 = readTSC();
        ver_context = __crawdog_ed25519_verify_init(ver_context, pubkey);
        t2 = readTSC() - t1;
        if (t2 < tm) tm = t2;
    }
    tm -= tovr;

    /* --------------------------------------------------------------------- */
    tm = (U64)(-1);
    for (i = 0; i < loops; i++)
    {
        t1 = readTSC();
        __crawdog_ed25519_verify_check(ver_context, sig, (const unsigned char*)"abc", 3);
        t2 = readTSC() - t1;
        if (t2 < tm) tm = t2;
    }
    tm -= tovr;

    __crawdog_ed25519_verify_finish(ver_context);

    return 0;
}

int signature_test(
    const unsigned char *sk, 
    const unsigned char *expected_pk, 
    const unsigned char *msg, size_t size, 
    const unsigned char *expected_sig)
{
    int rc = 0;
    unsigned char sig[__CRAWDOG_ED25519_SIGNATURE_SIZE];
    unsigned char pubKey[__CRAWDOG_ED25519_PUBLIC_KEY_SIZE];
    unsigned char privKey[__CRAWDOG_ED25519_PRIVATE_KEY_SIZE];
    void *blinding = __crawdog_ed25519_blinding_init(0, secret_blind, sizeof(secret_blind));

    printf("\n-- ed25519 -- sign/verify test ---------------------------------\n");
    printf("\n-- CreateKeyPair --\n");
    __crawdog_ed25519_create_keypair(pubKey, privKey, 0, sk);
    ecp_PrintHexBytes("secret_key", sk, __CRAWDOG_ED25519_SECRET_KEY_SIZE);
    ecp_PrintHexBytes("public_key", pubKey, __CRAWDOG_ED25519_PUBLIC_KEY_SIZE);
    ecp_PrintBytes("private_key", privKey, __CRAWDOG_ED25519_PRIVATE_KEY_SIZE);

    if (expected_pk && memcmp(pubKey, expected_pk, __CRAWDOG_ED25519_PUBLIC_KEY_SIZE) != 0)
    {
        rc++;
        printf("__crawdog_ed25519_create_keypair() FAILED!!\n");
        ecp_PrintHexBytes("Expected_pk", expected_pk, __CRAWDOG_ED25519_PUBLIC_KEY_SIZE);
    }

    printf("-- Sign/Verify --\n");
    __crawdog_ed25519_sign_message(sig, privKey, 0, msg, size);
    ecp_PrintBytes("message", msg, (U32)size);
    ecp_PrintBytes("signature", sig, __CRAWDOG_ED25519_SIGNATURE_SIZE);
    if (expected_sig && memcmp(sig, expected_sig, __CRAWDOG_ED25519_SIGNATURE_SIZE) != 0)
    {
        rc++;
        printf("Signature generation FAILED!!\n");
        ecp_PrintBytes("Calculated", sig, __CRAWDOG_ED25519_SIGNATURE_SIZE);
        ecp_PrintBytes("ExpectedSig", expected_sig, __CRAWDOG_ED25519_SIGNATURE_SIZE);
    }

    if (!__crawdog_ed25519_verify_signature(sig, pubKey, msg, size))
    {
        rc++;
        printf("Signature verification FAILED!!\n");
        ecp_PrintBytes("sig", sig, __CRAWDOG_ED25519_SIGNATURE_SIZE);
        ecp_PrintBytes("pk", pubKey, __CRAWDOG_ED25519_PUBLIC_KEY_SIZE);
    }

    printf("\n-- ed25519 -- sign/verify test w/blinding ----------------------\n");
    printf("\n-- CreateKeyPair --\n");
    __crawdog_ed25519_create_keypair(pubKey, privKey, blinding, sk);
    ecp_PrintHexBytes("secret_key", sk, __CRAWDOG_ED25519_SECRET_KEY_SIZE);
    ecp_PrintHexBytes("public_key", pubKey, __CRAWDOG_ED25519_PUBLIC_KEY_SIZE);
    ecp_PrintBytes("private_key", privKey, __CRAWDOG_ED25519_PRIVATE_KEY_SIZE);

    if (expected_pk && memcmp(pubKey, expected_pk, __CRAWDOG_ED25519_PUBLIC_KEY_SIZE) != 0)
    {
        rc++;
        printf("__crawdog_ed25519_create_keypair() FAILED!!\n");
        ecp_PrintHexBytes("Expected_pk", expected_pk, __CRAWDOG_ED25519_PUBLIC_KEY_SIZE);
    }

    printf("-- Sign/Verify --\n");
    __crawdog_ed25519_sign_message(sig, privKey, blinding, msg, size);
    ecp_PrintBytes("message", msg, (U32)size);
    ecp_PrintBytes("signature", sig, __CRAWDOG_ED25519_SIGNATURE_SIZE);
    if (expected_sig && memcmp(sig, expected_sig, __CRAWDOG_ED25519_SIGNATURE_SIZE) != 0)
    {
        rc++;
        printf("Signature generation FAILED!!\n");
        ecp_PrintBytes("Calculated", sig, __CRAWDOG_ED25519_SIGNATURE_SIZE);
        ecp_PrintBytes("ExpectedSig", expected_sig, __CRAWDOG_ED25519_SIGNATURE_SIZE);
    }

    if (!__crawdog_ed25519_verify_signature(sig, pubKey, msg, size))
    {
        rc++;
        printf("Signature verification FAILED!!\n");
        ecp_PrintBytes("sig", sig, __CRAWDOG_ED25519_SIGNATURE_SIZE);
        ecp_PrintBytes("pk", pubKey, __CRAWDOG_ED25519_PUBLIC_KEY_SIZE);
    }

    if (rc == 0)
    {
        printf("  ++ Signature Verified Successfully. ++\n");
    }

    __crawdog_ed25519_blinding_finish(blinding);
    return rc;
}

unsigned char sk1[32] = 
  { 0x4c,0xcd,0x08,0x9b,0x28,0xff,0x96,0xda,0x9d,0xb6,0xc3,0x46,0xec,0x11,0x4e,0x0f,
    0x5b,0x8a,0x31,0x9f,0x35,0xab,0xa6,0x24,0xda,0x8c,0xf6,0xed,0x4f,0xb8,0xa6,0xfb };
unsigned char pk1[__CRAWDOG_ED25519_PUBLIC_KEY_SIZE] = 
  { 0x3d,0x40,0x17,0xc3,0xe8,0x43,0x89,0x5a,0x92,0xb7,0x0a,0xa7,0x4d,0x1b,0x7e,0xbc,
    0x9c,0x98,0x2c,0xcf,0x2e,0xc4,0x96,0x8c,0xc0,0xcd,0x55,0xf1,0x2a,0xf4,0x66,0x0c };
unsigned char msg1[] = { 0x72 };
unsigned char msg1_sig[__CRAWDOG_ED25519_SIGNATURE_SIZE] = {
    0x92,0xa0,0x09,0xa9,0xf0,0xd4,0xca,0xb8,0x72,0x0e,0x82,0x0b,0x5f,0x64,0x25,0x40,
    0xa2,0xb2,0x7b,0x54,0x16,0x50,0x3f,0x8f,0xb3,0x76,0x22,0x23,0xeb,0xdb,0x69,0xda,
    0x08,0x5a,0xc1,0xe4,0x3e,0x15,0x99,0x6e,0x45,0x8f,0x36,0x13,0xd0,0xf1,0x1d,0x8c,
    0x38,0x7b,0x2e,0xae,0xb4,0x30,0x2a,0xee,0xb0,0x0d,0x29,0x16,0x12,0xbb,0x0c,0x00
};

int curve25519_SelfTest(int level);
int ed25519_selftest();

int dh_test()
{
    int rc = 0;
    unsigned char alice_public_key[32], alice_shared_key[32];
    unsigned char bruce_public_key[32], bruce_shared_key[32];

    unsigned char alice_secret_key[32] = { /* #1234 */
        0x03,0xac,0x67,0x42,0x16,0xf3,0xe1,0x5c,
        0x76,0x1e,0xe1,0xa5,0xe2,0x55,0xf0,0x67,
        0x95,0x36,0x23,0xc8,0xb3,0x88,0xb4,0x45,
        0x9e,0x13,0xf9,0x78,0xd7,0xc8,0x46,0xf4 };

    unsigned char bruce_secret_key[32] = { /* #abcd */
        0x88,0xd4,0x26,0x6f,0xd4,0xe6,0x33,0x8d,
        0x13,0xb8,0x45,0xfc,0xf2,0x89,0x57,0x9d,
        0x20,0x9c,0x89,0x78,0x23,0xb9,0x21,0x7d,
        0xa3,0xe1,0x61,0x93,0x6f,0x03,0x15,0x89 };

    printf("\n-- curve25519 -- key exchange test -----------------------------\n");
    /* Step 1. Alice and Bruce generate their own random secret keys */

    ecp_PrintHexBytes("Alice_secret_key", alice_secret_key, 32);
    ecp_PrintHexBytes("Bruce_secret_key", bruce_secret_key, 32);

    /* Step 2. Alice and Bruce create public keys associated with their secret keys */
    /*         and exchange their public keys */
	__crawdog_curve25519_forge_private_key(alice_secret_key);
	__crawdog_curve25519_forge_private_key(bruce_secret_key);
    __crawdog_curve25519_calculate_public_key(alice_public_key, alice_secret_key);
    __crawdog_curve25519_calculate_public_key(bruce_public_key, bruce_secret_key);
    ecp_PrintHexBytes("Alice_public_key", alice_public_key, 32);
    ecp_PrintHexBytes("Bruce_public_key", bruce_public_key, 32);

    /* Step 3. Alice and Bruce create their shared key */

    __crawdog_curve25519_calculate_shared_key(alice_shared_key, bruce_public_key, alice_secret_key);
    __crawdog_curve25519_calculate_shared_key(bruce_shared_key, alice_public_key, bruce_secret_key);
    ecp_PrintHexBytes("Alice_shared", alice_shared_key, 32);
    ecp_PrintHexBytes("Bruce_shared", bruce_shared_key, 32);

    /* Alice and Bruce should end up with idetntical keys */
    if (memcmp(alice_shared_key, bruce_shared_key, 32) != 0)
    {
        rc++;
        printf("DH key exchange FAILED!!\n");
    }
    return rc;
}

int allTestsRelatedTo25519(int argc, char**argv)
{
    int rc = 0;

#ifdef ECP_SELF_TEST
    if (curve25519_SelfTest(0))
    {
        printf("\n*********** curve25519 selftest FAILED!! ******************\n");
        return 1;
    }
    if (ed25519_selftest())
    {
        printf("\n*********** ed25519 selftest FAILED!! ********************\n");
        return 1;
    }
#endif

    rc += dh_test();

    rc += signature_test(sk1, pk1, msg1, sizeof(msg1), msg1_sig);

    speed_test(1000);

    return rc;
}