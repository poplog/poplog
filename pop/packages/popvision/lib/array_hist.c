/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 * File:            $popvision/lib/array_hist.c
 * Purpose:         External routines for histograms
 * Author:          David S Young, Jan 27 1994
 * Documentation:   HELP * ARRAY_HIST
 * Related Files:   LIB * ARRAY_HIST, LIB * EXT2D_ARGS
 */


/* Procedures for calculating histograms.

See LIB * EXT2D_ARGS for first 5 arguments, and LIB * ARRAY_HIST for
rest.

These routines don't reset the histogram or the below-above totals,
so they can be used for repeated calls on different parts of the same
array.

*/

#include <math.h>

/*
-- Macro definitions --------------------------------------------------
*/

#define LOOP_2D(TYPEI)                                          \
                                                                \
    TYPEI               *aisl, *aislmx, *aifst, *aifstmx;       \
                                                                \
    for (aisl       =   avi + starti,                           \
         aislmx     =   aisl + yreg * jumpi;                    \
                                                                \
         aisl       <   aislmx;                                 \
                                                                \
         aisl       +=  jumpi)                                  \
                                                                \
        for (aifst      =   aisl,                               \
             aifstmx    =   aifst + xreg;                       \
                                                                \
             aifst      <   aifstmx;                            \
                                                                \
             aifst++)                                           \

/* Get and declare the arguments with macros too */

#define ARGS xreg, yreg, avi, starti, jumpi

#define DECARGS(TYPEI)                                          \
    TYPEI               *avi;                                   \
    int                 xreg, yreg, starti, jumpi;              \

/*
-- Procedures ---------------------------------------------------------
*/

void array_hist_f(ARGS, lo, hi, hist, startindex, nbins, bloabv)

    DECARGS (float)
    float       lo, hi;
    int         *hist, startindex, nbins, *bloabv;

{
    float       binsizeinv = nbins / (hi - lo);
    int         ibin,
                endindex = startindex + nbins - 1,
                nblo = 0,
                nabv = 0;
    LOOP_2D (float) {
            /* Float case needs arithmetic before comparison,
            so that rounding errors can't generate illegal indices */
            ibin = startindex + (int) floor(binsizeinv * (*aifst - lo));
            if (ibin < startindex) nblo++;
            else if (ibin > endindex) nabv++;
            else (*(hist + ibin))++;
        }
    *bloabv++ += nblo;
    *bloabv += nabv;
}

void array_hist_b(ARGS, lo, hi, hist, startindex, nbins, bloabv)

    DECARGS (unsigned char)
    int         lo, hi, *hist, startindex, nbins, *bloabv;

{
    int         *histstart = hist + startindex,
                nblo = 0,
                nabv = 0,
                val,
                range = hi - lo;
    LOOP_2D (unsigned char) {
            /* Int case needs comparison before arithmetic, so that
            rounding towards zero on integer division won't give
            wrong answer for values just below lo. */
            if ((val = *aifst) < lo) nblo++;
            else if (val >= hi) nabv++;
            else (*(histstart + ((val-lo) * nbins) / range))++;
        }
    *bloabv++ += nblo;
    *bloabv += nabv;
}
