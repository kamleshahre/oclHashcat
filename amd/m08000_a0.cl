/**
 * Author......: Jens Steube <jens.steube@gmail.com>
 * License.....: MIT
 */

#define _SHA256_

#include "include/constants.h"
#include "include/kernel_vendor.h"

#ifdef  VLIW1
#define VECT_SIZE1
#endif

#ifdef  VLIW4
#define VECT_SIZE2
#endif

#ifdef  VLIW5
#define VECT_SIZE2
#endif

#define DGST_R0 3
#define DGST_R1 7
#define DGST_R2 2
#define DGST_R3 6

#include "include/kernel_functions.c"
#include "types_amd.c"
#include "common_amd.c"
#include "include/rp_gpu.h"
#include "rp_amd.c"

#ifdef  VECT_SIZE1
#define VECT_COMPARE_S "check_single_vect1_comp4.c"
#define VECT_COMPARE_M "check_multi_vect1_comp4.c"
#endif

#ifdef  VECT_SIZE2
#define VECT_COMPARE_S "check_single_vect2_comp4.c"
#define VECT_COMPARE_M "check_multi_vect2_comp4.c"
#endif

#ifdef  VECT_SIZE4
#define VECT_COMPARE_S "check_single_vect4_comp4.c"
#define VECT_COMPARE_M "check_multi_vect4_comp4.c"
#endif

__constant u32 k_sha256[64] =
{
  SHA256C00, SHA256C01, SHA256C02, SHA256C03,
  SHA256C04, SHA256C05, SHA256C06, SHA256C07,
  SHA256C08, SHA256C09, SHA256C0a, SHA256C0b,
  SHA256C0c, SHA256C0d, SHA256C0e, SHA256C0f,
  SHA256C10, SHA256C11, SHA256C12, SHA256C13,
  SHA256C14, SHA256C15, SHA256C16, SHA256C17,
  SHA256C18, SHA256C19, SHA256C1a, SHA256C1b,
  SHA256C1c, SHA256C1d, SHA256C1e, SHA256C1f,
  SHA256C20, SHA256C21, SHA256C22, SHA256C23,
  SHA256C24, SHA256C25, SHA256C26, SHA256C27,
  SHA256C28, SHA256C29, SHA256C2a, SHA256C2b,
  SHA256C2c, SHA256C2d, SHA256C2e, SHA256C2f,
  SHA256C30, SHA256C31, SHA256C32, SHA256C33,
  SHA256C34, SHA256C35, SHA256C36, SHA256C37,
  SHA256C38, SHA256C39, SHA256C3a, SHA256C3b,
  SHA256C3c, SHA256C3d, SHA256C3e, SHA256C3f,
};

