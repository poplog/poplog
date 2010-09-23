/* --- Copyright University of Sussex 2006. All rights reserved. ----------
 > File:            $popvision/lib/canny.p
 > Purpose:         Edge detector based on Canny's paper
 > Author:          David Young, Nov 12 1992 (see revisions)
 > Documentation:   HELP *CANNY
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses convolve_gauss_2d
uses arraysample
uses boundslist_utils
uses float_arrayprocs
uses pop_radians

define canny1(arrin, sigma, xdiff, ydiff) -> (xdiff, ydiff, g);
    ;;; Smoothing, differentiation, and finding gradient magnitude
    lvars arrin, sigma, xdiff, ydiff, g;
    ;;; work out output size
    lvars outbounds = region_expand(arrin, -diffgaussmask_limit(sigma));

    if xdiff and boundslist(xdiff) /= outbounds then
        mishap(xdiff, outbounds, 1, 'Wrong size array for x derivative')
    endif;
    if ydiff and boundslist(ydiff) /= outbounds then
        mishap(ydiff, outbounds, 1, 'Wrong size array for y derivative')
    endif;

    xdiff or newsfloatarray(outbounds) -> xdiff;
    ydiff or newsfloatarray(outbounds) -> ydiff;

    convolve_gauss_2d(arrin, [smoothy ^sigma diffx ^sigma], xdiff) -> xdiff;
    convolve_gauss_2d(arrin, [smoothx ^sigma diffy ^sigma], ydiff) -> ydiff;
    float_arrayhypot(xdiff, ydiff, oldsfloatarray(canny1, boundslist(xdiff)))
        -> g;
enddefine;

/* This POP-11 non-maximum suppresssion routine has been superseded
by the one that calls C code that follows. They should behave the
same way, except that directions are no longer calculated.

define canny2(xdiff, ydiff, g) -> (newg, dirs);
    ;;; Non-maximum suppression
    lvars xdiff, ydiff, g;
    lvars x, y, ux, uy, gc, g0,
        b = boundslist(g),
        newg = newsfloatarray(b, 0.0),
        dirs = newsfloatarray(b, 0.0),
        (x0, x1, y0, y1) = explode(b),
        x0p1 = x0+1, x1m1 = x1-1, t;

    fast_for y from y0+1 to y1-1 do
        fast_for x from x0p1 to x1m1 do
            xdiff(x,y) -> ux;
            ydiff(x,y) -> uy;
            g(x,y) -> gc;
            ;;; Four octants of slope direction within a half circle.
            ;;; For each, estimate slope on the boundary of the square round
            ;;; (x,y) by linear interpolation between two points.
            if ux*uy > 0 then
                uy - ux -> t;
                if abs(ux) < abs(uy) then
                nextif ((abs(uy * gc) ->> g0) <=
                        abs(ux * g(x fi_+ 1, y fi_+ 1) + t * g(x, y fi_+ 1))
                    or
                        g0 <=
                        abs(ux * g(x fi_- 1, y fi_- 1) + t * g(x, y fi_- 1)))
                else
                nextif ((abs(ux * gc) ->> g0) <=
                        abs(uy * g(x fi_+ 1, y fi_+ 1) - t * g(x fi_+ 1, y))
                    or
                        g0 <=
                        abs(uy * g(x fi_- 1, y fi_- 1) - t * g(x fi_- 1, y)))
                endif
            else
                uy + ux -> t;
                if abs(ux) < abs(uy) then
                nextif ((abs(uy * gc) ->> g0) <=
                        abs(ux * g(x fi_+ 1, y fi_- 1) - t * g(x, y fi_- 1))
                    or
                        g0 <=
                        abs(ux * g(x fi_- 1, y fi_+ 1) - t * g(x, y fi_+ 1)))
                else
                nextif ((abs(ux * gc) ->> g0) <=
                        abs(uy * g(x fi_+ 1, y fi_- 1) - t * g(x fi_+ 1, y))
                    or
                        g0 <=
                        abs(uy * g(x fi_- 1, y fi_+ 1) - t * g(x fi_- 1, y)))
                endif
            endif;
            ;;; If any of the conditions has been satisfied, will skip this
            gc -> newg(x,y);
            arctan2(ux, uy) -> dirs(x,y)
        endfor
    endfor
enddefine;

*/

lconstant macro extname = 'canny',
    obfile = objectfile(extname);

unless obfile then
    mishap(0, 'Cannot file object file')
endunless;

;;; Altered [A.S]
;;; exload extname [^obfile '-lm']
exload extname [^obfile ]
    EXT_canny2_f(6)                     <- canny2_f
endexload;

define lconstant setsfloatzero(arr);
    lvars arr;
    lvars (i2, i1) = arrayvector_bounds(arr);
    set_subvector(0.0, i1, arrayvector(arr), i2 - i1 + 1)
enddefine;

