/* --- Copyright University of Sussex 2001. All rights reserved. ----------
 > File:            $popvision/lib/array_transpose.p
 > Purpose:         Transpose a 2D array
 > Author:          David Young, Mar 29 2001 (see revisions)
 > Documentation:   HELP * ARRAY_TRANSPOSE
 */

compile_mode:pop11 +strict;

section;

uses popvision, objectfile, ext2d_args, newsfloatarray, newbytearray;

lconstant macro extname = 'array_transpose',
    obfile = objectfile(extname);

exload extname [^obfile] lconstant
    array_transpose_f(8),
    array_transpose_b(8)
endexload;

define array_transpose(arrin, region, arrout) -> arrout;
    unless region then
        boundslist(arrin) -> region
    endunless;
    lvars
        (x0, x1, y0, y1) = explode(region),
        regout = [^y0 ^y1 ^x0 ^x1];
    if arrout.isarray then
        ;;; maybe ought to allow non-overlapping regions here
        if arrayvector(arrout) == arrayvector(arrin) then
            mishap(arrin, arrout, 2, 'Arrays must be distinct')
        endif
    elseif arrout then
        oldanyarray(arrout, regout, datakey(arrayvector(arrin))) -> arrout
    else
        newanyarray(regout, datakey(arrayvector(arrin))) -> arrout
    endif;
    if arrin.issfloatarray and arrin.isarray_by_row
    and arrout.issfloatarray and arrout.isarray_by_row then
        ;;; can use external routine
        lvars
            argsin = ext2d_args([^arrin], region),
            ( , , vecout, offout, xincout)
            = explode(ext2d_args([^arrout], regout));
        exacc array_transpose_f(explode(argsin), vecout, offout, xincout);
    elseif arrin.isbytearray and arrin.isarray_by_row
    and arrout.isbytearray and arrout.isarray_by_row then
        ;;; can use external routine
        lvars
            argsin = ext2d_args([^arrin], region),
            ( , , vecout, offout, xincout)
            = explode(ext2d_args([^arrout], regout));
        exacc array_transpose_b(explode(argsin), vecout, offout, xincout);
    else
        ;;; have to use pop11
        lvars x, y;
        fast_for y from y0 to y1 do
            fast_for x from x0 to x1 do
                arrin(x, y) -> arrout(y, x)
            endfor
        endfor
    endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Oct  5 2001
        Added region and arrout arguments, and provided external routines
        for fast processing of float and byte arrays.
 */