static void sha256_transform (u32x digest[8], const u32x w[16])
{
  u32x a = digest[0];
  u32x b = digest[1];
  u32x c = digest[2];
  u32x d = digest[3];
  u32x e = digest[4];
  u32x f = digest[5];
  u32x g = digest[6];
  u32x h = digest[7];

  u32x w0_t = w[ 0];
  u32x w1_t = w[ 1];
  u32x w2_t = w[ 2];
  u32x w3_t = w[ 3];
  u32x w4_t = w[ 4];
  u32x w5_t = w[ 5];
  u32x w6_t = w[ 6];
  u32x w7_t = w[ 7];
  u32x w8_t = w[ 8];
  u32x w9_t = w[ 9];
  u32x wa_t = w[10];
  u32x wb_t = w[11];
  u32x wc_t = w[12];
  u32x wd_t = w[13];
  u32x we_t = w[14];
  u32x wf_t = w[15];

  #define ROUND_EXPAND()                            \
  {                                                 \
    w0_t = SHA256_EXPAND (we_t, w9_t, w1_t, w0_t);  \
    w1_t = SHA256_EXPAND (wf_t, wa_t, w2_t, w1_t);  \
    w2_t = SHA256_EXPAND (w0_t, wb_t, w3_t, w2_t);  \
    w3_t = SHA256_EXPAND (w1_t, wc_t, w4_t, w3_t);  \
    w4_t = SHA256_EXPAND (w2_t, wd_t, w5_t, w4_t);  \
    w5_t = SHA256_EXPAND (w3_t, we_t, w6_t, w5_t);  \
    w6_t = SHA256_EXPAND (w4_t, wf_t, w7_t, w6_t);  \
    w7_t = SHA256_EXPAND (w5_t, w0_t, w8_t, w7_t);  \
    w8_t = SHA256_EXPAND (w6_t, w1_t, w9_t, w8_t);  \
    w9_t = SHA256_EXPAND (w7_t, w2_t, wa_t, w9_t);  \
    wa_t = SHA256_EXPAND (w8_t, w3_t, wb_t, wa_t);  \
    wb_t = SHA256_EXPAND (w9_t, w4_t, wc_t, wb_t);  \
    wc_t = SHA256_EXPAND (wa_t, w5_t, wd_t, wc_t);  \
    wd_t = SHA256_EXPAND (wb_t, w6_t, we_t, wd_t);  \
    we_t = SHA256_EXPAND (wc_t, w7_t, wf_t, we_t);  \
    wf_t = SHA256_EXPAND (wd_t, w8_t, w0_t, wf_t);  \
  }

  #define ROUND_STEP(i)                                                                   \
  {                                                                                       \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, a, b, c, d, e, f, g, h, w0_t, k_sha256[i +  0]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, h, a, b, c, d, e, f, g, w1_t, k_sha256[i +  1]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, g, h, a, b, c, d, e, f, w2_t, k_sha256[i +  2]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, f, g, h, a, b, c, d, e, w3_t, k_sha256[i +  3]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, e, f, g, h, a, b, c, d, w4_t, k_sha256[i +  4]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, d, e, f, g, h, a, b, c, w5_t, k_sha256[i +  5]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, c, d, e, f, g, h, a, b, w6_t, k_sha256[i +  6]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, b, c, d, e, f, g, h, a, w7_t, k_sha256[i +  7]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, a, b, c, d, e, f, g, h, w8_t, k_sha256[i +  8]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, h, a, b, c, d, e, f, g, w9_t, k_sha256[i +  9]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, g, h, a, b, c, d, e, f, wa_t, k_sha256[i + 10]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, f, g, h, a, b, c, d, e, wb_t, k_sha256[i + 11]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, e, f, g, h, a, b, c, d, wc_t, k_sha256[i + 12]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, d, e, f, g, h, a, b, c, wd_t, k_sha256[i + 13]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, c, d, e, f, g, h, a, b, we_t, k_sha256[i + 14]); \
    SHA256_STEP (SHA256_F0o, SHA256_F1o, b, c, d, e, f, g, h, a, wf_t, k_sha256[i + 15]); \
  }

  ROUND_STEP (0);

  #pragma unroll
  for (int i = 16; i < 64; i += 16)
  {
    ROUND_EXPAND (); ROUND_STEP (i);
  }

  digest[0] += a;
  digest[1] += b;
  digest[2] += c;
  digest[3] += d;
  digest[4] += e;
  digest[5] += f;
  digest[6] += g;
  digest[7] += h;
}

