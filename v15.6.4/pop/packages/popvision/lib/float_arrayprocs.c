/* --- Copyright University of Sussex 2003. All rights reserved. ----------
 * File:            $popvision/lib/float_arrayprocs.c
 * Purpose:         Miscellaneous operations on floating point arrays
 * Author:          David Young, Nov 12 1992 (see revisions)
 * Documentation:   HELP *FLOAT_ARRAYPROCS
 * Related Files:   LIB *FLOAT_ARRAYPROCS
 */

/* Some small array procedures for float arrays */

#include <math.h>

void bytearray2float(arr1, arr3, n)
    unsigned char *arr1;
    float   *arr3;
    int n;
{
    float   *arr3end;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr3++)
            *arr3 = *arr1;
}

void float_arraydiff(arr1, arr2, arr3, n)
    float   *arr1, *arr2, *arr3;
    int n;
{
    float   *arr3end;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr2++,   arr3++)
            *arr3 = *arr1 - *arr2;
}

void float_arraysum(arr1, arr2, arr3, n)
    float   *arr1, *arr2, *arr3;
    int n;
{
    float   *arr3end;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr2++,   arr3++)
            *arr3 = *arr1 + *arr2;
}

void float_arraymult(arr1, arr2, arr3, n)
    float   *arr1, *arr2, *arr3;
    int n;
{
    float   *arr3end;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr2++,   arr3++)
            *arr3 = *arr1 * *arr2;
}

void float_complexmult(arr1r, arr1i, arr2r, arr2i, arr3r, arr3i, n)
    float   *arr1r, *arr1i, *arr2r, *arr2i, *arr3r, *arr3i;
    int n;
{
    float   *arr3end, t;

    for (arr3end = arr3r + n;
         arr3r < arr3end;
         arr1r++,  arr1i++, arr2r++, arr2i++,   arr3r++, arr3i++) {
            t      = *arr1r * *arr2r - *arr1i * *arr2i;
            *arr3i = *arr1r * *arr2i + *arr1i * *arr2r;
            *arr3r = t;
    }
}

void float_arraydiv(arr1, arr2, arr3, n)
    float   *arr1, *arr2, *arr3;
    int n;
{
    float   *arr3end;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr2++,   arr3++)
            *arr3 = *arr1 / *arr2;
}

void float_arraycomb(k1, arr1, k2, arr2, arr3, n)
    float   k1, *arr1, k2, *arr2, *arr3;
    int n;
{
    float   *arr3end;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr2++,   arr3++)
            *arr3 = k1 * *arr1 + k2 * *arr2;
}

void float_arraythreshold(v1, thresh, v2, usedata, arr1, arr3, n)
    float   v1, thresh, v2, *arr1, *arr3;
    int usedata, n;
{
    float   *arr3end, a;

    if (usedata > 0)
        for (arr3end = arr3 + n;
             arr3 < arr3end;
             arr1++,   arr3++)
                *arr3 = ((a = *arr1) >= thresh) ? a : v1;
    else if (usedata < 0)
        for (arr3end = arr3 + n;
             arr3 < arr3end;
             arr1++,   arr3++)
                *arr3 = ((a = *arr1) >= thresh) ? v2 : a;
    else
        for (arr3end = arr3 + n;
             arr3 < arr3end;
             arr1++,   arr3++)
                *arr3 = ((a = *arr1) >= thresh) ? v2 : v1;
}

void float_arraythreshold2(
    v1, thresh1, v2, thresh2, v3, usedata, arr1, arr3, n)
    float   v1, thresh1, v2, thresh2, v3, *arr1, *arr3;
    int usedata, n;
{
    float   *arr3end, a;
    int     use1 = usedata & 01,
            use2 = usedata & 02,
            use3 = usedata & 04;

    if (usedata)    /* Need to use original data */
        for (arr3end = arr3 + n;
             arr3 < arr3end;
             arr1++,   arr3++) {
                a = *arr1;
                if (a >= thresh2)
                    *arr3 = use3 ? a : v3;
                else if (a <= thresh1)
                    *arr3 = use1 ? a : v1;
                else
                    *arr3 = use2 ? a : v2;
                }
    else            /* Use values given - no need for tests */
        for (arr3end = arr3 + n;
             arr3 < arr3end;
             arr1++,   arr3++) {
                if (*arr1 >= thresh2)
                    *arr3 = v3;
                else if (*arr1 <= thresh1)
                    *arr3 = v1;
                else
                    *arr3 = v2;
                }
}

void float_arrayabs(arr1, arr3, n)
    float   *arr1, *arr3;
    int n;
{
    float   *arr3end;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr3++)
            if (*arr1 < 0.0)
                *arr3 = -(*arr1);
            else
                *arr3 = *arr1;
}

void float_arraysqr(arr1, arr3, n)
    float   *arr1, *arr3;
    int n;
{
    float   *arr3end;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr3++)
        *arr3 = *arr1 * *arr1;
}

void float_arraysqrt(arr1, arr3, n)
    float   *arr1, *arr3;
    int n;
{
    float   *arr3end;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr3++)
        *arr3 = sqrt(*arr1);
}

