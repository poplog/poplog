/* --- Copyright University of Sussex 2004. All rights reserved. ----------
 * File:            $popvision/lib/arrpack.c
 * Purpose:         Support for LIB * ARRPACK
 * Author:          David Young, Dec 16 2003 (see revisions)
 * Documentation:   HELP * ARRPACK
 * Related Files:   LIB * ARRPACK, LIB * ARRPACK.H, LIB * ARRSCAN.C
 */

/* Routines for operating on arrays, element by element.

Compile using gcc, as uses preprocessor and complex maths extensions. */

#include <math.h>
#include "arrpack.h"

/*
-- Single array -------------------------------------------------------
*/

#define N2 zero
#define OP *arr = 0;
PROC1(b, N2, unsigned char, OP, )
PROC1(i, N2, int, OP, )
PROC1(s, N2, float, OP, )
PROC1(d, N2, double, OP, )
PROC1(c, N2, __complex__ float, OP, )
PROC1(z, N2, __complex__ double, OP, )
#undef OP
#undef N2

#define N2 inc
#define OP (*arr)++;
PROC1(b, N2, unsigned char, OP, )
PROC1(i, N2, int, OP, )
PROC1(s, N2, float, OP, )
PROC1(d, N2, double, OP, )
PROC1(c, N2, __complex__ float, OP, )
PROC1(z, N2, __complex__ double, OP, )
#undef OP
#undef N2

#define N2 dec
#define OP (*arr)--;
PROC1(b, N2, unsigned char, OP, )
PROC1(i, N2, int, OP, )
PROC1(s, N2, float, OP, )
PROC1(d, N2, double, OP, )
PROC1(c, N2, __complex__ float, OP, )
PROC1(z, N2, __complex__ double, OP, )
#undef OP
#undef N2

#define N2 neg
#define OP *arr = -*arr;
PROC1(i, N2, int, OP, )
PROC1(s, N2, float, OP, )
PROC1(d, N2, double, OP, )
PROC1(c, N2, __complex__ float, OP, )
PROC1(z, N2, __complex__ double, OP, )
#undef OP
#undef N2

#define N2 sqr
#define OP *arr = *arr * *arr;
PROC1(b, N2, unsigned char, OP, )
PROC1(i, N2, int, OP, )
PROC1(s, N2, float, OP, )
PROC1(d, N2, double, OP, )
PROC1(c, N2, __complex__ float, OP, )
PROC1(z, N2, __complex__ double, OP, )
#undef OP
#undef N2

#define N2 conj
#define OP *arr = ~*arr;
PROC1(c, N2, __complex__ float, OP, )
PROC1(z, N2, __complex__ double, OP, )
#undef OP
#undef N2

/* Maths functions such as log need to be done using
the single precision and complex versions. These are not
available at the time of writing - add them later. */

#define N2 log
PROC1(s, N2, float, *arr=log(*arr);, )   /* should be logf */
PROC1(d, N2, double, *arr=log(*arr);, )
/* PROC1(c, N2, __complex__ float, *arr = logc(*arr);, ) */
/* PROC1(z, N2, __complex__ double, *arr = logc(*arr);, ) */
#undef N2

#define N2 sin
PROC1(s, N2, float, *arr=sin(*arr);, )
PROC1(d, N2, double, *arr=sin(*arr);, )
#undef N2

#define N2 cos
PROC1(s, N2, float, *arr=cos(*arr);, )
PROC1(d, N2, double, *arr=cos(*arr);, )
#undef N2

#define N2 tan
PROC1(s, N2, float, *arr=tan(*arr);, )
PROC1(d, N2, double, *arr=tan(*arr);, )
#undef N2

#define N2 asin
PROC1(s, N2, float, *arr=asin(*arr);, )
PROC1(d, N2, double, *arr=asin(*arr);, )
#undef N2

#define N2 acos
PROC1(s, N2, float, *arr=acos(*arr);, )
PROC1(d, N2, double, *arr=acos(*arr);, )
#undef N2

#define N2 atan
PROC1(s, N2, float, *arr=atan(*arr);, )
PROC1(d, N2, double, *arr=atan(*arr);, )
#undef N2

#define N2 sinh
PROC1(s, N2, float, *arr=sinh(*arr);, )
PROC1(d, N2, double, *arr=sinh(*arr);, )
#undef N2

