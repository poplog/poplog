/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 > File:            $popvision/lib/mlp_data.p
 > Purpose:         Multi-layer perceptron neural nets
 > Author:          David S Young, Aug 14 1998 (see revisions)
 > Documentation:   HELP * MLP
 > Related Files:   LIB MLP
 */

/*

         CONTENTS - (Use <ENTER> g to access required sections)

 -- Data records
 -- Mask and array sampling utilities
 -- Sorting arguments for example set definition
 -- Setting up index arrays
 -- Main procedure

*/

compile_mode:pop11 +strict;

section;

uses popvision
uses boundslist_utils

include mlp

/*
-- Data records -------------------------------------------------------
*/

#_IF DEF mlp_data_record_key
    syscancel("mlp_data_record_key");
#_ENDIF

defclass procedure mlp_data_record
           {mlpdata_name,
            mlpdata_data, mlpdata_datvec,
            mlpdata_offset_mask,
            mlpdata_mask_origs,
            mlpdata_nunits,
            mlpdata_ndim,
            mlpdata_negs,
            mlpdata_niter,    ;;; for training only
            mlpdata_nbatch,   ;;; for training only
            mlpdata_ransel};  ;;; for training only

0 ->> mlp_upd_coerce(mlpdata_niter) ->> mlp_upd_coerce(mlpdata_ransel)
  ->  mlp_upd_coerce(mlpdata_nbatch);

false ->> updater(mlpdata_negs) ->> updater(mlpdata_nunits)
      ->> updater(mlpdata_ndim) ->> updater(mlpdata_offset_mask)
      ->  updater(mlpdata_mask_origs);

define lconstant oldmlpdata_data; enddefine;
define updaterof oldmlpdata_data = updater(mlpdata_data) enddefine;
define lconstant oldmlpdata_datvec; enddefine;
define updaterof oldmlpdata_datvec = updater(mlpdata_datvec) enddefine;

define updaterof mlpdata_data(data, datrec);
    unless boundslist(data) = boundslist(datrec.mlpdata_data) then
        mishap(data, datrec.mlpdata_data, 2, 'New boundslist differs from old')
    endunless;
    array_to_sfloat(data) -> data;  ;;; copy if necessary
    data -> oldmlpdata_data(datrec);
    arrayvector(data) -> oldmlpdata_datvec(datrec)
enddefine;

false -> updater(mlpdata_datvec);

/*
-- Mask and array sampling utilities ----------------------------------
*/

define lconstant mlp_offsetter(bounds) /* -> offsetter */;
    ;;; Returns a procedure which takes as many arguments as the
    ;;; array specified. Treats each argument as an offset of the
    ;;; corresponding index and returns the overall offset in the
    ;;; arrayvector
    lvars x0 x1 c
        t = 1,
        dimlist = ncrev(tl(array_dimprods(bounds)));

    if dimlist == [] then
        identfn
    else
        procedure -> offset;
            lvars offset = 0;
            lvars dlist = dimlist;
            until dlist == [] do
                * (dest(dlist) -> dlist) + offset -> offset ;;; take from stack
            enduntil;
            + offset -> offset  ;;; take from stack
        endprocedure
    endif /* -> offsetter */;
enddefine;

define lconstant mlp_arrsampler(pstart, pinc, pend) /* -> sampler */;
    ;;; Returns a repeater which on each call returns a number of results,
    ;;; starting with the elements of pstart, and then incrementing them
    ;;; by the elements of pinc until the elements of pend are reached, in
    ;;; the manner of a set of nested for loops.
    ;;; Returns the appopriate number of termins when finished.
    ;;; All elements of pinc must be positive.
    lvars
        p = copy(pstart),
        n = datalength(pstart);

    procedure;
        lvars i t;
        if p(n) > pend(n) then
            repeat n times termin endrepeat ;;; returned when finished
        else
            explode(p);        ;;; these are returned
            ;;; set up next p
            fast_for i from 1 to n do
                p(i) + pinc(i) ->> p(i) -> t;
            quitif (t <= pend(i) or i == n);  ;;; can increment - leave loop
                pstart(i) -> p(i)
            endfor
        endif
    endprocedure