define canny2(xdiff, ydiff, g, newg) -> newg;
    ;;; Non-maximum suppression
    lvars xdiff, ydiff, g, newg;
    lvars
        b = boundslist(g),
        (x0, x1, y0, y1) = explode(b);
    if newg then
        setsfloatzero(newg)
    else
        newsfloatarray(b) -> newg
    endif;
    exacc EXT_canny2_f(arrayvector(xdiff), arrayvector(ydiff),
        arrayvector(g), arrayvector(newg), x1-x0+1, y1-y0+1);
enddefine;

/* This version of hysteresis thresholding superseded by slicker version
using appblobs, which avoids deep recursion. Using the direction information
when following lines makes little difference to the results (and can
be applied later if needed) so has been removed from the later version.
The appblobs version below is far faster.

define canny3(g, dirs, t1, t2, td) -> newg;
    ;;; Thresholding with hysteresis, following edges.
    lvars g, dirs, t1, t2, td, newg;
    lvars x, y, gg,
        (x0, x1, y0, y1) = explode(boundslist(g)),
        x0p1 = x0+1, x1m1 = x1-1,
        newg = newsfloatarray(boundslist(g), 0.0);

    define lconstant dirdiff(d1, d2) /* -> d */;
        ;;; Return difference between d1 and d2
        lvars d1, d2, d;
        ((d1 - d2) + pop_semicircle) mod pop_circle - pop_semicircle
    enddefine;

    define lconstant follow(x, y, gc, dc);
        lvars x, y, gc, dc;
        if newg(x,y) = 0.0 then
            ;;; Not been here before
            gc -> newg(x,y);
            lvars xfast, yfast, gg, dd, xm1 = x fi_- 1, xp1 = x fi_+ 1;
            fast_for yfast from y fi_- 1 to y fi_+ 1 do
                fast_for xfast from xm1 to xp1 do
                    if (g(xfast,yfast) ->> gg) >= t1 and
                        abs(dirdiff((dirs(xfast,yfast) ->> dd), dc)) <= td then
                        follow(xfast, yfast, gg, dd)
                    endif
                endfor
            endfor
        endif
    enddefine;

    fast_for y from y0+1 to y1-1 do
        fast_for x from x0p1 to x1m1 do
            if (g(x,y) ->> gg) >= t2 then
                follow(x, y, gg, dirs(x,y))
            endif
        endfor
    endfor

enddefine;

*/

uses appblobs

define canny3(g, t1, t2, newg) -> newg;
    lvars g, t1, t2, newg;

    ;;; Threshold absolutely at the low level
    float_threshold(0, t1, false, g, newg) -> newg;

    ;;; Retain only those connected segments that have some point exceeding
    ;;; or equalling the high threshold.

    ;;; First find which segments need to be retained
    defclass lconstant procedure blob {destroy, pixels};
    define lconstant RECORD(x, y, g) /*  -> blob */; lvars x, y, g;
        consblob(g < t2, conspair(conspair(x,y), []))
    enddefine;
    define updaterof RECORD(x, y, g, blob); lvars x, y, g, blob;
        if blob.destroy then
            g < t2 -> blob.destroy;
            conspair(conspair(x,y), blob.pixels) -> blob.pixels
        endif
    enddefine;
    define lconstant MERGE(blob1, blob2) -> blob1; lvars blob1, blob2;
        if blob1.destroy then
            blob2.destroy -> blob1.destroy;
            blob1.pixels nc_<> blob2.pixels -> blob1.pixels
        endif
    enddefine;
    lvars blob, pixel,
        destroyblobs = appblobs(newg, RECORD, MERGE, 8);

    ;;; Then set to zero those that have not passed
    fast_for blob in destroyblobs do
        if blob.destroy then
            fast_for pixel in blob.pixels do
                0.0s0 -> newg(fast_destpair(pixel))
            endfor
        endif
    endfor
enddefine;

define canny(image, sigma, threshlo, threshhi /*, xdiff, ydiff, gradients */)
        -> (xdiff, ydiff, gradients);
    ;;; Combines the separate Canny operations.
    lvars image, sigma, threshlo, threshhi, threshdir,
        xdiff = false, ydiff = false, gradients = false;

    ;;; Sort out arguments
    unless image.isarray then
        (image, sigma, threshlo, threshhi)
            -> (image, sigma, threshlo, threshhi, xdiff, ydiff, gradients)
    endunless;

    lvars rawgrads;
    canny1(image, sigma, xdiff, ydiff) -> (xdiff, ydiff, rawgrads);
    canny2(xdiff, ydiff, rawgrads, gradients) -> gradients;
    if threshlo then
        canny3(gradients, threshlo, threshhi, gradients) -> gradients
    endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 29 2006
		Removed -lm from exload commands
--- David Young, Apr  3 2000
        Changed dirdiff to use *pop_radians.
--- David S Young, Jan 20 1995
        Arrays to receive results can now be input to avoid creating
        garbage.
--- David S Young, Jul 13 1993
        Changed -newfloatarray- to -newsfloatarray- and -isfloatarray- to
        -issfloatarray- to avoid name clash with *VEC_MAT package.
--- David S Young, Nov 26 1992
        Installed
 */