#define N2 cosh
PROC1(s, N2, float, *arr=cosh(*arr);, )
PROC1(d, N2, double, *arr=cosh(*arr);, )
#undef N2

#define N2 tanh
PROC1(s, N2, float, *arr=tanh(*arr);, )
PROC1(d, N2, double, *arr=tanh(*arr);, )
#undef N2

#define N2 exp
PROC1(s, N2, float, *arr=exp(*arr);, )
PROC1(d, N2, double, *arr=exp(*arr);, )
#undef N2

#define N2 sqrt
PROC1(s, N2, float, *arr=sqrt(*arr);, )
PROC1(d, N2, double, *arr=sqrt(*arr);, )
#undef N2

#define N2 ceil
PROC1(s, N2, float, *arr=ceil(*arr);, )
PROC1(d, N2, double, *arr=ceil(*arr);, )
#undef N2

#define N2 floor
PROC1(s, N2, float, *arr=floor(*arr);, )
PROC1(d, N2, double, *arr=floor(*arr);, )
#undef N2

#define N2 abs
PROC1(i, N2, int, *arr = *arr>0 ? *arr : -*arr;, )
PROC1(s, N2, float, *arr=fabs(*arr);, )
PROC1(d, N2, double, *arr=fabs(*arr);, )
#undef N2

#define N2 logistic
PROC1(s, N2, float, *arr = 1/(1+exp(-*arr));, )
PROC1(d, N2, double, *arr = 1/(1+exp(-*arr));, )
#undef N2

#define N2 not
PROC1(i, N2, int, *arr = !*arr;, )
#undef N2

/*
-- Single array and scalars -------------------------------------------
*/

#define N2 k
#define OP(ADDR) *arr = ADDR k;
PROC1(b, N2, unsigned char, OP( ), int k,)
PROC1(i, N2, int, OP( ), int k,)
PROC1(s, N2, float, OP( ), float k,)
PROC1(d, N2, double, OP( ), double k,)
PROC1(c, N2, __complex__ float, OP(*), __complex__ float *k,)
PROC1(z, N2, __complex__ double, OP(*), __complex__ double *k,)
#undef OP
#undef N2

#define N2 plusk
#define OP(ADDR) *arr += ADDR k;
PROC1(b, N2, unsigned char, OP( ), int k,)
PROC1(i, N2, int, OP( ), int k,)
PROC1(s, N2, float, OP( ), float k,)
PROC1(d, N2, double, OP( ), double k,)
PROC1(c, N2, __complex__ float, OP(*), __complex__ float *k,)
PROC1(z, N2, __complex__ double, OP(*), __complex__ double *k,)
#undef OP
#undef N2

#define N2 minusk
#define OP(ADDR) *arr -= ADDR k;
PROC1(b, N2, unsigned char, OP( ), int k,)
PROC1(i, N2, int, OP( ), int k,)
PROC1(s, N2, float, OP( ), float k,)
PROC1(d, N2, double, OP( ), double k,)
PROC1(c, N2, __complex__ float, OP(*), __complex__ float *k,)
PROC1(z, N2, __complex__ double, OP(*), __complex__ double *k,)
#undef OP
#undef N2

#define N2 kminus
#define OP(ADDR) *arr = ADDR k - *arr;
PROC1(b, N2, unsigned char, OP( ), int k,)
PROC1(i, N2, int, OP( ), int k,)
PROC1(s, N2, float, OP( ), float k,)
PROC1(d, N2, double, OP( ), double k,)
PROC1(c, N2, __complex__ float, OP(*), __complex__ float *k,)
PROC1(z, N2, __complex__ double, OP(*), __complex__ double *k,)
#undef OP
#undef N2

#define N2 timesk
#define OP(ADDR) *arr *= ADDR k;
PROC1(b, N2, unsigned char, OP( ), int k,)
PROC1(i, N2, int, OP( ), int k,)
PROC1(s, N2, float, OP( ), float k,)
PROC1(d, N2, double, OP( ), double k,)
PROC1(c, N2, __complex__ float, OP(*), __complex__ float *k,)
PROC1(z, N2, __complex__ double, OP(*), __complex__ double *k,)
#undef OP
#undef N2

