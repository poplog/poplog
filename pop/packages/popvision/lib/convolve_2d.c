/* --- Copyright University of Sussex 2001. All rights reserved. ----------
 * File:            $popvision/lib/convolve_2d.c
 * Purpose:         Convolve a 2-D array with a 2-D mask
 * Author:          David S Young, Jun  3 1992 (see revisions)
 * Related Files:   LIB CONVOLVE_2D
 */

/* Convolution procedure for floats.

Array arguments are 2-D arrays, as in Fortran and POP-11, not vectors of
pointers as would be more suited to C.

This description assumes x running from left to right and y from top to
bottom, and that arrays are zero-based.

Arguments:

    in_2d           input array
    in_offset       offset in arrayvector
    in_xsize        first dimension of the input array
    in_xstart       x-coord of top-left location for mask
    in_ystart       y-coord of ditto
    in_xskip        amount to jump on x axis between evaluations
    in_yskip        amount to jump on y axis between evaluations
    mask_2d         mask array
    ms_offset       offset in arrayvector
    mask_xsize      first dimension of the mask array
    mask_ysize      second dimension of the mask array
    mask_xorig      x-coord of the "centre" of the mask array
    mask_yorig      y-coord of ditto
    out_2d          output array - changed on exit
    out_offset      offset in arrayvector
    out_xsize       first dimension of the output array
    out_xstart      x-coord of left side of output region
    out_xend        x-coord of right side of output region
    out_ystart      y-coord of top of output region
    out_yend        y-coord of bottom of output region

Assume that in_xskip and in_yskip are 1 for now.

The region bounded by out_{xstart,xend,ystart,yend} in the output array
is filled by convolving the mask with a region the same size in the
input array. The top left corner of this region in the input array is
specified by in_{xstart,ystart}.

The whole of the mask array is used.

The mask_{xorig,yorig} parameters determine how the mask lines up with
elements of the input array. They specify an element of the mask array
as an offset from its top left corner - call this element O. If we
consider positions relative to the input and output regions (i.e.
relative to (in_xstart, in_ystart) in the input array and relative to
(out_xstart, out_ystart) in the output array), then in calculating the
value to store at (X,Y) in the output array, the element at (X,Y) in the
input array is multiplied by O.

In other words, the formula used is

    output(out_xstart + X, out_ystart + Y)

        =  SUM   { input(in_xstart + X - x, in_ystart + Y - y)
           x,y
                   * mask(mask_xorig + x,  mask_yorig + y) }

where the sum ranges over values of x,y that produce legal offsets into
the mask array.

The procedure is long only because the special cases of 1x1, 1xn and mx1
masks are optimised (avoiding inner for-loops). These cases are all
handled in the one procedure to avoid repeating the long argument list.

If the in_xskip argument is greater than 1, the x coord of the mask in
the input array is shifted by in_xskip for each increment of the output
position. Likewise for in_yskip on the other axis. The formula becomes:

    output(out_xstart + X, out_ystart + Y)

    =  SUM   { input(in_xstart + X*in_xskip - x, in_ystart + Y*in_yskip - y)
       x,y
               * mask(mask_xorig + x,  mask_yorig + y) }

*/


static void convolve_2d_f (
    float*  in_2d,
    int     in_xsize,
    int     in_xstart,
    int     in_ystart,
    float*  mask_2d,
    int     mask_xsize,
    int     mask_ysize,
    int     mask_xorig,
    int     mask_yorig,
    float*  out_2d,
    int     out_xsize,
    int     out_xstart,
    int     out_xend,
    int     out_ystart,
    int     out_yend
    )

/* This version is for in_xskip = in_yskip = 1 */