__kernel void __attribute__((reqd_work_group_size (64, 1, 1))) m08000_m04 (__global pw_t *pws, __global gpu_rule_t *rules_buf, __global comb_t *combs_buf, __global bf_t *bfs_buf, __global void *tmps, __global void *hooks, __global u32 *bitmaps_buf_s1_a, __global u32 *bitmaps_buf_s1_b, __global u32 *bitmaps_buf_s1_c, __global u32 *bitmaps_buf_s1_d, __global u32 *bitmaps_buf_s2_a, __global u32 *bitmaps_buf_s2_b, __global u32 *bitmaps_buf_s2_c, __global u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global digest_t *digests_buf, __global u32 *hashes_shown, __global salt_t *salt_bufs, __global void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 rules_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
  /**
   * modifier
   */

  const u32 lid = get_local_id (0);

  /**
   * base
   */

  const u32 gid = get_global_id (0);

  if (gid >= gid_max) return;

  u32x pw_buf0[4];

  pw_buf0[0] = pws[gid].i[ 0];
  pw_buf0[1] = pws[gid].i[ 1];
  pw_buf0[2] = pws[gid].i[ 2];
  pw_buf0[3] = pws[gid].i[ 3];

  u32x pw_buf1[4];

  pw_buf1[0] = pws[gid].i[ 4];
  pw_buf1[1] = pws[gid].i[ 5];
  pw_buf1[2] = pws[gid].i[ 6];
  pw_buf1[3] = pws[gid].i[ 7];

  const u32 pw_len = pws[gid].pw_len;

  /**
   * salt
   */

  const u32 salt_buf0 = swap_workaround (salt_bufs[salt_pos].salt_buf[ 0]);
  const u32 salt_buf1 = swap_workaround (salt_bufs[salt_pos].salt_buf[ 1]);
  const u32 salt_buf2 = swap_workaround (salt_bufs[salt_pos].salt_buf[ 2]); // 0x80

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < rules_cnt; il_pos++)
  {
    u32x w0[4];
    u32x w1[4];
    u32x w2[4];
    u32x w3[4];

    w0[0] = pw_buf0[0];
    w0[1] = pw_buf0[1];
    w0[2] = pw_buf0[2];
    w0[3] = pw_buf0[3];
    w1[0] = pw_buf1[0];
    w1[1] = pw_buf1[1];
    w1[2] = pw_buf1[2];
    w1[3] = pw_buf1[3];
    w2[0] = 0;
    w2[1] = 0;
    w2[2] = 0;
    w2[3] = 0;
    w3[0] = 0;
    w3[1] = 0;
    w3[2] = 0;
    w3[3] = 0;

    const u32 out_len = apply_rules (rules_buf[il_pos].cmds, w0, w1, pw_len);

    u32x w0_t[4];
    u32x w1_t[4];
    u32x w2_t[4];
    u32x w3_t[4];

    make_unicode (w0, w0_t, w1_t);

    make_unicode (w1, w2_t, w3_t);

    u32x w_t[16];

    w_t[ 0] = swap_workaround (w0_t[0]);
    w_t[ 1] = swap_workaround (w0_t[1]);
    w_t[ 2] = swap_workaround (w0_t[2]);
    w_t[ 3] = swap_workaround (w0_t[3]);
    w_t[ 4] = swap_workaround (w1_t[0]);
    w_t[ 5] = swap_workaround (w1_t[1]);
    w_t[ 6] = swap_workaround (w1_t[2]);
    w_t[ 7] = swap_workaround (w1_t[3]);
    w_t[ 8] = swap_workaround (w2_t[0]);
    w_t[ 9] = swap_workaround (w2_t[1]);
    w_t[10] = swap_workaround (w2_t[2]);
    w_t[11] = swap_workaround (w2_t[3]);
    w_t[12] = swap_workaround (w3_t[0]);
    w_t[13] = swap_workaround (w3_t[1]);
    w_t[14] = swap_workaround (w3_t[2]);
    w_t[15] = swap_workaround (w3_t[3]);

    w_t[ 0] = w_t[ 0] >> 8;
    w_t[ 1] = w_t[ 1] >> 8;
    w_t[ 2] = w_t[ 2] >> 8;
    w_t[ 3] = w_t[ 3] >> 8;
    w_t[ 4] = w_t[ 4] >> 8;
    w_t[ 5] = w_t[ 5] >> 8;
    w_t[ 6] = w_t[ 6] >> 8;
    w_t[ 7] = w_t[ 7] >> 8;
    w_t[ 8] = w_t[ 8] >> 8;
    w_t[ 9] = w_t[ 9] >> 8;
    w_t[10] = w_t[10] >> 8;
    w_t[11] = w_t[11] >> 8;
    w_t[12] = w_t[12] >> 8;
    w_t[13] = w_t[13] >> 8;
    w_t[14] = w_t[14] >> 8;
    w_t[15] = w_t[15] >> 8;

    u32x digest[8];

    digest[0] = SHA256M_A;
    digest[1] = SHA256M_B;
    digest[2] = SHA256M_C;
    digest[3] = SHA256M_D;
    digest[4] = SHA256M_E;
    digest[5] = SHA256M_F;
    digest[6] = SHA256M_G;
    digest[7] = SHA256M_H;

    sha256_transform (digest, w_t); //   0 - 64

    w_t[ 0] = 0;
    w_t[ 1] = 0;
    w_t[ 2] = 0;
    w_t[ 3] = 0;
    w_t[ 4] = 0;
    w_t[ 5] = 0;
    w_t[ 6] = 0;
    w_t[ 7] = 0;
    w_t[ 8] = 0;
    w_t[ 9] = 0;
    w_t[10] = 0;
    w_t[11] = 0;
    w_t[12] = 0;
    w_t[13] = 0;
    w_t[14] = 0;
    w_t[15] = 0;

    sha256_transform (digest, w_t); //  64 - 128
    sha256_transform (digest, w_t); // 128 - 192
    sha256_transform (digest, w_t); // 192 - 256
    sha256_transform (digest, w_t); // 256 - 320
    sha256_transform (digest, w_t); // 320 - 384
    sha256_transform (digest, w_t); // 384 - 448

    w_t[15] =               0 | salt_buf0 >> 16;

    sha256_transform (digest, w_t); // 448 - 512

    w_t[ 0] = salt_buf0 << 16 | salt_buf1 >> 16;
    w_t[ 1] = salt_buf1 << 16 | salt_buf2 >> 16;
    w_t[ 2] = salt_buf2 << 16 | 0;
    w_t[15] = (510 + 8) * 8;

    sha256_transform (digest, w_t); // 512 - 576

    const u32x r0 = digest[3];
    const u32x r1 = digest[7];
    const u32x r2 = digest[2];
    const u32x r3 = digest[6];

    #include VECT_COMPARE_M
  }
}

