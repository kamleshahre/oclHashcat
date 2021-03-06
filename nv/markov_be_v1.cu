/**
 * Author......: Jens Steube <jens.steube@gmail.com>
 * License.....: MIT
 */

#define CHARSIZ 256

#define VECT_SIZE1

#include "types_nv.c"

__device__ static void generate_pw (u32 pw_buf[16], cs_t *root_css_buf, cs_t *markov_css_buf, const u32 pw_l_len, const u32 pw_r_len, const u32 mask80, const u32 bits14, const u32 bits15, u64 val)
{
  pw_buf[ 0] = 0;
  pw_buf[ 1] = 0;
  pw_buf[ 2] = 0;
  pw_buf[ 3] = 0;
  pw_buf[ 4] = 0;
  pw_buf[ 5] = 0;
  pw_buf[ 6] = 0;
  pw_buf[ 7] = 0;
  pw_buf[ 8] = 0;
  pw_buf[ 9] = 0;
  pw_buf[10] = 0;
  pw_buf[11] = 0;
  pw_buf[12] = 0;
  pw_buf[13] = 0;
  pw_buf[14] = 0;
  pw_buf[15] = 0;

  cs_t *cs = &root_css_buf[pw_r_len];

  u32 i;
  u32 j;

  for (i = 0, j = pw_r_len; i < pw_l_len; i++, j++)
  {
    const u32 len = cs->cs_len;

    const u64 next = val / len;
    const u64 pos  = val % len;

    val = next;

    const u32 key = cs->cs_buf[pos];

    const u32 jd4 = j / 4;
    const u32 jm4 = j % 4;

    pw_buf[jd4] |= key << ((3 - jm4) * 8);

    cs = &markov_css_buf[(j * CHARSIZ) + key];
  }

  const u32 jd4 = j / 4;
  const u32 jm4 = j % 4;

  pw_buf[jd4] |= (0xff << ((3 - jm4) * 8)) & mask80;

  if (bits14) pw_buf[14] = (pw_l_len + pw_r_len) * 8;
  if (bits15) pw_buf[15] = (pw_l_len + pw_r_len) * 8;
}

extern "C" __global__ void __launch_bounds__ (256, 1) l_markov (pw_t *pws_buf_l, cs_t *root_css_buf, cs_t *markov_css_buf, const u64 off, const u32 pw_l_len, const u32 pw_r_len, const u32 mask80, const u32 bits14, const u32 bits15, const u32 gid_max)
{
  const u32 gid = (blockIdx.x * blockDim.x) + threadIdx.x;

  if (gid >= gid_max) return;

  u32 pw_buf[16];

  generate_pw (pw_buf, root_css_buf, markov_css_buf, pw_l_len, pw_r_len, mask80, bits14, bits15, off + gid);

  pws_buf_l[gid].i[ 0] = pw_buf[ 0];
  pws_buf_l[gid].i[ 1] = pw_buf[ 1];
  pws_buf_l[gid].i[ 2] = pw_buf[ 2];
  pws_buf_l[gid].i[ 3] = pw_buf[ 3];
  pws_buf_l[gid].i[ 4] = pw_buf[ 4];
  pws_buf_l[gid].i[ 5] = pw_buf[ 5];
  pws_buf_l[gid].i[ 6] = pw_buf[ 6];
  pws_buf_l[gid].i[ 7] = pw_buf[ 7];
  pws_buf_l[gid].i[ 8] = pw_buf[ 8];
  pws_buf_l[gid].i[ 9] = pw_buf[ 9];
  pws_buf_l[gid].i[10] = pw_buf[10];
  pws_buf_l[gid].i[11] = pw_buf[11];
  pws_buf_l[gid].i[12] = pw_buf[12];
  pws_buf_l[gid].i[13] = pw_buf[13];
  pws_buf_l[gid].i[14] = pw_buf[14];
  pws_buf_l[gid].i[15] = pw_buf[15];

  pws_buf_l[gid].pw_len = pw_l_len + pw_r_len;
}

extern "C" __global__ void __launch_bounds__ (256, 1) r_markov (bf_t *pws_buf_r, cs_t *root_css_buf, cs_t *markov_css_buf, const u64 off, const u32 pw_r_len, const u32 mask80, const u32 bits14, const u32 bits15, const u32 gid_max)
{
  const u32 gid = (blockIdx.x * blockDim.x) + threadIdx.x;

  if (gid >= gid_max) return;

  u32 pw_buf[16];

  generate_pw (pw_buf, root_css_buf, markov_css_buf, pw_r_len, 0, 0, 0, 0, off + gid);

  pws_buf_r[gid].i = pw_buf[0];
}

extern "C" __global__ void __launch_bounds__ (256, 1) C_markov (comb_t *pws_buf, cs_t *root_css_buf, cs_t *markov_css_buf, const u64 off, const u32 pw_len, const u32 mask80, const u32 bits14, const u32 bits15, const u32 gid_max)
{
  const u32 gid = (blockIdx.x * blockDim.x) + threadIdx.x;

  if (gid >= gid_max) return;

  u32 pw_buf[16];

  generate_pw (pw_buf, root_css_buf, markov_css_buf, pw_len, 0, mask80, bits14, bits15, off + gid);

  pws_buf[gid].i[ 0] = pw_buf[ 0];
  pws_buf[gid].i[ 1] = pw_buf[ 1];
  pws_buf[gid].i[ 2] = pw_buf[ 2];
  pws_buf[gid].i[ 3] = pw_buf[ 3];
  pws_buf[gid].i[ 4] = pw_buf[ 4];
  pws_buf[gid].i[ 5] = pw_buf[ 5];
  pws_buf[gid].i[ 6] = pw_buf[ 6];
  pws_buf[gid].i[ 7] = pw_buf[ 7];

  pws_buf[gid].pw_len = pw_len;
}
