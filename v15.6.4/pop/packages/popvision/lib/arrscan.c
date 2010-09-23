/* --- Copyright University of Sussex 2004. All rights reserved. ----------
 * File:            $popvision/lib/arrscan.c
 * Purpose:         Support for LIB * ARRPACK
 * Author:          David Young, Dec 16 2003 (see revisions)
 * Documentation:   HELP * ARRPACK
 * Related Files:   LIB * ARRPACK.C
 */

#include <stdlib.h>
#include "arrscan.h"

/* For efficient C processing of multidimensional arrays. There are two
parts - arrscan for processing regularly spaced samples, and arrind for
processing samples specified by individual indices.

-- arrscan ------------------------------------------------------------

For translating simple specifications of sampled regions of
multidimensional arrays into efficient specifications that can be
used in loops that do element-by-element vector processing.

There are some optimisation options:

    cdopt = 0: Dimensions are not combined. Optimisation depends only on
    size of active region and sample increments, so may be used if
    region is to be processed in the same loop as other arrays or
    regions.

    cdopt = 1: Dimensions are combined where possible (e.g. one loop may
    cover the whole of a multidimensional array). Optimisation depends
    on dimensions of whole array, so only safe to use if region is to be
    processed on its own.

    ordopt = 0: Dimensions are left in original order, so processing
    proceeds with the first index varying fastest (regardless of whether
    this is the storage order).

    ordopt = 1: Dimensions are sorted in decreasing order of operation
    count, so the processing order depends on the region and sampling.
    This may be much more efficient if the processing order is
    unimportant.

The optimisation arguments must be 0 or 1 (not checked). If either
ordopt or cdopt is on, unitary dimensions are optimised away, but if
both are off, this is not done to preserve the original indices.

On entry, the specification for each N-dimensional array/region to be
processed is an integer array with 5*N+4 elements and the following
contents:

element         contents
-------         --------
0               Bit 0: if 0, spec is in unprocessed format as in this
                section; if 1, data has been processed into vector index
                form by a previous call
                Bit 1: storage order: 1 if first index changes fastest
                ("by column"), 0 if last index changes fastest ("by
                row")
                Bit 2 (ignored if bit 0 is 0): cdopt for the existing
                structure
                Bit 3 (ignored if bit 0 is 0): ordopt for the existing
                structure
                Bit 4 (ignored if bit 0 is 1): 1 if the array is to be
                completely processed - i.e. the region bounds equal the
                array bounds and the step sizes are all unity; 0
                otherwise. If 1, the region bounds and sample sizes
                specified below are ignored.
1               Number of dimensions of array, N. N >= 1
2               Unused
3..2*N+2        Array bounds: low limit then high limit of array index
                on each dimension in turn, for the original array
2*N+3           Unused
2*N+4..4*N+3    Region bounds: low limit then high limit of array index
                on each dimension in turn, for the region to be
                processed
4*N+4..5*N+3    Step sizes: for each dimension in turn, the increment
                for the array index between each element to be processed

On exit with a zero result each specification array has:

element         contents
-------         --------
0               Bit 0: set to 1
                Bit 1: 1 if original array was ordered by column, else 0
                Bit 2: cdopt for the results
                Bit 3: ordopt for the results
                Bit 4: undefined
1               N (unchanged)
2               The (0-based) vector index of the first element to
                process
3..2*N+2        For each original dimension in turn, the number of
                elements to process along this dimension (roughly the
                size of the region divided by the step size), followed
                by the increment in the vector index needed to step from
                one processable element to the next
2*N+3           Revised number of dimensions after optimisation, N' <=
                N.
2*N+4           For each new dimension in turn, the additional increment
..2*N+2*N'+3    in the vector index needed for a shift on this
                dimension, followed by the number of elements to process
                on this dimension
2*N+2*N'+4      Available as work space, zeroed on return
..2*N+3*N'+3

Also returns some of this information as individual values to minimise
the code needed to run a loop over the array:

    * the start offset
    * the increment of the first dimension (post optimisation)
    * this increment times the number of elements on the first dimension
    * a pointer to the increment for the second dimension
    * a pointer to the start of the work space, 2*(N'-1) greater than
      the pointer above


The routine result is as follows:

0: successful
1: array high bound less than low bound
2: region high bound less than low bound
3: not all sample points inside array bounds
4: sample increment zero or negative
5: -
6: number of dimensions less than 1
7: -

If the result is non-zero, the contents of the array are undefined on
exit.

The routine that checks for consistency between specifications returns:

0: successful
8: no. of dimensions different
9: no. of elements to process different on some dimension

and the routine that checks the total number of elements returns:

0: successful
10: total no. of elements different

*/

