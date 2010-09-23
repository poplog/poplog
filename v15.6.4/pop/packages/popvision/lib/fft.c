/* --- Copyright University of Sussex 2001. All rights reserved. ----------
 * File:            $popvision/lib/fft.c
 * Purpose:         Support for Fast Fourier Transforms
 * Author:          David S Young, Sep 24 1997 (see revisions)
 * Documentation:   HELP * FFT
 * Related Files:   $popvision/lib/fft.p
 */

#include <math.h>

void rev_subvector(int s_sub, float *s_vec,
                   int d_sub, float *d_vec, int N, int revsgn)
/* Copies the N components of the array s_vec ending at subscript
s_sub in reverse to the components of d_vec starting at subscript
d_sub, so that d_vec[d_sub+i] = s_vec[s_sub-i] */
{
    s_vec = s_vec + s_sub;
    d_vec = d_vec + d_sub;
    if (revsgn)
        for ( ; N; N--) *d_vec++ = -*s_vec--;
    else
        for ( ; N; N--) *d_vec++ = *s_vec--;
}

void negate_region(int xsize, int ysize, float *vec, int offset, int xdim)
/* Negates in place each element in a 2-D region of an array */
{
    float *vs, *vsm, *vf, *vfm;
    for (vs = vec+offset, vsm = vs + ysize*xdim;
         vs < vsm;
         vs += xdim)
        for (vf = vs, vfm = vf + xsize;
             vf < vfm;
             vf++)
            *vf = -*vf;
}

void multiply_region(float f, int xsize, int ysize,
                     float *vec, int offset, int xdim)
/* Multiplies by f, in place, each element in a 2-D region of an array */
{
    float *vs, *vsm, *vf, *vfm;
    for (vs = vec+offset, vsm = vs + ysize*xdim;
         vs < vsm;
         vs += xdim)
        for (vf = vs, vfm = vf + xsize;
             vf < vfm;
             vf++)
            *vf *= f;
}

int fft1pow2(int isign, int n, int inc,
    int rstart, float *datrarr, int istart, float *datiarr)
/*
1-D FFT for data lengths a power of 2. Based on code in "Numerical
Recipes in C" by W.H. Press, B.P. Flannery, S.A. Teukolsky and W.T.
Vetterling (CUP 1988), p. 411. Modifications are:
    a)  starting point of data in arrays is arbitrary - internally,
        arrays are treated as zero-based;
    b)  real and imaginary parts are passed in separate arrays;
    c)  data can be spread out rather than contiguous in the arrays,
        with a fixed gap between successive data points;
    d)  checks that n is in fact a power of 2, and that other
        integer arguments are sensible,
    e)  does 1/N normalisation on the forward transform.

Arguments are:
    isign:  the direction of the transform,
    n:      the number of data points. MUST be a power of 2;
    inc:    the interval between data points in the arrays. The i'th data
            point in any of the arrays is at an offset of i*inc;
    rstart: the offset of the start of data in datrarr;
    datrarr:the real part of the data;
    istart: the offset of the start of data in datiarr;
    datiarr:the imaginary part of the data.
Result is
    1 if n not a power of 2,
    2 if inc negative,
    3 if isign not plus or minus 1,
    otherwise 0,
and no operations are carried out on the data unless result is 0.
*/
{
    int     ninc = n * inc,
            nincd2 = ninc >> 1,
            i, j, m, mmax, istep, incdir;
    float   temp, tempr, tempi,
            *datr = datrarr + rstart,    /* zero-based arrays */
            *dati = datiarr + istart;
    double  wtemp, wr, wpr, wpi, wi, theta;

    /* Check that n is a power of 2, etc. */
    if (!n) return 0;
    for (m = n; !(m & 1); m >>= 1);
    if (m != 1) return 1;
    if (inc <= 0) return 2;
    if (isign != 1 && isign != -1) return 3;

    /* Bit-swapped reordering */
    j = 0;
    for (i = 0; i < ninc; i += inc) {
        if (j > i) {
            temp = datr[i]; datr[i] = datr[j]; datr[j] = temp;
            temp = dati[i]; dati[i] = dati[j]; dati[j] = temp;
        }
        m = nincd2;
        while (j >= m && m > 0) {
            j -= m;
            m >>= 1;
        }
        j += m;
    }

    /* Danielson-Lanczos recurrence */
    mmax = inc;
    incdir = isign * inc;
    while (ninc > mmax) {
        istep = mmax << 1;
        theta = 6.28318530717959 / (istep/incdir);
        wtemp = sin(0.5 * theta);
        wpr = -2.0 * wtemp * wtemp;
        wpi = sin(theta);
        wr = 1.0;
        wi = 0.0;
        for (m = 0; m < mmax; m += inc) {
            for (i = m; i < ninc; i += istep) {
                j = i + mmax;
                tempr = wr * datr[j] - wi * dati[j];
                tempi = wr * dati[j] + wi * datr[j];
                datr[j] = datr[i] - tempr;
                dati[j] = dati[i] - tempi;
                datr[i] += tempr;
                dati[i] += tempi;
            }
            wr = (wtemp = wr)*wpr - wi*wpi + wr;
            wi = wi*wpr + wtemp*wpi + wi;
        }
        mmax = istep;
    }

    /* Normalisation */
    if (isign == 1) {
        temp = 1.0/n;
        for (i = 0; i < ninc; i += inc) {
            datr[i] *= temp;
            dati[i] *= temp;
        }
    }

    return 0;
}

