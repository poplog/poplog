/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 > File:            $popvision/lib/convolve_index.p
 > Purpose:         General indexed convolution
 > Author:          David S Young, Nov 26 1992 (see revisions)
 > Documentation:   HELP *CONVOLVE_INDEX
 > Related Files:   $popvision/lib/convolve_index.c
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses objectfile
uses boundslist_utils
uses newsfloatarray

#_IF not(DEF convolve_index)

lconstant macro extname = 'convolve_index',
    obfile = objectfile(extname);

unless obfile then
    mishap(0, 'Cannot find object file')
endunless;

;;; Next declaration should not be lconstant in case another procedure
;;; uses this.
exload extname [^obfile]
    constant convolve_index_f(10)
endexload;

#_ENDIF

define convolve_index(arrin, weights, offsets, arrout, region) -> arrout;
    lvars arrin, weights, offsets, arrout, region;
    lvars
        masklen = length(offsets),
        ndim = pdnargs(arrin);

    ;;; Sort out input and output array arguments
    lvars boundsin = boundslist(arrin);
    unless arrin.issfloatarray then
        newsfloatarray(boundsin, arrin) -> arrin
    endunless;
    if arrout.islist then
        newsfloatarray(tl(arrout), hd(arrout)) -> arrout
    elseif arrout and not(arrout.issfloatarray) then
        newsfloatarray(boundslist(arrout), arrout) -> arrout
    endif;

    ;;; Check and sort out weight argument
    unless length(weights) == masklen then
        mishap(weights, offsets, 2, 'Different lengths of weights and offsets')
    endunless;
    ;;; Check for non-offset float array
    unless weights.issfloatarray
    and weights.arrayvector_bounds.erase == masklen then
        if weights.isarray then
            newsfloatarray(boundslist(weights), weights)
        else
            ;;; Copy data out of lists or vectors
            newsfloatarray([1 ^masklen],
                class_apply(datakey(weights))(%weights%))
        endif -> weights
    endunless;

    ;;; Convert offsets to scalar offsets, and find max and min on
    ;;; each dimensions
    lvars i, off,
        procedure arrin_index = array_indexer(arrin),
        zero_offset = arrin_index(repeat ndim times 0 endrepeat),
        offset, offsetvec,
        offsetsmin = copydata(hd(offsets)),
        offsetsmax = copydata(offsetsmin);
    fast_for offset in offsets do
        ;;; Find max and min offsets
        fast_for i from 1 to ndim do
            offset(i) ->> off;     ;;; on stack for arrin_index
            if off > offsetsmax(i) then
                off -> offsetsmax(i)
            elseif off < offsetsmin(i) then
                off -> offsetsmin(i)
            endif;
        endfor;
        ;;; The negate in the next line is what determines
        ;;; that offsets are in mask, not in input array
        (arrin_index() - zero_offset).negate   ;;; on stack for consintvec
    endfor, consintvec(masklen) -> offsetvec;

    ;;; Get maximum output region
    lvars r0, r1, regionmax;
    [% for i from 1 to ndim do
            nthbounds(boundsin, i) -> (r0, r1);
            (r0 fi_+ offsetsmax(i), r1 fi_+ offsetsmin(i))
        endfor %] -> regionmax;
    ;;; Take part that will go into output array if specified
    if arrout then
        region_intersect(arrout, regionmax) -> regionmax
    endif;
    ;;; And sort out the region argument
    if region then
        region_inclusion_check(regionmax, region);
    else    ;;; get region from input and output arrays
        regionmax -> region
    endif;
    region_nonempty_check(region);

    ;;; Create the output array if needed
    unless arrout then
        newsfloatarray(region) -> arrout
    endunless;

    ;;; End of sorting out arguments.

    ;;; Find the largest dimension of the output region - most
    ;;; efficient to let the loop over this be done in the external
    ;;; procedure.
    nthbounds(region, 1) -> (r0, r1);
    lvars s, maxdim = 1, maxsize = r1 - r0;
    for i from 2 to ndim do
        nthbounds(region, i) -> (r0, r1);
        if (r1 - r0 ->> s) > maxsize then
            s -> maxsize;
            i -> maxdim
        endif
    endfor;

    ;;; Set up to loop over start points in array
    lvars
        procedure arrout_index = array_indexer(arrout),
        (r0, r1) = nthbounds(region, maxdim);
    copylist(region) -> region;     ;;; in case it was an argument
    (r0, r0) -> nthbounds(region, maxdim);  ;;; subspace of start points
    lvars startpoint, in_start, out_start,
        ntodo = r1 - r0 + 1,
        in_incr = array_dimprods(arrin)(maxdim),
        out_incr = array_dimprods(arrout)(maxdim),
        procedure startpoints = region_rep(region);
    ;;; Loop over startpoints for indexed convolution
    until (startpoints() ->> startpoint) == termin do

        arrin_index(explode(startpoint)) - 1 -> in_start;
        arrout_index(explode(startpoint)) - 1 -> out_start;

        exacc convolve_index_f(
            arrayvector(arrin),
            in_start,
            in_incr,
            arrayvector(weights),
            offsetvec,
            masklen,
            arrayvector(arrout),
            out_start,
            out_incr,
            ntodo
        )
    enduntil

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Jul 13 1993
        Changed -newfloatarray- to -newsfloatarray- and -isfloatarray- to
        -issfloatarray- to avoid name clash with *VEC_MAT package.
 */
