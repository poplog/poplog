/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 * File:            $popvision/lib/arraylookup.c
 * Purpose:         C support for *ARRAYLOOKUP
 * Author:          David S Young, Jan 20 1994 (see revisions)
 * Documentation:   HELP * ARRAYLOOKUP
 * Related Files:   LIB * ARRAYLOOKUP
 */

/* Procedures to map rectangular 2-D regions of byte and float arrays
using lookup tables.

Procedures have standard names for first 8 arguments:

    xreg:       The size of the first dimension of the region
    yreg:       The size of the second dimension of the region
    avi:        The arrayvector of the input array
    starti:     The offset of the first element in the input array
    jumpi:      The increment between successive 1-D sections of
                    the region in the input array
    avo, starto, jumpo: Same as the last 3 for the output array.

Using standard names allows a  macro to be used for looping over the
regions in the two arrays.  In the body of the loop, two variables are
available:

    aifst:  A pointer to the current data in the input array
    aofst:  A pointer to the current data in the output array

         CONTENTS - (Use <ENTER> g to access required sections)

 -- Macro definitions
 -- Vector lookup for byte arrays
 -- Simple thresholding
 -- Linear quantisation
 -- Table quantisation

*/

/*
-- Macro definitions --------------------------------------------------
*/

#define LOOP_2D(TYPEI, TYPEO)                                   \
                                                                \
    TYPEI               *aisl, *aislmx, *aifst, *aifstmx;       \
    TYPEO               *aosl, *aofst;                          \
                                                                \
    for (aisl       =   avi + starti,                           \
         aosl       =   avo + starto,                           \
         aislmx     =   aisl + yreg * jumpi;                    \
                                                                \
         aisl       <   aislmx;                                 \
                                                                \
         aisl       +=  jumpi,                                  \
         aosl       +=  jumpo)                                  \
                                                                \
        for (aifst      =   aisl,                               \
             aofst      =   aosl,                               \
             aifstmx    =   aifst + xreg;                       \
                                                                \
             aifst      <   aifstmx;                            \
                                                                \
             aifst++,   aofst++)                                \

/* Get and declare the arguments with macros too */

#define ARGS xreg, yreg, avi, starti, jumpi, avo, starto, jumpo

#define DECARGS(TYPEI, TYPEO)                                   \
    TYPEI               *avi;                                   \
    TYPEO               *avo;                                   \
    int                 xreg, yreg, starti, jumpi, starto, jumpo;


/*
-- Vector lookup for byte arrays --------------------------------------
*/

void blookup(ARGS, lut)
/* Byte array to byte array, via byte lookup table of length 256. */
    DECARGS (unsigned char, unsigned char)
    unsigned char       *lut;
{
    LOOP_2D (unsigned char, unsigned char)
            *aofst  =   *(lut + *aifst);
}


/*
-- Simple thresholding ------------------------------------------------
*/

void ftlookupa(ARGS, t, f1, f2)
/* Float to float array, simple threshold */
    DECARGS (float, float)
    float               t, f1, f2;
{
    LOOP_2D (float, float)
            *aofst  =   *aifst < t ? f1 : f2;
}

void ftlookupb(ARGS, t, f1)
/* Float to float array, simple threshold, retain top */
    DECARGS (float, float)
    float               t, f1;
{
    LOOP_2D (float, float)
            *aofst  =   *aifst < t ? f1 : *aifst;
}

void ftlookupc(ARGS, t, f2)
/* Float to float array, simple threshold, retain bottom */
    DECARGS (float, float)
    float               t, f2;
{
    LOOP_2D (float, float)
            *aofst  =   *aifst < t ? *aifst : f2;
}

void fbtlookup(ARGS, t, f1, f2)
/* Float to byte array, simple threshold */
    DECARGS (float, unsigned char)
    float               t;
    int                 f1, f2;
{
    LOOP_2D (float, unsigned char)
            *aofst  =   *aifst < t ? f1 : f2;
}


/*
-- Linear quantisation ------------------------------------------------
*/

