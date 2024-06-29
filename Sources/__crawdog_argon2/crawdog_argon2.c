// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "crawdog_argon2.h"
#include "crawdog_encoding.h"
#include "crawdog_core.h"

const char *__crawdog_argon2_type2string(__crawdog_argon2_type type, int uppercase) {
    switch (type) {
        case Argon2_d:
            return uppercase ? "Argon2d" : "__crawdog_argon2d";
        case Argon2_i:
            return uppercase ? "Argon2i" : "__crawdog_argon2i";
        case Argon2_id:
            return uppercase ? "Argon2id" : "__crawdog_argon2id";
    }

    return NULL;
}

int __crawdog_argon2_ctx(__crawdog_argon2_context *context, __crawdog_argon2_type type) {
    /* 1. Validate all inputs */
    int result = validate_inputs(context);
    uint32_t memory_blocks, segment_length;
    __crawdog_argon2_instance_t instance;

    if (__CRAWDOG_ARGON2_OK != result) {
        return result;
    }

    if (Argon2_d != type && Argon2_i != type && Argon2_id != type) {
        return __CRAWDOG_ARGON2_INCORRECT_TYPE;
    }

    /* 2. Align memory size */
    /* Minimum memory_blocks = 8L blocks, where L is the number of lanes */
    memory_blocks = context->m_cost;

    if (memory_blocks < 2 * __CRAWDOG_ARGON2_SYNC_POINTS * context->lanes) {
        memory_blocks = 2 * __CRAWDOG_ARGON2_SYNC_POINTS * context->lanes;
    }

    segment_length = memory_blocks / (context->lanes * __CRAWDOG_ARGON2_SYNC_POINTS);
    /* Ensure that all segments have equal length */
    memory_blocks = segment_length * (context->lanes * __CRAWDOG_ARGON2_SYNC_POINTS);

    instance.version = context->version;
    instance.memory = NULL;
    instance.passes = context->t_cost;
    instance.memory_blocks = memory_blocks;
    instance.segment_length = segment_length;
    instance.lane_length = segment_length * __CRAWDOG_ARGON2_SYNC_POINTS;
    instance.lanes = context->lanes;
    instance.threads = context->threads;
    instance.type = type;

    if (instance.threads > instance.lanes) {
        instance.threads = instance.lanes;
    }

    /* 3. Initialization: Hashing inputs, allocating memory, filling first
     * blocks
     */
    result = initialize(&instance, context);

    if (__CRAWDOG_ARGON2_OK != result) {
        return result;
    }

    /* 4. Filling memory */
    result = fill_memory_blocks(&instance);

    if (__CRAWDOG_ARGON2_OK != result) {
        return result;
    }
    /* 5. Finalization */
    finalize(context, &instance);

    return __CRAWDOG_ARGON2_OK;
}

int __crawdog_argon2_hash(const uint32_t t_cost, const uint32_t m_cost,
                const uint32_t parallelism, const void *pwd,
                const size_t pwdlen, const void *salt, const size_t saltlen,
                void *hash, const size_t hashlen, char *encoded,
                const size_t encodedlen, __crawdog_argon2_type type,
                const uint32_t version){

    __crawdog_argon2_context context;
    int result;
    uint8_t *out;

    if (pwdlen > __CRAWDOG_ARGON2_MAX_PWD_LENGTH) {
        return __CRAWDOG_ARGON2_PWD_TOO_LONG;
    }

    if (saltlen > __CRAWDOG_ARGON2_MAX_SALT_LENGTH) {
        return __CRAWDOG_ARGON2_SALT_TOO_LONG;
    }

    if (hashlen > __CRAWDOG_ARGON2_MAX_OUTLEN) {
        return __CRAWDOG_ARGON2_OUTPUT_TOO_LONG;
    }

    if (hashlen < __CRAWDOG_ARGON2_MIN_OUTLEN) {
        return __CRAWDOG_ARGON2_OUTPUT_TOO_SHORT;
    }

    out = malloc(hashlen);
    if (!out) {
        return __CRAWDOG_ARGON2_MEMORY_ALLOCATION_ERROR;
    }

    context.out = (uint8_t *)out;
    context.outlen = (uint32_t)hashlen;
    context.pwd = CONST_CAST(uint8_t *)pwd;
    context.pwdlen = (uint32_t)pwdlen;
    context.salt = CONST_CAST(uint8_t *)salt;
    context.saltlen = (uint32_t)saltlen;
    context.secret = NULL;
    context.secretlen = 0;
    context.ad = NULL;
    context.adlen = 0;
    context.t_cost = t_cost;
    context.m_cost = m_cost;
    context.lanes = parallelism;
    context.threads = parallelism;
    context.allocate_cbk = NULL;
    context.free_cbk = NULL;
    context.flags = __CRAWDOG_ARGON2_DEFAULT_FLAGS;
    context.version = version;

    result = __crawdog_argon2_ctx(&context, type);

    if (result != __CRAWDOG_ARGON2_OK) {
        clear_internal_memory(out, hashlen);
        free(out);
        return result;
    }

    /* if raw hash requested, write it */
    if (hash) {
        memcpy(hash, out, hashlen);
    }

    /* if encoding requested, write it */
    if (encoded && encodedlen) {
        if (encode_string(encoded, encodedlen, &context, type) != __CRAWDOG_ARGON2_OK) {
            clear_internal_memory(out, hashlen); /* wipe buffers if error */
            clear_internal_memory(encoded, encodedlen);
            free(out);
            return __CRAWDOG_ARGON2_ENCODING_FAIL;
        }
    }
    clear_internal_memory(out, hashlen);
    free(out);

    return __CRAWDOG_ARGON2_OK;
}