void float_arraylogistic(arr1, arr3, n)
    float   *arr1, *arr3;
    int n;
{
    float   *arr3end;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr3++)
        *arr3 = 1.0 / (1.0 + exp(-*arr1));
}

float float_arraymean(arr1, n)
    float   *arr1;
    int n;
{
    float   sum = 0.0, *arr1end;

    for (arr1end = arr1 + n;
         arr1 < arr1end;
         arr1++)
            sum += *arr1;
    return(sum / n);
}

float float_arraymean_mask(wherezero, arr1, arr2, n)
    float   *arr1, *arr2;
    int n, wherezero;
{
    float   sum = 0.0, *arr1end;
    int     num = 0;

    if (wherezero) {
        for (arr1end = arr1 + n;
             arr1 < arr1end;
             arr1++,  arr2++)
                if (*arr2 == 0.0) {
                    sum += *arr1;
                    num++; }
        }
    else
        for (arr1end = arr1 + n;
             arr1 < arr1end;
             arr1++,  arr2++)
                if (*arr2 != 0.0) {
                    sum += *arr1;
                    num++; }
    if (num > 0)
        return(sum / num);
    else
        return(0.0);
}

void float_arrayhist(arr, n, mn, mx, hist, nbins)
    float   *arr;
    int     n;
    float   mn, mx;
    int     *hist;
    int     nbins;
{
    float   *arrend,
            binsizeinv = nbins / (mx - mn);
    int     ibin;

    for (arrend = arr + n;
         arr < arrend;
         arr++) {
        ibin = floor(binsizeinv * (*arr - mn));
        if (ibin >= 0 && ibin < nbins) {
            (*(hist+ibin))++ ; }
        }
}

void float_arraymultc(c, arr1, arr3, n)
    float   c, *arr1, *arr3;
    int n;
{
    float   *arr3end;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr3++)
            *arr3 = *arr1 * c;
}

void float_arraysetc(c, arr1, n)
    float   c, *arr1;
    int n;
{
    float   *arr1end;

    for (arr1end = arr1 + n;
         arr1 < arr1end;
         arr1++)
            *arr1 = c;
}

void float_arrayaddc(c, arr1, arr3, n)
    float   c, *arr1, *arr3;
    int n;
{
    float   *arr3end;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr3++)
            *arr3 = *arr1 + c;
}

void float_arrayaddc_mask(c, wherezero, arr1, arr2, arr3, n)
    float   c, *arr1, *arr2, *arr3;
    int n, wherezero;
{
    float   *arr3end;

    if (wherezero) {
        for (arr3end = arr3 + n;
             arr3 < arr3end;
             arr1++,  arr2++,  arr3++)
                if (*arr2 == 0.0)
                    *arr3 = *arr1 + c;
        }
    else
        for (arr3end = arr3 + n;
             arr3 < arr3end;
             arr1++,  arr2++,  arr3++)
                if (*arr2 != 0.0)
                    *arr3 = *arr1 + c;
}

void float_arraymultc_mask(c, wherezero, arr1, arr2, arr3, n)
    float   c, *arr1, *arr2, *arr3;
    int n, wherezero;
{
    float   *arr3end;

    if (wherezero) {
        for (arr3end = arr3 + n;
             arr3 < arr3end;
             arr1++,  arr2++,  arr3++)
                if (*arr2 == 0.0)
                    *arr3 = *arr1 * c;
        }
    else
        for (arr3end = arr3 + n;
             arr3 < arr3end;
             arr1++,  arr2++,  arr3++)
                if (*arr2 != 0.0)
                    *arr3 = *arr1 * c;
}

void float_arraymeansd(arr1, n, mean, sd)
    float   *arr1, *mean, *sd;
    int n;
{
    double   s = 0.0, ss = 0.0;
    float    *arr1end;

    for (arr1end = arr1 + n;
         arr1 < arr1end;
         arr1++) {
            s += *arr1;
            ss += *arr1 * *arr1; }

    if (n > 0) {
        *mean = s / n;
        *sd = sqrt(ss / n - *mean * *mean); }
    else {
        *mean = 0.0;
        *sd = 0.0; }
}

void float_arraymeansd_mask(wherezero, arr1, arr2, n, mean, sd)
    float *arr1, *arr2, *mean, *sd;
    int wherezero, n;
{
    double   s = 0.0, ss = 0.0;
    float    *arr1end;
    int      num = 0;

    if (wherezero) {
        for (arr1end = arr1 + n;
             arr1 < arr1end;
             arr1++, arr2++)
                if (*arr2 == 0.0) {
                    num++;
                    s += *arr1;
                    ss += *arr1 * *arr1; }
        }
    else
        for (arr1end = arr1 + n;
             arr1 < arr1end;
             arr1++, arr2++)
                if (*arr2 != 0.0) {
                    num++;
                    s += *arr1;
                    ss += *arr1 * *arr1; }

    if (num > 0) {
        *mean = s / num;
        *sd = sqrt(ss / num - *mean * *mean); }
    else {
        *mean = 0.0;
        *sd = 0.0; }
}

