/* --- Copyright University of Sussex 2004. All rights reserved. ----------
 * File:            $popvision/lib/arrpack.h
 * Purpose:         Support for ARRPACK.C
 * Author:          David Young, Dec 16 2003 (see revisions)
 * Documentation:   HELP * ARRPACK
 * Related Files:   LIB * ARRPACK.C
 */

#include "arrscan.h"

/* Macros to scan arrays.

Needs the Gnu preprocessor and language extensions. */

#define PROC1N(N1, N2, TYPE, OP, ARGS...) /* 1 array normal */       \
int N1 ## A ## N2(ARGS TYPE *arr, int *spec)                         \
{                                                                    \
    int err, off, d, nd;                                             \
    int *wk, *wp, *sps, *sp;                                         \
    TYPE *arrend;                                                    \
                                                                     \
    if (err = arrspec(spec, 1, 1, &off, &d, &nd, &sps, &wk))         \
        return err;                                                  \
    arr += off;                                                      \
                                                                     \
    while (1) {                                                      \
        /* dimension 1 expanded */                                   \
        for (arrend = arr+nd; arr < arrend; arr += d)                \
            { OP }                                                   \
        for (sp=sps, wp=wk; ; ) {   /* loop over dims 2...N */       \
            if (sp == wk) return 0;                                  \
            arr += *sp++;                                            \
            if (++(*wp) == *sp++)                                    \
                *wp++ = 0;                                           \
            else                                                     \
                break;                                               \
        }                                                            \
    }                                                                \
}                                                                    \

#define PROC1M(N1, N2, TYPE, OP, ARGS...) /* 1 array masked */       \
int N1 ## AM ## N2(ARGS int *mask, int *specm, TYPE *arr, int *spec) \
{                                                                    \
    int err, off, d, nd, offm, dm, ndm,                              \
        *wk, *wp, *sps, *sp,                                         \
        *wkm, *wpm, *spsm, *spm;                                     \
    TYPE *arrend;                                                    \
                                                                     \
    if (                                                             \
        (err = arrspec(spec, 0,1, &off,  &d,  &nd,  &sps,  &wk))     \
    ||  (err = arrspec(specm,0,1, &offm, &dm, &ndm, &spsm, &wkm))    \
    ||  (err = arrscan_check(spec, specm))                           \
        ) return err;                                                \
    arr += off; mask += offm;                                        \
                                                                     \
    while (1) {                                                      \
        for (arrend = arr+nd; arr < arrend; arr += d, mask += dm)    \
            if (*mask) { OP }                                        \
        for (sp=sps, spm=spsm, wp=wk; ; ) {                          \
            if (sp == wk) return 0;                                  \
            arr += *sp++;     mask += *spm++;                        \
            if (spm++, ++(*wp) == *sp++)                             \
                *wp++ = 0;                                           \
            else                                                     \
                break;                                               \
        }                                                            \
    }                                                                \
}                                                                    \

#define PROC1I(N1, N2, TYPE, OP, ARGS...) /* 1 array indexed*/       \
int N1 ## AI ## N2(ARGS int N, TYPE *arrbase, int *spec, int *index) \
{                                                                    \
    int err, nel, d0, *d, *dend;                                     \
    int ndim, *indexend, i;                                          \
    TYPE *arr;                                                       \
                                                                     \
    if (err = arrind(spec, &nel, &d0, &d, &dend)) return err;        \
    ndim = dend - d;                                                 \
                                                                     \
    /* It is tempting here to do arrbase+=d0, but this isn't allowed \
    if the result goes outside the array, so trust the compiler to   \
    do the right optimisations below. */                             \
                                                                     \
    if (ndim == 1)                                                   \
        for (indexend = index+N; index<indexend; ) {                 \
            if ((i = *index++ + d0) >= nel || i < 0) return 5;       \
            arr = arrbase + i;                                       \
            { OP }                                                   \
        }                                                            \
                                                                     \
    else if (ndim == 2) {                                            \
        int d1 = *d, d2 = *(d+1), x, y;                              \
        for (indexend = index+2*N; index<indexend; ) {               \
            x = *index++; y = *index++;                              \
            if ((i = d0 + d1*x + d2*y) >= nel || i < 0) return 5;    \
            arr = arrbase + i;                                       \
            { OP }                                                   \
        }                                                            \
    }                                                                \
                                                                     \
    else {                                                           \
        int *dp;                                                     \
        for (indexend = index+ndim*N; index<indexend; ) {            \
            for (dp=d, i=d0; dp < dend; ) i += *index++ * *dp++;     \
            if (i >= nel || i < 0) return 5;                         \
            arr = arrbase + i;                                       \
            { OP }                                                   \
        }                                                            \
    }                                                                \
    return 0;                                                        \
}                                                                    \

