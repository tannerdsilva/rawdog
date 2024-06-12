// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include "crawdog_md5.h"
#include "crawdog_sha1.h"
#include "crawdog_sha512.h"
#include "crawdog_sha256.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TYPES
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define MAX_PLAINTEXT_SIZE      100

typedef struct
{
    char            PlainText [MAX_PLAINTEXT_SIZE];
    uint32_t        PlainTextSize;                      // 0 to use (uint32_t)strlen
    MD5_HASH        Md5Hash;
    SHA1_HASH       Sha1Hash;
    SHA256_HASH     Sha256Hash;
    SHA512_HASH     Sha512Hash;
} TestVector;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  GLOBALS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static TestVector gTestVectors [] =
{
    {
        "", 0,
        {{0xd4,0x1d,0x8c,0xd9,0x8f,0x00,0xb2,0x04,0xe9,0x80,0x09,0x98,0xec,0xf8,0x42,0x7e}},  // md5
        {{0xda,0x39,0xa3,0xee,0x5e,0x6b,0x4b,0x0d,0x32,0x55,0xbf,0xef,0x95,0x60,0x18,0x90,0xaf,0xd8,0x07,0x09}},  // sha1
        {{0xe3,0xb0,0xc4,0x42,0x98,0xfc,0x1c,0x14,0x9a,0xfb,0xf4,0xc8,0x99,0x6f,0xb9,0x24,
          0x27,0xae,0x41,0xe4,0x64,0x9b,0x93,0x4c,0xa4,0x95,0x99,0x1b,0x78,0x52,0xb8,0x55}},  // sha256
        {{0xcf,0x83,0xe1,0x35,0x7e,0xef,0xb8,0xbd,0xf1,0x54,0x28,0x50,0xd6,0x6d,0x80,0x07,
          0xd6,0x20,0xe4,0x05,0x0b,0x57,0x15,0xdc,0x83,0xf4,0xa9,0x21,0xd3,0x6c,0xe9,0xce,
          0x47,0xd0,0xd1,0x3c,0x5d,0x85,0xf2,0xb0,0xff,0x83,0x18,0xd2,0x87,0x7e,0xec,0x2f,
          0x63,0xb9,0x31,0xbd,0x47,0x41,0x7a,0x81,0xa5,0x38,0x32,0x7a,0xf9,0x27,0xda,0x3e}},  // sha512
    },
    {
        "a", 0,
        {{0x0c,0xc1,0x75,0xb9,0xc0,0xf1,0xb6,0xa8,0x31,0xc3,0x99,0xe2,0x69,0x77,0x26,0x61}},  // md5
        {{0x86,0xf7,0xe4,0x37,0xfa,0xa5,0xa7,0xfc,0xe1,0x5d,0x1d,0xdc,0xb9,0xea,0xea,0xea,0x37,0x76,0x67,0xb8}},  // sha1
        {{0xca,0x97,0x81,0x12,0xca,0x1b,0xbd,0xca,0xfa,0xc2,0x31,0xb3,0x9a,0x23,0xdc,0x4d,
         0xa7,0x86,0xef,0xf8,0x14,0x7c,0x4e,0x72,0xb9,0x80,0x77,0x85,0xaf,0xee,0x48,0xbb}},  // sha256
        {{0x1f,0x40,0xfc,0x92,0xda,0x24,0x16,0x94,0x75,0x09,0x79,0xee,0x6c,0xf5,0x82,0xf2,
         0xd5,0xd7,0xd2,0x8e,0x18,0x33,0x5d,0xe0,0x5a,0xbc,0x54,0xd0,0x56,0x0e,0x0f,0x53,
         0x02,0x86,0x0c,0x65,0x2b,0xf0,0x8d,0x56,0x02,0x52,0xaa,0x5e,0x74,0x21,0x05,0x46,
         0xf3,0x69,0xfb,0xbb,0xce,0x8c,0x12,0xcf,0xc7,0x95,0x7b,0x26,0x52,0xfe,0x9a,0x75}},  // sha512
    },
    {
        "aaa", 0,
        {{0x47,0xbc,0xe5,0xc7,0x4f,0x58,0x9f,0x48,0x67,0xdb,0xd5,0x7e,0x9c,0xa9,0xf8,0x08}},  // md5
        {{0x7e,0x24,0x0d,0xe7,0x4f,0xb1,0xed,0x08,0xfa,0x08,0xd3,0x80,0x63,0xf6,0xa6,0xa9,0x14,0x62,0xa8,0x15}},  // sha1
        {{0x98,0x34,0x87,0x6d,0xcf,0xb0,0x5c,0xb1,0x67,0xa5,0xc2,0x49,0x53,0xeb,0xa5,0x8c,
          0x4a,0xc8,0x9b,0x1a,0xdf,0x57,0xf2,0x8f,0x2f,0x9d,0x09,0xaf,0x10,0x7e,0xe8,0xf0}},  // sha256
        {{0xd6,0xf6,0x44,0xb1,0x98,0x12,0xe9,0x7b,0x5d,0x87,0x16,0x58,0xd6,0xd3,0x40,0x0e,
          0xcd,0x47,0x87,0xfa,0xeb,0x9b,0x89,0x90,0xc1,0xe7,0x60,0x82,0x88,0x66,0x4b,0xe7,
          0x72,0x57,0x10,0x4a,0x58,0xd0,0x33,0xbc,0xf1,0xa0,0xe0,0x94,0x5f,0xf0,0x64,0x68,
          0xeb,0xe5,0x3e,0x2d,0xff,0x36,0xe2,0x48,0x42,0x4c,0x72,0x73,0x11,0x7d,0xac,0x09}},  // sha512
    },
    {
        "abc", 0,
        {{0x90,0x01,0x50,0x98,0x3c,0xd2,0x4f,0xb0,0xd6,0x96,0x3f,0x7d,0x28,0xe1,0x7f,0x72}},  // md5
        {{0xa9,0x99,0x3e,0x36,0x47,0x06,0x81,0x6a,0xba,0x3e,0x25,0x71,0x78,0x50,0xc2,0x6c,0x9c,0xd0,0xd8,0x9d}},  // sha1
        {{0xba,0x78,0x16,0xbf,0x8f,0x01,0xcf,0xea,0x41,0x41,0x40,0xde,0x5d,0xae,0x22,0x23,
          0xb0,0x03,0x61,0xa3,0x96,0x17,0x7a,0x9c,0xb4,0x10,0xff,0x61,0xf2,0x00,0x15,0xad}},  // sha256
        {{0xdd,0xaf,0x35,0xa1,0x93,0x61,0x7a,0xba,0xcc,0x41,0x73,0x49,0xae,0x20,0x41,0x31,
          0x12,0xe6,0xfa,0x4e,0x89,0xa9,0x7e,0xa2,0x0a,0x9e,0xee,0xe6,0x4b,0x55,0xd3,0x9a,
          0x21,0x92,0x99,0x2a,0x27,0x4f,0xc1,0xa8,0x36,0xba,0x3c,0x23,0xa3,0xfe,0xeb,0xbd,
          0x45,0x4d,0x44,0x23,0x64,0x3c,0xe8,0x0e,0x2a,0x9a,0xc9,0x4f,0xa5,0x4c,0xa4,0x9f}},  // sha512
    },
    {
        "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", 0,
        {{0x82,0x15,0xef,0x07,0x96,0xa2,0x0b,0xca,0xaa,0xe1,0x16,0xd3,0x87,0x6c,0x66,0x4a}},  // md5
        {{0x84,0x98,0x3e,0x44,0x1c,0x3b,0xd2,0x6e,0xba,0xae,0x4a,0xa1,0xf9,0x51,0x29,0xe5,0xe5,0x46,0x70,0xf1}},  // sha1
        {{0x24,0x8d,0x6a,0x61,0xd2,0x06,0x38,0xb8,0xe5,0xc0,0x26,0x93,0x0c,0x3e,0x60,0x39,
          0xa3,0x3c,0xe4,0x59,0x64,0xff,0x21,0x67,0xf6,0xec,0xed,0xd4,0x19,0xdb,0x06,0xc1}},  // sha256
        {{0x20,0x4a,0x8f,0xc6,0xdd,0xa8,0x2f,0x0a,0x0c,0xed,0x7b,0xeb,0x8e,0x08,0xa4,0x16,
          0x57,0xc1,0x6e,0xf4,0x68,0xb2,0x28,0xa8,0x27,0x9b,0xe3,0x31,0xa7,0x03,0xc3,0x35,
          0x96,0xfd,0x15,0xc1,0x3b,0x1b,0x07,0xf9,0xaa,0x1d,0x3b,0xea,0x57,0x78,0x9c,0xa0,
          0x31,0xad,0x85,0xc7,0xa7,0x1d,0xd7,0x03,0x54,0xec,0x63,0x12,0x38,0xca,0x34,0x45}},  // sha512
    },
    {
        "The quick brown fox jumps over the lazy dog", 0,
        {{0x9e,0x10,0x7d,0x9d,0x37,0x2b,0xb6,0x82,0x6b,0xd8,0x1d,0x35,0x42,0xa4,0x19,0xd6}},  // md5
        {{0x2f,0xd4,0xe1,0xc6,0x7a,0x2d,0x28,0xfc,0xed,0x84,0x9e,0xe1,0xbb,0x76,0xe7,0x39,0x1b,0x93,0xeb,0x12}},  // sha1
        {{0xd7,0xa8,0xfb,0xb3,0x07,0xd7,0x80,0x94,0x69,0xca,0x9a,0xbc,0xb0,0x08,0x2e,0x4f,
          0x8d,0x56,0x51,0xe4,0x6d,0x3c,0xdb,0x76,0x2d,0x02,0xd0,0xbf,0x37,0xc9,0xe5,0x92}},  // sha256
        {{0x07,0xe5,0x47,0xd9,0x58,0x6f,0x6a,0x73,0xf7,0x3f,0xba,0xc0,0x43,0x5e,0xd7,0x69,
          0x51,0x21,0x8f,0xb7,0xd0,0xc8,0xd7,0x88,0xa3,0x09,0xd7,0x85,0x43,0x6b,0xbb,0x64,
          0x2e,0x93,0xa2,0x52,0xa9,0x54,0xf2,0x39,0x12,0x54,0x7d,0x1e,0x8a,0x3b,0x5e,0xd6,
          0xe1,0xbf,0xd7,0x09,0x78,0x21,0x23,0x3f,0xa0,0x53,0x8f,0x3d,0xb8,0x54,0xfe,0xe6}},  // sha512
    },
    {
        "The quick brown fox jumps over the lazy dog.", 0,
        {{0xe4,0xd9,0x09,0xc2,0x90,0xd0,0xfb,0x1c,0xa0,0x68,0xff,0xad,0xdf,0x22,0xcb,0xd0}},  // md5
        {{0x40,0x8d,0x94,0x38,0x42,0x16,0xf8,0x90,0xff,0x7a,0x0c,0x35,0x28,0xe8,0xbe,0xd1,0xe0,0xb0,0x16,0x21}},  // sha1
        {{0xef,0x53,0x7f,0x25,0xc8,0x95,0xbf,0xa7,0x82,0x52,0x65,0x29,0xa9,0xb6,0x3d,0x97,
          0xaa,0x63,0x15,0x64,0xd5,0xd7,0x89,0xc2,0xb7,0x65,0x44,0x8c,0x86,0x35,0xfb,0x6c}},  // sha256
        {{0x91,0xea,0x12,0x45,0xf2,0x0d,0x46,0xae,0x9a,0x03,0x7a,0x98,0x9f,0x54,0xf1,0xf7,
          0x90,0xf0,0xa4,0x76,0x07,0xee,0xb8,0xa1,0x4d,0x12,0x89,0x0c,0xea,0x77,0xa1,0xbb,
          0xc6,0xc7,0xed,0x9c,0xf2,0x05,0xe6,0x7b,0x7f,0x2b,0x8f,0xd4,0xc7,0xdf,0xd3,0xa7,
          0xa8,0x61,0x7e,0x45,0xf3,0xc4,0x63,0xd4,0x81,0xc7,0xe5,0x86,0xc3,0x9a,0xc1,0xed}},  // sha512
    },
    {
        "message digest", 0,
        {{0xf9,0x6b,0x69,0x7d,0x7c,0xb7,0x93,0x8d,0x52,0x5a,0x2f,0x31,0xaa,0xf1,0x61,0xd0}},  // md5
        {{0xc1,0x22,0x52,0xce,0xda,0x8b,0xe8,0x99,0x4d,0x5f,0xa0,0x29,0x0a,0x47,0x23,0x1c,0x1d,0x16,0xaa,0xe3}},  // sha1
        {{0xf7,0x84,0x6f,0x55,0xcf,0x23,0xe1,0x4e,0xeb,0xea,0xb5,0xb4,0xe1,0x55,0x0c,0xad,
          0x5b,0x50,0x9e,0x33,0x48,0xfb,0xc4,0xef,0xa3,0xa1,0x41,0x3d,0x39,0x3c,0xb6,0x50}},  // sha256
        {{0x10,0x7d,0xbf,0x38,0x9d,0x9e,0x9f,0x71,0xa3,0xa9,0x5f,0x6c,0x05,0x5b,0x92,0x51,
          0xbc,0x52,0x68,0xc2,0xbe,0x16,0xd6,0xc1,0x34,0x92,0xea,0x45,0xb0,0x19,0x9f,0x33,
          0x09,0xe1,0x64,0x55,0xab,0x1e,0x96,0x11,0x8e,0x8a,0x90,0x5d,0x55,0x97,0xb7,0x20,
          0x38,0xdd,0xb3,0x72,0xa8,0x98,0x26,0x04,0x6d,0xe6,0x66,0x87,0xbb,0x42,0x0e,0x7c}},  // sha512
    },
    {
        "abcdefghijklmnopqrstuvwxyz", 0,
        {{0xc3,0xfc,0xd3,0xd7,0x61,0x92,0xe4,0x00,0x7d,0xfb,0x49,0x6c,0xca,0x67,0xe1,0x3b}},  // md5
        {{0x32,0xd1,0x0c,0x7b,0x8c,0xf9,0x65,0x70,0xca,0x04,0xce,0x37,0xf2,0xa1,0x9d,0x84,0x24,0x0d,0x3a,0x89}},  // sha1
        {{0x71,0xc4,0x80,0xdf,0x93,0xd6,0xae,0x2f,0x1e,0xfa,0xd1,0x44,0x7c,0x66,0xc9,0x52,
          0x5e,0x31,0x62,0x18,0xcf,0x51,0xfc,0x8d,0x9e,0xd8,0x32,0xf2,0xda,0xf1,0x8b,0x73}},  // sha256
        {{0x4d,0xbf,0xf8,0x6c,0xc2,0xca,0x1b,0xae,0x1e,0x16,0x46,0x8a,0x05,0xcb,0x98,0x81,
          0xc9,0x7f,0x17,0x53,0xbc,0xe3,0x61,0x90,0x34,0x89,0x8f,0xaa,0x1a,0xab,0xe4,0x29,
          0x95,0x5a,0x1b,0xf8,0xec,0x48,0x3d,0x74,0x21,0xfe,0x3c,0x16,0x46,0x61,0x3a,0x59,
          0xed,0x54,0x41,0xfb,0x0f,0x32,0x13,0x89,0xf7,0x7f,0x48,0xa8,0x79,0xc7,0xb1,0xf1}},  // sha512
    },
    {
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", 0,
        {{0xd1,0x74,0xab,0x98,0xd2,0x77,0xd9,0xf5,0xa5,0x61,0x1c,0x2c,0x9f,0x41,0x9d,0x9f}},  // md5
        {{0x76,0x1c,0x45,0x7b,0xf7,0x3b,0x14,0xd2,0x7e,0x9e,0x92,0x65,0xc4,0x6f,0x4b,0x4d,0xda,0x11,0xf9,0x40}},  // sha1
        {{0xdb,0x4b,0xfc,0xbd,0x4d,0xa0,0xcd,0x85,0xa6,0x0c,0x3c,0x37,0xd3,0xfb,0xd8,0x80,
          0x5c,0x77,0xf1,0x5f,0xc6,0xb1,0xfd,0xfe,0x61,0x4e,0xe0,0xa7,0xc8,0xfd,0xb4,0xc0}},  // sha256
        {{0x1e,0x07,0xbe,0x23,0xc2,0x6a,0x86,0xea,0x37,0xea,0x81,0x0c,0x8e,0xc7,0x80,0x93,
          0x52,0x51,0x5a,0x97,0x0e,0x92,0x53,0xc2,0x6f,0x53,0x6c,0xfc,0x7a,0x99,0x96,0xc4,
          0x5c,0x83,0x70,0x58,0x3e,0x0a,0x78,0xfa,0x4a,0x90,0x04,0x1d,0x71,0xa4,0xce,0xab,
          0x74,0x23,0xf1,0x9c,0x71,0xb9,0xd5,0xa3,0xe0,0x12,0x49,0xf0,0xbe,0xbd,0x58,0x94}},  // sha512
    },
    {   "12345678901234567890123456789012345678901234567890123456789012345678901234567890", 0,
        {{0x57,0xed,0xf4,0xa2,0x2b,0xe3,0xc9,0x55,0xac,0x49,0xda,0x2e,0x21,0x07,0xb6,0x7a}},  // md5
        {{0x50,0xab,0xf5,0x70,0x6a,0x15,0x09,0x90,0xa0,0x8b,0x2c,0x5e,0xa4,0x0f,0xa0,0xe5,0x85,0x55,0x47,0x32}},  // sha1
        {{0xf3,0x71,0xbc,0x4a,0x31,0x1f,0x2b,0x00,0x9e,0xef,0x95,0x2d,0xd8,0x3c,0xa8,0x0e,
          0x2b,0x60,0x02,0x6c,0x8e,0x93,0x55,0x92,0xd0,0xf9,0xc3,0x08,0x45,0x3c,0x81,0x3e}},  // sha256
        {{0x72,0xec,0x1e,0xf1,0x12,0x4a,0x45,0xb0,0x47,0xe8,0xb7,0xc7,0x5a,0x93,0x21,0x95,
          0x13,0x5b,0xb6,0x1d,0xe2,0x4e,0xc0,0xd1,0x91,0x40,0x42,0x24,0x6e,0x0a,0xec,0x3a,
          0x23,0x54,0xe0,0x93,0xd7,0x6f,0x30,0x48,0xb4,0x56,0x76,0x43,0x46,0x90,0x0c,0xb1,
          0x30,0xd2,0xa4,0xfd,0x5d,0xd1,0x6a,0xbb,0x5e,0x30,0xbc,0xb8,0x50,0xde,0xe8,0x43}},  // sha512
    },

};
#define NUM_TEST_VECTORS ( sizeof(gTestVectors) / sizeof(gTestVectors[0]) )

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  PRIVATE FUNCTIONS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TestMd5
//
//  Test MD5 algorithm against test vectors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static
bool
    TestMd5
    (
        void
    )
{
    uint32_t    i;
    uint32_t    k;
    uint32_t    len;
    __crawdog_md5_context  context;
    MD5_HASH    hash;
    bool        success = true;

    for( i=0; i<NUM_TEST_VECTORS; i++ )
    {
        __crawdog_md5_init( &context );
        len = (uint32_t) gTestVectors[i].PlainTextSize ? gTestVectors[i].PlainTextSize : (uint32_t)strlen( gTestVectors[i].PlainText );
        __crawdog_md5_update( &context, gTestVectors[i].PlainText, (uint32_t)len );
        __crawdog_md5_finish( &context, &hash );

        if( memcmp( &hash, &gTestVectors[i].Md5Hash, sizeof(hash) ) == 0 )
        {
            // Test vector passed
        }
        else
        {
            printf( "TestMd5 - Test vector %u failed\n", i );
            success = false;
        }
    }

    // Check the vectors again, this time adding just 1 char at a time to the hash functions
    for( i=0; i<NUM_TEST_VECTORS; i++ )
    {
        __crawdog_md5_init( &context );
        len = (uint32_t) gTestVectors[i].PlainTextSize ? gTestVectors[i].PlainTextSize : (uint32_t)strlen( gTestVectors[i].PlainText );
        for( k=0; k<len; k++ )
        {
            __crawdog_md5_update( &context, &gTestVectors[i].PlainText[k], 1 );
        }
        __crawdog_md5_finish( &context, &hash );

        if( memcmp( &hash, &gTestVectors[i].Md5Hash, sizeof(hash) ) == 0 )
        {
            // Test vector passed
        }
        else
        {
            printf( "TestMd5 - Test vector %u failed [byte by byte]\n", i );
            success = false;
        }
    }

    return success;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TestSha1
//
//  Test SHA1 algorithm against test vectors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static
bool
    TestSha1
    (
        void
    )
{
    uint32_t    i;
    uint32_t    k;
    uint32_t    len;
    __crawdog_sha1_context context;
    SHA1_HASH   hash;
    bool        success = true;

    for( i=0; i<NUM_TEST_VECTORS; i++ )
    {
        __crawdog_sha1_init( &context );
        len = (uint32_t) gTestVectors[i].PlainTextSize ? gTestVectors[i].PlainTextSize : (uint32_t)strlen( gTestVectors[i].PlainText );
        __crawdog_sha1_update( &context, gTestVectors[i].PlainText, (uint32_t)len );
        __crawdog_sha1_finish( &context, &hash );

        if( memcmp( &hash, &gTestVectors[i].Sha1Hash, sizeof(hash) ) == 0 )
        {
            // Test vector passed
        }
        else
        {
            printf( "TestSha1 - Test vector %u failed\n", i );
            success = false;
        }
    }

    // Check the vectors again, this time adding just 1 char at a time to the hash functions
    for( i=0; i<NUM_TEST_VECTORS; i++ )
    {
        __crawdog_sha1_init( &context );
        len = (uint32_t) gTestVectors[i].PlainTextSize ? gTestVectors[i].PlainTextSize : (uint32_t)strlen( gTestVectors[i].PlainText );
        for( k=0; k<len; k++ )
        {
            __crawdog_sha1_update( &context, &gTestVectors[i].PlainText[k], 1 );
        }
        __crawdog_sha1_finish( &context, &hash );

        if( memcmp( &hash, &gTestVectors[i].Sha1Hash, sizeof(hash) ) == 0 )
        {
            // Test vector passed
        }
        else
        {
            printf( "TestSha1 - Test vector %u failed [byte by byte]\n", i );
            success = false;
        }
    }

    return success;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TestSha256
//
//  Test SHA1 algorithm against test vectors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static
bool
    TestSha256
    (
        void
    )
{
    uint32_t        i;
    uint32_t        k;
    uint32_t        len;
    __crawdog_sha256_context   context;
    SHA256_HASH     hash;
    bool            success = true;

    for( i=0; i<NUM_TEST_VECTORS; i++ )
    {
        __crawdog_sha256_init( &context );
        len = (uint32_t) gTestVectors[i].PlainTextSize ? gTestVectors[i].PlainTextSize : (uint32_t)strlen( gTestVectors[i].PlainText );
        __crawdog_sha256_update( &context, gTestVectors[i].PlainText, (uint32_t)len );
        __crawdog_sha256_finish( &context, &hash );

        if( memcmp( &hash, &gTestVectors[i].Sha256Hash, sizeof(hash) ) == 0 )
        {
            // Test vector passed
        }
        else
        {
            printf( "TestSha256 - Test vector %u failed\n", i );
            success = false;
        }
    }

    // Check the vectors again, this time adding just 1 char at a time to the hash functions
    for( i=0; i<NUM_TEST_VECTORS; i++ )
    {
        __crawdog_sha256_init( &context );
        len = (uint32_t) gTestVectors[i].PlainTextSize ? gTestVectors[i].PlainTextSize : (uint32_t)strlen( gTestVectors[i].PlainText );
        for( k=0; k<len; k++ )
        {
            __crawdog_sha256_update( &context, &gTestVectors[i].PlainText[k], 1 );
        }
        __crawdog_sha256_finish( &context, &hash );

        if( memcmp( &hash, &gTestVectors[i].Sha256Hash, sizeof(hash) ) == 0 )
        {
            // Test vector passed
        }
        else
        {
            printf( "TestSha256 - Test vector %u failed [byte by byte]\n", i );
            success = false;
        }
    }

    return success;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TestSha512
//
//  Test SHA1 algorithm against test vectors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static
bool
    TestSha512
    (
        void
    )
{
    uint32_t        i;
    uint32_t        k;
    uint32_t        len;
    __crawdog_sha512_context   context;
    SHA512_HASH     hash;
    bool            success = true;

    for( i=0; i<NUM_TEST_VECTORS; i++ )
    {
        __crawdog_sha512_init( &context );
        len = (uint32_t) gTestVectors[i].PlainTextSize ? gTestVectors[i].PlainTextSize : (uint32_t)strlen( gTestVectors[i].PlainText );
        __crawdog_sha512_update( &context, gTestVectors[i].PlainText, (uint32_t)len );
        __crawdog_sha512_finish( &context, &hash );

        if( memcmp( &hash, &gTestVectors[i].Sha512Hash, sizeof(hash) ) == 0 )
        {
            // Test vector passed
        }
        else
        {
            printf( "TestSha512 - Test vector %u failed\n", i );
            success = false;
        }
    }

    // Check the vectors again, this time adding just 1 char at a time to the hash functions
    for( i=0; i<NUM_TEST_VECTORS; i++ )
    {
        __crawdog_sha512_init( &context );
        len = (uint32_t) gTestVectors[i].PlainTextSize ? gTestVectors[i].PlainTextSize : (uint32_t)strlen( gTestVectors[i].PlainText );
        for( k=0; k<len; k++ )
        {
            __crawdog_sha512_update( &context, &gTestVectors[i].PlainText[k], 1 );
        }
        __crawdog_sha512_finish( &context, &hash );

        if( memcmp( &hash, &gTestVectors[i].Sha512Hash, sizeof(hash) ) == 0 )
        {
            // Test vector passed
        }
        else
        {
            printf( "TestSha512 - Test vector %u failed [byte by byte]\n", i );
            success = false;
        }
    }

    return success;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  PUBLIC FUNCTIONS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TestHashes
//
//  Test Hash functions algorithm against test vectors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
bool
    __crawdog_testHashing
    (
        void
    )
{
    bool    success;
    bool    allSuccess = true;

    success = TestMd5( );
    if( !success ) { allSuccess = false; }
    printf( "Test MD5     - %s\n", success?"Pass":"Fail" );

    success = TestSha1( );
    if( !success ) { allSuccess = false; }
    printf( "Test SHA1    - %s\n", success?"Pass":"Fail" );

    success = TestSha256( );
    if( !success ) { allSuccess = false; }
    printf( "Test SHA256  - %s\n", success?"Pass":"Fail" );

    success = TestSha512( );
    if( !success ) { allSuccess = false; }
    printf( "Test SHA512  - %s\n", success?"Pass":"Fail" );

    return allSuccess;
}