// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#if defined(_OPENMP)
#include <omp.h>
#endif

#include "__crawdog_blake2.h"
#include "__crawdog_blake2-impl.h"

#define PARALLELISM_DEGREE 4

/*
  __crawdog_blake2b_init_param defaults to setting the expecting output length
  from the digest_length parameter block field.

  In some cases, however, we do not want this, as the output length
  of these instances is given by inner_length instead.
*/
static int __crawdog_blake2bp_init_leaf_param( __crawdog_blake2b_state *S, const __crawdog_blake2b_param *P )
{
  int err = __crawdog_blake2b_init_param(S, P);
  S->outlen = P->inner_length;
  return err;
}

static int __crawdog_blake2bp_init_leaf( __crawdog_blake2b_state *S, size_t outlen, size_t keylen, uint64_t offset )
{
  __crawdog_blake2b_param P[1];
  P->digest_length = (uint8_t)outlen;
  P->key_length = (uint8_t)keylen;
  P->fanout = PARALLELISM_DEGREE;
  P->depth = 2;
  store32( &P->leaf_length, 0 );
  store32( &P->node_offset, offset );
  store32( &P->xof_length, 0 );
  P->node_depth = 0;
  P->inner_length = __CRAWDOG_BLAKE2B_OUTBYTES;
  memset( P->reserved, 0, sizeof( P->reserved ) );
  memset( P->salt, 0, sizeof( P->salt ) );
  memset( P->personal, 0, sizeof( P->personal ) );
  return __crawdog_blake2bp_init_leaf_param( S, P );
}

static int __crawdog_blake2bp_init_root( __crawdog_blake2b_state *S, size_t outlen, size_t keylen )
{
  __crawdog_blake2b_param P[1];
  P->digest_length = (uint8_t)outlen;
  P->key_length = (uint8_t)keylen;
  P->fanout = PARALLELISM_DEGREE;
  P->depth = 2;
  store32( &P->leaf_length, 0 );
  store32( &P->node_offset, 0 );
  store32( &P->xof_length, 0 );
  P->node_depth = 1;
  P->inner_length = __CRAWDOG_BLAKE2B_OUTBYTES;
  memset( P->reserved, 0, sizeof( P->reserved ) );
  memset( P->salt, 0, sizeof( P->salt ) );
  memset( P->personal, 0, sizeof( P->personal ) );
  return __crawdog_blake2b_init_param( S, P );
}


int __crawdog_blake2bp_init( __crawdog_blake2bp_state *S, size_t outlen )
{
  size_t i;

  if( !outlen || outlen > __CRAWDOG_BLAKE2B_OUTBYTES ) return -1;

  memset( S->buf, 0, sizeof( S->buf ) );
  S->buflen = 0;
  S->outlen = outlen;

  if( __crawdog_blake2bp_init_root( S->R, outlen, 0 ) < 0 )
    return -1;

  for( i = 0; i < PARALLELISM_DEGREE; ++i )
    if( __crawdog_blake2bp_init_leaf( S->S[i], outlen, 0, i ) < 0 ) return -1;

  S->R->last_node = 1;
  S->S[PARALLELISM_DEGREE - 1]->last_node = 1;
  return 0;
}

int __crawdog_blake2bp_init_key( __crawdog_blake2bp_state *S, size_t outlen, const void *key, size_t keylen )
{
  size_t i;

  if( !outlen || outlen > __CRAWDOG_BLAKE2B_OUTBYTES ) return -1;

  if( !key || !keylen || keylen > __CRAWDOG_BLAKE2B_KEYBYTES ) return -1;

  memset( S->buf, 0, sizeof( S->buf ) );
  S->buflen = 0;
  S->outlen = outlen;

  if( __crawdog_blake2bp_init_root( S->R, outlen, keylen ) < 0 )
    return -1;

  for( i = 0; i < PARALLELISM_DEGREE; ++i )
    if( __crawdog_blake2bp_init_leaf( S->S[i], outlen, keylen, i ) < 0 ) return -1;

  S->R->last_node = 1;
  S->S[PARALLELISM_DEGREE - 1]->last_node = 1;
  {
    uint8_t block[__CRAWDOG_BLAKE2B_BLOCKBYTES];
    memset( block, 0, __CRAWDOG_BLAKE2B_BLOCKBYTES );
    memcpy( block, key, keylen );

    for( i = 0; i < PARALLELISM_DEGREE; ++i )
      __crawdog_blake2b_update( S->S[i], block, __CRAWDOG_BLAKE2B_BLOCKBYTES );

    secure_zero_memory( block, __CRAWDOG_BLAKE2B_BLOCKBYTES ); /* Burn the key from stack */
  }
  return 0;
}


