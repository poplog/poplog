/* --- Copyright University of Sussex 1999. All rights reserved. ----------
 > File:            $popvision/lib/arraysample.p
 > Purpose:         Resize a region of an array
 > Author:          David S Young, Jun  3 1992 (see revisions)
 > Documentation:   HELP ARRAYSAMPLE
 */

/*
The approach is to transform one dimension of the array at a time. Thus
the transformation (which has a diagonal matrix) is carried out by, say,
stretching on the 1-axis, then shifting on the 2-axis, then shrinking
on the 3-axis, and so on as required.

The transform for a given axis is given by iterating over the input region
projected along that axis - i.e. iterating all the indices other than
the one corresponding to the active axis. For each point in the iteration
subspace a linear transformation of the data along the active axis is
carried out.
*/

compile_mode:pop11 +strict;

section;

uses popvision
uses objectfile
uses oldarray
uses newsfloatarray
uses newintarray
uses boundslist_utils

/*
-- 1-D resampling of a 1-D array --------------------------------------
*/

/* Load external procedure for float and byte cases */

lconstant macro extname = 'arraysample',
    obfile = objectfile(extname);

#_IF obfile
    exload extname [^obfile]
        lconstant resample_1d_f(10),
                  copy_1d_f(7),
                  resample_1d_b(10),
                  copy_1d_b(7)
    endexload;
#_ELSE
    npr(';;; Warning: object file for arraysample not found -');
    npr(';;; using POP-11 procedures, but this will be slower for');
    npr(';;; byte and single-float arrays.');
    ;;; Need to give typespecs to these things in case object file not found
    ;;; - they are not then called, but compiler needs to have the info
    ;;; and conditional compilation in the main prog is a pain
       lconstant (resample_1d_f,
                  copy_1d_f,
                  resample_1d_b,
                  copy_1d_b) = (false, false, false, false);
       l_typespec resample_1d_f(10),
                  copy_1d_f(7),
                  resample_1d_b(10),
                  copy_1d_b(7);
#_ENDIF

/* Provide POP-11 procedure for other cases.
See arraysample.c for a description of what this does. */

define lconstant resample_1d_g(
        in_1d, in_start, in_step, mask_2d, mask_size, starts_1d,
        out_1d, out_start, out_step, n
    ;;; these extra arguments are accessors and updaters, to
    ;;; allow fast procs and rounding to be used when needed
        getter, maskgetter, startsgetter, putter);
    lvars procedure (getter, maskgetter, startsgetter, putter);
    lvars i, j, sum, v, in_go, out_x, in_x_fast, mask_x;

    ;;; As this is a translation of a C routine, it expects arguments to
    ;;; refer to zero-based vectors
    in_start + 1 -> in_go;
    out_start + 1 -> out_x;

    if mask_size == 0 then
        fast_for j from 1 to n do
            ;;; in_1d(in_go + starts_1d(j)) -> out_1d(out_x);
            putter(getter(in_go + startsgetter(j,starts_1d), in_1d),
                out_x, out_1d);
            out_x + out_step -> out_x
        endfor

    elseif mask_size < 0 then
        - mask_size -> mask_size;
        maskgetter(1, mask_2d) -> v;
        fast_for j from 1 to n do
            0 -> sum;
            in_go + startsgetter(j, starts_1d) -> in_x_fast;
            fast_for i from 1 to mask_size do
                sum + getter(in_x_fast,in_1d) -> sum;
                in_x_fast fi_+ in_step -> in_x_fast
            endfor;
            ;;; v * sum -> out_1d(out_x);
            putter(v * sum, out_x, out_1d);
            out_x + out_step -> out_x
        endfor

    else
        1 -> mask_x;
        fast_for j from 1 to n do
            0 -> sum;
            in_go + startsgetter(j, starts_1d) -> in_x_fast;
            fast_for i from 1 to mask_size do
                sum + getter(in_x_fast, in_1d) * maskgetter(mask_x,mask_2d)
                    -> sum;
                mask_x fi_+ 1 -> mask_x;
                in_x_fast fi_+ in_step -> in_x_fast
            endfor;
            ;;; sum -> out_1d(out_x);
            putter(sum, out_x, out_1d);
            out_x + out_step -> out_x
        endfor
    endif

