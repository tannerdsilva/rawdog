// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef _SHA1_H_
#define _SHA1_H_

#include <stdint.h>

#define SHA1HashSize 20

enum
{
  shaSuccess = 0,
  shaNull,            /* Null pointer parameter */
  shaInputTooLong,    /* input data too long */
  shaStateError       /* called Input after Result */
};

#define FLAG_COMPUTED   1
#define FLAG_CORRUPTED  2

/*
 * Data structure holding contextual information about the SHA-1 hash
 */
struct sha1
{
  uint8_t  Message_Block[64];       /* 512-bit message blocks         */
  uint32_t Intermediate_Hash[5];    /* Message Digest                 */
  uint32_t Length_Low;              /* Message length in bits         */
  uint32_t Length_High;             /* Message length in bits         */
  uint16_t Message_Block_Index;     /* Index into message block array */
  uint8_t  flags;
};



/* 
 * Public API
 */
int sha1_reset (struct sha1* context);
int sha1_input (struct sha1* context, const uint8_t* message_array, unsigned length);
int sha1_result(struct sha1* context, uint8_t Message_Digest[SHA1HashSize]);



#endif /* #ifndef _SHA1_H_ */


