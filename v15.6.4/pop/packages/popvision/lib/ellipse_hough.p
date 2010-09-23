/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 > File:            $popvision/lib/ellipse_hough.p
 > Purpose:         Simple Hough transform for ellipses
 > Author:          David S Young, Mar  3 1995 (see revisions)
 > Documentation:   HELP * ELLIPSE_HOUGH
 > Related Files:   See "uses" list
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses appellipse
uses newsfloatarray
uses array_peaks

define ellipse_hough(image, a, b, alpha) /* -> (xc, yc) */;
    lvars retacc = false, xc, yc;
    if alpha.isboolean then
        (image, a, b, alpha) -> (image, a, b, alpha, retacc)
    endif;

    lconstant refpk = 1;
    lvars x, y, crds, v,
        bounds = boundslist(image),
        accum = retacc and oldsfloatarray(ellipse_hough, bounds, 0)
                or newsfloatarray(bounds, 0);

    define lconstant accumulate(xc, yc); lvars xc, yc;
        accum(xc, yc) + v -> accum(xc, yc)
    enddefine;

    for v with_index crds in_array image do
        if v /= 0 then
            explode(crds) -> (x, y);
            appellipse_rim(x, y, a, b, alpha, bounds, accumulate);
        endif
    endfor;

    explode(refine_peaks(accum, array_peak(accum, false), refpk, refpk))
        -> ( , xc, yc);
    xc, yc, if retacc then accum endif   ;;; results
enddefine;

define circle_hough(image, r) /* -> (xc, yc) */;
    lvars retacc = false;
    if r.isboolean then
        (image, r) -> (image, r, retacc)
    endif;

    ellipse_hough(image, r, r, 0, retacc)
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Jan 28 2000
        Added possibility of returning accumulator array
 */
