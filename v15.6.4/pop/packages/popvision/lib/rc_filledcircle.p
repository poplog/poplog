/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 > File:            $popvision/lib/rc_filledcircle.p
 > Purpose:         Draw a filled circle
 > Author:          David S Young, Apr  8 1994
 > Documentation:   HELP * RC_FILLEDCIRCLE
 > Related Files:   LIB * RC_GRAPHIC
 */

compile_mode:pop11 +strict;

section;

uses rc_graphic

define rc_filledcircle(/* x, y, */ radius);
    ;;; Draw a circular blob
    lvars x, y, radius;
    ;;; Get the centre and radius in window coords. Use an average
    ;;; radius in case the x and y scales are different.
    lvars r, rstart, rend,
        (xc, yc) = rc_transxyout(rc_getxy()),
        R = round(radius * (abs(rc_xscale) + abs(rc_yscale))/2),
        Rsq = R * R;

    define lconstant point(x, y); lvars x, y;
        XpwDrawPoint(rc_window, x, y);
    enddefine;

    ;;; Avoid sqrt calls for small blobs
    lconstant builtins =
        {{0} {2 0} {3 2 0} {4 3 3 0} {5 5 4 3} {6 6 5 4 3}
        {7 7 6 6 5 4} {8 8 7 7 6 5} {9 9 8 8 7 7 6}};

    lvars procedure pythag;
    if R == 0 then  ;;; pythag never called
    elseif R <= length(builtins) then
        subscrv(% builtins(R) %) -> pythag
    else
        define lvars procedure pythag(r); lvars r;
            round(sqrt(Rsq - r*r))
        enddefine
    endif;

    ;;; Do central point and cross through it first - if inside the
    ;;; loop these points get drawn more than once
    point(xc, yc);
    for r from 1 to R do
        point(xc + r, yc);
        point(xc - r, yc);
        point(xc, yc + r);
        point(xc, yc - r);
    endfor;
    for rstart from 1 to R do       ;;; will not get to R
        pythag(rstart) -> rend;
    quitif(rend < rstart);          ;;; get diagonal right
        ;;; Do 4 points on diagonal cross
        point(xc + rstart, yc + rstart);
        point(xc + rstart, yc - rstart);
        point(xc - rstart, yc + rstart);
        point(xc - rstart, yc - rstart);
        for r from rstart + 1 to rend do
            ;;; fill in the 8 octants
            point(xc + r, yc + rstart);
            point(xc + r, yc - rstart);
            point(xc - r, yc + rstart);
            point(xc - r, yc - rstart);
            point(xc + rstart, yc + r);
            point(xc + rstart, yc - r);
            point(xc - rstart, yc + r);
            point(xc - rstart, yc - r);
        endfor
    endfor
enddefine;

endsection;
