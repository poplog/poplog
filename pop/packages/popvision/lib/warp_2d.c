/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 * File:            $popvision/lib/warp_2d.c
 * Purpose:         C routines for affine transformation of image
 * Author:          David S Young, Jul  9 1993
 * Documentation:   HELP *WARP_2D
 * Related Files:   LIB *WARP_2D
 */


void warp_n_f (
    in_2d,
    in_xsize, in_ysize,
    out_2d,
    out_xsize,
    out_xstart, out_xend, out_ystart, out_yend,
    in_xstart, in_ystart, Txx, Txy, Tyx, Tyy
    )

    /* Carries out an affine transformation. The parameters specify the
    backwards transform. Sampling uses nearest point.
    Arguments are single-precision floats.

    The calling procedure must check that there is no need to go
    outside the input array.

    Arguments are:

        in_2d - the input array
        in_xsize - the first dimension of the input array
        in_ysize - the second dimension of the input array (needed for
            the checking version and included here for consistency)
        out_2d - the output array
        out_xsize - the first dimension of the output array
        out_xstart, out_xend, out_ystart, out_yend
            - the region in the output array to fill with data
        in_xstart, in_ystart - the position in the input array which
            is to be mapped to (out_xstart, out_ystart) in the
            output array
        Txx, Txy, Tyx, Tyy - the elements of the transformation matrix
            mapping output to input.

    */

    float       *in_2d;
    int         in_xsize, in_ysize;
    float       *out_2d;
    int         out_xsize;
    int         out_xstart, out_xend, out_ystart, out_yend;
    float       in_xstart, in_ystart, Txx, Txy, Tyx, Tyy;

{
    float   *outslow, *outslow_max, *outfast, *outfast_max, *in_pos;
    float   xstart, ystart, x, y;
    int     xdo = out_xend - out_xstart;
    int     xint, yint;

for (outslow        =   out_2d + (out_xsize * out_ystart + out_xstart),
     outslow_max    =   out_2d + (out_xsize * out_yend + out_xstart),
     xstart         =   in_xstart + 0.5,
     ystart         =   in_ystart + 0.5;  /* +0.5 is for rounding */

     outslow        <=  outslow_max;

     outslow        +=  out_xsize,
     xstart         +=  Txy,
     ystart         +=  Tyy)

    for (outfast        =   outslow,
         outfast_max    =   outfast + xdo,
         x              =   xstart,
         y              =   ystart;

         outfast        <=  outfast_max;

         outfast++,
         x              +=  Txx,
         y              +=  Tyx) {

        xint = x;   yint = y; /* rounded because of +0.5 above */
        *outfast = *(in_2d + yint * in_xsize + xint);
        }

}

void warp_nc_f (
    in_2d,
    in_xsize, in_ysize,
    out_2d,
    out_xsize,
    out_xstart, out_xend, out_ystart, out_yend,
    in_xstart, in_ystart, Txx, Txy, Tyx, Tyy
    )

    /* Same as warp_n_f but checks that we're inside the input array
    for each point, and does nothing if we're not. */

    float       *in_2d;
    int         in_xsize, in_ysize;
    float       *out_2d;
    int         out_xsize;
    int         out_xstart, out_xend, out_ystart, out_yend;
    float       in_xstart, in_ystart, Txx, Txy, Tyx, Tyy;

{
    float   *outslow, *outslow_max, *outfast, *outfast_max, *in_pos;
    float   xstart, ystart, x, y;
    int     xdo = out_xend - out_xstart;
    int     xint, yint;

for (outslow        =   out_2d + (out_xsize * out_ystart + out_xstart),
     outslow_max    =   out_2d + (out_xsize * out_yend + out_xstart),
     xstart         =   in_xstart + 0.5,
     ystart         =   in_ystart + 0.5;  /* +0.5 is for rounding */

     outslow        <=  outslow_max;

     outslow        +=  out_xsize,
     xstart         +=  Txy,
     ystart         +=  Tyy)

    for (outfast        =   outslow,
         outfast_max    =   outfast + xdo,
         x              =   xstart,
         y              =   ystart;

         outfast        <=  outfast_max;

         outfast++,
         x              +=  Txx,
         y              +=  Tyx) {

        xint = x;   yint = y; /* rounded because of +0.5 above */
        if (xint >= 0 && xint < in_xsize &&
            yint >= 0 && yint < in_ysize)
            *outfast = *(in_2d + yint * in_xsize + xint);
        }

}