enddefine;

define lconstant copy_1d_g(in_1d, in_start, in_step, out_1d,
        out_start, out_step, n, getter, putter);
    lvars procedure (getter, putter);
    lvars j, in_x, out_x;

    in_start + 1 -> in_x;
    out_start + 1 -> out_x;

    if in_step == 1 and out_step == 1 then
        move_subvector(in_x, in_1d, out_x, out_1d, n)
    else
        fast_for j from 1 to n do
            ;;; in_1d(in_x) -> out_1d(out_x);
            putter(getter(in_x, in_1d), out_x, out_1d);
            in_x fi_+ in_step -> in_x;
            out_x fi_+ out_step -> out_x
        endfor
    endif

enddefine;


/*
-- Interpolation mask generation --------------------------------------
*/

define lconstant lin_map(x0, x1, y0, y1) -> (m,c);
    ;;; Returns the constants for the line
    ;;;     x = my + c
    ;;; which passes through (x0-0.5, y0-0.5) and (x1+0.5, y1+0.5)
    lvars nout = y1 - y0 + 1;
    number_coerce(x1 - x0 + 1, 0.0) / nout -> m;
    (x0*y1 - y0*x1 + 0.5*(x0+x1-y0-y1)) / nout -> c;
enddefine;

/* Procedures for getting offsets and weighting factors for the
3 cases of nearest point, interpolation and averaging */

;;; We recycle intvectors to avoid garbage
lvars startvec_save = initintvec(0);
define lconstant startvec(nout) /* -> intvec */;
    if nout > length(startvec_save) then
        initintvec(nout) ->> startvec_save
    else
        startvec_save
    endif
enddefine;

define lconstant nearestpoints(arrin, nin, D, nout)
        -> (starts, mask, masksize);
    ;;; Returns a vector of offsets into arrin for mapping nin points
    ;;; on its Dth dimension into nout points, taking the
    ;;; nearest point in arrin.
    lconstant dummymask = newsfloatarray([0 0]);
    lvars i,
        starts = startvec(nout),
        mask = dummymask,
        masksize = 0,
        (m, c) = lin_map(0, nin-1, 0, nout-1),
        stepsize = array_stepsize(arrin, D);
    fast_for i from 1 to nout do
        round(m*(i fi_- 1) + c) * stepsize -> starts(i);
    endfor
enddefine;

define lconstant interpoints(arrin, nin, D, nout) -> (starts, mask, masksize);
    ;;; Returns a vector of offsets and weighting factors for mapping
    ;;; nin points on the Dth dimension of arrin into nout points,
    ;;; using linear interpolation between the two nearest neighbours.
    ;;; Points near the ends are fudged.
    lvars
        starts = startvec(nout),
        mask = oldsfloatarray(interpoints, [% 1, 2, 1, nout %]),
        masksize = 2;
    lvars i, pos, p, f,
        maxpos = nin - 2,
        (m, c) = lin_map(0, nin-1, 0, nout-1),
        stepsize = array_stepsize(arrin, D);
    fast_for i from 1 to nout do
        m * (i fi_- 1) + c -> pos;
        round(pos-0.5) -> p;        ;;; intof no good round 0
        ;;; Avoid going off the ends
        if p fi_< 0 then
            0 ->> p -> f
        elseif p fi_> maxpos then
            maxpos -> p;
            1 -> f
        else
            pos - p -> f        ;;; linear weighting factor
        endif;
        p * stepsize -> starts(i);
        f -> mask(2,i);
        1.0 - f -> mask(1,i)
    endfor
enddefine;