int fft1pow2rf(int n, int rstarti, float *datrarri,
                int rstarto, float *datrarro, int istarto, float *datiarro)
/*
Forward 1-D FFT for real data, length a power of 2.
Based on code in "Numerical Recipes in C" by W.H. Press, B.P. Flannery, S.A.
Teukolsky and W.T. Vetterling (CUP 1988), p. 417.
Assumes data contiguous.
*/
{
    int     nd2 = n/2,
            nd4 = nd2/2,
            i, j, i1, i2;
    float   temp, t1, t2, h1r, h1i, h2r, h2i,
            *datri = datrarri + rstarti,    /* zero-based arrays */
            *datro = datrarro + rstarto,
            *datio = datiarro + istarto;
    double  wtemp, wr, wpr, wpi, wi, theta;

    /* Check that n is even or 1. Other checks done in fft1pow2 */
    if (!n) return 0;
    if (n == 1) {
        datro[0] = datri[0];
        datio[0] = 0.0;
        return 0;
    }
    if (n != 2*nd2) return 1;

    /* Copy data from real input to output arrays, alternating points */
    for (i=0, j=0; i < nd2; i++) {
        datro[i] = datri[j++];
        datio[i] = datri[j++];
    }

    /* Do half-length fft in place */
    i = fft1pow2(1, nd2, 1, 0, datro, 0, datio);
    if (i) return i;

    /* Initialise recurrence */
    theta = 6.28318530717959 /(double) n;
    wtemp = sin(0.5 * theta);
    wpr = -2.0 * wtemp * wtemp;
    wpi = sin(theta);
    wr = 1.0 + wpr;
    wi = wpi;

    /* Do final missing stage of FFT, including normalisation */
    i1 = 1;
    i2 = nd2-1;
    while (i1 < nd4) {
        h1r =  0.25*(datro[i1]+datro[i2]);
        h1i =  0.25*(datio[i1]-datio[i2]);
        h2r =  0.25*(datio[i1]+datio[i2]);
        h2i =  0.25*(datro[i2]-datro[i1]);
        t1 = wr*h2r - wi*h2i;
        t2 = wr*h2i + wi*h2r;
        datro[i1] =  h1r + t1;
        datio[i1] =  h1i + t2;
        datro[i2] =  h1r - t1;
        datio[i2] = -h1i + t2;
        wr = (wtemp = wr)*wpr - wi*wpi + wr;
        wi = wi*wpr + wtemp*wpi + wi;
        i1++;
        i2--;
    }
    if (nd4) {
        datro[nd4] *= 0.5;     /* Normalise middle point */
        datio[nd4] *= 0.5;
    }
    datro[0] = 0.5 * ((h1r=datro[0]) + (h1i=datio[0]));
    datio[0] = 0.0;
    datro[nd2] = 0.5 * (h1r - h1i);
    datio[nd2] = 0.0;

    return 0;
}

int fft1pow2rb(int n,
        int rstarti, float *datrarri, int istarti, float *datiarri,
        int rstarto, float *datrarro)