#define PROC1(N1, N2, TYPE, OP, ARGS...)                             \
            PROC1N(N1, N2, TYPE, OP, ARGS)                           \
            PROC1M(N1, N2, TYPE, OP, ARGS)                           \
            PROC1I(N1, N2, TYPE, OP, ARGS)                           \

#define PROCV(N1, N2, TYPE, OP, ARGS...)                             \
            PROC1I(N1, N2, TYPE, OP, ARGS)                           \


#define PROC2N(N1, N2, TYPE1, TYPE2, OP, ARGS...) /* 2 arrays */     \
int N1 ## A ## N2(ARGS TYPE1 *arr1, int *spec1, TYPE2 *arr2, int *spec2) \
{                                                                    \
    int err, off1, d1, nd1, off2, d2, nd2,                           \
        *wk1, *wp1, *sps1, *sp1,                                     \
        *wk2, *wp2, *sps2, *sp2;                                     \
    TYPE1 *arrend;                                                   \
                                                                     \
    if (                                                             \
        (err = arrspec(spec1,0,1, &off1, &d1, &nd1, &sps1, &wk1))    \
    ||  (err = arrspec(spec2,0,1, &off2, &d2, &nd2, &sps2, &wk2))    \
    ||  (err = arrscan_check(spec1, spec2))                          \
        ) return err;                                                \
    arr1 += off1; arr2 += off2;                                      \
                                                                     \
    while (1) {                                                      \
        for (arrend = arr1+nd1; arr1 < arrend; arr1 += d1, arr2 += d2) \
            { OP }                                                   \
        for (sp1=sps1, sp2=sps2, wp1=wk1; ; ) {                      \
            if (sp1 == wk1) return 0;                                \
            arr1 += *sp1++;     arr2 += *sp2++;                      \
            if (sp2++, ++(*wp1) == *sp1++)                           \
                *wp1++ = 0;                                          \
            else                                                     \
                break;                                               \
        }                                                            \
    }                                                                \
}                                                                    \

#define PROC2M(N1, N2, TYPE1, TYPE2, OP, ARGS...) /* 2 arrays */     \
int N1 ## AM ## N2(ARGS int *mask, int *specm,                       \
         TYPE1 *arr1, int *spec1, TYPE2 *arr2, int *spec2)           \
{                                                                    \
    int err, off1, d1, nd1, off2, d2, nd2, offm, dm, ndm,            \
        *wk1, *wp1, *sps1, *sp1,                                     \
        *wk2, *wp2, *sps2, *sp2,                                     \
        *wkm, *wpm, *spsm, *spm;                                     \
    TYPE1 *arrend;                                                   \
                                                                     \
    if (                                                             \
        (err = arrspec(spec1,0,1, &off1, &d1, &nd1, &sps1, &wk1))    \
    ||  (err = arrspec(spec2,0,1, &off2, &d2, &nd2, &sps2, &wk2))    \
    ||  (err = arrscan_check(spec1, spec2))                          \
    ||  (err = arrspec(specm,0,1, &offm, &dm, &ndm, &spsm, &wkm))    \
    ||  (err = arrscan_check(spec1, specm))                          \
        ) return err;                                                \
    arr1 += off1; arr2 += off2; mask += offm;                        \
                                                                     \
    while (1) {                                                      \
        for (arrend = arr1+nd1;                                      \
             arr1 < arrend;                                          \
             arr1 += d1, arr2 += d2, mask += dm)                     \
            if (*mask) { OP }                                        \
        for (sp1=sps1, sp2=sps2, spm = spsm, wp1=wk1; ; ) {          \
            if (sp1 == wk1) return 0;                                \
            arr1 += *sp1++;   arr2 += *sp2++;   mask += *spm++;      \
            if (sp2++, spm++, ++(*wp1) == *sp1++)                    \
                *wp1++ = 0;                                          \
            else                                                     \
                break;                                               \
        }                                                            \
    }                                                                \
}                                                                    \