define lconstant averpoints(arrin, nin, D, nout) -> (starts, mask, masksize);
    ;;; Returns a vector of offsets and weighting factors for
    ;;; mapping nin points on the Dth dimension of arrin into
    ;;; nout points, using equally weighted averaging over near neighbours.
    ;;; There will be no attempt to go outside the bounds of arrin:
    ;;; to show this for the start, consider the first iteration.
    ;;; In this iteration,      pos = (nin/nout - 1) / 2
    ;;;     and               hmask = ([nin/nout] - 1) / 2
    ;;; where [x] denotes x rounded to the nearest integer.
    ;;; Then p = [pos - hmask] =  [(nin/nout - [nin/nout]) / 2]
    ;;; will be less than 0 only if pos-hmask is less then 1/2, i.e. if
    ;;;         nin/nout - [nin/nout] < 1
    ;;; which clearly cannot happen.
    lconstant maskarr = newsfloatarray([0 0]);
    lvars
        starts = startvec(nout),
        mask_size = max(1, round(nin / nout)),
        mask = maskarr,
        masksize = -mask_size;
    1.0/mask_size -> mask(0);
    lvars i, pos, p, v, j,
        (m, c) = lin_map(0, nin-1, 0, nout-1),
        stepsize = array_stepsize(arrin, D),
        hmask = (mask_size - 1) / 2.0,
        c1 = c - hmask;
    fast_for i from 1 to nout do
        /*
        m * (i - 1) + c -> pos;
        round(pos - hmask) -> p;        ;;; intof no good close to 0
        p * stepsize -> starts(i);
        */
        round(m * (i fi_- 1) + c1) * stepsize -> starts(i)
    endfor
enddefine;

/*
-- 1-D resampling of N-D array ----------------------------------------
*/

