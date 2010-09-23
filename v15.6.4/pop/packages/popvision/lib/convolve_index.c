/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 * File:            $popvision/lib/convolve_index.c
 * Purpose:         C support for indexed convolution
 * Author:          David S Young, Nov 26 1992
 * Documentation:   HELP *CONVOLVE_INDEX
 * Related Files:   LIB *CONVOLVE_INDEX
 */

/* Provides an indexed convolution procedure. Only does a single
continuous region of the input and output arrays, so will probably need
calling repeatedly to carry out a convolution for an N-dimensional
region. */

void convolve_index_f (
    arrin,
    in_start,
    in_incr,
    mask,
    offsets,
    masklen,
    arrout,
    out_start,
    out_incr,
    n
    )

float   *arrin;         /* Input array */
int     in_start;       /* Offset into input array to start */
int     in_incr;        /* Increment into input array on each step */
float   *mask;          /* Weights array */
int     *offsets;       /* Offsets into input array for each weight */
int     masklen;        /* Number of wts & offsets */
float   *arrout;        /* Output array */
int     out_start;      /* Offset into output array to start */
int     out_incr;       /* Increment into output array on each step */
int     n;              /* Number of points to do */

{

    int     *offsetfast, *offsetend;
    float   *arrinfast, *arrinend, *arroutfast, *maskfast,
            sum;

    offsetend = offsets + masklen - 1;

    for (arrinfast = arrin + in_start,
         arroutfast = arrout + out_start,
         arrinend = arrinfast + in_incr * (n - 1);

         arrinfast <= arrinend;

         arrinfast += in_incr, arroutfast += out_incr) {

        for (maskfast = mask,
             offsetfast = offsets,
             sum = 0.0;

             offsetfast <= offsetend;

             maskfast++, offsetfast++)

            sum += *(arrinfast + *offsetfast) * *maskfast;

        *arroutfast = sum; }

}
