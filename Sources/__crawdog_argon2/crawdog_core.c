// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
/*For memory wiping*/
#ifdef _WIN32
#include <windows.h>
#include <winbase.h> /* For SecureZeroMemory */
#endif
#if defined __STDC_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
#define VC_GE_2005(version) (version >= 1400)

/* for explicit_bzero() on glibc */
#define _DEFAULT_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "crawdog_core.h"
#include "crawdog_thread.h"
#include "crawdog_blake2.h"
#include "crawdog_blake2-impl.h"
#include "crawdog_blake2addition.h"

#ifdef GENKAT
#include "genkat.h"
#endif

#if defined(__clang__)
#if __has_attribute(optnone)
#define NOT_OPTIMIZED __attribute__((optnone))
#endif
#elif defined(__GNUC__)
#define GCC_VERSION                                                            \
    (__GNUC__ * 10000 + __GNUC_MINOR__ * 100 + __GNUC_PATCHLEVEL__)
#if GCC_VERSION >= 40400
#define NOT_OPTIMIZED __attribute__((optimize("O0")))
#endif
#endif
#ifndef NOT_OPTIMIZED
#define NOT_OPTIMIZED
#endif

/***************Instance and Position constructors**********/
void init_block_value(block *b, uint8_t in) { memset(b->v, in, sizeof(b->v)); }

void copy_block(block *dst, const block *src) {
    memcpy(dst->v, src->v, sizeof(uint64_t) * __CRAWDOG_ARGON2_QWORDS_IN_BLOCK);
}

void xor_block(block *dst, const block *src) {
    int i;
    for (i = 0; i < __CRAWDOG_ARGON2_QWORDS_IN_BLOCK; ++i) {
        dst->v[i] ^= src->v[i];
    }
}

static void load_block(block *dst, const void *input) {
    unsigned i;
    for (i = 0; i < __CRAWDOG_ARGON2_QWORDS_IN_BLOCK; ++i) {
        dst->v[i] = load64((const uint8_t *)input + i * sizeof(dst->v[i]));
    }
}

static void store_block(void *output, const block *src) {
    unsigned i;
    for (i = 0; i < __CRAWDOG_ARGON2_QWORDS_IN_BLOCK; ++i) {
        store64((uint8_t *)output + i * sizeof(src->v[i]), src->v[i]);
    }
}

/***************Memory functions*****************/

int allocate_memory(const __crawdog_argon2_context *context, uint8_t **memory,
                    size_t num, size_t size) {
    size_t memory_size = num*size;
    if (memory == NULL) {
        return __CRAWDOG_ARGON2_MEMORY_ALLOCATION_ERROR;
    }

    /* 1. Check for multiplication overflow */
    if (size != 0 && memory_size / size != num) {
        return __CRAWDOG_ARGON2_MEMORY_ALLOCATION_ERROR;
    }

    /* 2. Try to allocate with appropriate allocator */
    if (context->allocate_cbk) {
        (context->allocate_cbk)(memory, memory_size);
    } else {
        *memory = malloc(memory_size);
    }

    if (*memory == NULL) {
        return __CRAWDOG_ARGON2_MEMORY_ALLOCATION_ERROR;
    }

    return __CRAWDOG_ARGON2_OK;
}

void free_memory(const __crawdog_argon2_context *context, uint8_t *memory,
                 size_t num, size_t size) {
    size_t memory_size = num*size;
    clear_internal_memory(memory, memory_size);
    if (context->free_cbk) {
        (context->free_cbk)(memory, memory_size);
    } else {
        free(memory);
    }
}

#if defined(__OpenBSD__)
#define HAVE_EXPLICIT_BZERO 1
#elif defined(__GLIBC__) && defined(__GLIBC_PREREQ)
#if __GLIBC_PREREQ(2,25)
#define HAVE_EXPLICIT_BZERO 1
#endif
#endif

