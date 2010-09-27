/* --- Copyright University of Sussex 2003. All rights reserved. ----------
 > File:            $popvision/lib/lapop.p
 > Purpose:         Linear algebra
 > Author:          David Young, Sep 22 2003 (see revisions)
 > Documentation:   HELP * LAPOP
 > Related Files:   LIB * LAPACK
 */


compile_mode:pop11 +strict;

uses popvision, lapack;

section;

/*
-- Utilities ----------------------------------------------------------
*/

;;; Real-complex flag.
lvars lapop_complex = false;

;;; Macros

;;; unique tags for recycleable arrays
lconstant macro ltag = [ #_< consref(0) >_# ];

define lconstant macro GETREGIONS;
    ;;; Sorts out arguments using the convention that arrays may
    ;;; optionally be followed by a boundslist-type region spec.
    ;;; Expects
    ;;; - a list of the formal arguments to the routine
    ;;; - a list of those that are arrays
    ;;; without separators.
    ;;; Declares <arg>reg variables for each array argument, and assigns
    ;;; the argument (if supplied) or the empty list to each one.
    lvars
        args = listread(),
        arrays = listread(),
        a, pargs;

    ;;; lvars areg = [], breg = [], creg = [];
    "lvars";
    for a in arrays do
        a <> "reg", "=", "nil", ","
    endfor; ";" ;

    ;;; if c.islist then (a, b, c) -> (a, b, c, creg) endif;
    ;;; if b.islist then (a, b) -> (a, b, breg) endif;       etc.
    for pargs on rev(args) do
        lvars carg = hd(pargs);
        if lmember(carg, arrays) then
            "if", carg, ".", "islist", "then", "(";
            for a in rev(pargs) do a, "," endfor;
            ")", "->", "(";
            for a in rev(pargs) do a, "," endfor;
            carg <> "reg", ")", "endif", ";";
        endif
    endfor
enddefine;

define :inline lconstant REG(arr, reg);
    ;;; Macro to get region list
    ((reg) /== [] and (reg) or boundslist(arr))
enddefine;

;;; Array utilities

define lconstant arr_type(arr) /* -> typeword */;
    ;;; Returns type of arrays that can be passed to lapack, or false.
    lconstant
        (sfloat_spec, _) = field_spec_info("sfloat"),
        (dfloat_spec, _) = field_spec_info("dfloat");
    lvars
        arrvec = arr.arrayvector,
        arr_name = arrvec.dataword;
    if arr_name == "cfloatvec" then
        "cfloat"
    elseif arr_name == "zfloatvec" then
        "zfloat"
    else
        lvars arr_spec = arrvec.datakey.class_spec;
        if arr_spec == sfloat_spec then
            "sfloat"
        elseif arr_spec == dfloat_spec then
            "dfloat"
        else
            false
        endif
    endif
enddefine;

define lconstant iscomplexarray(arr) /* -> boolean */;
    lvars arr_name = arr.arrayvector.dataword;
    arr_name == "cfloatvec" and "cfloat" or arr_name == "zfloatvec" and "zfloat"
enddefine;

define lconstant isfullarray(arr) /* -> boolean */;
    arr.arrayvector.datakey.class_spec == "full"
enddefine;

define lconstant hascomplexdata(arr, reg) -> result;
    ;;; Only needed for arrays whose data are not to be passed
    ;;; to Lapack - normally best to trap case of complex data in
    ;;; full array vector by catching exception when trying
    ;;; to assign to a packed array type.
    if iscomplexarray(arr) then
        true -> result
    elseif isfullarray(arr) then
        false -> result;
        lvars v;
        for v in_array arr in_region REG(arr, reg) do
            if v.iscomplex then
                true -> result;
                quitloop;
            endif
        endfor
    else
        false -> result
    endif
enddefine;

define lconstant array_dims(arr, reg) -> (nrows, ncols);
    ;;; Returns array dimensions. Checks that arr is 1-D or 2-D but no
    ;;; other checking.
    lvars adim = pdnargs(arr);
    if adim == 1 then           ;;; return as if column vector
        lvars (ax0, ax1) = explode(REG(arr, reg));
        ax1 fi_- ax0 fi_+ 1 -> nrows;
        1 -> ncols;
    elseif adim == 2 then
        lvars (ax0, ax1, ay0, ay1) = explode(REG(arr, reg));
        ax1 fi_- ax0 fi_+ 1 -> nrows;
        ay1 fi_- ay0 fi_+ 1 -> ncols;
    else
        mishap(arr, 1, 'lapop: Expecting 1-D or 2-D array')
    endif;
enddefine;

define lconstant row_dims(arr, reg) -> rows;
    ;;; Returns the row dimensions of an array/region.
    if listlength(REG(arr, reg) ->> rows) fi_> 2 then
        allbutlast(2, rows) -> rows
    endif
enddefine;

define lconstant col_dims(arr, reg) -> cols;
    ;;; Returns the col dimensions of an array/region.
    ;;; Gives [1 1] if a 1-D region.
    if (fast_back(fast_back(REG(arr, reg))) ->> cols) == [] then
        #_< [1 1] >_# -> cols
    endif
enddefine;

;;; Array/region copying support

define lconstant array_vec(arr, reg)
        -> (arrvec, index, dim1, nrows, ncols);

    ;;; Given a 1-D or 2-D  array and a region spec, returns the array
    ;;; vector, the index in it of the start of the region, the size of
    ;;; the first dimension of the array, the number of rows and columns
    ;;; in the region.
    ;;; Checks array is "by row" (in Poplog terminology - really by column).
    ;;; Checks regions are right length and inside arrays.

    arrayvector(arr) -> arrvec;
    arrayvector_bounds(arr) -> (_, index);

    lvars b = boundslist(arr), adim = pdnargs(arr);

    if adim == 1 then           ;;; return as if column vector
        lvars (ax0, ax1) = explode(b);

        if reg == [] or reg = b then
            ax1 fi_- ax0 fi_+ 1 ->> dim1 -> nrows;
        else
            lvars (rx0, rx1, len) = #| explode(reg) |#;

            unless len == 2 then
                mishap(reg, 1, 'Expecting list of length 2 for region')
            endunless;
            fi_check(rx0, ax0, ax1) -> ;    ;;; check region
            fi_check(rx1, rx0, ax1) -> ;    ;;; as need to check if integers

            ax1 fi_- ax0 fi_+ 1 -> dim1;    ;;; not usu. needed, retained for consistency
            (rx0 fi_- ax0) fi_+ index -> index;
            rx1 fi_- rx0 fi_+ 1 -> nrows;
        endif;
        1 -> ncols;

    elseif adim == 2 then
        unless arr.isarray_by_row then
            mishap(arr, 1, 'lapop: Need array arranged "by row"')
        endunless;
        lvars (ax0, ax1, ay0, ay1) = explode(b);

        if reg == [] or reg = b then
            ax1 fi_- ax0 fi_+ 1 ->> dim1 -> nrows;
            ay1 fi_- ay0 fi_+ 1 -> ncols;
        else
            lvars (rx0, rx1, ry0, ry1, len) = #| explode(reg) |#;

            unless len == 4 then
                mishap(reg, 1, 'lapop: Expecting list of length 4 for region')
            endunless;
            fi_check(rx0, ax0, ax1) -> ;        ;;; check region
            fi_check(rx1, rx0, ax1) -> ;
            fi_check(ry0, ay0, ay1) -> ;
            fi_check(ry1, ry0, ay1) -> ;

            ax1 fi_- ax0 fi_+ 1 -> dim1;
            (ry0 fi_- ay0) fi_* dim1 fi_+ (rx0 fi_- ax0) fi_+ index -> index;
            rx1 fi_- rx0 fi_+ 1 -> nrows;
            ry1 fi_- ry0 fi_+ 1 -> ncols;
        endif;
    else
        mishap(arr, 1, 'lapop: Expecting 1-D or 2-D array')
    endif;
enddefine;

define lconstant copy_region_r(arr1, reg1, arr2, reg2) /* -> result */;
    ;;; Copies from one region to another, point by point, when both
    ;;; arrays are expected to be real.
    ;;; Uses move_subvector, which behaves efficiently if the
    ;;; arrays are the same type.
    ;;; Requires regions to be compatible, but does not need arrays
    ;;; to have same types or numbers of dimensions.
    ;;; Returns true if successful, false if a complex number encountered
    ;;; and arr2 is a real sfloat or dfloat type, and mishaps if any
    ;;; other unassignable value is found.

    define dlocal pop_exception_handler(N, mess, idstring, severity)
            /* -> bool */;
        if (idstring = 'field-realtosf:type-real'
            or idstring = 'field-realtodf:type-real')
        and iscomplex(dup()) then
            erasenum(N);        ;;; remove arguments
            false;       ;;; return false to caller of copy_region_r
            exitfrom(copy_region_r)
        else
            false       ;;; return false to sys_raise_exception
        endif
    enddefine;

    lvars
        (v1, i1, d1, r1, c1) = array_vec(arr1, reg1),
        (v2, i2, d2, r2, c2) = array_vec(arr2, reg2);
    unless r1 == r2 and c1 == c2 then
        mishap(arr1, reg1, arr2, reg2, 4, 'lapop: Incompatible region sizes')
    endunless;

    if c1 == 1 or (r1 == d1 and r2 == d2) then
        move_subvector(i1, v1, i2, v2, c1 fi_* r1);
    else
        repeat c1 times
            move_subvector(i1, v1, i2, v2, r1);
            i1 fi_+ d1 -> i1;
            i2 fi_+ d2 -> i2;
        endrepeat
    endif;

    true /* -> result */
enddefine;

define lconstant copy_region_c(arr1, reg1, arr2, reg2);
    ;;; Copies from one region to another, point by point,
    ;;; when both arrays are complex, assuming that they are
    ;;; set up as in newcfloatarray or newzfloatarray, with
    ;;; a real arrayvector masquerading as complex. Otherwise like
    ;;; copy_region_r.

    lvars
        (v1, i1, d1, r1, c1) = array_vec(arr1, reg1),
        (v2, i2, d2, r2, c2) = array_vec(arr2, reg2);
    unless r1 == r2 and c1 == c2 then
        mishap(arr1, reg1, arr2, reg2, 4, 'lapop: Incompatible region sizes')
    endunless;

    ;;; Adjustment to give indices in underlying (real) vector so that
    ;;; move_subvector can be used for efficiency.
    (i1 fi_- 1) fi_<< 1 fi_+ 1 -> i1;
    (i2 fi_- 1) fi_<< 1 fi_+ 1 -> i2;
    r1 fi_<< 1 -> r1;
    r2 fi_<< 1 -> r2;
    d1 fi_<< 1 -> d1;
    d2 fi_<< 1 -> d2;

    if c1 == 1 or (r1 == d1 and r2 == d2) then
        move_subvector(i1, v1, i2, v2, c1 fi_* r1);
    else
        repeat c1 times
            move_subvector(i1, v1, i2, v2, r1);
            i1 fi_+ d1 -> i1;
            i2 fi_+ d2 -> i2;
        endrepeat
    endif
enddefine;

define lconstant copy_region_g(arr1, reg1, arr2, reg2);
    ;;; Copies from one region to another, point by point, covering
    ;;; all legal cases. Less efficient than the _r and _c versions.
    lvars a1, a2;
    if reg1 == [] then boundslist(arr1) -> reg1 endif;
    if reg2 == [] then boundslist(arr2) -> reg2 endif;
    if reg1 = reg2 then
        for a1, a2 in_array arr1, arr2 updating_last in_region reg1 do
            a1 -> a2
        endfor
    else
        lvars adim1 = pdnargs(arr1), adim2 = pdnargs(arr2);
        if adim1 == 1 and adim2 == 1 then
            lvars (x0, x1) = explode(reg1), (y0, y1) = explode(reg2);
            unless x1 fi_- x0 == y1 fi_- y0 then
                mishap(reg1,reg2,2, 'lapop: Incompatible region sizes')
            endunless;
            lvars x, y = y0;
            fast_for x from x0 to x1 do
                arr1(x) -> arr2(y);
                y fi_+ 1 -> y;
            endfor
        elseif adim1 == 2 and adim2 == 2 then
            lvars
                (rx0, rx1, cx0, cx1) = explode(reg1),
                (ry0, ry1, cy0, cy1) = explode(reg2);
            unless rx1 fi_- rx0 == ry1 fi_- ry0 and
                cx1 fi_- cx0 == cy1 fi_- cy0 then
                mishap(reg1,reg2,2, 'lapop: Incompatible region sizes')
            endunless;
            lvars a1, i, r, c,
                roff = ry0 fi_- rx0, coff = cy0 fi_- cx0;
            for a1 with_index i in_array arr1 in_region reg1 do
                explode(i) -> (r, c);
                a1 -> arr2(r fi_+ roff, c fi_+ coff)
            endfor
        elseif adim1 == 1 and adim2 == 2 then
            lvars
                (rx0, rx1) = explode(reg1),
                (ry0, ry1, cy0, cy1) = explode(reg2);
            unless rx1 fi_- rx0 == ry1 fi_- ry0 and 0 == cy1 fi_- cy0 then
                mishap(reg1,reg2,2, 'lapop: Incompatible region sizes')
            endunless;
            lvars a2, x = rx0;
            for a2 in_array arr2 updating_last in_region reg2 do
                arr1(x) -> a2;
                x fi_+ 1 -> x
            endfor
        elseif adim1 == 2 and adim2 == 1 then
            lvars
                (rx0, rx1, cx0, cx1) = explode(reg1),
                (ry0, ry1) = explode(reg2);
            unless rx1 fi_- rx0 == ry1 fi_- ry0 and cx1 fi_- cx0 == 0 then
                mishap(reg1,reg2,2, 'lapop: Incompatible region sizes')
            endunless;
            lvars a1, y = ry0;
            for a1 in_array arr1 in_region reg1 do
                a1 -> arr2(y);
                y fi_+ 1 -> y
            endfor
        else
            mishap(arr1,arr2,2, 'lapop: Expecting 1-D or 2-D arrays')
        endif
    endif
enddefine;

;;; 3 routines used in setting up arrays for external procs - copy,
;;; check and create. First two throw a special exception if complex data
;;; are encountered when expecting real data, so that the array allocation
;;; process can restart with the complex flag set true.

;;; String for mishap when unable to assign complex value
lconstant lapop_type_complex = 'lapop:type-complex';

define lconstant copy_region(arr1, reg1, arr2, reg2);
    ;;; General copy_region. Raises an exception if an
    ;;; inconsistency problem arises.
    lvars c1 = arr1.iscomplexarray, c2 = arr2.iscomplexarray, ok = true;
    if not(c1 or c2) then
        copy_region_r(arr1, reg1, arr2, reg2) -> ok;
    elseif c1 and c2 then
        copy_region_c(arr1, reg1, arr2, reg2)
    elseif not(c1) and c2 then
        lvars t1 = arr_type(arr1);
        if (t1 == "sfloat" and c2 == "cfloat")
        or (t1 == "dfloat" and c2 == "zfloat") then
            xLPRTOC(arr1, reg1, arr2, reg2)
        else
            copy_region_g(arr1, reg1, arr2, reg2)
        endif
    elseif c1 and arr2.isfullarray then
        copy_region_g(arr1, reg1, arr2, reg2)
    else    ;;; c1 and c2.onlytakesreals
        false -> ok;
    endif;
    unless ok then
        sys_raise_exception(arr2, 1,
            'lapop: Array with complex or full vector needed',
            lapop_type_complex, `E`)
    endunless;
enddefine;

define lconstant isok_input_arr(arr) /* -> boolean */;
    ;;; Indicates whether array can be passed as-is to lapack routine.
    ;;; Does not check if "by row" as that gets done in copy_region or lapack.
    ;;; Mishaps if lapop_complex is false and a complex array is given
    ;;; so that an immediate switch to complex computation can occur.
    lconstant mmess = 'lapop: Array with complex vector found in real mode';
    lvars atp = arr.arr_type;
    if atp == "sfloat" then
        ;;; There is an optimisation bug (at least in 15.52 SunOS) that makes
        ;;; if x then not(true or b) else endif; misbehave.
        not(popdprecision) and not(lapop_complex)
    elseif atp == "dfloat" then
        popdprecision and not(lapop_complex)
    elseif atp == "cfloat" then
        if lapop_complex then
            not(popdprecision)
        else
            sys_raise_exception(arr, 1, mmess, lapop_type_complex, `E`)
        endif
    elseif atp == "zfloat" then
        if lapop_complex then
            popdprecision
        else
            sys_raise_exception(arr, 1, mmess, lapop_type_complex, `E`)
        endif
    else
        false
    endif
enddefine;

define lconstant isok_output_arr(arr) /* -> boolean */;
    ;;; Like isok_input_arr but does not mishap - just returns false
    lvars atp = arr.arr_type;
    if atp == "sfloat" then
        not(popdprecision) and not(lapop_complex) ;;; see note above
    elseif atp == "dfloat" then
        popdprecision and not(lapop_complex)
    elseif atp == "cfloat" then
        lapop_complex and not(popdprecision)
    elseif atp == "zfloat" then
        lapop_complex and popdprecision
    else
        false
    endif
enddefine;

define lconstant oldfloatarray(/* tag, reg */) /* -> arr */ with_nargs 2;
    if popdprecision then
        if lapop_complex then
            oldzfloatarray()
        else
            olddfloatarray()
        endif
    else
        if lapop_complex then
            oldcfloatarray()
        else
            oldsfloatarray()
        endif
    endif
enddefine;

define lconstant oldrfloatarray(/* tag, reg */) /* -> arr */ with_nargs 2;
    ;;; Return a real floating point array.
    if popdprecision then
        olddfloatarray()
    else
        oldsfloatarray()
    endif
enddefine;

;;; Next few procedures are for getting arrays to pass to the external
;;; procedure. This could all be wrapped in one procedure, but since
;;; the categories are known at compile-time, having separate procedures
;;; saves some run-time switching and argument passing.
;;; The categories refer to how the array is used by the Lapack routine,
;;; not how it is seen by the caller. However, io_arr and iou_arr differ
;;; in respect of whether the array provided gets updated.
;;; Only array types and whether "by row" are checked - region sizes
;;; etc. are taken to be checked elsewhere.
;;; The tag argument needs to be unique for each call - it is for
;;; making recyclable arrays that aren't passed out. The oarr argument
;;; may also be used as a tag if it is not an array.

define lconstant i_arr(tag, iarr, ireg) -> (iarrE, iregE);
    ;;; Input only
    if iarr.isok_input_arr then
        (iarr, ireg) -> (iarrE, iregE)
    else
        oldfloatarray(tag, REG(iarr, ireg)) -> iarrE;
        [] -> iregE;
        copy_region(iarr, ireg, iarrE, iregE)
    endif
enddefine;

define lconstant iw_arr(tag, iarr, ireg) -> (iarrE, iregE);
    ;;; Input array that gets altered, but does not return results
    oldfloatarray(tag, REG(iarr, ireg)) -> iarrE;
    [] -> iregE;
    copy_region(iarr, ireg, iarrE, iregE)
enddefine;

define lconstant o_arr(tag, oarr, oreg, dreg) -> (oarr, oreg, do_copy);
    ;;; Output array. dreg is default region if oreg not supplied.
    ;;; Last result is true if copy to output needed after external call.
    unless oarr.isarray then ;;; oarr can be a tag
        (oarr, false) -> (tag, oarr)
    endunless;
    if oarr then
        if oarr.isok_output_arr then
            false -> do_copy        ;;; will return supplied array
        elseif lapop_complex
        and not(oarr.iscomplexarray or oarr.isfullarray) then
            mishap(oarr, 1, 'lapop: Complex or full array needed for output')
        else
            oldfloatarray(tag, REG(oarr, oreg)) -> oarr;
            [] -> oreg;
            true -> do_copy;    ;;; supplied array needs to be filled later
        endif
    else
        oldfloatarray(tag, oreg /== [] and oreg or dreg) -> oarr;
        [] -> oreg;
        false -> do_copy            ;;; will return new array
    endif
enddefine;

define lconstant o_arr_real with_nargs 4;
    dlocal lapop_complex = false;
    o_arr()
enddefine;

define lconstant o_arr_complex with_nargs 4;
    dlocal lapop_complex = true;
    o_arr()
enddefine;

define lconstant io_arr(tag, iarr, ireg, oarr, oreg)
        -> (oarr, oreg, do_copy);
    ;;; Input and output array
    o_arr(tag, oarr, oreg, REG(iarr, ireg)) -> (oarr, oreg, do_copy);
    copy_region(iarr, ireg, oarr, oreg);
enddefine;

define lconstant iou_arr(tag, ioarr, ioreg) -> (ioarrE, ioregE, do_copy);
    ;;; Updateable input and output array
    if ioarr.isok_input_arr then
        (ioarr, ioreg) -> (ioarrE, ioregE);
        false -> do_copy        ;;; will return supplied array
    elseif lapop_complex
    and not(ioarr.iscomplexarray or ioarr.isfullarray) then
        mishap(ioarr, 1, 'lapop: Complex or full array needed for update')
    else
        oldfloatarray(tag, REG(ioarr, ioreg)) -> ioarrE;
        [] -> ioregE;
        true -> do_copy;    ;;; supplied array needs to be filled later
        copy_region(ioarr, ioreg, ioarrE, ioregE); ;;; initialise
    endif
enddefine;

define lconstant result_arr(do_copy, arrE, regE, arr, reg) -> arr;
    ;;; Returns the array that is to be passed out.
    ;;; do_copy is normally result from o_arr or io_arr
    ;;; arrE and regE were passed to the external routine. arr and reg
    ;;; were passed in to the calling procedure.
    ;;; Does not need to return a region, since results either have
    ;;; region=boundslist or region given as argument.
    if do_copy then
        unless arr.isarray then
            oldfloatarray(arr, reg /== [] and reg or regE) -> arr
        endunless;
        copy_region(arrE, regE, arr, reg);
    else
        arrE -> arr         ;;; might already be identical
    endif
enddefine;

;;; Next two routines only strictly needed when first arg forced true
;;; because of bounds mismatch, even though o/p array has been created
;;; by o_arr, and the required type is not in the main procedure mode.
;;; This never arises at the time of writing. However it is good practice
;;; to use them in conjunction with o_arr_<type>, in case e.g. copy_region
;;; should be modified to refer to lapop_complex.

define lconstant result_arr_real with_nargs 5;
    dlocal lapop_complex = false;
    result_arr()
enddefine;

define lconstant result_arr_complex with_nargs 5;
    dlocal lapop_complex = true;
    result_arr()
enddefine;

;;; For handling exceptions thrown when complex data are encountered
;;; and the leading array was real or full. Restarts p, with
;;; the complex flag set true.

define lconstant cmplx_xcptn_hndlr(N, mess, idstring, severity, p)
        /* -> bool */;
    if idstring == lapop_type_complex then
        erasenum(N);
        true -> lapop_complex;
        chainfrom(p, p);
    else
        false
    endif
enddefine;

define lconstant null_xcptn_hndlr(N, mess, ids, sev) /* -> bool */;
    false
enddefine;

define :inline lconstant SETARRAYS;
    ;;; Macro to call setarrays with complex exceptions caught.
    if lapop_complex then
        setarrays()
    else
        dlocal pop_exception_handler = cmplx_xcptn_hndlr(% setarrays %);
        setarrays();
        null_xcptn_hndlr -> pop_exception_handler
    endif;
enddefine;


/*
-- Main routines ------------------------------------------------------
*/


define la_print(arr);
    lvars w = false, p = 3;
    if arr.isinteger then arr -> (arr, w) endif;
    if arr.isinteger then arr -> (arr, p) endif;

    GETREGIONS [arr] [arr]

    dlocal lapop_complex = hascomplexdata(arr, arrreg), pop_pr_places = p;

    w or (lapop_complex and 16 or 8) -> w;
    lvars d1 = pdnargs(arr) == 1,
        (r0, r1, c0, c1) = (explode(REG(arr, arrreg)), if d1 then 1, 1 endif);
    pr(newline);
    lvars r, c;
    for r from r0 to r1 do
        for c from c0 to c1 do
            pr_field(arr(r, unless d1 then c endunless), w, ' ', false)
        endfor;
        pr(newline);
    endfor
enddefine;


define la_copy(a, b) -> b;
    ;;; Atypical routine in that the operation is null. For efficiency
    ;;; lapack is used where the external call is the only copy needed,
    ;;; otherwise the Pop-11 routines are used. The direct calls to
    ;;; copy_region, arr_type and oldfloatarray would not normally
    ;;; happen at this level.

    GETREGIONS [a b] [a b]

    dlocal lapop_complex = a.iscomplexarray;

    if a.isok_input_arr
    and (not(b.isarray) or arr_type(a) == arr_type(b)) then
        o_arr(false, b, breg, areg) -> (b, breg, _);
        xLACPY('a', a, areg, b, breg)
    elseif b.isarray then
        copy_region(a, areg, b, breg)
    else
        define lconstant setarrays;
            lvars bb = oldfloatarray(b, breg /== [] and breg or REG(a, areg));
            copy_region(a, areg, bb, breg);
            bb -> b;  ;;; only update b if copy_region OK
        enddefine;
        SETARRAYS()
    endif
enddefine;


define la_col(a, ia, b, ib) -> b;
    ;;; Copy one column. More efficient than la_copy if arrays right
    ;;; type, since avoids need to build region lists.

    GETREGIONS [a ia b ib] [a b]

    dlocal lapop_complex = a.iscomplexarray;

    lvars adreg, bdreg;     ;;; column regions
    if a.isok_input_arr
    and (not(b.isarray) or arr_type(a) == arr_type(b)) then
        REG(a, areg) -> areg;
        lvars acols = fast_back(fast_back(areg));
        acols == [] and 1 or ia fi_- fast_front(acols) fi_+ 1 -> ia;
        if b.isarray or breg /== [] then
            lvars bcols = fast_back(fast_back(REG(b,breg)));
            bcols == [] and 1 or ib fi_- fast_front(bcols) fi_+ 1 -> ib;
        else
            row_dims(a, areg), if ib then <> [^ib ^ib] endif -> bdreg;
            1 -> ib
        endif;
        o_arr(false, b, breg, bdreg) -> (b, breg, _);
        xLPCOL(a, areg, ia, b, breg, ib);
    else
        lvars arows = row_dims(a, areg);
        arows, if pdnargs(a) == 2 then <> [^ia ^ia] endif -> adreg;
        if b.isarray then
            row_dims(b, breg), if pdnargs(b) == 2 then <> [^ib ^ib] endif
                -> bdreg;
            copy_region(a, adreg, b, bdreg)
        else
            if breg == [] then
                row_dims(a, areg), if ib then <> [^ib ^ib] endif ->> breg
            elseif listlength(breg) == 2 then
                breg
            else
                row_dims(b, breg) <> [^ib ^ib]
            endif -> bdreg;
            define lconstant setarrays;
                lvars bb = oldfloatarray(b, breg);
                copy_region(a, adreg, bb, bdreg);
                bb -> b;  ;;; only update b if copy_region OK
            enddefine;
            SETARRAYS()
        endif
    endif
enddefine;


define la_row(a, ia, b, ib) -> b;
    ;;; Copy one row. More efficient than la_copy if arrays right
    ;;; type, since avoids need to build region lists.

    GETREGIONS [a ia b ib] [a b]

    dlocal lapop_complex = a.iscomplexarray;

    lvars adreg, bdreg;     ;;; row regions
    if a.isok_input_arr
    and (not(b.isarray) or arr_type(a) == arr_type(b)) then
        REG(a,areg) -> areg;
        ia fi_- fast_front(areg) fi_+ 1 -> ia;
        if b.isarray or breg /== [] then
            ib fi_- fast_front(REG(b,breg)) fi_+ 1 -> ib;
        else
            conspair(ib, conspair(ib, fast_back(fast_back(areg))))
                -> bdreg;
            1 -> ib
        endif;
        o_arr(false, b, breg, bdreg) -> (b, breg, _);
        xLPROW(a, areg, ia, b, breg, ib);
    else
        conspair(ia, conspair(ia, fast_back(fast_back(REG(a,areg)))))
            -> adreg;
        if b.isarray then
            conspair(ib, conspair(ib, fast_back(fast_back(REG(b,breg)))))
                -> bdreg;
            copy_region(a, adreg, b, bdreg)
        else
            if breg == [] then
                conspair(ib, conspair(ib, fast_back(fast_back(REG(a,areg)))))
                    ->> breg
            else
                conspair(ib, conspair(ib, fast_back(fast_back(breg))))
            endif -> bdreg;
            define lconstant setarrays;
                lvars bb = oldfloatarray(b, breg);
                copy_region(a, adreg, bb, bdreg);
                bb -> b;  ;;; only update b if copy_region OK
            enddefine;
            SETARRAYS()
        endif
    endif
enddefine;


define la_ritoc(a, b, c) -> c;
    ;;; Combine real and imaginary parts.

    GETREGIONS [a b c] [a b c]

    dlocal lapop_complex = false;

    lvars aE, aregE, bE, bregE, cE, cregE, ccop,
        cdreg = not(c.isarray or creg /== []) and REG(a, areg);

    ;;; do not need to catch complex nos as a and b must be real
    i_arr(ltag, a, areg) -> (aE, aregE);
    i_arr(ltag, b, breg) -> (bE, bregE);
    o_arr_complex(ltag, c, creg, cdreg) -> (cE, cregE, ccop);

    xLPRITOC(aE, aregE, bE, bregE, cE, cregE);

    result_arr_complex(ccop, cE, cregE, c, creg) -> c
enddefine;


define la_ctori(c, a, b) -> (a, b);
    ;;; Combine real and imaginary parts.

    GETREGIONS [c a b] [c a b]

    dlocal lapop_complex = true;

    lvars aE, aregE, acop, bE, bregE, bcop, cE, cregE,
        abdreg = REG(c, creg);

    i_arr(ltag, c, creg) -> (cE, cregE);
    o_arr_real(ltag, a, areg, abdreg) -> (aE, aregE, acop);
    o_arr_real(ltag, b, breg, abdreg) -> (bE, bregE, bcop);

    xLPCTORI(cE, cregE, aE, aregE, bE, bregE);

    result_arr_real(acop, aE, aregE, a, areg) -> a;
    result_arr_real(bcop, bE, bregE, b, breg) -> b
enddefine;


define lconstant la_trans_conj(a, b, doconj) -> b;
    ;;; Transpose and optionally conjugate.

    GETREGIONS [a b doconj] [a b]

    dlocal lapop_complex = a.iscomplexarray;

    lvars aE, aregE, bE, bregE, bcop, bdreg = false;
    unless b.isarray or breg /== [] then
        col_dims(a, areg) <> row_dims(a, areg) -> bdreg
    endunless;

    define lconstant setarrays;
        i_arr(ltag, a, areg) -> (aE, aregE);
        o_arr(ltag, b, breg, bdreg) -> (bE, bregE, bcop);
    enddefine;
    SETARRAYS();

    if doconj and lapop_complex then
        xLPADJOINT(aE, aregE, bE, bregE)
    else
        xLPTRANS(aE, aregE, bE, bregE)
    endif;

    result_arr(bcop, bE, bregE, b, breg) -> b
enddefine;

define la_transpose with_nargs 2 = la_trans_conj(% false %); enddefine;

define la_adjoint with_nargs 2 = la_trans_conj(% true %); enddefine;


define la_reshape(a, abycol, b, bbycol) -> b;
    ;;; Reshape a matrix - i.e. reorder the elements.

    GETREGIONS [a abycol b bbycol] [a b]

    dlocal lapop_complex = a.iscomplexarray;

    unless b.isarray or breg /== [] then
        mishap(0, 'lapop: Output array or region spec. needed')
    endunless;

    lvars aE, aregE, bE, bregE, bcop;

    define lconstant setarrays;
        i_arr(ltag, a, areg) -> (aE, aregE);
        o_arr(ltag, b, breg, false) -> (bE, bregE, bcop);
    enddefine;
    SETARRAYS();

    xLPRESHAPE(abycol, bbycol, aE, aregE, bE, bregE);

    result_arr(bcop, bE, bregE, b, breg) -> b
enddefine;


define la_+(a, b, c) -> c;
    ;;; Returns the sum of matrix a and matrix b.

    GETREGIONS [a b c] [a b c]

    dlocal lapop_complex = a.iscomplexarray;

    lvars bE, bregE, cE, cregE, ccop;

    define lconstant setarrays;
        io_arr(ltag, a, areg, c, creg) -> (cE, cregE, ccop);
        i_arr(ltag, b, breg) -> (bE, bregE);
    enddefine;
    SETARRAYS();

    xLPAXPY(1, bE, bregE, cE, cregE);

    result_arr(ccop, cE, cregE, c, creg) -> c
enddefine;


define la_accum(alpha, a, b) -> b;
    ;;; Accumulates alpha*a + b

    GETREGIONS [alpha a b] [a b]

    dlocal lapop_complex = a.iscomplexarray or alpha.iscomplex;

    lvars aE, aregE, bE, bregE, bcop;

    define lconstant setarrays;
        i_arr(ltag, a, areg) -> (aE, aregE);
        iou_arr(ltag, b, breg) -> (bE, bregE, bcop);
    enddefine;
    SETARRAYS();

    xLPAXPY(alpha, aE, aregE, bE, bregE);

    result_arr(bcop, bE, bregE, b, breg) -> b
enddefine;


define la_scale(alpha, a, b) -> b;
    ;;; alpha * a where alpha is a scalar

    GETREGIONS [alpha a b] [a b]

    dlocal lapop_complex = alpha.iscomplex or a.iscomplexarray;

    lvars aE, aregE, bE, bregE, bcop;

    define lconstant setarrays;
        io_arr(ltag, a, areg, b, breg) -> (bE, bregE, bcop);
    enddefine;
    SETARRAYS();

    xLPSCAL(alpha, bE, bregE);

    result_arr(bcop, bE, bregE, b, breg) -> b
enddefine;


define la_*(a, b, c) -> c;
    ;;; Returns the matrix product of a matrix a with a matrix b.
    ;;; Since xGEMV is no faster than xGEMM, a separate la_*_vec
    ;;; is not provided. (Tested using 2000x2000 matrix, and repeated
    ;;; calls with 5x5 matrix.)

    GETREGIONS [a b c] [a b c]

    dlocal lapop_complex = a.iscomplexarray;

    lvars aE, aregE, bE, bregE, cE, cregE, ccop,
        cdreg = not(c.isarray or creg /== []) and
        (row_dims(a, areg) <> col_dims(b, breg));

    define lconstant setarrays;
        i_arr(ltag, a, areg) -> (aE, aregE);
        i_arr(ltag, b, breg) -> (bE, bregE);
        o_arr(ltag, c, creg, cdreg) -> (cE, cregE, ccop);
    enddefine;
    SETARRAYS();

    xGEMM('n', 'n', 1, aE, aregE, bE, bregE, 0, cE, cregE);

    result_arr(ccop, cE, cregE, c, creg) -> c
enddefine;


define la_trans_*(a, transa, b, transb, c) -> c;
    ;;; Returns op1(a)*op2(b) where ap1 and op2 are identity,
    ;;; transpose or adjoint operations.

    GETREGIONS [a transa b transb c] [a b c]

    dlocal lapop_complex = a.iscomplexarray;

    lvars aE, aregE, bE, bregE, cE, cregE, ccop, cdreg = false;
    unless c.isarray or creg /== [] then
        lvars op;
        if (fast_subscrs(1, transa) ->> op) == `n` or op == `N` then
            row_dims(a, areg)
        else
            col_dims(a, areg)
        endif
        <>
        if (fast_subscrs(1, transb) ->> op) == `n` or op == `N` then
            col_dims(b, breg)
        else
            row_dims(b, breg)
        endif
            -> cdreg
    endunless;

    define lconstant setarrays;
        i_arr(ltag, a, areg) -> (aE, aregE);
        i_arr(ltag, b, breg) -> (bE, bregE);
        o_arr(ltag, c, creg, cdreg) -> (cE, cregE, ccop);
    enddefine;
    SETARRAYS();

    xGEMM(transa, transb, 1, aE, aregE, bE, bregE, 0, cE, cregE);

    result_arr(ccop, cE, cregE, c, creg) -> c
enddefine;


define la_diag_*(a, b, c) -> c;
    ;;; Returns the matrix product diag(a)*b or a*diag(b).

    GETREGIONS [a b c] [a b c]

    REG(a, areg) -> areg;       ;;; avoid further calls to boundslist
    REG(b, breg) -> breg;
    lvars byrow,
        (am, an) = array_dims(a, areg),
        (bm, bn) = array_dims(b, breg);
    if (an == 1 and (bm /== 1 or bn /== 1) ->> byrow) then
        unless am == bm then
            mishap(b, breg, am, 3, 'lapop: B has wrong number of rows')
        endunless;
        (a, areg, b, breg) -> (b, breg, a, areg)
    else
        unless bn == 1 then
            mishap(a, areg, b, breg, 4, 'lapop: A or B must be a single col.')
        endunless;
        unless an == bm then
            mishap(a, areg, bm, 3, 'lapop: A has wrong number of cols')
        endunless;
    endif;

    dlocal lapop_complex = hascomplexdata(b, breg);

    lvars cE, cregE, ccop;
    define lconstant setarrays;
        io_arr(ltag, a, areg, c, creg) -> (cE, cregE, ccop);
    enddefine;
    SETARRAYS();

    lconstant
        Ar0 = [0 0 0 0], Ar1 = tl(Ar0), Ac0 = tl(Ar1), Ac1 = tl(Ac0);
    lvars i, bi, ar, ai0, ai1, d1 = pdnargs(a) == 1;
    if d1 then
        not(byrow) -> byrow; ;;; happens to work
        Ac0 -> ar
    else
        Ar0 -> ar
    endif;
    explode(areg) -> explode(ar);
    if byrow then
        Ar0 -> ai0; Ar1 -> ai1;
    else
        Ac0 -> ai0; Ac1 -> ai1;
    endif;
    fast_front(ai0) fi_-1 -> i;

    for bi in_array b in_region breg do
        i fi_+ 1 ->> i ->> fast_front(ai0) -> fast_front(ai1);
        xSCAL(bi, cE, ar, false);
    endfor;

    result_arr(ccop, cE, cregE, c, creg) -> c
enddefine;


define la_linsolve(a, b, x) -> x;
    ;;; Solves the linear equations a*x = b, where b may have multiple
    ;;; columns. a must be a square matrix, b must have same number of
    ;;; rows as a.
    ;;; Uses the "expert" driver xGESVX to take advantage of equilibration.
    ;;; Otherwise naive - for example discards the error results, and
    ;;; does not allow previous factorisation to be used - both of these
    ;;; would be worth including in a more sophisticated interface.

    GETREGIONS [a b x] [a b x]

    dlocal lapop_complex = a.iscomplexarray;

    lvars aE, aregE, bE, bregE, xE, xregE, xcop,
        n_col = col_dims(a, areg),
        nrhs_col = col_dims(b, breg),
        ipiv = oldintarray(ltag, n_col);

    define lconstant setarrays;
        ;;; Need to copy a and b because equilibration may alter them.
        iw_arr(ltag, a, areg) -> (aE, aregE);
        iw_arr(ltag, b, breg) -> (bE, bregE);
        o_arr(ltag, x, xreg, REG(b, breg)) -> (xE, xregE, xcop);
    enddefine;
    SETARRAYS();

    ;;; in principle these have uses, but treat as work arrays
    lvars
        af = oldfloatarray(ltag, REG(a, areg)),
        r = oldrfloatarray(ltag, n_col),
        c = oldrfloatarray(ltag, n_col),
        ferr = oldrfloatarray(ltag, nrhs_col),
        berr = oldrfloatarray(ltag, nrhs_col);

    ;;; First arg specifies to do equilibration if needed.
    ;;; 6th arg - equed - is dummy - it receives a result which is ignored.
    ;;; Condition result also ignored.
    xGESVX('e', 'n', aE,aregE, af,[], ipiv,[], 'n', r,[], c,[],
        bE,bregE, xE,xregE, ferr,[], berr,[]) -> /* rcond */;

    result_arr(xcop, xE, xregE, x, xreg) -> x
enddefine;


define la_lsqsolve(a, b, x) -> x;
    ;;; Finds the least squares solution to the linear equations a*x = b,
    ;;; where b may have multiple columns. a need not be a square matrix.
    ;;; Uses xGELS, so assumes x has rank equal to its smaller dimension.
    ;;; Does not bother with errors - see lsqsolve2 for a more sophisticated
    ;;; routine that returns these.

    GETREGIONS [a b x] [a b x]

    dlocal lapop_complex = a.iscomplexarray;

    lvars aE, aregE, bE, bregE, xcop, (m, n) = array_dims(a, areg);

    define lconstant setarrays;
        ;;; Complexity is due to Lapack routine using same array for b and x
        iw_arr(ltag, a, areg) -> (aE, aregE);   ;;; a may be altered
        if m == n then
            io_arr(ltag, b, breg, x, xreg) -> (bE, bregE, xcop)
        elseif m > n then
            iw_arr(ltag, b, breg) -> (bE, bregE)
        else   ;;; m < n
            lvars xdreg = false;
            unless x.isarray or xreg /== [] then
                col_dims(a, areg) <> col_dims(b, breg) -> xdreg ;;; n x nrhs
            endunless;
            o_arr(ltag, x, xreg, xdreg) -> (bE, bregE, xcop);
            lvars       ;;; m x nrhs region
                (xr0, xr1, xc0, xc1) = explode(REG(bE, bregE)),
                binxreg = [^(xr0, xr0 fi_+ m fi_- 1, xc0, xc1)];
            copy_region(b, breg, bE, binxreg);
        endif;
    enddefine;
    SETARRAYS();

    xGELS('n', aE,aregE, bE,bregE);

    if m <= n then
        result_arr(xcop, bE, bregE, x, xreg) -> x;
    else        ;;; m > n
        lvars
            (br0, br1, bc0, bc1) = explode(REG(bE, bregE)),
            xinbreg = [^(br0,        br0 fi_+ n fi_- 1, bc0, bc1)];
        result_arr(true, bE, xinbreg, x, xreg) -> x;
    endif
enddefine;


define la_lsqsolve2(a, b, x, errs, rcond) -> (x, errs, rank);
    ;;; Finds the least squares solution to the linear equations a*x = b,
    ;;; where b may have multiple columns. a need not be a square matrix.
    ;;; Uses xGELSX, but if xGELSY available that might be faster.
    ;;; See Lapack documentation for the rcond argument. If given as
    ;;; <false>, is passed on as 0.
    ;;; x returns the solution, errs the errors if m > n and rank=n - the sum
    ;;; of column j of errs gives the sum of the squared errors of column
    ;;; i of the solution.

    GETREGIONS [a b x errs rcond] [a b x errs]

    dlocal lapop_complex = a.iscomplexarray;

    lvars aE, aregE, bE, bregE, xcop, (m, n) = array_dims(a, areg);

    define lconstant setarrays;
        ;;; Complexity is due to Lapack routine using same array for b and x
        iw_arr(ltag, a, areg) -> (aE, aregE);   ;;; a may be altered
        if m == n then
            io_arr(ltag, b, breg, x, xreg) -> (bE, bregE, xcop)
        elseif m > n then
            iw_arr(ltag, b, breg) -> (bE, bregE)
        else   ;;; m < n
            lvars xdreg = false;
            unless x.isarray or xreg /== [] then
                col_dims(a, areg) <> col_dims(b, breg) -> xdreg ;;; n x nrhs
            endunless;
            o_arr(ltag, x, xreg, xdreg) -> (bE, bregE, xcop);
            lvars       ;;; m x nrhs region
                (xr0, xr1, xc0, xc1) = explode(REG(bE, bregE)),
                binxreg = [^(xr0, xr0 fi_+ m fi_- 1, xc0, xc1)];
            copy_region(b, breg, bE, binxreg);
        endif;
    enddefine;
    SETARRAYS();

    lvars (jpvt, jpvtreg) = (oldintarray(0, [1 ^n], 0), []);

    xGELSX(aE,aregE, bE,bregE, jpvt,jpvtreg, rcond or 0.0) -> rank;

    if m <= n then
        result_arr(xcop, bE, bregE, x, xreg) -> x;
        false -> errs;
    else        ;;; m > n
        lvars
            (br0, br1, bc0, bc1) = explode(REG(bE, bregE)),
            xinbreg = [^(br0,        br0 fi_+ n fi_- 1, bc0, bc1)],
            einbreg = [^(br0 fi_+ n, br1,               bc0, bc1)];
        result_arr(true, bE, xinbreg, x, xreg) -> x;
        result_arr(true, bE, einbreg, errs, errsreg) -> errs;
    endif
enddefine;


define la_eigvals(a, w) -> w;
    ;;; Returns the eigenvalues of a square matrix.

    GETREGIONS [a w] [a w]

    dlocal lapop_complex = a.iscomplexarray;

    lvars aE, aregE, wE, wregE, wcop, wdreg = col_dims(a, areg);

    define lconstant setarrays;
        iw_arr(ltag, a, areg) -> (aE, aregE);
        o_arr_complex(ltag, w, wreg, wdreg) -> (wE, wregE, wcop);
    enddefine;
    SETARRAYS();

    lvars scale = oldrfloatarray(ltag, wdreg);

    if lapop_complex then
        xGEEVX('b', 'n', 'n', 'n', aE,aregE, wE,wregE,
            false, false, false, false, scale,[],
            false, false, false, false) -> (_, _, _);
    else
        lvars
            wr = oldrfloatarray(ltag, wdreg),
            wi = oldrfloatarray(ltag, wdreg);
        xGEEVX('b', 'n', 'n', 'n', aE,aregE, wr,[], wi,[],
            false, false, false, false, scale,[],
            false, false, false, false) -> (_, _, _);
        xLPRITOC(wr,[], wi,[], wE, wregE);
    endif;
    result_arr(wcop, wE, wregE, w, wreg) -> w
enddefine;


define la_eig(a, vl, w, vr) -> (vl, w, vr);
    ;;; Returns the eigenvalues and eigenvectors of a square matrix.

    GETREGIONS [a vl w vr] [a vl w vr]

    dlocal lapop_complex = a.iscomplexarray;

    lvars aE, aregE, wE, wregE, wcop,
        vlE, vlregE, vlcop, vrE, vrregE, vrcop,
        vdreg = REG(a, areg), wdreg = col_dims(false, vdreg);

    define lconstant setarrays;
        iw_arr(ltag, a, areg) -> (aE, aregE);
        o_arr_complex(ltag, vl, vlreg, vdreg) -> (vlE, vlregE, vlcop);
        o_arr_complex(ltag, w, wreg, wdreg) -> (wE, wregE, wcop);
        o_arr_complex(ltag, vr, vrreg, vdreg) -> (vrE, vrregE, vrcop);
    enddefine;
    SETARRAYS();

    lvars scale = oldrfloatarray(ltag, wdreg);

    if lapop_complex then
        xGEEVX('b', 'v', 'v', 'n', aE,aregE, wE,wregE,
            vlE, vlregE, vrE, vrregE, scale,[],
            false, false, false, false) -> (_, _, _);
    else
        REG(wE, wregE) -> wregE;
        REG(vlE, vlregE) -> vlregE;
        REG(vrE, vrregE) -> vrregE;
        lvars
            wr = oldrfloatarray(ltag, wregE),
            wi = oldrfloatarray(ltag, wregE),
            vlx = oldrfloatarray(ltag, vlregE),
            vrx = oldrfloatarray(ltag, vrregE);
        xGEEVX('b', 'v', 'v', 'n', aE,aregE, wr,[], wi,[],
            vlx, [], vrx, [], scale,[],
            false, false, false, false) -> (_, _, _);
        xLPRITOC(wr,[], wi,[], wE, wregE);

        ;;; repackage the eigenvectors
        lconstant ;;; a regions for real, b for imag
            vlcrega = [0 0 0 0], vrcrega = [0 0 0 0],
            vlc0a = tl(tl(vlcrega)), vlc1a = tl(vlc0a),
            vrc0a = tl(tl(vrcrega)), vrc1a = tl(vrc0a),
            vlcregb = [0 0 0 0], vrcregb = [0 0 0 0],
            vlc0b = tl(tl(vlcregb)), vlc1b = tl(vlc0b),
            vrc0b = tl(tl(vrcregb)), vrc1b = tl(vrc0b);
        lvars (i, i1) = explode(wregE), jl, jr;
        explode(vlregE) -> explode(vlcrega);
        explode(vlregE) -> explode(vlcregb);
        explode(vrregE) -> explode(vrcrega);
        explode(vrregE) -> explode(vrcregb);
        fast_front(vlc0a) ->> jl -> fast_front(vlc1a);
        fast_front(vrc0a) ->> jr -> fast_front(vrc1a);
        repeat
            if wi(i) = 0.0 then
                xLPRTOC(vlx, vlcrega, vlE, vlcrega);
                xLPRTOC(vrx, vrcrega, vrE, vrcrega);
            else   ;;; have a conjugate pair
                i fi_+ 1 -> i;
                jl fi_+ 1 ->> jl ->> fast_front(vlc0b) -> fast_front(vlc1b);
                jr fi_+ 1 ->> jr ->> fast_front(vrc0b) -> fast_front(vrc1b);
                xLPRITOC(vlx, vlcrega, vlx, vlcregb, vlE, vlcrega);
                xCOPY(vlE, vlcrega, 1, vlE, vlcregb, 1);
                xLACGV(vlE, vlcregb, 1);
                xLPRITOC(vrx, vrcrega, vrx, vrcregb, vrE, vrcrega);
                xCOPY(vrE, vrcrega, 1, vrE, vrcregb, 1);
                xLACGV(vrE, vrcregb, 1);
            endif;
            i fi_+ 1 -> i;
            jl fi_+ 1 ->> jl ->> fast_front(vlc0a) -> fast_front(vlc1a);
            jr fi_+ 1 ->> jr ->> fast_front(vrc0a) -> fast_front(vrc1a);
        quitif (i fi_> i1); endrepeat;
    endif;

    result_arr(vlcop, vlE, vlregE, vl, vlreg) -> vl;
    result_arr(wcop, wE, wregE, w, wreg) -> w;
    result_arr(vrcop, vrE, vrregE, vr, vrreg) -> vr;
enddefine;


define la_eigvals_herm(a, w) -> w;
    ;;; Returns the eigenvalues of a Hermitian matrix.

    GETREGIONS [a w] [a w]

    dlocal lapop_complex = a.iscomplexarray;

    lvars aE, aregE, wE, wregE, wcop,
        wdreg = not(w.isarray or wreg /== []) and col_dims(a, areg);

    define lconstant setarrays;
        iw_arr(ltag, a, areg) -> (aE, aregE);
    enddefine;
    SETARRAYS();
    o_arr_real(ltag, w, wreg, wdreg) -> (wE, wregE, wcop);

    if lapop_complex then
        xHEEVD('n', 'u', aE,aregE, wE,wregE)
    else
        xSYEVD('n', 'u', aE,aregE, wE,wregE)
    endif;
    result_arr_real(wcop, wE, wregE, w, wreg) -> w
enddefine;


define la_eig_herm(a, w, e) -> (w, e);
    ;;; Returns the eigenvalues w and eigenvectors e of a Hermitian
    ;;; matrix a.

    GETREGIONS [a w e] [a w e]

    dlocal lapop_complex = a.iscomplexarray;

    lvars aE, aregE, ecop, wE, wregE, wcop,
        wdreg = not(w.isarray or wreg /== []) and col_dims(a, areg);

    define lconstant setarrays;
        io_arr(ltag, a, areg, e, ereg) -> (aE, aregE, ecop);
    enddefine;
    SETARRAYS();
    o_arr_real(ltag, w, wreg, wdreg) -> (wE, wregE, wcop);

    if lapop_complex then
        xHEEVD('v', 'u', aE,aregE, wE,wregE)
    else
        xSYEVD('v', 'u', aE,aregE, wE,wregE)
    endif;
    result_arr_real(wcop, wE, wregE, w, wreg) -> w;
    result_arr(ecop, aE, aregE, e, ereg) -> e;
enddefine;


define la_singvals(a, s) -> s;
    ;;; Returns the singular values of a real matrix.

    GETREGIONS [a s] [a s]

    dlocal lapop_complex = a.iscomplexarray;

    lvars aE, aregE, sE, sregE, scop,
        (m, n) = array_dims(a, areg),
        sdreg = not(s.isarray or sreg /== []) and
        (m < n and row_dims(a,areg) or col_dims(a,areg));

    define lconstant setarrays;
        iw_arr(ltag, a, areg) -> (aE, aregE);
    enddefine;
    SETARRAYS();
    o_arr_real(ltag, s, sreg, sdreg) -> (sE, sregE, scop);

    xGESVD('n', 'n', aE,aregE, sE,sregE, false,[], false,[]);
    result_arr_real(scop, sE, sregE, s, sreg) -> s
enddefine;


define la_svd(a, u, s, vt) -> (u, s, vt);
    ;;; Returns the singular value decomposition of a real matrix.
    ;;; Only returns singular vectors for non-zero singular values.

    GETREGIONS [a u s vt] [a u s vt]

    dlocal lapop_complex = a.iscomplexarray;

    lvars
        aE, aregE, sE, sregE, scop, vtE, vtregE, vtcop, uE, uregE, ucop,
        col_d = col_dims(a, areg),
        row_d = row_dims(a, areg),
        (m, n) = array_dims(a, areg);

    define lconstant setarrays;
        ;;; Since a gets destroyed anyway, might as well use it for one
        ;;; of the results matrices.
        if m >= n then      ;;; tall and thin
            io_arr(ltag, a, areg, u, ureg) -> (aE, aregE, ucop);
            o_arr(ltag, vt, vtreg, col_d <> col_d) -> (vtE, vtregE, vtcop);
        else                ;;; short and wide
            io_arr(ltag, a, areg, vt, vtreg) -> (aE, aregE, vtcop);
            o_arr(ltag, u, ureg, row_d <> row_d) -> (uE, uregE, ucop);
        endif;
    enddefine;
    SETARRAYS();

    if m >= n then      ;;; tall and thin
        o_arr_real(ltag, s, sreg, col_d) -> (sE, sregE, scop);
        xGESVD('o', 's', aE,aregE, sE,sregE, false,[], vtE,vtregE);
        result_arr(ucop, aE, aregE, u, ureg) -> u;
        result_arr(vtcop, vtE, vtregE, vt, vtreg) -> vt;
    else                ;;; short and wide
        o_arr_real(ltag, s, sreg, row_d) -> (sE, sregE, scop);
        xGESVD('s', 'o', aE,aregE, sE,sregE, uE,uregE, false,[]);
        result_arr(ucop, uE, uregE, u, ureg) -> u;
        result_arr(vtcop, aE, aregE, vt, vtreg) -> vt;
    endif;
    result_arr_real(scop, sE, sregE, s, sreg) -> s
enddefine;


vars lapop = true;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Oct  3 2003
        Added la_row, la_col, la_accum.
--- David Young, Sep 29 2003
        Added la_ritoc, la_ctori, la_+, la_scale, la_eigvals and la_eig.
        Changed so that complex output array does not switch computation
        into complex mode. Other minor tidying.
 */
