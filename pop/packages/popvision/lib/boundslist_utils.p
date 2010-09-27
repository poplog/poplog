/* --- Copyright University of Sussex 2001. All rights reserved. ----------
 > File:            $popvision/lib/boundslist_utils.p
 > Purpose:         Manipulate boundslist-type lists
 > Author:          David S Young, Jun  3 1992 (see revisions)
 > Documentation:   HELP BOUNDSLIST_UTILS
 */

compile_mode:pop11 +strict;

uses popvision
uses erandom

section;

/* Small utilities for manipulating
boundslist and boundslist-type lists specifying rectangular
(or hyper-rectangular) regions of arrays. */

define:inline lconstant getbounds(bounds);
    if bounds.isarray then boundslist(bounds) -> bounds endif
enddefine;

define region_inclusion_check(reg1, reg2);
    ;;; Mishaps unless reg2 is entirely within reg1, where
    ;;; regions have the structure of boundslists of
    ;;; any number of dimensions. If arrays are passed, their
    ;;; boundslists are considered.
    lvars r1, r2, 6 test = nonop >, 6 othertest = nonop <;
    getbounds(reg1); getbounds(reg2);
    unless length(reg1) == length(reg2) then
        mishap(reg1, reg2, 2, 'Regions different dimensions')
    endunless;
    for r1, r2 in reg1, reg2 do
        if r1 test r2 then
            mishap(reg1, reg2, 2, 'Region 2 not inside region 1')
        endif;
        (nonop test, nonop othertest) -> (nonop othertest, nonop test)
    endfor
enddefine;

define lconstant region_containspoint_stack(/* x,y,z, ..., */ reg) -> bool;
    lvars ndim = length(reg) div 2, idim = ndim;
    true -> bool;
    until reg == [] do
        lvars
            x = subscr_stack(idim),
            (x0, x1) = (destpair(destpair(reg)) -> reg);
        if(x < x0 or x > x1) then
            false -> bool;
            quitloop
        endif;
        idim fi_- 1 -> idim
    enduntil;
    erasenum(ndim)
enddefine;

define lconstant region_containspoint_list(p, reg) -> bool;
    lvars x, x0, x1;
    true -> bool;
    for x in p do
        destpair(destpair(reg)) -> (x0, x1, reg);
        if(x < x0 or x > x1) then
            false -> bool;
            quitloop
        endif
    endfor
enddefine;

define region_containspoint(p, reg) /* -> bool */;
    ;;; Returns true or false depending on whether the point
    ;;; specified is inside the region.
    getbounds(reg);
    if p.isnumber then
        region_containspoint_stack(p, reg)
    else
        region_containspoint_list(p, reg)
    endif
enddefine;

define region_nonempty_check(regin);
    ;;; Mishaps unless reg is a non-null array region
    getbounds(regin);
    lvars reg = regin, x0, x1;
    until reg == [] do
        destpair(destpair(reg)) -> (x0, x1, reg);
        if x1 < x0 then
            mishap(regin, 1, 'Invalid region for operation')
        endif
    enduntil
enddefine;

define region_intersect(reg1, reg2) /* -> region */;
    ;;; Returns the intersection of reg1 and reg2.
    lvars r1, r2, op = max, otherop = min;
    getbounds(reg1); getbounds(reg2);
    unless length(reg1) == length(reg2) then
        mishap(reg1, reg2, 2, 'Regions different dimensions')
    endunless;
    [% for r1, r2 in reg1, reg2 do
            op(r1, r2);     ;;; in list
            (op, otherop) -> (otherop, op)
        endfor %]
enddefine;

define region_bounding(reg1, reg2) /* -> region */;
    ;;; Returns the region that bounds both reg1 and reg2.
    lvars r1, r2, op = min, otherop = max;
    getbounds(reg1); getbounds(reg2);
    unless length(reg1) == length(reg2) then
        mishap(reg1, reg2, 2, 'Regions different dimensions')
    endunless;
    [% for r1, r2 in reg1, reg2 do
            op(r1, r2);     ;;; in list
            (op, otherop) -> (otherop, op)
        endfor %]
