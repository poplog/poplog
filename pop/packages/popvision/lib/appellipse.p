/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 > File:            $popvision/lib/appellipse.p
 > Purpose:         Apply a procedure to all points in or on an ellipse
 > Author:          David S Young, Mar  3 1995 (see revisions)
 > Documentation:   HELP * APPELLIPSE
 > Related Files:   See "uses" line
 */


section;

uses boundslist_utils

define lconstant ellipsematrix(x0, y0, a, b, phi) -> (x0, y0, t11, t12, t22);
    ;;; Given ellipse params, returns centre and control matrix.
    lvars
    ;;; Ellipse parameters as inverse major and minor axis vectors
        cosPhi = cos(phi), sinPhi = sin(phi),
        (a1, a2) = ( cosPhi/a, sinPhi/a),
        (b1, b2) = (-sinPhi/b, cosPhi/b);
    ;;; Control matrix for ellipse in original coords.
    a1 * a1 + b1 * b1 -> t11;
    a2 * a2 + b2 * b2 -> t22;
    a1 * a2 + b1 * b2 -> t12;
enddefine;

define lconstant ellipse_map(x0, y0, t11, t12, t22, region, bounds)
        -> (x0, y0, t11, t12, t22);
    lvars
        (Map, ) = region_map(region, bounds),
        (Scale, ) = region_scale(region, bounds),
        (xscale, yscale) = Scale(1, 1);
    ;;; Convert matrix to array coords (needs to be done on matrix not vectors)
    t11 / (xscale * xscale) -> t11;
    t22 / (yscale * yscale) -> t22;
    t12 / (xscale * yscale) -> t12;
    ;;; Convert origin
    Map(x0, y0) -> (x0, y0)
enddefine;

define lconstant ellipsequation(t11, t12, t22) -> (k1, k2, k3);
    ;;; Given control matrix, returns coefficients of quadratic for
    ;;; x as a function of y.
    1.0 / t11 -> k3;
    - t12 * k3 -> k1;
    k1 * k1 - t22 * k3 -> k2;
enddefine;

define:inline lconstant YFN(plusminus=item);
    ;;; Inline ellipse equation.
    x - x0 -> xoff;
    y0 + k1y * xoff -> t1;
    k2y * xoff * xoff + k3y -> t2;
    t2 > 0 and round(t1 plusminus sqrt(t2)) -> y;
enddefine;

define:inline lconstant XFN(plusminus=item);
    ;;; Inline ellipse equation.
    y - y0 -> yoff;
    x0 + k1x * yoff -> t1;
    k2x * yoff * yoff + k3x -> t2;
    t2 > 0 and round(t1 plusminus sqrt(t2)) -> x;
enddefine;

define lconstant clip(x0, x1, X0, X1) -> (x0, x1);
    if X0 then
        max(x0, X0) -> x0
    endif;
    if X1 then
        min(x1, X1) -> x1
    endif
enddefine;

define lconstant ceil(n1) -> n2;
    intof(n1) -> n2;
    if n1 > 0 and n1 /= n2 then n2 + 1 -> n2 endif;
enddefine;

define lconstant floor(n1) -> n2;
    intof(n1) -> n2;
    if n1 < 0 and n1 /= n2 then n2 - 1 -> n2 endif
enddefine;

define lconstant fixbounds(bounds) -> (X0, X1, Y0, Y1);
    ;;; Ensures that bounding box is integers and in right order.
    ;;; Take box as largest one that does not go outside the given
    ;;; box.
    (false, false, false, false) -> (X0, X1, Y0, Y1);
    if bounds then
        explode(bounds) -> (X0, X1, Y0, Y1);
        if X0 and X1 then (min(X0, X1), max(X0, X1)) -> (X0, X1) endif;
        X0 and ceil(X0) -> X0; X1 and floor(X1) -> X1;
        if Y0 and Y1 then (min(Y0, Y1), max(Y0, Y1)) -> (Y0, Y1) endif;
        Y0 and ceil(Y0) -> Y0; Y1 and floor(Y1) -> Y1;
    endif
enddefine;

