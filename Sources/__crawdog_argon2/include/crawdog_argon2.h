// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef __CRAWDOG_ARGON2_H
#define __CRAWDOG_ARGON2_H

#include <stdint.h>
#include <stddef.h>
#include <limits.h>

/* Symbols visibility control */
#ifdef A2_VISCTL
#define __CRAWDOG_ARGON2_PUBLIC __attribute__((visibility("default")))
#define __CRAWDOG_ARGON2_LOCAL __attribute__ ((visibility ("hidden")))
#elif defined(_MSC_VER)
#define __CRAWDOG_ARGON2_PUBLIC __declspec(dllexport)
#define __CRAWDOG_ARGON2_LOCAL
#else
#define __CRAWDOG_ARGON2_PUBLIC
#define __CRAWDOG_ARGON2_LOCAL
#endif

/*
 * Argon2 input parameter restrictions
 */

/* Minimum and maximum number of lanes (degree of parallelism) */
#define __CRAWDOG_ARGON2_MIN_LANES UINT32_C(1)
#define __CRAWDOG_ARGON2_MAX_LANES UINT32_C(0xFFFFFF)

/* Minimum and maximum number of threads */
#define __CRAWDOG_ARGON2_MIN_THREADS UINT32_C(1)
#define __CRAWDOG_ARGON2_MAX_THREADS UINT32_C(0xFFFFFF)

/* Number of synchronization points between lanes per pass */
#define __CRAWDOG_ARGON2_SYNC_POINTS UINT32_C(4)

/* Minimum and maximum digest size in bytes */
#define __CRAWDOG_ARGON2_MIN_OUTLEN UINT32_C(4)
#define __CRAWDOG_ARGON2_MAX_OUTLEN UINT32_C(0xFFFFFFFF)

/* Minimum and maximum number of memory blocks (each of BLOCK_SIZE bytes) */
#define __CRAWDOG_ARGON2_MIN_MEMORY (2 * __CRAWDOG_ARGON2_SYNC_POINTS) /* 2 blocks per slice */

#define __CRAWDOG_ARGON2_MIN(a, b) ((a) < (b) ? (a) : (b))
/* Max memory size is addressing-space/2, topping at 2^32 blocks (4 TB) */
#define __CRAWDOG_ARGON2_MAX_MEMORY_BITS                                                 \
    __CRAWDOG_ARGON2_MIN(UINT32_C(32), (sizeof(void *) * CHAR_BIT - 10 - 1))
#define __CRAWDOG_ARGON2_MAX_MEMORY                                                      \
    __CRAWDOG_ARGON2_MIN(UINT32_C(0xFFFFFFFF), UINT64_C(1) << __CRAWDOG_ARGON2_MAX_MEMORY_BITS)

/* Minimum and maximum number of passes */
#define __CRAWDOG_ARGON2_MIN_TIME UINT32_C(1)
#define __CRAWDOG_ARGON2_MAX_TIME UINT32_C(0xFFFFFFFF)

/* Minimum and maximum password length in bytes */
#define __CRAWDOG_ARGON2_MIN_PWD_LENGTH UINT32_C(0)
#define __CRAWDOG_ARGON2_MAX_PWD_LENGTH UINT32_C(0xFFFFFFFF)

/* Minimum and maximum associated data length in bytes */
#define __CRAWDOG_ARGON2_MIN_AD_LENGTH UINT32_C(0)
#define __CRAWDOG_ARGON2_MAX_AD_LENGTH UINT32_C(0xFFFFFFFF)

/* Minimum and maximum salt length in bytes */
#define __CRAWDOG_ARGON2_MIN_SALT_LENGTH UINT32_C(8)
#define __CRAWDOG_ARGON2_MAX_SALT_LENGTH UINT32_C(0xFFFFFFFF)

/* Minimum and maximum key length in bytes */
#define __CRAWDOG_ARGON2_MIN_SECRET UINT32_C(0)
#define __CRAWDOG_ARGON2_MAX_SECRET UINT32_C(0xFFFFFFFF)

/* Flags to determine which fields are securely wiped (default = no wipe). */
#define __CRAWDOG_ARGON2_DEFAULT_FLAGS UINT32_C(0)
#define __CRAWDOG_ARGON2_FLAG_CLEAR_PASSWORD (UINT32_C(1) << 0)
#define __CRAWDOG_ARGON2_FLAG_CLEAR_SECRET (UINT32_C(1) << 1)

/* Global flag to determine if we are wiping internal memory buffers. This flag
 * is defined in core.c and defaults to 1 (wipe internal memory). */
extern int FLAG_clear_internal_memory;