#define N2 divk
#define OP(ADDR) *arr /= ADDR k;
PROC1(b, N2, unsigned char, OP( ), int k,)
PROC1(i, N2, int, OP( ), int k,)
PROC1(s, N2, float, OP( ), float k,)
PROC1(d, N2, double, OP( ), double k,)
PROC1(c, N2, __complex__ float, OP(*), __complex__ float *k,)
PROC1(z, N2, __complex__ double, OP(*), __complex__ double *k,)
#undef OP
#undef N2

#define N2 kdiv
#define OP(ADDR) *arr = ADDR k / *arr;
PROC1(b, N2, unsigned char, OP( ), int k,)
PROC1(i, N2, int, OP( ), int k,)
PROC1(s, N2, float, OP( ), float k,)
PROC1(d, N2, double, OP( ), double k,)
PROC1(c, N2, __complex__ float, OP(*), __complex__ float *k,)
PROC1(z, N2, __complex__ double, OP(*), __complex__ double *k,)
#undef OP
#undef N2

#define N2 powk     /* uses math lib pow
    - should be improved for ints, and needs complex ops */
#define OP(ADDR) *arr = pow(*arr, ADDR k);
PROC1(b, N2, unsigned char, OP( ), int k,)
PROC1(i, N2, int, OP( ), int k,)
PROC1(s, N2, float, OP( ), float k,)
PROC1(d, N2, double, OP( ), double k,)
#undef OP
#undef N2

#define N2 modk
PROC1(b, N2, unsigned char, *arr %= k;, int k,)
PROC1(i, N2, int, *arr %= k;, int k,)
PROC1(s, N2, float, *arr = fmod(*arr, k);, float k,)
PROC1(d, N2, double, *arr = fmod(*arr, k);, double k,)
#undef N2

#define N2 maxk
#define OP(ADDR) *arr = *arr > ADDR k ? *arr : ADDR k;
PROC1(b, N2, unsigned char, OP( ), int k,)
PROC1(i, N2, int, OP( ), int k,)
PROC1(s, N2, float, OP( ), float k,)
PROC1(d, N2, double, OP( ), double k,)
#undef OP
#undef N2

#define N2 mink
#define OP(ADDR) *arr = *arr < ADDR k ? *arr : ADDR k;
PROC1(b, N2, unsigned char, OP( ), int k,)
PROC1(i, N2, int, OP( ), int k,)
PROC1(s, N2, float, OP( ), float k,)
PROC1(d, N2, double, OP( ), double k,)
#undef OP
#undef N2

#define N2 link
#define OP(ADDR) *arr = ADDR k1 * *arr + ADDR k2;
PROC1(b, N2, unsigned char, OP( ), int k1, int k2,)
PROC1(i, N2, int, OP( ), int k1, int k2,)
PROC1(s, N2, float, OP( ), float k1, float k2,)
PROC1(d, N2, double, OP( ), double k1, double k2,)
PROC1(c, N2, __complex__ float, OP(*),
    __complex__ float *k1, __complex__ float *k2,)
PROC1(z, N2, __complex__ double, OP(*),
    __complex__ double *k1, __complex__ double *k2,)
#undef OP
#undef N2

#define N2 quadk
#define OP(ADDR) *arr = ADDR k1 * *arr * *arr + ADDR k2 * *arr + ADDR k3;
PROC1(b, N2, unsigned char, OP( ), int k1, int k2, int k3,)
PROC1(i, N2, int, OP( ), int k1, int k2, int k3,)
PROC1(s, N2, float, OP( ), float k1, float k2, float k3,)
PROC1(d, N2, double, OP( ), double k1, double k2, double k3,)
PROC1(c, N2, __complex__ float, OP(*),
  __complex__ float *k1, __complex__ float *k2, __complex__ float *k3,)
PROC1(z, N2, __complex__ double, OP(*),
  __complex__ double *k1, __complex__ double *k2, __complex__ double *k3,)
#undef OP
#undef N2

#define N2 sumof
#define OP *k += *arr;
PROC1(b, N2, unsigned char, OP, int *k,)
PROC1(i, N2, int, OP, int *k,)
PROC1(s, N2, float, OP, float *k,)
PROC1(d, N2, double, OP, double *k,)
PROC1(c, N2, __complex__ float, OP, __complex__ float *k,)
PROC1(z, N2, __complex__ double, OP, __complex__ double *k,)
#undef OP
#undef N2