define appellipse(x0, y0, a, b, phi, proc);
    ;;; Calls proc(x,y) for each pixel x,y in the ellipse, if it is
    ;;; also within the region given by bounds (if given).

    ;;; Does shorter axis fastest to avoid leaving gaps.

    ;;; Main loop variables (declare first for register allocation)
    lvars x, y;

    lvars region = false, bounds = false, procedure proc;

    ;;; Get optional arguments
    if phi.islist or phi.isarray then
        (x0, y0, a, b, phi) -> (x0, y0, a, b, phi, bounds)
    endif;
    if phi.islist then
        (x0, y0, a, b, phi, bounds) -> (x0, y0, a, b, phi, region, bounds)
    endif;
    if bounds.isarray then boundslist(bounds) -> bounds endif;

    ;;; Convert to matrix equation
    lvars t11, t22, t12;
    ellipsematrix(x0, y0, a, b, phi) -> (x0, y0, t11, t12, t22);

    ;;; Convert to image coords
    if region and bounds then
        ellipse_map(x0, y0, t11, t12, t22, region, bounds)
            -> (x0, y0, t11, t12, t22)
    endif;

    lvars (X0, X1, Y0, Y1) = fixbounds(bounds);

    ;;; Loop over x or y depending on whether extent is greater in x or
    ;;; y direction. Repeat the code to avoid test in inner loop.

    if t11 > t22 then

        ;;; Constants in equations for x as a function of y
        lvars t1, t2, yoff,
            (k1, k2, k3) = ellipsequation(t11, t12, t22),
            vmax = sqrt(t11 / (t11*t22 - t12*t12)),
            (ystart, yend) = clip(round(y0 - vmax), round(y0 + vmax), Y0, Y1);

        for y from ystart to yend do
            y - y0 -> yoff;
            k2 * yoff * yoff + k3 -> t2;
            if t2 >= 0 then     ;;; rounding errors can give t2 < 0
                x0 + k1 * yoff -> t1;
                sqrt(t2) -> t2;
                lvars
                    (xstart, xend) = clip(round(t1-t2), round(t1+t2), X0, X1);
                for x from xstart to xend do
                    proc(x, y)
                endfor
            endif
        endfor

    else

        ;;; Constants in equations for y as a function of x
        lvars t1, t2, xoff,
            (k1, k2, k3) = ellipsequation(t22, t12, t11),
            vmax = sqrt(t22 / (t11*t22 - t12*t12)),
            (xstart, xend) = clip(round(x0 - vmax), round(x0 + vmax), X0, X1);

        for x from xstart to xend do
            x - x0 -> xoff;
            k2 * xoff * xoff + k3 -> t2;
            if t2 >= 0 then
                y0 + k1 * xoff -> t1;
                sqrt(t2) -> t2;
                lvars
                    (ystart, yend) = clip(round(t1- t2), round(t1+t2), Y0, Y1);
                for y from ystart to yend do
                    proc(x, y)
                endfor
            endif
        endfor

    endif

enddefine;

