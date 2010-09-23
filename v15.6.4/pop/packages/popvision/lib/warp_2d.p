/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 > File:            $popvision/lib/warp_2d.p
 > Purpose:         Apply an affine transformation to an image array
 > Author:          David S Young, Jul  9 1993 (see revisions)
 > Documentation:   HELP WARP_2D
 > Related Files:   warp_2d.c
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses objectfile
uses boundslist_utils
uses newsfloatarray

lconstant macro extname = 'warp_2d',
    obfile = objectfile(extname);

unless obfile then
    mishap(0, 'Cannot find object file')
endunless;

;;; Next declaration should not be lconstant in case another procedure
;;; uses this.
exload extname [^obfile]
    constant warp_n_f(15),
             warp_l_f(15),
             warp_nc_f(15),
             warp_lc_f(15)
endexload;

define warp_xy(x, y, T) /* -> xp, yp */;
    ;;; Linear transform of x, y given parameters T.
    lvars x, y, T, xp, yp;
    lvars Tx, Ty, Txx, Txy, Tyx, Tyy;
    if T.isnumber then
        (x, y, T) -> (x, y, Tx, Ty, Txx, Txy, Tyx, Tyy)
    else
        explode(T) -> (Tx, Ty, Txx, Txy, Tyx, Tyy)
    endif;
    Tx + Txx * x + Txy * y /* -> xp */;
    Ty + Tyx * x + Tyy * y /* -> yp */;
enddefine;

define warp_invert(T) -> Tx, Ty, Txx, Txy, Tyx, Tyy;
    ;;; Get parameters for inverse transform
    lvars T, Tx, Ty, Txx, Txy, Tyx, Tyy;
    if T.isnumber then
        T -> (Tx, Ty, Txx, Txy, Tyx, Tyy)
    else
        explode(T) -> (Tx, Ty, Txx, Txy, Tyx, Tyy)
    endif;
    lvars det = Txx * Tyy - Txy * Tyx;
    (Tyy / det, Txx / det) -> (Txx, Tyy);
    (-Txy / det, -Tyx / det) -> (Txy, Tyx);
    (-Tx * Txx - Ty * Txy,  -Tx * Tyx - Ty * Tyy) -> (Tx, Ty)
enddefine;

define lconstant solvematches(points) /* -> Tx, Ty, Txx, Txy, Tyx, Tyy */;
    ;;; Parameters for linear transform given three matching points.
    lvars points, Tx, Ty, Txx, Txy, Tyx, Tyy;
    lvars x1, y1, x1p, y1p, x2, y2, x2p, y2p, x3, y3, x3p, y3p;
    if points.isnumber then
        points
    else
        explode(points)
    endif -> (x1, y1, x1p, y1p, x2, y2, x2p, y2p, x3, y3, x3p, y3p);
    lvars
        t1 = x2 * y3 - x3 * y2,
        t2 = x3 * y1 - x1 * y3,
        t3 = x1 * y2 - x2 * y1,
        u1 = y2 - y3,
        u2 = y3 - y1,
        u3 = y1 - y2,
        v1 = x3 - x2,
        v2 = x1 - x3,
        v3 = x2 - x1,
        det = t1 + t2 + t3;
    (t1 * x1p + t2 * x2p + t3 * x3p) / det /* -> Tx */;
    (t1 * y1p + t2 * y2p + t3 * y3p) / det /* -> Ty */;
    (u1 * x1p + u2 * x2p + u3 * x3p) / det /* -> Txx */;
    (v1 * x1p + v2 * x2p + v3 * x3p) / det /* -> Txy */;
    (u1 * y1p + u2 * y2p + u3 * y3p) / det /* -> Tyx */;
    (v1 * y1p + v2 * y2p + v3 * y3p) / det /* -> Tyy */;
enddefine;

