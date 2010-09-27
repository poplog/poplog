/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 > File:            $popvision/lib/arraylookup.p
 > Purpose:         Apply lookup tables to array data
 > Author:          David S Young, Jan 20 1994 (see revisions)
 > Documentation:   HELP * ARRAYLOOKUP
 > Related Files:   LIB * ARRAYLOOKUP.C
 */

/*
         CONTENTS - (Use <ENTER> g to access required sections)

 -- Constants and simple utilities
 -- External procedures
 -- Caller for external procedures
 -- Procedure lut - any array
 -- All cases - byte arrays
 -- Vector lut - general arrays
 -- Linear quantisation lut - general arrays
 -- Linear quantisation lut - float arrays
 -- Linear quantisation lut - float to byte arrays
 -- Threshold lut - general arrays
 -- Threshold lut - float arrays
 -- Threshold lut - float to byte arrays
 -- Quantisation lut - general arrays
 -- Quantisation lut - float arrays
 -- Quantisation lut - float to byte arrays
 -- Top-level procedure

*/

compile_mode:pop11 +strict;

section;

global constant procedure arraylookup;

/*
-- Constants and simple utilities -------------------------------------
*/

uses popvision
uses objectfile
uses boundslist_utils
uses newsfloatarray
uses newbytearray
uses ext2d_args

;;; Controls the length of best-guess lookup tables for float
;;; quantisation.  Guess tables are tabsizerat times the number of
;;; quantisation bins.
lconstant tabsizerat = 2;

lconstant
    procedure tofloat = number_coerce(% 0.0s0 %),
    (, bits_per_byte) = field_spec_info("byte"),
    bytesize = 2 ** bits_per_byte,
    bytetable = inits(bytesize);        ;;; for byte lookup

define lconstant issfloatvec(/* v */) /* -> result */ with_nargs 1;
    .datakey.class_spec == "decimal"
enddefine;

define lconstant issfloatarr(/* arr */) /* -> result */ with_nargs 1;
    .arrayvector.issfloatvec
enddefine;

define lconstant isbytevec(/* v */) /* -> result */ with_nargs 1;
    .datakey.class_spec == 8
enddefine;

define lconstant isbytearr(/* arr */) /* -> result */ with_nargs 1;
    .arrayvector.isbytevec
enddefine;

define lconstant tofloatvec(v) -> v;
    lvars v;
    unless v.issfloatvec then
        conssfloatvec(explode(v), length(v)) -> v
    endunless
enddefine;

define lconstant tobytevec(v) -> v;
    lvars v;
    unless v.isbytevec then
        consbytevec(explode(v), length(v)) -> v
    endunless
enddefine;

/*
-- External procedures ------------------------------------------------
*/

lconstant macro extname = 'arraylookup',
    obfile = objectfile(extname);

unless obfile then
    mishap(extname, 1, 'Object file not found')
endunless;

exload extname [^obfile] lconstant
                    blookup_EXT(9)              <- blookup,

                    ftlookupa_EXT(11)           <- ftlookupa,
                    ftlookupb_EXT(10)           <- ftlookupb,
                    ftlookupc_EXT(10)           <- ftlookupc,
                    fbtlookup_EXT(11)           <- fbtlookup,

                    fllookup_EXT(12)            <- fllookup,
                    fllookupu_EXT(13)           <- fllookupu,
                    fbllookup_EXT(12)           <- fbllookup,

                    fqlookup_EXT(15)            <- fqlookup,
                    fqlookupu_EXT(16)           <- fqlookupu,
                    fbqlookup_EXT(15)           <- fbqlookup
endexload;

/*
-- Caller for external procedures -------------------------------------
*/

define lconstant map_2d_ext(arrin, arrout, region, proc);
    lvars arrin, arrout, region, procedure proc;

    ;;; Calls proc with first 8 arguments for the external
    ;;; procedure on the stack.

    lvars extargs, argvec;
    ext2d_args([% arrin, arrout %], region) -> extargs;
    if extargs.isvector then
        proc(explode(extargs))
    else
        for argvec from_repeater extargs do
            proc(explode(argvec))
        endfor
    endif
enddefine;

/*
-- Procedure lut - any array ------------------------------------------
*/

