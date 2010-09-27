/* --- Copyright University of Sussex 2001. All rights reserved. ----------
 > File:            $popvision/lib/fft.p
 > Purpose:         Fast Fourier Transforms
 > Author:          David S Young, Sep 24 1997 (see revisions)
 > Documentation:   HELP * FFT
 > Related Files:   $popvision/lib/fft.c
 */

/*

         CONTENTS - (Use <ENTER> g to access required sections)

 -- External loads
 -- Misc. utilities
 -- Copying periodic and symmetrical data
 -- ... 1-D cases
 -- ... 2-D cases
 -- 1-D FFT
 -- 2-D FFT

*/

compile_mode:pop11 +strict;

section;

uses popvision, objectfile, newsfloatarray,
     arraysample, arrayset, array_transpose, ext2d_args;

/*
-- External loads -----------------------------------------------------
*/

lconstant macro extname = 'fft',
    obfile = objectfile(extname);

unless obfile then
    mishap(0, 'Cannot find object file for fft')
endunless;

exload extname [^obfile] /*lconstant*/
        rev_subvector_EXT(6)                  <- rev_subvector,
        negate_region_EXT(5)                  <- negate_region,
        multiply_region_EXT(f<SF>, xs, ys, v, off, xd)   <- multiply_region,
        fft1pow2_EXT(7):int                   <- fft1pow2,
        fft1pow2rf_EXT(7):int                 <- fft1pow2rf,
        fft1pow2rb_EXT(7):int                 <- fft1pow2rb,
        fft1pow2mult_EXT(9):int               <- fft1pow2mult,
        fft1pow2rfmult_EXT(10):int            <- fft1pow2rfmult,
        fft1pow2rbmult_EXT(10):int            <- fft1pow2rbmult
endexload;


/*
-- Misc. utilities ----------------------------------------------------
*/


;;; The next macro is used in calls to *oldarray and its variants,
;;; directly or indirectly. It makes a unique tag which means that
;;; arrays can be recycled for use at the same point in the code.