#define PROC2I(N1, N2, TYPE1, TYPE2, OP, ARGS...) /* 2 arrays ind*/  \
int N1 ## AI ## N2(ARGS int N,                                       \
        TYPE1 *arrbase1, int *spec1, int *index1,                    \
        TYPE2 *arrbase2, int *spec2, int *index2)                    \
{                                                                    \
    int err, nel1, d01, *d1, *dend1, nel2, d02, *d2, *dend2;         \
    int ndim1, ndim2, *indexend, i1, i2;                             \
    TYPE1 *arr1;                                                     \
    TYPE2 *arr2;                                                     \
                                                                     \
    if (                                                             \
        (err = arrind(spec1, &nel1, &d01, &d1, &dend1))              \
    ||  (err = arrind(spec2, &nel2, &d02, &d2, &dend2))              \
        ) return err;                                                \
    ndim1 = dend1 - d1;                                              \
    ndim2 = dend2 - d2;                                              \
                                                                     \
    if (ndim1 == 1 && ndim2 == 1)                                    \
        for (indexend = index1+N; index1<indexend; ) {               \
            if ((i1 = *index1++ + d01) >= nel1 || i1 < 0) return 5;  \
            if ((i2 = *index2++ + d02) >= nel2 || i2 < 0) return 5;  \
            arr1 = arrbase1 + i1;                                    \
            arr2 = arrbase2 + i2;                                    \
            { OP }                                                   \
        }                                                            \
                                                                     \
    else if (ndim1 == 2 && ndim2 == 2) {                             \
        int d11 = *d1, d21 = *(d1+1), x1, y1,                        \
            d12 = *d2, d22 = *(d2+1), x2, y2;                        \
        for (indexend = index1+2*N; index1<indexend; ) {             \
            x1 = *index1++; y1 = *index1++;                          \
            x2 = *index2++; y2 = *index2++;                          \
            if ((i1 = d01 + d11*x1 + d21*y1) >= nel1 || i1 < 0)      \
                return 5;                                            \
            if ((i2 = d02 + d12*x2 + d22*y2) >= nel2 || i2 < 0)      \
                return 5;                                            \
            arr1 = arrbase1 + i1;                                    \
            arr2 = arrbase2 + i2;                                    \
            { OP }                                                   \
        }                                                            \
    }                                                                \
                                                                     \
    else {                                                           \
        int *dp1, *dp2;                                              \
        for (indexend = index1+ndim1*N; index1<indexend; ) {         \
            for (dp1=d1, i1=d01; dp1 < dend1; )                      \
                i1 += *index1++ * *dp1++;                            \
            for (dp2=d2, i2=d02; dp2 < dend2; )                      \
                i2 += *index2++ * *dp2++;                            \
            if (i1 >= nel1 || i1 < 0) return 5;                      \
            if (i2 >= nel2 || i2 < 0) return 5;                      \
            arr1 = arrbase1 + i1;                                    \
            arr2 = arrbase2 + i2;                                    \
            { OP }                                                   \
        }                                                            \
    }                                                                \
    return 0;                                                        \
}                                                                    \

#define PROC2S(N1, N2, TYPE, OP, ARGS...)                            \
            PROC2N(N1, N2, TYPE, TYPE, OP, ARGS)                     \
            PROC2M(N1, N2, TYPE, TYPE, OP, ARGS)                     \
            PROC2I(N1, N2, TYPE, TYPE, OP, ARGS)                     \

#define PROC2(N1, N2, TYPE1, TYPE2, OP, ARGS...)                     \
            PROC2N(N1, N2, TYPE1, TYPE2, OP, ARGS)                   \
            PROC2M(N1, N2, TYPE1, TYPE2, OP, ARGS)                   \
            PROC2I(N1, N2, TYPE1, TYPE2, OP, ARGS)                   \