void warp_l_f (
    in_2d,
    in_xsize, in_ysize,
    out_2d,
    out_xsize,
    out_xstart, out_xend, out_ystart, out_yend,
    in_xstart, in_ystart, Txx, Txy, Tyx, Tyy
    )

    /* Carries out an affine transformation. The parameters specify the
    backwards transform. Sampling uses bilinear interpolation.
    Arguments are single-precision floats.

    Arguments as for warp_n_f.

    The procedure is much lengthened by the need to deal with the
    possibility that rounding errors will cause it to take data from
    outside the array, even if the calling procedure has checked that it
    should not do so. This can happen if a sample point falls
    exactly on a point at the boundary of the array. Provided the calling
    routine has done appropriate checks, the problem will only arise
    for the last point in each row and the last row (of the output array)
    processed. These points are therefore handled as separate cases. The
    tests are not needed in the bulk of the array and would slow down the
    routine if made for every point. */

    float       *in_2d;
    int         in_xsize, in_ysize;
    float       *out_2d;
    int         out_xsize;
    int         out_xstart, out_xend, out_ystart, out_yend;
    float       in_xstart, in_ystart, Txx, Txy, Tyx, Tyy;

{
    float   *outslow, *outslow_max, *outfast, *outfast_max, *in_pos;
    float   xstart, ystart, x, y, xrem, xremc, yrem, yremc, xa, xb;
    int     xdo = out_xend - out_xstart,
            xsp1 = in_xsize + 1;
    int     xint, yint;
    float   tolx = 1.0e-5 * xdo,
            toly = 1.0e-5 * (out_yend - out_ystart);

for (outslow        =   out_2d + (out_xsize * out_ystart + out_xstart),
     outslow_max    =   out_2d + (out_xsize * out_yend + out_xstart),
     xstart         =   in_xstart,
     ystart         =   in_ystart;

     outslow        <   outslow_max;    /* stop before last line */

     outslow        +=  out_xsize,
     xstart         +=  Txy,
     ystart         +=  Tyy) {

    for (outfast        =   outslow,
         outfast_max    =   outfast + xdo,
         x              =   xstart,     xint = x,   xrem = x - xint,
         y              =   ystart,     yint = y,   yrem = y - yint;

         outfast        <   outfast_max; /* stop before last pt */

         outfast++,
         x              +=  Txx,        xint = x,   xrem = x - xint,
         y              +=  Tyx,        yint = y,   yrem = y - yint) {

        xremc = 1.0 - xrem;
        in_pos = in_2d + yint * in_xsize + xint;
        *outfast = (1.0 - yrem) * (xremc * *in_pos + xrem * *(in_pos+1))
         + yrem * (xremc * *(in_pos+in_xsize) + xrem * *(in_pos+xsp1));
        }

    /* Do last point separately, as accumulation of rounding errors
       can take us outside array if not trapped. */
    xremc = 1.0 - xrem;
    in_pos = in_2d + yint * in_xsize + xint;
    if (xrem < tolx)       {xa = *in_pos;     xb = *(in_pos+in_xsize); }
    else if (xremc < tolx) {xa = *(in_pos+1); xb = *(in_pos+xsp1); }
    else {
        xa = xremc * *in_pos + xrem * *(in_pos+1);
        xb = xremc * *(in_pos+in_xsize) + xrem * *(in_pos+xsp1); };
    *outfast = (1.0 - yrem) * xa + yrem * xb;
    }

/* Do last line separately for same reason */
for (outfast        =   outslow,
     outfast_max    =   outfast + xdo,
     x              =   xstart,     xint = x,   xrem = x - xint,
     y              =   ystart,     yint = y,   yrem = y - yint;

     outfast        <   outfast_max; /* stop before last pt */

     outfast++,
     x              +=  Txx,        xint = x,   xrem = x - xint,
     y              +=  Tyx,        yint = y,   yrem = y - yint) {

    xremc = 1.0 - xrem;
    yremc = 1.0 - yrem;
    in_pos = in_2d + yint * in_xsize + xint;
    if (yrem < toly)
        *outfast = xremc * *in_pos + xrem * *(in_pos+1);
    else if (yremc < toly)
        *outfast = xremc * *(in_pos+in_xsize) + xrem * *(in_pos+xsp1);
    else
        *outfast = (1.0 - yrem) * (xremc * *in_pos + xrem * *(in_pos+1))
         + yrem * (xremc * *(in_pos+in_xsize) + xrem * *(in_pos+xsp1));
    }

/* And finally the very last point */
xremc = 1.0 - xrem;
yremc = 1.0 - yrem;
in_pos = in_2d + yint * in_xsize + xint;
if (yrem < toly) {
    if (xrem < tolx) *outfast = *in_pos;
    else if (xremc < tolx) *outfast = *(in_pos+1);
    else *outfast = xremc * *in_pos + xrem * *(in_pos+1); }
else if (yremc < toly) {
    if (xrem < tolx) *outfast = *(in_pos+in_xsize);
    else if (xremc < tolx) *outfast = *(in_pos+xsp1);
    else *outfast = xremc * *(in_pos+in_xsize) + xrem * *(in_pos+xsp1); }
else {
    if (xrem < tolx)       {xa = *in_pos;     xb = *(in_pos+in_xsize); }
    else if (xremc < tolx) {xa = *(in_pos+1); xb = *(in_pos+xsp1); }
    else {
        xa = xremc * *in_pos + xrem * *(in_pos+1);
        xb = xremc * *(in_pos+in_xsize) + xrem * *(in_pos+xsp1); };
    *outfast = (1.0 - yrem) * xa + yrem * xb; }

}

