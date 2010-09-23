/* --- Copyright University of Sussex 2003. All rights reserved. ----------
 * File:            $popvision/lib/logsample.c
 * Purpose:         Support for LIB * LOGSAMPLE
 * Author:          David S Young, Jul 28 1994 (see revisions)
 * Documentation:   HELP * LOGSAMPLE
 * Related Files:   LIB * LOGSAMPLE
 */

/* Resampling between conventional and log-polar images. The LP image
is always an array of single floats. The input conventional image can
be single floats or bytes. Most of the routines are duplicated to allow
this to be done efficiently - to avoid making the source long, each
routine is declared as a macro then expanded in a float and byte
version. */

#include <math.h>

static int ifloor(float x)
/* Rounding floats to ints towards negative infinity */
{
    int y = x;
    return (x < 0.0 && y != x ? y-1 : y);
}


static int nint(float x)
/* Returns nearest integer to a given float */
{ return ((int) (x > 0.0 ? x + 0.5 : x - 0.5)); }


static int imax(int i, int j)
{ return(i > j ? i : j); }


static int imin(int i, int j)
{ return(i < j ? i : j); }


/* Constants for gval*/

#define gval_range 2.5      /* Go this many sigmas each side */
#define recsq2 0.7071068    /* 1/sqrt(2) */


#define GVAL(SUFFIX, ARRTYPE)                                                \
float gval ## SUFFIX (int xsize, int ysize, ARRTYPE *arr, int xdim,          \
           float x, float y, float sigma)                                    \
/* Inner product of the values in arr with a Gaussian mask of width          \
sigma centred on x, y, with exact interpolation built in, so slow.  */       \
{                                                                            \
    float       ax, ax1, ay, aysq, wid, k, snorm, sum, g;                    \
    int         x0, x1, y0, y1, ix, iy;                                      \
                                                                             \
    wid     = gval_range * sigma + 1.0;                                      \
    x0      = imax(0, nint(x - wid));                                        \
    x1      = imin(xsize-1, nint(x + wid));                                  \
    y0      = imax(0, nint(y - wid));                                        \
    y1      = imin(ysize-1, nint(y + wid));                                  \
                                                                             \
    if (y1 < y0 || x1 < x0) return(0.0);                                     \
                                                                             \
    k       = recsq2 / sigma;                                                \
    ay      = k * (y0 - y);                                                  \
    ax1     = k * (x0 - x);                                                  \
    snorm   = 0.0;                                                           \
    sum     = 0.0;                                                           \
                                                                             \
    for (iy = y0;    iy <= y1;   iy++, ay += k) {                            \
        ax = ax1;                                                            \
        aysq = ay * ay;                                                      \
        for (ix = x0;   ix <= x1;   ix++, ax += k) {                         \
            g = exp(-(ax * ax + aysq));                                      \
            sum += g * *(arr + iy*xdim + ix);                                \
            snorm += g;                                                      \
        }                                                                    \
    }                                                                        \
    return (sum / snorm);                                                    \
}
GVAL(f, float)
GVAL(b, unsigned char)


#define RESAMP_G(SUFFIX, ARRTYPE)                                            \
void resamp_g ## SUFFIX                                                      \
             (int xsize, int ysize, ARRTYPE *arrin, int offin, int xdimin,   \
              int nr,    int nw,    float *arrout, int offout, int xdimout,  \
              float rmin, float rmax, float xc, float yc,                    \
              float ratp, float ratn, float minsig, float sigwin,            \
              float *costab, float *sintab)                                  \
