/* --- Copyright University of Sussex 2006. All rights reserved. ----------
 > File:            $popvision/lib/float_arrayprocs.p
 > Purpose:         Miscellaneous operations on floating point arrays
 > Author:          David Young, Nov 12 1992 (see revisions)
 > Documentation:   HELP *FLOAT_ARRAYPROCS
 > Related Files:   LIB *NEWSFLOATARRAY
 */

/* Some procedures for operating on floating point arrays.
The arrays have to fill their arrayvectors and be of type float. */

compile_mode:pop11 +strict;

section;

uses popvision
uses objectfile
uses newsfloatarray
uses newbytearray

lconstant macro extname = 'float_arrayprocs',
    obfile = objectfile(extname);

unless obfile then
    mishap(0, 'Cannot find object file')
endunless;

;;; Altered [AS]
;;; exload extname [^obfile '-lm']
exload extname [^obfile ]
    EXT_bytearray2float(3)               <- bytearray2float,
    EXT_float_arraydiff(4)               <- float_arraydiff,
    EXT_float_arraysum(4)                <- float_arraysum,
    EXT_float_arraymult(4)               <- float_arraymult,
    EXT_float_complexmult(7)             <- float_complexmult,
    EXT_float_arraydiv(4)                <- float_arraydiv,
    EXT_float_arraycomb(6)               <- float_arraycomb,
    EXT_float_arrayhypot(4)              <- float_arrayhypot,
    EXT_float_arrayatan2(4)              <- float_arrayatan2,
    EXT_float_arraythreshold(7)          <- float_arraythreshold,
    EXT_float_arraythreshold2(9)         <- float_arraythreshold2,
    EXT_float_arrayabs(3)                <- float_arrayabs,
    EXT_float_arraysqr(3)                <- float_arraysqr,
    EXT_float_arraysqrt(3)               <- float_arraysqrt,
    EXT_float_arraylogistic(3)           <- float_arraylogistic,
    EXT_float_arraymean(2): float        <- float_arraymean,
    EXT_float_arraymean_mask(4): float   <- float_arraymean_mask,
    EXT_float_arraysetc(3)               <- float_arraysetc,
    EXT_float_arrayhist(6)               <- float_arrayhist,
    EXT_float_arraymultc(4)              <- float_arraymultc,
    EXT_float_arrayaddc(4)               <- float_arrayaddc,
    EXT_float_arrayaddc_mask(6)          <- float_arrayaddc_mask,
    EXT_float_arraymultc_mask(6)         <- float_arraymultc_mask,
    EXT_float_arraymeansd(4)             <- float_arraymeansd,
    EXT_float_arraymeansd_mask(6)        <- float_arraymeansd_mask,
    EXT_float_arraywtdav_mask(7)         <- float_arraywtdav_mask,
    EXT_float_arraydilate(5)             <- float_arraydilate,
    EXT_float_arrayerode(5)              <- float_arrayerode,
    EXT_floatarray2byte(7)               <- floatarray2byte
endexload;


define lconstant tofloat = number_coerce(%0.0s0%) enddefine;

define lconstant b2i(bool) /* -> int */;
    if bool then 1 else 0 endif
enddefine;

/* Convenient array checking stuff for operations that
do not need the arraybounds */

define constant isontoarray(array) /* -> boolean */;
    ;;; Check an array fills its arrayvector
    lvars (e, s) = arrayvector_bounds(array);
    s == 1 and e == datalength(array)
enddefine;

define lconstant float_arrcheck1(arr1);
    ;;; Mishaps if array is not onto and not a float array
    unless arr1.isontoarray then
        mishap(arr1, 1, 'Array does not exactly fit arrayvector')
    endunless;
    unless arr1.issfloatarray then
        mishap(arr1, 1, 'Array not packed floating array')
    endunless;
enddefine;

define lconstant float_arrcheck2(arr1, arr2);
    ;;; Checks that two arrays are onto and have same bounds
    float_arrcheck1(arr1);
    float_arrcheck1(arr2);
    unless boundslist(arr1) = boundslist(arr2) then
        mishap(arr1, arr2, 2, 'Arrays different dimensions')
    endunless;