enddefine;

define region_centre(reg) /* -> xc, yc, ... */;
    ;;; Returns, on the stack, the coordinates of the the centre of the
    ;;; region, not rounded.
    getbounds(reg);
    until reg == [] do
        lvars (x0, x1) = (dest(dest(reg)) -> reg);
        (x0+x1) / 2.0         ;;; on stack
    enduntil
enddefine;

define updaterof region_centre(/* xc, yc, ... */ reg) -> region;
    ;;; Returns a new region which is the same size in each dimension
    ;;; as regin, but which is centred on the coordinates which precede
    ;;; reg on the stack. (Must be the right number of them.)
    ;;; Will round to integers if optional last arg is true.
    lvars doround = false;
    if reg.isboolean then
        reg -> (reg, doround)
    endif;
    getbounds(reg);
    lvars x0, x1, s, x0n, N2 = length(reg), N = N2 div 2, N0 = N;
    until reg == [] do
        dest(dest(reg)) -> (x0, x1, reg);
        subscr_stack(N) - (x0+x1)/2.0 -> s;
        x0 + s -> x0n;
        if doround then round(x0n) -> x0n endif;
        x0n, x1 + x0n - x0;     ;;; on stack to go into result.
        N + 1 -> N;             ;;; maintain stack offset
    enduntil;
    conslist(N2) -> region;
    erasenum(N0);
enddefine;

define region_conv_output(reg1, reg2) /* -> newreg */;
    ;;; Returns the output region for an N-D convolution of an array of
    ;;; size reg1 with a mask of size reg2
    getbounds(reg1); getbounds(reg2);
    unless length(reg1) == length(reg2) then
        mishap(reg1, reg2, 2, 'Regions different dimensions')
    endunless;
    lvars x0, x1, y0, y1;
    [% until reg1 == [] do
            destpair(destpair(reg1)) -> (x0, x1, reg1);
            destpair(destpair(reg2)) -> (y0, y1, reg2);
            x0 + y1, x1 + y0                ;;; into list
        enduntil  %]
enddefine;

define region_conv_input(reg1, reg2) /* -> newreg */;
    ;;; Returns the input region for an N-D convolution
    ;;; producing out of size reg1 with a mask of size reg2
    getbounds(reg1); getbounds(reg2);
    unless length(reg1) == length(reg2) then
        mishap(reg1, reg2, 2, 'Regions different dimensions')
    endunless;
    lvars x0, x1, y0, y1;
    [% until reg1 == [] do
            destpair(destpair(reg1)) -> (x0, x1, reg1);
            destpair(destpair(reg2)) -> (y0, y1, reg2);
            x0 - y1, x1 - y0                ;;; into list
        enduntil  %]
enddefine;

define region_size(arr) /* -> size */;
    if arr.isarray then
        datalength(arr)
    else
        1;
        until arr == [] do
            * (- (dest(arr) -> arr) + (dest(arr) -> arr) + 1)
        enduntil
    endif
enddefine;

define nthbounds(arr, n) /* -> (b1, b2) */;
    lvars n2 = n fi_* 2;
    getbounds(arr);
    arr(n2 fi_- 1), arr(n2)
enddefine;

define updaterof nthbounds(/* b1, b2, */ list, n) with_nargs 4;
    lvars n2 = n fi_* 2;
    /* (b1, b2) */ -> (list(n2 fi_- 1), list(n2))
enddefine;

