// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
// copyright (c) frank denis 2013-2024. all rights reserved.
#include "crawdog_hchacha20.h"
#include <string.h>
#include <stdlib.h>
#include <errno.h>

typedef struct HChaCha20TV_ {
    const char key[__CRAWDOG_HCHACHA20_KEYBYTES * 2 + 1];
    const char in[__CRAWDOG_HCHACHA20_INPUTBYTES * 2 + 1];
    const char out[__CRAWDOG_HCHACHA20_OUTPUTBYTES * 2 + 1];
} HChaCha20TV;

int
sodium_hex2bin(unsigned char *const bin, const size_t bin_maxlen,
               const char *const hex, const size_t hex_len,
               const char *const ignore, size_t *const bin_len,
               const char **const hex_end)
{
    size_t        bin_pos = (size_t) 0U;
    size_t        hex_pos = (size_t) 0U;
    int           ret     = 0;
    unsigned char c;
    unsigned char c_acc = 0U;
    unsigned char c_alpha0, c_alpha;
    unsigned char c_num0, c_num;
    unsigned char c_val;
    unsigned char state = 0U;

    while (hex_pos < hex_len) {
        c        = (unsigned char) hex[hex_pos];
        c_num    = c ^ 48U;
        c_num0   = (c_num - 10U) >> 8;
        c_alpha  = (c & ~32U) - 55U;
        c_alpha0 = ((c_alpha - 10U) ^ (c_alpha - 16U)) >> 8;
        if ((c_num0 | c_alpha0) == 0U) {
            if (ignore != NULL && state == 0U && strchr(ignore, c) != NULL) {
                hex_pos++;
                continue;
            }
            break;
        }
        c_val = (c_num0 & c_num) | (c_alpha0 & c_alpha);
        if (bin_pos >= bin_maxlen) {
            ret   = -1;
            errno = ERANGE;
            break;
        }
        if (state == 0U) {
            c_acc = c_val * 16U;
        } else {
            bin[bin_pos++] = c_acc | c_val;
        }
        state = ~state;
        hex_pos++;
    }
    if (state != 0U) {
        hex_pos--;
        errno = EINVAL;
        ret = -1;
    }
    if (ret != 0) {
        bin_pos = (size_t) 0U;
    }
    if (hex_end != NULL) {
        *hex_end = &hex[hex_pos];
    } else if (hex_pos != hex_len) {
        errno = EINVAL;
        ret = -1;
    }
    if (bin_len != NULL) {
        *bin_len = bin_pos;
    }
    return ret;
}