static int dusort(const void *p1, const void *p2)
    /* With qsort, puts results in descending order of first argument in
    field, then ascending order of second */
{
    int i = *(int *)p1, j = *(int *)p2;
    if (i == j)     /* sort on second elements */
        return *((int *)p1+1) - *((int *)p2+1);
    else            /* sort on first elements */
        return j-i;
}

static int ddsort(const void *p1, const void *p2)
    /* With qsort, puts results in descending order of first argument in
    field, then descending order of second */
{
    int i = *(int *)p1, j = *(int *)p2;
    if (i == j)     /* sort on second elements */
        return *((int *)p2+1) - *((int *)p1+1);
    else            /* sort on first elements */
        return j-i;
}

int arrspec(int *spec, int cdopt, int ordopt,
        int *off, int *dp, int *ndp, int **spp, int **wkp)
{
    const size_t twoints = 2 * sizeof(int);    /* for sort */
    int N, newN, flags, init, firstfastest, i, s, n, d,
        *sp, *t, *indexp, *bds, *ns, *newNp, *reg,
        *newns, *newnbase, *samp;

    /* Get N and set pointers to subarrays */
    flags = *(sp = spec);
    if ((newN = N = *++sp) <= 0) return 6;      /* 1 */
    indexp = ++sp;                              /* 2 */
    ns = bds = ++sp;                            /* 3 */
    newNp = (sp += 2*N);                        /* 3 + 2*N */

    /* Check flags */
    init = flags&01;
    if (init && (flags>>2&01 == cdopt) && (flags>>3&01 == ordopt))
        goto Return;    /* Nothing needed */
    firstfastest = flags&02;

    /* More pointers to parts of the spec */
    newnbase = newns = reg = ++sp;              /* 4 + 2*N */
    samp = sp + 2*N;                            /* 4 + 4*N */

    /* Convert bounds, region and increments into vector index spec */
    if (!init) {               /* Unprocessed */
        int r0, r1, rs, b0, b1, bs, roff, index = 0, d = 1;
        if (flags&020)        /* Complete */
            if (firstfastest)
                while (bds < newNp) {
                    if ((*bds++ = bs = *(bds+1)-*bds+1) <= 0) return 1;
                    *bds++ = d;
                    d *= bs;
                }
            else
                for (bds=newNp-1; bds >= ns; ) {
                    if ((bs = *bds-*(bds-1)+1) <= 0) return 1;
                    *bds-- = d;
                    *bds-- = bs;
                    d *= bs;
                }
        else {                  /* Not complete */
            if (firstfastest)
                while (bds < newNp) {
                    b0 = *bds; b1 = *(bds+1);
                    if ((bs = b1-b0+1) <= 0) return 1;
                    r0 = *reg++; r1 = *reg++;
                    if ((rs = r1-r0) < 0) return 2;
                    if ((s = *samp++) < 1) return 4;
                    if ((roff=r0-b0) < 0 || r0+s*(n=rs/s) > b1) return 3;
                    index += roff * d;
                    *bds++ = n + 1;             /* n[i] */
                    *bds++ = d * s;             /* ds[i] */
                    d *= bs;
                }
            else
                for (bds=newNp-1, reg=samp, samp+=N; bds >= ns; ) {
                    b1 = *bds; b0 = *(bds-1);
                    if ((bs = b1-b0+1) <= 0) return 1;
                    r1 = *--reg; r0 = *--reg;
                    if ((rs = r1-r0) < 0) return 2;
                    if ((s = *--samp) < 1) return 4;
                    if ((roff=r0-b0) < 0 || r0+s*(n=rs/s) > b1) return 3;
                    index += roff * d;
                    *bds-- = d * s;             /* ds[i] */
                    *bds-- = n + 1;             /* n[i] */
                    d *= bs;
                }
        }
        *indexp = index;

        if (N == 1) {    /* No optimisations */
            *newns++ = *(ns+1);  /* Vector index discontinuity */
            *newns   = *ns;      /* No. to process */
            *newNp = 1;
        }
    }

    if (N > 1) {

        /* Optimisation A: remove singleton dimensions. Done
        if ordopt or cdopt is true, since either may destroy
        original indexing.
        Optimisation B: combine dimensions if cdopt is true.
        Copy to higher part of spec also. */
        for (i=0; i<newN; i++) {
            n = *ns++;  d = *ns++;
            if (ordopt || cdopt)
                while (ns <= newNp && n == 1 && newN > 1) {
                    newN--;
                    n = *ns++;  d = *ns++;
                }
            if (cdopt)
                if (firstfastest)
                    while (ns < newNp && n * d  == *(ns+1)) {
                        newN--;
                        n *= *ns++;  ns++;
                    }
                else
                    while (ns < newNp && d == *ns * *(ns+1)) {
                        newN--;
                        n *= *ns++; d = *ns++;
                    }
            *newns++ = n;  *newns++ = d;
        }
        *newNp = newN;

        /* Optimisation C: sort dimensions, largest first. Equal
        dimensions sorted on ds. One can show that having removed
        singleton dimensions, ds is monotonic at this point, so the
        ordering is deterministic and depends only on ns. It is
        therefore OK even when array will be processed alongside others
        treated the same way. Switch on firstfastest for consistency
        between the two cases. */
        if (ordopt)
            if (firstfastest)
                qsort((void *)newnbase, (size_t)newN, twoints, dusort);
            else
                qsort((void *)newnbase, (size_t)newN, twoints, ddsort);

        /* Convert to jumps for efficient looping, put incr. before n */
        for (s=0; newnbase<newns; ) {
            n = *newnbase;
            d = *(newnbase+1);
            *newnbase++ = d-s;
            *newnbase++ = n;
            s = n * d;
        }
    }

    *spec = ordopt<<3 | cdopt<<2 | firstfastest | 01;

Return:

    *off = *indexp;
    newN = *newNp++;
    *wkp = sp = newNp + 2*newN;
    t = sp + (newN-1);
    while (sp <= t) *sp++ = 0;
    *dp = *newNp++;
    *ndp = *newNp++ * *dp;
    *spp = newNp;
    return 0;
}