/* Error codes */
typedef enum Argon2_ErrorCodes {
    __CRAWDOG_ARGON2_OK = 0,

    __CRAWDOG_ARGON2_OUTPUT_PTR_NULL = -1,

    __CRAWDOG_ARGON2_OUTPUT_TOO_SHORT = -2,
    __CRAWDOG_ARGON2_OUTPUT_TOO_LONG = -3,

    __CRAWDOG_ARGON2_PWD_TOO_SHORT = -4,
    __CRAWDOG_ARGON2_PWD_TOO_LONG = -5,

    __CRAWDOG_ARGON2_SALT_TOO_SHORT = -6,
    __CRAWDOG_ARGON2_SALT_TOO_LONG = -7,

    __CRAWDOG_ARGON2_AD_TOO_SHORT = -8,
    __CRAWDOG_ARGON2_AD_TOO_LONG = -9,

    __CRAWDOG_ARGON2_SECRET_TOO_SHORT = -10,
    __CRAWDOG_ARGON2_SECRET_TOO_LONG = -11,

    __CRAWDOG_ARGON2_TIME_TOO_SMALL = -12,
    __CRAWDOG_ARGON2_TIME_TOO_LARGE = -13,

    __CRAWDOG_ARGON2_MEMORY_TOO_LITTLE = -14,
    __CRAWDOG_ARGON2_MEMORY_TOO_MUCH = -15,

    __CRAWDOG_ARGON2_LANES_TOO_FEW = -16,
    __CRAWDOG_ARGON2_LANES_TOO_MANY = -17,

    __CRAWDOG_ARGON2_PWD_PTR_MISMATCH = -18,    /* NULL ptr with non-zero length */
    __CRAWDOG_ARGON2_SALT_PTR_MISMATCH = -19,   /* NULL ptr with non-zero length */
    __CRAWDOG_ARGON2_SECRET_PTR_MISMATCH = -20, /* NULL ptr with non-zero length */
    __CRAWDOG_ARGON2_AD_PTR_MISMATCH = -21,     /* NULL ptr with non-zero length */

    __CRAWDOG_ARGON2_MEMORY_ALLOCATION_ERROR = -22,

    __CRAWDOG_ARGON2_FREE_MEMORY_CBK_NULL = -23,
    __CRAWDOG_ARGON2_ALLOCATE_MEMORY_CBK_NULL = -24,

    __CRAWDOG_ARGON2_INCORRECT_PARAMETER = -25,
    __CRAWDOG_ARGON2_INCORRECT_TYPE = -26,

    __CRAWDOG_ARGON2_OUT_PTR_MISMATCH = -27,

    __CRAWDOG_ARGON2_THREADS_TOO_FEW = -28,
    __CRAWDOG_ARGON2_THREADS_TOO_MANY = -29,

    __CRAWDOG_ARGON2_MISSING_ARGS = -30,

    __CRAWDOG_ARGON2_ENCODING_FAIL = -31,

    __CRAWDOG_ARGON2_DECODING_FAIL = -32,

    __CRAWDOG_ARGON2_THREAD_FAIL = -33,

    __CRAWDOG_ARGON2_DECODING_LENGTH_FAIL = -34,

    __CRAWDOG_ARGON2_VERIFY_MISMATCH = -35
} __crawdog_argon2_error_codes;

/* Memory allocator types --- for external allocation */
typedef int (*allocate_fptr)(uint8_t **memory, size_t bytes_to_allocate);
typedef void (*deallocate_fptr)(uint8_t *memory, size_t bytes_to_allocate);

/* Argon2 external data structures */

/*
 *****
 * Context: structure to hold Argon2 inputs:
 *  output array and its length,
 *  password and its length,
 *  salt and its length,
 *  secret and its length,
 *  associated data and its length,
 *  number of passes, amount of used memory (in KBytes, can be rounded up a bit)
 *  number of parallel threads that will be run.
 * All the parameters above affect the output hash value.
 * Additionally, two function pointers can be provided to allocate and
 * deallocate the memory (if NULL, memory will be allocated internally).
 * Also, three flags indicate whether to erase password, secret as soon as they
 * are pre-hashed (and thus not needed anymore), and the entire memory
 *****
 * Simplest situation: you have output array out[8], password is stored in
 * pwd[32], salt is stored in salt[16], you do not have keys nor associated
 * data. You need to spend 1 GB of RAM and you run 5 passes of Argon2d with
 * 4 parallel lanes.
 * You want to erase the password, but you're OK with last pass not being
 * erased. You want to use the default memory allocator.
 * Then you initialize:
 Argon2_Context(out,8,pwd,32,salt,16,NULL,0,NULL,0,5,1<<20,4,4,NULL,NULL,true,false,false,false)
 */
