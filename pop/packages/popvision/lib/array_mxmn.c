/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 * File:            $popvision/lib/array_mxmn.c
 * Purpose:         Maximum and minimum values in byte & float arrays
 * Author:          David S Young, Nov  9 1993 (see revisions)
 * Documentation:   HELP *ARRAY_MXMN (after loading LIB *VISION)
 * Related Files:   LIB *ARRAY_MXMN (after loading LIB *VISION)
 */


/* Procedures to find the maximum and minimum values in rectangular
regions of 2-D arrays of bytes and single-precision floats.

Arguments are

    xreg:       The size of the first dimension of the region
    yreg:       The size of the second dimension of the region
    avi:        The arrayvector of the input array
    starti:     The offset of the first element in the input array
    jumpi:      The increment between successive 1-D sections of
                    the region in the input array
    results:     2-element array of type float for float data or int for
                    byte data to receive the results

*/

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

void array_mxmn_2d_f(ARGS, results)

    DECARGS (float)
    float       *results;

{
    float       a,
                mx = *(avi + starti),
                mn = mx;
    LOOP_2D (float)
            if ((a = *aifst) < mn)    mn = a;
            else if (        a > mx) mx = a;

    *results++ = mx;
    *results = mn;
}

void array_mxmn_2d_b(ARGS, results)

    DECARGS (unsigned char)
    int         *results;

{
    int         a,
                mx = *(avi + starti),
                mn = mx;
    LOOP_2D (unsigned char)
            if ((a = *aifst) < mn)    mn = a;
            else if (        a > mx) mx = a;

    *results++ = mx;
    *results = mn;
}

/* --- Revision History ---------------------------------------------------
--- David S Young, Jan 25 1994
        Simplified arguments and introduced macros
 */