void NOT_OPTIMIZED secure_wipe_memory(void *v, size_t n) {
#if defined(_MSC_VER) && VC_GE_2005(_MSC_VER) || defined(__MINGW32__)
    SecureZeroMemory(v, n);
#elif defined memset_s
    memset_s(v, n, 0, n);
#elif defined(HAVE_EXPLICIT_BZERO)
    explicit_bzero(v, n);
#else
    static void *(*const volatile memset_sec)(void *, int, size_t) = &memset;
    memset_sec(v, 0, n);
#endif
}

/* Memory clear flag defaults to true. */
int FLAG_clear_internal_memory = 1;
void clear_internal_memory(void *v, size_t n) {
  if (FLAG_clear_internal_memory && v) {
    secure_wipe_memory(v, n);
  }
}

void finalize(const __crawdog_argon2_context *context, __crawdog_argon2_instance_t *instance) {
    if (context != NULL && instance != NULL) {
        block blockhash;
        uint32_t l;

        copy_block(&blockhash, instance->memory + instance->lane_length - 1);

        /* XOR the last blocks */
        for (l = 1; l < instance->lanes; ++l) {
            uint32_t last_block_in_lane =
                l * instance->lane_length + (instance->lane_length - 1);
            xor_block(&blockhash, instance->memory + last_block_in_lane);
        }

        /* Hash the result */
        {
            uint8_t blockhash_bytes[__CRAWDOG_ARGON2_BLOCK_SIZE];
            store_block(blockhash_bytes, &blockhash);
            __crawdog_blake2b_long(context->out, context->outlen, blockhash_bytes,
                         __CRAWDOG_ARGON2_BLOCK_SIZE);
            /* clear blockhash and blockhash_bytes */
            clear_internal_memory(blockhash.v, __CRAWDOG_ARGON2_BLOCK_SIZE);
            clear_internal_memory(blockhash_bytes, __CRAWDOG_ARGON2_BLOCK_SIZE);
        }

#ifdef GENKAT
        print_tag(context->out, context->outlen);
#endif

        free_memory(context, (uint8_t *)instance->memory,
                    instance->memory_blocks, sizeof(block));
    }
}

uint32_t index_alpha(const __crawdog_argon2_instance_t *instance,
                     const __crawdog_argon2_position_t *position, uint32_t pseudo_rand,
                     int same_lane) {
    /*
     * Pass 0:
     *      This lane : all already finished segments plus already constructed
     * blocks in this segment
     *      Other lanes : all already finished segments
     * Pass 1+:
     *      This lane : (SYNC_POINTS - 1) last segments plus already constructed
     * blocks in this segment
     *      Other lanes : (SYNC_POINTS - 1) last segments
     */
    uint32_t reference_area_size;
    uint64_t relative_position;
    uint32_t start_position, absolute_position;

    if (0 == position->pass) {
        /* First pass */
        if (0 == position->slice) {
            /* First slice */
            reference_area_size =
                position->index - 1; /* all but the previous */
        } else {
            if (same_lane) {
                /* The same lane => add current segment */
                reference_area_size =
                    position->slice * instance->segment_length +
                    position->index - 1;
            } else {
                reference_area_size =
                    position->slice * instance->segment_length +
                    ((position->index == 0) ? (-1) : 0);
            }
        }
    } else {
        /* Second pass */
        if (same_lane) {
            reference_area_size = instance->lane_length -
                                  instance->segment_length + position->index -
                                  1;
        } else {
            reference_area_size = instance->lane_length -
                                  instance->segment_length +
                                  ((position->index == 0) ? (-1) : 0);
        }
    }

    /* 1.2.4. Mapping pseudo_rand to 0..<reference_area_size-1> and produce
     * relative position */
    relative_position = pseudo_rand;
    relative_position = relative_position * relative_position >> 32;
    relative_position = reference_area_size - 1 -
                        (reference_area_size * relative_position >> 32);

    /* 1.2.5 Computing starting position */
    start_position = 0;

    if (0 != position->pass) {
        start_position = (position->slice == __CRAWDOG_ARGON2_SYNC_POINTS - 1)
                             ? 0
                             : (position->slice + 1) * instance->segment_length;
    }

    /* 1.2.6. Computing absolute position */
    absolute_position = (start_position + relative_position) %
                        instance->lane_length; /* absolute position */
    return absolute_position;
}