{
    int         out_xlen    = out_xend - out_xstart,
                mask_xlen   = mask_xsize - 1,
                mask_ylen   = mask_ysize - 1;
    float       sum, sclr,
                *out_y, *out_y_max, *out_x, *out_x_max,
                *in_y, *in_x,
                *in_fast_x, *in_fast_y,
                *mask_x, *mask_y,
                *mask_x_max, *mask_y_max;

/* Variables:
    in_y and out_y point to the starting point for operations on
        the current line of the input and output arrays
    in_x points to the element of the input array corresponding to the
        current position of the first element of the mask
    in_fast_x and in_fast_y are similar for the inner summation loop
    out_x points to the element of the output array to receive the
        result of the current summation
    mask_y and mask_x similarly point to a row and an element of the
        mask array

The inner loops (after the first case) go forward through the input
array but backward through the mask array to implement the flip
necessary for proper convolution. */

if (mask_xsize == 1 && mask_ysize == 1)

    /* The special case of a 1x1 mask - i.e. just scalar mult */

    for (sclr       =   *mask_2d,
         out_y_max  =   out_2d + (out_xsize * out_yend + out_xstart),
         out_y      =   out_2d + (out_xsize * out_ystart + out_xstart),
         in_y       =   in_2d + (in_xsize * (in_ystart + mask_yorig)
                              + in_xstart + mask_xorig);

         out_y <= out_y_max;        /* CONDITION */

         out_y  +=  out_xsize,   in_y  +=  in_xsize) /* move down */

        for (out_x      =   out_y,
             in_x       =   in_y,
             out_x_max  =   out_y + out_xlen;

             out_x <= out_x_max;    /* CONDITION */

             out_x++,        in_x++)    /* move right */

            *out_x = sclr * *in_x;

    /* end scalar mult case */

else if (mask_xsize == 1)

    /* The special case of a 1xn mask */

    for (mask_y_max     =   mask_2d + mask_ylen,
         out_y_max      =   out_2d + (out_xsize * out_yend + out_xstart),
         out_y          =   out_2d + (out_xsize * out_ystart + out_xstart),
         in_y           =   in_2d + (
                            in_xsize * (in_ystart - mask_ylen + mask_yorig)
                            + in_xstart + mask_xorig);

         out_y <= out_y_max;        /* CONDITION */

         out_y += out_xsize,  in_y += in_xsize)  /* move down */

        for (out_x_max  =   out_y + out_xlen,
             out_x      =   out_y,
             in_x       =   in_y;

             out_x <= out_x_max;    /* CONDITION */

             out_x++,   in_x++) {       /* move right */

            for (sum        =   0.0,
                 mask_y     =   mask_y_max,
                 in_fast_y  =   in_x;

                 mask_y >= mask_2d;     /* CONDITION */

                 mask_y--,  in_fast_y += in_xsize)  /* up mask, down input */

                sum += *in_fast_y * *mask_y;        /* summation step */

            *out_x = sum; }

    /* end 1xn case */

else if (mask_ysize == 1)

    /* The special case of a mx1 mask */

    for (mask_x_max     =   mask_2d + mask_xlen,
         out_y_max      =   out_2d + (out_xsize * out_yend + out_xstart),
         out_y          =   out_2d + (out_xsize * out_ystart + out_xstart),
         in_y           =   in_2d + (in_xsize * (in_ystart + mask_yorig)
                                  + in_xstart - mask_xlen + mask_xorig);

         out_y <= out_y_max;    /* CONDITION */

         out_y += out_xsize,    in_y += in_xsize)  /* move down */

        for (out_x_max  =   out_y + out_xlen,
             out_x      =   out_y,
             in_x       =   in_y;

             out_x <= out_x_max;        /* CONDTION */

             out_x++,    in_x++) {      /* move right */

            for (sum        =   0.0,
                 mask_x     =   mask_x_max,
                 in_fast_x  =   in_x;

                 mask_x >= mask_2d;     /* CONDITION */

                 mask_x--,          in_fast_x++)   /* left mask, right input */

                sum += *in_fast_x * *mask_x;        /* summation step */

            *out_x = sum; }

    /* end mx1 case */

else

    /* The general case of a 2-D mask */

    for (mask_y_max     =   mask_2d + (mask_xsize * mask_ylen),
         out_y_max      =   out_2d + (out_xsize * out_yend + out_xstart),
         out_y          =   out_2d + (out_xsize * out_ystart + out_xstart),
         in_y           =   in_2d + (
                            in_xsize * (in_ystart - mask_ylen + mask_yorig)
                            + in_xstart - mask_xlen + mask_xorig);

         out_y <= out_y_max;    /* CONDITION */

         out_y += out_xsize,    in_y += in_xsize)   /* move down */

        for (out_x_max  =   out_y + out_xlen,
             out_x      =   out_y,
             in_x       =   in_y;

             out_x <= out_x_max;        /* CONDITION */

             out_x++,    in_x++) {      /* move right */

            for (sum        =   0.0,
                 mask_y     =   mask_y_max,
                 in_fast_y  =   in_x;

                 mask_y >= mask_2d;     /* CONDITION */

                 mask_y -= mask_xsize,  in_fast_y += in_xsize)
                            /* up mask, down input */

                for (mask_x     =   mask_y + mask_xlen,
                     in_fast_x  =   in_fast_y;

                     mask_x >= mask_y;      /* CONDITION */

                     mask_x--, in_fast_x++) /* left mask, right input */

                    sum += *in_fast_x * *mask_x;    /* summation step */

            *out_x = sum; }

    /* end general case */
}