int
tv_hchacha20(void)
{
    static const HChaCha20TV tvs[] = {
        { "24f11cce8a1b3d61e441561a696c1c1b7e173d084fd4812425435a8896a013dc", "d9660c5900ae19ddad28d6e06e45fe5e", "5966b3eec3bff1189f831f06afe4d4e3be97fa9235ec8c20d08acfbbb4e851e3" },
        { "80a5f6272031e18bb9bcd84f3385da65e7731b7039f13f5e3d475364cd4d42f7", "c0eccc384b44c88e92c57eb2d5ca4dfa", "6ed11741f724009a640a44fce7320954c46e18e0d7ae063bdbc8d7cf372709df" },
        { "cb1fc686c0eec11a89438b6f4013bf110e7171dace3297f3a657a309b3199629", "fcd49b93e5f8f299227e64d40dc864a3", "84b7e96937a1a0a406bb7162eeaad34308d49de60fd2f7ec9dc6a79cbab2ca34" },
        { "6640f4d80af5496ca1bc2cfff1fefbe99638dbceaabd7d0ade118999d45f053d", "31f59ceeeafdbfe8cae7914caeba90d6", "9af4697d2f5574a44834a2c2ae1a0505af9f5d869dbe381a994a18eb374c36a0" },
        { "0693ff36d971225a44ac92c092c60b399e672e4cc5aafd5e31426f123787ac27", "3a6293da061da405db45be1731d5fc4d", "f87b38609142c01095bfc425573bb3c698f9ae866b7e4216840b9c4caf3b0865" },
        { "809539bd2639a23bf83578700f055f313561c7785a4a19fc9114086915eee551", "780c65d6a3318e479c02141d3f0b3918", "902ea8ce4680c09395ce71874d242f84274243a156938aaa2dd37ac5be382b42" },
        { "1a170ddf25a4fd69b648926e6d794e73408805835c64b2c70efddd8cd1c56ce0", "05dbee10de87eb0c5acb2b66ebbe67d3", "a4e20b634c77d7db908d387b48ec2b370059db916e8ea7716dc07238532d5981" },
        { "3b354e4bb69b5b4a1126f509e84cad49f18c9f5f29f0be0c821316a6986e15a6", "d8a89af02f4b8b2901d8321796388b6c", "9816cb1a5b61993735a4b161b51ed2265b696e7ded5309c229a5a99f53534fbc" },
        { "4b9a818892e15a530db50dd2832e95ee192e5ed6afffb408bd624a0c4e12a081", "a9079c551de70501be0286d1bc78b045", "ebc5224cf41ea97473683b6c2f38a084bf6e1feaaeff62676db59d5b719d999b" },
        { "c49758f00003714c38f1d4972bde57ee8271f543b91e07ebce56b554eb7fa6a7", "31f0204e10cf4f2035f9e62bb5ba7303", "0dd8cc400f702d2c06ed920be52048a287076b86480ae273c6d568a2e9e7518c" }
    };
    const HChaCha20TV *tv;
    unsigned char     *constant;
    unsigned char     *key;
    unsigned char     *in;
    unsigned char     *out;
    unsigned char     *out2;
    size_t             i;

    constant = (unsigned char *) malloc(__CRAWDOG_HCHACHA20_CONSTBYTES);
    key = (unsigned char *) malloc(__CRAWDOG_HCHACHA20_KEYBYTES);
    in = (unsigned char *) malloc(__CRAWDOG_HCHACHA20_INPUTBYTES);
    out = (unsigned char *) malloc(__CRAWDOG_HCHACHA20_OUTPUTBYTES);
    out2 = (unsigned char *) malloc(__CRAWDOG_HCHACHA20_OUTPUTBYTES);
    for (i = 0; i < (sizeof tvs) / (sizeof tvs[0]); i++) {
        tv = &tvs[i];
        sodium_hex2bin(key, __CRAWDOG_HCHACHA20_KEYBYTES,
                       tv->key, strlen(tv->key), NULL, NULL, NULL);
        sodium_hex2bin(in, __CRAWDOG_HCHACHA20_INPUTBYTES,
                       tv->in, strlen(tv->in), NULL, NULL, NULL);
        sodium_hex2bin(out, __CRAWDOG_HCHACHA20_OUTPUTBYTES,
                       tv->out, strlen(tv->out), NULL, NULL, NULL);
        __crawdog_hchacha20(out2, in, key, NULL);
        if(memcmp(out, out2, __CRAWDOG_HCHACHA20_OUTPUTBYTES) != 0) {
			return -1;
		}
    }

    sodium_hex2bin(constant, __CRAWDOG_HCHACHA20_CONSTBYTES,
                   "0d29b795c1ca70c1652e823364d32417",
                   __CRAWDOG_HCHACHA20_CONSTBYTES * 2 + 1, NULL, NULL, NULL);
    sodium_hex2bin(out, __CRAWDOG_HCHACHA20_OUTPUTBYTES,
                   "934d941d78eb9bfc2f0376f7ccd4a11ecf0c6a44104618a9749ef47fe97037a2",
                   __CRAWDOG_HCHACHA20_OUTPUTBYTES * 2 + 1, NULL, NULL, NULL);

    __crawdog_hchacha20(out2, in, key, constant);
    if (memcmp(out, out2, __CRAWDOG_HCHACHA20_OUTPUTBYTES) != 0) {
		return -1;
	}

    free(out2);
    free(out);
    free(in);
    free(key);
    free(constant);

    if(__crawdog_hchacha20_outputbytes() != __CRAWDOG_HCHACHA20_OUTPUTBYTES) {
		return -1;
	}
    if (__crawdog_hchacha20_inputbytes() != __CRAWDOG_HCHACHA20_INPUTBYTES) {
		return -1;
	}
    if (__crawdog_hchacha20_keybytes() != __CRAWDOG_HCHACHA20_KEYBYTES) {
		return -1;
	}
    if (__crawdog_hchacha20_constbytes() != __CRAWDOG_HCHACHA20_CONSTBYTES) {
		return -1;
	}

    return 0;
}