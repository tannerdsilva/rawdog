// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
// copyright (c) 2015 mehdi sotoodeh
#ifndef __CRAWDOG_CURVE25519_MEHDI_H
#define __CRAWDOG_CURVE25519_MEHDI_H

#include <stdint.h>
#include "crawdog_basetypes.h"

#ifdef USE_ASM_LIB
#define U_WORD          U64
#define S_WORD          S64
#define WORDSIZE_64
#define W64(lo,hi)      ((U64)hi<<32)+lo
#else
#define U_WORD          U32
#define S_WORD          S32
#define WORDSIZE_32
#define W64(lo,hi)      lo,hi
#endif

#define K_BYTES         32
#define K_WORDS         (K_BYTES/sizeof(U_WORD))

#define W256(x0,x1,x2,x3,x4,x5,x6,x7) {W64(x0,x1),W64(x2,x3),W64(x4,x5),W64(x6,x7)}

/* Affine coordinates */
typedef struct {
    U_WORD x[K_WORDS];
    U_WORD y[K_WORDS];
} Affine_POINT;

/* Projective coordinates */
typedef struct {
    U_WORD x[K_WORDS];  /* x/z */
    U_WORD y[K_WORDS];  /* y/z */
    U_WORD z[K_WORDS];
    U_WORD t[K_WORDS];  /* xy/z */
} Ext_POINT;

/* pre-computed, extended point */
typedef struct
{
    U_WORD YpX[K_WORDS];        /* Y+X */
    U_WORD YmX[K_WORDS];        /* Y-X */
    U_WORD T2d[K_WORDS];        /* 2d*T */
    U_WORD Z2[K_WORDS];         /* 2*Z */
} PE_POINT;

/* pre-computed, Affine point */
typedef struct
{
    U_WORD YpX[K_WORDS];        /* Y+X */
    U_WORD YmX[K_WORDS];        /* Y-X */
    U_WORD T2d[K_WORDS];        /* 2d*T */
} PA_POINT;

typedef struct {
    U_WORD bl[K_WORDS];
    U_WORD zr[K_WORDS];
    PE_POINT BP;
} EDP_BLINDING_CTX;

extern const uint8_t ecp_BasePoint[K_BYTES];

/* Return point Q = k*P */
void ecp_PointMultiply(OUT uint8_t *Q, IN const uint8_t *P, IN const uint8_t *K, IN int len);

/* Set low and high bits */
void ecp_TrimSecretKey(uint8_t *X);

/* -- utils ----------------------------------------------------------------- */

/* Convert big-endian byte array to little-endian byte array and vice versa */
uint8_t* ecp_ReverseByteOrder(OUT uint8_t *Y, IN const uint8_t *X);
/* Convert little-endian byte array to little-endian word array */
U_WORD* ecp_BytesToWords(OUT U_WORD *Y, IN const uint8_t *X);
/* Convert little-endian word array to little-endian byte array */
uint8_t* ecp_WordsToBytes(OUT uint8_t *Y, IN const U_WORD *X);
uint8_t* ecp_EncodeInt(OUT uint8_t *Y, IN const U_WORD *X, IN uint8_t parity);
uint8_t ecp_DecodeInt(OUT U_WORD *Y, IN const uint8_t *X);

/* -- base point order ------------------------------------------------------ */

/* Z = (X*Y)/R mod BPO */
void eco_MontMul(OUT U_WORD *Z, IN const U_WORD *X, IN const U_WORD *Y);
/* Return Y = X*R mod BPO */
void eco_ToMont(OUT U_WORD *Y, IN const U_WORD *X);
/* Return Y = X/R mod BPO */
void eco_FromMont(OUT U_WORD *Y, IN const U_WORD *X);
/* Calculate Y = X**E mod BPO */
void eco_ExpModBPO(OUT U_WORD *Y, IN const U_WORD *X, IN const uint8_t *E, IN int bytes);
/* Calculate Y = 1/X mod BPO */
void eco_InvModBPO(OUT U_WORD *Y, IN const U_WORD *X);
/* Z = X*Y mod BPO */
void eco_MulReduce(OUT U_WORD *Z, IN const U_WORD *X, IN const U_WORD *Y);
/* Return Y = D mod BPO where D is 512-bit big-endian byte array (i.e SHA512 digest) */
void eco_DigestToWords( OUT U_WORD *Y, IN const uint8_t *D);
/* Z = X + Y mod BPO */
void eco_AddReduce(OUT U_WORD *Z, IN const U_WORD *X, IN const U_WORD *Y);
/* X mod BPO */
void eco_Mod(U_WORD *X);