enddefine;

define lconstant float_arrcheckn(n);
    ;;; Checks that n arrays (on stack) are onto and have same bounds
    lvars arr, b1 = false, b;
    repeat n times
            -> arr;     ;;; next thing from stack
        float_arrcheck1(arr);
        boundslist(arr) -> b;
        if b1 then
            unless boundslist(arr) = b1 then
                mishap(b, b1, 2, 'Arrays different dimensions')
            endunless
        else
            b -> b1
        endif
    endrepeat
enddefine;

define lconstant float_getoutput1(arr1,arr2) -> arr2;
    ;;; If arr2 is false, check arr1 and then
    ;;; return a full array same size as arr1; if
    ;;; arr2 is an array, check it matches arr1 and return it
    if arr2.isarray then
        float_arrcheck2(arr1, arr2)
    else
        float_arrcheck1(arr1);
        oldsfloatarray(arr2, boundslist(arr1)) -> arr2
    endif
enddefine;

/* Operations that work on individual pixels */

define float_arraycopy(arr1, arr2) -> arr2;
    float_getoutput1(arr1, arr2) -> arr2;
    move_subvector(1, arrayvector(arr1), 1, arrayvector(arr2), datalength(arr1))
enddefine;

define byte2float(arr1, arr2) -> arr2;
    unless arr1.isontoarray and
        class_spec(datakey(arrayvector(arr1))) == 8 then
        mishap(arr1, 1, 'Not byte array or does not fill arrayvector')
    endunless;
    if arr2 then
        unless datalength(arr2) == datalength(arr1) then
            mishap(arr1, arr2, 2, 'Output array wrong size')
        endunless;
        float_arrcheck1(arr2)
    else
        newsfloatarray(boundslist(arr1)) -> arr2
    endif;

    exacc EXT_bytearray2float(arrayvector(arr1), arrayvector(arr2),
        datalength(arr2))
enddefine;

define float2byte(min1, max1, arr1, min2, max2, arr2) -> arr2;
    float_arrcheck1(arr1);
    if arr2 then
        unless arr2.isontoarray and
            class_spec(datakey(arrayvector(arr2))) == 8 and
            datalength(arr2) == datalength(arr1) then
            mishap(arr2, 1, 'Wrong size or kind of output array')
        endunless
    else
        newbytearray(boundslist(arr1)) -> arr2
    endif;

    exacc EXT_floatarray2byte(min1.tofloat, max1.tofloat,
        arrayvector(arr1), min2.round, max2.round, arrayvector(arr2),
        datalength(arr2))
enddefine;

define float_arraydiff(arr1, arr2, arr3) -> arr3;
    float_arrcheck2(arr1, arr2);
    float_getoutput1(arr1, arr3) -> arr3;

    exacc EXT_float_arraydiff(arrayvector(arr1), arrayvector(arr2),
        arrayvector(arr3), datalength(arr3));
enddefine;

define float_arraysum(arr1, arr2, arr3) -> arr3;
    float_arrcheck2(arr1, arr2);
    float_getoutput1(arr1, arr3) -> arr3;

    exacc EXT_float_arraysum(arrayvector(arr1), arrayvector(arr2),
        arrayvector(arr3), datalength(arr3));
enddefine;

define float_arraymult(arr1, arr2, arr3) -> arr3;
    float_arrcheck2(arr1, arr2);
    float_getoutput1(arr1, arr3) -> arr3;

    exacc EXT_float_arraymult(arrayvector(arr1), arrayvector(arr2),
        arrayvector(arr3), datalength(arr3));
enddefine;

define float_complexmult(arr1r, arr1i, arr2r, arr2i, arr3r, arr3i)
        -> (arr3r, arr3i);
    float_arrcheckn(arr1r, arr1i, arr2r, arr2i, 4);
    float_getoutput1(arr1r, arr3r) -> arr3r;
    float_getoutput1(arr1i, arr3i) -> arr3i;

    exacc EXT_float_complexmult(
        arrayvector(arr1r), arrayvector(arr1i),
        arrayvector(arr2r), arrayvector(arr2i),
        arrayvector(arr3r), arrayvector(arr3i),
        datalength(arr3r));