define lconstant plookup(arrin, region, lut, arrout);
    ;;; Simple case where lut is applicable (property, array, procedure etc.)
    ;;; and need to do it in POP-11
    lvars arrin, region, procedure lut, arrout;
    lvars ain, aout;

    for ain, aout
        in_array arrin, arrout updating_last
        in_region region
    do
        lut(ain) -> aout
    endfor
enddefine;

/*
-- All cases - byte arrays --------------------------------------------
*/

define lconstant blookup(arrin, region, lut, arrout);
;;; Handle byte arrays by converting any lut to a vector lut
    lvars arrin, region, lut, arrout;

    unless lut.isbytevec and length(lut) == 256 then
        ;;; Convert to byte vector table.
        ;;; lut_source not a byte vector to avoid recursion into this proc;
        ;;; lconstant OK as never updated.
        lconstant lut_source = newarray([0 255], identfn);
        ;;; Tempting to make lut_vals lconstant, but lut
        ;;; could in principal invoke a recursive call.
        lvars lut_vals = newbytearray([0 255]);
        arrayvector(
            arraylookup(lut_source, false, lut, lut_vals)) -> lut
    endunless;

    map_2d_ext(arrin, arrout, region,
        procedure(/* arri etc. */);
            exacc blookup_EXT(/* arri etc., */ lut)
        endprocedure)
enddefine;

/*
-- Vector lut - general arrays ----------------------------------------
*/

define lconstant vlookup(arrin, region, v, arrout);
    ;;; Increment by 1 in order to treat vectors as if zero-based.
    lvars arrin, region, v, arrout;
    lvars f = nonop +(% 1 %) <> class_subscr(datakey(v))(% v %);
    plookup(arrin, region, f, arrout)
enddefine;


/*
-- Linear quantisation lut - general arrays ---------------------------
*/

define lconstant llookup1(v, fvals, Nvals, k, t1) -> result;
    ;;; Linearly quantises v, and returns the appropriate table entry.
    ;;; Results out of range take the top or bottom entries.
    ;;; Nvals should be the length of fvals.
    lvars v, procedure fvals, Nvals, k, t1, result;
    ;;; Must add 2 before taking int to avoid rounding problems
    lvars i = intof(k * (v - t1) + 2);
    ;;; Seems like fi_ procedures should be OK - but they are not
    ;;; really safe as values way outside the range of the
    ;;; table are allowed.
    ;;; Rounding errors are not trapped - this would need more tests
    ;;; on v.
    if i > Nvals then
        Nvals -> i
    elseif i < 1 then
        1 -> i
    endif;
    ;;; Allow "undef" in table - means retain original value
    if (fvals(i) ->> result) == undef then
        v -> result
    endif
enddefine;

define lconstant llookup(arrin, region, lut, arrout);
    lvars arrin, region, lut, arrout;
    lvars
        (t1, tn, fvals) = explode(lut),
        Nvals = length(fvals),
        k = (Nvals - 2) / (tn - t1),
        f = class_fast_subscr(datakey(fvals))(% fvals %);
    plookup(arrin, region, llookup1(% f, Nvals, k, t1 %), arrout)
enddefine;

/*
-- Linear quantisation lut - float arrays -----------------------------
*/

define lconstant fval_table(fvals) -> (fvals, undefs);
    ;;; Replaces undefs in fvals, returning a table of their positions
    ;;; if there are any, and ensuring that fvals is a float vector.
    lvars fvals, undefs = false;
    unless fvals.issfloatvec then
        lvars i, v,
            l = length(fvals),
            newfvals = initsfloatvec(l);
        fast_for i from 1 to l do
            if (fvals(i) ->> v) == undef then
                0.0 -> newfvals(i);
                unless undefs then
                    initintvec(l) -> undefs
                endunless;
                1 -> undefs(i)
            else
                v -> newfvals(i)
            endif
        endfor;
        newfvals -> fvals
    endunless
enddefine;

define lconstant fllookup(arrin, region, lut, arrout);
    lvars arrin, region, lut, arrout;
    lvars undefs,
        (t1, tn, fvals) = explode(lut),
        Maxv = length(fvals) - 1,
        k = (Maxv - 1) / (tn - t1);
    fval_table(fvals) -> (fvals, undefs);
    map_2d_ext(arrin, arrout, region,
        if undefs then
            procedure(/* arri etc. */);
                exacc fllookupu_EXT(/* arri etc., */
                    fvals, undefs, Maxv, k.tofloat, t1.tofloat)
            endprocedure
        else
            procedure(/* arri etc. */);
                exacc fllookup_EXT(/* arri etc., */
                    fvals, Maxv, k.tofloat, t1.tofloat)
            endprocedure
        endif)
