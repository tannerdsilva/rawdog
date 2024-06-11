// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef __CRAWDOG_BLAKE2_H
#define __CRAWDOG_BLAKE2_H

#include <stddef.h>
#include <stdint.h>

#if defined(_MSC_VER)
#define __CRAWDOG_BLAKE2_PACKED(x) __pragma(pack(push, 1)) x __pragma(pack(pop))
#else
#define __CRAWDOG_BLAKE2_PACKED(x) x __attribute__((packed))
#endif

#if defined(__cplusplus)
extern "C" {
#endif

  enum __crawdog_blake2s_constant
  {
    __CRAWDOG_BLAKE2S_BLOCKBYTES = 64,
    __CRAWDOG_BLAKE2S_OUTBYTES   = 32,
    __CRAWDOG_BLAKE2S_KEYBYTES   = 32,
    __CRAWDOG_BLAKE2S_SALTBYTES  = 8,
    __CRAWDOG_BLAKE2S_PERSONALBYTES = 8
  };

  enum __crawdog_blake2b_constant
  {
    __CRAWDOG_BLAKE2B_BLOCKBYTES = 128,
    __CRAWDOG_BLAKE2B_OUTBYTES   = 64,
    __CRAWDOG_BLAKE2B_KEYBYTES   = 64,
    __CRAWDOG_BLAKE2B_SALTBYTES  = 16,
    __CRAWDOG_BLAKE2B_PERSONALBYTES = 16
  };

  typedef struct __crawdog_blake2s_state__
  {
    uint32_t h[8];
    uint32_t t[2];
    uint32_t f[2];
    uint8_t  buf[__CRAWDOG_BLAKE2S_BLOCKBYTES];
    size_t   buflen;
    size_t   outlen;
    uint8_t  last_node;
  } __crawdog_blake2s_state;

  typedef struct __crawdog_blake2b_state__
  {
    uint64_t h[8];
    uint64_t t[2];
    uint64_t f[2];
    uint8_t  buf[__CRAWDOG_BLAKE2B_BLOCKBYTES];
    size_t   buflen;
    size_t   outlen;
    uint8_t  last_node;
  } __crawdog_blake2b_state;

  typedef struct __crawdog_blake2sp_state__
  {
    __crawdog_blake2s_state S[8][1];
    __crawdog_blake2s_state R[1];
    uint8_t       buf[8 * __CRAWDOG_BLAKE2S_BLOCKBYTES];
    size_t        buflen;
    size_t        outlen;
  } __crawdog_blake2sp_state;

  typedef struct __crawdog_blake2bp_state__
  {
    __crawdog_blake2b_state S[4][1];
    __crawdog_blake2b_state R[1];
    uint8_t       buf[4 * __CRAWDOG_BLAKE2B_BLOCKBYTES];
    size_t        buflen;
    size_t        outlen;
  } __crawdog_blake2bp_state;


  __CRAWDOG_BLAKE2_PACKED(struct __crawdog_blake2s_param__
  {
    uint8_t  digest_length; /* 1 */
    uint8_t  key_length;    /* 2 */
    uint8_t  fanout;        /* 3 */
    uint8_t  depth;         /* 4 */
    uint32_t leaf_length;   /* 8 */
    uint32_t node_offset;  /* 12 */
    uint16_t xof_length;    /* 14 */
    uint8_t  node_depth;    /* 15 */
    uint8_t  inner_length;  /* 16 */
    /* uint8_t  reserved[0]; */
    uint8_t  salt[__CRAWDOG_BLAKE2S_SALTBYTES]; /* 24 */
    uint8_t  personal[__CRAWDOG_BLAKE2S_PERSONALBYTES];  /* 32 */
  });

  typedef struct __crawdog_blake2s_param__ __crawdog_blake2s_param;

  __CRAWDOG_BLAKE2_PACKED(struct __crawdog_blake2b_param__
  {
    uint8_t  digest_length; /* 1 */
    uint8_t  key_length;    /* 2 */
    uint8_t  fanout;        /* 3 */
    uint8_t  depth;         /* 4 */
    uint32_t leaf_length;   /* 8 */
    uint32_t node_offset;   /* 12 */
    uint32_t xof_length;    /* 16 */
    uint8_t  node_depth;    /* 17 */
    uint8_t  inner_length;  /* 18 */
    uint8_t  reserved[14];  /* 32 */
    uint8_t  salt[__CRAWDOG_BLAKE2B_SALTBYTES]; /* 48 */
    uint8_t  personal[__CRAWDOG_BLAKE2B_PERSONALBYTES];  /* 64 */
  });

  typedef struct __crawdog_blake2b_param__ __crawdog_blake2b_param;

  typedef struct __crawdog_blake2xs_state__
  {
    __crawdog_blake2s_state S[1];
    __crawdog_blake2s_param P[1];
  } __crawdog_blake2xs_state;

  typedef struct __crawdog_blake2xb_state__
  {
    __crawdog_blake2b_state S[1];
    __crawdog_blake2b_param P[1];
  } __crawdog_blake2xb_state;

  /* Padded structs result in a compile-time error */
  enum {
    __CRAWDOG_BLAKE2_DUMMY_1 = 1/(int)(sizeof(__crawdog_blake2s_param) == __CRAWDOG_BLAKE2S_OUTBYTES),
    __CRAWDOG_BLAKE2_DUMMY_2 = 1/(int)(sizeof(__crawdog_blake2b_param) == __CRAWDOG_BLAKE2B_OUTBYTES)
  };

  /* Streaming API */
  int __crawdog_blake2s_init( __crawdog_blake2s_state *S, size_t outlen );
  int __crawdog_blake2s_init_key( __crawdog_blake2s_state *S, size_t outlen, const void *key, size_t keylen );
  int __crawdog_blake2s_init_param( __crawdog_blake2s_state *S, const __crawdog_blake2s_param *P );
  int __crawdog_blake2s_update( __crawdog_blake2s_state *S, const void *in, size_t inlen );
  int __crawdog_blake2s_final( __crawdog_blake2s_state *S, void *out, size_t outlen );

  int __crawdog_blake2b_init( __crawdog_blake2b_state *S, size_t outlen );
  int __crawdog_blake2b_init_key( __crawdog_blake2b_state *S, size_t outlen, const void *key, size_t keylen );
  int __crawdog_blake2b_init_param( __crawdog_blake2b_state *S, const __crawdog_blake2b_param *P );
  int __crawdog_blake2b_update( __crawdog_blake2b_state *S, const void *in, size_t inlen );
  int __crawdog_blake2b_final( __crawdog_blake2b_state *S, void *out, size_t outlen );

  int __crawdog_blake2sp_init( __crawdog_blake2sp_state *S, size_t outlen );
  int __crawdog_blake2sp_init_key( __crawdog_blake2sp_state *S, size_t outlen, const void *key, size_t keylen );
  int __crawdog_blake2sp_update( __crawdog_blake2sp_state *S, const void *in, size_t inlen );
  int __crawdog_blake2sp_final( __crawdog_blake2sp_state *S, void *out, size_t outlen );

  int __crawdog_blake2bp_init( __crawdog_blake2bp_state *S, size_t outlen );
  int __crawdog_blake2bp_init_key( __crawdog_blake2bp_state *S, size_t outlen, const void *key, size_t keylen );
  int __crawdog_blake2bp_update( __crawdog_blake2bp_state *S, const void *in, size_t inlen );
  int __crawdog_blake2bp_final( __crawdog_blake2bp_state *S, void *out, size_t outlen );

  /* Variable output length API */
  int __crawdog_blake2xs_init( __crawdog_blake2xs_state *S, const size_t outlen );
  int __crawdog_blake2xs_init_key( __crawdog_blake2xs_state *S, const size_t outlen, const void *key, size_t keylen );
  int __crawdog_blake2xs_update( __crawdog_blake2xs_state *S, const void *in, size_t inlen );
  int __crawdog_blake2xs_final(__crawdog_blake2xs_state *S, void *out, size_t outlen);

  int __crawdog_blake2xb_init( __crawdog_blake2xb_state *S, const size_t outlen );
  int __crawdog_blake2xb_init_key( __crawdog_blake2xb_state *S, const size_t outlen, const void *key, size_t keylen );
  int __crawdog_blake2xb_update( __crawdog_blake2xb_state *S, const void *in, size_t inlen );
  int __crawdog_blake2xb_final(__crawdog_blake2xb_state *S, void *out, size_t outlen);

  /* Simple API */
  int __crawdog_blake2s( void *out, size_t outlen, const void *in, size_t inlen, const void *key, size_t keylen );
  int __crawdog_blake2b( void *out, size_t outlen, const void *in, size_t inlen, const void *key, size_t keylen );

  int __crawdog_blake2sp( void *out, size_t outlen, const void *in, size_t inlen, const void *key, size_t keylen );
  int __crawdog_blake2bp( void *out, size_t outlen, const void *in, size_t inlen, const void *key, size_t keylen );

  int __crawdog_blake2xs( void *out, size_t outlen, const void *in, size_t inlen, const void *key, size_t keylen );
  int __crawdog_blake2xb( void *out, size_t outlen, const void *in, size_t inlen, const void *key, size_t keylen );

  /* This is simply an alias for __crawdog_blake2b */
  int __crawdog_blake2( void *out, size_t outlen, const void *in, size_t inlen, const void *key, size_t keylen );

#if defined(__cplusplus)
}
#endif

#endif