/* Single-threaded version for p=1 case */
static int fill_memory_blocks_st(__crawdog_argon2_instance_t *instance) {
    uint32_t r, s, l;

    for (r = 0; r < instance->passes; ++r) {
        for (s = 0; s < __CRAWDOG_ARGON2_SYNC_POINTS; ++s) {
            for (l = 0; l < instance->lanes; ++l) {
                __crawdog_argon2_position_t position = {r, l, (uint8_t)s, 0};
                fill_segment(instance, position);
            }
        }
#ifdef GENKAT
        internal_kat(instance, r); /* Print all memory blocks */
#endif
    }
    return __CRAWDOG_ARGON2_OK;
}

#if !defined(__CRAWDOG_ARGON2_NO_THREADS)

#ifdef _WIN32
static unsigned __stdcall fill_segment_thr(void *thread_data)
#else
static void *fill_segment_thr(void *thread_data)
#endif
{
    __crawdog_argon2_thread_data *my_data = thread_data;
    fill_segment(my_data->instance_ptr, my_data->pos);
    __crawdog_argon2_thread_exit();
    return 0;
}

/* Multi-threaded version for p > 1 case */
static int fill_memory_blocks_mt(__crawdog_argon2_instance_t *instance) {
    uint32_t r, s;
    __crawdog_argon2_thread_handle_t *thread = NULL;
    __crawdog_argon2_thread_data *thr_data = NULL;
    int rc = __CRAWDOG_ARGON2_OK;

    /* 1. Allocating space for threads */
    thread = calloc(instance->lanes, sizeof(__crawdog_argon2_thread_handle_t));
    if (thread == NULL) {
        rc = __CRAWDOG_ARGON2_MEMORY_ALLOCATION_ERROR;
        goto fail;
    }

    thr_data = calloc(instance->lanes, sizeof(__crawdog_argon2_thread_data));
    if (thr_data == NULL) {
        rc = __CRAWDOG_ARGON2_MEMORY_ALLOCATION_ERROR;
        goto fail;
    }

    for (r = 0; r < instance->passes; ++r) {
        for (s = 0; s < __CRAWDOG_ARGON2_SYNC_POINTS; ++s) {
            uint32_t l, ll;

            /* 2. Calling threads */
            for (l = 0; l < instance->lanes; ++l) {
                __crawdog_argon2_position_t position;

                /* 2.1 Join a thread if limit is exceeded */
                if (l >= instance->threads) {
                    if (__crawdog_argon2_thread_join(thread[l - instance->threads])) {
                        rc = __CRAWDOG_ARGON2_THREAD_FAIL;
                        goto fail;
                    }
                }

                /* 2.2 Create thread */
                position.pass = r;
                position.lane = l;
                position.slice = (uint8_t)s;
                position.index = 0;
                thr_data[l].instance_ptr =
                    instance; /* preparing the thread input */
                memcpy(&(thr_data[l].pos), &position,
                       sizeof(__crawdog_argon2_position_t));
                if (__crawdog_argon2_thread_create(&thread[l], &fill_segment_thr,
                                         (void *)&thr_data[l])) {
                    /* Wait for already running threads */
                    for (ll = 0; ll < l; ++ll)
                        __crawdog_argon2_thread_join(thread[ll]);
                    rc = __CRAWDOG_ARGON2_THREAD_FAIL;
                    goto fail;
                }

                /* fill_segment(instance, position); */
                /*Non-thread equivalent of the lines above */
            }

            /* 3. Joining remaining threads */
            for (l = instance->lanes - instance->threads; l < instance->lanes;
                 ++l) {
                if (__crawdog_argon2_thread_join(thread[l])) {
                    rc = __CRAWDOG_ARGON2_THREAD_FAIL;
                    goto fail;
                }
            }
        }

#ifdef GENKAT
        internal_kat(instance, r); /* Print all memory blocks */
#endif
    }

fail:
    if (thread != NULL) {
        free(thread);
    }
    if (thr_data != NULL) {
        free(thr_data);
    }
    return rc;
}

