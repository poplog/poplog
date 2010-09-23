/* --- Copyright University of Sussex 2006. All rights reserved. ----------
 > File:            $popvision/lib/straight_hough.p
 > Purpose:         Straight line detection using the Hough transform
 > Author:          David Young, Nov 12 1992 (see revisions)
 > Documentation:   HELP *STRAIGHT_HOUGH
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses newsfloatarray
uses float_arrayprocs
uses convolve_gauss_2d
uses boundslist_utils
uses arraysample
uses array_wrap
uses array_peaks
uses pop_radians

/*

The C procedure called below does something like this ...

    ;;; Loop over the array looking for non-zero points
    fast_for y from y0 to y1 do
        fast_for x from x0 to x1 do
            if (image(x,y) ->> val) /= 0 then
                Tostand(x,y) -> (X,Y);

                ;;; Loop over theta, accumulating evidence for all lines
                ;;; passing through X, Y.
                1 -> cost;  0 -> sint;
                fast_for t from 0 to tstop do
                    ;;; Get R and convert to position in array
                    X * cost + Y * sint -> R;
                    intof(Rconv * R) -> r;
                    ;;; Accumulate array, dealing with negative R
                    if R < 0 then
                        ;;; Replace negative R by positive R and theta 180 degrees
                        ;;; different
                        -r -> r;
                        t + ntheta_half -> tt;
                        hough(r, tt) + val -> hough(r, tt);
                    else
                        hough(r, t) + val -> hough(r, t);
                    endif;

                    ;;; Update cos and sin theta using recurrence relns.
                    ;;; cos A+B = cos A cos B - sin A sin B
                    ;;; sin A+B = sin A cos B + cos A sin B
                    (cost * c - sint * s, sint * c + cost * s) -> (cost, sint);
                endfor
            endif
        endfor
    endfor;

*/

/* External procedure */

lconstant macro extname = 'straight_hough',
    obfile = objectfile(extname);

unless obfile then
    mishap(0, 'Cannot find object file')
endunless;

;;; Altered AS 29 Mar 2006
;;; exload extname [^obfile '-lm']
exload extname [^obfile ]
    EXT_straight_hough_array_f(17)         <- straight_hough_array_f
endexload;