int __crawdog_argon2i_hash_encoded(const uint32_t t_cost, const uint32_t m_cost,
                         const uint32_t parallelism, const void *pwd,
                         const size_t pwdlen, const void *salt,
                         const size_t saltlen, const size_t hashlen,
                         char *encoded, const size_t encodedlen) {

    return __crawdog_argon2_hash(t_cost, m_cost, parallelism, pwd, pwdlen, salt, saltlen,
                       NULL, hashlen, encoded, encodedlen, Argon2_i,
                       __CRAWDOG_ARGON2_VERSION_NUMBER);
}

int __crawdog_argon2i_hash_raw(const uint32_t t_cost, const uint32_t m_cost,
                     const uint32_t parallelism, const void *pwd,
                     const size_t pwdlen, const void *salt,
                     const size_t saltlen, void *hash, const size_t hashlen) {

    return __crawdog_argon2_hash(t_cost, m_cost, parallelism, pwd, pwdlen, salt, saltlen,
                       hash, hashlen, NULL, 0, Argon2_i, __CRAWDOG_ARGON2_VERSION_NUMBER);
}

int __crawdog_argon2d_hash_encoded(const uint32_t t_cost, const uint32_t m_cost,
                         const uint32_t parallelism, const void *pwd,
                         const size_t pwdlen, const void *salt,
                         const size_t saltlen, const size_t hashlen,
                         char *encoded, const size_t encodedlen) {

    return __crawdog_argon2_hash(t_cost, m_cost, parallelism, pwd, pwdlen, salt, saltlen,
                       NULL, hashlen, encoded, encodedlen, Argon2_d,
                       __CRAWDOG_ARGON2_VERSION_NUMBER);
}

int __crawdog_argon2d_hash_raw(const uint32_t t_cost, const uint32_t m_cost,
                     const uint32_t parallelism, const void *pwd,
                     const size_t pwdlen, const void *salt,
                     const size_t saltlen, void *hash, const size_t hashlen) {

    return __crawdog_argon2_hash(t_cost, m_cost, parallelism, pwd, pwdlen, salt, saltlen,
                       hash, hashlen, NULL, 0, Argon2_d, __CRAWDOG_ARGON2_VERSION_NUMBER);
}

int __crawdog_argon2id_hash_encoded(const uint32_t t_cost, const uint32_t m_cost,
                          const uint32_t parallelism, const void *pwd,
                          const size_t pwdlen, const void *salt,
                          const size_t saltlen, const size_t hashlen,
                          char *encoded, const size_t encodedlen) {

    return __crawdog_argon2_hash(t_cost, m_cost, parallelism, pwd, pwdlen, salt, saltlen,
                       NULL, hashlen, encoded, encodedlen, Argon2_id,
                       __CRAWDOG_ARGON2_VERSION_NUMBER);
}

int __crawdog_argon2id_hash_raw(const uint32_t t_cost, const uint32_t m_cost,
                      const uint32_t parallelism, const void *pwd,
                      const size_t pwdlen, const void *salt,
                      const size_t saltlen, void *hash, const size_t hashlen) {
    return __crawdog_argon2_hash(t_cost, m_cost, parallelism, pwd, pwdlen, salt, saltlen,
                       hash, hashlen, NULL, 0, Argon2_id,
                       __CRAWDOG_ARGON2_VERSION_NUMBER);
}