#endif /* __CRAWDOG_ARGON2_NO_THREADS */

int fill_memory_blocks(__crawdog_argon2_instance_t *instance) {
	if (instance == NULL || instance->lanes == 0) {
	    return __CRAWDOG_ARGON2_INCORRECT_PARAMETER;
    }
#if defined(__CRAWDOG_ARGON2_NO_THREADS)
    return fill_memory_blocks_st(instance);
#else
    return instance->threads == 1 ?
			fill_memory_blocks_st(instance) : fill_memory_blocks_mt(instance);
#endif
}

int validate_inputs(const __crawdog_argon2_context *context) {
    if (NULL == context) {
        return __CRAWDOG_ARGON2_INCORRECT_PARAMETER;
    }

    if (NULL == context->out) {
        return __CRAWDOG_ARGON2_OUTPUT_PTR_NULL;
    }

    /* Validate output length */
    if (__CRAWDOG_ARGON2_MIN_OUTLEN > context->outlen) {
        return __CRAWDOG_ARGON2_OUTPUT_TOO_SHORT;
    }

    if (__CRAWDOG_ARGON2_MAX_OUTLEN < context->outlen) {
        return __CRAWDOG_ARGON2_OUTPUT_TOO_LONG;
    }

    /* Validate password (required param) */
    if (NULL == context->pwd) {
        if (0 != context->pwdlen) {
            return __CRAWDOG_ARGON2_PWD_PTR_MISMATCH;
        }
    }

    if (__CRAWDOG_ARGON2_MIN_PWD_LENGTH > context->pwdlen) {
      return __CRAWDOG_ARGON2_PWD_TOO_SHORT;
    }

    if (__CRAWDOG_ARGON2_MAX_PWD_LENGTH < context->pwdlen) {
        return __CRAWDOG_ARGON2_PWD_TOO_LONG;
    }

    /* Validate salt (required param) */
    if (NULL == context->salt) {
        if (0 != context->saltlen) {
            return __CRAWDOG_ARGON2_SALT_PTR_MISMATCH;
        }
    }

    if (__CRAWDOG_ARGON2_MIN_SALT_LENGTH > context->saltlen) {
        return __CRAWDOG_ARGON2_SALT_TOO_SHORT;
    }

    if (__CRAWDOG_ARGON2_MAX_SALT_LENGTH < context->saltlen) {
        return __CRAWDOG_ARGON2_SALT_TOO_LONG;
    }

    /* Validate secret (optional param) */
    if (NULL == context->secret) {
        if (0 != context->secretlen) {
            return __CRAWDOG_ARGON2_SECRET_PTR_MISMATCH;
        }
    } else {
        if (__CRAWDOG_ARGON2_MIN_SECRET > context->secretlen) {
            return __CRAWDOG_ARGON2_SECRET_TOO_SHORT;
        }
        if (__CRAWDOG_ARGON2_MAX_SECRET < context->secretlen) {
            return __CRAWDOG_ARGON2_SECRET_TOO_LONG;
        }
    }

    /* Validate associated data (optional param) */
    if (NULL == context->ad) {
        if (0 != context->adlen) {
            return __CRAWDOG_ARGON2_AD_PTR_MISMATCH;
        }
    } else {
        if (__CRAWDOG_ARGON2_MIN_AD_LENGTH > context->adlen) {
            return __CRAWDOG_ARGON2_AD_TOO_SHORT;
        }
        if (__CRAWDOG_ARGON2_MAX_AD_LENGTH < context->adlen) {
            return __CRAWDOG_ARGON2_AD_TOO_LONG;
        }
    }

    /* Validate memory cost */
    if (__CRAWDOG_ARGON2_MIN_MEMORY > context->m_cost) {
        return __CRAWDOG_ARGON2_MEMORY_TOO_LITTLE;
    }

    if (__CRAWDOG_ARGON2_MAX_MEMORY < context->m_cost) {
        return __CRAWDOG_ARGON2_MEMORY_TOO_MUCH;
    }

    if (context->m_cost < 8 * context->lanes) {
        return __CRAWDOG_ARGON2_MEMORY_TOO_LITTLE;
    }

    /* Validate time cost */
    if (__CRAWDOG_ARGON2_MIN_TIME > context->t_cost) {
        return __CRAWDOG_ARGON2_TIME_TOO_SMALL;
    }

    if (__CRAWDOG_ARGON2_MAX_TIME < context->t_cost) {
        return __CRAWDOG_ARGON2_TIME_TOO_LARGE;
    }

    /* Validate lanes */
    if (__CRAWDOG_ARGON2_MIN_LANES > context->lanes) {
        return __CRAWDOG_ARGON2_LANES_TOO_FEW;
    }

    if (__CRAWDOG_ARGON2_MAX_LANES < context->lanes) {
        return __CRAWDOG_ARGON2_LANES_TOO_MANY;
    }

    /* Validate threads */
    if (__CRAWDOG_ARGON2_MIN_THREADS > context->threads) {
        return __CRAWDOG_ARGON2_THREADS_TOO_FEW;
    }

    if (__CRAWDOG_ARGON2_MAX_THREADS < context->threads) {
        return __CRAWDOG_ARGON2_THREADS_TOO_MANY;
    }

    if (NULL != context->allocate_cbk && NULL == context->free_cbk) {
        return __CRAWDOG_ARGON2_FREE_MEMORY_CBK_NULL;
    }

    if (NULL == context->allocate_cbk && NULL != context->free_cbk) {
        return __CRAWDOG_ARGON2_ALLOCATE_MEMORY_CBK_NULL;
    }

    return __CRAWDOG_ARGON2_OK;
}