enddefine;

/*
-- Linear quantisation lut - float to byte arrays ---------------------
*/

define lconstant fbllookup(arrin, region, lut, arrout);
    lvars arrin, region, lut, arrout;
    lvars
        (t1, tn, bvals) = explode(lut),
        Maxv = length(bvals) - 1,
        k = (Maxv - 1) / (tn - t1);
    tobytevec(bvals) -> bvals;
    map_2d_ext(arrin, arrout, region,
        procedure(/* arri etc. */);
            exacc fbllookup_EXT(/* arri etc., */
                bvals, Maxv, k.tofloat, t1.tofloat)
        endprocedure)
enddefine;

/*
-- Threshold lut - general arrays -------------------------------------
*/

define lconstant tlookup1a(v, t, f1, f2) /* -> result */;
    lvars v, t, f1, f2;
    if v < t then f1 else f2 endif
enddefine;

define lconstant tlookup1b(v, t, f1) /* -> result */;
    lvars v, t, f1, f2;
    if v < t then f1 else v endif
enddefine;

define lconstant tlookup1c(v, t, f2) /* -> result */;
    lvars v, t, f1, f2;
    if v < t then v else f2 endif
enddefine;

define lconstant tlookup(arrin, region, lut, arrout);
    lvars arrin, region, lut, arrout;
    lvars
        (thresh, fvals) = explode(lut),
        (f1, f2) = explode(fvals),
        t = thresh(1);
    if f1 == undef then
        plookup(arrin, region, tlookup1c(% t, f2 %), arrout)
    elseif f2 == undef then
        plookup(arrin, region, tlookup1b(% t, f1 %), arrout)
    else
        plookup(arrin, region, tlookup1a(% t, f1, f2 %), arrout)
    endif
enddefine;

/*
-- Threshold lut - float arrays ---------------------------------------
*/

define lconstant ftlookup(arrin, region, lut, arrout);
    lvars arrin, region, lut, arrout;
    lvars p,
        (thresh, fvals) = explode(lut),
        (f1, f2) = explode(fvals),
        t = tofloat(thresh(1));
    if f1 == undef then
        procedure(/* arri etc. */);
            exacc ftlookupc_EXT(/* arri etc., */ t, f2.tofloat)
        endprocedure
    elseif f2 == undef then
        procedure(/* arri etc. */);
            exacc ftlookupb_EXT(/* arri etc., */ t, f1.tofloat)
        endprocedure
    else
        procedure(/* arri etc. */);
            exacc ftlookupa_EXT(/* arri etc., */ t, f1.tofloat, f2.tofloat)
        endprocedure
    endif -> p;
    map_2d_ext(arrin, arrout, region, p);
enddefine;

/*
-- Threshold lut - float to byte arrays -------------------------------
*/

define lconstant fbtlookup(arrin, region, lut, arrout);
    lvars arrin, region, lut, arrout;
    lvars
        (thresh, fvals) = explode(lut),
        (f1, f2) = explode(fvals),
        t = tofloat(thresh(1));
    round(f1) -> f1;
    checkinteger(f1, 0, bytesize-1);
    round(f2) -> f2;
    checkinteger(f2, 0, bytesize-1);
    map_2d_ext(arrin, arrout, region,
        procedure(/* arri etc. */);
            exacc fbtlookup_EXT(/* arri etc., */ t, f1, f2)
        endprocedure)
enddefine;

/*
-- Quantisation lut - general arrays ----------------------------------
*/

define lconstant qlookup0(v, thresh, Nvals, index) -> index;

    ;;; Returns     1 if v < thresh(1)
    ;;;             Nvals if v >= thresh(Nvals-1)
    ;;;             I, where thresh(I-1) <= v < thresh(I), otherwise.

    ;;; Assumes     thresh(I) < thresh(I+1) for all I
    ;;;             length of thresh is at least Nvals-1
    ;;;             1 <= index <= Nvals on entry

    ;;; The index argument should be a guess at I.

    lvars v, thresh, Nvals, index;
    if index == Nvals or v < thresh(index) then
        repeat
            index fi_- 1 -> index;
        quitif (index == 0 or v >= thresh(index)) endrepeat;
        index fi_+ 1 -> index
    else  /* v >= thresh(index) */
        repeat
            index fi_+ 1 -> index;
        quitif (index == Nvals or v < thresh(index)) endrepeat
    endif;
