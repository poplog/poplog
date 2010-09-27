/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 > File:            $popvision/lib/gaussmask.p
 > Purpose:         Generate 1-D Gaussian convolution masks
 > Author:          David Young, Nov 12 1992 (see revisions)
 > Documentation:   HELP *GAUSSMASK
 > Related Files:   LIB *CONVOLVE_GAUSS_2D
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses newsfloatarray

vars gaussmask_limit_ratio = 2.575;     ;;; less than 1% error

define vars procedure gaussmask_limit(sigma) /* -> size */;
    round(sigma * gaussmask_limit_ratio) /* -> size */
enddefine;

lconstant hold_masks1 = newsparse(2);    ;;; cache masks

define gaussmask(sigma) -> mask;
    lconstant zeromask = newsfloatarray([0 0], 1.0);
    lvars size = gaussmask_limit(sigma);
    if sigma = 0.0 then
        zeromask -> mask
    elseif
        (hold_masks1(size, number_coerce(sigma, 0.0s0)) ->> mask) == undef
    then
        ;;; Do calculation as not cached.
        newsfloatarray([%-size, size%]) -> mask;
        lvars i, sum = 0.5,
            k = -1.0 /  (2.0 * sigma * sigma);
        1.0 -> mask(0);
        fast_for i from 1 to size do
            exp(k * i * i) ->> mask(i) ->> mask(-i); + sum -> sum
        endfor;
        0.5 / sum -> k;
        ncmapdata(mask, nonop *(%k%))
            ->> hold_masks1(size, number_coerce(sigma, 0.0s0))
            -> mask
    endif
enddefine;

vars diffgaussmask_limit_ratio = 3.035;     ;;; less than 1% error

define vars procedure diffgaussmask_limit(sigma) /* -> size */;
    max(1, round(sigma * diffgaussmask_limit_ratio)) /* -> size */
enddefine;

lconstant hold_masks2 = newsparse(2);    ;;; cache masks

define diffgaussmask(sigma) -> mask;
    lvars size = diffgaussmask_limit(sigma);
    if sigma = 0.0 then 1.0 -> sigma endif; ;;; will use smallest mask
    if
        (hold_masks2(size, number_coerce(sigma, 0.0s0)) ->> mask) == undef
    then
        ;;; Do calculation as not cached.
        newsfloatarray([%-size, size%]) -> mask;
        lvars i, sum = 0.0,
            k = -1.0 /  (2.0 * sigma * sigma);
        0.0 -> mask(0);
        ;;; The signs used are correct - the values stored are negative
        ;;; for positive i
        fast_for i from 1 to size do
            i * exp(k * i * i) ->> mask(i);
            .negate ->> mask(-i); * i + sum -> sum;
        endfor;
        0.5 / sum -> k;
        ncmapdata(mask, nonop *(%k%))
            ->> hold_masks2(size, number_coerce(sigma, 0.0s0))
            -> mask
    endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Jul  3 2000
        Made gaussmask_limit and diffgaussmask_limit vars as they are
        supposed to be user-definable.
--- David S Young, Jul 13 1993
        Changed -newfloatarray- to -newsfloatarray- and -isfloatarray- to
        -issfloatarray- to avoid name clash with *VEC_MAT package.
 */