void fill_first_blocks(uint8_t *blockhash, const __crawdog_argon2_instance_t *instance) {
    uint32_t l;
    /* Make the first and second block in each lane as G(H0||0||i) or
       G(H0||1||i) */
    uint8_t blockhash_bytes[__CRAWDOG_ARGON2_BLOCK_SIZE];
    for (l = 0; l < instance->lanes; ++l) {

        store32(blockhash + __CRAWDOG_ARGON2_PREHASH_DIGEST_LENGTH, 0);
        store32(blockhash + __CRAWDOG_ARGON2_PREHASH_DIGEST_LENGTH + 4, l);
        __crawdog_blake2b_long(blockhash_bytes, __CRAWDOG_ARGON2_BLOCK_SIZE, blockhash,
                     __CRAWDOG_ARGON2_PREHASH_SEED_LENGTH);
        load_block(&instance->memory[l * instance->lane_length + 0],
                   blockhash_bytes);

        store32(blockhash + __CRAWDOG_ARGON2_PREHASH_DIGEST_LENGTH, 1);
        __crawdog_blake2b_long(blockhash_bytes, __CRAWDOG_ARGON2_BLOCK_SIZE, blockhash,
                     __CRAWDOG_ARGON2_PREHASH_SEED_LENGTH);
        load_block(&instance->memory[l * instance->lane_length + 1],
                   blockhash_bytes);
    }
    clear_internal_memory(blockhash_bytes, __CRAWDOG_ARGON2_BLOCK_SIZE);
}