/*
Backward 1-D FFT for real data, length a power of 2.
Based on code in "Numerical Recipes in C" by W.H. Press, B.P. Flannery, S.A.
Teukolsky and W.T. Vetterling (CUP 1988), p. 417.
Do not need factor of 1/2 which appears there, because inverse fft is
already operating on half-length data.
*/
{
    int     nd2 = n/2,
            nd4 = nd2/2,
            i, i1, i2, i3, i4;
    float   temp, t1, t2, h1r, h1i, h2r, h2i,
            *datri = datrarri + rstarti,    /* zero-based arrays */
            *datii = datiarri + istarti,
            *datro = datrarro + rstarto;
    double  wtemp, wr, wpr, wpi, wi, theta;

    /* Check that n is even or 1. Other checks done in fft1pow2 */
    if (!n) return 0;
    if (n == 1) {
        datro[0] = datri[0];
        return 0;
    }
    if (n != 2*nd2) return 1;

    /* Initialise recurrence */
    theta = -6.28318530717959 /(double) n;
    wtemp = sin(0.5 * theta);
    wpr = -2.0 * wtemp * wtemp;
    wpi = sin(theta);
    wr = 1.0 + wpr;
    wi = wpi;

    /* Perform preliminary step of fft, copying data from complex
    input arrays to alternating points in output array. */
    i1 = 1;
    i2 = nd2-1,
    i3 = 2,
    i4 = n-2;
    while (i1 < nd4) {
        h1r =  datri[i1]+datri[i2];
        h1i =  datii[i1]-datii[i2];
        h2r = -datii[i1]-datii[i2];
        h2i =  datri[i1]-datri[i2];
        t1 = wr*h2r - wi*h2i;
        t2 = wr*h2i + wi*h2r;
        datro[i3]     =  h1r + t1;
        datro[i3+1]   =  h1i + t2;
        datro[i4]     =  h1r - t1;
        datro[i4+1]   = -h1i + t2;
        wr = (wtemp = wr)*wpr - wi*wpi + wr;
        wi = wi*wpr + wtemp*wpi + wi;
        i1++;
        i2--;
        i3 += 2;
        i4 -= 2;
    }
    datro[nd2] = 2.0 * datri[nd4];
    datro[nd2+1] = 2.0 * datii[nd4];
    datro[0]   = datri[0]+datri[nd2];
    datro[1] = datri[0]-datri[nd2];

    /* Do rest of fft in place */
    fft1pow2(-1, nd2, 2, 0, datro, 1, datro);

    return 0;
}

int fft1pow2mult(int isign, int p, int pinc, int n, int ninc,
    int rstart, float *datrarr, int istart, float *datiarr)
/*
Multiple 1-D FFT for data lengths a power of 2.
See comments for fft1pow2. Arguments in common have same meanings for
each individual transform. Additional arguments are:
    p:      the number of transforms to do;
    pinc:   the increment between corresponding data points in the
            array.
This is equivalent to calling fft1pow2 for each row or col of an
array, but is more efficient since trigonometric calculations are
not repeated. Also innermost loops use pointer arithmetic rather than
array subscripting - may give a small speedup.
*/
{
    int     nninc = n * ninc,
            nincd2 = nninc >> 1,
            ppinc = p * pinc,
            i, j, m, mmax, istep, incdir;
    float   temp, tempr, tempi,
            *datr = datrarr + rstart,
            *dati = datiarr + istart,
            *dri, *drj, *dii, *dij, *dstop;
    double  wtemp, wr, wpr, wpi, wi, theta;

    /* Check that n is a power of 2, etc. */
    if (!n || !p) return 0;
    for (m = n; !(m & 1); m >>= 1);
    if (m != 1) return 1;
    if (ninc <= 0) return 2;
    if (isign != 1 && isign != -1) return 3;
    if (p < 0 || pinc <= 0) return 4;

    /* Bit-swapped reordering */
    j = 0;
    for (i = 0; i < nninc; i += ninc) {
        if (j > i)
            for (dri = datr+i, drj = datr+j, dii = dati+i, dij = dati+j,
                    dstop = dri + ppinc;
                 dri < dstop;
                 dri += pinc, drj += pinc, dii += pinc, dij += pinc) {
                temp = *dri; *dri = *drj; *drj = temp;
                temp = *dii; *dii = *dij; *dij = temp;
            }
        m = nincd2;
        while (j >= m && m > 0) {
            j -= m;
            m >>= 1;
        }
        j += m;
    }

    /* Danielson-Lanczos recurrence */
    mmax = ninc;
    incdir = isign * ninc;
    while (nninc > mmax) {
        istep = mmax << 1;
        theta = 6.28318530717959 / (istep/incdir);
        wtemp = sin(0.5 * theta);
        wpr = -2.0 * wtemp * wtemp;
        wpi = sin(theta);
        wr = 1.0;
        wi = 0.0;
        for (m = 0; m < mmax; m += ninc) {
            for (i = m; i < nninc; i += istep) {
                j = i + mmax;
                for (dri = datr+i, drj = datr+j, dii = dati+i, dij = dati+j,
                        dstop = dri + ppinc;
                     dri < dstop;
                     dri += pinc, drj += pinc, dii += pinc, dij += pinc) {
                    tempr = wr * *drj - wi * *dij;
                    tempi = wr * *dij + wi * *drj;
                    *drj = *dri - tempr;
                    *dij = *dii - tempi;
                    *dri += tempr;
                    *dii += tempi;
                }
            }
            wr = (wtemp = wr)*wpr - wi*wpi + wr;
            wi = wi*wpr + wtemp*wpi + wi;
        }
        mmax = istep;
    }

    /* Normalisation */
    if (isign == 1) {
        temp = 1.0/n;
        for (i = 0; i < nninc; i += ninc)
            for (dri = datr+i, dii = dati+i, dstop = dri + ppinc;
                 dri < dstop;
                 dri += pinc, dii += pinc) {
                *dri *= temp;
                *dii *= temp;
            }
    }

    return 0;
}

