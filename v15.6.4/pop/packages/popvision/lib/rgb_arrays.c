/* --- Copyright University of Sussex 2001. All rights reserved. ----------
 * File:            $popvision/lib/rgb_arrays.c
 * Purpose:         RGB array format conversions
 * Author:          David Young, Sep  3 2001 (see revisions)
 * Documentation:   HELP * RGB_ARRAYS
 * Related Files:   LIB * RGB_ARRAYS
 */

/* Note: this would seem to be more efficiently done by directly
addressing the bytes of the unsigned int arrays, rather than by shifting
and combining or masking. However, this runs into difficulties because
the r,g,b order presented to X goes with the significance order within
ints, rather than with addressing order. That is, to avoid problems with
differences between bigendian and littlendian machines we have to treat
the blue, say, as the low-order bits of the the int rather than as the
bits with the lowest address. It would be possible to test for endedness
and then use byte addressing, but at a small cost in efficiency this is
a more straightforward and portable approach.

At present the 24-bit methods retain byte indexing because they are
intended to be used with read-in sunrasterfile data, which is
presumably going to retain address order across machines. But this
needs to be tested. */

void rgb8_to_32(xsize, ysize, rvec, rstart, rx,
                              gvec, gstart, gx,
                              bvec, bstart, bx,
                              avec, astart, ax)
    unsigned char *rvec, *gvec, *bvec;
    unsigned int *avec;
    int xsize, ysize, rstart, rx, gstart, gx, bstart, bx, astart, ax;
{
    unsigned char *rsl, *rfst, *gsl, *gfst, *bsl, *bfst, *rfstmx;
    unsigned int *asl, *aslmx, *afst;

    for (rsl=rvec+rstart, gsl=gvec+gstart, bsl=bvec+bstart, asl=avec+astart,
         aslmx=asl + ysize*ax;
         asl < aslmx;
         rsl += rx, bsl += bx, gsl += gx, asl += ax)

        for (rfst=rsl, gfst=gsl, bfst=bsl, afst=asl,
             rfstmx = rfst + xsize;
             rfst < rfstmx;
             )
            *afst++ = *rfst++ << 16u | *gfst++ << 8u | *bfst++ ;
}

static unsigned int f2u(f)
    float f;
{
    f *= 256.0;
    f = f > 255.0 ? 255.0 : f;
    f = f < 0.0 ? 0.0 : f;
    return((unsigned int) f);
}

static unsigned char f2i(f)
    float f;
{
    f *= 256.0;
    f = f > 255.0 ? 255.0 : f;
    f = f < 0.0 ? 0.0 : f;
    return((unsigned char) f);
}

void rgbsfloat_to_32(xsize, ysize, rvec, rstart, rx,
                                   gvec, gstart, gx,
                                   bvec, bstart, bx,
                                   avec, astart, ax)
    float *rvec, *gvec, *bvec;
    unsigned int *avec;
    int xsize, ysize, rstart, rx, gstart, gx, bstart, bx, astart, ax;
{
    float *rsl, *rfst, *gsl, *gfst, *bsl, *bfst, *rfstmx;
    unsigned int *asl, *aslmx, *afst;

    for (rsl=rvec+rstart, gsl=gvec+gstart, bsl=bvec+bstart, asl=avec+astart,
         aslmx=asl+ysize*ax;
         asl < aslmx;
         rsl += rx, bsl += bx, gsl += gx, asl += ax)

        for (rfst=rsl, gfst=gsl, bfst=bsl, afst=asl,
             rfstmx = rfst + xsize;
             rfst < rfstmx;
             )
            *afst++ = f2u(*rfst++) << 16U | f2u(*gfst++) << 8U | f2u(*bfst++) ;
}

void rgb32_to_8(xsize, ysize, avec, astart, ax,
                              rvec, rstart, rx,
                              gvec, gstart, gx,
                              bvec, bstart, bx)
    unsigned char *rvec, *gvec, *bvec;
    unsigned int *avec;
    int xsize, ysize, rstart, rx, gstart, gx, bstart, bx, astart, ax;
{
    unsigned char *rsl, *rfst, *gsl, *gfst, *bsl, *bfst, *rfstmx;
    unsigned int *asl, *aslmx, *afst;

    for (rsl=rvec+rstart, gsl=gvec+gstart, bsl=bvec+bstart, asl=avec+astart,
         aslmx=asl+ysize*ax;
         asl < aslmx;
         rsl += rx, bsl += bx, gsl += gx, asl += ax)

        for (rfst=rsl, gfst=gsl, bfst=bsl, afst=asl,
             rfstmx = rfst + xsize;
             rfst < rfstmx;
             )
        {
            *rfst++ = (unsigned char) *afst >> 16u & 0xFFu;
            *gfst++ = (unsigned char) *afst >>  8u & 0xFFu;
            *bfst++ = (unsigned char) *afst++ & 0xFFu;
        }
}