void initial_hash(uint8_t *blockhash, __crawdog_argon2_context *context,
                  __crawdog_argon2_type type) {
    __crawdog_blake2b_state BlakeHash;
    uint8_t value[sizeof(uint32_t)];

    if (NULL == context || NULL == blockhash) {
        return;
    }

    __crawdog_blake2b_init(&BlakeHash, __CRAWDOG_ARGON2_PREHASH_DIGEST_LENGTH);

    store32(&value, context->lanes);
    __crawdog_blake2b_update(&BlakeHash, (const uint8_t *)&value, sizeof(value));

    store32(&value, context->outlen);
    __crawdog_blake2b_update(&BlakeHash, (const uint8_t *)&value, sizeof(value));

    store32(&value, context->m_cost);
    __crawdog_blake2b_update(&BlakeHash, (const uint8_t *)&value, sizeof(value));

    store32(&value, context->t_cost);
    __crawdog_blake2b_update(&BlakeHash, (const uint8_t *)&value, sizeof(value));

    store32(&value, context->version);
    __crawdog_blake2b_update(&BlakeHash, (const uint8_t *)&value, sizeof(value));

    store32(&value, (uint32_t)type);
    __crawdog_blake2b_update(&BlakeHash, (const uint8_t *)&value, sizeof(value));

    store32(&value, context->pwdlen);
    __crawdog_blake2b_update(&BlakeHash, (const uint8_t *)&value, sizeof(value));

    if (context->pwd != NULL) {
        __crawdog_blake2b_update(&BlakeHash, (const uint8_t *)context->pwd,
                       context->pwdlen);

        if (context->flags & __CRAWDOG_ARGON2_FLAG_CLEAR_PASSWORD) {
            secure_wipe_memory(context->pwd, context->pwdlen);
            context->pwdlen = 0;
        }
    }

    store32(&value, context->saltlen);
    __crawdog_blake2b_update(&BlakeHash, (const uint8_t *)&value, sizeof(value));

    if (context->salt != NULL) {
        __crawdog_blake2b_update(&BlakeHash, (const uint8_t *)context->salt,
                       context->saltlen);
    }

    store32(&value, context->secretlen);
    __crawdog_blake2b_update(&BlakeHash, (const uint8_t *)&value, sizeof(value));

    if (context->secret != NULL) {
        __crawdog_blake2b_update(&BlakeHash, (const uint8_t *)context->secret,
                       context->secretlen);

        if (context->flags & __CRAWDOG_ARGON2_FLAG_CLEAR_SECRET) {
            secure_wipe_memory(context->secret, context->secretlen);
            context->secretlen = 0;
        }
    }

    store32(&value, context->adlen);
    __crawdog_blake2b_update(&BlakeHash, (const uint8_t *)&value, sizeof(value));

    if (context->ad != NULL) {
        __crawdog_blake2b_update(&BlakeHash, (const uint8_t *)context->ad,
                       context->adlen);
    }

    __crawdog_blake2b_final(&BlakeHash, blockhash, __CRAWDOG_ARGON2_PREHASH_DIGEST_LENGTH);
}

int initialize(__crawdog_argon2_instance_t *instance, __crawdog_argon2_context *context) {
    uint8_t blockhash[__CRAWDOG_ARGON2_PREHASH_SEED_LENGTH];
    int result = __CRAWDOG_ARGON2_OK;

    if (instance == NULL || context == NULL)
        return __CRAWDOG_ARGON2_INCORRECT_PARAMETER;
    instance->context_ptr = context;

    /* 1. Memory allocation */
    result = allocate_memory(context, (uint8_t **)&(instance->memory),
                             instance->memory_blocks, sizeof(block));
    if (result != __CRAWDOG_ARGON2_OK) {
        return result;
    }

    /* 2. Initial hashing */
    /* H_0 + 8 extra bytes to produce the first blocks */
    /* uint8_t blockhash[__CRAWDOG_ARGON2_PREHASH_SEED_LENGTH]; */
    /* Hashing all inputs */
    initial_hash(blockhash, context, instance->type);
    /* Zeroing 8 extra bytes */
    clear_internal_memory(blockhash + __CRAWDOG_ARGON2_PREHASH_DIGEST_LENGTH,
                          __CRAWDOG_ARGON2_PREHASH_SEED_LENGTH -
                              __CRAWDOG_ARGON2_PREHASH_DIGEST_LENGTH);

#ifdef GENKAT
    initial_kat(blockhash, context, instance->type);
#endif

    /* 3. Creating first blocks, we always have at least two blocks in a slice
     */
    fill_first_blocks(blockhash, instance);
    /* Clearing the hash */
    clear_internal_memory(blockhash, __CRAWDOG_ARGON2_PREHASH_SEED_LENGTH);

    return __CRAWDOG_ARGON2_OK;
}