#define N2 maxof
#define OP *k = *k > *arr ? *k : *arr;
PROC1(b, N2, unsigned char, OP, int *k,)
PROC1(i, N2, int, OP, int *k,)
PROC1(s, N2, float, OP, float *k,)
PROC1(d, N2, double, OP, double *k,)
#undef OP
#undef N2

#define N2 minof
#define OP *k = *k < *arr ? *k : *arr;
PROC1(b, N2, unsigned char, OP, int *k,)
PROC1(i, N2, int, OP, int *k,)
PROC1(s, N2, float, OP, float *k,)
PROC1(d, N2, double, OP, double *k,)
#undef OP
#undef N2

#define N2 minmaxof
#define OP *k1 = *k1 < *arr ? *k1 : *arr;                            \
           *k2 = *k2 > *arr ? *k2 : *arr;
#define ARGS(TYPE) TYPE *k1, TYPE *k2,
PROC1(b, N2, unsigned char, OP, ARGS(int))
PROC1(i, N2, int, OP, ARGS(int))
PROC1(s, N2, float, OP, ARGS(float))
PROC1(d, N2, double, OP, ARGS(double))
#undef ARGS
#undef OP
#undef N2

/*
-- Two arrays ---------------------------------------------------------
*/

#define N2 plus
#define OP *arr2 += *arr1;
PROC2S(b, N2, unsigned char, OP, )
PROC2S(i, N2, int, OP, )
PROC2S(s, N2, float, OP, )
PROC2S(d, N2, double, OP, )
PROC2S(c, N2, __complex__ float, OP, )
PROC2S(z, N2, __complex__ double, OP, )
#undef OP
#undef N2

#define N2 minus
#define OP *arr2 = *arr1 - *arr2;
PROC2S(b, N2, unsigned char, OP, )
PROC2S(i, N2, int, OP, )
PROC2S(s, N2, float, OP, )
PROC2S(d, N2, double, OP, )
PROC2S(c, N2, __complex__ float, OP, )
PROC2S(z, N2, __complex__ double, OP, )
#undef OP
#undef N2

#define N2 minusrev
#define OP *arr2 = *arr2 - *arr1;
PROC2S(b, N2, unsigned char, OP, )
PROC2S(i, N2, int, OP, )
PROC2S(s, N2, float, OP, )
PROC2S(d, N2, double, OP, )
PROC2S(c, N2, __complex__ float, OP, )
PROC2S(z, N2, __complex__ double, OP, )
#undef OP
#undef N2

#define N2 times
#define OP *arr2 *= *arr1;
PROC2S(b, N2, unsigned char, OP, )
PROC2S(i, N2, int, OP, )
PROC2S(s, N2, float, OP, )
PROC2S(d, N2, double, OP, )
PROC2S(c, N2, __complex__ float, OP, )
PROC2S(z, N2, __complex__ double, OP, )
#undef OP
#undef N2

#define N2 div
#define OP *arr2 = *arr1 / *arr2;
PROC2S(b, N2, unsigned char, OP, )
PROC2S(i, N2, int, OP, )
PROC2S(s, N2, float, OP, )
PROC2S(d, N2, double, OP, )
PROC2S(c, N2, __complex__ float, OP, )
PROC2S(z, N2, __complex__ double, OP, )
#undef OP
#undef N2

#define N2 divrev
#define OP *arr2 = *arr2 / *arr1;
PROC2S(b, N2, unsigned char, OP, )
PROC2S(i, N2, int, OP, )
PROC2S(s, N2, float, OP, )
PROC2S(d, N2, double, OP, )
PROC2S(c, N2, __complex__ float, OP, )
PROC2S(z, N2, __complex__ double, OP, )
#undef OP
#undef N2

#define N2 pow    /* Needs complex, and better lib for ints */
#define OP *arr2 = pow(*arr1, *arr2);
PROC2S(b, N2, unsigned char, OP, )
PROC2S(i, N2, int, OP, )
PROC2S(s, N2, float, OP, )
PROC2S(d, N2, double, OP, )
#undef OP
#undef N2

#define N2 mod
PROC2S(b, N2, unsigned char, *arr2 = *arr1 % *arr2;, )
PROC2S(i, N2, int, *arr2 = *arr1 % *arr2;, )
PROC2S(s, N2, float, *arr2 = fmod(*arr1, *arr2);, )
PROC2S(d, N2, double, fmod(*arr1, *arr2);, )
#undef N2

