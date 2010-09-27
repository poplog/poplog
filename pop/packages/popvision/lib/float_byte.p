/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 > File:            $popvision/lib/float_byte.p
 > Purpose:         Convert between packed single prec float & byte arrays
 > Author:          David S Young, Jun 11 1992 (see revisions)
 > Documentation:   HELP *FLOAT_BYTE
 > Related Files:   float_byte.c
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses objectfile
uses boundslist_utils
uses newsfloatarray
uses newbytearray

lconstant macro extname = 'float_byte',
    obfile = objectfile(extname);

unless obfile then
    mishap(obfile, 1, 'Object file not found')
endunless;

exload extname [^obfile]
    lconstant EXT_float_to_byte(7)       <-  float_to_byte,
              EXT_byte_to_float(7)       <-  byte_to_float
endexload;

define float_byte(imagein, imageout, region, p0, p255)
        -> imageout;
    lvars imagein, imageout, region, p0, p255,
        invec = arrayvector(imagein),
        b_to_f = imagein.isbytearray,
        outvec, ini1, n, outi1;

    ;;; sort out the arguments
    unless region then
        boundslist(imagein) -> region
    else
        region_inclusion_check(imagein, region)
    endunless;
    unless b_to_f or imagein.issfloatarray then
        mishap(imagein, 1, 'Input array must be packed float or byte')
    endunless;
    if imageout then
        region_inclusion_check(imageout, region);
        arrayvector(imageout) -> outvec;
        if b_to_f and not(imageout.issfloatarray) then
            mishap(imageout, 1, 'Output array must be packed float')
        endif;
        if not(b_to_f) and not(imageout.isbytearray) then
            mishap(imageout, 1, 'Output array must be packed byte')
        endif
    else        ;;; need new imageout
        if b_to_f then
            newsfloatarray(region)
        else
            newbytearray(region)
        endif -> imageout;
        arrayvector(imageout) -> outvec
    endif;
    number_coerce(p0, 0.0s0), number_coerce(p255, 0.0s0) -> (p0, p255);

    ;;; check whether region continuous in both arrayvectors
    region_arrvec(imagein, region) -> (ini1, n);
    region_arrvec(imageout, region) -> (outi1, );

    if ini1 and outi1 then
        ;;; can do it in one call
        if b_to_f then
            exacc EXT_byte_to_float
            (invec, ini1-1, outvec, outi1-1, n, p0, p255)
        else
            exacc EXT_float_to_byte
            (invec, ini1-1, outvec, outi1-1, n, p0, p255)
        endif

    else
        ;;; Need to do each line separately. (Could optimise further by
        ;;; looking for continuous subarrays if no. of dimensions > 2,
        ;;; but probably not worth it.)

        lvars
            in_index = array_indexer(imagein, true),
            out_index = array_indexer(imageout, true),
            firstindex = hd(region),
        ;;; subspace is the space of starting points for each row
            subspace = firstindex :: (firstindex :: tl(tl(region))),
            rep = region_rep(subspace),
            coords;
        hd(tl(region)) - firstindex + 1 -> n;   ;;; no of points in a line

        ;;; loop over the starting points
        until (rep() ->> coords) == termin do
            in_index(explode(coords)) -> ini1;
            out_index(explode(coords)) -> outi1;
            if b_to_f then
                exacc EXT_byte_to_float
                (invec, ini1-1, outvec, outi1-1, n, p0, p255)
            else
                exacc EXT_float_to_byte
                (invec, ini1-1, outvec, outi1-1, n, p0, p255)
            endif
        enduntil

    endif

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Nov 16 1994
        Changed newsarray to newbytearray
        Gets isbytearray from LIB * NEWBYTEARRAY
        Mishaps if object file not found (used to just set float_byte to false)
--- David S Young, Jul 13 1993
        Changed -newfloatarray- to -newsfloatarray- and -isfloatarray- to
        -issfloatarray- to avoid name clash with *VEC_MAT package.
--- David S Young, Sep  8 1992
        Uses -class_spec- instead of -class_field_spec- for generality
--- David S Young, Jun 19 1992
        Gets -isfloatarray- from LIB NEWFLOATARRAY
 */