#define PROC3N(N1, N2, TYPE1, TYPE2, TYPE3, OP, ARGS...) /* 3 arrays */ \
int N1 ## A ## N2(ARGS TYPE1 *arr1, int *spec1,                      \
        TYPE2 *arr2, int *spec2, TYPE3 *arr3, int *spec3)            \
{                                                                    \
    int err, off1, d1, nd1, off2, d2, nd2, off3, d3, nd3,            \
        *wk1, *wp1, *sps1, *sp1,                                     \
        *wk2, *wp2, *sps2, *sp2,                                     \
        *wk3, *wp3, *sps3, *sp3;                                     \
    TYPE1 *arrend;                                                   \
                                                                     \
    if (                                                             \
        (err = arrspec(spec1,0,1, &off1, &d1, &nd1, &sps1, &wk1))    \
    ||  (err = arrspec(spec2,0,1, &off2, &d2, &nd2, &sps2, &wk2))    \
    ||  (err = arrscan_check(spec1, spec2))                          \
    ||  (err = arrspec(spec3,0,1, &off3, &d3, &nd3, &sps3, &wk3))    \
    ||  (err = arrscan_check(spec1, spec3))                          \
        ) return err;                                                \
    arr1 += off1; arr2 += off2; arr3 += off3;                        \
                                                                     \
    while (1) {                                                      \
        for (arrend = arr1+nd1;                                      \
             arr1 < arrend;                                          \
             arr1 += d1, arr2 += d2, arr3 += d3)                     \
            { OP }                                                   \
        for (sp1=sps1, sp2=sps2, sp3=sps3, wp1=wk1; ; ) {            \
            if (sp1 == wk1) return 0;                                \
            arr1 += *sp1++;     arr2 += *sp2++;     arr3 += *sp3++;  \
            if (sp2++, sp3++, ++(*wp1) == *sp1++)                    \
                *wp1++ = 0;                                          \
            else                                                     \
                break;                                               \
        }                                                            \
    }                                                                \
}                                                                    \

#define PROC3M(N1, N2, TYPE1, TYPE2, TYPE3, OP, ARGS...)             \
int N1 ## AM ## N2(ARGS int *mask, int *specm, TYPE1 *arr1, int *spec1, \
        TYPE2 *arr2, int *spec2, TYPE3 *arr3, int *spec3)            \
{                                                                    \
    int err, off1, d1, nd1, off2, d2, nd2, off3, d3, nd3, offm, dm, ndm, \
        *wk1, *wp1, *sps1, *sp1,                                     \
        *wk2, *wp2, *sps2, *sp2,                                     \
        *wk3, *wp3, *sps3, *sp3,                                     \
        *wkm, *wpm, *spsm, *spm;                                     \
    TYPE1 *arrend;                                                   \
                                                                     \
    if (                                                             \
        (err = arrspec(spec1,0,1, &off1, &d1, &nd1, &sps1, &wk1))    \
    ||  (err = arrspec(spec2,0,1, &off2, &d2, &nd2, &sps2, &wk2))    \
    ||  (err = arrscan_check(spec1, spec2))                          \
    ||  (err = arrspec(spec3,0,1, &off3, &d3, &nd3, &sps3, &wk3))    \
    ||  (err = arrscan_check(spec1, spec3))                          \
    ||  (err = arrspec(specm,0,1, &offm, &dm, &ndm, &spsm, &wkm))    \
    ||  (err = arrscan_check(spec1, specm))                          \
        ) return err;                                                \
    arr1 += off1; arr2 += off2; arr3 += off3; mask += offm;          \
                                                                     \
    while (1) {                                                      \
        for (arrend = arr1+nd1;                                      \
             arr1 < arrend;                                          \
             arr1 += d1, arr2 += d2, arr3 += d3, mask += dm)         \
            if (*mask) { OP }                                        \
        for (sp1=sps1, sp2=sps2, sp3=sps3, spm = spsm, wp1=wk1; ; ) { \
            if (sp1 == wk1) return 0;                                \
            arr1 += *sp1++; arr2 += *sp2++; arr3 += *sp3++;          \
                                                mask += *spm++;      \
            if (sp2++, sp3++, spm++, ++(*wp1) == *sp1++)             \
                *wp1++ = 0;                                          \
            else                                                     \
                break;                                               \
        }                                                            \
    }                                                                \
}                                                                    \

