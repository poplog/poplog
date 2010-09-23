/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 > File:            $popvision/lib/convolve_nx1d.p
 > Purpose:         Convolve N-D array with 1-D array
 > Author:          David S Young, Jun  3 1992 (see revisions)
 > Documentation:   HELP CONVOLVE_NX1D
 > Related Files:   convolve_1d.c
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses objectfile
uses boundslist_utils
uses newsfloatarray

lconstant macro extname = 'convolve_1d',
    obfile = objectfile(extname);

unless obfile then
    mishap(0, 'Cannot find object file')
endunless;

exload extname [^obfile]
    lconstant convolve_1d_f(10)
endexload;

define lconstant float_array_check(arr) /* -> arr */;
    ;;; Checks the array has a float array vector, and if not,
    ;;; constructs a new array of that type, with the data copied.
    lvars arr;
    if arr.issfloatarray then
        arr
    else
        newsfloatarray(boundslist(arr), arr)
    endif
enddefine;

/* The main procedure - see above for details */

define procedure convolve_nx1d(arrin, mask, D, arrout, region) -> arrout;
    lvars arrin, mask, D, arrout, region;

    lvars
        in_0, in_1, ms_0, ms_1, rg_0, rg_1, ;;; bounds along the active dim
        in_reg_max, coords, out_span,
        procedure (newcoords, arrin_offset, arrout_offset),
        in_start, in_step, mask_size, mask_orig,    ;;; args for ext
        out_start, out_step, out_end;               ;;; call

    ;;; Coerce arrays to packed float, and get the bounds of the active
    ;;; dimension
    float_array_check(arrin) -> arrin;
    nthbounds(arrin, D) -> (in_0, in_1);
    float_array_check(mask) -> mask;
    unless length(boundslist(mask)) == 2 then
        mishap(mask, 1, 'Need 1-D mask array')
    endunless;
    explode(boundslist(mask)) -> (ms_0, ms_1);
    if arrout.islist then
        newsfloatarray(tl(arrout), hd(arrout)) -> arrout
    endif;
    if arrout then
        float_array_check(arrout) -> arrout;
    endif;

    ;;; Construct the output region
    ;;; in_reg_max is the maximal region in the input array
    copylist(boundslist(arrin)) -> in_reg_max;
    (in_0 + ms_1, in_1 + ms_0) -> nthbounds(in_reg_max, D);
    if  region.islist then  ;;; it is explicit as an argument
        ;;; so check it is legal
        region_inclusion_check(in_reg_max, region);
        if arrout then region_inclusion_check(arrout, region) endif;
    else    ;;; get region from input array and mask
        if arrout then  ;;; take the intersection
            region_intersect(in_reg_max, arrout)
        else
            in_reg_max
        endif -> region;
    endif;
    nthbounds(region, D) -> (rg_0, rg_1);

    ;;; Mishap if either the mask was bigger than the input image,
    ;;; or the output region is wholly outside the output array
    region_nonempty_check(region);

    ;;; Construct the output array if need be
    unless arrout then
        newsfloatarray(region) -> arrout;
    endunless;

    ;;; Set the "region" to be the subspace of starting points
    ;;; Copy to avoid updating argument or boundslist of arrout
    copylist(region) -> region;
    rg_0 -> region(D * 2);        ;;; instead of rg_1

    ;;; Set up repeater and array index references
    region_rep(region) -> newcoords;
    array_indexer(arrin) -> arrin_offset;
    array_indexer(arrout) -> arrout_offset;

    ms_1 - ms_0 + 1 -> mask_size;
    -ms_0 -> mask_orig;

    ;;; Get step sizes
    array_stepsize(arrin, D) -> in_step;
    array_stepsize(arrout, D) -> out_step;
    out_step * (rg_1 - rg_0) -> out_span;

    ;;; Loop over the subspace of starting points
    until (newcoords() ->> coords) == termin do

        arrin_offset(explode(coords)) - 1 -> in_start;
        arrout_offset(explode(coords)) - 1 -> out_start;
        out_start + out_span -> out_end;

        ;;; Do the 1-D convolution on this row
        exacc convolve_1d_f(
            arrayvector(arrin),             ;;;  in_1d
            in_start,
            in_step,
            arrayvector(mask),              ;;;  mask_1d
            mask_size,
            mask_orig,
            arrayvector(arrout),            ;;;  out_1d
            out_start,
            out_step,
            out_end
        )

    enduntil

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Jul 13 1993
        Changed -newfloatarray- to -newsfloatarray- and -isfloatarray- to
        -issfloatarray- to avoid name clash with *VEC_MAT package.
--- David S Young, Jun 19 1992
        Now tests arrays with -isfloatarray-
 */
