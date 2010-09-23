/* --- Copyright University of Sussex 1999. All rights reserved. ----------
 > File:            $popvision/lib/array_mxmn.p
 > Purpose:         Return maximum and minimum values from an array
 > Author:          David S Young, Jul 13 1993 (see revisions)
 > Documentation:   HELP *ARRAY_MXMN
 > Related Files:   array_mxmn.c
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses objectfile
uses ext2d_args

lconstant macro extname = 'array_mxmn',
    obfile = objectfile(extname);

unless obfile then
    mishap(0, 'Cannot find object file - see LIB OBJECTFILE for info')
endunless;

exload extname [^obfile]
        constant    array_mxmn_2d_b(6),
                    array_mxmn_2d_f(6)
endexload;

define array_mxmn(arr, region) -> (mx, mn);
    ;;; Find max and min values in specified region of array. Optimised
    ;;; for 2-D byte and single precision float arrays, but almost optimal
    ;;; for any number of dimensions with these types.
    lvars arr, region, mx, mn;

    ;;; Array info
    lvars
        arrspec = arr.arrayvector.datakey.class_spec,
        itsafloatarr = arrspec == "decimal",
        itsabytearr = arrspec == 8;

    ;;; Default region
    unless region then
        boundslist(arr) -> region
    endunless;

    ;;; Either its a byte or float array and can use
    ;;; an external proc for speed or its not and have to do it in POP-11.

    defclass lconstant vfloat :float;
    lconstant
        fresults = initvfloat(2),
        bresults = initintvec(2);
    lvars extargs, argvec, results;

    if itsabytearr then
        ext2d_args([% arr %], region) -> extargs;
        if extargs.isvector then
            exacc array_mxmn_2d_b(explode(extargs), bresults);
            bresults(1) -> mx;
            bresults(2) -> mn;
        else
            false ->> mx -> mn;
            for argvec from_repeater extargs do
                exacc array_mxmn_2d_b(explode(argvec), bresults);
                bresults(1), if mx then max(mx) endif -> mx;
                bresults(2), if mn then min(mn) endif -> mn;
            endfor
        endif

    elseif itsafloatarr then
        ext2d_args([% arr %], region) -> extargs;
        if extargs.isvector then
            exacc array_mxmn_2d_f(explode(extargs), fresults);
            fresults(1) -> mx;
            fresults(2) -> mn;
        else
            false ->> mx -> mn;
            for argvec from_repeater extargs do
                exacc array_mxmn_2d_f(explode(argvec), fresults);
                fresults(1), if mx then max(mx) endif -> mx;
                fresults(2), if mn then min(mn) endif -> mn;
            endfor
        endif

    else    ;;; do it in POP-11

        ;;; Get first point now to avoid test in loop, using odd elements
        ;;; of the region.
        lvars r = region;
        arr(
            until r == [] do
                destpair(r) -> r; back(r) -> r;
            enduntil
        ) ->> mn -> mx;

        lvars v;
        for v in_array arr in_region region do
            if v < mn then
                v -> mn
            elseif v > mx then
                v -> mx
            endif
        endfor

    endif

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Sep 24 1999
        Added test for missing object file
--- David S Young, Jan 25 1994
        Uses in_array and ext2d_args.
 */
