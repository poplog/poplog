/* --- Copyright University of Sussex 2003. All rights reserved. ----------
 > File:            $popvision/lib/corners_hs.p
 > Purpose:         Find corner points in images
 > Author:          David Young, Oct 24 2003
 > Documentation:   HELP * CORNERS_HS
 > Related Files:   See uses list
 */

;;; Simple implementation of the Harris-Stephens ("Plessey") corner
;;; detector, AVC88 p.147.

compile_mode:pop11 +strict;

section;

uses popvision, convolve_gauss_2d, float_arrayprocs, boundslist_utils;
uses array_peaks;

lconstant macro ltag = [ #_< consref(0) >_# ];

define corner_response_hs(im, sigma, k, R) -> R;
    ;;; Apparently 0.04 is recommended for k
    lconstant
        xdiff = newsfloatarray([-1 1 0 0], erase),
        ydiff = newsfloatarray([0 0 -1 1], procedure(i, j); j endprocedure);
    lvars bds = region_expand(im, -1);
    unless im.isarray then -> im endunless;
    lvars
        X = convolve_2d(im, xdiff, ltag, bds),
        Y = convolve_2d(im, ydiff, ltag, bds),
        XY = float_arraymult(X, Y, ltag),
        X2 = float_arraysqr(X, X),
        Y2 = float_arraysqr(Y, Y),
        A = convolve_gauss_2d(X2, sigma, ltag),
        B = convolve_gauss_2d(Y2, sigma, ltag),
        C = convolve_gauss_2d(XY, sigma, ltag),
        C2 = float_arraysqr(C, C),
        AB = float_arraymult(A, B, ltag),
        Tr = float_arraysum(A, B, A),
        Tr2 = float_arraysqr(Tr, Tr),
        kTr2 = float_multconst(k, Tr2, Tr2),
        Det = float_arraydiff(AB, C2, B);
    float_arraydiff(Det, kTr2, R) -> R enddefine;

define corners_hs(/* im, sigma, k, */ thr) /* -> corns */ with_nargs 4;
    lvars R = corner_response_hs(/* im, sigma, k, */ ltag);
    array_peaks(R, thr, false)
enddefine;

endsection;