enddefine;

define lconstant mlp_narrsamps(pstart,pinc,pend) -> res;
    ;;; Same arguments as mlp_arrsampler, but just returns the number
    ;;; of results that will give before it gives termin.
    lvars ps, pin, pe;
    1 -> res;
    for ps, pin, pe in_vector pstart, pinc, pend do
        res * ((pe - ps) div pin + 1) -> res
    endfor
enddefine;

define lconstant mlp_masklims(mask) -> (mins,maxs);
    ;;; Find max and min offsets in mask
    lvars m, i, v, n = length(hd(mask));
    copy(hd(mask)) -> mins;
    copy(mins) -> maxs;
    for m in mask do
        for i from 1 to n do
            m(i) -> v;
            if v < mins(i) then
                v -> mins(i)
            elseif v > maxs(i) then
                v -> maxs(i)
            endif
        endfor
    endfor
enddefine;

define lconstant mlp_stimlims(bounds,mask) -> (pstart,pend);
    ;;; Works out how close to the edges of the array the mask origin
    ;;; can go.
    lvars i, mins, maxs, n = length(hd(mask));
    initv(n) -> pstart;
    initv(n) -> pend;
    ;;; Next line stops compiler trying to make "-" unary
    lconstant 5 minus = nonop -;
    if bounds.isarray then boundslist(bounds) -> bounds endif;
    mlp_masklims(mask) -> (mins,maxs);
    for i from 1 to n do
        dest(bounds) -> bounds; minus mins(i) -> pstart(i);
        dest(bounds) -> bounds; minus maxs(i) -> pend(i)
    endfor
enddefine;

define lconstant mlp_defmask(pinc) /* -> mask */;
    ;;; Generates a list of offsets such that when used with the
    ;;; given mask origin increments, the array will be covered with
    ;;; no overlap
    lvars pin, offset, region;
    [% for pin in_vector pinc do 0, pin-1 endfor %] -> region;
    [% for offset in_region region do
            copy(offset)
        endfor %]
enddefine;

/*
-- Sorting arguments for example set definition -----------------------
*/

