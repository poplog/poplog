/* --- Copyright University of Sussex 2003. All rights reserved. ----------
 > File:            $popvision/lib/convolve_gauss_2d.p
 > Purpose:         Convolve 2-D arrays with Gaussian masks
 > Author:          David S Young, Jun  3 1992 (see revisions)
 > Documentation:   HELP *CONVOLVE_GAUSS_2D
 > Related Files:   LIB *CONVOLVE_2D, LIB *GAUSSMASK
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses boundslist_utils
uses arraysample
uses convolve_2d
uses gaussmask
uses newsfloatarray
uses float_arrayprocs

define convolve_gauss_2d(image, operations /*, arrout*/) -> arrout;
    lvars image, operations, arrout = false;

    lconstant zerolist = [0 0], smoothlist = [smoothx 0 smoothy 0];

    ;;; Sort out args, including optional 3rd arg
    unless operations.isreal or operations.islist then
        (image, operations) -> (image, operations, arrout)
    endunless;
    if operations.isreal then
        operations ->> smoothlist(2) -> smoothlist(4);
        smoothlist -> operations
    endif;

    ;;; tags for getting work arrays
    lconstant
        wk1tag = consref("convolve_gauss_2d"),
        wk2tag = consref("convolve_gauss_2d");

    if operations == [] then ;;; no operations but need to copy data
        if arrout.isarray then
            lvars region = region_intersect(image, arrout);
            arraysample(image, region, arrout, region, "nearest") ->
        else
            oldsfloatarray(arrout, boundslist(image), image) -> arrout
        endif

    else
        lvars op, sigma, mask, wk1 = wk1tag, wk2 = wk2tag;
        until operations == [] do
            dest(dest(operations)) -> (op, sigma, operations);
            switchon op ==
            case "smoothx" then
                gaussmask(sigma) -> mask;
                ;;; Make a 2-D array with no y extent
                newanyarray(boundslist(mask) <> zerolist, mask) -> mask;
            case "smoothy" then
                gaussmask(sigma) -> mask;
                newanyarray(zerolist <> boundslist(mask), mask) -> mask;
            case "diffx" then
                diffgaussmask(sigma) -> mask;
                ;;; Make a 2-D array with no y extent
                newanyarray(boundslist(mask) <> zerolist, mask) -> mask;
            case "diffy" then
                diffgaussmask(sigma) -> mask;
                newanyarray(zerolist <> boundslist(mask), mask) -> mask;
            else
                mishap(op, 1, 'Unknown operation')
            endswitchon;

            ;;; Convolve 2-D handles what are really 1-D masks efficiently
            if operations == [] then
                ;;; last operation
                convolve_2d(image, mask, arrout,
                    arrout.isarray and boundslist(arrout)) -> arrout
            else
                convolve_2d(image, mask,
                    oldsfloatarray(wk1, region_conv_output(image, mask)),
                    false)
                    -> image;
                ;;; use other work array next time
                (wk1, wk2) -> (wk2, wk1)
            endif
        enduntil
    endif enddefine;

define convolve_gauss_2d_sizeout(bounds, operations) -> bounds;
    lvars bounds, operations;

    lconstant
        smoothlist = [smoothx 0 smoothy 0],
        maskbounds = [0 0 0 0];
    ;;; Sort out args, including optional 3rd arg
    if operations.isreal then
        operations ->> smoothlist(2) -> smoothlist(4);
        smoothlist -> operations
    endif;

    lvars op, sigma, lim;
    until operations == [] do
        dest(dest(operations)) -> (op, sigma, operations);
        switchon op ==
        case "smoothx" then
            gaussmask_limit(sigma) -> lim;
            -lim, lim, 0, 0 -> explode(maskbounds);
        case "smoothy" then
            gaussmask_limit(sigma) -> lim;
            0, 0, -lim, lim -> explode(maskbounds);
        case "diffx" then
            diffgaussmask_limit(sigma) -> lim;
            -lim, lim, 0, 0 -> explode(maskbounds);
        case "diffy" then
            diffgaussmask_limit(sigma) -> lim;
            0, 0, -lim, lim -> explode(maskbounds);
        else
            mishap(op, 1, 'Unknown operation')
        endswitchon;
        region_conv_output(bounds, maskbounds) -> bounds;
    enduntil