/*                                                                           \
Resample an image in arrin to arrout, going out to radius rmax,              \
centering on (xc, yc), using Gaussian receptive fields.                      \
                                                                             \
Output has nr rings and nw wedges.                                           \
                                                                             \
In each case the sizes and offsets specify the valid input and output        \
data regions, as set up in *EXT2D_ARGS.  (xc, yc) is relative to the         \
first point in the input data region.                                        \
                                                                             \
The sample can be got using a Gaussian of sigma ratp*(the                    \
separation between sample points) and ratn set negative or                   \
as a difference of Gaussians using ratn to set the size of the               \
negative Gaussian. However if minsig is greater than 0 then                  \
neither sigma is allowed to drop below minsig (assuming ratn                 \
bigger than ratp).                                                           \
                                                                             \
If sigwin is greater than zero then the image is multiplied by               \
a Gaussian window of width sigwin before transforming.                       \
*/                                                                           \
{                                                                            \
    int     xout, yout;                                                      \
    float   rinc, r, rsep, winden, x, y, window, sigmap, sigman, val,        \
            *cptr, *sptr;                                                    \
                                                                             \
    rinc = pow(rmax/rmin, 1.0/(nr - 1));                                     \
    rsep = rinc - 1.0;                                                       \
    r = rmin;                                                                \
    winden = 2.0 * sigwin * sigwin;                                          \
                                                                             \
    arrin = arrin + offin;                                                   \
    arrout = arrout + offout;                                                \
                                                                             \
    for (xout = 0;      xout < nr;      xout++, r *= rinc) {                 \
        cptr = costab;                                                       \
        sptr = sintab;                                                       \
        sigmap = ratp * r * rsep;                                            \
        if (minsig > 0.0 && sigmap < minsig) sigmap = minsig;                \
        sigman = sigmap * (ratn / ratp);                                     \
        window = sigwin > 0.0 ? exp(-((r*r)/winden)) : 1.0;                  \
                                                                             \
        for (yout = 0;  yout < nw;      yout++) {                            \
            x = r * *cptr++ + xc;                                            \
            y = r * *sptr++ + yc;                                            \
            val = gval ## SUFFIX                                             \
                      (xsize, ysize, arrin, xdimin, x, y, sigmap);           \
            if (sigman > 0.0)                                                \
                val -= gval ## SUFFIX                                        \
                           (xsize, ysize, arrin, xdimin, x, y, sigman);      \
            *(arrout + xdimout*yout + xout) = window * val;                  \
        }                                                                    \
    }                                                                        \
}
RESAMP_G(f, float)
RESAMP_G(b, unsigned char)


#define RESAMP_N(SUFFIX, ARRTYPE)                                            \
void resamp_n ## SUFFIX                                                      \
             (int xsize, int ysize, ARRTYPE *arrin, int offin, int xdimin,   \
              int nr,    int nw,    float *arrout, int offout, int xdimout,  \
              float rmin, float rmax, float xc, float yc, float sigwin,      \
              float *costab, float *sintab)                                  \
/*                                                                           \
Like resamp_g but using nearest data point.                                  \
*/                                                                           \
{                                                                            \
    int     x, y, xout, yout;                                                \
    float   rinc, r, winden, window, val,                                    \
            *cptr, *sptr, *aoutx, *aouty;                                    \
                                                                             \
    rinc = pow(rmax/rmin, 1.0/(nr - 1));                                     \
    r = rmin;                                                                \
    winden = 2.0 * sigwin * sigwin;                                          \
                                                                             \
    arrin = arrin + offin;                                                   \
    aoutx = arrout + offout;                                                 \
                                                                             \
    for (xout = 0;      xout < nr;      xout++, aoutx++, r *= rinc) {        \
        cptr = costab;                                                       \
        sptr = sintab;                                                       \
        aouty = aoutx;                                                       \
                                                                             \
        if (sigwin > 0.0) {                                                  \
            window = exp(-((r*r)/winden));                                   \
            for (yout = 0;  yout < nw;      yout++, aouty += xdimout) {      \
                x = nint(r * *cptr++ + xc);                                  \
                y = nint(r * *sptr++ + yc);                                  \
                *aouty = window * *(arrin + xdimin*y + x);                   \
            }                                                                \
        }                                                                    \
        else                                                                 \
            for (yout = 0;  yout < nw;      yout++, aouty += xdimout) {      \
                x = nint(r * *cptr++ + xc);                                  \
                y = nint(r * *sptr++ + yc);                                  \
                *aouty = *(arrin + xdimin*y + x);                            \
            }                                                                \
    }                                                                        \
}
RESAMP_N(f, float)
RESAMP_N(b, unsigned char)