lconstant macro ltag = [ #_< consref(0) >_# ];


define nextpow2(x) -> y;
    if x > 0 then
        1 -> y;
        x - 1 -> x;
        until x == 0 do x >> 1 -> x; y << 1 -> y enduntil
    else
        0 -> y
    endif
enddefine;


define lconstant arrstart(arr) -> off;
    arrayvector_bounds(arr) -> ( , off);
enddefine;


define lconstant regions_share_storage(
        sx0, sx1, sy0, sy1, sarr,
        dx0, dx1, dy0, dy1, darr) -> result;
    ;;; Returns true if two regions of 2-D arrays share storage
    if sarr == darr then
        ;;; same array - regions overlap in 2D?
        not(sx0 > dx1 or dx0 > sx1 or sy0 > dy1 or dy0 > sy1) -> result
    elseif arrayvector(sarr) == arrayvector(darr) then
        ;;; different arrays on same arrayvector - end points overlap?
        lvars
            sr0 = arrstart(sarr),
            dr0 = arrstart(darr),
            (Sx0, Sx1, Sy0, Sy1) = explode(boundslist(sarr)),
            swid = Sx1 - Sx0 + 1,
            (Dx0, Dx1, Dy0, Dy1) = explode(boundslist(darr)),
            dwid = Dx1 - Dx0 + 1,
            s0 = sr0 + (sy0-Sy0) * swid + (sx0 - Sx0),
            s1 = sr0 + (sy1-Sy0) * swid + (sx1 - Sx0),
            d0 = dr0 + (dy0-Dy0) * dwid + (dx0 - Dx0),
            d1 = dr0 + (dy1-Dy0) * dwid + (dx1 - Dx0);
        not(s0 > d1 or d0 > s1) -> result
    else
        false -> result;
    endif
enddefine;


define lconstant negate_region(arr, region);
    ;;; Negates each element of arr in place.
    unless region then boundslist(arr) -> region endunless;
    if arr.issfloatarray and arr.isarray_by_row then
        lconstant arrlist = [0];
        arr -> hd(arrlist);
        exacc negate_region_EXT(explode(ext2d_args(arrlist, region)))
    else
        lvars a;
        for a, a in_array arr, arr updating_last in_region region do
            -a -> a
        endfor
    endif
enddefine;


define lconstant multiply_region(f, arr, region);
    ;;; Multiplies each element of arr in place.
    if arr.issfloatarray and arr.isarray_by_row then
        lconstant arrlist = [0];
        arr -> hd(arrlist);
        exacc multiply_region_EXT(
            number_coerce(f, 0.0s0),
            explode(ext2d_args(arrlist, region)))
    else
        lvars a;
        for a, a in_array arr, arr updating_last in_region region do
            f * a -> a
        endfor
    endif
enddefine;


define lconstant rev_subvector(s_sub, s_vec, d_sub, d_vec, N, revsgn);
    ;;; Like move_subvector but reverses direction, and sign as well
    ;;; if revsgn is true. Counts down from s_sub and up from d_sub.
    ;;; Not correct if input and output regions are in same vector
    ;;; and overlap.

    ;;; check null case
    returnif (s_sub == d_sub and s_vec == d_vec);

    fi_check(N, 0, false) -> ;
    fi_check(s_sub, N, datalength(s_vec)) -> ;
    fi_check(d_sub, 1, datalength(d_vec) fi_- N fi_+ 1) -> ;

    if s_vec.issfloatvec and d_vec.issfloatvec then
        exacc rev_subvector_EXT(s_sub fi_- 1, s_vec,
            d_sub fi_- 1, d_vec, N, (revsgn and 1) or 0)

    else

        lvars i = s_sub, j,
            procedure(
            sv = class_fast_subscr(datakey(s_vec)),
            dv = class_fast_subscr(datakey(d_vec)));
        if revsgn then
            fast_for j from d_sub to d_sub fi_+ N fi_- 1 do
                -sv(i, s_vec) -> dv(j, d_vec);
                i fi_- 1 -> i
            endfor
        else
            fast_for j from d_sub to d_sub fi_+ N fi_- 1 do
                sv(i, s_vec) -> dv(j, d_vec);
                i fi_- 1 -> i
            endfor
        endif
    endif
enddefine;


/*
-- Copying periodic and symmetrical data ------------------------------
*/

/*
Warning: in some places a span of data is defined using s <= i <= e,
where s and e are the start and end points and i is the index, and in
others using s <= i < e. The first convention comes from Pop11
boundslists, the second is however more convenient for many computations
(for example, the length of the span is just e-s in this convention).
Sometimes below the second convention is referred to as the +1
convention because the end point is increased by one. It ought to be
clear from the comments which one is in use at any point, but do not
make changes without being certain which one is in effect. Wherever
spans are passed as lists, the boundslist convention is in force.
*/


define lconstant trim_n(s0, s1, n) -> (t0, t1);
    ;;; Trims the span s0 <= s < s1 to have no more than n points,
    ;;; if possible starting from a multiple of n. Uses +1 convention.
    s0 + -s0 mod max(n,1) -> t0;
    t0 + n -> t1;
    if s1 < t1 then
        s0 -> t0;
        min(t0+n, s1) -> t1
    endif
enddefine;


define lconstant trim_n2_ref(s0, s1, nd2) -> (t0, t1);
    ;;; Trims the span s0 <= s < s1 to have no more than nd2+1 points,
    ;;; ensuring that all the points apart from the end points
    ;;; come from a single half-cycle. Uses +1 convention.

    ;;; leftmost cycle start after s0
    s0 + -s0 mod max(nd2, 1) -> t0;
    t0 + nd2 + 1 -> t1;         ;;; Note +1 is deliberate to include point nd2

    if t1 > s1 then
        ;;; no complete cycle in original span
        ;;; but must keep to cycle boundaries to avoid inconsistency
        if t0+1 >= s1 then
            ;;; no boundaries in original span - keep it all
            s0 -> t0;
            s1 -> t1
        elseif t0-s0 >= s1-t0 then
            ;;; use larger segment - in this case left one
            t0 + 1 -> t1;    ;;; +1 to keep nd2 or 0 point
            s0 -> t0
        else
            ;;; larger segment on right of boundary
            s1 -> t1
        endif
    endif
enddefine;


define lconstant remove_zeropts(s0, s1, nd2) -> (s0, s1);
    ;;; Remove the end points of the span if they are zero modulus nd2.
    if s0 mod nd2 == 0 then s0 + 1 -> s0 endif;
    if s1 mod nd2 == 1 then s1 - 1 -> s1 endif;  ;;; 1 as using +1 convention
enddefine;


/*
-- ... 1-D cases ------------------------------------------------------
*/


define copy_modn(s0, s1, soff, src, d0, d1, doff, dst, N);
    ;;; Fills elements d0 to d1 of the destination array D from
    ;;; elements s0 to s1 of the source array S, such that
    ;;;             D(i) = S(j) if i mod N = j mod N
    ;;; If the number of source data points is greater than N, only
    ;;; N are used; if the number is less than N, then the source
    ;;; is padded up to N with zeros.
    ;;; The source array S is to be passed as its arrayvector src
    ;;; and the arrayvector offset soff, so that src(soff+i) = S(i),
    ;;; and likewise for the destination array D.

    ;;; Uses boundslist convention for s0,s1,d0,d1 on entry.

    ;;; OK to copy onto same vector unless offsets incongruent and
    ;;; regions overlap
    if src == dst and (soff-doff) mod N /== 0
    and soff + s0 <= doff + d1 and soff + s1 >= doff + d0 then
        mishap(soff, doff, 2, 'Incongruent offsets in vector')
    endif;

    ;;; Simpler to work with end points just after the end of the data
    ;;; - switching to +1 convention from here on in.
    s1 + 1 -> s1;
    d1 + 1 -> d1;

    ;;; Ignore excess input data
    trim_n(s0, s1, N) -> (s0, s1);
    lvars sN = s0 + N;      ;;; end of zero-padded extension

    ;;; map d0 onto src
    s0 + (d0-s0) mod N -> s0;
    lvars size;                 ;;; size of chunk to transfer
    until d0 == d1 do
        if s0 < s1 then        ;;; transfer some data
            min(s1 - s0, d1 - d0) -> size;
            move_subvector(s0+soff, src, d0+doff, dst, size)
        else                    ;;; pad with zeros
            min(sN - s0, d1 - d0) -> size;
            set_subvector(0, d0+doff, dst, size)
        endif;
        s0 + size -> s0;     ;;; shift for next src chunk
        if s0 == sN then s0 - N -> s0 endif;
        d0 + size -> d0;
    enduntil
enddefine;


define copy_modn_ref(s0, s1, soff, src, d0, d1, doff, dst,  N, revsgn);
    ;;; Fills elements d0 to d1 of the destination array D from
    ;;; elements s0 to s1 of the source array S, such that
    ;;;     if i mod N <= N/2
    ;;;             D(i) = S(j) where j satisfies i mod N = j mod N
    ;;;     if i mod N > N/2
    ;;;             D(i) = sgn * S(j) where j satisfies i mod N = N - (j mod N)
    ;;; where sgn is +/-1 if revsgn is false/true.

    ;;; Uses boundslist convention for s0,s1,d0,d1 on entry.

    ;;; If revsgn is false then:
    ;;; If the number of source data points is greater than N/2+1, only
    ;;; N/2+1 are used; if the number is less than N/2+1, then the source
    ;;; is padded up to N/2+1 with zeros.

    ;;; If revsgn is true then the number used is N/2-1.

    ;;; The source array S is to be passed as its arrayvector src
    ;;; and the arrayvector offset soff, so that src(soff+i) = S(i),
    ;;; and likewise for the destination array D.

    lvars Nd2 = N div 2;
    unless Nd2*2 == N then
        mishap(N, 1, 'Expecting even number')
    endunless;

    ;;; OK to copy onto same vector unless offsets incongruent and
    ;;; regions overlap
    if src == dst and (soff-doff) mod N /== 0
    and soff + s0 <= doff + d1 and soff + s1 >= doff + d0 then
        mishap(soff, doff, 2, 'Incongruent offsets in vector')
    endif;

    ;;; Simpler to work with end points just after the end of the data
    ;;; - switching to +1 convention from here on in.
    s1 + 1 -> s1;
    d1 + 1 -> d1;
    ;;; Ignore excess input data
    trim_n2_ref(s0, s1, Nd2) -> (s0, s1);
    if revsgn then remove_zeropts(s0, s1, Nd2) -> (s0, s1) endif;
    lvars sN = s0 + N, s1mN = s1 - N;

    ;;; map d0 onto src
    lvars size,                 ;;; size of chunk to transfer
        s0a = s0 + (d0-s0) mod N,
        s0b = s1mN + (-d0-s1) mod N + 1; ;;; +1 translates start to end
    until d0 == d1 do
        if s0a < s1 then        ;;; transfer some data
            min(s1 - s0a, d1 - d0) -> size;
            move_subvector(s0a+soff, src, d0+doff, dst, size)
        elseif s0b > s0 then        ;;; transfer reverse section
            min(s0b - s0, d1 - d0) -> size;
            rev_subvector(s0b+soff-1, src, d0+doff, dst, size, revsgn)
        else ;;; pad with zeros
            min(min(sN-s0a, s0b-s1mN), d1 - d0) -> size;
            set_subvector(0, d0+doff, dst, size)
        endif;
        s0a + size -> s0a;     ;;; shift for next src chunk
        if s0a >= sN then s0a - N -> s0a endif;
        s0b - size -> s0b;     ;;; shift for next src chunk
        if s0b <= s1mN then s0b + N -> s0b endif;
        d0 + size -> d0;
    enduntil
enddefine;


/*
-- ... 2-D cases ------------------------------------------------------
*/


define lconstant copy_modn2_basic(
        sx0, sx1, sy0, sy1, sarr,
        dx0, dx1, dy0, dy1, darr,
        N, M);
    ;;; 2-D equivalent of copy_modn.
    ;;; Does not zero background and assumes sreg and dreg set up
    ;;; as required, and all checks except for null input region done.
    ;;; Uses +1 convention throughout.

    ;;; Skip null operation now
returnif (sx1 <= sx0 or sy1 <= sy0);

    lvars sxN = sx0 + N, syM = sy0 + M;   ;;; end of region to skip

    sx0 + (dx0-sx0) mod N -> sx0;
    sy0 + (dy0-sy0) mod M -> sy0;
    lconstant regions = [0 0 0 0], regiond = [0 0 0 0];
    lvars xsize, ysize;
    until dx0 == dx1 do
        if sx0 < sx1 then
            min(sx1 - sx0, dx1 - dx0) -> xsize;

            ;;; Inner loop just like outer loop - see copy_modn for comments
            lvars sy0f = sy0, dy0f = dy0;
            until dy0f == dy1 do
                if sy0f < sy1 then
                    min(sy1 - sy0f, dy1 - dy0f) -> ysize;
                    sx0, sx0+xsize-1, sy0f, sy0f+ysize-1 -> explode(regions);
                    dx0, dx0+xsize-1, dy0f, dy0f+ysize-1 -> explode(regiond);
                    arraysample(sarr, regions, darr, regiond, "nearest") -> ;
                else
                    min(syM - sy0f, dy1 - dy0f) -> ysize;
                endif;
                sy0f + ysize -> sy0f;
                if sy0f == syM then sy0f - M -> sy0f endif;
                dy0f + ysize -> dy0f;
            enduntil

        else                    ;;; skip region
            min(sxN - sx0, dx1 - dx0) -> xsize;
        endif;
        sx0 + xsize -> sx0;
        if sx0 == sxN then sx0 - N -> sx0 endif;
        dx0 + xsize -> dx0;
    enduntil
enddefine;


define lconstant copy_modn2_flip(
        sx0, sx1, sy0, sy1, sarr,
        dx0, dx1, dy0, dy1, darr,
        N, M, revsgn);
    ;;; Like copy_modn2_basic but reflects data about origin.
    ;;; Optionally reverses sign of data copied.
    ;;; Assumes regions set up properly, with no inconsistencies.
    ;;; Uses +1 convention throughout.

    ;;; Skip null operation with no more ado.
returnif (sx1 <= sx0 or sy1 <= sy0);        ;;; +1 convention means <= not <

    lvars sx1mN = sx1 - N, sy1mM = sy1 - M;

    sx1mN + (-dx0-sx1) mod N + 1 -> sx1;
    sy1mM + (-dy0-sy1) mod M + 1 -> sy1;
    lconstant regions = [0 0 0 0], regiond = [0 0 0 0];
    lvars xsize, ysize;
    until dx0 == dx1 do
        if sx1 > sx0 then
            min(sx1 - sx0, dx1 - dx0) -> xsize;

            lvars sy1f = sy1, dy0f = dy0;
            until dy0f == dy1 do
                if sy1f > sy0 then
                    min(sy1f - sy0, dy1 - dy0f) -> ysize;
                    sx1-1, sx1-xsize, sy1f-1, sy1f-ysize -> explode(regions);
                    dx0, dx0+xsize-1, dy0f, dy0f+ysize-1 -> explode(regiond);
                    arraysample(sarr, regions, darr, regiond, "nearest") -> ;
                    if revsgn then
                        negate_region(darr, regiond)
                    endif
                else
                    min(sy1f - sy1mM, dy1 - dy0f) -> ysize;
                endif;
                sy1f - ysize -> sy1f;
                if sy1f == sy1mM then sy1f + M -> sy1f endif;
                dy0f + ysize -> dy0f;
            enduntil

        else                    ;;; skip region
            min(sx1 - sx1mN, dx1 - dx0) -> xsize;
        endif;
        sx1 - xsize -> sx1;
        if sx1 == sx1mN then sx1 + N -> sx1 endif;
        dx0 + xsize -> dx0;
    enduntil
enddefine;


define lconstant copy_modn2_basicandflip(
        sx0, sx1, sy0, sy1, sarr,
        dx0, dx1, dy0, dy1, darr,
        N, M, revsgn);
    ;;; This assumes that any points in the output that do not map
    ;;; onto the input region have already been set suitably (e.g. to 0)
    ;;; and that the input region has been set up to avoid inconsistent
    ;;; data. Then all points in the output that map onto the input either
    ;;; by translation by (kN, jM) where k,j are integers, or by reflection
    ;;; in the origin, get set suitably, with a change of sign if revsgn
    ;;; is true.
    copy_modn2_basic(sx0, sx1, sy0, sy1, sarr,
        dx0, dx1, dy0, dy1, darr, N, M);
    copy_modn2_flip(sx0, sx1, sy0, sy1, sarr,
        dx0, dx1, dy0, dy1, darr, N, M, revsgn);
enddefine;


define copy_modn2(sreg, sarr, dreg, darr, N, M);
    ;;; 2-D equivalent of copy_modn.
    ;;; Apparently null operations (sreg = dreg and sarr == darr) are
    ;;; allowed because they can be used to enforce periodicity.

    unless sreg then boundslist(sarr) -> sreg endunless;
    unless dreg then boundslist(darr) -> dreg endunless;

    ;;; Obtain consistent region - also switch to +1 convention here
    lvars
        (sx0, sx1, sy0, sy1) = explode(sreg),
        (dx0, dx1, dy0, dy1) = explode(dreg);
    trim_n(sx0, sx1+1, N) -> (sx0, sx1);
    trim_n(sy0, sy1+1, M) -> (sy0, sy1);
    dx1 + 1 -> dx1;
    dy1 + 1 -> dy1;

    ;;; If arrays share storage, must copy because of the need to
    ;;; set output to 0 before filling in other bits. Also avoids
    ;;; any problems with incompatible regions.
    ;;; Need to switch back to boundslist mode.
    if regions_share_storage(sx0, sx1-1, sy0, sy1-1, sarr,
            dx0, dx1-1, dy0, dy1-1, darr) then
        [% sx0, sx1-1, sy0, sy1-1 %] -> sreg;
        lvars tarr = oldanyarray(ltag, sreg, datakey(arrayvector(sarr)));
        arraysample(sarr, sreg, tarr, sreg, "nearest") -> sarr
    endif;

    arrayset(0, darr, dreg);
    copy_modn2_basic(
        sx0, sx1, sy0, sy1, sarr,
        dx0, dx1, dy0, dy1, darr, N, M);
enddefine;


define copy_modn_ref2(sreg, sarr, dreg, darr, N, M, revsgn);
    ;;; 2-D equivalent of copy_modn_ref.
    ;;; Apparently null operations (sreg = dreg and sarr == darr) are
    ;;; allowed because they can be used to enforce periodicity and symmetry.

    ;;; First check that have even tiling region
    lvars Nd2 = N div 2, Md2 = M div 2;
    unless Nd2*2 == N and Md2*2 == M then
        mishap(N, M, 2, 'Expecting even numbers')
    endunless;

    unless sreg then boundslist(sarr) -> sreg endunless;
    unless dreg then boundslist(darr) -> dreg endunless;

    ;;; Find a region of the input array such that redundant data are
    ;;; not included. This means that in one direction must not go both
    ;;; sides of any 0 mod K/2 whilst on other must not have more than
    ;;; K points (where K is N or M depending on direction). Choose
    ;;; option that uses as much of array as possible. In addition,
    ;;; need to avoid redundant parts of row or columns which are
    ;;; 0 mod K/2.

    lvars
        (sx0, sx1, sy0, sy1) = explode(sreg),
        (dx0, dx1, dy0, dy1) = explode(dreg);

    ;;; Switch to +1 convention from here.
    sx1 + 1 -> sx1;
    sy1 + 1 -> sy1;
    dx1 + 1 -> dx1;
    dy1 + 1 -> dy1;
    lvars
        (sx0a, sx1a) = trim_n2_ref(sx0, sx1, Nd2),
        (sy0a, sy1a) =      trim_n(sy0, sy1, M),
        (sx0b, sx1b) =      trim_n(sx0, sx1, N),
        (sy0b, sy1b) = trim_n2_ref(sy0, sy1, Md2),
        ix0, ix1, iy0, iy1,         ;;; overall region used
        extraa, extrab;             ;;; flags for extra strips
    if (sx1a-sx0a)*(sy1a-sy0a) >= (sx1b-sx0b)*(sy1b-sy0b) then
        ;;; portrait region
        (sx0a, sx1a, sy0a, sy1a) -> (ix0, ix1, iy0, iy1);
        ;;; main section
        remove_zeropts(sx0a, sx1a, Nd2) -> (sx0, sx1);
        (sy0a, sy1a) -> (sy0, sy1);
        ;;; extra bits
        if (sx0a < sx0 ->> extraa) or (sx1a > sx1 ->> extrab) then
            ;;; possible columns either side, on x mod N/2 = 0
            trim_n2_ref(sy0a, sy1a, Md2) -> (sy0a, sy1a);
            if revsgn then
                remove_zeropts(sy0a, sy1a, Md2) -> (sy0a, sy1a)
            endif;
            if extrab then
                (sx1a-1, sx1a, sy0a, sy1a) -> (sx0b, sx1b, sy0b, sy1b)
            endif;
            if extraa then
                sx0a+1 -> sx1a
            endif
        endif
    else
        ;;; landscape region
        (sx0b, sx1b, sy0b, sy1b) -> (ix0, ix1, iy0, iy1);
        (sx0b, sx1b) -> (sx0, sx1);
        remove_zeropts(sy0b, sy1b, Md2) -> (sy0, sy1);
        if (sy0b < sy0 ->> extrab) or (sy1b > sy1 ->> extraa) then
            trim_n2_ref(sx0b, sx1b, Nd2) -> (sx0b, sx1b);
            if revsgn then
                remove_zeropts(sx0b, sx1b, Nd2) -> (sx0b, sx1b)
            endif;
            if extraa then
                (sy1b-1, sy1b, sx0b, sx1b) -> (sy0a, sy1a, sx0a, sx1a)
            endif;
            if extrab then
                sy0b+1 -> sy1b
            endif
        endif
    endif;

    ;;; If arrays share storage, must copy because of the need to
    ;;; set output to 0 before filling in other bits. Also avoids
    ;;; any problems with incompatible regions. Need to switch back
    ;;; to boundslist mode.
    if regions_share_storage(
            ix0, ix1-1, iy0, iy1-1, sarr,
            dx0, dx1-1, dy0, dy1-1, darr) then
        [% ix0, ix1-1, iy0, iy1-1 %] -> sreg;
        lvars tarr = oldanyarray(ltag, sreg, datakey(arrayvector(sarr)));
        arraysample(sarr, sreg, tarr, sreg, "nearest") -> sarr
    endif;

    ;;; Now do copies. Region in general cannot be rectangular, so
    ;;; need 3 calls to cover all the bits.
    arrayset(0, darr, dreg);
    copy_modn2_basicandflip(sx0, sx1, sy0, sy1, sarr,
        dx0, dx1, dy0, dy1, darr, N, M, revsgn);
    if extraa then
        copy_modn2_basicandflip(sx0a, sx1a, sy0a, sy1a, sarr,
            dx0, dx1, dy0, dy1, darr, N, M, revsgn);
    endif;
    if extrab then
        copy_modn2_basicandflip(sx0b, sx1b, sy0b, sy1b, sarr,
            dx0, dx1, dy0, dy1, darr, N, M, revsgn);
    endif;
enddefine;


/*
-- 1-D FFT ------------------------------------------------------------
*/


define fft_1d(N, dir, inr, ini, outr, outi) -> (outr, outi);

    ;;; Check args - first N
    if N and N /== nextpow2(N) then
        mishap(N, 1, 'N must be an integer and a power of 2')
    endif;

    ;;;     - inputs
    lvars b = boundslist(inr), in0, in1, inoffr, inoffi, inrv, iniv;
    unless pdnargs(inr) == 1 and b = boundslist(ini) then
        mishap(inr, ini, 2,
            'Input arrays must be 1-D with same boundslists')
    endunless;
    explode(b) -> (in0, in1);
    arrstart(inr) - in0 -> inoffr;
    arrstart(ini) - in0 -> inoffi;
    arrayvector(inr) -> inrv;
    arrayvector(ini) -> iniv;
    N or nextpow2(in1 - in0 + 1) -> N;
    lvars Nm1 = N - 1;

    ;;;     - outputs
    lvars bout, out0, out1, outoffr, outoffi, outrv, outiv,
        t0, t1, mustcopy = false;
    if outr.isarray then            ;;; output arrays supplied
        boundslist(outr) -> bout;
        arrayvector(outr) -> outrv;
        arrayvector(outi) -> outiv;
        unless pdnargs(outr) == 1 and bout = boundslist(outi)
        and outrv /== outiv then
            mishap(outr, outi, 2,
                'Output arrs must be 1-D, same bounds, different arrayvectors')
        endunless;
        explode(bout) -> (out0, out1);
        arrstart(outr) - out0 -> outoffr;
        arrstart(outi) - out0 -> outoffi;
        ;;; Calculate first point for transform (must be congruent to 0)
        out0 + -out0 mod N -> t0;
        ;;; Supplied output array suitable for external routine?
        if out1 < t0+Nm1 or not(outr.issfloatarray and outi.issfloatarray) then
            true -> mustcopy;
            lvars outrvE = outrv, outivE = outiv, ;;; save supplied values
                out0E = out0, out1E = out1,
                outoffrE = outoffr, outoffiE = outoffi;
            0 ->> out0 -> t0;  Nm1 -> out1;
            arrayvector(oldsfloatarray(ltag, [0 ^out1])) -> outrv;
            arrayvector(oldsfloatarray(ltag, [0 ^out1])) -> outiv;
            1 ->> outoffr -> outoffi;
        endif
    else                    ;;; must create output arrays
        0 ->> out0 -> t0;  Nm1 -> out1;
        oldsfloatarray(outr, [0 ^out1]) -> outr;
        oldsfloatarray(outi, [0 ^out1]) -> outi;
        arrayvector(outr) -> outrv;
        arrayvector(outi) -> outiv;
        1 ->> outoffr -> outoffi;
    endif;
    t0 + Nm1 -> t1;

    ;;; copy inputs, shifting if necessary to take account of input bounds
    ;;; and padding with zeros
    copy_modn(in0, in1, inoffr, inrv, t0, t1, outoffr, outrv, N);
    copy_modn(in0, in1, inoffi, iniv, t0, t1, outoffi, outiv, N);

    ;;; call the external FFT routine
    lvars ierr;
    exacc fft1pow2_EXT(
        if dir then 1 else -1 endif, N, 1,    ;;; isign, N, inc
        t0 + outoffr - 1, outrv,              ;;; rstart, datrarr
        t0 + outoffi - 1, outiv)              ;;; istart, datiarr
        -> ierr;
    unless (ierr == 0) then
        mishap('Error in external routine arguments', [External error ^ierr])
    endunless;

    if mustcopy then    ;;; copy data back to real output
        copy_modn(t0, t1, outoffr, outrv, out0E, out1E, outoffrE, outrvE, N);
        copy_modn(t0, t1, outoffi, outiv, out0E, out1E, outoffiE, outivE, N);
    else                ;;; extend data cyclically (may do nothing)
        copy_modn(t0, t1, outoffr, outrv, out0, out1, outoffr, outrv, N);
        copy_modn(t0, t1, outoffi, outiv, out0, out1, outoffi, outiv, N);
    endif
enddefine;


define fft_1d_real_fwd(N, inr, outr, outi) -> (outr, outi);

    ;;; Check args - first N
    if N and N /== nextpow2(N) then
        mishap(N, 1, 'N must be an integer and a power of 2')
    endif;

    ;;;     - input array
    lvars b = boundslist(inr), in0, in1, s0, inoffr, inrv;
    unless pdnargs(inr) == 1 then
        mishap(inr, 1, 'Input array must be 1-D')
    endunless;
    explode(b) -> (in0, in1);
    arrstart(inr) - in0 -> inoffr;
    arrayvector(inr) -> inrv;
    N or nextpow2(in1 - in0 + 1) -> N;

    lvars Nm1 = N - 1, Nd2 = N div 2;
    ;;; Calculate first point for transform (must be congruent to 0)
    in0 + -in0 mod N -> s0;
    ;;; Supplied input array suitable for external routine?
    if in1 < s0+Nm1 or not(inr.issfloatarray) then
        lvars inrvT = arrayvector(oldsfloatarray(ltag, [0 ^Nm1]));
        copy_modn(in0, in1, inoffr, inrv, 0, Nm1, 1, inrvT, N);
        inrvT -> inrv;
        0 -> s0;
        1 -> inoffr;
    endif;

    ;;;     - outputs
    lvars bout, out0, out1, outoffr, outoffi, outrv, outiv,
        t0, t1, mustcopy = false;
    if outr.isarray then            ;;; output arrays supplied
        boundslist(outr) -> bout;
        arrayvector(outr) -> outrv;
        arrayvector(outi) -> outiv;
        unless pdnargs(outr) == 1 and bout = boundslist(outi)
        and outrv /== outiv then
            mishap(outr, outi, 2,
                'Output arrs must be 1-D, same bounds, different arrayvectors')
        endunless;
        explode(bout) -> (out0, out1);
        arrstart(outr) - out0 -> outoffr;
        arrstart(outi) - out0 -> outoffi;
        ;;; Calculate first point for transform (must be congruent to 0)
        out0 + -out0 mod N -> t0;
        ;;; Supplied output array suitable for external routine?
        if out1 < t0+Nd2        ;;; not Nd2-1 - need point N/2
        or not(outr.issfloatarray and outi.issfloatarray) then
            true -> mustcopy;
            lvars outrvE = outrv, outivE = outiv, ;;; save supplied values
                out0E = out0, out1E = out1,
                outoffrE = outoffr, outoffiE = outoffi;
            0 ->> out0 -> t0;  Nd2 -> out1;
            arrayvector(oldsfloatarray(ltag, [0 ^out1])) -> outrv;
            arrayvector(oldsfloatarray(ltag, [0 ^out1])) -> outiv;
            1 ->> outoffr -> outoffi;
        endif
    else                    ;;; must create output arrays
        0 ->> out0 -> t0;  Nd2 -> out1;
        oldsfloatarray(outr, [0 ^out1]) -> outr;
        oldsfloatarray(outr, [0 ^out1]) -> outi;
        arrayvector(outr) -> outrv;
        arrayvector(outi) -> outiv;
        1 ->> outoffr -> outoffi;
    endif;
    t0 + Nd2 -> t1;

    ;;; call the external FFT routine
    lvars ierr;
    exacc fft1pow2rf_EXT(
        N,                                    ;;; n
        s0 + inoffr - 1, inrv,                ;;; rstarti, datrarri
        t0 + outoffr - 1, outrv,              ;;; rstarto, dattrarro
        t0 + outoffi - 1, outiv)              ;;; istarto, dattiarro
        -> ierr;
    unless (ierr == 0) then
        mishap('Error in external routine arguments', [External error ^ierr])
    endunless;

    if mustcopy then    ;;; copy data back to real output
        copy_modn_ref(t0, t1, outoffr, outrv,
            out0E, out1E, outoffrE, outrvE, N, false);
        copy_modn_ref(t0, t1, outoffi, outiv,
            out0E, out1E, outoffiE, outivE, N, true);
    else                ;;; extend data cyclically (may do nothing)
        copy_modn_ref(t0, t1, outoffr, outrv,
            out0, out1, outoffr, outrv, N, false);
        copy_modn_ref(t0, t1, outoffi, outiv,
            out0, out1, outoffi, outiv, N, true);
    endif
enddefine;


define fft_1d_real_bckwd(N, inr, ini, outr) -> outr;

    ;;; Check args - first N
    if N and N /== nextpow2(N) then
        mishap(N, 1, 'N must be an integer and a power of 2')
    endif;

    ;;;     - inputs
    lvars b = boundslist(inr), in0, in1, s0, inoffr, inoffi, inrv, iniv;
    unless pdnargs(inr) == 1 and b = boundslist(ini) then
        mishap(inr, ini, 2,
            'Input arrays must be 1-D with same boundslists')
    endunless;
    explode(b) -> (in0, in1);
    arrstart(inr) - in0 -> inoffr;
    arrstart(ini) - in0 -> inoffi;
    arrayvector(inr) -> inrv;
    arrayvector(ini) -> iniv;
    N or 2*nextpow2(in1 - in0) -> N;    ;;; different from other transforms

    lvars Nm1 = N - 1, Nd2 = N div 2;
    ;;; Calculate first point for transform (must be congruent to 0)
    in0 + -in0 mod N -> s0;
    ;;; Supplied input arrays suitable for external routine?
    if in1 < s0+Nd2 or not(inr.issfloatarray and ini.issfloatarray) then
        lvars
            inrvT = arrayvector(oldsfloatarray(ltag, [0 ^Nd2])),
            inivT = arrayvector(oldsfloatarray(ltag, [0 ^Nd2]));
        copy_modn_ref(in0, in1, inoffr, inrv, 0, Nd2, 1, inrvT, N, false);
        copy_modn_ref(in0, in1, inoffi, iniv, 0, Nd2, 1, inivT, N, true);
        inrvT -> inrv; inivT -> iniv;
        0 -> s0;
        1 ->> inoffr -> inoffi;
    endif;

    ;;;     - outputs
    lvars out0, out1, outoffr, outrv, t0, t1, mustcopy = false;
    if outr.isarray then            ;;; output array supplied
        arrayvector(outr) -> outrv;
        unless pdnargs(outr) == 1 then
            mishap(outr, 1, 'Output array must be 1-D')
        endunless;
        explode(boundslist(outr)) -> (out0, out1);
        arrstart(outr) - out0 -> outoffr;
        ;;; Calculate first point for transform (must be congruent to 0)
        out0 + -out0 mod N -> t0;
        ;;; Supplied output array suitable for external routine?
        if out1 < t0+Nm1 or not(outr.issfloatarray) then
            true -> mustcopy;
            lvars outrvE = outrv, ;;; save supplied values
                out0E = out0, out1E = out1,
                outoffrE = outoffr;
            0 ->> out0 -> t0;  Nm1 -> out1;
            arrayvector(oldsfloatarray(ltag, [0 ^out1])) -> outrv;
            1 -> outoffr;
        endif
    else                    ;;; must create output array
        0 ->> out0 -> t0;  Nm1 -> out1;
        oldsfloatarray(outr, [0 ^out1]) -> outr;
        arrayvector(outr) -> outrv;
        1 -> outoffr;
    endif;
    t0 + Nm1 -> t1;

    ;;; call the external FFT routine
    lvars ierr;
    exacc fft1pow2rb_EXT(
        N,                                    ;;; n
        s0 + inoffr - 1, inrv,                ;;; rstarti, datrarri
        s0 + inoffi - 1, iniv,                ;;; istarti, datiarri
        t0 + outoffr - 1, outrv)              ;;; rstarto, dattrarro
        -> ierr;
    unless (ierr == 0) then
        mishap('Error in external routine arguments', [External error ^ierr])
    endunless;

    if mustcopy then    ;;; copy data back to real output
        copy_modn(t0, t1, outoffr, outrv, out0E, out1E, outoffrE, outrvE, N)
    else                ;;; extend data cyclically (may do nothing)
        copy_modn(t0, t1, outoffr, outrv, out0, out1, outoffr, outrv, N)
    endif
enddefine;


/*
-- 2-D FFT ------------------------------------------------------------
*/


define fft_2d(N, M, dir, inr, ini, outr, outi) -> (outr, outi);
    dlocal poparray_by_row = true;

    ;;; Check and sort out args - first N and M
    if (N and N /== nextpow2(N)) or (M and M /== nextpow2(M)) then
        mishap(N, M, 2, 'N and M must be integers and a powers of 2')
    endif;

    ;;;     - inputs
    lvars b = boundslist(inr), inx0, inx1, iny0, iny1;
    unless pdnargs(inr) == 2 and b = boundslist(ini)
    and inr.isarray_by_row and ini.isarray_by_row then
        mishap(inr, ini, 2,
            'Input arrays must be 2-D, arrayed by row, with same boundslists')
    endunless;
    explode(b) -> (inx0, inx1, iny0, iny1);
    N or nextpow2(inx1 - inx0 + 1) -> N;
    M or nextpow2(iny1 - iny0 + 1) -> M;
    lvars Nm1 = N - 1, Mm1 = M - 1;

    ;;;     - outputs
    lvars bout, outx0, outx1, outy0, outy1, xsize, outoffr, outoffi,
        tx0, ty0, tregion, outrE = false, outiE;
    if outr.isarray then            ;;; output arrays supplied
        boundslist(outr) -> bout;
        unless pdnargs(outr) == 2 and bout = boundslist(outi)
        and arrayvector(outr) /== arrayvector(outi)
        and outr.isarray_by_row and outi.isarray_by_row then
            mishap(outr, outi, 2,
                'Output arrs must be 2-D, same boundslists, '
                <> 'arrayed by row with different arrayvectors')
        endunless;
        explode(bout) -> (outx0, outx1, outy0, outy1);
        ;;; Calculate first point for transform (must be congruent to 0)
        outx0 + -outx0 mod N -> tx0;
        outy0 + -outy0 mod M -> ty0;
        ;;; Supplied output array suitable for external routine?
        if outx1 >= tx0+Nm1 and outy1 >= ty0+Mm1
        and outr.issfloatarray and outi.issfloatarray then
            [% tx0, tx0 + Nm1, ty0, ty0 + Mm1 %] -> tregion;
            outx1 - outx0 + 1 -> xsize;
            lvars startoffset = tx0-outx0 + xsize * (ty0-outy0);
            arrstart(outr) + startoffset - 1 -> outoffr;
            arrstart(outi) + startoffset - 1 -> outoffi;
        else        ;;; no - need to get and use work arrays
            outr -> outrE, outi -> outiE;   ;;; save caller-supplied arrs
            [% 0, Nm1, 0, Mm1 %] -> tregion;
            oldsfloatarray(ltag, tregion) -> outr;
            oldsfloatarray(ltag, tregion) -> outi;
            0 ->> outoffr -> outoffi;
            N -> xsize;
        endif
    else                    ;;; must create output arrays
        false -> bout;      ;;; no need to extend later
        [% 0, Nm1, 0, Mm1 %] -> tregion;
        oldsfloatarray(outr, tregion) -> outr;
        oldsfloatarray(outi, tregion) -> outi;
        0 ->> outoffr -> outoffi;
        N -> xsize;
    endif;

    ;;; copy inputs, shifting if necessary to take account of input bounds
    ;;; and padding with zeros
    copy_modn2(b, inr, tregion, outr, N, M);
    copy_modn2(b, ini, tregion, outi, N, M);

    lvars ierr;
    ;;; call the external FFT routine for the x-direction
    exacc fft1pow2mult_EXT(
        if dir then 1 else -1 endif,        ;;; isign
        M,                                  ;;; p - no. transforms
        xsize,                              ;;; pinc - increment in y
        N,                                  ;;; n - length of transform
        1,                                  ;;; ninc - increment in x
        outoffr,                            ;;; rstart
        arrayvector(outr),                  ;;; datrarr
        outoffi,                            ;;; istart,
        arrayvector(outi))                  ;;; datiarr
        -> ierr;
    unless (ierr == 0) then
        mishap('Error in external routine arguments', [External error ^ierr])
    endunless;
    ;;; ... and for the y-direction
    exacc fft1pow2mult_EXT(
        if dir then 1 else -1 endif,        ;;; isign
        N,                                  ;;; p - no. transforms
        1,                                  ;;; pinc - increment in y
        M,                                  ;;; n - length of transform
        xsize,                              ;;; ninc - increment in x
        outoffr,                            ;;; rstart
        arrayvector(outr),                  ;;; datrarr
        outoffi,                            ;;; istart,
        arrayvector(outi))                  ;;; datiarr
        -> ierr;
    unless (ierr == 0) then
        mishap('Error in external routine arguments', [External error ^ierr])
    endunless;

    if outrE then           ;;; copy data back to real output
        copy_modn2(tregion, outr, bout, outrE, N, M);
        copy_modn2(tregion, outi, bout, outiE, N, M);
        (outrE, outiE) -> (outr, outi);
    elseif bout and bout /= tregion then        ;;; extend data cyclically
        copy_modn2(tregion, outr, bout, outr, N, M);
        copy_modn2(tregion, outi, bout, outi, N, M);
    endif
enddefine;


define fft_2d_real_fwd(N, M, inr, outr, outi) -> (outr, outi);
    dlocal poparray_by_row = true;

    ;;; Check and sort out args - first N and M
    if (N and N /== nextpow2(N)) or (M and M /== nextpow2(M)) then
        mishap(N, M, 2, 'N and M must be integers and a powers of 2')
    endif;

    ;;;     - inputs
    lvars b = boundslist(inr),
        inx0, inx1, iny0, iny1, sx0, sy0, inxsize, inoffr;
    unless pdnargs(inr) == 2 and inr.isarray_by_row then
        mishap(inr, 1,
            'Input array must be 2-D, arrayed by row')
    endunless;
    explode(b) -> (inx0, inx1, iny0, iny1);
    N or nextpow2(inx1 - inx0 + 1) -> N;
    M or nextpow2(iny1 - iny0 + 1) -> M;
    lvars Nm1 = N-1, Nd2 = N div 2, Nd2p1 = Nd2+1, Mm1 = M-1;

    ;;; Calculate first point for transform (must be congruent to 0)
    inx0 + -inx0 mod N -> sx0;
    iny0 + -iny0 mod M -> sy0;
    ;;; Supplied input array suitable for external routine?
    if inx1 < sx0+Nm1 or iny1 < sy0+Mm1 or not(inr.issfloatarray) then
        lvars
            bT = [0 ^Nm1 0 ^Mm1],
            inrT = oldsfloatarray(ltag, bT);
        copy_modn2(b, inr, bT, inrT, N, M);
        inrT -> inr;
        bT -> b;
        N -> inxsize;
        0 -> inoffr
    else
        inx1 - inx0 + 1 -> inxsize;
        arrstart(inr) + sx0-inx0 + inxsize*(sy0-iny0) - 1 -> inoffr
    endif;

    ;;;     - outputs
    lvars bout, outx0, outx1, outy0, outy1, outxsize, outoffr, outoffi,
        tx0, ty0, tregion, outrE = false, outiE;
    if outr.isarray then            ;;; output arrays supplied
        boundslist(outr) -> bout;
        unless pdnargs(outr) == 2 and bout = boundslist(outi)
        and arrayvector(outr) /== arrayvector(outi)
        and outr.isarray_by_row and outi.isarray_by_row then
            mishap(outr, outi, 2,
                'Output arrs must be 2-D, same boundslists, '
                <> 'arrayed by row with different arrayvectors')
        endunless;
        explode(bout) -> (outx0, outx1, outy0, outy1);
        ;;; Calculate first point for transform (must be congruent to 0)
        outx0 + -outx0 mod N -> tx0;
        outy0 + -outy0 mod M -> ty0;
        ;;; Supplied output arrays suitable for external routine?
        if outx1 >= tx0+Nd2 and outy1 >= ty0+Mm1
        and outr.issfloatarray and outi.issfloatarray then
            ;;; they are OK
            [% tx0, tx0 + Nd2, ty0, ty0 + Mm1 %] -> tregion;
            outx1 - outx0 + 1 -> outxsize;
            lvars startoffset = tx0-outx0 + outxsize*(ty0-outy0);
            arrstart(outr) + startoffset - 1 -> outoffr;
            arrstart(outi) + startoffset - 1 -> outoffi;
        else        ;;; no - need to get and use work arrays
            outr -> outrE, outi -> outiE;   ;;; save caller-supplied arrs
            [% 0, Nd2, 0, Mm1 %] -> tregion;
            oldsfloatarray(ltag, tregion) -> outr;
            oldsfloatarray(ltag, tregion) -> outi;
            Nd2p1 -> outxsize;
            0 ->> outoffr -> outoffi
        endif
    else                    ;;; must create output arrays
        false -> bout;      ;;; no need to extend later
        [% 0, Nd2, 0, Mm1 %] -> tregion;
        oldsfloatarray(outr, tregion) -> outr;
        oldsfloatarray(outi, tregion) -> outi;
        Nd2p1 -> outxsize;
        0 ->> outoffr -> outoffi
    endif;
    lvars ierr;
    ;;; call the external FFT routine for the x-direction
    exacc fft1pow2rfmult_EXT(
        M,                                  ;;; p - no. transforms
        inxsize,                            ;;; pinci - input increment in y
        outxsize,                           ;;; pinco - output increment in y
        N,                                  ;;; n - length of transform
        inoffr,                             ;;; rstarti
        arrayvector(inr),                   ;;; datrarri
        outoffr,                            ;;; rstarto
        arrayvector(outr),                  ;;; datrarro
        outoffi,                            ;;; istarto
        arrayvector(outi)                   ;;; datiarro
    ) -> ierr;
    unless (ierr == 0) then
        mishap('Error in external routine arguments', [External error ^ierr])
    endunless;
    ;;; ... and for the y-direction
    exacc fft1pow2mult_EXT(
        1,                                  ;;; isign
        Nd2p1,                              ;;; p - no. transforms
        1,                                  ;;; pinc - increment in y
        M,                                  ;;; n - length of transform
        outxsize,                           ;;; ninc - increment in x
        outoffr,                            ;;; rstart
        arrayvector(outr),                  ;;; datrarr
        outoffi,                            ;;; istart,
        arrayvector(outi)                  ;;; datiarr
    ) -> ierr;
    unless (ierr == 0) then
        mishap('Error in external routine arguments', [External error ^ierr])
    endunless;

    if outrE then           ;;; copy data back to proper output
        copy_modn_ref2(tregion, outr, bout, outrE, N, M, false);
        copy_modn_ref2(tregion, outi, bout, outiE, N, M, true);
        (outrE, outiE) -> (outr, outi);
    elseif bout and bout /= tregion then        ;;; extend data cyclically
        copy_modn_ref2(tregion, outr, bout, outr, N, M, false);
        copy_modn_ref2(tregion, outi, bout, outi, N, M, true);
    endif
enddefine;


define fft_2d_real_bckwd(N, M, inr, ini, outr) -> outr;
    dlocal poparray_by_row = true;

    ;;; Check and sort out args - first N and M
    if (N and N /== nextpow2(N)) or (M and M /== nextpow2(M)) then
        mishap(N, M, 2, 'N and M must be integers and a powers of 2')
    endif;

    ;;;     - inputs
    lvars b = boundslist(inr),
        inx0, inx1, iny0, iny1, sx0, sy0, inxsize, inoffr, inoffi;
    unless pdnargs(inr) == 2 and b = boundslist(ini)
    and inr.isarray_by_row and ini.isarray_by_row then
        mishap(inr, ini, 2,
            'Input arrays must be 2-D, arrayed by row, with same boundslists')
    endunless;
    explode(b) -> (inx0, inx1, iny0, iny1);
    N or 2*nextpow2(inx1 - inx0) -> N;    ;;; assume x-axis truncated
    M or nextpow2(iny1 - iny0 + 1) -> M;
    lvars Nm1 = N-1, Nd2 = N div 2, Nd2p1 = Nd2+1, Mm1 = M-1;

    ;;; Copy to work arrays to avoid corrupting inputs.
    ;;; In principle this could be avoided by
    ;;; writing fft1pow2rbmult so that it could operate in-place, and
    ;;; copying to the output array before calling both stages, but
    ;;; this would involve considerably more work. Work arrays should
    ;;; not really cost anything unless garbage collections are
    ;;; frequent.
    lvars
        bT = [0 ^Nd2 0 ^Mm1],
        inrT = oldsfloatarray(ltag, bT),
        iniT = oldsfloatarray(ltag, bT);
    copy_modn_ref2(b, inr, bT, inrT, N, M, false);
    copy_modn_ref2(b, ini, bT, iniT, N, M, true);
    inrT -> inr; iniT -> ini;
    bT -> b;
    Nd2p1 -> inxsize;
    0 ->> inoffr -> inoffi;

    ;;;     - outputs
    lvars bout, outx0, outx1, outy0, outy1, outxsize, outoffr,
        tx0, ty0, tregion, outrE= false;
    if outr.isarray then            ;;; output array supplied
        boundslist(outr) -> bout;
        unless pdnargs(outr) == 2 and outr.isarray_by_row then
            mishap(outr, 1, 'Output array must be 2-D, arrayed by row')
        endunless;
        explode(bout) -> (outx0, outx1, outy0, outy1);
        ;;; Calculate first point for transform (must be congruent to 0)
        outx0 + -outx0 mod N -> tx0;
        outy0 + -outy0 mod M -> ty0;
        ;;; Supplied output array suitable for external routine?
        if outx1 >= tx0+Nm1 and outy1 >= ty0+Mm1 and outr.issfloatarray then
            [% tx0, tx0 + Nm1, ty0, ty0 + Mm1 %] -> tregion;
            outx1 - outx0 + 1 -> outxsize;
            arrstart(outr) + tx0-outx0 + outxsize*(ty0-outy0) - 1 -> outoffr;
        else        ;;; no - need to get and use work arrays
            outr -> outrE;
            [% 0, Nm1, 0, Mm1 %] -> tregion;
            oldsfloatarray(ltag, tregion) -> outr;
            N -> outxsize;
            0 -> outoffr
        endif
    else                    ;;; must create output array
        false -> bout;
        [% 0, Nm1, 0, Mm1 %] -> tregion;
        oldsfloatarray(outr, tregion) -> outr;
        N -> outxsize;
        0 -> outoffr
    endif;

    ;;; First transform for y direction, in place on work arrays
    lvars ierr;
    exacc fft1pow2mult_EXT(
        -1,                                 ;;; isign
        Nd2p1,                              ;;; p - no. transforms
        1,                                  ;;; pinc - increment in y
        M,                                  ;;; n - length of transform
        inxsize,                            ;;; ninc - increment in x
        inoffr,                             ;;; rstart
        arrayvector(inr),                   ;;; datrarr
        inoffi,                             ;;; istart,
        arrayvector(ini)                    ;;; datiarr
    ) -> ierr;
    unless (ierr == 0) then
        mishap('Error in external routine arguments', [External error ^ierr])
    endunless;
    ;;; Second transform for x direction, to output array
    exacc fft1pow2rbmult_EXT(
        M,                                  ;;; p - no. transforms
        inxsize,                            ;;; pinci - input increment in y
        outxsize,                           ;;; pinco - output increment in y
        N,                                  ;;; n - length of transform
        inoffr,                             ;;; rstarti
        arrayvector(inr),                   ;;; datrarri
        inoffi,                             ;;; rstarto
        arrayvector(ini),                   ;;; datrarro
        outoffr,                            ;;; istarto
        arrayvector(outr)                   ;;; datiarro
    ) -> ierr;
    unless (ierr == 0) then
        mishap('Error in external routine arguments', [External error ^ierr])
    endunless;

    if outrE then    ;;; copy data back to real output
        copy_modn2(tregion, outr, bout, outrE, N, M);
        outrE -> outr
    elseif bout and bout /= tregion then          ;;; extend data cyclically
        copy_modn2(tregion, outr, bout, outr, N, M)
    endif
enddefine;


define fft_2d_real_sym(N, M, dir, inr, outr) -> outr;
    dlocal poparray_by_row = true;

    ;;; Check and sort out args - first N and M
    if (N and N /== nextpow2(N)) or (M and M /== nextpow2(M)) then
        mishap(N, M, 2, 'N and M must be integers and powers of 2')
    endif;

    ;;;     - inputs
    lvars
        b = boundslist(inr),
        (inx0, inx1, iny0, iny1) = explode(b);
    unless pdnargs(inr) == 2 and inr.isarray_by_row then
        mishap(inr, 1,
            'Input array must be 2-D, arrayed by row')
    endunless;

    if dir then
        N or nextpow2(inx1 - inx0 + 1) -> N;      ;;; assume y-axis truncated
        M or 2*nextpow2(iny1 - iny0) -> M;
    else
        N or 2*nextpow2(inx1 - inx0) -> N;      ;;; assume x-axis truncated
        M or nextpow2(iny1 - iny0 + 1) -> M;
    endif;
    lvars
        Nm1 = N-1, Nd2 = N div 2, Nd2p1 = Nd2+1,
        Mm1 = M-1, Md2 = M div 2, Md2p1 = Md2+1;

    ;;; Calculate first point for transform (must be congruent to 0)
    lvars
        sx0 = inx0 + -inx0 mod N,
        sx1 = sx0 + Nd2,
        sy0 = iny0 + -iny0 mod M,
        sy1 = sy0 + Mm1,
        regin = [^sx0 ^sx1 ^sy0 ^sy1];
    ;;; Supplied input array suitable?
    lvars bT = false, inrT;
    if inx1 < sx1 or iny1 < sy1 or not(inr.issfloatarray) then
        [0 ^Nd2 0 ^Mm1] -> bT;
        oldsfloatarray(ltag, bT) -> inrT;
        copy_modn_ref2(b, inr, bT, inrT, N, M, false);
        inrT -> inr;
        bT -> regin;
    endif;

    ;;; Take transpose of input so can apply forward real->imag. FFT to
    ;;; the y-direction. This is necessitated by lack of ninci and ninco
    ;;; arguments for fft1pow2rfmult which would allow it to operate on
    ;;; rows as well as on columns.
    lvars transin = array_transpose(inr, regin, ltag);

    unless bT then
        ;;; have not called copy_modn_ref2, so might have inconsistent data
        ;;; in the top and bottom rows - fix this.
        lconstant reg1 = [0 0 0 0], reg2 = [0 0 0 0];
        (sy0+1, sy0+Md2-1, sx0, sx0) -> explode(reg1);
        (sy1,   sy0+Md2+1, sx0, sx0) -> explode(reg2);
        arraysample(transin, reg1, transin, reg2, "nearest") -> ;
        (sy0+1, sy0+Md2-1, sx1, sx1) -> explode(reg1);
        (sy1,   sy0+Md2+1, sx1, sx1) -> explode(reg2);
        arraysample(transin, reg1, transin, reg2, "nearest") -> ;
    endunless;

    ;;; Arrays for intermediate complex results
    lvars
        interbds = [0 ^Md2 0 ^Nd2],
        interr = oldsfloatarray(ltag, interbds),
        interi = oldsfloatarray(ltag, interbds);

    lvars ierr;
    ;;; call the external FFT routine for the original y-direction
    exacc fft1pow2rfmult_EXT(
        Nd2p1,                              ;;; p - no. transforms
        M,                                  ;;; pinci - input increment in y
        Md2p1,                              ;;; pinco - output increment in y
        M,                                  ;;; n - length of transform
        0, arrayvector(transin),            ;;; datrarri
        0, arrayvector(interr),             ;;; datrarro
        0, arrayvector(interi)              ;;; datiarro
    ) -> ierr;
    unless (ierr == 0) then
        mishap('Error in external routine arguments', [External error ^ierr])
    endunless;

    ;;; transpose back - boundslists become [0 Nd2 0 Md2]
    array_transpose(interr, false, ltag) -> interr;
    array_transpose(interi, false, ltag) -> interi;

    ;;; and take complex conjugate as using reverse transform below
    negate_region(interi, false);

    ;;;     - outputs
    lvars bout, outx0, outx1, outy0, outy1, outxsize, outoffr,
        tregion, outrE = false;
    if outr.isarray then            ;;; output arrays supplied
        boundslist(outr) -> bout;
        explode(bout) -> (outx0, outx1, outy0, outy1);
        unless pdnargs(outr) == 2 and outr.isarray_by_row then
            mishap(outr, 1, 'Output array must be 2-D, arrayed by row')
        endunless;
        ;;; Calculate first point for transform (must be congruent to 0)
        lvars
            tx0 = outx0 + -outx0 mod N,
            tx1 = tx0 + Nm1,
            ty0 = outy0 + -outy0 mod M,
            ty1 = ty0 + Md2;
        ;;; Supplied output array suitable for external routine?
        if outx1 >= tx1 and outy1 >= ty1 and outr.issfloatarray then
            ;;; it is OK
            [% tx0, tx1, ty0, ty1 %] -> tregion;
            outx1 - outx0 + 1 -> outxsize;
            arrstart(outr) + tx0-outx0 + outxsize*(ty0-outy0) - 1 -> outoffr;
        else        ;;; no - need to get and use work arrays
            outr -> outrE;   ;;; save caller-supplied arrs
            [% 0, Nm1, 0, Md2 %] -> tregion;
            oldsfloatarray(ltag, tregion) -> outr;
            N -> outxsize;
            0 -> outoffr
        endif
    else                    ;;; must create output arrays
        [% 0, Nm1, 0, Md2 %] -> tregion;
        false -> bout;
        N -> outxsize;
        0 -> outoffr;
        if dir then
            ;;; Want forward transform to produce outputs in portrait form
            oldsfloatarray(outr, [% 0, Nd2, 0, Mm1 %]) -> outrE;
            oldsfloatarray(ltag, tregion) -> outr;
        else
            oldsfloatarray(outr, tregion) -> outr;
        endif
    endif;

    ;;; Transform along x direction back to real array
    exacc fft1pow2rbmult_EXT(
        Md2p1,                              ;;; p - no. transforms
        Nd2p1,                              ;;; pinci - input increment in y
        outxsize,                           ;;; pinco - output increment in y
        N,                                  ;;; n - length of transform
        0, arrayvector(interr),             ;;; datrarri
        0, arrayvector(interi),             ;;; datiarri
        outoffr,                            ;;; istarto
        arrayvector(outr)                   ;;; datrarro
    ) -> ierr;
    unless (ierr == 0) then
        mishap('Error in external routine arguments', [External error ^ierr])
    endunless;

    ;;; Fix normalisation
    if dir then
        multiply_region(1.0/N, outr, tregion)
    else
        multiply_region(M, outr, tregion)
    endif;

    if outrE then    ;;; copy data back to real output
        copy_modn_ref2(tregion, outr, bout, outrE, N, M, false);
        outrE -> outr
    elseif bout and bout /= tregion then       ;;; extend data cyclically
        copy_modn_ref2(tregion, outr, bout, outr, N, M, false)
    endif
enddefine;


vars fft = true;            ;;; for uses

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Oct 28 2001
        Changed to use oldsfloatarray with <false> as first argument where
        appropriate.
--- David Young, Oct 11 2001
        Fixed bug in copy_modn_ref2 and added routine for 2-D real symmetric
        data. Also some general reorganisation and tidying.
--- David Young, Oct  2 2001
        Allowed tags to be given to specify recyclable output arrays.
--- David Young, Oct  2 2001
        Fixed bug in copy_modn_ref and added routines for 2-D real data.
--- David S Young, Mar 12 1999
        Added routines for 1-D real data.
 */