static int __crawdog_argon2_compare(const uint8_t *b1, const uint8_t *b2, size_t len) {
    size_t i;
    uint8_t d = 0U;

    for (i = 0U; i < len; i++) {
        d |= b1[i] ^ b2[i];
    }
    return (int)((1 & ((d - 1) >> 8)) - 1);
}

int __crawdog_argon2_verify(const char *encoded, const void *pwd, const size_t pwdlen,
                  __crawdog_argon2_type type) {

    __crawdog_argon2_context ctx;
    uint8_t *desired_result = NULL;

    int ret = __CRAWDOG_ARGON2_OK;

    size_t encoded_len;
    uint32_t max_field_len;

    if (pwdlen > __CRAWDOG_ARGON2_MAX_PWD_LENGTH) {
        return __CRAWDOG_ARGON2_PWD_TOO_LONG;
    }

    if (encoded == NULL) {
        return __CRAWDOG_ARGON2_DECODING_FAIL;
    }

    encoded_len = strlen(encoded);
    if (encoded_len > UINT32_MAX) {
        return __CRAWDOG_ARGON2_DECODING_FAIL;
    }

    /* No field can be longer than the encoded length */
    max_field_len = (uint32_t)encoded_len;

    ctx.saltlen = max_field_len;
    ctx.outlen = max_field_len;

    ctx.salt = malloc(ctx.saltlen);
    ctx.out = malloc(ctx.outlen);
    if (!ctx.salt || !ctx.out) {
        ret = __CRAWDOG_ARGON2_MEMORY_ALLOCATION_ERROR;
        goto fail;
    }

    ctx.pwd = (uint8_t *)pwd;
    ctx.pwdlen = (uint32_t)pwdlen;

    ret = decode_string(&ctx, encoded, type);
    if (ret != __CRAWDOG_ARGON2_OK) {
        goto fail;
    }

    /* Set aside the desired result, and get a new buffer. */
    desired_result = ctx.out;
    ctx.out = malloc(ctx.outlen);
    if (!ctx.out) {
        ret = __CRAWDOG_ARGON2_MEMORY_ALLOCATION_ERROR;
        goto fail;
    }

    ret = __crawdog_argon2_verify_ctx(&ctx, (char *)desired_result, type);
    if (ret != __CRAWDOG_ARGON2_OK) {
        goto fail;
    }

fail:
    free(ctx.salt);
    free(ctx.out);
    free(desired_result);

    return ret;
}

int __crawdog_argon2i_verify(const char *encoded, const void *pwd, const size_t pwdlen) {

    return __crawdog_argon2_verify(encoded, pwd, pwdlen, Argon2_i);
}

int __crawdog_argon2d_verify(const char *encoded, const void *pwd, const size_t pwdlen) {

    return __crawdog_argon2_verify(encoded, pwd, pwdlen, Argon2_d);
}

int __crawdog_argon2id_verify(const char *encoded, const void *pwd, const size_t pwdlen) {

    return __crawdog_argon2_verify(encoded, pwd, pwdlen, Argon2_id);
}

int __crawdog_argon2d_ctx(__crawdog_argon2_context *context) {
    return __crawdog_argon2_ctx(context, Argon2_d);
}

int __crawdog_argon2i_ctx(__crawdog_argon2_context *context) {
    return __crawdog_argon2_ctx(context, Argon2_i);
}

int __crawdog_argon2id_ctx(__crawdog_argon2_context *context) {
    return __crawdog_argon2_ctx(context, Argon2_id);
}

int __crawdog_argon2_verify_ctx(__crawdog_argon2_context *context, const char *hash,
                      __crawdog_argon2_type type) {
    int ret = __crawdog_argon2_ctx(context, type);
    if (ret != __CRAWDOG_ARGON2_OK) {
        return ret;
    }

    if (__crawdog_argon2_compare((uint8_t *)hash, context->out, context->outlen)) {
        return __CRAWDOG_ARGON2_VERIFY_MISMATCH;
    }

    return __CRAWDOG_ARGON2_OK;
}

int __crawdog_argon2d_verify_ctx(__crawdog_argon2_context *context, const char *hash) {
    return __crawdog_argon2_verify_ctx(context, hash, Argon2_d);
}

int __crawdog_argon2i_verify_ctx(__crawdog_argon2_context *context, const char *hash) {
    return __crawdog_argon2_verify_ctx(context, hash, Argon2_i);
}

int __crawdog_argon2id_verify_ctx(__crawdog_argon2_context *context, const char *hash) {
    return __crawdog_argon2_verify_ctx(context, hash, Argon2_id);
}