#define N2 max
#define OP *arr2 = *arr1 > *arr2 ? *arr1 : *arr2;
PROC2S(b, N2, unsigned char, OP, )
PROC2S(i, N2, int, OP, )
PROC2S(s, N2, float, OP, )
PROC2S(d, N2, double, OP, )
#undef OP
#undef N2

#define N2 min
#define OP *arr2 = *arr1 < *arr2 ? *arr1 : *arr2;
PROC2S(b, N2, unsigned char, OP, )
PROC2S(i, N2, int, OP, )
PROC2S(s, N2, float, OP, )
PROC2S(d, N2, double, OP, )
#undef OP
#undef N2

#define N2 arctan2  /* note switch in order */
#define OP *arr2 = atan2(*arr2, *arr1);
PROC2S(s, N2, float, OP, )
PROC2S(d, N2, double, OP, )
#undef OP
#undef N2

#define N2 sumsqr
#define OP *arr2 = *arr1 * *arr1 + *arr2 * *arr2;
PROC2S(s, N2, float, OP, )
PROC2S(d, N2, double, OP, )
#undef OP
#undef N2

#define N2 hypot
#define OP *arr2 = hypot(*arr1, *arr2);
PROC2S(s, N2, float, OP, )
PROC2S(d, N2, double, OP, )
#undef OP
#undef N2

#define N2 cartopol
#define OP(TYPE)                                                     \
    TYPE a;                                                          \
    a = *arr1;                                                       \
    *arr1 = hypot(*arr1, *arr2);                                     \
    *arr2 = atan2(*arr2, a);
PROC2S(s, N2, float, OP(float), )
PROC2S(d, N2, double, OP(double), )
#undef OP
#undef N2

#define N2 poltocar
#define OP(TYPE)                                                     \
    TYPE a;                                                          \
    a = *arr1;                                                       \
    *arr1 = a * cos(*arr2);                                          \
    *arr2 = a * sin(*arr2);
PROC2S(s, N2, float, OP(float), )
PROC2S(d, N2, double, OP(double), )
#undef OP
#undef N2

PROC2S(i, and, int, *arr2 = *arr1 && *arr2;, )
PROC2S(i, or,  int, *arr2 = *arr1 || *arr2;, )
PROC2S(i, xor, int, *arr2 = !*arr1 != !*arr2;, )

/*
-- Two arrays and scalars ---------------------------------------------
*/

#define N2 lincomb
#define OP(ADDR) *arr2 = ADDR k1 * *arr1 + ADDR k2 * *arr2;
PROC2S(b, N2, unsigned char, OP( ), int k1, int k2,)
PROC2S(i, N2, int, OP( ), int k1, int k2,)
PROC2S(s, N2, float, OP( ), float k1, float k2,)
PROC2S(d, N2, double, OP( ), double k1, double k2,)
PROC2S(c, N2, __complex__ float, OP(*),
    __complex__ float *k1, __complex__ float *k2,)
PROC2S(z, N2, __complex__ double, OP(*),
    __complex__ double *k1, __complex__ double *k2,)
#undef OP
#undef N2

#define N2 keq
#define OP(ADDR) *arr2 = *arr1 == ADDR k;
PROC2(bi, N2, unsigned char, int, OP( ), int k,)
PROC2(ii, N2, int, int, OP( ), int k,)
PROC2(si, N2, float, int, OP( ), float k,)
PROC2(di, N2, double, int, OP( ), double k,)
PROC2(ci, N2, __complex__ float, int, OP(*), __complex__ float *k,)
PROC2(zi, N2, __complex__ double, int, OP(*), __complex__ double *k,)
#undef OP
#undef N2

#define N2 kne
#define OP(ADDR) *arr2 = *arr1 != ADDR k;
PROC2(bi, N2, unsigned char, int, OP( ), int k,)
PROC2(ii, N2, int, int, OP( ), int k,)
PROC2(si, N2, float, int, OP( ), float k,)
PROC2(di, N2, double, int, OP( ), double k,)
PROC2(ci, N2, __complex__ float, int, OP(*), __complex__ float *k,)
PROC2(zi, N2, __complex__ double, int, OP(*), __complex__ double *k,)
#undef OP
#undef N2