define warp_params(T) -> (Tx, Ty, Txx, Txy, Tyx, Tyy);
    ;;; Interpret a transformation specification. Allows a variety
    ;;; of ways of setting the parameters, ending up with the
    ;;; underlying matrix.
    lvars T,
        Tx = 0, Ty = 0, Txx = 1, Txy = 0, Tyx = 0, Tyy = 1;
    lvars
        nP = 0, useT = false, useV = false, useD = false, useE = false,
        x0 = 0, y0 = 0, x0p = false, y0p = false,
        E = 1, phi = 0, A = 1, theta = 0,
        vx = 0, vy = 0,
        vxx = 0, vxy = 0, vyx = 0, vyy = 0,
        D = 0, R = 0, S1 = 0, S2 = 0, S = false;

    ;;; Routines to step through a vector or list
    lvars iptr = 1, vecl;
    define lconstant nextvec /* -> val */;
        if iptr > vecl then termin
        else T(iptr); iptr + 1 -> iptr
        endif;
    enddefine;
    define lconstant nextlist /* -> val */;
        if T == [] then termin
        else dest(T) -> T
        endif
    enddefine;
    lvars procedure next;

    if T.isnumber then
        ;;; Assume matrix form, on stack
        T -> (Tx, Ty, Txx, Txy, Tyx, Tyy)
    elseif T.isvector and T(1).isnumber and length(T) == 6 then
        ;;; Assume matrix form, as vector
        explode(T) -> (Tx, Ty, Txx, Txy, Tyx, Tyy)
    else
        ;;; List or vector of alternating parameter names and values
        if T.isvector then
            length(T) -> vecl;
            nextvec -> next
        else
            nextlist -> next
        endif;
        lvars name;
        ;;; Loop through reading parameter name - value pairs
        until (next() ->> name) == termin do
            lowertoupper(name) -> name;
            if name == "P" then ;;; Point correspondence
                if nP == 0 then             ;;; first point
                    next() -> x0; next() -> y0;
                    unless next() == "->" then
                        mishap(0, 'Expecting ->')
                    endunless;
                    next() -> x0p; next() -> y0p;
                else    ;;; 2nd or 3rd point
                    next(); next();        ;;; just dump coords on stack
                    unless next() == "->" then
                        mishap(0, 'Expecting ->')
                    endunless;
                    next(); next();        ;;; coords on stack
                endif;
                nP + 1 -> nP
            elseif name == "P0" then
                ;;; fixed point params
                next() -> x0;   next() -> y0
                ;;; Otherwise one val per param
            elseif name == "TX" then next() -> Tx;          true -> useT
            elseif name == "TY" then next() -> Ty;          true -> useT
            elseif name == "TXX" then next() -> Txx;        true -> useT
            elseif name == "TXY" then next() -> Txy;        true -> useT
            elseif name == "TYX" then next() -> Tyx;        true -> useT
            elseif name == "TYY" then next() -> Tyy;        true -> useT
            elseif name == "E" then next() -> E;            true -> useE
            elseif name == "PHI" then next() -> phi;        true -> useE
            elseif name == "A" then next() -> A;            true -> useE
            elseif name == "THETA" then next() -> theta
            elseif name == "VX" then next() -> vx;          true -> useD
            elseif name == "VY" then next() -> vy;          true -> useD
            elseif name == "VXX" then next() -> vxx;        true -> useV
            elseif name == "VXY" then next() -> vxy;        true -> useV
            elseif name == "VYX" then next() -> vyx;        true -> useV
            elseif name == "VYY" then next() -> vyy;        true -> useV
            elseif name == "D" then next() -> D;            true -> useD
            elseif name == "R" then next() -> R;            true -> useD
            elseif name == "S1" then next() -> S1;          true -> useD
            elseif name == "S2" then next() -> S2;          true -> useD
            elseif name == "S" then next() -> S;            true -> useD
            else
                mishap(name, 1, 'Illegal transform parameter')
            endif
        enduntil;

        if useT then
            ;;; Need do nothing
        elseif nP > 1 then      ;;; Have point correspondences
            if nP > 3 then
                mishap(0, 'Too many points specified')
            endif;
            if nP == 2 then 0, 0, 0, 0 endif;           ;;; origin fixed
            solvematches(x0, y0, x0p, y0p /* rest on stack */)
                -> (Tx, Ty, Txx, Txy, Tyx, Tyy)
        elseif useV then
            1 + vxx -> Txx;     1 + vyy -> Tyy;
            vxy -> Txy;         vyx -> Tyx;
            vx - vxx * x0 - vxy * y0 -> Tx;
            vy - vyx * x0 - vyy * y0 -> Ty;
        elseif useD then
            if S then
                S * cos(2 * theta) -> S1;
                S * sin(2 * theta) -> S2
            endif;
            D + S1 -> vxx;      D - S1 -> vyy;
            1 + vxx -> Txx;     1 + vyy -> Tyy;
            S2 - R -> Txy;      S2 + R -> Tyx;
            vx - vxx * x0 - Txy * y0 -> Tx;
            vy - Tyx * x0 - vyy * y0 -> Ty;
        else
            unless x0p then x0 -> x0p endunless;
            unless y0p then y0 -> y0p endunless;
            lvars
                c = cos(theta), s = sin(theta),
                cc = c * c, ss = s * s, sc = s * c,
                flip = A < 0;
            sqrt(abs(A)) -> A;
            E * A -> S1;        E / A -> S2;
            if flip then -S2 -> S2 endif;
            ;;; Get shear and expansion matrix
            cc * S1 + ss * S2 -> Txx;
            sc * (S1 - S2) ->> Txy -> Tyx;
            ss * S1 + cc * S2 -> Tyy;
            ;;; Multiply by rotation matrix
            cos(phi) -> c;          sin(phi) -> s;
            c * Txx - s * Tyx,      c * Txy - s * Tyy,
            s * Txx + c * Tyx,      s * Txy + c * Tyy
                -> (Txx, Txy, Tyx, Tyy);
            x0p - Txx * x0 - Txy * y0 -> Tx;
            y0p - Tyx * x0 - Tyy * y0 -> Ty;
        endif
    endif
