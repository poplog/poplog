/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 * File:            $popvision/lib/arraysample.c
 * Purpose:         Simple interpolation for float & byte arrays
 * Author:          David S Young, Jun  3 1992 (see revisions)
 * Related Files:   LIB ARRAYSAMPLE
 */

/* General interpolation/extrapolation procedure for floats.

In the description below, arrays are taken to be zero-based.

For arraysample_1d_x arguments are:

in_1d       input array
in_start    starting offset into input array
in_step     step size through input array
mask_2d     array of masks
mask_size   size of each mask
starts_1d   array of starting points for the mask applications
out_1d      output array
out_start   starting offset into output array
out_step    step size through output array
n           number of points to process

The formula is

    out_1d(out_start + I * out_step)   =

            SUM  { in_1d(in_start + starts_1d(I) + X * in_step)
             X
                   * mask_2d(X + I * mask_size)  }

where the sum is performed over values of X from 0 to mask_size-1.
I ranges from 0 to n-1.

The mask size can be passed as 0, in which case the mask is ignored
and the formula is just

    out_1d(out_start + I * out_step)  =  in_1d(in_start + starts_1d(I)).

The mask size can also be negative. In this case summation or averaging
is carried out over abs(mask_size) samples. The formula is

    out_1d(out_start + I * out_step)   =

            v * SUM { in_1d(in_start + starts_1d(I) + X * in_step)
                       X

where v is a scalar value pointed to by mask_2d. For averaging, this
should be 1/abs(mask_size).

The routine copy_1d_x is a simple routine for straightforward case of
an equally-spaced copy

    out_1d(out_start + I * out_step)  =  in_1d(in_start + I * in_step)

for I from 0 to n-1.

*/

/*
-- Float version ------------------------------------------------------
*/

void resample_1d_f (
    in_1d,
    in_start,
    in_step,
    mask_2d,
    mask_size,
    starts_1d,
    out_1d,
    out_start,
    out_step,
    n
    )

float    *in_1d;
int       in_start;
int       in_step;
float    *mask_2d;
int       mask_size;
int      *starts_1d;
float    *out_1d;
int       out_start;
int       out_step;
int       n;

{

int     i, j;
float   sum, v,
        *in_go, *out_x, *in_x_fast;

if (mask_size == 0)

    for (j = 0,
         in_go      =   in_1d + in_start,
         out_x      =   out_1d + out_start;

         j < n;

         j++,   out_x += out_step)

            *out_x  = *(in_go + starts_1d[j]);

else if (mask_size < 0) {

    mask_size = -mask_size;
    v = *mask_2d;

    for (j = 0,
         in_go      =   in_1d + in_start,
         out_x      =   out_1d + out_start;

         j < n;

         j++,   out_x += out_step) {

        for (sum = 0.0,
             i = 0,
             in_x_fast  = in_go + starts_1d[j];

             i < mask_size;

             in_x_fast += in_step,   i++)

            sum += *in_x_fast;

        *out_x = v * sum; }
    }

else

    for (j = 0,
         in_go      =   in_1d + in_start,
         out_x      =   out_1d + out_start;

         j < n;

         j++,   out_x += out_step) {

        for (sum = 0.0,
             i = 0,
             in_x_fast  = in_go + starts_1d[j];

             i < mask_size;

             mask_2d++,  in_x_fast += in_step,   i++)

            sum += *in_x_fast * *mask_2d;

        *out_x = sum; }

}


void copy_1d_f (
    in_1d,
    in_start,
    in_step,
    out_1d,
    out_start,
    out_step,
    n
    )

float    *in_1d;
int       in_start;
int       in_step;
float    *out_1d;
int       out_start;
int       out_step;
int       n;

{

float  *in_x, *out_x, *in_end;

for (in_x       =   in_1d + in_start,
     in_end     =   in_x + n * in_step,
     out_x      =   out_1d + out_start;

     in_x < in_end;

     in_x += in_step,   out_x += out_step)

        *out_x  = *in_x;

}

/*
-- Byte version -------------------------------------------------------

Note that does NOT check for values in range, for efficiency. The
calling routine is trusted to have given a sensible mask etc.

Note also that the mask is still a float array.

*/

void resample_1d_b (
    in_1d,
    in_start,
    in_step,
    mask_2d,
    mask_size,
    starts_1d,
    out_1d,
    out_start,
    out_step,
    n
    )

unsigned char  *in_1d;
int             in_start;
int             in_step;
float          *mask_2d;
int             mask_size;
int            *starts_1d;
unsigned char  *out_1d;
int             out_start;
int             out_step;
int             n;

{

int             i, j;
float           sum, v;
unsigned char  *in_go, *out_x, *in_x_fast;

if (mask_size == 0)

    for (j = 0,
         in_go      =   in_1d + in_start,
         out_x      =   out_1d + out_start;

         j < n;

         j++,   out_x += out_step)

            *out_x  = *(in_go + starts_1d[j]);

else if (mask_size < 0) {

    mask_size = -mask_size;
    v = *mask_2d;

    for (j = 0,
         in_go      =   in_1d + in_start,
         out_x      =   out_1d + out_start;

         j < n;

         j++,   out_x += out_step) {

        for (sum = 0.0,
             i = 0,
             in_x_fast  = in_go + starts_1d[j];

             i < mask_size;

             in_x_fast += in_step,   i++)

            sum += *in_x_fast;

        *out_x = v * sum + 0.5; }   /* round */
    }

else

    for (j = 0,
         in_go      =   in_1d + in_start,
         out_x      =   out_1d + out_start;

         j < n;

         j++,   out_x += out_step) {

        for (sum = 0.0,
             i = 0,
             in_x_fast  = in_go + starts_1d[j];

             i < mask_size;

             mask_2d++,  in_x_fast += in_step,   i++)

            sum += *in_x_fast * *mask_2d;

        *out_x = sum + 0.5; }   /* round */

}


void copy_1d_b (
    in_1d,
    in_start,
    in_step,
    out_1d,
    out_start,
    out_step,
    n
    )

unsigned char  *in_1d;
int             in_start;
int             in_step;
unsigned char  *out_1d;
int             out_start;
int             out_step;
int             n;

{

unsigned char  *in_x, *out_x, *in_end;

for (in_x       =   in_1d + in_start,
     in_end     =   in_x + n * in_step,
     out_x      =   out_1d + out_start;

     in_x < in_end;

     in_x += in_step,   out_x += out_step)

        *out_x  = *in_x;

}

/* --- Revision History ---------------------------------------------------
--- David S Young, Jun 11 1992
        Name changed from arraysample_f.c. Byte procedures included.
        Bug in copy_1d procedures fixed.
 */
