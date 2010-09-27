/* --- Copyright University of Sussex 2001. All rights reserved. ----------
 * File:            $popvision/lib/array_transpose.c
 * Purpose:         Transpose regions of float and byte arrays
 * Author:          David Young, Oct  5 2001
 * Documentation:   HELP * ARRAY_TRANSPOSE
 * Related Files:   LIB * ARRAY_TRANSPOSE
 */

/* Procedures to transpose a 2-D region of a float or byte array.

Arguments are

    xreg:       The size of the first dimension of the input region
    yreg:       The size of the second dimension of the input region
    avi:        The arrayvector of the input array
    starti:     The offset of the first element in the input array
    jumpi:      The increment between successive 1-D sections of
                    the region in the input array
    avo:        The arrayvector of the output array
    starto:     The offset of the first element in the output array
    jumpo:      The increment between successive 1-D sections of
                    the region in the output array

*/

/*
-- Macro definitions --------------------------------------------------
*/

#define LOOP_2D(TYPE)                                           \
                                                                \
    TYPE                *aisl, *aislmx, *aifst, *aifstmx,       \
                        *aosl, *aofst;                          \
                                                                \
    for (aisl = avi + starti, aosl = avo + starto,              \
         aislmx = aisl + yreg * jumpi;                          \
                                                                \
         aisl < aislmx;                                         \
                                                                \
         aisl += jumpi, aosl++)                                 \
                                                                \
        for (aifst = aisl, aofst = aosl,                        \
             aifstmx = aifst + xreg;                            \
                                                                \
             aifst < aifstmx;                                   \
                                                                \
             aifst++, aofst += jumpo)                           \


#define ARGS(TYPE)                                              \
    int xreg, int yreg, TYPE *avi, int starti, int jumpi,       \
                        TYPE *avo, int starto, int jumpo

/*
-- Procedures ---------------------------------------------------------
*/

void array_transpose_f(ARGS(float))
{
    LOOP_2D (float)
            *aofst = *aifst;
}

void array_transpose_b(ARGS(unsigned char))
{
    LOOP_2D (unsigned char)
            *aofst = *aifst;
}