enddefine;

define warp_trans(T) -> (tf, tb);
    lvars T, tf, tb;
    lvars (Tx, Ty, Txx, Txy, Tyx, Tyy) = warp_params(T);
    warp_xy(% Tx, Ty, Txx, Txy, Tyx, Tyy %) -> tf;
    warp_xy(% warp_invert(Tx, Ty, Txx, Txy, Tyx, Tyy) %) -> tb
enddefine;


define lconstant floor(v) /* -> result */;
    lvars v;
    if v.isintegral or v mod 1.0 = 0.0 then
        intof(v)
    else
        round(v - 0.5)
    endif
enddefine;

define lconstant ceil(v) /* -> result */;
    lvars v;
    if v.isintegral or v mod 1.0 = 0.0 then
        intof(v)
    else
        round(v + 0.5)
    endif
enddefine;

define lconstant mxmnxy(xmin, ymin, xmax, ymax, xi, yi)
        /* -> (xmin, ymin, xmax, ymax) */;
    lvars xmin, xmax, ymin, ymax, xi, yi;
    min(xi, xmin);
    min(yi, ymin);
    max(xi, xmax);
    max(yi, ymax);
enddefine;

define warp_2d(arrin, regionin, T, arrout, regionout, options) -> arrout;
    lvars arrin, regionin, T, arrout, regionout, options;
    lvars Tx, Ty, Txx, Txy, Tyx, Tyy;
    lconstant tofloat = number_coerce(% 0.0s0 %);

    ;;; Sort out arguments

    ;;; Transform parameters
    if T.isnumber then
        (arrin, regionin, warp_invert(T))
            -> (arrin, regionin, Tx, Ty, Txx, Txy, Tyx, Tyy)
    else
        warp_invert(warp_params(T)) -> (Tx, Ty, Txx, Txy, Tyx, Tyy)
    endif;

    ;;; Array arguments to right type if given
    lvars boundsin = boundslist(arrin);
    unless arrin.issfloatarray then
        newsfloatarray(boundsin, arrin) -> arrin
    endunless;
    if arrout.islist then
        newsfloatarray(tl(arrout), hd(arrout)) -> arrout
    elseif arrout and not(arrout.issfloatarray) then
        newsfloatarray(boundslist(arrout), arrout) -> arrout
    endif;

    ;;; Region arguments
    unless regionout then
        boundslist(arrout) -> regionout
    endunless;
    unless arrout then
        newsfloatarray(regionout) -> arrout
    endunless;

    lvars boundsout = boundslist(arrout);
    region_inclusion_check(boundsout, regionout);

    ;;; Options argument - defaults set first.
    lvars sampling = "interpolate", out_of_range = "mishap";
    define lconstant setopt(option); lvars option;
        if lmember(option, [interpolate, nearest]) then
            option -> sampling
        elseif lmember(option, [mishap, ignore]) then
            option -> out_of_range
        else
            mishap(option, 1, 'unrecognised option')
        endif
    enddefine;
    if options.isword then
        setopt(options)
    else
        applist(options, setopt)
    endif;

    ;;; End of sorting out arguments

    lvars
        procedure out_to_in = warp_xy(% Tx, Ty, Txx, Txy, Tyx, Tyy %),
        (x0i, x1i, y0i, y1i) = explode(boundsin),
        (x0o, x1o, y0o, y1o) = explode(boundsout),
        (x0r, x1r, y0r, y1r) = explode(regionout);

    lvars xstart, ystart;
    out_to_in(x0r, y0r) -> (xstart, ystart);
    if out_of_range == "mishap" then
        lvars xmin, xmax, ymin, ymax;
        ;;; Check not going to go outside of input array
        mxmnxy(
            mxmnxy(
                mxmnxy(xstart, ystart, xstart, ystart, out_to_in(x1r, y0r)),
                out_to_in(x1r, y1r)),
            out_to_in(x0r, y1r)) -> (xmin, ymin, xmax, ymax);
        if floor(xmin) < x0i or floor(ymin) < y0i
        or ceil(xmax) > x1i or ceil(ymax) > y1i then
            mishap(regionout, 1, 'Region needs data from outside input array')
        endif
    endif;

    ;;; Call external proc
    arrayvector(arrin),         ;;; in_2d
    x1i - x0i + 1,              ;;; in_xsize
    y1i - y0i + 1,              ;;; in_ysize
    arrayvector(arrout),        ;;; out_2d
    x1o - x0o + 1,              ;;; out_xsize
    x0r - x0o,                  ;;; out_xstart
    x1r - x0o,                  ;;; out_xend
    y0r - y0o,                  ;;; out_ystart
    y1r - y0o,                  ;;; out_yend
    tofloat(xstart - x0i),      ;;; in_xstart
    tofloat(ystart - y0i),      ;;; in_ystart
    tofloat(Txx),
    tofloat(Txy),
    tofloat(Tyx),
    tofloat(Tyy),
    if sampling == "nearest" and out_of_range == "mishap" then
        exacc warp_n_f()
    elseif sampling == "nearest" and out_of_range == "ignore" then
        exacc warp_nc_f()
    elseif sampling == "interpolate" and out_of_range == "mishap" then
        exacc warp_l_f()
    elseif sampling == "interpolate" and out_of_range == "ignore" then
        exacc warp_lc_f()
    endif;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Jul 13 1993
        Changed -newfloatarray- to -newsfloatarray- and -isfloatarray- to
        -issfloatarray- to avoid name clash with *VEC_MAT package.
 */