#define N2 kgt
#define OP(ADDR) *arr2 = ADDR k > *arr1;
PROC2(bi, N2, unsigned char, int, OP( ), int k,)
PROC2(ii, N2, int, int, OP( ), int k,)
PROC2(si, N2, float, int, OP( ), float k,)
PROC2(di, N2, double, int, OP( ), double k,)
#undef OP
#undef N2

#define N2 kge
#define OP(ADDR) *arr2 = ADDR k >= *arr1;
PROC2(bi, N2, unsigned char, int, OP( ), int k,)
PROC2(ii, N2, int, int, OP( ), int k,)
PROC2(si, N2, float, int, OP( ), float k,)
PROC2(di, N2, double, int, OP( ), double k,)
#undef OP
#undef N2

#define N2 klt
#define OP(ADDR) *arr2 = ADDR k < *arr1;
PROC2(bi, N2, unsigned char, int, OP( ), int k,)
PROC2(ii, N2, int, int, OP( ), int k,)
PROC2(si, N2, float, int, OP( ), float k,)
PROC2(di, N2, double, int, OP( ), double k,)
#undef OP
#undef N2

#define N2 kle
#define OP(ADDR) *arr2 = ADDR k <= *arr1;
PROC2(bi, N2, unsigned char, int, OP( ), int k,)
PROC2(ii, N2, int, int, OP( ), int k,)
PROC2(si, N2, float, int, OP( ), float k,)
PROC2(di, N2, double, int, OP( ), double k,)
#undef OP
#undef N2

/*
-- Three arrays -------------------------------------------------------
*/

#define N2 eq
#define OP *arr3 = *arr1 == *arr2;
PROC3(bbi, N2, unsigned char, unsigned char, int, OP, )
PROC3(iii, N2, int, int, int, OP, )
PROC3(ssi, N2, float, float, int, OP, )
PROC3(ddi, N2, double, double, int, OP, )
PROC3(cci, N2, __complex__ float, __complex__ float, int, OP, )
PROC3(zzi, N2, __complex__ double, __complex__ double, int, OP, )
#undef OP
#undef N2

#define N2 ne
#define OP *arr3 = *arr1 != *arr2;
PROC3(bbi, N2, unsigned char, unsigned char, int, OP, )
PROC3(iii, N2, int, int, int, OP, )
PROC3(ssi, N2, float, float, int, OP, )
PROC3(ddi, N2, double, double, int, OP, )
PROC3(cci, N2, __complex__ float, __complex__ float, int, OP, )
PROC3(zzi, N2, __complex__ double, __complex__ double, int, OP, )
#undef OP
#undef N2

#define N2 gt
#define OP *arr3 = *arr1 > *arr2;
PROC3(bbi, N2, unsigned char, unsigned char, int, OP, )
PROC3(iii, N2, int, int, int, OP, )
PROC3(ssi, N2, float, float, int, OP, )
PROC3(ddi, N2, double, double, int, OP, )
#undef OP
#undef N2

#define N2 ge
#define OP *arr3 = *arr1 >= *arr2;
PROC3(bbi, N2, unsigned char, unsigned char, int, OP, )
PROC3(iii, N2, int, int, int, OP, )
PROC3(ssi, N2, float, float, int, OP, )
PROC3(ddi, N2, double, double, int, OP, )
#undef OP
#undef N2

#define N2 lt
#define OP *arr3 = *arr1 < *arr2;
PROC3(bbi, N2, unsigned char, unsigned char, int, OP, )
PROC3(iii, N2, int, int, int, OP, )
PROC3(ssi, N2, float, float, int, OP, )
PROC3(ddi, N2, double, double, int, OP, )
#undef OP
#undef N2

#define N2 le
#define OP *arr3 = *arr1 <= *arr2;
PROC3(bbi, N2, unsigned char, unsigned char, int, OP, )
PROC3(iii, N2, int, int, int, OP, )
PROC3(ssi, N2, float, float, int, OP, )
PROC3(ddi, N2, double, double, int, OP, )
#undef OP
#undef N2

/*
-- Copying and type conversion ----------------------------------------
*/

