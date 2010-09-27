/* --- Copyright University of Sussex 1995. All rights reserved. ----------
 > File:            $popvision/lib/squared_gradients.p
 > Purpose:         Estimate the total squared gradient at each pixel
 > Author:          David S Young, Feb 24 1995
 > Documentation:   HELP * SQUARED_GRADIENTS
 > Related Files:   See "uses" list below
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses convolve_2d
uses gaussmask
uses arraysample
uses float_arrayprocs

define squared_gradients(arrin, sigma, arrout, region) -> arrout;
    lvars arrin, sigma, arrout, region;

    ;;; Complete arguments
    lvars
        smargin = gaussmask_limit(sigma),
        dmargin = diffgaussmask_limit(sigma);
    if arrout.islist then
        if length(arrout) == 4 then
            newsfloatarray(arrout) -> arrout
        else
            newsfloatarray(tl(arrout), hd(arrout)) -> arrout
        endif
    endif;
    if arrout then
        region or boundslist(arrout) -> region
    else
        region or region_expand(arrin, -dmargin) -> region;
        newsfloatarray(region) -> arrout
    endif;

    ;;; Get masks
    lconstant zerolist = [0 0];
    lvars
        smask = gaussmask(sigma),
        smaskx = newanyarray(boundslist(smask) <> zerolist, smask),
        smasky = newanyarray(zerolist <> boundslist(smask), smask),
        dmask = diffgaussmask(sigma),
        dmaskx = newanyarray(boundslist(dmask) <> zerolist, dmask),
        dmasky = newanyarray(zerolist <> boundslist(dmask), dmask);

    ;;; Get work arrays
    lconstant
        wktags = consref(0), wktagx = consref(0), wktagy = consref(0);
    lvars
        dataregion = region_intersect(region, region_expand(arrin, -dmargin)),
        smthregion = region_expand(dataregion, dmargin),
        smth = oldsfloatarray(wktags, smthregion, 0),
        xdiff = oldsfloatarray(wktagx, region, 0),
        ydiff = oldsfloatarray(wktagy, region, 0);

    ;;; Get individual gradients
    convolve_2d(arrin, smaskx, smth, false) -> smth;
    convolve_2d(smth, dmasky, ydiff, dataregion) -> ydiff;
    convolve_2d(arrin, smasky, smth, false) -> smth;
    convolve_2d(smth, dmaskx, xdiff, dataregion) -> xdiff;

    ;;; Combine the gradients
    lvars tmparrout;
    if arrout.issfloatarray and boundslist(arrout) = region then
        arrout
    else
        xdiff
    endif -> tmparrout;
    float_arraysum(
        float_arraysqr(xdiff, xdiff), float_arraysqr(ydiff, ydiff), tmparrout
    ) -> tmparrout;

    ;;; Copy back if necessary
    unless tmparrout == arrout then
        arraysample(tmparrout, region, arrout, region, "nearest") -> ;
    endunless;
enddefine;

endsection;