enddefine;

define lconstant qlookup1(v, thresh, fvals, Nvals, tabl, Ntab, k, t1)
        -> result;
    ;;; As qlookup0 except uses tabl to get a guess at the quantisation
    ;;; index, having done a linear quantisation first, and returns value
    ;;; from fvals (which should have length Nvals).
    ;;; tabl should be the guess table, of length Ntab, and k and t1 the
    ;;; appropriate constants for getting an index into it.
    lvars v, thresh, procedure fvals, Nvals, tabl, Ntab, k, t1, result;

    ;;; This code like llookup1, but is simple enough to put inline
    lvars i = intof(k * (v - t1) + 2);
    if i > Ntab then
        Ntab -> i
    elseif i < 1 then
        1 -> i
    endif;

    if (fvals(qlookup0(v, thresh, Nvals, tabl(i))) ->> result) == undef then
        v -> result
    endif;
enddefine;

define lconstant guesstable(thresh, Nvals, Ntab, ext) -> (tabl, k, t1);
    ;;; Makes a table of guesses for qlookup0, based on linear
    ;;; quantisation of input values.
    ;;; If ext true, then table is intvec rather
    ;;; than full vec, for passing to external routine, and
    ;;; indices in it are zero-based.
    lvars thresh, Nvals, Ntab, ext, tabl, k, t1;
    if ext then
        initintvec(Ntab)
    else
        initv(Ntab)
    endif -> tabl;

    thresh(1) -> t1;
    (Ntab - 2) / (thresh(Nvals-1) - t1) -> k;

    ;;; Find value at mid-point of table entry, and look this up to
    ;;; get the index to go in the table.
    lvars
        kinv = 1/k,
        i, index = 1;
    fast_for i from 1 to Ntab do
        qlookup0(kinv * (i - 1.5) + t1, thresh, Nvals, index) -> index;
        if ext then index fi_- 1 else index endif -> tabl(i)
    endfor;

enddefine;


define lconstant qlookup(arrin, region, lut, arrout);
    lvars arrin, region, lut, arrout;
    lvars
        (thresh, fvals) = explode(lut),
        Nvals = length(fvals);

    ;;; Pick up thresholding as special case here
    if Nvals == 2 then
        tlookup(arrin, region, lut, arrout)

    else
        lvars
            Ntab = tabsizerat * (Nvals - 1) + 1,
            (tabl, k, t1) = guesstable(thresh, Nvals, Ntab, false),
            f = class_fast_subscr(datakey(fvals))(% fvals %);
        unless length(thresh) == Nvals - 1 then
            mishap(0, 'Lookup table lengths do not agree')
        endunless;
        plookup(arrin, region,
            qlookup1(% thresh, f, Nvals, tabl, Ntab, k, t1 %), arrout)
    endif
enddefine;

/*
-- Quantisation lut - float arrays ------------------------------------
*/

define lconstant fqlookup(arrin, region, lut, arrout);
    lvars arrin, region, lut, arrout;
    lvars
        (thresh, fvals) = explode(lut),
        Maxv = length(fvals) - 1;

    if Maxv == 1 then           ;;; can just threshold
        ftlookup(arrin, region, lut, arrout)

    else
        lvars undefs,
            Maxt = Maxv * tabsizerat,
        ;;; tables generated for external case
            (tabl, k, t1) = guesstable(thresh, Maxv+1, Maxt+1, true);
        unless length(thresh) == Maxv then
            mishap(0, 'Lookup table lengths do not agree')
        endunless;
        tofloatvec(thresh) -> thresh;
        fval_table(fvals) -> (fvals, undefs);
        map_2d_ext(arrin, arrout, region,
            if undefs then
                procedure(/* arri etc. */);
                    exacc fqlookupu_EXT(/* arri etc., */
                        thresh, fvals, undefs, Maxv,
                        tabl, Maxt, k.tofloat, t1.tofloat)
                endprocedure
            else
                procedure(/* arri etc. */);
                    exacc fqlookup_EXT(/* arri etc., */
                        thresh, fvals, Maxv, tabl, Maxt, k.tofloat, t1.tofloat)
                endprocedure
            endif)
    endif