define straight_hough_array(image, region, nr, ntheta, hough)
        -> (hough, rtheta, xc, yc);
    ;;; Takes an image with the properties described above, the number
    ;;; of bins for r, the number for theta, and returns the accumulator
    ;;; array and a procedure which translates from indexes in the accumulator
    ;;; array to r and theta in the image coordinates.
    ;;; If an array is supplied as the hough input argument, it must
    ;;; be zeroed by the calling procedure (unless additional
    ;;; accumulation is wanted). It must include the region
    ;;; [-1 nr -1 ntheta].
    ;;; xc and yc return the position of the centre of the
    ;;; coordinate system.

    lvars image, region, nr, ntheta, hough, procedure rtheta, xc, yc;

    ;;; If region is non-false, only the part of the image specified by
    ;;; it is processed.
    unless region then boundslist(image) -> region endunless;
    region_inclusion_check(image, region);
    ;;; Fix the image array if necessary
    unless image.issfloatarray then
        newsfloatarray(region, image) -> image
    endunless;
    region_nonempty_check(region);
    lvars
        (rx0, rx1, ry0, ry1) = explode(region),
        (x0, x1, y0, y1) = explode(boundslist(image));

    ;;; When we loop over theta, we only need to do half a circle,
    ;;; because lines have twofold symmetry. But the accumulator array
    ;;; has to cover a full circle (unless negative R values are allowed).
    ;;; Unless ntheta is even, things get complex at the middle value -
    ;;; so insist on this.
    lvars ntheta_half = ntheta div 2;
    unless ntheta_half * 2 == ntheta then
        mishap(ntheta, 1, 'No of theta bins must be even')
    endunless;

    ;;; Check supplied array, or make new one
    lvars
        rmax = nr - 1,
        tmax = ntheta - 1,
        tstop = ntheta_half - 1,
    ;;; The extra pixel in the r direction is protection against
    ;;; rounding errors.
        hough_bounds = [0 ^nr 0 ^tmax];
    if hough then
        unless hough.issfloatarray then
            mishap(hough, 1, 'Need packed float array')
        endunless;
        region_inclusion_check(hough, hough_bounds);
    else
        newsfloatarray(hough_bounds) -> hough    ;;; zeroed
    endif;
    lvars (hr0, hr1, ht0, ht1) = explode(boundslist(hough));

    lconstant
        twopi = 2 * pi,
        tofloat = number_coerce(% 0.0s0 %);
    lvars
        Tbin = twopi / ntheta,  ;;; external proc uses radians
    ;;; We work in coords centred in the region.
    ;;; Get the maximum possible radius to consider.
        xlimit = 0.5 * (rx1 - rx0),
        ylimit = 0.5 * (ry1 - ry0),
        Rmax = sqrt(xlimit * xlimit + ylimit * ylimit),
        Rconv = nr / Rmax,
        Rbin = Rmax / nr,
        xbegin = -Rconv * xlimit,
        ybegin = -Rconv * ylimit;

    exacc EXT_straight_hough_array_f (
        arrayvector(image),     ;;; arr
        x1 - x0 + 1,            ;;; xsize
        rx0 - x0,               ;;; xstart
        rx1 - x0,               ;;; xend
        ry0 - y0,               ;;; ystart
        ry1 - y0,               ;;; yend
        arrayvector(hough),     ;;; hough
        hr1 - hr0 + 1,          ;;; rsize
        -hr0,                   ;;; rstart
        rmax - hr0,             ;;; rend
        -ht0,                   ;;; tstart
        tstop - ht0,            ;;; tend
        tofloat(xbegin),        ;;; xbegin
        tofloat(ybegin),        ;;; ybegin
        tofloat(Rconv),         ;;; xincr
        tofloat(Rconv),         ;;; yincr
        tofloat(Tbin)           ;;; tbin
    );

    ;;; Provide a convenience translator from Hough pixels to
    ;;; R and Theta defined relative to image coordinates.
    ;;; Note that theta is anticlockwise from the X axis.
    ;;; r gets 0.5 added because of truncation in the external routine.
    ;;; but t is effectively rounded so does not need it.
    ;;; Fix Tbin if we are supposed to be working in degrees.
    Tbin * pop_radian -> Tbin;

    define lvars procedure rtheta(r, t) -> (R, T);
        lvars r, t, R, T;
        (r + 0.5) * Rbin -> R;
        t * Tbin -> T
    enddefine;

    rx0 + xlimit -> xc;
    ry0 + ylimit -> yc;
enddefine;

define straight_hough
        (image, region, nr, ntheta, sigmar, sigmat, avr, avt, threshold, hough)
        -> (hough, peaklist, xc, yc);
    lvars image, region, nr, ntheta, sigmar, sigmat, avr, avt, threshold,
        hough, peaklist, xc, yc;

    ;;; Work out the extra space needed in the accumulator array if
    ;;; smoothing and peak averaging are wanted.
    lvars extrar = 0, extrat = 0;
    if threshold then
        1 ->> extrar -> extrat
    endif;
    if avr then max(extrar, avr) -> extrar endif;
    if sigmar then
        extrar + gaussmask_limit(sigmar) -> extrar
    endif;
    if avt then max(extrat, avt) -> extrat endif;
    if sigmat then
        extrat + gaussmask_limit(sigmat) -> extrat
    endif;
    lvars
        rmax = nr - 1, tmax = ntheta - 1, hough_full_bounds;
    ;;; Note extra element at top r as rounding error protection
    [% -extrar, max(nr, rmax+extrar), -extrat, tmax+extrat %]
        -> hough_full_bounds;

    if hough then
        region_inclusion_check(hough, hough_full_bounds)
    else
        newsfloatarray(hough_full_bounds, 0) -> hough;
    endif;

    ;;; Fill accumulator
    lvars rtheta;
    straight_hough_array(image, region, nr, ntheta, hough)
        -> (hough, rtheta, xc, yc);

    ;;; Now reflect about R = 0 and wrap round on theta, in case smoothing
    ;;; or averaging are required. Leave high R values as zero.
    if extrar > 0 then
        lvars
            ntheta_half = ntheta div 2,
            tstop = ntheta_half - 1;
        arraysample(hough, [% 0, extrar-1, 0, tstop %],
            hough, [% -1, -extrar, ntheta_half, tmax %], "nearest") -> hough;
        arraysample(hough, [% 0, extrar-1, ntheta_half, tmax %],
            hough, [% -1, -extrar, 0, tstop %], "nearest") -> hough;
    endif;
    array_wrap(hough, [% -extrar, rmax, 0, tmax %],
        hough, [% -extrar, rmax, -extrat, tmax + extrat %]) -> hough;

    ;;; Smooth if required
    lvars gauss_ops = [];
    if sigmar then
        "smoothx" :: (sigmar :: gauss_ops) -> gauss_ops
    endif;
    if sigmat then
        "smoothy" :: (sigmat :: gauss_ops) -> gauss_ops
    endif;
    unless gauss_ops == [] then
        convolve_gauss_2d(hough, gauss_ops) -> hough
    endunless;

    ;;; Find peaks in smoothed array
    if threshold then
        threshold * float_arraymean(hough) -> threshold;
        array_peaks(hough, threshold, [% 0, rmax, 0, tmax %]) -> peaklist;
        ;;; Refine the peaks
        if avr then
            refine_peaks(hough, peaklist, avr, avt) -> peaklist
        endif;

        ;;; Finally, put the peaklist into array coords
        applist(peaklist,
            procedure(v); lvars v;
                rtheta(v(2), v(3)) -> (v(2), v(3))
            endprocedure)
    else
        rtheta -> peaklist
    endif;