#define N2 cop
#define OP(TYPE2) *arr2 = (TYPE2)*arr1;
#define TYPE1 unsigned char
PROC2(bb, N2, TYPE1, unsigned char, OP(unsigned char), )
PROC2(bi, N2, TYPE1, int, OP(int), )
PROC2(bs, N2, TYPE1, float, OP(float), )
PROC2(bd, N2, TYPE1, double, OP(double), )
PROC2(bc, N2, TYPE1, __complex__ float, OP(__complex__ float), )
PROC2(bz, N2, TYPE1, __complex__ double, OP(__complex__ double), )
#undef TYPE1
#define TYPE1 int
PROC2(ib, N2, TYPE1, unsigned char, OP(unsigned char), )
PROC2(ii, N2, TYPE1, int, OP(int), )
PROC2(is, N2, TYPE1, float, OP(float), )
PROC2(id, N2, TYPE1, double, OP(double), )
PROC2(ic, N2, TYPE1, __complex__ float, OP(__complex__ float), )
PROC2(iz, N2, TYPE1, __complex__ double, OP(__complex__ double), )
#undef TYPE1
#define TYPE1 float
PROC2(sb, N2, TYPE1, unsigned char, OP(unsigned char), )
PROC2(si, N2, TYPE1, int, OP(int), )
PROC2(ss, N2, TYPE1, float, OP(float), )
PROC2(sd, N2, TYPE1, double, OP(double), )
PROC2(sc, N2, TYPE1, __complex__ float, OP(__complex__ float), )
PROC2(sz, N2, TYPE1, __complex__ double, OP(__complex__ double), )
#undef TYPE1
#define TYPE1 double
PROC2(db, N2, TYPE1, unsigned char, OP(unsigned char), )
PROC2(di, N2, TYPE1, int, OP(int), )
PROC2(ds, N2, TYPE1, float, OP(float), )
PROC2(dd, N2, TYPE1, double, OP(double), )
PROC2(dc, N2, TYPE1, __complex__ float, OP(__complex__ float), )
PROC2(dz, N2, TYPE1, __complex__ double, OP(__complex__ double), )
#undef TYPE1
#define TYPE1 __complex__ float
PROC2(cc, N2, TYPE1, __complex__ float, OP(__complex__ float), )
PROC2(cz, N2, TYPE1, __complex__ double, OP(__complex__ double), )
#undef TYPE1
#define TYPE1 __complex__ double
PROC2(zc, N2, TYPE1, __complex__ float, OP(__complex__ float), )
PROC2(zz, N2, TYPE1, __complex__ double, OP(__complex__ double), )
#undef TYPE1
#undef OP
#undef N2

#define N2 real
#define OP(TYPE2) *arr2 = (TYPE2) __real__ *arr1;
#define TYPE1 __complex__ float
PROC2(cb, N2, TYPE1, unsigned char, OP(unsigned char), )
PROC2(ci, N2, TYPE1, int, OP(int), )
PROC2(cs, N2, TYPE1, float, OP(float), )
PROC2(cd, N2, TYPE1, double, OP(double), )
#undef TYPE1
#define TYPE1 __complex__ double
PROC2(zb, N2, TYPE1, unsigned char, OP(unsigned char), )
PROC2(zi, N2, TYPE1, int, OP(int), )
PROC2(zs, N2, TYPE1, float, OP(float), )
PROC2(zd, N2, TYPE1, double, OP(double), )
#undef TYPE1
#undef OP
#undef N2

#define N2 imag
#define OP(TYPE2) *arr2 = (TYPE2) __imag__ *arr1;
#define TYPE1 __complex__ float
PROC2(cb, N2, TYPE1, unsigned char, OP(unsigned char), )
PROC2(ci, N2, TYPE1, int, OP(int), )
PROC2(cs, N2, TYPE1, float, OP(float), )
PROC2(cd, N2, TYPE1, double, OP(double), )
#undef TYPE1
#define TYPE1 __complex__ double
PROC2(zb, N2, TYPE1, unsigned char, OP(unsigned char), )
PROC2(zi, N2, TYPE1, int, OP(int), )
PROC2(zs, N2, TYPE1, float, OP(float), )
PROC2(zd, N2, TYPE1, double, OP(double), )
#undef TYPE1
#undef OP
#undef N2

#define N2 ctori
#define OP(TYPE2) *arr2 = (TYPE2) __real__ *arr1;                    \
                  *arr3 = (TYPE2) __imag__ *arr1;