typedef struct Argon2_Context {
    uint8_t *out;    /* output array */
    uint32_t outlen; /* digest length */

    uint8_t *pwd;    /* password array */
    uint32_t pwdlen; /* password length */

    uint8_t *salt;    /* salt array */
    uint32_t saltlen; /* salt length */

    uint8_t *secret;    /* key array */
    uint32_t secretlen; /* key length */

    uint8_t *ad;    /* associated data array */
    uint32_t adlen; /* associated data length */

    uint32_t t_cost;  /* number of passes */
    uint32_t m_cost;  /* amount of memory requested (KB) */
    uint32_t lanes;   /* number of lanes */
    uint32_t threads; /* maximum number of threads */

    uint32_t version; /* version number */

    allocate_fptr allocate_cbk; /* pointer to memory allocator */
    deallocate_fptr free_cbk;   /* pointer to memory deallocator */

    uint32_t flags; /* array of bool options */
} __crawdog_argon2_context;

/* Argon2 primitive type */
typedef enum Argon2_type {
  Argon2_d = 0,
  Argon2_i = 1,
  Argon2_id = 2
} __crawdog_argon2_type;

/* Version of the algorithm */
typedef enum Argon2_version {
    __CRAWDOG_ARGON2_VERSION_10 = 0x10,
    __CRAWDOG_ARGON2_VERSION_13 = 0x13,
    __CRAWDOG_ARGON2_VERSION_NUMBER = __CRAWDOG_ARGON2_VERSION_13
} __crawdog_argon2_version;

/*
 * Function that gives the string representation of an __crawdog_argon2_type.
 * @param type The __crawdog_argon2_type that we want the string for
 * @param uppercase Whether the string should have the first letter uppercase
 * @return NULL if invalid type, otherwise the string representation.
 */
__CRAWDOG_ARGON2_PUBLIC const char *__crawdog_argon2_type2string(__crawdog_argon2_type type, int uppercase);

/*
 * Function that performs memory-hard hashing with certain degree of parallelism
 * @param  context  Pointer to the Argon2 internal structure
 * @return Error code if smth is wrong, __CRAWDOG_ARGON2_OK otherwise
 */
__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2_ctx(__crawdog_argon2_context *context, __crawdog_argon2_type type);

/**
 * Hashes a password with Argon2i, producing an encoded hash
 * @param t_cost Number of iterations
 * @param m_cost Sets memory usage to m_cost kibibytes
 * @param parallelism Number of threads and compute lanes
 * @param pwd Pointer to password
 * @param pwdlen Password size in bytes
 * @param salt Pointer to salt
 * @param saltlen Salt size in bytes
 * @param hashlen Desired length of the hash in bytes
 * @param encoded Buffer where to write the encoded hash
 * @param encodedlen Size of the buffer (thus max size of the encoded hash)
 * @pre   Different parallelism levels will give different results
 * @pre   Returns __CRAWDOG_ARGON2_OK if successful
 */
__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2i_hash_encoded(const uint32_t t_cost,
                                       const uint32_t m_cost,
                                       const uint32_t parallelism,
                                       const void *pwd, const size_t pwdlen,
                                       const void *salt, const size_t saltlen,
                                       const size_t hashlen, char *encoded,
                                       const size_t encodedlen);

/**
 * Hashes a password with Argon2i, producing a raw hash at @hash
 * @param t_cost Number of iterations
 * @param m_cost Sets memory usage to m_cost kibibytes
 * @param parallelism Number of threads and compute lanes
 * @param pwd Pointer to password
 * @param pwdlen Password size in bytes
 * @param salt Pointer to salt
 * @param saltlen Salt size in bytes
 * @param hash Buffer where to write the raw hash - updated by the function
 * @param hashlen Desired length of the hash in bytes
 * @pre   Different parallelism levels will give different results
 * @pre   Returns __CRAWDOG_ARGON2_OK if successful
 */
__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2i_hash_raw(const uint32_t t_cost, const uint32_t m_cost,
                                   const uint32_t parallelism, const void *pwd,
                                   const size_t pwdlen, const void *salt,
                                   const size_t saltlen, void *hash,
                                   const size_t hashlen);

__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2d_hash_encoded(const uint32_t t_cost,
                                       const uint32_t m_cost,
                                       const uint32_t parallelism,
                                       const void *pwd, const size_t pwdlen,
                                       const void *salt, const size_t saltlen,
                                       const size_t hashlen, char *encoded,
                                       const size_t encodedlen);

__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2d_hash_raw(const uint32_t t_cost, const uint32_t m_cost,
                                   const uint32_t parallelism, const void *pwd,
                                   const size_t pwdlen, const void *salt,
                                   const size_t saltlen, void *hash,
                                   const size_t hashlen);

__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2id_hash_encoded(const uint32_t t_cost,
                                        const uint32_t m_cost,
                                        const uint32_t parallelism,
                                        const void *pwd, const size_t pwdlen,
                                        const void *salt, const size_t saltlen,
                                        const size_t hashlen, char *encoded,
                                        const size_t encodedlen);