void rgb32_to_sfloat(xsize, ysize, avec, astart, ax,
                                   rvec, rstart, rx,
                                   gvec, gstart, gx,
                                   bvec, bstart, bx)
    float *rvec, *gvec, *bvec;
    unsigned int *avec;
    int xsize, ysize, rstart, rx, gstart, gx, bstart, bx, astart, ax;
{
    float *rsl, *rfst, *gsl, *gfst, *bsl, *bfst, *rfstmx;
    unsigned int *asl, *aslmx, *afst;

    for (rsl=rvec+rstart, gsl=gvec+gstart, bsl=bvec+bstart, asl=avec+astart,
         aslmx=asl+ysize*ax;
         asl < aslmx;
         rsl += rx, bsl += bx, gsl += gx, asl += ax)

        for (rfst=rsl, gfst=gsl, bfst=bsl, afst=asl,
             rfstmx = rfst + xsize;
             rfst < rfstmx;
             )
        {
            *rfst++ = (float) (*afst >> 16u & 0xFFu) / 256.0;
            *gfst++ = (float) (*afst >>  8u & 0xFFu) / 256.0;
            *bfst++ = (float) (*afst++ & 0xFFu) / 256.0;
        }
}

void rgb8_to_24(xsize, ysize, rvec, rstart, rx,
                              gvec, gstart, gx,
                              bvec, bstart, bx,
                              avec, astart, ax)
    unsigned char *rvec, *gvec, *bvec, *avec;
    int xsize, ysize, rstart, rx, gstart, gx, bstart, bx, astart, ax;
{
    unsigned char *rsl, *rfst, *gsl, *gfst, *bsl, *bfst, *rfstmx, *rslmx;
    unsigned char *asl, *afst;

    astart *= 3;
    ax *= 3;

    for (rsl=rvec+rstart, gsl=gvec+gstart, bsl=bvec+bstart, asl=avec+astart,
         rslmx = rsl + ysize*rx;
         rsl < rslmx;
         rsl += rx, bsl += bx, gsl += gx, asl += ax)

        for (rfst=rsl, gfst=gsl, bfst=bsl, afst = asl,
             rfstmx = rfst + xsize;
             rfst < rfstmx;
             )
        {
            *afst++ = *bfst++;
            *afst++ = *gfst++;
            *afst++ = *rfst++;
        }
}

void rgbsfloat_to_24(xsize, ysize, rvec, rstart, rx,
                                   gvec, gstart, gx,
                                   bvec, bstart, bx,
                                   avec, astart, ax)
    float *rvec, *gvec, *bvec;
    unsigned char *avec;
    int xsize, ysize, rstart, rx, gstart, gx, bstart, bx, astart, ax;
{
    float *rsl, *rfst, *gsl, *gfst, *bsl, *bfst, *rfstmx, *rslmx;
    unsigned char *asl, *afst;

    astart *= 3;
    ax *= 3;

    for (rsl=rvec+rstart, gsl=gvec+gstart, bsl=bvec+bstart, asl=avec+astart,
         rslmx = rsl + ysize*rx;
         rsl < rslmx;
         rsl += rx, bsl += bx, gsl += gx, asl += ax)

        for (rfst=rsl, gfst=gsl, bfst=bsl, afst = asl,
             rfstmx = rfst + xsize;
             rfst < rfstmx;
             )
        {
            *afst++ = f2i(*bfst++);
            *afst++ = f2i(*gfst++);
            *afst++ = f2i(*rfst++);
        }
}