define region_rep(region) /* -> rep */;
    ;;; Returns a repeater which itself returns successive sets of coords
    ;;; from the region (putting them in a vector). The contents of the
    ;;; vector must not be altered between calls.
    ;;; An array can be given as an argument.
    ;;; First coord interates fastest.
    ;;; Returns termin when it has finished.
    getbounds(region);
    lvars len = length(region) div 2,
        coords = initv(len),
        maxcoords = initv(len),
        mincoords = initv(len),
        i;
    for i from 1 to len do
        dest(region) -> region ->> coords(i) -> mincoords(i);
        dest(region) -> region -> maxcoords(i)
    endfor;
    coords(1) - 1 -> coords(1);     ;;; point before start

    procedure /* -> coords */;
        lvars i, c;
        fast_for i from 1 to len do
            fast_subscrv(i,coords) fi_+ 1 ->> fast_subscrv(i,coords) /* -> c */;
        returnif (/* c */ fi_<= fast_subscrv(i, maxcoords)) (coords);
            fast_subscrv(i, mincoords) -> fast_subscrv(i, coords)
        endfor;
        return(termin)
    endprocedure

enddefine;

define region_randsample(reg) -> rep;
    ;;; Returns a repeater than randomly samples uniformly within the
    ;;; region. Results not rounded.
    lvars procedure rep;
    lvars x0, x1, reps;
    getbounds(reg);
    [% until reg == [] do
            dest(dest(reg)) -> (x0, x1, reg);
            erandom([uniform % number_coerce(x0, 0.0), x1 %]) ;;; procedure on stack
        enduntil %] -> reps;

    define lvars rep;
        applist(reps, fast_apply)
    enddefine;
enddefine;

define array_dimprods(bounds) /* -> arrprods */;
    ;;; Returns a list of the array dimension products
    lvars x0, x1, c, t = 1;
    getbounds(bounds);
    [%  until bounds == [] do
            t;  ;;; into list with it
            destpair(destpair(bounds)) -> (x0, x1, bounds);
            x1 - x0 + 1 -> c;       ;;; current dimension
            c * t -> t;        ;;; subarray size
        enduntil %]
enddefine;

define array_dimsizes(bounds) /* -> sizes */;
    getbounds(bounds);
    [% until bounds == [] do
            - (destpair(bounds) -> bounds) + (destpair(bounds) -> bounds) + 1
        enduntil %]
enddefine;

define array_dimbases(bounds) /* -> bases */;
    ;;; Returns a list of the array lower limits
    getbounds(bounds);
    [%  until bounds == [] do
            dest(bounds) -> bounds; ;;; leave hd on stack
            tl(bounds) -> bounds;
        enduntil %]
enddefine;

define array_dimtops(bounds) /* -> bases */;
    ;;; Returns a list of the array upper limits
    getbounds(bounds);
    [%  until bounds == [] do
            tl(bounds) -> bounds;
            dest(bounds) -> bounds; ;;; leave hd on stack
        enduntil %]
enddefine;

