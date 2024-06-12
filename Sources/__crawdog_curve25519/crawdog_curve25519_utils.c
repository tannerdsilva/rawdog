// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
// copyright (c) 2015 mehdi sotoodeh
#include "crawdog_curve25519_mehdi.h"
#include <stdint.h>
/* Trim private key   */
void ecp_TrimSecretKey(uint8_t *X)
{
    X[0] &= 0xf8;
    X[31] = (X[31] | 0x40) & 0x7f;
}

/* Convert big-endian byte array to little-endian byte array and vice versa */
uint8_t* ecp_ReverseByteOrder(OUT uint8_t *Y, IN const uint8_t *X)
{
    int i;
    for (i = 0; i < 32; i++) Y[i] = X[31-i];
    return Y;
}

/* Convert little-endian byte array to little-endian word array */
U32* ecp_BytesToWords(OUT U32 *Y, IN const uint8_t *X)
{
    int i;
    M32 m;
    
    for (i = 0; i < 8; i++)
    {
        m.u8.b0 = *X++;
        m.u8.b1 = *X++;
        m.u8.b2 = *X++;
        m.u8.b3 = *X++;
        
        Y[i] = m.u32;
    }
    return Y;
}

/* Convert little-endian word array to little-endian byte array */
uint8_t* ecp_WordsToBytes(OUT uint8_t *Y, IN const U32 *X)
{
    int i;
    M32 m;
    
    for (i = 0; i < 32;)
    {
        m.u32 = *X++;
        Y[i++] = m.u8.b0;
        Y[i++] = m.u8.b1;
        Y[i++] = m.u8.b2;
        Y[i++] = m.u8.b3;
    }
    return Y;
}

uint8_t* ecp_EncodeInt(OUT uint8_t *Y, IN const U32 *X, IN uint8_t parity)
{
    int i;
    M32 m;
    
    for (i = 0; i < 28;)
    {
        m.u32 = *X++;
        Y[i++] = m.u8.b0;
        Y[i++] = m.u8.b1;
        Y[i++] = m.u8.b2;
        Y[i++] = m.u8.b3;
    }

    m.u32 = *X;
    Y[28] = m.u8.b0;
    Y[29] = m.u8.b1;
    Y[30] = m.u8.b2;
    Y[31] = (uint8_t)((m.u8.b3 & 0x7f) | (parity << 7));

    return Y;
}

uint8_t ecp_DecodeInt(OUT U32 *Y, IN const uint8_t *X)
{
    int i;
    M32 m;
    
    for (i = 0; i < 7; i++)
    {
        m.u8.b0 = *X++;
        m.u8.b1 = *X++;
        m.u8.b2 = *X++;
        m.u8.b3 = *X++;
        
        Y[i] = m.u32;
    }

    m.u8.b0 = *X++;
    m.u8.b1 = *X++;
    m.u8.b2 = *X++;
    m.u8.b3 = *X & 0x7f;
        
    Y[7] = m.u32;

    return (uint8_t)((*X >> 7) & 1);
}

void ecp_4Folds(uint8_t* Y, const U32* X)
{
    int i, j;
    uint8_t a, b;
    for (i = 32; i-- > 0; Y++)
    {
        a = 0;
        b = 0;
        for (j = 8; j > 1;)
        {
            j -= 2;
            a = (a << 1) + ((X[j+1] >> i) & 1);
            b = (b << 1) + ((X[j] >> i) & 1);
        }
        Y[0] = a;
        Y[32] = b;
    }
}

void ecp_8Folds(uint8_t* Y, const U32* X)
{
    int i, j;
    uint8_t a = 0;
    for (i = 32; i-- > 0;)
    {
        for (j = 8; j-- > 0;) a = (a << 1) + ((X[j] >> i) & 1);
        *Y++ = a;
    }
}
