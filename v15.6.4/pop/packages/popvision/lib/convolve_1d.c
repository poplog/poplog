/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 * File:            $popvision/lib/convolve_1d.c
 * Purpose:         Convolve 2 1-D arrays (non circular)
 * Author:          David S Young, Jun  3 1992
 * Related Files:   convolve_nx1d.p
 */

/* Convolution procedure for floats.

Does a 1-D convolution. The mask array is assumed to be densely packed
and full, but the data from the input and output arrays is allowed
to start from an arbitrary point and to have a step larger than one,
so that it can, for instance, represent a line through a higher-dimension
array.

In the description below, arrays are taken to be zero-based.

Arguments are:

in_1d       input array
in_start    starting offset into input array
in_step     step size through input array
mask_1d     mask array
mask_size   size of 1-D mask array
mask_orig   "centre" of the mask array - see below
out_1d      output array
out_start   starting offset into output array
out_step    step size through output array
out_end     ending offset into output array

The formula is

    out_1d(out_start + I * out_step)   +=

            SUM  { in_1d(in_start + I * in_step - X * in_step)
             X
                   * mask_1d(mask_orig + X)  }

where the sum ranges over values of X that produce legal offsets into
the mask array.  I ranges from 0 to the biggest value such that
out_start + I * out_step is no greater than out_end.

*/

void convolve_1d_f (
    in_1d,
    in_start,
    in_step,
    mask_1d,
    mask_size,
    mask_orig,
    out_1d,
    out_start,
    out_step,
    out_end
    )

float    *in_1d;
int       in_start;
int       in_step;
float    *mask_1d;
int       mask_size;
int       mask_orig;
float    *out_1d;
int       out_start;
int       out_step;
int       out_end;

{

int     mask_len = mask_size - 1;
float   sum,
        *in_x, *out_x, *out_x_max,
        *in_x_fast, *mask_x, *mask_max;

for (mask_max   =   mask_1d + mask_len,
     in_x       =   in_1d + in_start + in_step * (mask_orig - mask_len),
     out_x      =   out_1d + out_start,
     out_x_max  =   out_1d + out_end;

     out_x <= out_x_max;

     in_x += in_step,   out_x += out_step) {

    for (sum = 0.0,
         in_x_fast  = in_x,
         mask_x     = mask_max;

         mask_x >= mask_1d;

         mask_x--,  in_x_fast += in_step)

        sum += *in_x_fast * *mask_x;

    *out_x = sum; }

}