int fft1pow2rfmult(int p, int pinci, int pinco, int n,
                   int rstarti, float *datrarri,
                   int rstarto, float *datrarro,
                   int istarto, float *datiarro)
/*
In effect, applies fft1pow2rf to multiple columns.
*/
{
    int     nd2 = n/2,
            nd4 = nd2/2,
            ppinco = p * pinco,
            i, j, i1, i2;
    float   temp, t1, t2, h1r, h1i, h2r, h2i,
            *datri = datrarri + rstarti,    /* zero-based arrays */
            *datro = datrarro + rstarto,
            *datio = datiarro + istarto,
            *drii, *drij1, *drij2, *droi, *dioi, *droj, *dioj, *dstop;
    double  wtemp, wr, wpr, wpi, wi, theta;

    /* Check n and p before use */
    if (!p || !n) return 0;
    if (p < 0 || pinci <= 0 || pinco <= 0) return 4;

    /* Check that n is even or 1. Other checks done in fft1pow2mult */
    if (n == 1) {
        for (droi = datro, drii = datri, dioi = datio,
                dstop = droi + ppinco;
             droi < dstop;
             droi += pinco, drii += pinci, dioi += pinco) {
            *droi = *drii;
            *dioi = 0.0;
        }
        return 0;
    }
    if (n != 2*nd2) return 1;

    /* Copy data from real input to output arrays, alternating points */
    for (i=0, j=0; i < nd2; i++, j += 2)
        for (droi=datro+i, drij1=datri+j, dioi=datio+i, drij2=datri+j+1,
                dstop = droi + ppinco;
             droi < dstop;
             droi += pinco, drij1 += pinci, dioi += pinco, drij2 += pinci) {
            *droi = *drij1;
            *dioi = *drij2;
        }

    /* Do half-length fft in place */
    i = fft1pow2mult(1, p, pinco, nd2, 1, 0, datro, 0, datio);
    if (i) return i;

    /* Initialise recurrence */
    theta = 6.28318530717959 /(double) n;
    wtemp = sin(0.5 * theta);
    wpr = -2.0 * wtemp * wtemp;
    wpi = sin(theta);
    wr = 1.0 + wpr;
    wi = wpi;

    /* Do final missing stage of FFT, including normalisation */
    i = 1;
    j = nd2 - 1;
    while (i < nd4) {
        for (droi = datro+i, droj = datro+j, dioi = datio+i, dioj = datio+j,
                dstop = droi + ppinco;
             droi < dstop;
             droi += pinco, droj += pinco, dioi += pinco, dioj += pinco) {
            h1r =  0.25 * (*droi + *droj);
            h1i =  0.25 * (*dioi - *dioj);
            h2r =  0.25 * (*dioi + *dioj);
            h2i =  0.25 * (*droj - *droi);
            t1 = wr*h2r - wi*h2i;
            t2 = wr*h2i + wi*h2r;
            *droi =  h1r + t1;
            *dioi =  h1i + t2;
            *droj =  h1r - t1;
            *dioj = -h1i + t2;
        }
        wr = (wtemp = wr)*wpr - wi*wpi + wr;
        wi = wi*wpr + wtemp*wpi + wi;
        i++;
        j--;
    }
    if (nd4)
        for (droi = datro+nd4, dioi = datio+nd4,
                dstop = droi + ppinco;
             droi < dstop;
             droi += pinco, dioi += pinco) {
            *droi *= 0.5;     /* Normalise middle point */
            *dioi *= 0.5;
        }
    for (droi=datro, dioi=datio, droj=datro+nd2, dioj=datio+nd2,
            dstop = droi + ppinco;
         droi < dstop;
         droi += pinco, dioi += pinco, droj += pinco, dioj += pinco) {
        *droi = 0.5 * ((h1r=*droi) + (h1i=*dioi));
        *dioi = 0.0;
        *droj = 0.5 * (h1r - h1i);
        *dioj = 0.0;
    }

    return 0;
}