__kernel void __attribute__((reqd_work_group_size (64, 1, 1))) m08000_m08 (__global pw_t *pws, __global gpu_rule_t *rules_buf, __global comb_t *combs_buf, __global bf_t *bfs_buf, __global void *tmps, __global void *hooks, __global u32 *bitmaps_buf_s1_a, __global u32 *bitmaps_buf_s1_b, __global u32 *bitmaps_buf_s1_c, __global u32 *bitmaps_buf_s1_d, __global u32 *bitmaps_buf_s2_a, __global u32 *bitmaps_buf_s2_b, __global u32 *bitmaps_buf_s2_c, __global u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global digest_t *digests_buf, __global u32 *hashes_shown, __global salt_t *salt_bufs, __global void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 rules_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
}

__kernel void __attribute__((reqd_work_group_size (64, 1, 1))) m08000_m16 (__global pw_t *pws, __global gpu_rule_t *rules_buf, __global comb_t *combs_buf, __global bf_t *bfs_buf, __global void *tmps, __global void *hooks, __global u32 *bitmaps_buf_s1_a, __global u32 *bitmaps_buf_s1_b, __global u32 *bitmaps_buf_s1_c, __global u32 *bitmaps_buf_s1_d, __global u32 *bitmaps_buf_s2_a, __global u32 *bitmaps_buf_s2_b, __global u32 *bitmaps_buf_s2_c, __global u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global digest_t *digests_buf, __global u32 *hashes_shown, __global salt_t *salt_bufs, __global void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 rules_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
}