void convolve_2d_skip_f (
    float*  in_2d,
    int     in_offset,
    int     in_xsize,
    int     in_xstart,
    int     in_ystart,
    int     in_xskip,
    int     in_yskip,
    float*  mask_2d,
    int     mask_offset,
    int     mask_xsize,
    int     mask_ysize,
    int     mask_xorig,
    int     mask_yorig,
    float*  out_2d,
    int     out_offset,
    int     out_xsize,
    int     out_xstart,
    int     out_xend,
    int     out_ystart,
    int     out_yend
    )

{
    int         out_xlen    = out_xend - out_xstart,
                mask_xlen   = mask_xsize - 1,
                mask_ylen   = mask_ysize - 1,
                in_yjump    = in_xsize * in_yskip;
    float       sum, sclr,
                *out_y, *out_y_max, *out_x, *out_x_max,
                *in_y, *in_x,
                *in_fast_x, *in_fast_y,
                *mask_x, *mask_y,
                *mask_x_max, *mask_y_max;

/* Shift now to zero-based arrays */
in_2d = in_2d + in_offset;
mask_2d = mask_2d + mask_offset;
out_2d = out_2d + out_offset;

if (in_xskip == 1 && in_yskip == 1)   /* Use faster routine */
    convolve_2d_f (
        in_2d, in_xsize, in_xstart, in_ystart,
        mask_2d, mask_xsize, mask_ysize, mask_xorig, mask_yorig,
        out_2d, out_xsize, out_xstart, out_xend, out_ystart, out_yend
    );

else
for (mask_y_max     =   mask_2d + (mask_xsize * mask_ylen),
     out_y_max      =   out_2d + (out_xsize * out_yend + out_xstart),
     out_y          =   out_2d + (out_xsize * out_ystart + out_xstart),
     in_y           =   in_2d + (
                        in_xsize * (in_ystart - mask_ylen + mask_yorig)
                        + in_xstart - mask_xlen + mask_xorig);

     out_y <= out_y_max;    /* CONDITION */

     out_y += out_xsize,    in_y += in_yjump)   /* move down */

    for (out_x_max  =   out_y + out_xlen,
         out_x      =   out_y,
         in_x       =   in_y;

         out_x <= out_x_max;        /* CONDITION */

         out_x++,    in_x += in_xskip) {      /* move right */

        for (sum        =   0.0,
             mask_y     =   mask_y_max,
             in_fast_y  =   in_x;

             mask_y >= mask_2d;     /* CONDITION */

             mask_y -= mask_xsize,  in_fast_y += in_xsize)
                        /* up mask, down input */

            for (mask_x     =   mask_y + mask_xlen,
                 in_fast_x  =   in_fast_y;

                 mask_x >= mask_y;      /* CONDITION */

                 mask_x--, in_fast_x++) /* left mask, right input */

                sum += *in_fast_x * *mask_x;    /* summation step */

        *out_x = sum; }

}

/* --- Revision History ---------------------------------------------------
--- David Young, Oct 28 2001
        Added routine to do subsampling at the same time as convolution.
 */