define lconstant resample_nx1d(arrin, x0, x1, D, arrout, regionout, opt)
        -> arrout;
    ;;; Resample an array along the Dth dimension, using nearest point,
    ;;; interpolation or averaging accoring to opt.
    ;;; If opt is "smooth", then averaging is used when 3 or more
    ;;; points will get averaged, otherwise interpolation.
    ;;;
    ;;;     x0 and x1 give the D-dimension limits of data in arrin
    ;;;         (if false, default to the Dth bounds pair)
    ;;;     regionout gives the region of arrout to fill
    ;;;         (if false, defaults to as big a region as possible)
    ;;;     if arrout is false, a new array is created - but regionout
    ;;;         must then be specified to give its bounds
    ;;;
    ;;; If x0 > x1 then the array needs to be mirrored along this
    ;;; axis. Easiest way to handle this is to fix the parameters
    ;;; that control the output pointer.

    lconstant
        dummymask = newsfloatarray([0 0]),
        isintegervec = datakey <> class_spec <> isinteger,
        oddtag = consref("oddtag"),     ;;; tags for work arrays
        eventag = consref("eventag");

    lvars
        in_0, in_1,         ;;; Dth bounds of input region
        out_0, out_1,       ;;;   ditto output region
        regionin,           ;;; input region
        nin, nout,          ;;; no of points along Dth dimension
        starts, mask,       ;;; see resample_1d_f.c
        flip = false,       ;;; needs to be mirrored
        coordsin, coordsout,
        procedure(newcoordsin, newcoordsout, arrin_offset, arrout_offset),
        in_start, in_step, out_start, out_step, mask_size,  ;;; for 1d routine
        invec = arrayvector(arrin),
        arrin_type = class_spec(datakey(invec)),
        outvec, arrout_type,
        use_byteproc = false, use_floatproc = false, use_genproc = false,
        getter, maskgetter, startsgetter, putter, ptr;

    ;;; Get the bounds of the active dimension, check arrout argument
    nthbounds(arrin, D) -> (in_0, in_1);
    if x0 then x0 -> in_0 endif;
    if x1 then x1 -> in_1 endif;
    if in_0 > in_1 then     ;;; check if a flip
        (in_0, in_1) -> (in_1, in_0);
        true -> flip
    endif;
    unless arrout.isarray then
        if arrout then  ;;; arrout is actually key not array
            ;;; This array is intermediate - use oldarray to avoid garbage,
            ;;; but use different tags on odd and even dimensions to avoid
            ;;; overwriting
            oldanyarray(if D mod 2 == 0 then eventag else oddtag endif,
                regionout, arrout) -> arrout
        else
            ;;; This array will be returned from arraysample
            newanyarray(regionout, datakey(arrayvector(arrin))) -> arrout
        endif
    endunless;

    ;;; Check array types and hence which procedures to call
    arrayvector(arrout) -> outvec;
    class_spec(datakey(outvec)) -> arrout_type;
    if obfile and arrin_type == "decimal" and arrout_type == "decimal" then
        true -> use_floatproc
    elseif obfile and arrin_type == 8 and arrout_type == 8 then
        true -> use_byteproc
    else    ;;; uses POP-11
        true -> use_genproc
    endif;

    ;;; Establish output region
    unless regionout then
        ;;; If no region specified, do as much as possible
        region_intersect(arrin, arrout) -> regionout;
        nthbounds(arrout, D) -> nthbounds(regionout, D)
    endunless;
    region_inclusion_check(arrout, regionout);
    nthbounds(regionout, D) -> (out_0, out_1);
    ;;; Establish input region
    copylist(regionout) -> regionin;
    (in_0, in_1) -> nthbounds(regionin, D);
    region_inclusion_check(arrin, regionin);

    in_1 - in_0 + 1 -> nin;
    out_1 - out_0 + 1 -> nout;

    ;;; Fix option
    if nin == nout then
        "copy" -> opt ;;; as other existing options would just copy anyway
    else
        if opt == "smooth" then
            if round(nin/nout) >= 3 then
                "average" -> opt
            else
                "interpolate" -> opt
            endif
        endif
    endif;

    ;;; Get offset and weight arrays
    if opt == "nearest" then
        nearestpoints(arrin, nin, D, nout) -> (starts, mask, mask_size)
    elseif opt == "interpolate" then
        interpoints(arrin, nin, D, nout) -> (starts, mask, mask_size)
    elseif opt == "average" then
        averpoints(arrin, nin, D, nout) -> (starts, mask, mask_size)
    elseif opt /== "copy" then
        mishap(opt, 1, 'Unrecognised option')
    endif;

    ;;; Set up accessor and updater procs for POP-11 case
    ;;; Use fast subscriptors for speed, and round if needed
    if use_genproc then
        class_fast_subscr(datakey(invec)) -> getter;
        updater(class_fast_subscr(datakey(outvec))) -> ptr;
        if not(outvec.isintegervec) or
            (mask_size == 0 and invec.isintegervec) then
            ptr -> putter
        else        ;;; need to round
            procedure(item, n, vec); lvars item, n, vec;
                ptr(round(item), n, vec)
            endprocedure -> putter
        endif;
        if opt /== "copy" then
            class_fast_subscr(datakey(arrayvector(mask))) -> maskgetter;
            class_fast_subscr(datakey(starts)) -> startsgetter;
        endif
    endif;

    ;;; Set the regionout to be the subspace of starting points
    ;;; Copy to avoid updating argument
    copylist(regionout) -> regionout;
    if flip then
        out_1 -> regionout(D * 2 - 1)    ;;; instead of out_0 - start at top
    else
        out_0 -> regionout(D * 2)        ;;; instead of out_1
    endif;
    copylist(regionin) -> regionin;
    in_0 -> regionin(D * 2);

    ;;; Set up repeater and array index references
    region_rep(regionin) -> newcoordsin;
    region_rep(regionout) -> newcoordsout;
    array_indexer(arrin) -> arrin_offset;
    array_indexer(arrout) -> arrout_offset;

    ;;; Get step sizes
    array_stepsize(arrin, D) -> in_step;
    array_stepsize(arrout, D) -> out_step;
    if flip then -out_step -> out_step endif;   ;;; work downwards

    ;;; Loop over the subspace of starting points
    until (newcoordsin() ->> coordsin) == termin do

        arrin_offset(explode(coordsin)) - 1 -> in_start;
        newcoordsout() -> coordsout;
        arrout_offset(explode(coordsout)) - 1 -> out_start;

        if opt == "copy" then
            arrayvector(arrin),
            in_start,
            in_step,
            arrayvector(arrout),
            out_start,
            out_step,
            nout;        ;;; args on stack
            if use_floatproc then
                exacc copy_1d_f ()
            elseif use_byteproc then
                exacc copy_1d_b ()
            else
                copy_1d_g (getter, putter)
            endif

        else
            arrayvector(arrin),
            in_start,
            in_step,
            arrayvector(mask),
            mask_size,
            starts,     ;;; an intvec
            arrayvector(arrout),
            out_start,
            out_step,
            nout;        ;;; args on stack
            if use_floatproc then
                exacc resample_1d_f ()
            elseif use_byteproc then
                exacc resample_1d_b ()
            else
                resample_1d_g (getter, maskgetter, startsgetter, putter)
            endif

        endif

    enduntil

