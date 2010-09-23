/* --- Copyright University of Sussex 1998. All rights reserved. ----------
 * File:            $popvision/lib/canny.c
 * Purpose:         Nonmaximum suppression for Canny edge finder
 * Author:          David Young, Nov 12 1992 (see revisions)
 * Documentation:   HELP *CANNY
 * Related Files:   LIB *CANNY
 */

/* Non-maximum suppression - second stage of Canny operation.
xdiff and ydiff are pointers to the xsize x ysize arrays containing
the x and y derivatives, and g is a pointer to the array of gradient
magnitudes. newg is a pointer to the array, assumed to be initialised
to zero on entry, to take the output. Values in g which lie on a ridge
are copied into newg.

This is adapted from Richard Tobin (indirectly). */

#include <math.h>

void canny2_f(xdiff, ydiff, g, newg, xsize, ysize)
    float *xdiff, *ydiff, *g, *newg;
    int xsize, ysize;
{
    float *xdiffy, *ydiffy, *gy, *newgy, *gyend,
          *xdiffx, *ydiffx, *gx, *newgx, *gxend,
          ux, uy, gc, g0, t;

    /* Point one row down and one column in*/
    xdiffy = xdiff + xsize + 1;
    ydiffy = ydiff + xsize + 1;
    gy = g + xsize + 1;
    newgy = newg + xsize + 1;

    for (gyend = gy + xsize * (ysize-3);

         gy <= gyend;

         xdiffy += xsize, ydiffy += xsize,
         gy += xsize, newgy += xsize)

        for (xdiffx = xdiffy, ydiffx = ydiffy,
             gx = gy, newgx = newgy,
             gxend = gx + xsize - 3;

             gx <= gxend;

             xdiffx++, ydiffx++, gx++, newgx++)
            {
            ux = *xdiffx; uy = *ydiffx; gc = *gx;
            if (ux*uy > 0) {
                t = uy - ux;
                if (fabs(ux) < fabs(uy))
                    {if ((g0 = fabs(uy * gc))
                          <= fabs(ux * *(gx+1+xsize) + t * *(gx+xsize)) ||
                       g0 <  fabs(ux * *(gx-1-xsize) + t * *(gx-xsize)))
                        continue;}
                else
                    {if ((g0 = fabs(ux * gc))
                          <= fabs(uy * *(gx+1+xsize) - t * *(gx+1)) ||
                       g0 <  fabs(uy * *(gx-1-xsize) - t * *(gx-1)))
                        continue;} }
            else {
                t = ux + uy;
                if (fabs(ux) < fabs(uy))
                    {if ((g0 = fabs(uy * gc))
                          <= fabs(ux * *(gx+1-xsize) - t * *(gx-xsize)) ||
                       g0 <  fabs(ux * *(gx-1+xsize) - t * *(gx+xsize)))
                        continue;}
                else
                    {if ((g0 = fabs(ux * gc))
                          <= fabs(uy * *(gx+1-xsize) - t * *(gx+1)) ||
                       g0 <  fabs(uy * *(gx-1+xsize) - t * *(gx-1)))
                        continue;} };
            *newgx = gc;
            }
}

/* --- Revision History ---------------------------------------------------
--- David S Young, Feb 16 1998
        Changed tests from "g0 <= g1 or g0 <= g2" (where g0 is in the
        middle and g1 and g2 are interpolated values one pixel away) to
        "g0 <= g1 or g0 < g2". This means that perfect noise-free step
        edges are detected (they were not before because two equal
        values could occur at the top of the gradient peak) but
        performance on real images is unaffected.
--- David S Young, Nov 26 1992
        Installed
 */
