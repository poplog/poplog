/* --- Copyright University of Sussex 1996. All rights reserved. ----------
 > File:            $popvision/lib/arrayset.p
 > Purpose:         Set a region of an array to a constant value
 > Author:          David S Young, Jul  8 1996
 > Documentation:   HELP * ARRAYSET
 > Related Files:   LIB * ARRAYSET.C
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses objectfile
uses ext2d_args
uses newsfloatarray
uses newbytearray

lconstant macro extname = 'arrayset',
    obfile = objectfile(extname);

exload extname [^obfile] lconstant
    arrayset_2d_b(val, xreg, yreg, av, start, jump),
    arrayset_2d_f(val<SF>, xreg, yreg, av, start, jump)
endexload;

define arrayset(val, arr, region);
    ;;; Set the values in the specified region of the array. Optimised
    ;;; for 2-D byte and single precision float arrays, but almost optimal
    ;;; for any number of dimensions with these types.
    lvars val, arr, region;

    ;;; Default region
    unless region then
        boundslist(arr) -> region
    endunless;

    lvars extargs, argvec, results;

    if arr.isbytearray then
        ext2d_args([% arr %], region) -> extargs;
        checkinteger(val, 0, 255);
        if extargs.isvector then
            exacc arrayset_2d_b(val, explode(extargs));
        else
            for argvec from_repeater extargs do
                exacc arrayset_2d_b(val, explode(argvec));
            endfor
        endif

    elseif arr.issfloatarray then
        ext2d_args([% arr %], region) -> extargs;
        number_coerce(val, 0.0) -> val;
        if extargs.isvector then
            exacc arrayset_2d_f(val, explode(extargs));
        else
            for argvec from_repeater extargs do
                exacc arrayset_2d_f(val, explode(argvec));
            endfor
        endif

    else    ;;; do it in POP-11
        lvars v;
        for v in_array arr updating_last in_region region do
            val -> v;
        endfor

    endif

enddefine;

endsection;