enddefine;

define float_arraydiv(arr1, arr2, arr3) -> arr3;
    float_arrcheck2(arr1, arr2);
    float_getoutput1(arr1, arr3) -> arr3;

    exacc EXT_float_arraydiv(arrayvector(arr1), arrayvector(arr2),
        arrayvector(arr3), datalength(arr3));
enddefine;

define float_arraycomb(k1, arr1, k2, arr2, arr3) -> arr3;
    float_arrcheck2(arr1, arr2);
    float_getoutput1(arr1, arr3) -> arr3;

    exacc EXT_float_arraycomb(k1.tofloat, arr1.arrayvector,
        k2.tofloat, arr2.arrayvector, arr3.arrayvector, arr3.datalength);
enddefine;

define float_arrayhypot(arr1, arr2, arr3) -> arr3;
    float_arrcheck2(arr1, arr2);
    float_getoutput1(arr1, arr3) -> arr3;

    exacc EXT_float_arrayhypot(arrayvector(arr1), arrayvector(arr2),
        arrayvector(arr3), datalength(arr3));
enddefine;

define float_arrayatan2(arr1, arr2, arr3) -> arr3;
    float_arrcheck2(arr1, arr2);
    float_getoutput1(arr1, arr3) -> arr3;

    exacc EXT_float_arrayatan2(arrayvector(arr1), arrayvector(arr2),
        arrayvector(arr3), datalength(arr3));
enddefine;

define float_threshold(v1, thresh, v2, arr1, arr2) -> arr2;
    ;;; Fills arr2 with v2 for all positions greater than or equal to
    ;;; thresh, and v1 otherwise. If v1 or v2 is false, the original
    ;;; data is left.
    lvars usedata = 0;
    float_getoutput1(arr1, arr2) -> arr2;

    unless v1 then -1 -> usedata; 0.0s0 -> v1
    elseunless v2 then 1 -> usedata; 0.0s0 -> v2
    endunless;
    exacc EXT_float_arraythreshold(v1.tofloat, thresh.tofloat, v2.tofloat,
        usedata, arr1.arrayvector, arr2.arrayvector, arr2.datalength)
enddefine;

define float_threshold2(v1, thresh1, v2, thresh2, v3, arr1, arr2) -> arr2;
    ;;; Fills arr2 with v1 where value of arr1 is less then or equal
    ;;; to thresh1, v2 where it is between thresh1 and thresh2, and
    ;;; v3 otherwise. Uses original data where v1, v2 or v3 are false.
    float_getoutput1(arr1, arr2) -> arr2;

    lvars usedata = 0;
    unless v1 then
        usedata || 1 -> usedata;
        0.0 -> v1
    endunless;
    unless v2 then
        usedata || 2 -> usedata;
        0.0 -> v2
    endunless;
    unless v3 then
        usedata || 4 -> usedata;
        0.0 -> v3
    endunless;

    exacc EXT_float_arraythreshold2(v1.tofloat, thresh1.tofloat, v2.tofloat,
        thresh2.tofloat, v3.tofloat, usedata,
        arr1.arrayvector, arr2.arrayvector, arr2.datalength)
enddefine;

define float_arrayabs(arr1, arr2) -> arr2;
    float_getoutput1(arr1, arr2) -> arr2;

    exacc EXT_float_arrayabs(arr1.arrayvector, arr2.arrayvector,
        arr2.datalength)
enddefine;

define float_arraysqr(arr1, arr2) -> arr2;
    float_getoutput1(arr1, arr2) -> arr2;

    exacc EXT_float_arraysqr(arr1.arrayvector, arr2.arrayvector,
        arr2.datalength)
enddefine;