enddefine;

/* Sometimes can just shift array bounds instead of copying */

define lconstant shiftbounds_1d(arrin, shift, D) /* -> arrout */;
    ;;; Shifts the array along the Dth dimension just by changing the
    ;;; boundslist
    if shift == 0 then
        arrin /* -> arrout */
    else
        lvars
            b = copylist(boundslist(arrin)),
            (x0, x1) = nthbounds(b, D),
            (, offset) = arrayvector_bounds(arrin);
        (x0 + shift, x1 + shift) -> nthbounds(b, D);
        newanyarray(b, arrin, offset-1) /* -> arrout */
    endif
enddefine;

define lconstant getflips(regionin, regionout) -> (rin, rout, flips, nflips);
    [] -> rin; [] -> rout; 0 -> nflips;
    lvars x0, x1, y0, y1, flip;
    {%
        until regionin == [] do
            destpair(destpair(regionin)) -> (x0, x1, regionin);
            x0 > x1 -> flip;
            if flip then (x0, x1) -> (x1, x0) endif;
            conspair(x1, conspair(x0, rin)) -> rin;
            destpair(destpair(regionout)) -> (y0, y1, regionout);
            if y0 > y1 then
                not(flip) -> flip;  (y0, y1) -> (y1, y0)
            endif;
            conspair(y1, conspair(y0, rout)) -> rout;
            if flip then nflips fi_+ 1 -> nflips endif;
            flip        ;;; in vector
        enduntil
        %} -> flips;
        fast_ncrev(rin) -> rin;
        fast_ncrev(rout) -> rout;
enddefine;

/* Ordering of dimensions can have a big effect on efficiency */

define lconstant sortdims(regionin, regionout, flips) /* -> dimlist */;
    ;;; Heuristic ordering of dimension processing.
    lvars dimlist, x0, x1, y0, y1, xsize, ysize, flip, dim = 0;
    [%
        until regionin == [] do
            dim fi_+ 1 -> dim;
            destpair(destpair(regionin)) -> (x0, x1, regionin);
            x1 fi_- x0 fi_+ 1 -> xsize;
            destpair(destpair(regionout)) -> (y0, y1, regionout);
            y1 fi_- y0 fi_+ 1 -> ysize;
            flips(dim) -> flip;

            if not(flip) and (x0 /== y0) and (xsize == ysize) then
                ;;; bounds shifts
                {% dim, 0, 0 %},         ;;; first do shift
            elseif flip or (x0 /== y0) or (x1 /== y1) then
                ;;; general case
                {% dim, 1, (ysize+0.0)/xsize %}  ;;; best data reduction first
            else      ;;; this leaves possible copies
                ;;; - put last as possibly not needed at all
                {% dim, 2, -xsize %}     ;;; biggest dimension first
            endif

        enduntil
    %] -> dimlist;
    nc_listsort(dimlist,
        procedure(v1, v2);
            v1(2) < v2(2) or (v1(2) == v2(2) and v1(3) < v2(3))
        endprocedure) -> dimlist;
    ncmaplist(dimlist, procedure(v); v(1) endprocedure) /* -> dimlist */
enddefine;

/*
-- Main procedure - N-D resampling of N-D array -----------------------
*/