void float_arraywtdav_mask(alpha1, alpha2, arr1, arr2, mask, arr3, n)
    float   alpha1, alpha2, *arr1, *arr2, *mask, *arr3;
    int n;
{
    float   *arr3end, beta1 = 1.0-alpha1, beta2 = 1.0-alpha2;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr2++,  mask++, arr3++)
            if (*mask == 0.0)
                *arr3 = alpha1 * *arr1 + beta1 * *arr2;
            else
                *arr3 = alpha2 * *arr1 + beta2 * *arr2;
}

void float_arraydilate(v, arr1, arr2, x1, y1)
    int x1, y1;     /* arrays are [1 x1 1 y1] */
    float v, *arr1, *arr2;
{
    float *arr1y, *arr2y, *arr1x, *arr2x,
          *arr1yend, *arr1xend;
    int z1, z2, z3;

    for (arr1yend = arr1 + (x1 * (y1-2)),
         arr1y = arr1 + x1,
         arr2y = arr2 + x1;

         arr1y <= arr1yend;       /* not < as in routines above */

         arr1y += x1,    arr2y += x1) {

        z1 = *arr1y == 0.0 && *(arr1y-x1) == 0.0 && *(arr1y+x1) == 0.0;
        arr1x = arr1y + 1;
        z2 = *arr1x == 0.0 && *(arr1x-x1) == 0.0 && *(arr1x+x1) == 0.0;

        for (arr1xend = arr1y + (x1-1),
             arr1x = arr1y + 2,
             arr2x = arr2y + 1;

             arr1x <= arr1xend;

             arr1x++,  arr2x++) {
                z3 = *arr1x == 0.0 && *(arr1x-x1) == 0.0
                    && *(arr1x+x1) == 0.0;
                if (z1 && z2 && z3)
                    *arr2x = 0.0;
                else
                    *arr2x = v;
                z1 = z2;      z2 = z3;
            }
        }
}

void float_arrayerode(v, arr1, arr2, x1, y1)
    int x1, y1;     /* arrays are [1 x1 1 y1] */
    float v, *arr1, *arr2;
{
    float *arr1y, *arr2y, *arr1x, *arr2x,
          *arr1yend, *arr1xend;
    int z1, z2, z3;

    for (arr1yend = arr1 + (x1 * (y1-2)),
         arr1y = arr1 + x1,
         arr2y = arr2 + x1;

         arr1y <= arr1yend;       /* not < as in routines above */

         arr1y += x1,    arr2y += x1) {

        z1 = *arr1y != 0.0 && *(arr1y-x1) != 0.0 && *(arr1y+x1) != 0.0;
        arr1x = arr1y + 1;
        z2 = *arr1x != 0.0 && *(arr1x-x1) != 0.0 && *(arr1x+x1) != 0.0;

        for (arr1xend = arr1y + (x1-1),
             arr1x = arr1y + 2,
             arr2x = arr2y + 1;

             arr1x <= arr1xend;

             arr1x++,  arr2x++) {
                z3 = *arr1x != 0.0 && *(arr1x-x1) != 0.0
                    && *(arr1x+x1) != 0.0;
                if (z1 && z2 && z3)
                    *arr2x = v;
                else
                    *arr2x = 0.0;
                z1 = z2;      z2 = z3;
            }
        }
}

void floatarray2byte(amin, amax, arr1, imin, imax, arr3, n)
    float   amin, amax, *arr1;
    int imin, imax;
    unsigned char *arr3;
    int n;
{
    unsigned char *arr3end;
    float          m = (imax - imin) / (amax - amin);
    int            i;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr3++) {
            i = (int) ((*arr1 - amin) * m + 0.5) + imin;
            if (i < imin)
                *arr3 = imin;
            else if (i > imax)
                *arr3 = imax;
            else
                *arr3 = i;
        }
}

void float_arrayhypot(arr1, arr2, arr3, n)
    float   *arr1, *arr2, *arr3;
    int n;
{
    float   *arr3end;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr2++,  arr3++)
            *arr3 = hypot(*arr1, *arr2);
}

void float_arrayatan2(arr1, arr2, arr3, n)
    float   *arr1, *arr2, *arr3;
    int n;
{
    float   *arr3end;

    for (arr3end = arr3 + n;
         arr3 < arr3end;
         arr1++,  arr2++,  arr3++)
            *arr3 = atan2(*arr1, *arr2);
}

/* --- Revision History ---------------------------------------------------
--- David Young, Oct  8 2003
        Added -float_arraysqrt-
--- David Young, Oct  5 2001
        Added -float_complexmult-
--- David Young, Feb 24 2000
        -float_arraylogistic- added
--- David S Young, Apr  8 1994
        -float_arraymult- and -float_arraydiv- added
--- David S Young, Nov 29 1993
        -float_arraythreshold2- now allows data to be retained
--- David S Young, Jul 22 1993
        Added -float_arraymultc_mask- and -float_arrayhist-
--- David S Young, Jan 30 1993
        Added -float_arraysqr- and -float_arraysetc-
 */
