/* --- Copyright University of Sussex 1996. All rights reserved. ----------
 * File:            $popvision/lib/arrayset.c
 * Purpose:         C routine for arrayset
 * Author:          David S Young, Jul  8 1996
 * Documentation:   HELP * ARRAYSET
 * Related Files:   LIB * ARRAYSET
 */

/* Procedures to set a region of a 2-D array of bytes or
single-precision floats to a constant value.

Arguments are

    val:        The value to store in the region
    xreg:       The size of the first dimension of the region
    yreg:       The size of the second dimension of the region
    avi:        The arrayvector of the array
    starti:     The offset of the first element in the input array
    jumpi:      The increment between successive 1-D sections of
                    the region in the input array

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


#define ARGS(TYPEI)                                             \
    int xreg, int yreg, TYPEI *avi, int starti, int jumpi

/*
-- Procedures ---------------------------------------------------------
*/

void arrayset_2d_f(float val, ARGS(float))
{
    LOOP_2D (float)
            *aifst = val;
}

void arrayset_2d_b(int val, ARGS(unsigned char))
{
    LOOP_2D (unsigned char)
            *aifst = val;
}

/* --- Revision History ---------------------------------------------------
--- David S Young, Jan 25 1994
        Simplified arguments and introduced macros
 */