define procedure arraysample(arrin, regionin, arrout, regionout)
        -> arrout;
    dlocal poparray_by_row = true;      ;;; ensure arrays created correctly

    lvars opt = "nearest";      ;;; optional argument
    if regionout.isword then
        (arrin, regionin, arrout, regionout)
            -> (arrin, regionin, arrout, regionout, opt)
    endif;

    lvars dim, dimlist, x0, x1, y0, y1, region, flips, nflips, out_type,
        ndim = pdnargs(arrin);

    ;;; Fix missing args
    unless regionin then
        boundslist(arrin) -> regionin
    endunless;
    unless regionout then
        if arrout then
            boundslist(arrout)
        else
            regionin
        endif -> regionout
    endunless;

    ;;; Check that everything has the same no. dimensions
    unless length(regionin) div 2 == ndim and
        length(regionout) div 2 == ndim and
        (not(arrout) or (pdnargs(arrout) == ndim)) then
        mishap(arrin, regionin, arrout, regionout, 4, 'Incompatible dimensions')
    endunless;

    ;;; Check arrayed by row. If necessary, could handle by-column arrays
    ;;; by flipping boundslists, but gets complex.
    unless arrin.isarray_by_row then
        mishap(arrin, 1, 'Input array must be ordered by row')
    endunless;
    unless not(arrout) or arrout.isarray_by_row then
        mishap(arrout, 1, 'Output array must be ordered by row')
    endunless;

    ;;; get type of output array - convert on first call to resample_nx1d
    datakey(arrayvector(arrout or arrin)) -> out_type;

    ;;; Discover any flips and fix region lists so all dims +ve
    ;;; Have to do this now, as regions are used to create arrays
    getflips(regionin, regionout) -> (regionin, regionout, flips, nflips);
    ;;; Order dimensions heuristically
    sortdims(regionin, regionout, flips) -> dimlist;

    regionin -> region;     ;;; current input then output region

    for dim in dimlist do       ;;; Iterate over dimensions
        nthbounds(region, dim) -> (x0, x1);
        nthbounds(regionout, dim) -> (y0, y1);
        ;;; Specify a flip
        if flips(dim) then
            (x0, x1) -> (x1, x0);
            nflips - 1 -> nflips
        endif;

        ;;; Set up temporary OUTPUT region changing this dimension only
        copylist(region) -> region;     ;;; May be used as boundslist
        (y0, y1) -> nthbounds(region, dim);

        if region = regionout and nflips == 0 then
            ;;; Ready to finish off into output array
            if arrout and arrayvector(arrin) == arrayvector(arrout) then
                ;;; Possibly need to do nothing at all ...
                unless x0 == y0 and x1 == y1 and arrout == arrin then
                    ;;; ... but may need to copy twice to avoid overwriting
                    resample_nx1d(arrin, x0, x1, dim, out_type, region, opt)
                        -> arrin;
                    resample_nx1d(arrin, y0, y1, dim, arrout, region, "copy")
                        -> arrout
                endunless
            else
                ;;; Like general case but into output array
                resample_nx1d(arrin, x0, x1, dim, arrout, region, opt)
                    -> arrout;
            endif;
            quitloop;

        elseif x1-x0 == y1-y0 then
            ;;; No need to copy this dimension - just shift array bounds
            shiftbounds_1d(arrin, y0-x0, dim) -> arrin

        else
            ;;; General case for non-final dimension
            resample_nx1d(arrin, x0, x1, dim, out_type, region, opt)
                -> arrin;       ;;; arrin now a new array
        endif
    endfor

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Oct 18 1999
        Fixed following bug: when output array and input array shared
        storage and the only operation was a shift, no operations were
        carried out. At the same time simplified -sortdims- and reordered
        the tests in the main loop of -arraysample- to put termination test
        ahead of shift test.
--- David S Young, Dec  1 1998
        Added heuristic dimension ordering - increases speed greatly
        in certain cases.
--- David S Young, Sep  4 1997
        Put in check for arrays ordered by row.
--- David S Young, Nov 15 1994
        Garbage creation reduced by use of oldarray and similar measures.
--- David S Young, Dec 10 1993
        Put -move_subvector- into -copy_1d_g-, which speeds it up a lot
        in certain cases.
        Now prints a warning if the object file is missing.
--- David S Young, Nov 29 1993
        Uses -class_spec- instead of -class_field_spec- in order to
        recognise all byte arrays properly.
--- David S Young, Jul 13 1993
        Changed -newfloatarray- to -newsfloatarray- and -isfloatarray- to
        -issfloatarray- to avoid name clash with *VEC_MAT package.
--- David S Young, Jun 11 1992
        Revised to deal with flips properly, and to handle any type
        of array more consistently.
 */