int __crawdog_blake2bp_update( __crawdog_blake2bp_state *S, const void *pin, size_t inlen )
{
  const unsigned char * in = (const unsigned char *)pin;
  size_t left = S->buflen;
  size_t fill = sizeof( S->buf ) - left;
  size_t i;

  if( left && inlen >= fill )
  {
    memcpy( S->buf + left, in, fill );

    for( i = 0; i < PARALLELISM_DEGREE; ++i )
      __crawdog_blake2b_update( S->S[i], S->buf + i * __CRAWDOG_BLAKE2B_BLOCKBYTES, __CRAWDOG_BLAKE2B_BLOCKBYTES );

    in += fill;
    inlen -= fill;
    left = 0;
  }

#if defined(_OPENMP)
  #pragma omp parallel shared(S), num_threads(PARALLELISM_DEGREE)
#else

  for( i = 0; i < PARALLELISM_DEGREE; ++i )
#endif
  {
#if defined(_OPENMP)
    size_t      i = omp_get_thread_num();
#endif
    size_t inlen__ = inlen;
    const unsigned char *in__ = ( const unsigned char * )in;
    in__ += i * __CRAWDOG_BLAKE2B_BLOCKBYTES;

    while( inlen__ >= PARALLELISM_DEGREE * __CRAWDOG_BLAKE2B_BLOCKBYTES )
    {
      __crawdog_blake2b_update( S->S[i], in__, __CRAWDOG_BLAKE2B_BLOCKBYTES );
      in__ += PARALLELISM_DEGREE * __CRAWDOG_BLAKE2B_BLOCKBYTES;
      inlen__ -= PARALLELISM_DEGREE * __CRAWDOG_BLAKE2B_BLOCKBYTES;
    }
  }

  in += inlen - inlen % ( PARALLELISM_DEGREE * __CRAWDOG_BLAKE2B_BLOCKBYTES );
  inlen %= PARALLELISM_DEGREE * __CRAWDOG_BLAKE2B_BLOCKBYTES;

  if( inlen > 0 )
    memcpy( S->buf + left, in, inlen );

  S->buflen = left + inlen;
  return 0;
}

int __crawdog_blake2bp_final( __crawdog_blake2bp_state *S, void *out, size_t outlen )
{
  uint8_t hash[PARALLELISM_DEGREE][__CRAWDOG_BLAKE2B_OUTBYTES];
  size_t i;

  if(out == NULL || outlen < S->outlen) {
    return -1;
  }

  for( i = 0; i < PARALLELISM_DEGREE; ++i )
  {
    if( S->buflen > i * __CRAWDOG_BLAKE2B_BLOCKBYTES )
    {
      size_t left = S->buflen - i * __CRAWDOG_BLAKE2B_BLOCKBYTES;

      if( left > __CRAWDOG_BLAKE2B_BLOCKBYTES ) left = __CRAWDOG_BLAKE2B_BLOCKBYTES;

      __crawdog_blake2b_update( S->S[i], S->buf + i * __CRAWDOG_BLAKE2B_BLOCKBYTES, left );
    }

    __crawdog_blake2b_final( S->S[i], hash[i], __CRAWDOG_BLAKE2B_OUTBYTES );
  }

  for( i = 0; i < PARALLELISM_DEGREE; ++i )
    __crawdog_blake2b_update( S->R, hash[i], __CRAWDOG_BLAKE2B_OUTBYTES );

  return __crawdog_blake2b_final( S->R, out, S->outlen );
}