#define PROC3I(N1, N2, TYPE1, TYPE2, TYPE3, OP, ARGS...)             \
int N1 ## AI ## N2(ARGS int N,                                       \
        TYPE1 *arrbase1, int *spec1, int *index1,                    \
        TYPE2 *arrbase2, int *spec2, int *index2,                    \
        TYPE3 *arrbase3, int *spec3, int *index3)                    \
{                                                                    \
    int err, nel1, d01, *d1, *dend1,                                 \
        nel2, d02, *d2, *dend2,                                      \
        nel3, d03, *d3, *dend3;                                      \
    int ndim1, ndim2, ndim3, *indexend, i1, i2, i3;                  \
    TYPE1 *arr1;                                                     \
    TYPE2 *arr2;                                                     \
    TYPE3 *arr3;                                                     \
                                                                     \
    if (                                                             \
        (err = arrind(spec1, &nel1, &d01, &d1, &dend1))              \
    ||  (err = arrind(spec2, &nel2, &d02, &d2, &dend2))              \
    ||  (err = arrind(spec3, &nel3, &d03, &d3, &dend3))              \
        ) return err;                                                \
    ndim1 = dend1 - d1;                                              \
    ndim2 = dend2 - d2;                                              \
    ndim3 = dend3 - d3;                                              \
                                                                     \
    if (ndim1 == 1 && ndim2 == 1 && ndim3 == 1)                      \
        for (indexend = index1+N; index1<indexend; ) {               \
            if ((i1 = *index1++ + d01) >= nel1 || i1 < 0) return 5;  \
            if ((i2 = *index2++ + d02) >= nel2 || i2 < 0) return 5;  \
            if ((i3 = *index3++ + d03) >= nel3 || i3 < 0) return 5;  \
            arr1 = arrbase1 + i1;                                    \
            arr2 = arrbase2 + i2;                                    \
            arr3 = arrbase3 + i3;                                    \
            { OP }                                                   \
        }                                                            \
                                                                     \
    else if (ndim1 == 2 && ndim2 == 2 && ndim3 == 2) {               \
        int d11 = *d1, d21 = *(d1+1), x1, y1,                        \
            d12 = *d2, d22 = *(d2+1), x2, y2,                        \
            d13 = *d3, d23 = *(d3+1), x3, y3;                        \
        for (indexend = index1+2*N; index1<indexend; ) {             \
            x1 = *index1++; y1 = *index1++;                          \
            x2 = *index2++; y2 = *index2++;                          \
            x3 = *index3++; y3 = *index3++;                          \
            if ((i1 = d01 + d11*x1 + d21*y1) >= nel1 || i1 < 0)      \
                return 5;                                            \
            if ((i2 = d02 + d12*x2 + d22*y2) >= nel2 || i2 < 0)      \
                return 5;                                            \
            if ((i3 = d03 + d13*x3 + d23*y3) >= nel3 || i3 < 0)      \
                return 5;                                            \
            arr1 = arrbase1 + i1;                                    \
            arr2 = arrbase2 + i2;                                    \
            arr3 = arrbase3 + i3;                                    \
            { OP }                                                   \
        }                                                            \
    }                                                                \
                                                                     \
    else {                                                           \
        int *dp1, *dp2, *dp3;                                        \
        for (indexend = index1+ndim1*N; index1<indexend; ) {         \
            for (dp1=d1, i1=d01; dp1 < dend1; )                      \
                i1 += *index1++ * *dp1++;                            \
            for (dp2=d2, i2=d02; dp2 < dend2; )                      \
                i2 += *index2++ * *dp2++;                            \
            for (dp3=d3, i3=d03; dp3 < dend3; )                      \
                i3 += *index3++ * *dp3++;                            \
            if (i1 >= nel1 || i1 < 0) return 5;                      \
            if (i2 >= nel2 || i2 < 0) return 5;                      \
            if (i3 >= nel3 || i3 < 0) return 5;                      \
            arr1 = arrbase1 + i1;                                    \
            arr2 = arrbase2 + i2;                                    \
            arr3 = arrbase3 + i3;                                    \
            { OP }                                                   \
        }                                                            \
    }                                                                \
    return 0;                                                        \
}                                                                    \

