// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
// copyright (c) 2015 mehdi sotoodeh
#ifndef __CRAWDOG_ED25519_SIGNATURE_H
#define __CRAWDOG_ED25519_SIGNATURE_H

#include <stddef.h>

/* -- ed25519-sign ------------------------------------------------------------- */

#define __CRAWDOG_ED25519_PUBLIC_KEY_SIZE     32
#define __CRAWDOG_ED25519_SECRET_KEY_SIZE     32
#define __CRAWDOG_ED25519_PRIVATE_KEY_SIZE    64
#define __CRAWDOG_ED25519_SIGNATURE_SIZE      64

/* Generate public key associated with the secret key */
void __crawdog_ed25519_create_keypair(
    unsigned char *pubKey,              /* OUT: public key */
    unsigned char *privKey,             /* OUT: private key */
    const void *blinding,               /* IN: [optional] null or blinding context */
    const unsigned char *sk);           /* IN: secret key (32 bytes) */

/* Generate message signature */
void __crawdog_ed25519_sign_message(
    unsigned char *signature,           /* OUT:[64 bytes] signature (R,S) */
    const unsigned char *privKey,       /* IN: [64 bytes] private key (sk,pk) */
    const void *blinding,               /* IN: [optional] null or blinding context */
    const unsigned char *msg,           /* IN: [msg_size bytes] message to sign */
    size_t msg_size);                   /* IN: size of message */

void *__crawdog_ed25519_blinding_init(
    void *context,                      /* IO: null or ptr blinding context */
    const unsigned char *seed,          /* IN: [size bytes] random blinding seed */
    size_t size);                       /* IN: size of blinding seed */

void __crawdog_ed25519_blinding_finish(
    void *context);                     /* IN: blinding context */

/* -- ed25519-verify ----------------------------------------------------------- */

/*  Single-phased signature validation.
    Returns 1 for SUCCESS and 0 for FAILURE
*/
int __crawdog_ed25519_verify_signature(
    const unsigned char *signature,     /* IN: [64 bytes] signature (R,S) */
    const unsigned char *publicKey,     /* IN: [32 bytes] public key */
    const unsigned char *msg,           /* IN: [msg_size bytes] message to sign */
    size_t msg_size);                   /* IN: size of message */

/*  First part of two-phase signature validation.
    This function creates context specifc to a given public key.
    Needs to be called once per public key
*/
void * __crawdog_ed25519_verify_init(
    void *context,                      /* IO: null or verify context to use */
    const unsigned char *publicKey);    /* IN: [32 bytes] public key */

/*  Second part of two-phase signature validation.
    Input context is output of __crawdog_ed25519_verify_init() for associated public key.
    Call it once for each message/signature pairs
    Returns 1 for SUCCESS and 0 for FAILURE
*/
int __crawdog_ed25519_verify_check(
    const void          *context,       /* IN: created by __crawdog_ed25519_verify_init */
    const unsigned char *signature,     /* IN: signature (R,S) */
    const unsigned char *msg,           /* IN: message to sign */
    size_t msg_size);                   /* IN: size of message */

/* Free up context memory */
void __crawdog_ed25519_verify_finish(void *ctx);

#endif	// __CRAWDOG_ED25519_SIGNATURE_H