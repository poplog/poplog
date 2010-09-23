/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 * File:            $popvision/lib/array_peaks.c
 * Purpose:         Find local maxima in an array
 * Author:          David Young, Nov 12 1992 (see revisions)
 * Documentation:   HELP *ARRAY_PEAKS
 * Related Files:   LIB *ARRAY_PEAKS
 */

/* Find local peaks in an array */

int array_peaks(arr, xsize, xstart, xend, ystart, yend, thresh, out, n)

float       *arr;
int         xsize, xstart, xend, ystart, yend;
float       thresh;
int         *out, n;

{
    float       *arrslow, *arrfast,
                *arrslowinner, *arrfastinner,
                a;
    int         diagshift = xsize + 1,
                x, y, i, j, atpeak;

    for (arrslow = arr + xsize * ystart + xstart, y = ystart;
         y <= yend;
         arrslow += xsize, y++)

        for (arrfast = arrslow, x = xstart;
             x <= xend;
             arrfast++, x++)

            if ((a = *arrfast) >= thresh) {

                for (atpeak = 1,
                     arrslowinner = arrfast - diagshift, i = 3;
                     i && atpeak;
                     arrslowinner += xsize, i--)

                    for (arrfastinner = arrslowinner, j = 3;
                         j && atpeak;
                         arrfastinner++, j--)

                            atpeak = a >= *arrfastinner;

                if (atpeak)
                    if (n) {
                        *out++ = x;
                        *out++ = y;
                        n--; }
                    else
                        return -1;
                };
    return n;
}

/* Find the maximum point in a region of an array */

void array_peak(arr, xsize, xstart, xend, ystart, yend, out)

float       *arr;
int         xsize, xstart, xend, ystart, yend;
int         *out;

{
    float       *arrslow, *arrfast,
                *arrslowinner, *arrfastinner,
                amx;
    int         x, y,
                xmx = xstart,
                ymx = ystart;

    for (arrslow = arr + xsize * ystart + xstart,
         y = ystart,
         amx = *arrslow;

         y <= yend;

         arrslow += xsize, y++)

        for (arrfast = arrslow, x = xstart;
             x <= xend;
             arrfast++, x++)

            if (*arrfast > amx) {
                amx = *arrfast;
                xmx = x;
                ymx = y; };

    *out++ = xmx;
    *out = ymx;

}

/* --- Revision History ---------------------------------------------------
--- David S Young, Jan 30 1993
        Added -array_peak-
 */