#define PROC3S(N1, N2, TYPE, OP, ARGS...)                            \
            PROC3N(N1, N2, TYPE, TYPE, TYPE, OP, ARGS)               \
            PROC3M(N1, N2, TYPE, TYPE, TYPE, OP, ARGS)               \
            PROC3I(N1, N2, TYPE, TYPE, TYPE, OP, ARGS)               \

#define PROC3(N1, N2, TYPE1, TYPE2, TYPE3, OP, ARGS...)              \
            PROC3N(N1, N2, TYPE1, TYPE2, TYPE3, OP, ARGS)            \
            PROC3M(N1, N2, TYPE1, TYPE2, TYPE3, OP, ARGS)            \
            PROC3I(N1, N2, TYPE1, TYPE2, TYPE3, OP, ARGS)            \


#define PROCR(NAME, TYPE) /* Reshape */                              \
int NAME(TYPE *arr1, int *spec1, TYPE *arr2, int *spec2)             \
{                                                                    \
    int err, ntodo, i, off1, d1, nd1, n1, n1s, off2, d2, nd2, n2, n2s, \
        *wk1, *wp1, *sps1, *sp1,                                     \
        *wk2, *wp2, *sps2, *sp2;                                     \
    TYPE *arrend;                                                    \
                                                                     \
    if (                                                             \
        (err = arrspec(spec1,1,0, &off1, &d1, &nd1, &sps1, &wk1))    \
    ||  (err = arrspec(spec2,1,0, &off2, &d2, &nd2, &sps2, &wk2))    \
    ||  (err = arrscan_check_total(spec1, spec2))                    \
        ) return err;                                                \
    arr1 += off1;               arr2 += off2;                        \
    n1 = n1s = nd1 / d1;        n2 = n2s = nd2 / d2;                 \
                                                                     \
    while (1) {                                                      \
        ntodo = n1<n2 ? n1 : n2;                                     \
        for (i=0; i<ntodo; i++, arr1+=d1, arr2+=d2) *arr2 = *arr1;   \
        n1 -= ntodo;                                                 \
        n2 -= ntodo;                                                 \
                                                                     \
        if (n1 == 0) {                                               \
            for (sp1=sps1, wp1=wk1; ; ) {                            \
                if (sp1 == wk1) return 0;                            \
                arr1 += *sp1++;                                      \
                if (++(*wp1) == *sp1++)                              \
                    *wp1++ = 0;                                      \
                else                                                 \
                    break;                                           \
            }                                                        \
            n1 = n1s;                                                \
        }                                                            \
        if (n2 == 0) {                                               \
            for (sp2=sps2, wp2=wk2; ; ) {                            \
                arr2 += *sp2++;                                      \
                if (++(*wp2) == *sp2++)                              \
                    *wp2++ = 0;                                      \
                else                                                 \
                    break;                                           \
            }                                                        \
            n2 = n2s;                                                \
        }                                                            \
    }                                                                \
}                                                                    \