int linquant_f(v, Maxv, k, t1)
/* Linearly quantises v into range 0 .. Maxv */
    float   v, k, t1;
    int     Maxv;
{
    int     i;
    /* Must add 1 before taking int to avoid rounding problems */
    i = k * (v - t1) + 1.0;
    if      (i > Maxv)  i = Maxv;
    else if (i < 0)     i = 0;
    return i;
}


void fllookup(ARGS, fvals, Maxv, k, t1)
/* Float to float array, linear quantisation */
    DECARGS (float, float)
    float               *fvals, k, t1;
    int                 Maxv;
{
    LOOP_2D (float, float)
            *aofst  =   *(fvals + linquant_f(*aifst, Maxv, k, t1));
}


void fllookupu(ARGS, fvals, undefs, Maxv, k, t1)
/* Float to float array, linear quantisation */
    DECARGS (float, float)
    float               *fvals, *undefs, k, t1;
    int                 Maxv;
{
    int     i;
    LOOP_2D (float, float) {
            i = linquant_f(*aifst, Maxv, k, t1);
            *aofst  =   *(undefs+i) ? *aifst : *(fvals+i);
    }
}


void fbllookup(ARGS, bvals, Maxv, k, t1)
/* Float to byte array, linear quantisation */
    DECARGS (float, unsigned char)
    float               k, t1;
    unsigned char       *bvals;
    int                 Maxv;
{
    LOOP_2D (float, unsigned char)
            *aofst  =   *(bvals + linquant_f(*aifst, Maxv, k, t1));
}


/*
-- Table quantisation -------------------------------------------------
*/


int quant_f(v, thresh, Maxv, tabl, Maxt, k, t1)
/* Quantises v: returns I s.t. quants(I-1) <= v < quants(I).
tabl(K) should return a good guess for I  */
    float   v, k, t1;
    float   *thresh;
    int     Maxv, Maxt;
    int     *tabl;
{
    int     i, index;
    i = k * (v - t1) + 1.0;     /* like linquant_f */
    if      (i > Maxt)  i = Maxt;
    else if (i < 0)     i = 0;
    index = *(tabl + i);

    if (index == Maxv || v < *(thresh + index)) {
        do index--; while (index != -1 && v < *(thresh + index));
        index++; }
    else
        do index++; while (index != Maxv && v >= *(thresh + index));
    return index;
}


void fqlookup(ARGS, thresh, fvals, Maxv, tabl, Maxt, k, t1)
/* Float to float array, via quantisation table aided by
guess lookup table. */
    DECARGS (float, float)
    float               *thresh, *fvals, k, t1;
    int                 *tabl, Maxv, Maxt;
{
    LOOP_2D (float, float)
            *aofst  =   *(fvals +
                    quant_f(*aifst, thresh, Maxv, tabl, Maxt, k, t1));
}


void fqlookupu(ARGS, thresh, fvals, undefs, Maxv, tabl, Maxt, k, t1)
/* Float to float array, quantisation table with undefined values */
    DECARGS (float, float)
    float               *thresh, *fvals, k, t1;
    int                 *tabl, *undefs, Maxv, Maxt;
{
    int     i;
    LOOP_2D (float, float) {
            i = quant_f(*aifst, thresh, Maxv, tabl, Maxt, k, t1);
            *aofst  =   *(undefs+i) ? *aifst : *(fvals+i);
    }
}


void fbqlookup(ARGS, thresh, bvals, Maxv, tabl, Maxt, k, t1)
/* Float to byte array, via quantisation table aided by
guess lookup table. */
    DECARGS (float, unsigned char)
    float               *thresh, k, t1;
    unsigned char       *bvals;
    int                 *tabl, Maxv, Maxt;
{
    LOOP_2D (float, unsigned char)
            *aofst  =   *(bvals +
                    quant_f(*aifst, thresh, Maxv, tabl, Maxt, k, t1));
}

/* --- Revision History ---------------------------------------------------
--- David S Young, Apr 27 1994
        Fixed bug in quant_f - stopping condition going down was
        index != 0, but index != -1 is correct
--- David S Young, Jan 25 1994
        Simplified arguments.
 */