int arrscan_check(int *spec1, int *spec2)
    /* Check that two specifications are consistent - same number of
    dimensions and same number of values to process on each */
{
    int i, N = *++spec1;        /* orig dimensions */
    if (N != *++spec2) return 8;
    for (i=0; i < N; i++)
        if (*(spec1 += 2) != *(spec2 += 2)) return 9;
    return 0;
}

static int arrscan_ntot(int *spec)
{
    int N, i, t;
    N = *++spec;
    spec += 2*N+2;
    N = *spec;
    for (i=0, t=1; i<N; i++)
        t *= *(spec += 2);
    return t;
}

int arrscan_check_total(int *spec1, int *spec2)
    /* Check that two specifications refer to the same total number
    of data, though they may differ on individual dimensions. */
{
    return (arrscan_ntot(spec1) == arrscan_ntot(spec2)) ? 0 : 10;
}

int arrscan_dimpars1(int dim, int *spec, int *istart, int *iinc)
    /* Return the start point and increment for a given dimension.
    spec must be unprocessed by arrspec */
{
    int N;
    if (dim < 1 || dim > (N = *(spec+1))) return 11;
    if (N <= 0) return 6;
    if (*spec & 020) {         /* complete */
        *istart = *(spec + 1 + 2*dim);
        *iinc = 1;
    }
    else {
        *istart = *(spec + 2 + 2*(N+dim));
        *iinc = *(spec + 3 + 4*N + dim);
    }
    return 0;
}