#define PROCIN(N1, N2, TYPE) /* Set to dim'th index */               \
int N1 ## A ## N2(int dim, TYPE *arr, int *spec)                     \
{                                                                    \
    int err, i, istart, iinc, cdim, off, d, nd;                      \
    int *wk, *wp, *sps, *sp;                                         \
    TYPE *arrend;                                                    \
                                                                     \
    if (err = arrscan_dimpars1(dim, spec, &istart, &iinc))           \
        return err;                                                  \
    if (err = arrspec(spec, 0, 0, &off, &d, &nd, &sps, &wk))         \
        return err;                                                  \
    arr += off;                                                      \
                                                                     \
    if (dim == 1)                                                    \
        while (1) {                                                  \
            for (i = istart, arrend = arr+nd;                        \
                 arr < arrend;                                       \
                 i += iinc, arr += d)                                \
                *arr = i;                                            \
            for (sp=sps, wp=wk; ; ) {   /* loop over dims 2...N */   \
                if (sp == wk) return 0;                              \
                arr += *sp++;                                        \
                if (++(*wp) == *sp++)                                \
                    *wp++ = 0;                                       \
                else                                                 \
                    break;                                           \
            }                                                        \
        }                                                            \
    else {                                                           \
        i = istart;                                                  \
        while (1) {                                                  \
            for (arrend = arr+nd; arr < arrend; arr += d)            \
                *arr = i;                                            \
            for (cdim=2, sp=sps, wp=wk; ; cdim++) {                  \
                if (sp == wk) return 0;                              \
                arr += *sp++;                                        \
                if (cdim == dim) i += iinc;                          \
                if (++(*wp) == *sp++) {                              \
                    *wp++ = 0;                                       \
                    i = istart;                                      \
                }                                                    \
                else                                                 \
                    break;                                           \
            }                                                        \
        }                                                            \
    }                                                                \
}                                                                    \

#define PROCIM(N1, N2, TYPE) /* Set to dim'th index */               \
int N1 ## AM ## N2(                                                  \
        int dim, int *mask, int *specm, TYPE *arr, int *spec)        \
{                                                                    \
    int err, i, istart, iinc, cdim, off, d, nd, offm, dm, ndm,       \
        *wk, *wp, *sps, *sp,                                         \
        *wkm, *wpm, *spsm, *spm;                                     \
    TYPE *arrend;                                                    \
                                                                     \
    if (err = arrscan_dimpars1(dim, spec, &istart, &iinc))           \
        return err;                                                  \
    if (                                                             \
        (err = arrspec(spec,  0, 0, &off,  &d,  &nd,  &sps,  &wk))   \
    ||  (err = arrspec(specm, 0, 0, &offm, &dm, &ndm, &spsm, &wkm))  \
    ||  (err = arrscan_check(spec, specm))                           \
        ) return err;                                                \
    arr += off; mask += offm;                                        \
                                                                     \
    if (dim == 1)                                                    \
        while (1) {                                                  \
            for (i = istart, arrend = arr+nd;                        \
                 arr < arrend;                                       \
                 i += iinc, arr += d, mask += dm)                    \
                if (*mask) *arr = i;                                 \
            for (sp=sps, spm=spsm, wp=wk; ; ) {                      \
                if (sp == wk) return 0;                              \
                arr += *sp++;   mask += *spm++;                      \
                if (spm++, ++(*wp) == *sp++)                         \
                    *wp++ = 0;                                       \
                else                                                 \
                    break;                                           \
            }                                                        \
        }                                                            \
    else {                                                           \
        i = istart;                                                  \
        while (1) {                                                  \
            for (arrend = arr+nd; arr < arrend; arr += d, mask += dm) \
                if (*mask) *arr = i;                                 \
            for (cdim=2, sp=sps, spm=spsm, wp=wk; ; cdim++) {        \
                if (sp == wk) return 0;                              \
                arr += *sp++;   mask += *spm++;                      \
                if (cdim == dim) i += iinc;                          \
                if (spm++, ++(*wp) == *sp++) {                       \
                    *wp++ = 0;                                       \
                    i = istart;                                      \
                }                                                    \
                else                                                 \
                    break;                                           \
            }                                                        \
        }                                                            \
    }                                                                \
}                                                                    \

#define PROCI(N1, N2, TYPE)                                          \
            PROCIN(N1, N2, TYPE)                                     \
            PROCIM(N1, N2, TYPE)                                     \


