/* --- Copyright University of Sussex 2001. All rights reserved. ----------
 > File:            $popvision/lib/convolve_2d.p
 > Purpose:         Convolve a 2-D array with a 2-D mask (non-circular)
 > Author:          David S Young, Jun  3 1992 (see revisions)
 > Documentation:   HELP CONVOLVE_2D
 > Related Files:   convolve_2d.c
 */

compile_mode:pop11 +strict;

section;

uses popvision, objectfile, boundslist_utils, arraysample,
    newsfloatarray, newbytearray, float_byte;

lconstant macro extname = 'convolve_2d',
    obfile = objectfile(extname);

unless obfile then
    mishap(0, 'Cannot find object file')
endunless;

exload extname [^obfile] lconstant
    convolve_2d_skip_f(20)
endexload;

lconstant macro ltag = [ #_< consref(0) >_# ];  ;;; For oldarray

define lconstant float_2d_array_check(arr, tag) /* -> arr */;
    ;;; Checks an array is 2d.
    ;;; Checks the array has a float array vector, and if not,
    ;;; constructs a new array of that type, with the data copied.
    dlocal poparray_by_row = true;
    unless arr.isarray_by_row and pdnargs(arr) == 2 then
        mishap(arr, 1, 'Need 2-D array ordered by row')
    endunless;
    if arr.issfloatarray then
        arr
    elseif arr.isbytearray then
        float_byte(arr, oldsfloatarray(tag, boundslist(arr)), false, 0, 255)
    else
        oldsfloatarray(tag, boundslist(arr), arr)
    endif
enddefine;

define lconstant array_offset(arr) /* -> off */;
    lvars ( , start) = arrayvector_bounds(arr);
    start - 1 /* -> offset */
enddefine;

define lconstant input_region(skip, m0, m1, out0, out1) -> (in0, in1);
    ;;; Given a skip and start and end points for the mask and output region,
    ;;; gives the start and end points for the input region.
    out0*skip - m1 -> in0;
    out1*skip - m0 -> in1
enddefine;

define lconstant skip_trim(g0, g1, skip) -> (g0, g1);
    ;;; Given start and end points and a skip, returns trimmed
    ;;; start and end points which are multiples of the skip.
    g0 + -g0 mod skip -> g0;
    g1+1 - skip + -(g1+1) mod skip -> g1;
enddefine;

define lconstant output_region(in0, in1, skip, m0, m1) -> (out0, out1);
    ;;; Given input start and end points, a skip, and mask start and
    ;;; end points, returns output start and end points.
    lvars (g0, g1) = skip_trim(in0+m1, in1+m0, skip);
    g0 div skip -> out0;
    g1 div skip -> out1;
enddefine;

define lconstant getoptargs(arrin) -> (arrin, skip_x, skip_y);
    ;;; get optional skip arguments
    1 ->> skip_x -> skip_y;
    unless arrin.isarray or arrin.islist then
        arrin -> (arrin, skip_y);
        checkinteger(skip_y, 1, false);
        skip_y -> skip_x
    endunless;
    unless arrin.isarray or arrin.islist then
        arrin -> (arrin, skip_x);
        checkinteger(skip_x, 1, false)
    endunless
enddefine;

define convolve_2d(arrin, mask, arrout, out_region) -> arrout;
    lvars skip_x, skip_y;
    getoptargs(arrin) -> (arrin, skip_x, skip_y);

    lvars
        arrout_orig = false,            ;;; original arrout
        in_x0, in_x1, in_y0, in_y1,     ;;; input bounds
        ir_x0, ir_x1, ir_y0, ir_y1,     ;;; actual input region
        ms_x0, ms_x1, ms_y0, ms_y1,     ;;; mask bounds
        ot_x0, ot_x1, ot_y0, ot_y1,     ;;; output array bounds
        or_x0, or_x1, or_y0, or_y1;     ;;; actual output region

    ;;; Coerce arrays to packed float, check they are 2-D, and
    ;;; get the array bounds into separate variables.
    float_2d_array_check(arrin, ltag) -> arrin;
    explode(boundslist(arrin)) -> (in_x0, in_x1, in_y0, in_y1);
    float_2d_array_check(mask, ltag) -> mask;
    explode(boundslist(mask)) -> (ms_x0, ms_x1, ms_y0, ms_y1);
    if arrout.islist then
        lvars initval = 0.0;
        if length(arrout) == 5 then
            dest(arrout) -> (initval, arrout)
        endif;
        explode(arrout) -> (ot_x0, ot_x1, ot_y0, ot_y1);
        newsfloatarray(arrout, initval) -> arrout;
    elseif arrout.isarray then
        arrout -> arrout_orig;     ;;; save original input
        float_2d_array_check(arrout, ltag) -> arrout;
        explode(boundslist(arrout)) -> (ot_x0, ot_x1, ot_y0, ot_y1);
    endif;

    ;;; Construct the input and output regions
    if out_region.islist then  ;;; output region is explicit, get input reg.

        if arrout.isarray then region_inclusion_check(arrout, out_region) endif;
        explode(out_region) -> (or_x0, or_x1, or_y0, or_y1);
        input_region(skip_x, ms_x0, ms_x1, or_x0, or_x1) -> (ir_x0, ir_x1);
        input_region(skip_y, ms_y0, ms_y1, or_y0, or_y1) -> (ir_y0, ir_y1);
        lconstant in_region = [0 0 0 0];    ;;; not used as boundslist
        (ir_x0, ir_x1, ir_y0, ir_y1) -> explode(in_region);
        region_inclusion_check(arrin, in_region);

    else    ;;; get output region from input array

        output_region(in_x0, in_x1, skip_x, ms_x0, ms_x1) -> (or_x0, or_x1);
        output_region(in_y0, in_y1, skip_y, ms_y0, ms_y1) -> (or_y0, or_y1);
        [% or_x0, or_x1, or_y0, or_y1 %] -> out_region;  ;;; used as boundslist
        ;;; and generate actual input region
        input_region(skip_x, ms_x0, ms_x1, or_x0, or_x1) -> (ir_x0, ir_x1);
        input_region(skip_y, ms_y0, ms_y1, or_y0, or_y1) -> (ir_y0, ir_y1);

    endif;

    ;;; Check output region
    if or_x0 > or_x1 or or_y0 > or_y1 then
        mishap(arrin, mask, arrout, out_region, 4,
            'No valid outputs - mask bigger than input array, or output region null')
    endif;
    ;;; Check arrout or construct it
    if arrout.isarray then
        region_inclusion_check(arrout, out_region)
    else
        oldsfloatarray(arrout, out_region) -> arrout;
        (or_x0, or_x1, or_y0, or_y1) -> (ot_x0, ot_x1, ot_y0, ot_y1);
    endif;

    ;;; All seems ready do the convolution
    exacc convolve_2d_skip_f(
        arrayvector(arrin),             ;;;  in_2d
        array_offset(arrin),            ;;;  in_offset
        in_x1 - in_x0 + 1,              ;;;  in_xsize
        ir_x0 + ms_x1 - in_x0,          ;;;  in_xstart
        ir_y0 + ms_y1 - in_y0,          ;;;  in_ystart
        skip_x, skip_y,                 ;;;  in_xskip, in_yskip
        arrayvector(mask),              ;;;  mask_2d
        array_offset(mask),             ;;;  mask_offset
        ms_x1 - ms_x0 + 1,              ;;;  mask_xsize
        ms_y1 - ms_y0 + 1,              ;;;  mask_ysize
        -ms_x0,                         ;;;  mask_xorig
        -ms_y0,                         ;;;  mask_yorig
        arrayvector(arrout),            ;;;  out_2d
        array_offset(arrout),           ;;;  out_offset
        ot_x1 - ot_x0 + 1,              ;;;  out_xsize
        or_x0 - ot_x0,                  ;;;  out_xstart
        or_x1 - ot_x0,                  ;;;  out_xend
        or_y0 - ot_y0,                  ;;;  out_ystart
        or_y1 - ot_y0                   ;;;  out_yend
    );

    ;;;  copy back if arrout was supplied by not sfloat
    if arrout_orig and arrout_orig /== arrout then
        arraysample(arrout, false, arrout_orig, false, "nearest") -> arrout
    endif

enddefine;

define convolve_2d_sizeout(arrin, mask) -> bdsout;
    lvars skip_x, skip_y;
    getoptargs(arrin) -> (arrin, skip_x, skip_y);

    lvars
        in_x0, in_x1, in_y0, in_y1,     ;;; input bounds
        ms_x0, ms_x1, ms_y0, ms_y1,     ;;; mask bounds
        or_x0, or_x1, or_y0, or_y1;     ;;; actual output region

    if arrin.isarray then boundslist(arrin) -> arrin endif;
    explode(arrin) -> (in_x0, in_x1, in_y0, in_y1);
    if mask.isarray then boundslist(mask) -> mask endif;
    explode(mask) -> (ms_x0, ms_x1, ms_y0, ms_y1);

    output_region(in_x0, in_x1, skip_x, ms_x0, ms_x1) -> (or_x0, or_x1);
    output_region(in_y0, in_y1, skip_y, ms_y0, ms_y1) -> (or_y0, or_y1);
    if or_x0 > or_x1 or or_y0 > or_y1 then
        false -> bdsout
    else
        [% or_x0, or_x1, or_y0, or_y1 %] -> bdsout
    endif
enddefine;

define convolve_2d_sizein(arrin, mask, out_region) -> bdsin;
    lvars skip_x, skip_y;
    getoptargs(arrin) -> (arrin, skip_x, skip_y);

    lvars
        ir_x0, ir_x1, ir_y0, ir_y1,     ;;; actual input region
        ms_x0, ms_x1, ms_y0, ms_y1,     ;;; mask bounds
        or_x0, or_x1, or_y0, or_y1;     ;;; actual output region

    if mask.isarray then boundslist(mask) -> mask endif;
    explode(mask) -> (ms_x0, ms_x1, ms_y0, ms_y1);
    if out_region.isarray then boundslist(out_region) -> out_region endif;
    explode(out_region) -> (or_x0, or_x1, or_y0, or_y1);

    input_region(skip_x, ms_x0, ms_x1, or_x0, or_x1) -> (ir_x0, ir_x1);
    input_region(skip_y, ms_y0, ms_y1, or_y0, or_y1) -> (ir_y0, ir_y1);
    [% ir_x0, ir_x1, ir_y0, ir_y1 %] -> bdsin;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Nov 12 2001
        Added sizein and sizeout routines and fixed minor bug that did not
        allow tag to be passed as output array argument.
--- David Young, Oct 28 2001
        Substantial revision. Main effect is to allow optional "skip"
        arguments so that subsampling can take place at the same time as
        convolution. Also updated to allow arrays offset in arrayvector,
        and now insists that output array is big enough to take whole of
        output region, whether defined by explicit final argument or
        implicitly from input array, skip arguments and mask. This last
        change is incompatible with previous versions, which took the
        intersection of the output array and output region, but this is
        different from the rest of popvision and is unlikely ever to
        have been used.
--- David S Young, Jul 13 1993
        Changed -newfloatarray- to -newsfloatarray- and -isfloatarray- to
        -issfloatarray- to avoid name clash with *VEC_MAT package.
--- David S Young, Jun 19 1992
        Changed to test arrays using -isfloatarray-
 */