#define INTER4(SUFFIX, ARRTYPE)                                              \
float inter4 ## SUFFIX                                                       \
            (float xrem, float yrem,                                         \
             ARRTYPE axy, ARRTYPE ax1y, ARRTYPE axy1, ARRTYPE ax1y1)         \
/* Bilinear interpolation between 4 neighbours*/                             \
{                                                                            \
    float yremc;                                                             \
                                                                             \
    yremc = 1.0 - yrem;                                                      \
    return(        xrem  * (yrem * ax1y1 + yremc * ax1y)                     \
          + (1.0 - xrem) * (yrem * axy1  + yremc * axy));                    \
}
INTER4(f, float)
INTER4(b, unsigned char)


#define CIRCLEAV(SUFFIX, ARRTYPE, SUMTYPE)                                   \
float circleav ## SUFFIX(ARRTYPE *arr, int xdim, int x, int y, int rad)      \
/*                                                                           \
Returns the average value in a roughly circular region of an array.          \
*/                                                                           \
{                                                                            \
    /* Table avoids taking sqrts for small circles */                        \
    static const int tabsize          = 10,                                  \
                     builtins[10][8]  = {                                    \
                                            { 0, 0, 0, 0, 0, 0, 0, 0, },     \
                                            { 0, 0, 0, 0, 0, 0, 0, 0, },     \
                                            { 0, 2, 0, 0, 0, 0, 0, 0, },     \
                                            { 0, 3, 2, 0, 0, 0, 0, 0, },     \
                                            { 0, 4, 3, 3, 0, 0, 0, 0, },     \
                                            { 0, 5, 5, 4, 3, 0, 0, 0, },     \
                                            { 0, 6, 6, 5, 4, 3, 0, 0, },     \
                                            { 0, 7, 7, 6, 6, 5, 4, 0, },     \
                                            { 0, 8, 8, 7, 7, 6, 5, 0, },     \
                                            { 0, 9, 9, 8, 8, 7, 7, 6, },     \
                                        };                                   \
    SUMTYPE sum;                                                             \
    float   rsq;                                                             \
    int     n, r, rstart, rend;                                              \
                                                                             \
    rsq = rad * rad;                                                         \
                                                                             \
    sum = *(arr + xdim*y + x);      /* middle point */                       \
    n = 1;                                                                   \
                                                                             \
    for (r = 1;     r <= rad;   r++) {      /* rest of central cross */      \
        sum += *(arr + xdim*(y+r) + x) + *(arr + xdim*(y-r) + x)             \
            +  *(arr + xdim*y + (x+r)) + *(arr + xdim*y + (x-r));            \
        n += 4;                                                              \
    }                                                                        \
                                                                             \
    for (rstart = 1;    rstart <= rad;   rstart++) {  /* go out along */     \
        rend = rad < tabsize ?                        /* diagonals    */     \
                builtins[rad][rstart] :                                      \
                sqrt(rsq - rstart*rstart) + 0.5;                             \
                                                                             \
        if (rend < rstart) break;           /* finished */                   \
                                                                             \
        sum +=              /* four points on diagonal cross */              \
            *(arr + xdim*(y+rstart) + (x+rstart)) +                          \
            *(arr + xdim*(y+rstart) + (x-rstart)) +                          \
            *(arr + xdim*(y-rstart) + (x+rstart)) +                          \
            *(arr + xdim*(y-rstart) + (x-rstart));                           \
            n += 4;                                                          \
                                                                             \
        for (r = rstart+1;  r <= rend;  r++) {    /* fill in octants */      \
            sum +=                                                           \
                *(arr + xdim*(y+rstart) + (x+r)) +                           \
                *(arr + xdim*(y+rstart) + (x-r)) +                           \
                *(arr + xdim*(y-rstart) + (x+r)) +                           \
                *(arr + xdim*(y-rstart) + (x-r)) +                           \
                *(arr + xdim*(y+r) + (x+rstart)) +                           \
                *(arr + xdim*(y+r) + (x-rstart)) +                           \
                *(arr + xdim*(y-r) + (x+rstart)) +                           \
                *(arr + xdim*(y-r) + (x-rstart));                            \
            n += 8;                                                          \
        }                                                                    \
    }                                                                        \
    return ((float) sum / n);                                                \
}
CIRCLEAV(f, float, float)
CIRCLEAV(b, unsigned char, int)