#define PROCFN(N1, N2, TYPE) /* Find indices of non-zero elements */ \
int N1 ## A ## N2(                                                   \
        TYPE *arr, int *spec, int *wkarr, int *noutp, int *res)      \
{                                                                    \
    int err, i, ist1, iinc1, off, d, nd, iout = 0, nout = *noutp;    \
    int *wk, *wp, *sps, *sp,                                         \
        *istarts, *iincs, *istart, *iinc, *iend;                     \
    TYPE *arrend;                                                    \
                                                                     \
    iend = iincs = (istarts=wkarr) + *(spec+1);                      \
    if (err = arrscan_dimpars(spec, istarts, iincs)) return err;     \
    if (err = arrspec(spec, 0, 0, &off, &d, &nd, &sps, &wk))         \
        return err;                                                  \
    arr += off;                                                      \
    ist1 = *istarts++;                                               \
    iinc1 = *iincs++;                                                \
                                                                     \
    while (1) {                                                      \
        for (i = ist1, arrend = arr+nd;                              \
             arr < arrend;                                           \
             i += iinc1, arr += d)                                   \
            if (*arr != 0)   /* test covers complex case */          \
                if (iout++ < nout) {                                 \
                    *res++ = i;                                      \
                    for (istart=istarts, iinc=iincs, wp = wk;        \
                         istart < iend; )                            \
                        *res++ = *istart++ + *wp++ * *iinc++;        \
                }                                                    \
        for (sp=sps, wp=wk; ; ) {                                    \
            if (sp == wk) goto Return;                               \
            arr += *sp++;                                            \
            if (++(*wp) == *sp++)                                    \
                *wp++ = 0;                                           \
            else                                                     \
                break;                                               \
        }                                                            \
    }                                                                \
                                                                     \
Return:                                                              \
    *noutp = iout;                                                   \
    return 0;                                                        \
}                                                                    \

#define PROCFM(N1, N2, TYPE) /* Find indices of non-zero elements */ \
int N1 ## AM ## N2(int *mask, int *specm,                            \
        TYPE *arr, int *spec, int *wkarr, int *noutp, int *res)      \
{                                                                    \
    int err, i, ist1, iinc1, off, d, nd, offm, dm, ndm,              \
        iout = 0, nout = *noutp;                                     \
    int *wk, *wp, *sps, *sp,                                         \
        *wkm, wpm, *spsm, *spm,                                      \
        *istarts, *iincs, *istart, *iinc, *iend;                     \
    TYPE *arrend;                                                    \
                                                                     \
    iend = iincs = (istarts=wkarr) + *(spec+1);                      \
    if (err = arrscan_dimpars(spec, istarts, iincs)) return err;     \
    if (                                                             \
        (err = arrspec(spec, 0,0, &off,  &d,  &nd,  &sps,  &wk))     \
    ||  (err = arrspec(specm,0,0, &offm, &dm, &ndm, &spsm, &wkm))    \
    ||  (err = arrscan_check(spec, specm))                           \
        ) return err;                                                \
    arr += off; mask += offm;                                        \
    ist1 = *istarts++;                                               \
    iinc1 = *iincs++;                                                \
                                                                     \
    while (1) {                                                      \
        for (i = ist1, arrend = arr+nd;                              \
             arr < arrend;                                           \
             i += iinc1, arr += d, mask += dm)                       \
            if (*mask && *arr != 0)   /* test covers complex case */ \
                if (iout++ < nout) {                                 \
                    *res++ = i;                                      \
                    for (istart=istarts, iinc=iincs, wp = wk;        \
                         istart < iend; )                            \
                        *res++ = *istart++ + *wp++ * *iinc++;        \
                }                                                    \
        for (sp=sps, spm=spsm, wp=wk; ; ) {                          \
            if (sp == wk) goto Return;                               \
            arr += *sp++;   mask += *spm++;                          \
            if (++(*wp) == *sp++)                                    \
                *wp++ = 0;                                           \
            else                                                     \
                break;                                               \
        }                                                            \
    }                                                                \
                                                                     \
Return:                                                              \
    *noutp = iout;                                                   \
    return 0;                                                        \
}                                                                    \

#define PROCF(N1, N2, TYPE)                                          \
            PROCFN(N1, N2, TYPE)                                     \
            PROCFM(N1, N2, TYPE)                                     \


/* --- Revision History ---------------------------------------------------
--- David Young, Apr  1 2004
        Added indexed and find PROCI and PROCF functions.
 */
