// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#include <stdint.h>
#include <string.h>
#include <stdio.h>

#include "__crawdog_blake2.h"
#include "__crawdog_blake2-impl.h"

int __crawdog_blake2xb_init( __crawdog_blake2xb_state *S, const size_t outlen ) {
  return __crawdog_blake2xb_init_key(S, outlen, NULL, 0);
}

int __crawdog_blake2xb_init_key( __crawdog_blake2xb_state *S, const size_t outlen, const void *key, size_t keylen)
{
  if ( outlen == 0 || outlen > 0xFFFFFFFFUL ) {
    return -1;
  }

  if (NULL != key && keylen > __CRAWDOG_BLAKE2B_KEYBYTES) {
    return -1;
  }

  if (NULL == key && keylen > 0) {
    return -1;
  }

  /* Initialize parameter block */
  S->P->digest_length = __CRAWDOG_BLAKE2B_OUTBYTES;
  S->P->key_length    = keylen;
  S->P->fanout        = 1;
  S->P->depth         = 1;
  store32( &S->P->leaf_length, 0 );
  store32( &S->P->node_offset, 0 );
  store32( &S->P->xof_length, outlen );
  S->P->node_depth    = 0;
  S->P->inner_length  = 0;
  memset( S->P->reserved, 0, sizeof( S->P->reserved ) );
  memset( S->P->salt,     0, sizeof( S->P->salt ) );
  memset( S->P->personal, 0, sizeof( S->P->personal ) );

  if( __crawdog_blake2b_init_param( S->S, S->P ) < 0 ) {
    return -1;
  }

  if (keylen > 0) {
    uint8_t block[__CRAWDOG_BLAKE2B_BLOCKBYTES];
    memset(block, 0, __CRAWDOG_BLAKE2B_BLOCKBYTES);
    memcpy(block, key, keylen);
    __crawdog_blake2b_update(S->S, block, __CRAWDOG_BLAKE2B_BLOCKBYTES);
    secure_zero_memory(block, __CRAWDOG_BLAKE2B_BLOCKBYTES);
  }
  return 0;
}

int __crawdog_blake2xb_update( __crawdog_blake2xb_state *S, const void *in, size_t inlen ) {
    return __crawdog_blake2b_update( S->S, in, inlen );
}

int __crawdog_blake2xb_final( __crawdog_blake2xb_state *S, void *out, size_t outlen) {

  __crawdog_blake2b_state C[1];
  __crawdog_blake2b_param P[1];
  uint32_t xof_length = load32(&S->P->xof_length);
  uint8_t root[__CRAWDOG_BLAKE2B_BLOCKBYTES];
  size_t i;

  if (NULL == out) {
    return -1;
  }

  /* outlen must match the output size defined in xof_length, */
  /* unless it was -1, in which case anything goes except 0. */
  if(xof_length == 0xFFFFFFFFUL) {
    if(outlen == 0) {
      return -1;
    }
  } else {
    if(outlen != xof_length) {
      return -1;
    }
  }

  /* Finalize the root hash */
  if (__crawdog_blake2b_final(S->S, root, __CRAWDOG_BLAKE2B_OUTBYTES) < 0) {
    return -1;
  }

  /* Set common block structure values */
  /* Copy values from parent instance, and only change the ones below */
  memcpy(P, S->P, sizeof(__crawdog_blake2b_param));
  P->key_length = 0;
  P->fanout = 0;
  P->depth = 0;
  store32(&P->leaf_length, __CRAWDOG_BLAKE2B_OUTBYTES);
  P->inner_length = __CRAWDOG_BLAKE2B_OUTBYTES;
  P->node_depth = 0;

  for (i = 0; outlen > 0; ++i) {
    const size_t block_size = (outlen < __CRAWDOG_BLAKE2B_OUTBYTES) ? outlen : __CRAWDOG_BLAKE2B_OUTBYTES;
    /* Initialize state */
    P->digest_length = block_size;
    store32(&P->node_offset, i);
    __crawdog_blake2b_init_param(C, P);
    /* Process key if needed */
    __crawdog_blake2b_update(C, root, __CRAWDOG_BLAKE2B_OUTBYTES);
    if (__crawdog_blake2b_final(C, (uint8_t *)out + i * __CRAWDOG_BLAKE2B_OUTBYTES, block_size) < 0 ) {
        return -1;
    }
    outlen -= block_size;
  }
  secure_zero_memory(root, sizeof(root));
  secure_zero_memory(P, sizeof(P));
  secure_zero_memory(C, sizeof(C));
  /* Put __crawdog_blake2xb in an invalid state? cf. __crawdog_blake2s_is_lastblock */
  return 0;

}

