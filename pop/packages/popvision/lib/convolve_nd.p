/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 > File:            $popvision/lib/convolve_nd.p
 > Purpose:         Convolution of N-D arrays
 > Author:          David S Young, Nov 26 1992 (see revisions)
 > Documentation:   HELP *CONVOLVE_ND
 > Related Files:   LIB *CONVOLVE_INDEX_F.C
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

;;; Next declaration not lconstant in case another library uses the
;;; external procedure.
exload extname [^obfile]
    constant convolve_index_f(10)
endexload;

#_ENDIF

define convolve_nd(arrin, mask, arrout, region) -> arrout;
    lvars arrin, mask, arrout, region;
    lvars
        ndim = pdnargs(arrin),
        masklen = datalength(mask);

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

    ;;; Check and sort out mask argument
    unless pdnargs(mask) == ndim then
        mishap(arrin, mask, 2, 'Arrays different no. dimensions')
    endunless;
    ;;; Check for non-offset float array
    lvars (, mstart) = arrayvector_bounds(mask);
    unless mask.issfloatarray and mstart == 1 then
        newsfloatarray(boundslist(mask), mask) -> mask
    endunless;

    ;;; Get offsets corresponding to the mask array.
    lvars offsetvec,
        procedure arrin_index = array_indexer(arrin),
        zero_offset = arrin_index(repeat ndim times 0 endrepeat),
        procedure mask_rep = region_rep(mask),
        mask_coords;
    until (mask_rep() ->> mask_coords) == termin do
        zero_offset - arrin_index(explode(mask_coords)) ;;; on stack
    enduntil, consintvec(masklen) -> offsetvec;

    ;;; Get maximum output region
    lvars i, r0, r1, m0, m1, regionmax;
    [% for i from 1 to ndim do
            nthbounds(boundsin, i) -> (r0, r1);
            nthbounds(mask, i) -> (m0, m1);
            (r0 fi_+ m1, r1 fi_+ m0)
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
            arrayvector(mask),
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