/* Constant for smoothval */

#define smoothval_maxrad 2      /* Biggest radius for interpolation */

#define SMOOTHVAL(SUFFIX, ARRTYPE)                                           \
float smoothval ## SUFFIX                                                    \
               (int xsize, int ysize, ARRTYPE *arr, int xdim,                \
                float x, float y, float rad)                                 \
/*                                                                           \
Samples arr at the point (x, y) using simple interpolation between           \
nearest 4 data points or averaging over a circular region, depending         \
on how big rad is. A compromise between high-quality Gaussian                \
interpolation and fast nearest neighbour.                                    \
*/                                                                           \
{                                                                            \
    int     irad, ix, ixp1, iy, iyp1;                                        \
                                                                             \
    irad = rad;                                                              \
                                                                             \
    if (irad < smoothval_maxrad) {  /* If true, interpolate, else average */ \
        ix = ifloor(x);                                                      \
        iy = ifloor(y);                                                      \
        ixp1 = ix + 1;                                                       \
        iyp1 = iy + 1;                                                       \
                                                                             \
        if (ix < 0 || iy < 0 || ixp1 >= xsize || iyp1 >= ysize)              \
            return(0.0);                                                     \
                                                                             \
        return(inter4 ## SUFFIX( x-ix,    y-iy,                              \
            *(arr + xdim*iy + ix),      *(arr + xdim*iy + ixp1),             \
            *(arr + xdim*iyp1 + ix),    *(arr + xdim*iyp1 + ixp1)));         \
    }                                                                        \
    else {                  /* average */                                    \
        ix = nint(x);       /* use nearest, not rounded down */              \
        iy = nint(y);                                                        \
        if (ix-irad < 0 || iy-irad < 0                                       \
            || ix+irad >= xsize || iy + irad >= ysize) return(0.0);          \
                                                                             \
        return(circleav ## SUFFIX(arr, xdim, ix, iy, irad));                 \
    }                                                                        \
}
SMOOTHVAL(f, float)
SMOOTHVAL(b, unsigned char)


#define RESAMP_S(SUFFIX, ARRTYPE)                                            \
void resamp_s ## SUFFIX                                                      \
             (int xsize, int ysize, ARRTYPE *arrin, int offin, int xdimin,   \
              int nr,    int nw,    float *arrout, int offout, int xdimout,  \
              float rmin, float rmax, float xc, float yc, float sigwin,      \
              float *costab, float *sintab)                                  \
/*                                                                           \
Like resamp_g but using interpolation or averaging.                          \
*/                                                                           \
{                                                                            \
    int     xout, yout;                                                      \
    float   x, y, rinc, r, rad, rrad, winden, window, val,                   \
            *cptr, *sptr, *aoutx, *aouty;                                    \
                                                                             \
    rinc = pow(rmax/rmin, 1.0/(nr - 1));                                     \
    rrad = 0.5 * (rinc - 1.0);                                               \
    r = rmin;                                                                \
    winden = 2.0 * sigwin * sigwin;                                          \
                                                                             \
    arrin = arrin + offin;                                                   \
    aoutx = arrout + offout;                                                 \
                                                                             \
    for (xout = 0;      xout < nr;      xout++, aoutx++, r *= rinc) {        \
        cptr = costab;                                                       \
        sptr = sintab;                                                       \
        rad = r * rrad;                                                      \
        aouty = aoutx;                                                       \
                                                                             \
        if (sigwin > 0.0) {                                                  \
            window = exp(-((r*r)/winden));                                   \
            for (yout = 0;  yout < nw;      yout++, aouty += xdimout) {      \
                x = r * *cptr++ + xc;                                        \
                y = r * *sptr++ + yc;                                        \
                *aouty = window *                                            \
                    smoothval(xsize, ysize, arrin, xdimin, x, y, rad);       \
            }                                                                \
        }                                                                    \
        else                                                                 \
            for (yout = 0;  yout < nw;      yout++, aouty += xdimout) {      \
                x = r * *cptr++ + xc;                                        \
                y = r * *sptr++ + yc;                                        \
                *aouty = smoothval ## SUFFIX                                 \
                                  (xsize, ysize, arrin, xdimin, x, y, rad);  \
            }                                                                \
    }                                                                        \
}
RESAMP_S(f, float)
RESAMP_S(b, unsigned char)