int __crawdog_blake2xb(void *out, size_t outlen, const void *in, size_t inlen, const void *key, size_t keylen)
{
  __crawdog_blake2xb_state S[1];

  /* Verify parameters */
  if (NULL == in && inlen > 0)
    return -1;

  if (NULL == out)
    return -1;

  if (NULL == key && keylen > 0)
    return -1;

  if (keylen > __CRAWDOG_BLAKE2B_KEYBYTES)
    return -1;

  if (outlen == 0)
    return -1;

  /* Initialize the root block structure */
  if (__crawdog_blake2xb_init_key(S, outlen, key, keylen) < 0) {
    return -1;
  }

  /* Absorb the input message */
  __crawdog_blake2xb_update(S, in, inlen);

  /* Compute the root node of the tree and the final hash using the counter construction */
  return __crawdog_blake2xb_final(S, out, outlen);
}

#if defined(__CRAWDOG_BLAKE2XB_SELFTEST)
#include <string.h>
#include "__crawdog_blake2-kat.h"
int main( void )
{
  uint8_t key[__CRAWDOG_BLAKE2B_KEYBYTES];
  uint8_t buf[__CRAWDOG_BLAKE2_KAT_LENGTH];
  size_t i, step, outlen;

  for( i = 0; i < __CRAWDOG_BLAKE2B_KEYBYTES; ++i ) {
    key[i] = ( uint8_t )i;
  }

  for( i = 0; i < __CRAWDOG_BLAKE2_KAT_LENGTH; ++i ) {
    buf[i] = ( uint8_t )i;
  }

  /* Testing length of outputs rather than inputs */
  /* (Test of input lengths mostly covered by __crawdog_blake2b tests) */

  /* Test simple API */
  for( outlen = 1; outlen <= __CRAWDOG_BLAKE2_KAT_LENGTH; ++outlen )
  {
      uint8_t hash[__CRAWDOG_BLAKE2_KAT_LENGTH] = {0};
      if( __crawdog_blake2xb( hash, outlen, buf, __CRAWDOG_BLAKE2_KAT_LENGTH, key, __CRAWDOG_BLAKE2B_KEYBYTES ) < 0 ) {
        goto fail;
      }

      if( 0 != memcmp( hash, __crawdog_blake2xb_keyed_kat[outlen-1], outlen ) )
      {
        goto fail;
      }
  }

  /* Test streaming API */
  for(step = 1; step < __CRAWDOG_BLAKE2B_BLOCKBYTES; ++step) {
    for (outlen = 1; outlen <= __CRAWDOG_BLAKE2_KAT_LENGTH; ++outlen) {
      uint8_t hash[__CRAWDOG_BLAKE2_KAT_LENGTH];
      __crawdog_blake2xb_state S;
      uint8_t * p = buf;
      size_t mlen = __CRAWDOG_BLAKE2_KAT_LENGTH;
      int err = 0;

      if( (err = __crawdog_blake2xb_init_key(&S, outlen, key, __CRAWDOG_BLAKE2B_KEYBYTES)) < 0 ) {
        goto fail;
      }

      while (mlen >= step) {
        if ( (err = __crawdog_blake2xb_update(&S, p, step)) < 0 ) {
          goto fail;
        }
        mlen -= step;
        p += step;
      }
      if ( (err = __crawdog_blake2xb_update(&S, p, mlen)) < 0) {
        goto fail;
      }
      if ( (err = __crawdog_blake2xb_final(&S, hash, outlen)) < 0) {
        goto fail;
      }

      if (0 != memcmp(hash, __crawdog_blake2xb_keyed_kat[outlen-1], outlen)) {
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