__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2id_hash_raw(const uint32_t t_cost,
                                    const uint32_t m_cost,
                                    const uint32_t parallelism, const void *pwd,
                                    const size_t pwdlen, const void *salt,
                                    const size_t saltlen, void *hash,
                                    const size_t hashlen);

/* generic function underlying the above ones */
__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2_hash(const uint32_t t_cost, const uint32_t m_cost,
                              const uint32_t parallelism, const void *pwd,
                              const size_t pwdlen, const void *salt,
                              const size_t saltlen, void *hash,
                              const size_t hashlen, char *encoded,
                              const size_t encodedlen, __crawdog_argon2_type type,
                              const uint32_t version);

/**
 * Verifies a password against an encoded string
 * Encoded string is restricted as in validate_inputs()
 * @param encoded String encoding parameters, salt, hash
 * @param pwd Pointer to password
 * @pre   Returns __CRAWDOG_ARGON2_OK if successful
 */
__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2i_verify(const char *encoded, const void *pwd,
                                 const size_t pwdlen);

__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2d_verify(const char *encoded, const void *pwd,
                                 const size_t pwdlen);

__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2id_verify(const char *encoded, const void *pwd,
                                  const size_t pwdlen);

/* generic function underlying the above ones */
__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2_verify(const char *encoded, const void *pwd,
                                const size_t pwdlen, __crawdog_argon2_type type);

/**
 * Argon2d: Version of Argon2 that picks memory blocks depending
 * on the password and salt. Only for side-channel-free
 * environment!!
 *****
 * @param  context  Pointer to current Argon2 context
 * @return  Zero if successful, a non zero error code otherwise
 */
__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2d_ctx(__crawdog_argon2_context *context);

/**
 * Argon2i: Version of Argon2 that picks memory blocks
 * independent on the password and salt. Good for side-channels,
 * but worse w.r.t. tradeoff attacks if only one pass is used.
 *****
 * @param  context  Pointer to current Argon2 context
 * @return  Zero if successful, a non zero error code otherwise
 */
__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2i_ctx(__crawdog_argon2_context *context);

/**
 * Argon2id: Version of Argon2 where the first half-pass over memory is
 * password-independent, the rest are password-dependent (on the password and
 * salt). OK against side channels (they reduce to 1/2-pass Argon2i), and
 * better with w.r.t. tradeoff attacks (similar to Argon2d).
 *****
 * @param  context  Pointer to current Argon2 context
 * @return  Zero if successful, a non zero error code otherwise
 */
__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2id_ctx(__crawdog_argon2_context *context);

/**
 * Verify if a given password is correct for Argon2d hashing
 * @param  context  Pointer to current Argon2 context
 * @param  hash  The password hash to verify. The length of the hash is
 * specified by the context outlen member
 * @return  Zero if successful, a non zero error code otherwise
 */
__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2d_verify_ctx(__crawdog_argon2_context *context, const char *hash);

/**
 * Verify if a given password is correct for Argon2i hashing
 * @param  context  Pointer to current Argon2 context
 * @param  hash  The password hash to verify. The length of the hash is
 * specified by the context outlen member
 * @return  Zero if successful, a non zero error code otherwise
 */
__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2i_verify_ctx(__crawdog_argon2_context *context, const char *hash);

/**
 * Verify if a given password is correct for Argon2id hashing
 * @param  context  Pointer to current Argon2 context
 * @param  hash  The password hash to verify. The length of the hash is
 * specified by the context outlen member
 * @return  Zero if successful, a non zero error code otherwise
 */
__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2id_verify_ctx(__crawdog_argon2_context *context,
                                      const char *hash);

/* generic function underlying the above ones */
__CRAWDOG_ARGON2_PUBLIC int __crawdog_argon2_verify_ctx(__crawdog_argon2_context *context, const char *hash,
                                    __crawdog_argon2_type type);

/**
 * Get the associated error message for given error code
 * @return  The error message associated with the given error code
 */
__CRAWDOG_ARGON2_PUBLIC const char *__crawdog_argon2_error_message(int error_code);

/**
 * Returns the encoded hash length for the given input parameters
 * @param t_cost  Number of iterations
 * @param m_cost  Memory usage in kibibytes
 * @param parallelism  Number of threads; used to compute lanes
 * @param saltlen  Salt size in bytes
 * @param hashlen  Hash size in bytes
 * @param type The __crawdog_argon2_type that we want the encoded length for
 * @return  The encoded hash length in bytes
 */
__CRAWDOG_ARGON2_PUBLIC size_t __crawdog_argon2_encodedlen(uint32_t t_cost, uint32_t m_cost,
                                       uint32_t parallelism, uint32_t saltlen,
                                       uint32_t hashlen, __crawdog_argon2_type type);

#endif