enddefine;

/*
-- Quantisation lut - float to byte arrays ----------------------------
*/

define lconstant fbqlookup(arrin, region, lut, arrout);
    lvars arrin, region, lut, arrout;
    lvars
        (thresh, fvals) = explode(lut),
        Maxv = length(fvals) - 1;

    if Maxv == 1 then
        fbtlookup(arrin, region, lut, arrout)

    else
        lvars
            Maxt = Maxv * tabsizerat,
        ;;; tables generated for external case
            (tabl, k, t1) = guesstable(thresh, Maxv+1, Maxt+1, true);
        unless length(thresh) == Maxv then
            mishap(0, 'Lookup table lengths do not agree')
        endunless;
        tofloatvec(thresh) -> thresh;
        tobytevec(fvals) -> fvals;
        map_2d_ext(arrin, arrout, region,
            procedure(/* arri etc. */);
                exacc fbqlookup_EXT(/* arri etc., */
                    thresh, fvals, Maxv, tabl, Maxt, k.tofloat, t1.tofloat)
            endprocedure)
    endif
enddefine;

/*
-- Top-level procedure ------------------------------------------------
*/

define arraylookup(arrin, region, lut, arrout) -> arrout;
    lvars arrin, region, lut, arrout;

    ;;; Allow arguments to default and check region legality
    lvars ndims = pdnargs(arrin);
    unless region then
        boundslist(arrin) -> region
    else
        unless length(region) == 2 * ndims then
            mishap(arrin, region, 2,
                'Different no. of dimensions in array and region')
        endunless;
        region_inclusion_check(arrin, region)
    endunless;
    unless arrout then
        newanyarray(region, datakey(arrayvector(arrin))) -> arrout
    else
        unless pdnargs(arrout) == ndims then
            mishap(arrin, arrout, 2,
                'Different no. of dimensions in input and output')
        endunless;
        region_inclusion_check(arrout, region)
    endunless;
    if arrayvector(arrin) == arrayvector(arrout) then
        ;;; if same arrayvector then must map onto same bit of array
        lvars
            ( , vi) = arrayvector_bounds(arrin),
            ( , vo) = arrayvector_bounds(arrout);
        unless vi == vo and boundslist(arrin) = boundslist(arrout) then
            mishap(arrin, arrout, 2,
                'Arrays share arrayvector but regions differ')
        endunless
    endif;

    lvars
        in_byte = arrin.isbytearr,
        out_byte = arrout.isbytearr,
        in_float = arrin.issfloatarr,
        out_float = arrout.issfloatarr;

    if in_byte and out_byte then
        ;;; Trap all byte-to-byte cases and convert to vector lookup
        blookup(arrin, region, lut, arrout)

    elseif lut.isprocedure then
        ;;; Just apply procedure, array or prop
        plookup(arrin, region, lut, arrout)

    elseif lut.isvectorclass then
        ;;; General vector lookup
        vlookup(arrin, region, lut, arrout)

    elseif not(lut.ispair and lut.back.atom) and length(lut) == 3 then
        ;;; Linear quantisation case
        if in_float and out_float then
            fllookup(arrin, region, lut, arrout)
        elseif in_float and out_byte then
            fbllookup(arrin, region, lut, arrout)
        else
            ;;; General case
            llookup(arrin, region, lut, arrout)
        endif

    elseif (lut.ispair and lut.back.atom) or length(lut) == 2 then
        ;;; Table quantisation case (including thresholding)
        if in_float and out_float then
            fqlookup(arrin, region, lut, arrout)
        elseif in_float and out_byte then
            fbqlookup(arrin, region, lut, arrout)
        else
            ;;; General case
            qlookup(arrin, region, lut, arrout)
        endif

    else
        mishap(0, 'Unrecognised form of lookup table')
    endif

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Nov 15 1994
        sfloat replaced by sfloatvec to fit with new newsfloatarray.
        consstring replaced by consbytevec.
--- David S Young, Jan 31 1994
        Simplified and generalised byte-to-byte case with recursive call to
        get vector lookup table.
--- David S Young, Jan 25 1994
        Uses in_array and ext2d_args.
 */
