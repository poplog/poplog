/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 * File:            $popvision/lib/straight_hough.c
 * Purpose:         Straight line finding by Hough Transform
 * Author:          David Young, Nov 12 1992 (see revisions)
 * Documentation:   HELP *STRAIGHT_HOUGH
 * Related Files:   LIB *STRAIGHT_HOUGH
 */

#include <math.h>

void straight_hough_array_f(
    arr, xsize, xstart, xend, ystart, yend,
    hough, rsize, rstart, rend, tstart, tend,
    xbegin, ybegin, xincr, yincr, tbin)

float   *arr;
int     xsize, xstart, xend, ystart, yend;
float   *hough;
int     rsize, rstart, rend, tstart, tend;
/* The first pixel processed is at xbegin, ybegin in user coords */
float   xbegin, ybegin, xincr, yincr, tbin;

{   float   *arrslow, *arrfast, *arrslowend, *arrfastend,
            *h, *hbegin, *hend, *hh;
    int     xn = xend - xstart,
            thalf = rsize * (tend - tstart + 1);
    float   a, x, y, r,
            c, s, chold,
            cincr = cos(tbin), sincr = sin(tbin);
    int     rint;

    hbegin = hough + rsize * tstart + rstart;
    hend = hough + rsize * tend + rstart;

    for (arrslow = arr + xsize * ystart + xstart,
         arrslowend = arr + xsize * yend + xstart,
         y = ybegin;

         arrslow <= arrslowend;

         arrslow += xsize, y += yincr)

        for (arrfast = arrslow,
             arrfastend = arrslow + xn,
             x = xbegin;

             arrfast <= arrfastend;

             arrfast++, x += xincr)

            if ((a = *arrfast) != 0.0)
                for (h = hbegin,
                     c = 1,   s = 0;   /* First bin is at angle zero */

                     h <= hend;

                     chold = c * cincr - s * sincr,
                     s = s * cincr + c * sincr,
                     c = chold,
                     h += rsize) {
                    r = x * c + y * s;
                    if (r < 0.0) {
                        rint = -r;  /* truncate */
                        hh = h + thalf + rint; }
                    else {
                        rint = r;   /* truncate */
                        hh = h + rint; }
                    *hh += a; }
}

/* --- Revision History ---------------------------------------------------
--- David S Young, Nov 26 1992
        Installed
 */