define region_map(rega, regb) -> (mapab, mapba);
    ;;; Return procedures which perform a linear map from region a to
    ;;; region b and back again. Each procedure takes the same number of
    ;;; arguments as the dimensionality of the regions, and returns
    ;;; that number of results.
    lconstant tofloat = number_coerce(% 0.0 %);  ;;; no ratios wanted probably
    getbounds(rega);  getbounds(regb);
    unless length(rega) == length(regb) then
        mishap(rega, regb, 2, 'Regions different dimensions')
    endunless;
    lvars l = length(rega) div 2;

    ;;; Build lists of size ratios and origins for linear maps.
    ;;; These will be in reverse order to the arguments.
    lvars a0, a1, b0, b1, asize, bsize, ratioab, ratioba,
        ratiosab = [], ratiosba = [], originsab = [], originsba = [];
    until rega == [] do
        dest(rega) -> (a0, rega); dest(rega) -> (a1, rega);
        dest(regb) -> (b0, regb); dest(regb) -> (b1, regb);
        tofloat(a1 - a0) -> asize;  tofloat(b1 - b0) -> bsize;
        bsize/asize ->> ratioab; conspair(ratiosab) -> ratiosab;
        asize/bsize ->> ratioba; conspair(ratiosba) -> ratiosba;
        conspair(b0 - a0 * ratioab, originsab) -> originsab;
        conspair(a0 - b0 * ratioba, originsba) -> originsba;
    enduntil;

    if l == 1 then
        ;;; Treat single dimension as special case, for efficiency
        define lconstant linmap1(/* x, */ m, c) /* -> y */ with_nargs 3;
            lvars m, c, x;
            /* x */ * m + c
        enddefine;

        ;;; Explicit closures more efficient than implicit
        linmap1(% ratioab, hd(originsab) %) -> mapab;
        linmap1(% ratioba, hd(originsba) %) -> mapba;

    elseif l == 2 then
        ;;; And why not make 2-D a special case too - just a few more
        ;;; lines of code, and likely to be used a lot.
        ;;; (Actually, the difference is rather little)
        define lconstant linmap2(x1, x2, m1, m2, c1, c2) /* -> (y1, y2) */;
            lvars m1, m2, c1, c2, x1, x2;
            m1 * x1 + c1 /* -> y1 */;
            m2 * x2 + c2 /* -> y1 */;
        enddefine;

        linmap2(% explode(ncrev(ratiosab)), explode(ncrev(originsab)) %)
             -> mapab;
        linmap2(% explode(ncrev(ratiosba)), explode(ncrev(originsba)) %)
            -> mapba;

    else
        ;;; More than 2-D, so use the lists

        define lconstant linmapn(storevec, n, ms, cs);
            ;;; Storevec is supplied as an argument to avoid having to build
            ;;; a new vector each time.
            lvars storevec, n, ms, cs;
            lvars m, c;
            fast_for m, c in ms, cs do
                /* argument off stack */ * m + c -> fast_subscrv(n, storevec);
                n fi_- 1 -> n
            endfor;
            explode(storevec) /* results on stack */
        enddefine;

        lvars storevec = initv(l);
        linmapn(% storevec, l, ratiosab, originsab %) -> mapab;
        linmapn(% storevec, l, ratiosba, originsba %) -> mapba;
        l ->> pdnargs(mapab) -> pdnargs(mapba)
    endif
enddefine;

define region_scale(rega, regb) -> (mapab, mapba);
    ;;; Like region_map, but the procedures just scale their arguments,
    ;;; not shift them as well.
    lconstant
        tofloat = number_coerce(% 0.0 %);     ;;; no ratios wanted probably
    getbounds(rega);  getbounds(regb);
    unless length(rega) == length(regb) then
        mishap(rega, regb, 2, 'Regions different dimensions')
    endunless;
    lvars l = length(rega) div 2;

    lvars a0, a1, b0, b1, asize, bsize, ratioab, ratioba,
        ratiosab = [], ratiosba = [];
    until rega == [] do
        dest(rega) -> (a0, rega); dest(rega) -> (a1, rega);
        dest(regb) -> (b0, regb); dest(regb) -> (b1, regb);
        tofloat(a1 - a0) -> asize;  tofloat(b1 - b0) -> bsize;
        bsize/asize ->> ratioab; conspair(ratiosab) -> ratiosab;
        asize/bsize ->> ratioba; conspair(ratiosba) -> ratiosba;
    enduntil;

    if l == 1 then
        nonop * (% ratioab %) -> mapab;
        nonop * (% ratioba %) -> mapba;
    elseif l == 2 then
        define lconstant scale2(x1, x2, m1, m2) /* -> (y1, y2) */;
            lvars m1, m2, x1, x2;
            m1 * x1 /* -> y1 */;
            m2 * x2 /* -> y1 */;
        enddefine;
        scale2(% explode(ncrev(ratiosab)) %) -> mapab;
        scale2(% explode(ncrev(ratiosba)) %) -> mapba;
    else
        define lconstant scalen(storevec, n, ms);
            lvars storevec, n, ms;
            lvars m;
            fast_for m in ms do
                /* argument off stack */ * m -> fast_subscrv(n, storevec);
                n fi_- 1 -> n
            endfor;
            explode(storevec) /* results on stack */
        enddefine;

        lvars storevec = initv(l);
        scalen(% storevec, l, ratiosab %) -> mapab;
        scalen(% storevec, l, ratiosba %) -> mapba;
        l ->> pdnargs(mapab) -> pdnargs(mapba)
    endif