float interp_wrap(int xsize, int ysize, float *arr, int xdim,
                  float x, float y)
/*
Like smoothval, but only interpolates and wraps round on the y-axis.
*/
{
    int     irad, ix, ixp1, iy, iyp1;
    float   yrem;

    ix = ifloor(x);
    iy = ifloor(y);
    ixp1 = ix + 1;
    iyp1 = iy + 1;
    yrem = y - iy;

    /* Wrap round */
    if (iyp1 == 0) iy = ysize - 1;
    else if (iyp1 == ysize) iyp1 = 0;

    /* Assume this check effectively done in caller ...
    if (ix < 0 || iy < 0 || ixp1 >= xsize || iyp1 >= ysize)
        return(0.0);
    */

    return(inter4f( x-ix,    yrem,
        *(arr + xdim*iy + ix),      *(arr + xdim*iy + ixp1),
        *(arr + xdim*iyp1 + ix),    *(arr + xdim*iyp1 + ixp1)));
}



void desamp(int nr,    int nw,    float *arrin,  int offin,  int xdimin,
            int xsize, int ysize, float *arrout, int offout, int xdimout,
            float rmin, float rmax, float xc, float yc)
/*
Approximate inverse of log-sampling routines.
Uses simple interpolation only, wrapping round correctly on the
wedge axis.
*/
{
    static const float  rtwopi = 0.5 / 3.141593;
    int         x, y, xstart, xend, ystart, yend;
    float       nrm1, fnw, c1, c2, c3, xoff, xoffsq, yoff, rs, xin, yin;

    nrm1 = nr - 1;
    fnw = nw;
    c1 = nrm1 / (2.0 * log(rmax/rmin));
    c2 = 2.0 * c1 * log(rmin);
    c3 = fnw * rtwopi;

    xstart = imax(0, ifloor(xc-rmax));
    xend   = imin(xsize-1, ifloor(xc+rmax)+1);
    ystart = imax(0, ifloor(yc-rmax));
    yend   = imin(ysize-1, ifloor(yc+rmax)+1);

    arrin = arrin + offin;
    arrout = arrout + offout;

    for (x = xstart;  x <= xend;    x++) {
        xoff = x - xc;
        xoffsq = xoff * xoff;

        for (y = ystart;    y <= yend;  y++) {
            yoff = y - yc;
            rs = xoffsq + yoff*yoff;
            xin = rs > 0.0 ? c1 * log(rs) - c2 : -1.0;
            if (xin > 0.0 && xin < nrm1) {
                yin = c3 * atan2(yoff, xoff);
                if (yin < 0.0) yin = yin + fnw;
                *(arrout + xdimout*y + x) =
                    interp_wrap(nr, nw, arrin, xdimin, xin, yin);
            }
        }
    }
}

/* --- Revision History ---------------------------------------------------
--- David Young, Nov  5 2003
        Declared utility functions ifloor etc. as static.
--- David Young, Mar  2 2000
        Moved from Sussex local vision libraries to popvision.
--- David S Young, Nov 16 1994
        Routines for byte array inputs added.
 */