void rgb24_to_8(xsize, ysize, avec, astart, ax,
                              rvec, rstart, rx,
                              gvec, gstart, gx,
                              bvec, bstart, bx)
    unsigned char *rvec, *gvec, *bvec, *avec;
    int xsize, ysize, rstart, rx, gstart, gx, bstart, bx, astart, ax;
{
    unsigned char *rsl, *rfst, *gsl, *gfst, *bsl, *bfst, *rfstmx, *rslmx;
    unsigned char *asl, *afst;

    astart *= 3;
    ax *= 3;

    for (rsl=rvec+rstart, gsl=gvec+gstart, bsl=bvec+bstart, asl=avec+astart,
         rslmx = rsl + ysize*rx;
         rsl < rslmx;
         rsl += rx, bsl += bx, gsl += gx, asl += ax)

        for (rfst=rsl, gfst=gsl, bfst=bsl, afst = asl,
             rfstmx = rfst + xsize;
             rfst < rfstmx;
             )
        {
            *bfst++ = *afst++;
            *gfst++ = *afst++;
            *rfst++ = *afst++;
        }
}

void rgb24_to_sfloat(xsize, ysize, avec, astart, ax,
                                   rvec, rstart, rx,
                                   gvec, gstart, gx,
                                   bvec, bstart, bx)
    float *rvec, *gvec, *bvec;
    unsigned char *avec;
    int xsize, ysize, rstart, rx, gstart, gx, bstart, bx, astart, ax;
{
    float *rsl, *rfst, *gsl, *gfst, *bsl, *bfst, *rfstmx, *rslmx;
    unsigned char *asl, *afst;

    astart *= 3;
    ax *= 3;

    for (rsl=rvec+rstart, gsl=gvec+gstart, bsl=bvec+bstart, asl=avec+astart,
         rslmx = rsl + ysize*rx;
         rsl < rslmx;
         rsl += rx, bsl += bx, gsl += gx, asl += ax)

        for (rfst=rsl, gfst=gsl, bfst=bsl, afst = asl,
             rfstmx = rfst + xsize;
             rfst < rfstmx;
             )
        {
            *rfst++ = ((float) *afst++) / 256.0;
            *gfst++ = ((float) *afst++) / 256.0;
            *bfst++ = ((float) *afst++) / 256.0;
        }
}

void rgb24_to_32(xsize, ysize, vec24, start24, x24,
                               vec32, start32, x32)
    unsigned char *vec24;
    unsigned int *vec32;
    int xsize, ysize, start24, x24, start32, x32;
/* The use of address order for 24 bit and significance order for 32 bit
data seems particularly odd here. However, it may make sense - if it
does not, then the best solution would be to generalise this library to
give more flexibility, and determine colour ordering properly from the
data source. */
{
    unsigned char *sl24, *fst24;
    unsigned int *sl32, *slmx32, *fst32, *fstmx32;

    start24 *= 3;
    x24 *= 3;

    for (sl24 = vec24+start24, sl32 = vec32+start32,
         slmx32 = sl32+ysize*x32;
         sl32 < slmx32;
         sl24 += x24, sl32 += x32)

        for (fst24 = sl24, fst32 = sl32,
             fstmx32 = fst32 + xsize;
             fst32 < fstmx32;
             fst24 += 3)
            *fst32++ = *(fst24+2) << 16u | *(fst24+1) << 8u | *fst24 ;
}

void rgb32_to_24(xsize, ysize, vec32, start32, x32,
                               vec24, start24, x24)
    unsigned char *vec24;
    unsigned int *vec32;
    int xsize, ysize, start24, x24, start32, x32;
{
    unsigned char *sl24, *fst24;
    unsigned int *sl32, *slmx32, *fst32, *fstmx32;

    start24 *= 3;
    x24 *= 3;

    for (sl24 = vec24+start24, sl32 = vec32+start32,
         slmx32 = sl32+ysize*x32;
         sl32 < slmx32;
         sl24 += x24, sl32 += x32)

        for (fst24 = sl24, fst32 = sl32,
             fstmx32 = fst32 + xsize;
             fst32 < fstmx32;
             fst24 += 3)
        {
            *(fst24+2) = (unsigned char) *fst32 >> 16u & 0xFFu;
            *(fst24+1) = (unsigned char) *fst32 >>  8u & 0xFFu;
            *fst24     = (unsigned char) *fst32++ & 0xFFu;
        }
}

/* --- Revision History ---------------------------------------------------
--- David Young, Sep 27 2001
        Changed access to 32-bit data from byte addressing to shifting and
        masking (see note at top) to try to avoid big/little endian
        problems.
 */