enddefine;

define hough_linepoints(peak, xc, yc, bounds) -> (X0, Y0, X1, Y1);
    ;;; Return coords of intersections of line with box given by
    ;;; bounds, or falses if none.
    if bounds.isarray then boundslist(bounds) -> bounds endif;
    lvars
        ( , r, theta) = explode(peak),
        (x0, x1, y0, y1) = explode(bounds),
        c = cos(theta), s = sin(theta),
        flip = abs(c) > abs(s);
    if flip then
        ;;; line is nearer vertical than horizontal - flip over
        (s, c, x0, x1, y0, y1, xc, yc) ->
        (c, s, y0, y1, x0, x1, yc, xc)
    endif;

    define:inline intersecty(x);
        ((r - c * (x - xc)) / s + yc)
    enddefine;
    define:inline intersectx(y);
        ((r - s * (y - yc)) / c + xc)
    enddefine;

    ;;; line is within 45 degrees of horizontal so intersects sides extended
    intersecty(x0) -> Y0;     ;;; intersection with l side
    intersecty(x1) -> Y1;     ;;; intersection with r side
    if Y0 < y0 then
        if Y1 < y0 then
            (false, false, false, false) -> (X0,Y0, X1,Y1)
        else
            y0 -> Y0;
            intersectx(Y0) -> X0;
            if Y1 <= y1 then
                x1 -> X1
            else
                y1 -> Y1;
                intersectx(Y1) -> X1
            endif
        endif
    elseif Y0 > y1 then
        if Y1 > y1 then
            (false, false, false, false) -> (X0,Y0, X1,Y1)
        else
            y1 -> Y0;
            intersectx(Y0) -> X0;
            if Y1 >= y0 then
                x1 -> X1
            else
                y0 -> Y1;
                intersectx(Y1) -> X1
            endif
        endif
    else
        x0 -> X0;
        if Y1 < y0 then
            y0 -> Y1;
            intersectx(Y1) -> X1
        elseif Y1 > y1 then
            y1 -> Y1;
            intersectx(Y1) -> X1
        else
            x1 -> X1
        endif
    endif;

    if flip then
        (X0, Y0, X1, Y1) -> (Y0, X0, Y1, X1)
    endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 29 2006
		Removed -lm from exload command
		
--- David Young, Apr  3 2000
        Now uses pop_radian from LIB * POP_RADIANS.
--- David Young, Jan 28 2000
        Fixed hough_linepoints which did not truncate correctly
--- David S Young, Jan 27 1995
        convolve_gauss_2d called conditionally, only if needed
--- David S Young, Jul 13 1993
        Changed -newfloatarray- to -newsfloatarray- and -isfloatarray- to
        -issfloatarray- to avoid name clash with *VEC_MAT package.
--- David S Young, Jan 30 1993
        Modified setting of -hough_full_bounds- to provide better protection
        against going outside array after rounding errors.
 */