/*
The following routine can take a variety of argument lists, and returns
the full set of arguments.

-  mlp_sortdatargs(stims,mask,pstart,pinc,pend) -> (stims,mask,pstart,pinc,pend);

    This is the full form - the procedure returns its arguments.
    STIMS is the stimulus array
    MASK is a list of vectors, each giving an offset relative to
    the mask origin of one element of each sample to be taken from STIMS.
    PSTART is a vector giving the coordinates in STIMS of the mask origin
    for the first sample. PSTART must lie inside STIMS (even though in
    principle it need not if all the mask offsets are shifted one way)
    PINC is a vector giving the amount by which each coordinate in the mask
    origin must be shifted to get to a new position on the mask origin
    lattice. Each element must be >= 1.
    PEND is a vector giving the coordinates in STIMS of the mask origin
    for the last sample. PEND must lie inside STIMS. Each element of PEND
    must be greater than or equal to the corresponding element of PSTART.

-  mlp_sortdatargs(stims,pstart,pinc,pend) -> (stims,mask,pstart,pinc,pend);

    As above, only the mask now defaults to the set of offsets that
    allows the stimulus array to be tesselated without overlap - i.e.
    the mask specifies a continuous chunk of the array of a size equal to the
    jumps given by PINC, thus: [{0 0 0 ...} {1 0 0 ...} {pinc(1)-1 0 0 ...}
    ... {0 1 0 ...} {1 1 0 ...} ... ... {pinc(1)-1 pinc(2)-1 ...} ...].

-  mlp_sortdatargs(stims,mask,pinc) -> (stims,mask,pstart,pinc,pend);

    As the first form, only PSTART and PEND default to the minimum and maximum
    values of the coordinates, respectively, that will allow all the
    samples to come from within the array, taking account of the mask
    values.

-  mlp_sortdatargs(stims,pinc) -> (stims,mask,pstart,pinc,pend);

    Combines the defaults in the two previous examples.

-  mlp_sortdatargs(stims,mask) -> (stims,mask,pstart,pinc,pend);

    Here PINC defaults to {1 1 1 ...}, where the number of
    1s is equal to the number of dimensions of STIMS. I.e. the array is
    sampled as densely as possible.

-  mlp_sortdatargs(stims,nin,nstart,nstep,nend) -> (stims,mask,pstart,pinc,pend);

    STIMS must be 1-D in this form.
    NIN is the number of input units (i.e. the number of elements of
    a sample). Samples are taken to be contiguous chunks of the array
    - i.e. the equivalent mask would be [{0} {1} {2} ... {^nin-1}].
    NSTART is a number - the position of the first mask origin.
    NSTEP is a number - the amount to jump along the array to get each new sample -
    i.e. it is just the only element of PINC. So samples can be overlapping,
    succeed one another, or have gaps between them in the array.
    NEND is a number - the position of the last mask origin in the array.

-  mlp_sortdatargs(stims,nin,nstep) -> (stims,mask,pstart,pinc,pend);

    As above, only NSTART and NEND default to the minimum and maximum
    permissible values respectively.

-  mlp_sortdatargs(stims) -> (stims,mask,pstart,pinc,pend);

    If STIMS is 2-D
    The size of the first dimension must be equal to the number of input
    units. The size of the second dimension is the number of different
    stimuli. Each column or raster line of the array is thus taken as
    a separate stimulus - i.e. they do not overlap.

    If STIMS is 1-D
    Then assume that there is just a single example in it.

*/

define lconstant mlp_sortdatargs(stims) -> (stims,mask,pstart,pinc,pend);
    lvars mask = undef, pstart = undef, pinc, pend, nin, nstart, nstep, nend,
        stimoffs, stimstarts, i, x0, x1, nstims, b;

    if stims.isarray then
        ;;; Only one argument - may be 1-D or 2-D
        boundslist(stims) -> b;
        if length(b) == 4 then  ;;; it is 2-D
            explode(b) -> (x0,x1,,);
            x1 - x0 + 1 -> nin;
            {% nin, 1 %} -> pinc;
        elseif length(b) == 2 then  ;;; it is 1-D
            explode(b) -> (x0,x1);
            {% x1-x0+1 %} -> pinc
        else
            mishap('Need 1-D or 2-D array',[^b])
        endif

    elseif stims.isreal then
        ;;; A 1-D array followed by nin and nstep
        stims -> (stims, nin, nstep);

        if stims.isreal then    ;;; still real - nstart and nend have been given
            stims, nin, nstep -> (stims, nin, nstart, nstep, nend);
            {% nstart %} -> pstart;
            {% nend %} -> pend;
        endif;

        [% for i from 0 to nin-1 do {% i %} endfor %] -> mask;
        {% nstep %} -> pinc;

    elseif stims.islist then
        ;;; The list gives the offsets for the array. Assume densely overlapped
        ;;; samples are required
        stims -> (stims, mask);
        {% repeat pdnargs(stims) times 1 endrepeat %} -> pinc;

    elseif stims.isvector then
        ;;; have been given at least stims and pinc
        stims -> (stims, pinc);

        if stims.isvector then  ;;; Have been given pstart and pend
            stims, pinc -> (stims, pstart, pinc, pend)
        endif;

        if stims.islist then    ;;; Have been given mask
            stims -> (stims, mask)
        endif;

    endif;

    if mask == undef then       ;;; still need mask
        mlp_defmask(pinc) -> mask
    endif;

    if pstart == undef then     ;;; still need pstart and pend
        mlp_stimlims(stims, mask) -> (pstart, pend)
    endif;

enddefine;