define appellipse_rim(x0, y0, a, b, phi, proc);
    ;;; Calls proc(x,y) for each pixel x,y on the boundary of the ellipse.
    ;;; Arguments as for appellipse.

    lvars x, y;
    lvars region = false, bounds = false, procedure proc;

    ;;; Get optional arguments
    if phi.islist or phi.isarray then
        (x0, y0, a, b, phi) -> (x0, y0, a, b, phi, bounds)
    endif;
    if phi.islist then
        (x0, y0, a, b, phi, bounds) -> (x0, y0, a, b, phi, region, bounds)
    endif;
    if bounds.isarray then boundslist(bounds) -> bounds endif;

    ;;; Get control matrix
    lvars t11, t22, t12;
    ellipsematrix(x0, y0, a, b, phi) -> (x0, y0, t11, t12, t22);

    ;;; Convert to image coords
    if region and bounds then
        ellipse_map(x0, y0, t11, t12, t22, region, bounds)
            -> (x0, y0, t11, t12, t22)
    endif;

    ;;; Find points of unit slope - switch over at these from
    ;;; incrementing x to incrementing y.
    lvars
        D = t11 * t22 - t12 * t12,
        T = t11 + t22,
        Twot12 = 2*t12,

        denom1 = sqrt(D * (T - Twot12)),
        Xt1 = (t22 - t12) / denom1,
        Yt1 = (t11 - t12) / denom1,
        denom2 = sqrt(D * (T + Twot12)),
        Xt2 = - (t22 + t12) / denom2,
        Yt2 = (t11 + t12) / denom2,

    ;;; Constants in equations for x as a function of y and vice versa
        (k1x, k2x, k3x) = ellipsequation(t11, t12, t22),
        (k1y, k2y, k3y) = ellipsequation(t22, t12, t11),
        xoff, yoff, t1, t2;

    ;;; Ellipse equations
    define lconstant yfnp(x) -> y; YFN(+) enddefine;
    define lconstant yfnm(x) -> y; YFN(-) enddefine;
    define lconstant xfnp(y) -> x; XFN(+) enddefine;
    define lconstant xfnm(y) -> x; XFN(-) enddefine;

    ;;; Do each of the four quadrants separately. Could save some
    ;;; work by using symmetry - but possibly not worth it.

    ;;; Get start and end points for each segment.
    lvars
        (xs1, xe1) = (round(x0+Xt2), round(x0+Xt1)),
        (ys1, ye1) = (yfnp(xs1), yfnp(xe1)),
        (ys2, ye2) = (round(y0+Yt1), round(y0-Yt2)),
        (xs2, xe2) = (xfnp(ys2), xfnp(ye2)),
        (xs3, xe3) = (round(x0-Xt2), round(x0-Xt1)),
        (ys3, ye3) = (yfnm(xs3), yfnm(xe3)),
        (ys4, ye4) = (round(y0-Yt1), round(y0+Yt2)),
        (xs4, xe4) = (xfnm(ys4), xfnm(ye4));

    ;;; Retreat if rounded end points outside ellipse bounds
    unless ys1 then xs1+1 -> xs1; yfnp(xs1) -> ys1 endunless;
    unless ye1 then xe1-1 -> xe1; yfnp(xe1) -> ye1 endunless;
    unless xs2 then ys2-1 -> ys2; xfnp(ys2) -> xs2 endunless;
    unless xe2 then ye2+1 -> ye2; xfnp(ye2) -> xe2 endunless;
    unless ys3 then xs3-1 -> xs3; yfnm(xs3) -> ys3 endunless;
    unless ye3 then xe3+1 -> xe3; yfnm(xe3) -> ye3 endunless;
    unless xs4 then ys4+1 -> ys4; xfnm(ys4) -> xs4 endunless;
    unless xe4 then ye4-1 -> ye4; xfnm(ye4) -> xe4 endunless;

    ;;; Avoid overlaps
    ;;; between adjacent segments (though not between opposite ones).
    if xe1 >= xs2 and ye1 <= ys2 then ye1-1 -> ys2 endif;
    if xe2 <= xs3 and ye2 <= ys3 then xe2-1 -> xs3 endif;
    if xe3 <= xs4 and ye3 >= ys4 then ye3+1 -> ys4 endif;
    if xe4 >= xs1 and ye4 >= ys1 then xe4+1 -> xs1 endif;

    ;;; clip to box
    lvars (X0, X1, Y0, Y1) = fixbounds(bounds);
    clip(xs1, xe1, X0, X1) -> (xs1, xe1);
    clip(ye2, ys2, Y0, Y1) -> (ye2, ys2);
    clip(xe3, xs3, X0, X1) -> (xe3, xs3);
    clip(ys4, ye4, Y0, Y1) -> (ys4, ye4);

    ;;; Do the drawing.
    for x from xs1 to xe1 do
        YFN(+);
        unless (Y0 and y < Y0) or (Y1 and y > Y1) then
            proc(x, y)
        endunless
    endfor;
    for y from ys2 by -1 to ye2 do
        XFN(+);
        unless (X0 and x < X0) or (X1 and x > X1) then
            proc(x, y)
        endunless
    endfor;
    for x from xs3 by -1 to xe3 do
        YFN(-);
        unless (Y0 and y < Y0) or (Y1 and y > Y1) then
            proc(x, y)
        endunless
    endfor;
    for y from ys4 to ye4 do
        XFN(-);
        unless (X0 and x < X0) or (X1 and x > X1) then
            proc(x, y)
        endunless
    endfor;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Sep  5 2000
        Removed bug that prevented ______bounds from being an array.
--- David Young, Jun  2 2000
        Completely revised and improved algorithm for avoiding overlap
        in appellipse_rim. Also generally tidied up.
--- David Young, Jun  1 2000
        Made ______bounds argument optional.
 */