enddefine;

define convolve_gauss_2d_sizein(operations, bounds) -> bounds;
    lvars bounds, operations;

    lconstant
        smoothlist = [smoothx 0 smoothy 0],
        maskbounds = [0 0 0 0];
    ;;; Sort out args, including optional 3rd arg
    if operations.isreal then
        operations ->> smoothlist(2) -> smoothlist(4);
        smoothlist -> operations
    endif;

    lvars op, sigma, lim;
    rev(operations) -> operations;
    until operations == [] do
        dest(dest(operations)) -> (sigma, op, operations);
        switchon op ==
        case "smoothx" then
            gaussmask_limit(sigma) -> lim;
            -lim, lim, 0, 0 -> explode(maskbounds);
        case "smoothy" then
            gaussmask_limit(sigma) -> lim;
            0, 0, -lim, lim -> explode(maskbounds);
        case "diffx" then
            diffgaussmask_limit(sigma) -> lim;
            -lim, lim, 0, 0 -> explode(maskbounds);
        case "diffy" then
            diffgaussmask_limit(sigma) -> lim;
            0, 0, -lim, lim -> explode(maskbounds);
        else
            mishap(op, 1, 'Unknown operation')
        endswitchon;
        region_conv_input(bounds, maskbounds) -> bounds;
    enduntil
enddefine;


global vars convolve_dog_ratio = 1.6;

define convolve_dog_2d(image, sigma /*, arrout*/) -> arrout;
    lvars image, sigma, arrout = false;

    unless sigma.isreal then
        (image, sigma) -> (image, sigma, arrout)
    endunless;

    lconstant
        innertag = consref("inner"),
        outertag = consref("outer");
    lvars
        outersigma = convolve_dog_ratio * sigma,
        maxlen = gaussmask_limit(max(sigma, outersigma)),
        outbounds = region_expand(image, -maxlen),
        innerimage = convolve_gauss_2d(image, sigma,
        oldsfloatarray(innertag, outbounds)),
        outerimage = convolve_gauss_2d(image, outersigma,
        oldsfloatarray(outertag, outbounds));
    unless arrout.isarray then
        oldsfloatarray(arrout, outbounds) -> arrout
    endunless;
    float_arraydiff(innerimage, outerimage, arrout) -> arrout
enddefine;

define convolve_dog_2d_sizeout(bounds, sigma) /* -> bounds */;
    lvars bounds, sigma;
    lvars
        outersigma = convolve_dog_ratio * sigma,
        maxlen = gaussmask_limit(max(sigma, outersigma));
    region_expand(bounds, -maxlen) /* -> bounds */
enddefine;

define convolve_dog_2d_sizein(sigma, bounds) /* -> bounds */;
    lvars bounds, sigma;
    lvars
        outersigma = convolve_dog_ratio * sigma,
        maxlen = gaussmask_limit(max(sigma, outersigma));
    region_expand(bounds, maxlen) /* -> bounds */
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Oct  7 2003
        Made it possible for arrout to be a tag for -oldsfloatarray-
--- David Young, Dec 13 2001
        Changed last arg to first call to -convolve_2d-, as incompatible
        change to that library means that boundslist argument is now needed.
--- David S Young, Feb 27 1997
        Added -convolve_gauss_2d_sizein-, -convolve_gauss_2d_sizeout-,
        -convolve_dog_2d_sizein- and -convolve_dog_2d_sizeout-.
--- David S Young, Jan 27 1995
        Included copy operation for case where no operations specified
--- David S Young, Nov 16 1994
        Changed to reduce garbage creation - allows output arrays to
        be supplied and uses oldsfloatarray for work arrays.
--- David S Young, Jul 13 1993
        Changed -newfloatarray- to -newsfloatarray- and -isfloatarray- to
        -issfloatarray- to avoid name clash with *VEC_MAT package.
--- David S Young, Nov 26 1992
        Changed to use *GAUSSMASK
 */