/*
-- Setting up index arrays --------------------------------------------
*/

;;; This flag determines whether a full index array (for speed) or
;;; a skeleton specification (for size) is produced.
vars mlp_fullindex = true;

define lconstant mlp_setindexarrs(/* Arguments as for mlp_sortdatargs */)
        -> (stims, stimoffs, stimstarts, ndim, negs);

    ;;; Creates stimoffs and stimstarts arrays which specify the masks
    ;;; to use when getting examples.
    ;;; If the mlp_fullindex is true, then stimstarts is set up with
    ;;; every possible index into the arrayvector, and ndim is 0.
    ;;; Otherwise stimstarts is 2-D and is set up with the limits and
    ;;; increments, and ndim is the no. of dimensions of the data array.

    ;;; Do stack naughtiness
    lvars (stims, mask, pstart, pinc, pend) = mlp_sortdatargs();

    lvars nin = length(mask);
    mlp_narrsamps(pstart, pinc, pend) -> negs;

    ;;; Set up mask offsets
    initmlpivec(nin) -> stimoffs;
    lvars i = 0, p, procedure offs = mlp_offsetter(stims);
    for p in mask do
        i + 1 -> i;
        offs(explode(p)) -> stimoffs(i)
    endfor;

    if mlp_fullindex then
        0 -> ndim;
        initmlpivec(negs) -> stimstarts;
        lvars procedure (
            poss = array_indexer(stims),
            points = mlp_arrsampler(pstart, pinc, pend));
        fast_for i from 1 to datalength(stimstarts) do
            ;;; -1 is for zero-based C routines
            poss(points()) - 1 -> stimstarts(i)
        endfor
    else
        length(pinc) -> ndim;
        newanyarray([1 ^ndim 1 5], mlpivec_key) -> stimstarts;
        lvars base,
            dimprods = array_dimprods(stims),
            bases = array_dimbases(stims);
        for i from 1 to length(pinc) do
            dest(dimprods) -> (stimstarts(i,1), dimprods);
            dest(bases) -> (base, bases);
            pstart(i) - base ->> stimstarts(i,2) -> stimstarts(i,5);
            pinc(i) -> stimstarts(i,3);
            pend(i) - base -> stimstarts(i,4)
        endfor;
        arrayvector(stimstarts) -> stimstarts
    endif
enddefine;


/*
-- Main procedure -----------------------------------------------------
*/

define mlp_makedata(stims /* etc, niter, ransel */) /* -> datarec */;
    ;;; Arguments are as for mlp_sortdatargs, but with optionally
    ;;; the number of iterations for training and whether to use
    ;;; random selection as final two arguments.

    lvars ransel = 0, niter = 1, nbatch = 1,
        stimoffs, stimstarts, ndim, negs;

    ;;; See if ransel and niter have been specified
    if stims.isboolean then
        stims -> (stims, niter, ransel);
    endif;
    niter or 0 -> niter;        ;;; <false> means no forward pass
    unless niter.isinteger then
        explode(niter) -> (niter, nbatch)
    endunless;

    mlp_setindexarrs(stims /* and other stuff on stack */)
        -> (stims, stimoffs, stimstarts, ndim, negs);

    if nbatch == true then negs -> nbatch endif;

    ;;; Coerce array type if necessary
    array_to_sfloat(stims) -> stims;

    consmlp_data_record(
        'mlpdata',
        stims, arrayvector(stims),
        stimoffs,
        stimstarts,
        datalength(stimoffs),       ;;; nunits
        ndim,
        negs,
        niter,
        nbatch,
        if ransel then 1 else 0 endif)
enddefine;

vars mlp_data = true;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Mar  2 2000
        Moved from Sussex local vision libraries to popvision.
--- David S Young, Aug 26 1998
        Added support for batch learning.
--- David S Young, Aug 20 1998
        Minor tidying
--- David S Young, Aug 18 1998
        Added +strict compile mode and made some procedures lconstant.
 */