const char *__crawdog_argon2_error_message(int error_code) {
    switch (error_code) {
    case __CRAWDOG_ARGON2_OK:
        return "OK";
    case __CRAWDOG_ARGON2_OUTPUT_PTR_NULL:
        return "Output pointer is NULL";
    case __CRAWDOG_ARGON2_OUTPUT_TOO_SHORT:
        return "Output is too short";
    case __CRAWDOG_ARGON2_OUTPUT_TOO_LONG:
        return "Output is too long";
    case __CRAWDOG_ARGON2_PWD_TOO_SHORT:
        return "Password is too short";
    case __CRAWDOG_ARGON2_PWD_TOO_LONG:
        return "Password is too long";
    case __CRAWDOG_ARGON2_SALT_TOO_SHORT:
        return "Salt is too short";
    case __CRAWDOG_ARGON2_SALT_TOO_LONG:
        return "Salt is too long";
    case __CRAWDOG_ARGON2_AD_TOO_SHORT:
        return "Associated data is too short";
    case __CRAWDOG_ARGON2_AD_TOO_LONG:
        return "Associated data is too long";
    case __CRAWDOG_ARGON2_SECRET_TOO_SHORT:
        return "Secret is too short";
    case __CRAWDOG_ARGON2_SECRET_TOO_LONG:
        return "Secret is too long";
    case __CRAWDOG_ARGON2_TIME_TOO_SMALL:
        return "Time cost is too small";
    case __CRAWDOG_ARGON2_TIME_TOO_LARGE:
        return "Time cost is too large";
    case __CRAWDOG_ARGON2_MEMORY_TOO_LITTLE:
        return "Memory cost is too small";
    case __CRAWDOG_ARGON2_MEMORY_TOO_MUCH:
        return "Memory cost is too large";
    case __CRAWDOG_ARGON2_LANES_TOO_FEW:
        return "Too few lanes";
    case __CRAWDOG_ARGON2_LANES_TOO_MANY:
        return "Too many lanes";
    case __CRAWDOG_ARGON2_PWD_PTR_MISMATCH:
        return "Password pointer is NULL, but password length is not 0";
    case __CRAWDOG_ARGON2_SALT_PTR_MISMATCH:
        return "Salt pointer is NULL, but salt length is not 0";
    case __CRAWDOG_ARGON2_SECRET_PTR_MISMATCH:
        return "Secret pointer is NULL, but secret length is not 0";
    case __CRAWDOG_ARGON2_AD_PTR_MISMATCH:
        return "Associated data pointer is NULL, but ad length is not 0";
    case __CRAWDOG_ARGON2_MEMORY_ALLOCATION_ERROR:
        return "Memory allocation error";
    case __CRAWDOG_ARGON2_FREE_MEMORY_CBK_NULL:
        return "The free memory callback is NULL";
    case __CRAWDOG_ARGON2_ALLOCATE_MEMORY_CBK_NULL:
        return "The allocate memory callback is NULL";
    case __CRAWDOG_ARGON2_INCORRECT_PARAMETER:
        return "Argon2_Context context is NULL";
    case __CRAWDOG_ARGON2_INCORRECT_TYPE:
        return "There is no such version of Argon2";
    case __CRAWDOG_ARGON2_OUT_PTR_MISMATCH:
        return "Output pointer mismatch";
    case __CRAWDOG_ARGON2_THREADS_TOO_FEW:
        return "Not enough threads";
    case __CRAWDOG_ARGON2_THREADS_TOO_MANY:
        return "Too many threads";
    case __CRAWDOG_ARGON2_MISSING_ARGS:
        return "Missing arguments";
    case __CRAWDOG_ARGON2_ENCODING_FAIL:
        return "Encoding failed";
    case __CRAWDOG_ARGON2_DECODING_FAIL:
        return "Decoding failed";
    case __CRAWDOG_ARGON2_THREAD_FAIL:
        return "Threading failure";
    case __CRAWDOG_ARGON2_DECODING_LENGTH_FAIL:
        return "Some of encoded parameters are too long or too short";
    case __CRAWDOG_ARGON2_VERIFY_MISMATCH:
        return "The password does not match the supplied hash";
    default:
        return "Unknown error code";
    }
}

size_t __crawdog_argon2_encodedlen(uint32_t t_cost, uint32_t m_cost, uint32_t parallelism,
                         uint32_t saltlen, uint32_t hashlen, __crawdog_argon2_type type) {
  return strlen("$$v=$m=,t=,p=$$") + strlen(__crawdog_argon2_type2string(type, 0)) +
         numlen(t_cost) + numlen(m_cost) + numlen(parallelism) +
         b64len(saltlen) + b64len(hashlen) + numlen(__CRAWDOG_ARGON2_VERSION_NUMBER) + 1;
}
