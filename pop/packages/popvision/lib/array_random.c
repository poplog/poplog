/* --- Copyright University of Sussex 1998. All rights reserved. ----------
 * File:            $popvision/lib/array_random.c
 * Purpose:         C routines for array_random
 * Author:          David S Young, Jul  8 1996 (see revisions)
 * Documentation:   HELP * ARRAY_RANDOM
 * Related Files:   LIB * ARRAY_RANDOM
 */


/* Procedures to set regions of 2-D arrays of bytes and single-precision
floats to random values. Uses the drand48 family, which is supplied with
the standard library on Suns. It would be easy enough to replace this
with any other random number generator.

Arguments are

    xreg:       The size of the first dimension of the region
    yreg:       The size of the second dimension of the region
    avi:        The arrayvector of the input array
    starti:     The offset of the first element in the input array
    jumpi:      The increment between successive 1-D sections of
                    the region in the input array
    p0:         Lower bound for uniform and mean for gaussian dist
    p1:         Upper bound for uniform and sd for gaussian dist

*/

#include <stdlib.h>
#include <math.h>

/*
-- Interface to random number seeder ----------------------------------

Use a local seed to avoid interactions with other uses of rand48.
*/

static unsigned short seed[3] = {1, 1, 1};

void array_random_set(unsigned short *s)
{
    seed[0] = s[0];
    seed[1] = s[1];
    seed[2] = s[2];
}

void array_random_get(unsigned short *s)
{
    s[0] = seed[0];
    s[1] = seed[1];
    s[2] = seed[2];
}

/*
-- Macro definitions --------------------------------------------------
*/

#define DECLARE_LOOPVARS(TYPEI)                                 \
    TYPEI               *aisl, *aislmx, *aifst, *aifstmx;       \

#define LOOP_2D                                                 \
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

#define ARGS(TYPEI)                                             \
        int xreg, int yreg, TYPEI *avi, int starti, int jumpi

/*
-- Procedures ---------------------------------------------------------
*/

void array_random_u_2d_f(ARGS(float), double p0, double p1)
{
    DECLARE_LOOPVARS (float)
    double range = p1 - p0;
    LOOP_2D
        *aifst = range * erand48(seed) + p0;
}

void array_random_ui_2d_f(ARGS(float), double p0, double p1)
{
    DECLARE_LOOPVARS (float)
    double range = p1 - p0;
    LOOP_2D
        *aifst = floor(range * erand48(seed) + p0);
}

float gaussdev (void)
/* Returns a normally distributed deviate using the code from
Numerical Recipes in C (Press et al.) */
{
    static int iset = 0;
    static float gset;
    float fac, r, v1, v2;

    if (iset == 0) {
        do {
            v1 = 2.0 * erand48(seed) - 1.0;
            v2 = 2.0 * erand48(seed) - 1.0;
            r = v1*v1 + v2*v2;
        } while (r >= 1.0 || r == 0.0);
        fac = sqrt(-2.0 * log(r)/r);
        gset = v1 * fac;
        iset = 1;
        return v2 * fac;
    } else {
        iset = 0;
        return gset;
    }
}

void array_random_g_2d_f(ARGS(float), double m, double sd)
{
    DECLARE_LOOPVARS (float)
    LOOP_2D {
        *aifst = m + sd * gaussdev();
    }
}

void array_random_u_2d_b(ARGS(unsigned char), int p0, int p1)
{
    DECLARE_LOOPVARS (unsigned char)
    double      range = p1 - p0,
                f0 = p0,
                v;
    if (p0 >= 0 && p1 <= 256)       /* 0.0 <= erand() < 1.0 */
        LOOP_2D
            *aifst = (unsigned char) (range * erand48(seed) + f0);
    else
        LOOP_2D {
            v = range * erand48(seed) + f0;
            if (v < 0.0) v = 0.0;
            else if (v > 255.0) v = 255.0;
            *aifst = (unsigned char) v;
        }
}

/* --- Revision History ---------------------------------------------------
--- David S Young, Jul 17 1998
        Changed Gaussian generator from sum of 12 independent variables
        to the faster and more accurate Box-Muller method from
        Numerical Recipes in C (Press et al.).
--- David S Young, Aug  9 1996
        Added procedures to return seeds and to produce uniform
        distributions with integral values.
 */
