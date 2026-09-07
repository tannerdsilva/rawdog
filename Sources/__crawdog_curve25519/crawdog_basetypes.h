// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
// copyright (c) 2015 mehdi sotoodeh
#ifndef __CURVE25519_BASE_TYPE_H
#define __CURVE25519_BASE_TYPE_H

#include <stdint.h>

/* Little-endian as default */
#ifndef ECP_CONFIG_BIG_ENDIAN
#define ECP_CONFIG_LITTLE_ENDIAN
#endif

typedef unsigned char       uint8_t;
typedef signed   char       S8;

#if defined(_MSC_VER)
typedef unsigned __int16    U16;
typedef signed   __int16    S16;
typedef unsigned __int32    U32;
typedef signed   __int32    S32;
typedef unsigned __int64    U64;
typedef signed   __int64    S64;
#else
typedef uint16_t            U16;
typedef int16_t             S16;
typedef uint32_t            U32;
typedef int32_t             S32;
typedef uint64_t            U64;
typedef int64_t             S64;
#endif

typedef unsigned int        SZ;

#ifdef ECP_CONFIG_BIG_ENDIAN
typedef union
{
    U16 u16;
    S16 s16;
    uint8_t bytes[2];
    struct { uint8_t b1, b0; } u8;
    struct { S8 b1; uint8_t b0; } s8;
} M16;
typedef union
{
    U32 u32;
    S32 s32;
    uint8_t bytes[4];
    struct { U16 w1, w0; } u16;
    struct { S16 w1; U16 w0; } s16;
    struct { uint8_t b3, b2, b1, b0; } u8;
    struct { M16 hi, lo; } m16;
} M32;
typedef union
{
    U64 u64;
    S64 s64;
    uint8_t bytes[8];
    struct { U32 hi, lo; } u32;
    struct { S32 hi; U32 lo; } s32;
    struct { U16 w3, w2, w1, w0; } u16;
    struct { uint8_t b7, b6, b5, b4, b3, b2, b1, b0; } u8;
    struct { M32 hi, lo; } m32;
} M64;
#else
typedef union
{
    U16 u16;
    S16 s16;
    uint8_t bytes[2];
    struct { uint8_t b0, b1; } u8;
    struct { uint8_t b0; S8 b1; } s8;
} M16;
typedef union
{
    U32 u32;
    S32 s32;
    uint8_t bytes[4];
    struct { U16 w0, w1; } u16;
    struct { U16 w0; S16 w1; } s16;
    struct { uint8_t b0, b1, b2, b3; } u8;
    struct { M16 lo, hi; } m16;
} M32;
typedef union
{
    U64 u64;
    S64 s64;
    uint8_t bytes[8];
    struct { U32 lo, hi; } u32;
    struct { U32 lo; S32 hi; } s32;
    struct { U16 w0, w1, w2, w3; } u16;
    struct { uint8_t b0, b1, b2, b3, b4, b5, b6, b7; } u8;
    struct { M32 lo, hi; } m32;
} M64;
#endif

#define IN
#define OUT

#endif // __CURVE25519_BASE_TYPE_H