int fft1pow2rbmult(int p, int pinci, int pinco, int n,
                   int rstarti, float *datrarri,
                   int istarti, float *datiarri,
                   int rstarto, float *datrarro)
/*
In effect applies fft1pow2rb to each column of an array.
*/
{
    int     nd2 = n/2,
            nd4 = nd2/2,
            ppinci = p * pinci,
            ppinco = p * pinco,
            i, i1, i2, i3, i4;
    float   temp, t1, t2, h1r, h1i, h2r, h2i,
            *datri = datrarri + rstarti,    /* zero-based arrays */
            *datii = datiarri + istarti,
            *datro = datrarro + rstarto,
            *dro, *dri,
            *drii1, *drii2, *diii1, *diii2, *droi3, *droi3p, *droi4, *droi4p,
            *drond2, *drind4, *drond2p, *diind4, *drind2, *drop, *dstop;
    double  wtemp, wr, wpr, wpi, wi, theta;

    /* Check that n is even or 1, and check p. Other checks done in fft1pow2 */
    if (!n || !p) return 0;
    if (p < 0 || pinci <= 0 || pinco <= 0) return 4;
    if (n == 1) {
        for (dro = datro, dri = datri, dstop = dro + ppinco;
             dro < dstop;
             dro += pinco, dri += pinci)
            *dro = *dri;
        return 0;
    }
    if (n != 2*nd2) return 1;

    /* Initialise recurrence */
    theta = -6.28318530717959 /(double) n;
    wtemp = sin(0.5 * theta);
    wpr = -2.0 * wtemp * wtemp;
    wpi = sin(theta);
    wr = 1.0 + wpr;
    wi = wpi;

    /* Perform preliminary step of fft, copying data from complex
    input arrays to alternating points in output array. */
    i1 = 1;
    i2 = nd2 - 1,
    i3 = 2,
    i4 = n - 2;
    while (i1 < nd4) {
        for (drii1=datri+i1, drii2=datri+i2, diii1=datii+i1, diii2=datii+i2,
             droi3=datro+i3, droi3p=droi3+1,
             droi4=datro+i4, droi4p=droi4+1,
                dstop = drii1 + ppinci;
             drii1 < dstop;
             drii1+=pinci, drii2+=pinci, diii1+=pinci, diii2+=pinci,
             droi3+=pinco, droi3p+=pinco, droi4+=pinco, droi4p+=pinco) {
            h1r =  *drii1 + *drii2;
            h1i =  *diii1 - *diii2;
            h2r = -*diii1 - *diii2;
            h2i =  *drii1 - *drii2;
            t1 = wr*h2r - wi*h2i;
            t2 = wr*h2i + wi*h2r;
            *droi3  =  h1r + t1;
            *droi3p =  h1i + t2;
            *droi4  =  h1r - t1;
            *droi4p = -h1i + t2;
        }
        wr = (wtemp = wr)*wpr - wi*wpi + wr;
        wi = wi*wpr + wtemp*wpi + wi;
        i1++;
        i2--;
        i3 += 2;
        i4 -= 2;
    }
    for (drond2 = datro+nd2, drind4 = datri+nd4,
         dro = datro, dri = datri, drond2p = drond2+1,
         diind4 = datii+nd4, drind2 = datri+nd2,
         drop  = datro+1,
            dstop = dro + ppinco;
         dro < dstop;
         drond2 += pinco, drind4 += pinci,
         dro += pinco, dri += pinci, drond2p += pinco,
         diind4 += pinci, drind2 += pinci, drop += pinco) {
        *drond2 = 2.0 * *drind4;
        *drond2p = 2.0 * *diind4;
        *dro   = *dri + *drind2;
        *drop  = *dri - *drind2;
    }

    /* Do rest of fft in place */
    fft1pow2mult(-1, p, pinco, nd2, 2, 0, datro, 1, datro);

    return 0;
}


/* --- Revision History ---------------------------------------------------
--- David Young, Oct 11 2001
        Added multiply_region.
--- David Young, Oct  2 2001
        Added routines for 2-D real data.
--- David S Young, Mar 12 1999
        Added routines for 1-D real data.
 */