define float_arraysqrt(arr1, arr2) -> arr2;
    float_getoutput1(arr1, arr2) -> arr2;

    exacc EXT_float_arraysqrt(arr1.arrayvector, arr2.arrayvector,
        arr2.datalength)
enddefine;

define float_arraylogistic(arr1, arr2) -> arr2;
    float_getoutput1(arr1, arr2) -> arr2;

    exacc EXT_float_arraylogistic(arr1.arrayvector, arr2.arrayvector,
        arr2.datalength)
enddefine;

define float_arraymean(arr) /* -> mean */;
    float_arrcheck1(arr);

    exacc EXT_float_arraymean(arr.arrayvector, arr.datalength);
enddefine;

define float_arraymean_mask(arr, mask, wherezero) /* -> mean */;
    ;;; Only uses points where mask is zero
    ;;; if wherezero is true, otherwise uses all other points
    float_arrcheck2(arr, mask);

    exacc EXT_float_arraymean_mask(wherezero.b2i,
        arr.arrayvector, mask.arrayvector, arr.datalength)
enddefine;

define float_arrayhist(arr, mn, mx, hist) -> hist;
    lvars nbins, histv;
    float_arrcheck1(arr);

    if hist.isinteger then
        hist -> nbins;
        initintvec(nbins) ->> histv -> hist
    else
        if hist.isarray then
            unless hist.isontoarray then
                mishap(hist, 1, 'Does not fill arrayvector')
            endunless;
            arrayvector(hist) -> histv
        else
            hist -> histv
        endif;
        unless histv.isintvec then
            mishap(histv, 1, 'Need intvec')
        endunless;
        length(histv) -> nbins;
        set_subvector(0, 1, histv, nbins);
    endif;

    exacc EXT_float_arrayhist(arr.arrayvector, arr.datalength,
        mn.tofloat, mx.tofloat, histv, nbins)
enddefine;

define float_setconst(c, arr);
    float_arrcheck1(arr);

    exacc EXT_float_arraysetc(c.tofloat, arr.arrayvector, arr.datalength);
enddefine;

define float_multconst(c, arr1, arr2) -> arr2;
    float_getoutput1(arr1,arr2) -> arr2;

    exacc EXT_float_arraymultc(c.tofloat, arr1.arrayvector,
        arr2.arrayvector, arr2.datalength);
enddefine;

define float_addconst(c, arr1, arr2) -> arr2;
    float_getoutput1(arr1,arr2) -> arr2;

    exacc EXT_float_arrayaddc(c.tofloat, arr1.arrayvector,
        arr2.arrayvector, arr2.datalength);
enddefine;

define float_multconst_mask(c, arr1, mask, wherezero, arr2) -> arr2;
    ;;; Multiplies by c elements of arr1 identified by mask and wherezero.
    float_arrcheck2(arr1, mask);
    float_getoutput1(arr1, arr2) -> arr2;

    exacc EXT_float_arraymultc_mask(c.tofloat, wherezero.b2i,
        arr1.arrayvector, mask.arrayvector, arr2.arrayvector,
        arr2.datalength)
enddefine;

define float_addconst_mask(c, arr1, mask, wherezero, arr2) -> arr2;
    ;;; Adds c to elements of arr1 identified by mask and wherezero.
    float_arrcheck2(arr1, mask);
    float_getoutput1(arr1, arr2) -> arr2;

    exacc EXT_float_arrayaddc_mask(c.tofloat, wherezero.b2i,
        arr1.arrayvector, mask.arrayvector, arr2.arrayvector,
        arr2.datalength)
enddefine;

define float_mean_sd(arr) /* -> (mean, sd) */;
    ;;; Return mean and sd
    lconstant
        meanv = arrayvector(newsfloatarray([0 0])),
        sdv = arrayvector(newsfloatarray([0 0]));
    float_arrcheck1(arr);

    exacc EXT_float_arraymeansd(arr.arrayvector,
        arr.datalength, meanv, sdv);
    meanv(1), sdv(1) /* -> (mean, sd) */
enddefine;