__kernel void __attribute__((reqd_work_group_size (64, 1, 1))) m08000_s04 (__global pw_t *pws, __global gpu_rule_t *rules_buf, __global comb_t *combs_buf, __global bf_t *bfs_buf, __global void *tmps, __global void *hooks, __global u32 *bitmaps_buf_s1_a, __global u32 *bitmaps_buf_s1_b, __global u32 *bitmaps_buf_s1_c, __global u32 *bitmaps_buf_s1_d, __global u32 *bitmaps_buf_s2_a, __global u32 *bitmaps_buf_s2_b, __global u32 *bitmaps_buf_s2_c, __global u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global digest_t *digests_buf, __global u32 *hashes_shown, __global salt_t *salt_bufs, __global void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 rules_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
  /**
   * modifier
   */

  const u32 lid = get_local_id (0);

  /**
   * base
   */

  const u32 gid = get_global_id (0);

  if (gid >= gid_max) return;

  u32x pw_buf0[4];

  pw_buf0[0] = pws[gid].i[ 0];
  pw_buf0[1] = pws[gid].i[ 1];
  pw_buf0[2] = pws[gid].i[ 2];
  pw_buf0[3] = pws[gid].i[ 3];

  u32x pw_buf1[4];

  pw_buf1[0] = pws[gid].i[ 4];
  pw_buf1[1] = pws[gid].i[ 5];
  pw_buf1[2] = pws[gid].i[ 6];
  pw_buf1[3] = pws[gid].i[ 7];

  const u32 pw_len = pws[gid].pw_len;

  /**
   * salt
   */

  const u32 salt_buf0 = swap_workaround (salt_bufs[salt_pos].salt_buf[ 0]);
  const u32 salt_buf1 = swap_workaround (salt_bufs[salt_pos].salt_buf[ 1]);
  const u32 salt_buf2 = swap_workaround (salt_bufs[salt_pos].salt_buf[ 2]); // 0x80

  /**
   * digest
   */

  const u32 search[4] =
  {
    digests_buf[digests_offset].digest_buf[DGST_R0],
    digests_buf[digests_offset].digest_buf[DGST_R1],
    digests_buf[digests_offset].digest_buf[DGST_R2],
    digests_buf[digests_offset].digest_buf[DGST_R3]
  };

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < rules_cnt; il_pos++)
  {
    u32x w0[4];
    u32x w1[4];
    u32x w2[4];
    u32x w3[4];

    w0[0] = pw_buf0[0];
    w0[1] = pw_buf0[1];
    w0[2] = pw_buf0[2];
    w0[3] = pw_buf0[3];
    w1[0] = pw_buf1[0];
    w1[1] = pw_buf1[1];
    w1[2] = pw_buf1[2];
    w1[3] = pw_buf1[3];
    w2[0] = 0;
    w2[1] = 0;
    w2[2] = 0;
    w2[3] = 0;
    w3[0] = 0;
    w3[1] = 0;
    w3[2] = 0;
    w3[3] = 0;

    const u32 out_len = apply_rules (rules_buf[il_pos].cmds, w0, w1, pw_len);

    u32x w0_t[4];
    u32x w1_t[4];
    u32x w2_t[4];
    u32x w3_t[4];

    make_unicode (w0, w0_t, w1_t);

    make_unicode (w1, w2_t, w3_t);

    u32x w_t[16];

    w_t[ 0] = swap_workaround (w0_t[0]);
    w_t[ 1] = swap_workaround (w0_t[1]);
    w_t[ 2] = swap_workaround (w0_t[2]);
    w_t[ 3] = swap_workaround (w0_t[3]);
    w_t[ 4] = swap_workaround (w1_t[0]);
    w_t[ 5] = swap_workaround (w1_t[1]);
    w_t[ 6] = swap_workaround (w1_t[2]);
    w_t[ 7] = swap_workaround (w1_t[3]);
    w_t[ 8] = swap_workaround (w2_t[0]);
    w_t[ 9] = swap_workaround (w2_t[1]);
    w_t[10] = swap_workaround (w2_t[2]);
    w_t[11] = swap_workaround (w2_t[3]);
    w_t[12] = swap_workaround (w3_t[0]);
    w_t[13] = swap_workaround (w3_t[1]);
    w_t[14] = swap_workaround (w3_t[2]);
    w_t[15] = swap_workaround (w3_t[3]);

    w_t[ 0] = w_t[ 0] >> 8;
    w_t[ 1] = w_t[ 1] >> 8;
    w_t[ 2] = w_t[ 2] >> 8;
    w_t[ 3] = w_t[ 3] >> 8;
    w_t[ 4] = w_t[ 4] >> 8;
    w_t[ 5] = w_t[ 5] >> 8;
    w_t[ 6] = w_t[ 6] >> 8;
    w_t[ 7] = w_t[ 7] >> 8;
    w_t[ 8] = w_t[ 8] >> 8;
    w_t[ 9] = w_t[ 9] >> 8;
    w_t[10] = w_t[10] >> 8;
    w_t[11] = w_t[11] >> 8;
    w_t[12] = w_t[12] >> 8;
    w_t[13] = w_t[13] >> 8;
    w_t[14] = w_t[14] >> 8;
    w_t[15] = w_t[15] >> 8;

    u32x digest[8];

    digest[0] = SHA256M_A;
    digest[1] = SHA256M_B;
    digest[2] = SHA256M_C;
    digest[3] = SHA256M_D;
    digest[4] = SHA256M_E;
    digest[5] = SHA256M_F;
    digest[6] = SHA256M_G;
    digest[7] = SHA256M_H;

    sha256_transform (digest, w_t); //   0 - 64

    w_t[ 0] = 0;
    w_t[ 1] = 0;
    w_t[ 2] = 0;
    w_t[ 3] = 0;
    w_t[ 4] = 0;
    w_t[ 5] = 0;
    w_t[ 6] = 0;
    w_t[ 7] = 0;
    w_t[ 8] = 0;
    w_t[ 9] = 0;
    w_t[10] = 0;
    w_t[11] = 0;
    w_t[12] = 0;
    w_t[13] = 0;
    w_t[14] = 0;
    w_t[15] = 0;

    sha256_transform (digest, w_t); //  64 - 128
    sha256_transform (digest, w_t); // 128 - 192
    sha256_transform (digest, w_t); // 192 - 256
    sha256_transform (digest, w_t); // 256 - 320
    sha256_transform (digest, w_t); // 320 - 384
    sha256_transform (digest, w_t); // 384 - 448

    w_t[15] =               0 | salt_buf0 >> 16;

    sha256_transform (digest, w_t); // 448 - 512

    w_t[ 0] = salt_buf0 << 16 | salt_buf1 >> 16;
    w_t[ 1] = salt_buf1 << 16 | salt_buf2 >> 16;
    w_t[ 2] = salt_buf2 << 16 | 0;
    w_t[15] = (510 + 8) * 8;

    sha256_transform (digest, w_t); // 512 - 576

    const u32x r0 = digest[3];
    const u32x r1 = digest[7];
    const u32x r2 = digest[2];
    const u32x r3 = digest[6];

    #include VECT_COMPARE_S
  }
}