enddefine;

define region_expand(reg, n) /* -> newreg */;
    ;;; Expands a region by n along every axis.
    getbounds(reg);
    [% until reg == [] do
            (destpair(reg) -> reg) - n;
            (destpair(reg) -> reg) + n;
        enduntil
    %]
enddefine;

define array_indexer(bounds) /* -> indexer */;
    ;;; Returns a procedure that looks like the array given,
    ;;; but which when called just returns the index into
    ;;; the arrayvector.
    ;;; If a second option argument is true, then the procedure generated
    ;;; checks that its arguments are withing the original bounds.
    ;;; Can also be called just with the boundslist as argument.

    lvars check = false, indexer;
    if bounds.isboolean then
        bounds -> (bounds, check)
    endif;

    lvars b x0 x1 c dimlist minsublist
        arrstart = 1,
        t = 1;

    ;;; need local version of erase because newanyarray requires its
    ;;; subscriptor to have a formal updater.
    define lconstant eras; erase() enddefine;
    define updaterof eras; erasenum(3); enddefine;

    if bounds.isarray then
        arrayvector_bounds(bounds) -> arrstart -> ;
        boundslist(bounds) -> bounds;
    endif;

    if check then   ;;; generate checking procedure

        newanyarray(bounds,identfn,eras,arrstart-1) /* -> indexer */


    else            ;;; non-checking procedure
        ncrev(array_dimprods(bounds)) -> dimlist;
        ncrev(array_dimbases(bounds)) -> minsublist;

        procedure -> offset;
            lvars v, offset = arrstart, dlist = dimlist, slist = minsublist;
            until dlist == [] do
                    -> v;       ;;; take from stack
                (v - (fast_destpair(slist) -> slist))
                * (fast_destpair(dlist) -> dlist) + offset -> offset
            enduntil;
        endprocedure /* -> offsetter */;
        ;;; would be nice to set pdnargs, but cannot for some reason

    endif
enddefine;

define array_stepsize(arr, dir) /* -> stepsize */;
    ;;; Returns the step in the array vector corresponding to
    ;;; an increment of 1 along the dimension specified by dir
    array_dimprods(arr)(dir)
enddefine;

define region_arrvec(array, region) -> (i1, n);
    ;;; If the region represents a continuous section of the array vector of
    ;;; the array, return the starting index into the array vector and
    ;;; the number of points in it. Otherwise, return two false values.
    ;;; Can be called with an indexer procedure instead of an array.
    lvars i2, r;
    if array.isarray or array.islist then
        array_indexer(array, true) -> array
    endif;

    ;;; Get lowest and highest indexes of region
    region -> r;
    array(until r == [] do (dest(r) -> r); (tl(r) -> r) enduntil) -> i1;
    region -> r;
    array(until r == [] do (tl(r) -> r); (dest(r) -> r) enduntil) -> i2;
    i2 - i1 + 1 -> n;

    ;;; Check it is continuous
    unless region_size(region) == n then
        false ->> i1 -> n
    endunless
enddefine;

global vars boundslist_utils = true;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Apr 10 2001
        Added updater of region_centre.
--- David Young, Mar 27 2000
        Added region_centre, region_randsample and region_containspoint.
--- David S Young, Dec  2 1998
        Made getbounds inline and did some general tidying.
--- David S Young, Jan 30 1993
        Added region_conv_input and region_conv_output.
--- David Young, Nov 12 1992
        Added region_map and region_scale.
--- David S Young, Jun  6 1992
        Added region_size, array_dimsizes and region_arrvec.
 */