#define TYPE1 __complex__ float
PROC3(cb, N2, TYPE1, unsigned char, unsigned char, OP(unsigned char), )
PROC3(ci, N2, TYPE1, int, int, OP(int), )
PROC3(cs, N2, TYPE1, float, float, OP(float), )
PROC3(cd, N2, TYPE1, double, double, OP(double), )
#undef TYPE1
#define TYPE1 __complex__ double
PROC3(zb, N2, TYPE1, unsigned char, unsigned char, OP(unsigned char), )
PROC3(zi, N2, TYPE1, int, int, OP(int), )
PROC3(zs, N2, TYPE1, float, float, OP(float), )
PROC3(zd, N2, TYPE1, double, double, OP(double), )
#undef TYPE1
#undef OP
#undef N2

#define N2 ritoc
#define OP(TYPE3) *arr3 = (TYPE3)*arr1 + (TYPE3)*arr2 * 1i;
#define TYPE3 __complex__ float
PROC3(bc, N2, unsigned char, unsigned char, TYPE3, OP(TYPE3), )
PROC3(ic, N2, int, int, TYPE3, OP(TYPE3), )
PROC3(sc, N2, float, float, TYPE3, OP(TYPE3), )
PROC3(dc, N2, float, float, TYPE3, OP(TYPE3), )
#undef TYPE3
#define TYPE3 __complex__ double
PROC3(bz, N2, unsigned char, unsigned char, TYPE3, OP(TYPE3), )
PROC3(iz, N2, int, int, TYPE3, OP(TYPE3), )
PROC3(sz, N2, float, float, TYPE3, OP(TYPE3), )
PROC3(dz, N2, float, float, TYPE3, OP(TYPE3), )
#undef TYPE3
#undef OP
#undef N2

/*
-- Reshaping ----------------------------------------------------------
*/

PROCR(bAreshape, unsigned char)
PROCR(iAreshape, int)
PROCR(sAreshape, float)
PROCR(dAreshape, double)
PROCR(cAreshape, __complex__ float)
PROCR(zAreshape, __complex__ double)

/*
-- Setting to index ---------------------------------------------------
*/

PROCI(b, index, unsigned char)
PROCI(i, index, int)
PROCI(s, index, float)
PROCI(d, index, double)
PROCI(c, index, __complex__ float)
PROCI(z, index, __complex__ double)

/*
-- Conversion to/from indexed form ------------------------------------
*/

#define N2 getvals
#define OP *vals++ = *arr;
#define ARGS(TYPE) TYPE *vals,
PROCV(b, N2, unsigned char, OP, ARGS(unsigned char))
PROCV(i, N2, int, OP, ARGS(int))
PROCV(s, N2, float, OP, ARGS(float))
PROCV(d, N2, double, OP, ARGS(double))
PROCV(c, N2, __complex__ float, OP, ARGS(__complex__ float))
PROCV(z, N2, __complex__ double, OP, ARGS(__complex__ double))
#undef ARGS
#undef OP
#undef N2

#define N2 setvals
#define OP *arr = *vals++;
#define ARGS(TYPE) TYPE *vals,
PROCV(b, N2, unsigned char, OP, ARGS(unsigned char))
PROCV(i, N2, int, OP, ARGS(int))
PROCV(s, N2, float, OP, ARGS(float))
PROCV(d, N2, double, OP, ARGS(double))
PROCV(c, N2, __complex__ float, OP, ARGS(__complex__ float))
PROCV(z, N2, __complex__ double, OP, ARGS(__complex__ double))
#undef ARGS
#undef OP
#undef N2

/*
-- Finding non-zero elements ------------------------------------------
*/

PROCF(b, find, unsigned char)
PROCF(i, find, int)
PROCF(s, find, float)
PROCF(d, find, double)
PROCF(c, find, __complex__ float)
PROCF(z, find, __complex__ double)

/*
-- Setting a spec vector ----------------------------------------------
*/

int xAspecv(int *spec, int cdopt, int ordopt)
{
    int off, d, nd, *wk, *sps;
    return arrspec(spec, cdopt, ordopt, &off, &d, &nd, &sps, &wk);
}

int xAindv(int *spec)
{
    int nel, d0, *d, *dend;
    return arrind(spec, &nel, &d0, &d, &dend);
}

/* --- Revision History ---------------------------------------------------
--- David Young, Apr 26 2004
        Added minusrev and divrev
--- David Young, Apr  1 2004
        Added "find" PROCF, xAindv, "value" PROCV functions
--- David Young, Dec 19 2003
        Added xAspecv
 */