void warp_lc_f (
    in_2d,
    in_xsize, in_ysize,
    out_2d,
    out_xsize,
    out_xstart, out_xend, out_ystart, out_yend,
    in_xstart, in_ystart, Txx, Txy, Tyx, Tyy
    )

    /* Like warp_l_f but checks every point for whether it is inside
    input array and does nothing if it is not. The possibility of
    appearing to go outside because of rounding is checked for each
    outside point - not absolutely the fastest thing but pretty
    close. */

    float       *in_2d;
    int         in_xsize, in_ysize;
    float       *out_2d;
    int         out_xsize;
    int         out_xstart, out_xend, out_ystart, out_yend;
    float       in_xstart, in_ystart, Txx, Txy, Tyx, Tyy;

{
    float   *outslow, *outslow_max, *outfast, *outfast_max, *in_pos;
    float   xstart, ystart, x, y, xrem, xremc, yrem, yremc, xa, xb;
    int     xdo = out_xend - out_xstart,
            xsp1 = in_xsize + 1,
            xsm1 = in_xsize - 1,
            ysm1 = in_ysize - 1;
    int     xint, yint;
    float   tolx = 1.0e-5 * xdo,
            toly = 1.0e-5 * (out_yend - out_ystart);

for (outslow        =   out_2d + (out_xsize * out_ystart + out_xstart),
     outslow_max    =   out_2d + (out_xsize * out_yend + out_xstart),
     xstart         =   in_xstart,
     ystart         =   in_ystart;

     outslow        <=  outslow_max;    /* stop before last line */

     outslow        +=  out_xsize,
     xstart         +=  Txy,
     ystart         +=  Tyy)

    for (outfast        =   outslow,
         outfast_max    =   outfast + xdo,
         x              =   xstart,
         y              =   ystart;

         outfast        <=  outfast_max; /* stop before last pt */

         outfast++,
         x              +=  Txx,
         y              +=  Tyx) {

        xint = x;       xrem = x - xint;        xremc = 1.0 - xrem;
        yint = y;       yrem = y - yint;        yremc = 1.0 - yrem;
        if (xint >= 0 && xint < xsm1 && yint >= 0 && yint < ysm1) {
            in_pos = in_2d + yint * in_xsize + xint;
            *outfast = yremc * (xremc * *in_pos + xrem * *(in_pos+1))
            + yrem * (xremc * *(in_pos+in_xsize) + xrem * *(in_pos+xsp1));
            }
        else { /* could be just due to rounding - check and try again */
            if (xint == -1 && xremc < tolx)
                { xint = 0; xrem = 0.0; xremc = 1.0; }
            else if (xint == xsm1 && xrem < tolx)
                { xint = xsm1-1; xrem = 1.0; xremc = 0.0; };
            if (yint == -1 && yremc < toly)
                { yint = 0; yrem = 0.0; yremc = 1.0; }
            else if (yint == ysm1 && yrem < toly)
                { yint = ysm1-1; yrem = 1.0; yremc = 0.0; };
            if (xint >= 0 && xint < xsm1 && yint >= 0 && yint < ysm1) {
                in_pos = in_2d + yint * in_xsize + xint;
                *outfast = yremc * (xremc * *in_pos + xrem * *(in_pos+1))
                         + yrem *
                    (xremc * *(in_pos+in_xsize) + xrem * *(in_pos+xsp1));
                }
            }
        }
}