int arrscan_dimpars(int *spec, int *istarts, int *iincs)
    /* Copy start points and increments. spec must be unprocessed by
    arrspec. */
{
    int N, *rlo, *samp, i;
    if ((N = *(spec+1)) <= 0) return 6;
    if (*spec & 020)          /* complete */
        for (i=0, rlo=spec+3; i<N; i++) {
            *istarts++ = *rlo++; rlo++;
            *iincs++ = 1;
        }
    else
        for (i=0, rlo=spec+4+2*N, samp=rlo+2*N; i<N; i++) {
            *istarts++ = *rlo++; rlo++;
            *iincs++ = *samp++;
        }
    return 0;
}

/*
-- arrind -------------------------------------------------------------

For translating boundslist-type array specifications into C-compatible
specifications for indexed access.

On entry, the specification for each N-dimensional array to be
processed is an integer array with 2*N+3 elements and the following
contents:

element         contents
-------         --------
0               Bit 0: if 0, spec is in unprocessed format as in this
                section; if 1, data has been processed into vector index
                form by a previous call
                Bit 1: storage order: 1 if first index changes fastest
                ("by column"), 0 if last index changes fastest ("by
                row")
1               Number of dimensions of array, N. N >= 1
2               Unused
3..2*N+2        Array bounds: low limit then high limit of array index
                on each dimension in turn, for the original array

On exit with a zero result each specification array has:

element         contents
-------         --------
0               Bit 0: set to 1
                Bit 1: 1 if original array was ordered by column, else 0
1               N (unchanged)
2               The number of elements in the array
3               The constant for the linear equation from indices to
                vector offsets
4..N+3          The coefficients in the linear equation from indices to
                vector offsets

Also returns some of this information as individual values to minimise
the code needed to run a loop over a set of indices:

    * the number of elements in the array
    * the constant in the equation
    * a pointer to the coefficients
    * a point to just past the end of the coefficients, N greater than
      the pointer above

The routine result is as follows:

0: successful
1: array high bound less than low bound
6: number of dimensions less than 1

If the result is non-zero, the contents of the array are undefined on
exit.

*/

int arrind(int *spec, int *nelp, int *d0p, int **dp, int **dendp)
{
    int flags, N, firstfastest, d0, d, b0, b1, bs,
        *sp, *nelsp, *d0sp, *dsp, *dendsp, *bds, *ds, *bdsend;

    /* Get N and set pointers to subarrays */
    flags = *(sp = spec);
    if ((N = *++sp) <= 0) return 6;             /* 1 */
    nelsp = ++sp;                               /* 2 */
    d0sp = ++sp;                                /* 3 */
    dsp = ++sp;                                 /* 4 */
    dendsp = dsp+N;                             /* N+4 */

    /* Check flags */
    if (flags&01) goto Return;
    firstfastest = flags&02;

    /* Convert bounds into vector index spec */
    d0 = 0;
    d = 1;
    if (firstfastest)
        for (bds=d0sp, ds=dsp; ds<dendsp; ) {
            b0 = *bds++;
            if ((bs = *bds++ - b0 + 1) <= 0) return 1;
            d0 -= b0 * d;
            *ds++ = d;
            d *= bs;
        }
    else {
        for (bdsend=d0sp, bds=d0sp+2*N, ds=bds; bds > bdsend; ) {
            b1 = *--bds; b0 = *--bds;
            if ((bs = b1 - b0 + 1) <= 0) return 1;
            d0 -= b0 * d;
            *--ds = d;
            d *= bs;
        }
        for (sp=ds, ds=dsp; ds<dendsp; ) *ds++ = *sp++;
    }
    *nelsp = d;
    *d0sp = d0;

    *spec = firstfastest | 01;

Return:

    *nelp = *nelsp;
    *d0p = *d0sp;
    *dp = dsp;
    *dendp = dendsp;
    return 0;
}

/* --- Revision History ---------------------------------------------------
--- David Young, Apr  1 2004
        Added arrind:support for indexed active sets. Also
        arrscan_dimpars1 and arrscan_dimpars: support for setting to
        indices.
 */