int __crawdog_blake2bp( void *out, size_t outlen, const void *in, size_t inlen, const void *key, size_t keylen )
{
  uint8_t hash[PARALLELISM_DEGREE][__CRAWDOG_BLAKE2B_OUTBYTES];
  __crawdog_blake2b_state S[PARALLELISM_DEGREE][1];
  __crawdog_blake2b_state FS[1];
  size_t i;

  /* Verify parameters */
  if ( NULL == in && inlen > 0 ) return -1;

  if ( NULL == out ) return -1;

  if( NULL == key && keylen > 0 ) return -1;

  if( !outlen || outlen > __CRAWDOG_BLAKE2B_OUTBYTES ) return -1;

  if( keylen > __CRAWDOG_BLAKE2B_KEYBYTES ) return -1;

  for( i = 0; i < PARALLELISM_DEGREE; ++i )
    if( __crawdog_blake2bp_init_leaf( S[i], outlen, keylen, i ) < 0 ) return -1;

  S[PARALLELISM_DEGREE - 1]->last_node = 1; /* mark last node */

  if( keylen > 0 )
  {
    uint8_t block[__CRAWDOG_BLAKE2B_BLOCKBYTES];
    memset( block, 0, __CRAWDOG_BLAKE2B_BLOCKBYTES );
    memcpy( block, key, keylen );

    for( i = 0; i < PARALLELISM_DEGREE; ++i )
      __crawdog_blake2b_update( S[i], block, __CRAWDOG_BLAKE2B_BLOCKBYTES );

    secure_zero_memory( block, __CRAWDOG_BLAKE2B_BLOCKBYTES ); /* Burn the key from stack */
  }

#if defined(_OPENMP)
  #pragma omp parallel shared(S,hash), num_threads(PARALLELISM_DEGREE)
#else

  for( i = 0; i < PARALLELISM_DEGREE; ++i )
#endif
  {
#if defined(_OPENMP)
    size_t      i = omp_get_thread_num();
#endif
    size_t inlen__ = inlen;
    const unsigned char *in__ = ( const unsigned char * )in;
    in__ += i * __CRAWDOG_BLAKE2B_BLOCKBYTES;

    while( inlen__ >= PARALLELISM_DEGREE * __CRAWDOG_BLAKE2B_BLOCKBYTES )
    {
      __crawdog_blake2b_update( S[i], in__, __CRAWDOG_BLAKE2B_BLOCKBYTES );
      in__ += PARALLELISM_DEGREE * __CRAWDOG_BLAKE2B_BLOCKBYTES;
      inlen__ -= PARALLELISM_DEGREE * __CRAWDOG_BLAKE2B_BLOCKBYTES;
    }

    if( inlen__ > i * __CRAWDOG_BLAKE2B_BLOCKBYTES )
    {
      const size_t left = inlen__ - i * __CRAWDOG_BLAKE2B_BLOCKBYTES;
      const size_t len = left <= __CRAWDOG_BLAKE2B_BLOCKBYTES ? left : __CRAWDOG_BLAKE2B_BLOCKBYTES;
      __crawdog_blake2b_update( S[i], in__, len );
    }

    __crawdog_blake2b_final( S[i], hash[i], __CRAWDOG_BLAKE2B_OUTBYTES );
  }

  if( __crawdog_blake2bp_init_root( FS, outlen, keylen ) < 0 )
    return -1;

  FS->last_node = 1; /* Mark as last node */

  for( i = 0; i < PARALLELISM_DEGREE; ++i )
    __crawdog_blake2b_update( FS, hash[i], __CRAWDOG_BLAKE2B_OUTBYTES );

  return __crawdog_blake2b_final( FS, out, outlen );;
}

#if defined(__CRAWDOG_BLAKE2BP_SELFTEST)
#include <string.h>
#include "__crawdog_blake2-kat.h"
int main( void )
{
  uint8_t key[__CRAWDOG_BLAKE2B_KEYBYTES];
  uint8_t buf[__CRAWDOG_BLAKE2_KAT_LENGTH];
  size_t i, step;

  for( i = 0; i < __CRAWDOG_BLAKE2B_KEYBYTES; ++i )
    key[i] = ( uint8_t )i;

  for( i = 0; i < __CRAWDOG_BLAKE2_KAT_LENGTH; ++i )
    buf[i] = ( uint8_t )i;

  /* Test simple API */
  for( i = 0; i < __CRAWDOG_BLAKE2_KAT_LENGTH; ++i )
  {
    uint8_t hash[__CRAWDOG_BLAKE2B_OUTBYTES];
    __crawdog_blake2bp( hash, __CRAWDOG_BLAKE2B_OUTBYTES, buf, i, key, __CRAWDOG_BLAKE2B_KEYBYTES );

    if( 0 != memcmp( hash, __crawdog_blake2bp_keyed_kat[i], __CRAWDOG_BLAKE2B_OUTBYTES ) )
    {
      goto fail;
    }
  }

  /* Test streaming API */
  for(step = 1; step < __CRAWDOG_BLAKE2B_BLOCKBYTES; ++step) {
    for (i = 0; i < __CRAWDOG_BLAKE2_KAT_LENGTH; ++i) {
      uint8_t hash[__CRAWDOG_BLAKE2B_OUTBYTES];
      __crawdog_blake2bp_state S;
      uint8_t * p = buf;
      size_t mlen = i;
      int err = 0;

      if( (err = __crawdog_blake2bp_init_key(&S, __CRAWDOG_BLAKE2B_OUTBYTES, key, __CRAWDOG_BLAKE2B_KEYBYTES)) < 0 ) {
        goto fail;
      }

      while (mlen >= step) {
        if ( (err = __crawdog_blake2bp_update(&S, p, step)) < 0 ) {
          goto fail;
        }
        mlen -= step;
        p += step;
      }
      if ( (err = __crawdog_blake2bp_update(&S, p, mlen)) < 0) {
        goto fail;
      }
      if ( (err = __crawdog_blake2bp_final(&S, hash, __CRAWDOG_BLAKE2B_OUTBYTES)) < 0) {
        goto fail;
      }

      if (0 != memcmp(hash, __crawdog_blake2bp_keyed_kat[i], __CRAWDOG_BLAKE2B_OUTBYTES)) {
        goto fail;
      }
    }
  }

  puts( "ok" );
  return 0;
fail:
  puts("error");
  return -1;
}
#endif
