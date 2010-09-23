/* --- Copyright University of Sussex 1997. All rights reserved. ----------
 > File:            $popvision/lib/horn_schunck.p
 > Purpose:         Estimate optic flow vectors from grey-level gradients
 > Author:          David S Young, Apr  8 1994 (see revisions)
 > Documentation:   HELP * HORN_SCHUNCK
 > Related Files:   See "uses" below
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses convolve_2d
uses gaussmask
uses convolve_gauss_2d
uses array_reflect
uses boundslist_utils
uses float_arrayprocs

lvars
    work_array1 = newsfloatarray([0 0 0 0]),       ;;; to avoid garbage
    work_array2 = newsfloatarray([0 0 0 0]);

define lconstant set_work_arrays(region); lvars region;
    ;;; Ensure that the work arrays are the right size
    unless boundslist(work_array1) = region then
        newsfloatarray(region) -> work_array1;
        newsfloatarray(region) -> work_array2
    endunless
enddefine;

define lconstant gauss_smooth(arrin, sigma, arrout);
    lvars arrin, sigma, arrout;
    ;;; Like *convolve_gauss_2d but extends output to limits of
    ;;; input array by reflection

    lconstant zerobounds = [0 0];
    lvars
        mask = gaussmask(sigma),
        hmask = newanyarray(boundslist(mask) <> zerobounds, mask),
        vmask = newanyarray(zerobounds <> boundslist(mask), mask),
        midbounds = region_conv_output(arrin, hmask),
        outbounds = region_conv_output(midbounds, vmask);

    ;;; Do horizontal convolution
    convolve_2d(arrin, hmask, work_array1, midbounds) -> ;

    ;;; Do vertical convolution
    convolve_2d(work_array1, vmask, arrout, outbounds) -> ;

    ;;; Extend by reflection
    array_reflect(arrout, outbounds, arrout, boundslist(arrin)) -> ;
enddefine;

define lconstant gradients(im1, im2, sigma) -> (Ex, Ey, Et);
    lvars im1, im2, sigma, Ex, Ey, Et;
    ;;; Find spatial and temporal gradients
    lvars
        outbounds = region_expand(im1, -diffgaussmask_limit(sigma)),
        imsum = float_arraysum(im1, im2, false);
    float_multconst(0.5, imsum, imsum) -> ;
    convolve_gauss_2d(imsum, [diffx ^sigma smoothy ^sigma],
        newsfloatarray(outbounds)) -> Ex;
    convolve_gauss_2d(imsum, [smoothx ^sigma diffy ^sigma],
        newsfloatarray(outbounds)) -> Ey;

    lvars imdiff = float_arraydiff(im2, im1, imsum);
    convolve_gauss_2d(imdiff, sigma, newsfloatarray(outbounds)) -> Et;
enddefine;

define lconstant scale_arrays(Ex, Ey, lambd) -> (Px, Py);
    lvars Ex, Ey, lambd, Px, Py;
    float_arraysqr(Ex, false) -> Px;     ;;; temporary use of Px
    float_arraysqr(Ey, false) -> Py;     ;;; temporary use of Py
    float_arraysum(Px, Py, work_array1) -> ;
    float_addconst(lambd, work_array1, work_array1) -> ;
    float_arraydiv(Ex, work_array1, Px) -> ;
    float_arraydiv(Ey, work_array1, Py) -> ;
enddefine;

define lconstant horn_schunck1(Ex, Ey, Et, Px, Py, sigma2, u, v);
    ;;; One iteration, updating u and v
    lvars Ex, Ey, Et, Px, Py, sigma2, u, v;

    ;;; Smooth u and v
    gauss_smooth(u, sigma2, u);
    gauss_smooth(v, sigma2, v);

    ;;; Form dot product
    float_arraymult(Ex, u, work_array1) -> ;
    float_arraymult(Ey, v, work_array2) -> ;
    float_arraysum(work_array1, work_array2, work_array1) -> ;
    float_arraysum(work_array1, Et, work_array2) -> ;

    ;;; Scale
    float_arraymult(work_array2, Px, work_array1) -> ;
    float_arraymult(work_array2, Py, work_array2) -> ;

    ;;; and subtract
    float_arraydiff(u, work_array1, u) -> ;
    float_arraydiff(v, work_array2, v) -> ;
enddefine;

define lconstant horn_schunck0(im1, im2, sigma1, lambd)
        -> (Ex, Ey, Et, Px, Py, u, v);
    lvars im1, im2, sigma1, lambd, Ex, Ey, Et, Px, Py, u, v;
    gradients(im1, im2, sigma1) -> (Ex, Ey, Et);
    set_work_arrays(boundslist(Et));
    scale_arrays(Ex, Ey, lambd) -> (Px, Py);
    newsfloatarray(boundslist(Et)) -> u;
    newsfloatarray(boundslist(Et)) -> v;
enddefine;

define horn_schunck(im1, im2, sigma1, sigma2, lambd) -> hs;
    lvars im1, im2, sigma1, sigma2, lambd, procedure hs;
    ;;; Returns a procedure that returns updated u and v arrays
    ;;; each time it is called
    lvars (Ex, Ey, Et, Px, Py, u, v) = horn_schunck0(im1, im2, sigma1, lambd);

    define lvars procedure hs /* -> (u, v) */;
        horn_schunck1(Ex, Ey, Et, Px, Py, sigma2, u, v);
        (u, v) /* results */
    enddefine;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Feb 20 1997
        Gradient calculation changed to trim edges rather than extend by
        reflection, by using convolve_gauss_2d rather than the local
        gauss_smooth (which is retained for smoothing the flow). This greatly
        improves performance by removing effectively reversed flow from
        the margin.
--- David S Young, Nov 15 1994
        conssfloat changed to conssfloatvec to fit with new newsfloatarray
 */