__kernel void __attribute__((reqd_work_group_size (64, 1, 1))) m08000_s08 (__global pw_t *pws, __global gpu_rule_t *rules_buf, __global comb_t *combs_buf, __global bf_t *bfs_buf, __global void *tmps, __global void *hooks, __global u32 *bitmaps_buf_s1_a, __global u32 *bitmaps_buf_s1_b, __global u32 *bitmaps_buf_s1_c, __global u32 *bitmaps_buf_s1_d, __global u32 *bitmaps_buf_s2_a, __global u32 *bitmaps_buf_s2_b, __global u32 *bitmaps_buf_s2_c, __global u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global digest_t *digests_buf, __global u32 *hashes_shown, __global salt_t *salt_bufs, __global void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 rules_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
}

__kernel void __attribute__((reqd_work_group_size (64, 1, 1))) m08000_s16 (__global pw_t *pws, __global gpu_rule_t *rules_buf, __global comb_t *combs_buf, __global bf_t *bfs_buf, __global void *tmps, __global void *hooks, __global u32 *bitmaps_buf_s1_a, __global u32 *bitmaps_buf_s1_b, __global u32 *bitmaps_buf_s1_c, __global u32 *bitmaps_buf_s1_d, __global u32 *bitmaps_buf_s2_a, __global u32 *bitmaps_buf_s2_b, __global u32 *bitmaps_buf_s2_c, __global u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global digest_t *digests_buf, __global u32 *hashes_shown, __global salt_t *salt_bufs, __global void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 rules_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
}