#define ed25519_PackPoint(buff, Y, parity) ecp_EncodeInt(buff, Y, (uint8_t)(parity & 1))

/* -- big-number ------------------------------------------------------------ */
U_WORD ecp_Add(U_WORD* Z, const U_WORD* X, const U_WORD* Y);
S_WORD ecp_Sub(U_WORD* Z, const U_WORD* X, const U_WORD* Y);
void ecp_SetValue(U_WORD* X, U_WORD value);
void ecp_Copy(U_WORD* Y, const U_WORD* X);
void ecp_AddReduce(U_WORD* Z, const U_WORD* X, const U_WORD* Y);
void ecp_SubReduce(U_WORD* Z, const U_WORD* X, const U_WORD* Y);
void ecp_MulReduce(U_WORD* Z, const U_WORD* X, const U_WORD* Y);
void ecp_SqrReduce(U_WORD* Y, const U_WORD* X);
void ecp_ModExp2523(U_WORD *Y, const U_WORD *X);
void ecp_Inverse(U_WORD *out, const U_WORD *z);
void ecp_MulMod(U_WORD* Z, const U_WORD* X, const U_WORD* Y);
void ecp_Mul(U_WORD* Z, const U_WORD* X, const U_WORD* Y);
/* Computes Y = b*X */
void ecp_WordMulSet(U_WORD *Y, U_WORD b, const U_WORD* X);
/* Computes Z = Y + b*X and return carry */
U_WORD ecp_WordMulAdd(U_WORD *Z, const U_WORD* Y, U_WORD b, const U_WORD* X);
/* Computes Z = Y + b*X */
void ecp_WordMulAddReduce(U_WORD *Z, const U_WORD* Y, U_WORD b, const U_WORD* X);
void ecp_Mod(U_WORD* X);
int ecp_CmpNE(const U_WORD* X, const U_WORD* Y);
int ecp_CmpLT(const U_WORD* X, const U_WORD* Y);
/* Calculate: Y = [b:X] mod BPO */
void eco_ReduceHiWord(U_WORD* Y, U_WORD b, const U_WORD* X);

/* -- ed25519 --------------------------------------------------------------- */
void ed25519_UnpackPoint(Affine_POINT *r, const unsigned char *p);
void ed25519_CalculateX(OUT U_WORD *X, IN const U_WORD *Y, U_WORD parity);
void edp_AddAffinePoint(Ext_POINT *p, const PA_POINT *q);
void edp_AddBasePoint(Ext_POINT *p);
void edp_AddPoint(Ext_POINT *r, const Ext_POINT *p, const PE_POINT *q);
void edp_DoublePoint(Ext_POINT *p);
void edp_ComputePermTable(PE_POINT *qtable, Ext_POINT *Q);
void edp_ExtPoint2PE(PE_POINT *r, const Ext_POINT *p);
void edp_BasePointMult(OUT Ext_POINT *S, IN const U_WORD *sk, IN const U_WORD *R);
void edp_BasePointMultiply(OUT Affine_POINT *Q, IN const U_WORD *sk, 
    IN const void *blinding);
void ecp_4Folds(uint8_t* Y, const U_WORD* X);
void ecp_8Folds(uint8_t* Y, const U_WORD* X);

#endif  // __CRAWDOG_CURVE25519_MEHDI_H