define float_mean_sd_mask(arr, mask, wherezero) /* -> (mean, sd) */;
    ;;; Return mean and sd
    lconstant
        meanv = arrayvector(newsfloatarray([0 0])),
        sdv = arrayvector(newsfloatarray([0 0]));
    float_arrcheck2(arr, mask);

    exacc EXT_float_arraymeansd_mask(wherezero.b2i, arr.arrayvector,
        mask.arrayvector, arr.datalength, meanv, sdv);
    meanv(1), sdv(1) /* -> (mean, sd) */
enddefine;

define float_arraywtdav_mask(alpha1, alpha2, arr1, arr2, mask, arr3) -> arr3;
    ;;; Averages arr1 and arr2 into arr3. Alpha1 is the weight attached
    ;;; to arr1 when mask is zero, and alpha2 is the weight when mask is
    ;;; non-zero.
    ;;; Rounds the results, and clips to 0 to 255
    float_arrcheck2(arr1, arr2);
    float_arrcheck2(arr1, mask);
    float_getoutput1(arr1, arr3) -> arr3;

    exacc EXT_float_arraywtdav_mask(alpha1.tofloat, alpha2.tofloat,
        arr1.arrayvector, arr2.arrayvector, mask.arrayvector,
        arr3.arrayvector, arr3.datalength)
enddefine;

/* Checking that arrays are different */

define float_getoutput2(arr1, arr2, canbesame) -> arr2;
    if arr2.isarray and not(canbesame)
    and arrayvector(arr2) == arrayvector(arr1) then
        mishap(arr1, 1, 'Need distinct arrays')
    endif;
    float_getoutput1(arr1, arr2) -> arr2
enddefine;

define lconstant macro getbounds arr;
    "lvars", "(", "x0", ",", "x1", ",", "y0", ",", "y1", ")", "=",
    "explode", "(", "boundslist", "(", arr, ")", ")"
enddefine;

/* Operations that work in 2-D */

define float_dilate_nonzero(val, arr1, arr2) -> arr2;
    ;;; Dilation with 3x3 structuring element
    ;;; Leaves a 1-pixel border of the output array untouched.
    getbounds arr1;
    float_getoutput2(arr1, arr2, false) -> arr2;

    exacc EXT_float_arraydilate(val.tofloat, arr1.arrayvector,
        arr2.arrayvector, x1-x0+1, y1-y0+1);
enddefine;

define float_erode_nonzero(val, arr1, arr2) -> arr2;
    ;;; Dilation with 3x3 structuring element
    ;;; Leaves a 1-pixel border of the output array untouched.
    getbounds arr1;
    float_getoutput2(arr1, arr2, false) -> arr2;

    exacc EXT_float_arrayerode(val.tofloat, arr1.arrayvector,
        arr2.arrayvector, x1-x0+1, y1-y0+1);
enddefine;

global vars float_arrayprocs = true;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 29 2006
		Removed '-lm' from exload commands
--- David Young, Oct  8 2003
        Added -float_arraysqrt-
--- David Young, Oct  7 2003
        float_getoutput1 and float_getoutput2 now call oldsfloatarray with
        the argument as a tag
--- David Young, Oct  5 2001
        Removed redundant lvars declarations of arguments and results
        and added float_complexmult.
--- David Young, Feb 24 2000
        float_arraylogistic added
--- David S Young, Nov 16 1994
        changed newsarray to newbytearray
--- David S Young, Apr  8 1994
        -float_arraymult- and -float_arraydiv- added
--- David S Young, Nov 29 1993
        -float_threshold2- allows data to be retained
--- David S Young, Jul 22 1993
        Added -float_multconst_mask- and -float_arrayhist-.
--- David S Young, Jul 14 1993
        Array arguments now checked for identical boundslists and not just
        same numbers of elements.
        Various undocumented procedures made lconstant.
--- David S Young, Jul 13 1993
        Changed -newfloatarray- to -newsfloatarray- and -isfloatarray- to
        -issfloatarray- to avoid name clash with *VEC_MAT package.
--- David S Young, Jan 30 1993
        Added -float_arraysqr- and -float_setconst-
 */
