/* --- Copyright University of Sussex 2006. All rights reserved. ----------
 > File:            $popvision/lib/lapack.p
 > Purpose:         Interface to Lapack (linear algebra package)
 > Author:          David Young, Aug 13 2003 (see revisions)
 > Documentation:   HELP * LAPACK
 */

compile_mode:pop11 +strict;

section;

uses popvision, excall;
uses newsfloatarray,newdfloatarray,newcfloatarray,newzfloatarray,newintarray;

/*
-- External routines --------------------------------------------------
*/

/* Set up string for loading libraries. */

#_IF not(DEF lapack_libraries)
#_IF sys_os_type(2) == "sunos"
vars lapack_libraries =
    ['-L/opt/SUNWspro/lib' '-lsunperf' '-lF77' '-lM77' '-lsunmath'];
#_ELSEIF sys_os_type(2) == "linux"
	;;; Added by A.Sloman 5 Dec 2004

	vars lapack_libraries =
		;;; link options obtained from running f77 -v
    	['-L/usr/lib'
    	'-L/usr/lib/gcc-lib/i386-redhat-linux/3.2.2/'
		'-llapack'
		;;; '-lfrtbegin'  only has .a version
		;;; Not sure if this is needed A.S.
		;;; '-lg2c'
		;;; Removed by [A.S]
		;;; '-lm'
		;;; Not sure if this is needed A.S.
		;;; '-lgcc_s'
		;;; '-lgcc'       not present
		;;; '-lc'		  a script
		;;; '-lgcc_s'     repeated
		;;; '-lgcc'		  not present
		];
#_ELSE
mishap(0, 'Don\'t know where to find Lapack library on this machine');
#_ENDIF
#_ENDIF

exload lapack [^(explode(lapack_libraries))]
    (language FORTRAN)
lconstant

        ;;; BLAS

        SSWAP, DSWAP, CSWAP, ZSWAP,
        SSCAL, DSCAL, CSCAL, ZSCAL,
        SCOPY, DCOPY, CCOPY, ZCOPY,
        SAXPY, DAXPY, CAXPY, ZAXPY,
        SDOT, DDOT, CDOTU, ZDOTU, CDOTC, ZDOTC,
        SNRM2, DNRM2, SCNRM2, DZNRM2,
        SASUM, DASUM, SCASUM, DZASUM,
        ISAMAX, IDAMAX, ICAMAX, IZAMAX,
        SGEMV, DGEMV, CGEMV, ZGEMV,
        SGER, DGER, CGERU, ZGERU, CGERC, ZGERC,
        SSYR, DSYR, CHER, ZHER,     ;;; CSYR ZSYR exist but nonstandard?
        SSYR2, DSYR2, CHER2, ZHER2,
        SGEMM, DGEMM, CGEMM, ZGEMM,
        SSYMM, DSYMM, CSYMM, ZSYMM, CHEMM, ZHEMM,
        SSYRK, DSYRK, CSYRK, ZSYRK, CHERK, ZHERK,
        SSYR2K, DSYR2K, CSYR2K, ZSYR2K, CHER2K, ZHER2K,

        ;;; Lapack

        ILAENV,
        CLACGV, ZLACGV,
        SLACPY, DLACPY, CLACPY, ZLACPY,
        SGESV, DGESV, CGESV, ZGESV,
        SGESVX, DGESVX, CGESVX, ZGESVX,
        SPOSV, DPOSV, CPOSV, ZPOSV,
        SPOSVX, DPOSVX, CPOSVX, ZPOSVX,
        SSYSV, DSYSV, CSYSV, ZSYSV, CHESV, ZHESV,
        SSYSVX, DSYSVX, CSYSVX, ZSYSVX, CHESVX, ZHESVX,
        SGELS, DGELS, CGELS, ZGELS,
        SGELSX, DGELSX, CGELSX, ZGELSX,
        SGELSS, DGELSS, CGELSS, ZGELSS,
        SGGLSE, DGGLSE, CGGLSE, ZGGLSE,
        SGGGLM, DGGGLM, CGGGLM, ZGGGLM,
        SSYEV, DSYEV, CHEEV, ZHEEV,
        SSYEVD, DSYEVD, CHEEVD, ZHEEVD,
        SSYEVX, DSYEVX, CHEEVX, ZHEEVX,
        SGEEV, DGEEV, CGEEV, ZGEEV,
        SGEEVX, DGEEVX, CGEEVX, ZGEEVX,
        SGESVD, DGESVD, CGESVD, ZGESVD,
        SSYGV, DSYGV, CHEGV, ZHEGV,
        SGEGV, DGEGV, CGEGV, ZGEGV,
        SGGSVD, DGGSVD, CGGSVD, ZGGSVD;

endexload;

/*
-- Utilities ----------------------------------------------------------
*/

;;; constants to denote float array types - integers for easy indexing
lconstant
    (sfloat, dfloat, cfloat, zfloat) = (1,2,3,4),
    precwords = {sfloat dfloat cfloat zfloat};

define lconstant prec_word(prec) /* -> word */;
    prec.isinteger and precwords(prec) or prec
enddefine;

;;; macros to recognise array classes
define :inline lconstant floatprec(prec);
    (prec.isinteger)
enddefine;
define :inline lconstant realprec(prec);
    (prec == 1 or prec == 2)
enddefine;
define :inline lconstant compprec(prec);
    (prec == 3 or prec == 4)
enddefine;
define :inline lconstant singprec(prec);
    (prec == 1 or prec == 3)
enddefine;
define :inline lconstant dbleprec(prec);
    (prec == 2 or prec == 4)
enddefine;

;;; unique tags for recycleable arrays
lconstant macro ltag = [ #_< consref(0) >_# ];

;;; local vector for info result
lconstant info = initintvec(1);

;;; For testing UPLO legal
lconstant uplo_opts = [`U` `L`];

;;; For generating name vectors (preferably at compile time)
define lconstant fnames(basename) /* -> vec */;
    lconstant types = {'S' 'D' 'C' 'Z'};
    mapdata(types, nonop <> (% allbutfirst(1, basename) %))
enddefine;
define lconstant fsynames(basename) /* -> vec */;
    ;;; Do not use if CSYxxx function exists!
    lconstant types = {'SSY' 'DSY' 'CHE' 'ZHE'};
    mapdata(types, nonop <> (% allbutfirst(3, basename) %))
enddefine;

;;; Vector for dummy float array arguments. Has to be right type in case
;;; type checking is on.
define lconstant dummyvec(prec) /* -> (dummyvec, index) */;
    lconstant dummyvecs = {^(
        initsfloatvec(1),
        initdfloatvec(1),
        initcfloatvec(1),
        initzfloatvec(1)
        )};
    fast_subscrv(prec, dummyvecs), 1
enddefine;

;;; Processing array/region arguments

define lconstant vec_type(arrvec) /* -> typeword */;
    ;;; Returns byte, sfloat, dfloat, int, cfloat, zfloat
    lconstant
        (sfloat_spec, _) = field_spec_info("sfloat"),
        (dfloat_spec, _) = field_spec_info("dfloat"),
        (int_spec, _) = field_spec_info("int"),
        (byte_spec, _) = field_spec_info("byte");
    lvars arr_name = arrvec.dataword;
    if arr_name == "cfloatvec" then
        cfloat
    elseif arr_name == "zfloatvec" then
        zfloat
    else
        lvars arr_spec = arrvec.datakey.class_spec;
        switchon arr_spec ==
        case sfloat_spec then sfloat
        case dfloat_spec then dfloat
        case int_spec then "int"
        case byte_spec then "byte"
        else
            mishap(arr_spec, 1, 'lapack: Array type not recognised')
        endswitchon
    endif
enddefine;

define lconstant array_spec(arr, reg, ndim, prec)
        -> (arrvec, index, dim1, nrows, ncols, ndim, prec);

    ;;; Given a 1-D or 2-D  array and a region spec, returns the array
    ;;; vector, the index in it of the start of the region, the size of
    ;;; the first dimension of the array, the number of rows and columns
    ;;; in the region, the number of dimensions of the array, and the
    ;;; precision as "byte", sfloat, dfloat, cfloat, zfloat or "int".

    ;;; Checks arr is "by row" (in Poplog terminology) if it is 2-D,
    ;;; and is a packed array of bytes, ints, floats or
    ;;; double-precision floats.

    ;;; ndim:

    ;;;   If ndim is 1 on entry, the array may actually be 1-D or 2-D.
    ;;;   If the array is 2-D the region must specify (part of) a single
    ;;;   column. ndim is returned as 1.

    ;;;   If ndim is 2 on entry, the array may actually be 1-D or 2-D.
    ;;;   If the array is 1-D it is treated as a single column.

    ;;;   If ndim is <false> the array may be 1-D or 2-D and the number
    ;;;   of dimensions is returned.

    ;;; If prec is non-<false> on entry, a mishap occurs if the
    ;;; array type does not agree. "float" may be used to mean sfloat,
    ;;; dfloat, cfloat or zfloat - the actual precision is returned.
    ;;; "real" may be used to sfloat or dfloat. "complex" means
    ;;; cfloat or zfloat.

    ;;; Also checks that the region is wholly inside the array, and that
    ;;; the leading dimension of the array is non-empty.

    arrayvector(arr) -> arrvec;
    arrayvector_bounds(arr) -> (_, index);

    lvars       ;;; actual array precision and dimensions
        aprec = vec_type(arrvec),
        adim = pdnargs(arr),
        b = boundslist(arr);

    if not(prec)
    or prec == aprec
    or (prec == "float" and floatprec(aprec))
    or (prec == "real" and realprec(aprec))
    or (prec == "complex" and compprec(aprec))
    then
        aprec -> prec
    else
        mishap(prec_word(aprec), prec_word(prec), 2,
            'lapack: Array of unexpected type')
    endif;

    if adim == 1 then           ;;; return as if column vector
        lvars (ax0, ax1) = explode(b);

        if reg == [] or reg = b then
            ax1 fi_- ax0 fi_+ 1 ->> dim1 -> nrows;
        else
            lvars (rx0, rx1) = explode(reg);
            fi_check(rx0, ax0, ax1) -> ;        ;;; check region
            fi_check(rx1, rx0, ax1) -> ;

            ax1 fi_- ax0 fi_+ 1 -> dim1;    ;;; not usu. needed, retained for consistency
            (rx0 fi_- ax0) fi_+ index -> index;
            rx1 fi_- rx0 fi_+ 1 -> nrows;
        endif;
        1 -> ncols;

        ndim or 1 -> ndim;

    elseif adim == 2 then
        unless arr.isarray_by_row then
            mishap(arr, 1, 'lapack: Need array arranged "by row"')
        endunless;

        lvars (ax0, ax1, ay0, ay1) = explode(b);

        if reg == [] or reg = b then
            ax1 fi_- ax0 fi_+ 1 ->> dim1 -> nrows;
            ay1 fi_- ay0 fi_+ 1 -> ncols;
        else
            lvars (rx0, rx1, ry0, ry1) = explode(reg);
            fi_check(rx0, ax0, ax1) -> ;        ;;; check region
            fi_check(rx1, rx0, ax1) -> ;
            fi_check(ry0, ay0, ay1) -> ;
            fi_check(ry1, ry0, ay1) -> ;

            ax1 fi_- ax0 fi_+ 1 -> dim1;
            (ry0 fi_- ay0) fi_* dim1 fi_+ (rx0 fi_- ax0) fi_+ index -> index;
            rx1 fi_- rx0 fi_+ 1 -> nrows;
            ry1 fi_- ry0 fi_+ 1 -> ncols;
        endif;

        if ndim == 1 and ncols /== 1 then
            mishap(arr, reg, 2, 'lapack: Array/region expected to be 1-D')
        else
            ndim or 2 -> ndim
        endif

    else
        mishap(arr, 1, 'lapack: Expecting 1-D or 2-D array')
    endif;

    fi_check(dim1, 1, false) -> ;
enddefine;

define lconstant array_spec_incr(arr, reg, incr, prec)
        -> (arrvec, index, incr, nvals, prec);
    ;;; Like array_spec, but where an increment may be given
    if incr then
        fi_check(incr, 1, false) -> ;
        lvars (arrvec, index, _, size, _, _, prec)
            = array_spec(arr, reg, 1, prec);
        (size fi_- 1) fi_div incr fi_+ 1 -> nvals;
    else
        lvars (arrvec, index, incr, nrows, nvals, _, prec)
            = array_spec(arr, reg, false, prec);
        if nvals == 1 then              ;;; 1 col
            1 -> incr;
            nrows -> nvals;
            ;;; if nrows == 1 then incr=dim1, nvals=ncols
        elseif nrows /== 1 then
            mishap(arr, reg, 2, 'lapack: X region must be single row or col')
        endif
    endif
enddefine;

;;; Other utilities

define lconstant checkstring(str, opts) -> opt;
    ;;; Checks that we have a string and its first letter (uppercased)
    ;;; is one of the single characters in opts. Returns the character.
    unless str.isstring and not(str.isdstring) then
        mishap(str, 1, 'lapack: String (not dstring) expected')
    endunless;
    unless lmember((lowertoupper(str(1)) ->> opt), opts) then
        mishap(str, maplist(opts, consstring(% 1 %)), 2,
            'lapack: String does not start with expected character')
    endunless
enddefine;

define lconstant workfvec(/* tag, bounds, */ prec)
        /* -> arr */ with_nargs 3;
    ;;; Return vector of type determined by prec, for array bounds given
    lconstant m =
        {^(oldsfloatarray, olddfloatarray, oldcfloatarray, oldzfloatarray)};
    arrayvector(m(prec)())
enddefine;

define lconstant workivec(/* bounds etc. */) /* -> arr */ with_nargs 2;
    ;;; Return int vector, for array bounds given
    arrayvector(oldintarray())
enddefine;

define lconstant check_error;
    ;;; Assume error code stored in info.
    ;;; Only check for negative values.
    lvars err = info(1);
    if err fi_< 0 then      ;;; should not happen?
        mishap(err, 1, 'Fatal error return from Lapack routine')
    elseif err fi_> 0 then
        sys_raise_exception(err, 1,
            'Computational error in Lapack routine', 'lapack:arith', `W`)
    endif
enddefine;

define lapack_lasterror /* -> errcode */;
    ;;; Return the last error value from a Lapack routine
    info(1)
enddefine;

;;; Edit next lines to determine whether excall checking is done.

lconstant macro CHK = [[]];        ;;; Should be normal state (off)
;;; lconstant macro CHK = [[r a i s]];      ;;; Switch on during debugging

unless CHK == [] then
    npr('lapack: Argument checking is on, probably unnecessarily')
endunless;

/*
-- Interface routines - BLAS ------------------------------------------
*/


define xSWAP(x, xr, incx, y, yr, incy);
    lvars (xv, xi, incx, xvals, prec) = array_spec_incr(x, xr, incx, "float");
    lvars (yv, yi, incy, yvals, _) = array_spec_incr(y, yr, incy, prec);
    unless xvals == yvals then
        mishap(x,xr,incx, y,yr,incy, 6,
            'lapack: X and Y lengths not compatible')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item);
        excall check=CHK PROC(
            IREF            xvals,
            VEC             xv[xi],
            IREF            incx,
            VEC             yv[yi],
            IREF            incy)
    enddefine;

    if prec == sfloat then
        EXTCALL(SSWAP, SVEC)
    elseif prec == dfloat then
        EXTCALL(DSWAP, DVEC)
    elseif prec == cfloat then
        EXTCALL(CSWAP, CVEC)
    elseif prec == zfloat then
        EXTCALL(ZSWAP, ZVEC)
    endif
enddefine;


define xSCAL(alpha, y, yr, incy);
    lvars (yv, yi, incy, yvals, prec) = array_spec_incr(y, yr, incy, "float");

    define :inline lconstant EXTCALL(PROC=item, VEC=item, REF=item);
        excall check=CHK PROC(
            IREF            yvals,
            REF             alpha,
            VEC             yv[yi],
            IREF            incy)
    enddefine;

    if prec == sfloat then
        EXTCALL(SSCAL, SVEC, SREF)
    elseif prec == dfloat then
        EXTCALL(DSCAL, DVEC, DREF)
    elseif prec == cfloat then
        EXTCALL(CSCAL, CVEC, CREF)
    elseif prec == zfloat then
        EXTCALL(ZSCAL, ZVEC, ZREF)
    endif
enddefine;


define xCOPY(x, xr, incx, y, yr, incy);
    lvars (xv, xi, incx, xvals, prec) = array_spec_incr(x, xr, incx, "float");
    lvars (yv, yi, incy, yvals, _) = array_spec_incr(y, yr, incy, prec);
    unless xvals == yvals then
        mishap(x,xr,incx, y,yr,incy, 6,
            'lapack: X and Y lengths not compatible')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item);
        excall check=CHK PROC(
            IREF            xvals,
            VEC             xv[xi],
            IREF            incx,
            VEC             yv[yi],
            IREF            incy)
    enddefine;

    if prec == sfloat then
        EXTCALL(SCOPY, SVEC)
    elseif prec == dfloat then
        EXTCALL(DCOPY, DVEC)
    elseif prec == cfloat then
        EXTCALL(CCOPY, CVEC)
    elseif prec == zfloat then
        EXTCALL(ZCOPY, ZVEC)
    endif
enddefine;


define xAXPY(alpha, x, xr, incx, y, yr, incy);
    lvars (xv, xi, incx, xvals, prec) = array_spec_incr(x, xr, incx, "float");
    lvars (yv, yi, incy, yvals, _) = array_spec_incr(y, yr, incy, prec);
    unless xvals == yvals then
        mishap(x,xr,incx, y,yr,incy, 6,
            'lapack: X and Y lengths not compatible')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item, REF=item);
        excall check=CHK PROC(
            IREF            xvals,
            REF             alpha,
            VEC             xv[xi],
            IREF            incx,
            VEC             yv[yi],
            IREF            incy)
    enddefine;

    if prec == sfloat then
        EXTCALL(SAXPY, SVEC, SREF)
    elseif prec == dfloat then
        EXTCALL(DAXPY, DVEC, DREF)
    elseif prec == cfloat then
        EXTCALL(CAXPY, CVEC, CREF)
    elseif prec == zfloat then
        EXTCALL(ZAXPY, ZVEC, ZREF)
    endif
enddefine;


define lconstant xDOT_UC(x, xr, incx, y, yr, incy, func) -> result;
    lvars (xv, xi, incx, xvals, prec) = array_spec_incr(x, xr, incx, "float");
    lvars (yv, yi, incy, yvals, _) = array_spec_incr(y, yr, incy, prec);
    unless xvals == yvals then
        mishap(x,xr,incx, y,yr,incy, 6,
            'lapack: X and Y lengths not compatible')
    endunless;

    define :inline lconstant EXTCALL(
            PROC=item, RES=item, VEC=item, REF=item);
        excall check=CHK RES PROC(
            REF             result,
            IREF            xvals,
            VEC             xv[xi],
            IREF            incx,
            VEC             yv[yi],
            IREF            incy)
    enddefine;

    if func == "dot" then
        if prec == sfloat then
            EXTCALL(SDOT, sfloat, SVEC, VOID) -> result
        elseif prec == dfloat then
            EXTCALL(DDOT, dfloat, DVEC, VOID) -> result
        else
            mishap(0, 'lapack: xDOT needs real arguments')
        endif
    elseif func == "dotu" then
        0.0 -> result;
        if prec == cfloat then
            EXTCALL(CDOTU, void, CVEC, CREF)
        elseif prec == zfloat then
            EXTCALL(ZDOTU, void, ZVEC, ZREF)
        else
            mishap(0, 'lapack: xDOTU needs complex arguments')
        endif
    elseif func == "dotc" then
        0.0 -> result;
        if prec == cfloat then
            EXTCALL(CDOTC, void, CVEC, CREF)
        elseif prec == zfloat then
            EXTCALL(ZDOTC, void, ZVEC, ZREF)
        else
            mishap(0, 'lapack: xDOTC needs complex arguments')
        endif
    endif
enddefine;


define xDOT(/* x, xr, incx, y, yr, incy */) /* -> result */ with_nargs 6;
    xDOT_UC("dot")
enddefine;

define xDOTU(/* x, xr, incx, y, yr, incy */) /* -> result */ with_nargs 6;
    xDOT_UC("dotu")
enddefine;

define xDOTC(/* x, xr, incx, y, yr, incy */) /* -> result */ with_nargs 6;
    xDOT_UC("dotc")
enddefine;


define xNRM2(x, xr, incx) /* -> result */;
    lvars (xv, xi, incx, xvals, prec) = array_spec_incr(x, xr, incx, "float");

    define :inline lconstant EXTCALL(PROC=item, VEC=item, RES=item);
        excall check=CHK RES PROC(
            IREF            xvals,
            VEC             xv[xi],
            IREF            incx) /* -> result */
    enddefine;

    if prec == sfloat then
        EXTCALL(SNRM2, SVEC, sfloat)
    elseif prec == dfloat then
        EXTCALL(DNRM2, DVEC, dfloat)
    elseif prec == cfloat then
        EXTCALL(SCNRM2, CVEC, sfloat)
    elseif prec == zfloat then
        EXTCALL(DZNRM2, ZVEC, dfloat)
    endif
enddefine;


define xASUM(x, xr, incx) /* -> result */;
    lvars (xv, xi, incx, xvals, prec) = array_spec_incr(x, xr, incx, "float");

    define :inline lconstant EXTCALL(PROC=item, VEC=item, RES=item);
        excall check=CHK RES PROC(
            IREF            xvals,
            VEC             xv[xi],
            IREF            incx) /* -> result */
    enddefine;

    if prec == sfloat then
        EXTCALL(SASUM, SVEC, sfloat)
    elseif prec == dfloat then
        EXTCALL(DASUM, DVEC, dfloat)
    elseif prec == cfloat then
        EXTCALL(SCASUM, CVEC, sfloat)
    elseif prec == zfloat then
        EXTCALL(DZASUM, ZVEC, dfloat)
    endif
enddefine;


define IxAMAX(x, xr, incx) /* -> result */;
    lvars (xv, xi, incx, xvals, prec) = array_spec_incr(x, xr, incx, "float");

    define :inline lconstant EXTCALL(PROC=item, VEC=item);
        excall check=CHK int PROC(
            IREF            xvals,
            VEC             xv[xi],
            IREF            incx) /* -> result */
    enddefine;

    if prec == sfloat then
        EXTCALL(ISAMAX, SVEC)
    elseif prec == dfloat then
        EXTCALL(IDAMAX, DVEC)
    elseif prec == cfloat then
        EXTCALL(ICAMAX, CVEC)
    elseif prec == zfloat then
        EXTCALL(IZAMAX, ZVEC)
    endif
enddefine;


define xGEMV(trans, alpha, a, ar, x, xr, incx, beta, y, yr, incy);
    lconstant trans_opts = [`N` `T` `C`];
    lvars trans_opt = checkstring(trans, trans_opts);

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");

    lvars (xv, xi, incx, xvals, _) = array_spec_incr(x, xr, incx, prec);
    unless xvals == (trans_opt == `N` and n or m) then
        mishap(x, xr, incx, a, ar, 5, 'lapack: X length not compatible with A')
    endunless;

    lvars (yv, yi, incy, yvals, _) = array_spec_incr(y, yr, incy, prec);
    unless yvals == (trans_opt == `N` and m or n) then
        mishap(y, yr, incy, a, ar, 5, 'lapack: Y length not compatible with A')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item, REF=item);
        excall check=CHK PROC(
            FSTRING        trans,
            IREF           m,
            IREF           n,
            REF            alpha,
            VEC            av[ai],
            IREF           lda,
            VEC            xv[xi],
            IREF           incx,
            REF            beta,
            VEC            yv[yi],
            IREF           incy)
    enddefine;

    if prec == sfloat then
        EXTCALL(SGEMV, SVEC, SREF)
    elseif prec == dfloat then
        EXTCALL(DGEMV, DVEC, DREF)
    elseif prec == cfloat then
        EXTCALL(CGEMV, CVEC, CREF)
    elseif prec == zfloat then
        EXTCALL(ZGEMV, ZVEC, ZREF)
    endif
enddefine;


define lconstant xGER_UC(alpha, x, xr, incx, y, yr, incy, a, ar, func);
    lvars (xv, xi, incx, xvals, prec) = array_spec_incr(x, xr, incx, "float");
    lvars (yv, yi, incy, yvals, _) = array_spec_incr(y, yr, incy, prec);
    lvars (av, ai, lda, m, n, _, _) = array_spec(a, ar, 2, prec);
    unless xvals == m and yvals == n then
        mishap(x,xr,incx, y,yr,incy, a,ar, 8,
            'lapack: X or Y length not compatible with A')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item, REF=item);
        excall check=CHK PROC(
            IREF            m,
            IREF            n,
            REF             alpha,
            VEC             xv[xi],
            IREF            incx,
            VEC             yv[yi],
            IREF            incy,
            VEC             av[ai],
            IREF            lda)
    enddefine;

    if func == "ger" then
        if prec == sfloat then
            EXTCALL(SGER, SVEC, SREF)
        elseif prec == dfloat then
            EXTCALL(DGER, DVEC, DREF)
        else
            mishap(0, 'lapack: xGER needs real arguments')
        endif
    elseif func == "geru" then
        if prec == cfloat then
            EXTCALL(CGERU, CVEC, CREF)
        elseif prec == zfloat then
            EXTCALL(ZGERU, ZVEC, ZREF)
        else
            mishap(0, 'lapack: xGERU needs complex arguments')
        endif
    elseif func == "gerc" then
        if prec == cfloat then
            EXTCALL(CGERC, CVEC, CREF)
        elseif prec == zfloat then
            EXTCALL(ZGERC, ZVEC, ZREF)
        else
            mishap(0, 'lapack: xGERC needs complex arguments')
        endif
    endif
enddefine;

define xGER(/* alpha, x, xr, incx, y, yr, incy, a, ar */) with_nargs 9;
    xGER_UC("ger")
enddefine;

define xGERU(/* alpha, x, xr, incx, y, yr, incy, a, ar */) with_nargs 9;
    xGER_UC("geru")
enddefine;

define xGERC(/* alpha, x, xr, incx, y, yr, incy, a, ar */) with_nargs 9;
    xGER_UC("gerc")
enddefine;


;;; The BLAS home page does not list CSYR and ZSYR , but these
;;; are in sunperflib and appear in other libraries on the web -
;;; so could be included if required in the next routine.

define lconstant xSYR_HER(uplo, alpha, x, xr, incx, a, ar, func);
    checkstring(uplo, uplo_opts) -> ;
    lvars (xv, xi, incx, xvals, prec) = array_spec_incr(x, xr, incx, "float");
    lvars (av, ai, lda, m, n, _, _) = array_spec(a, ar, 2, prec);
    unless xvals == m and xvals == n then
        mishap(x,xr,incx, a,ar, 5,
            'lapack: X length not compatible with A, or A not square')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item, REF=item);
        excall check=CHK PROC(
            FSTRING         uplo,
            IREF            n,
            REF             alpha,
            VEC             xv[xi],
            IREF            incx,
            VEC             av[ai],
            IREF            lda)
    enddefine;

    if func == "syr" then
        if prec == sfloat then
            EXTCALL(SSYR, SVEC, SREF)
        elseif prec == dfloat then
            EXTCALL(DSYR, DVEC, DREF)
        else
            mishap(0, 'lapack: xSYR needs real arguments')
        endif
    elseif func == "her" then
        if prec == cfloat then
            EXTCALL(CHER, CVEC, SREF)      ;;; Yes, SREF is correct
        elseif prec == zfloat then         ;;; as ALPHA is real;
            EXTCALL(ZHER, ZVEC, DREF)      ;;; and so is DREF.
        else
            mishap(0, 'lapack: xHER needs complex arguments')
        endif
    endif
enddefine;

define xSYR(/* uplo, alpha, x, xr, incx, a, ar */) with_nargs 7;
    xSYR_HER("syr")
enddefine;

define xHER(/* uplo, alpha, x, xr, incx, a, ar */) with_nargs 7;
    xSYR_HER("her")
enddefine;


define lconstant xSYR2_HER2(
        uplo, alpha, x, xr, incx, y, yr, incy, a, ar, func);
    checkstring(uplo, uplo_opts) -> ;
    lvars (xv, xi, incx, xvals, prec) = array_spec_incr(x, xr, incx, "float");
    lvars (yv, yi, incy, yvals, _) = array_spec_incr(y, yr, incy, prec);
    lvars (av, ai, lda, m, n, _, _) = array_spec(a, ar, 2, prec);
    unless xvals == m and yvals == n and m == n then
        mishap(x,xr,incx, y,yr,incy, a,ar, 8,
            'lapack: X or Y length not compatible with A, or A not square')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item, REF=item);
        excall check=CHK PROC(
            FSTRING         uplo,
            IREF            n,
            REF             alpha,
            VEC             xv[xi],
            IREF            incx,
            VEC             yv[yi],
            IREF            incy,
            VEC             av[ai],
            IREF            lda)
    enddefine;

    if func == "syr2" then
        if prec == sfloat then
            EXTCALL(SSYR2, SVEC, SREF)
        elseif prec == dfloat then
            EXTCALL(DSYR2, DVEC, DREF)
        else
            mishap(0, 'lapack: xSYR2 needs real arguments')
        endif
    elseif func == "her2" then
        if prec == cfloat then
            EXTCALL(CHER2, CVEC, CREF)
        elseif prec == zfloat then
            EXTCALL(ZHER2, ZVEC, ZREF)
        else
            mishap(0, 'lapack: xHER2 needs complex arguments')
        endif
    endif
enddefine;

define xSYR2(/* uplo, alpha, x, xr, incx, y, yr, incy, a, ar */) with_nargs 10;
    xSYR2_HER2("syr2")
enddefine;

define xHER2(/* uplo, alpha, x, xr, incx, y, yr, incy, a, ar */) with_nargs 10;
    xSYR2_HER2("her2")
enddefine;


define xGEMM(transa, transb, alpha, a, ar, b, br, beta, c, cr);
    lconstant trans_opts = [`N` `T` `C`];
    lvars
        transa_opt = checkstring(transa, trans_opts),
        transb_opt = checkstring(transb, trans_opts);

    lvars (av, ai, lda, m, k, _, prec) = array_spec(a, ar, 2, "float");
    unless transa_opt == `N` then (m, k) -> (k, m) endunless;

    lvars (bv, bi, ldb, kb, n, _, _) = array_spec(b, br, 2, prec);
    unless transb_opt == `N` then (kb, n) -> (n, kb) endunless;
    unless kb == k then
        mishap(a, ar, b, br, 4,
            'lapack: Incompatible array dimensions for A and B')
    endunless;

    lvars (cv, ci, ldc, mc, nc, _, _) = array_spec(c, cr, 2, prec);
    unless mc == m and nc == n then
        mishap(a,ar,b,br,c,cr, 6,
            'lapack: C dimensions not compatible with A and B')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item, REF=item);
        excall check=CHK PROC(
            FSTRING         transa,
            FSTRING         transb,
            IREF            m,
            IREF            n,
            IREF            k,
            REF             alpha,
            VEC             av[ai],
            IREF            lda,
            VEC             bv[bi],
            IREF            ldb,
            REF             beta,
            VEC             cv[ci],
            IREF            ldc)
    enddefine;

    if prec == sfloat then
        EXTCALL(SGEMM, SVEC, SREF)
    elseif prec == dfloat then
        EXTCALL(DGEMM, DVEC, DREF)
    elseif prec == cfloat then
        EXTCALL(CGEMM, CVEC, CREF)
    elseif prec == zfloat then
        EXTCALL(ZGEMM, ZVEC, ZREF)
    endif
enddefine;


define lconstant xSYMM_HEMM(
        side, uplo, alpha, a, ar, b, br, beta, c, cr, func);
    lconstant side_opts = [`L` `R`];
    lvars side_opt = checkstring(side, side_opts);
    checkstring(uplo, uplo_opts) -> ;

    lvars (av, ai, lda, ma, na, _, prec) = array_spec(a, ar, 2, "float");
    unless  ma == na then
        mishap(a, ar, 2, 'lapack: Expecting square array A')
    endunless;

    lvars (bv, bi, ldb, m, n, _, _) = array_spec(b, br, 2, prec);
    unless ma == (side_opt == `L` and m or n) then
        mishap(a, ar, b, br, 4,
            'lapack: Incompatible array dimensions for A and B')
    endunless;

    lvars (cv, ci, ldc, mc, nc, _, _) = array_spec(c, cr, 2, prec);
    unless mc == m and nc == n then
        mishap(b,br,c,cr, 4,
            'lapack: C dimensions not compatible with B')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item, REF=item);
        excall check=CHK PROC(
            FSTRING         side,
            FSTRING         uplo,
            IREF            m,
            IREF            n,
            REF             alpha,
            VEC             av[ai],
            IREF            lda,
            VEC             bv[bi],
            IREF            ldb,
            REF             beta,
            VEC             cv[ci],
            IREF            ldc)
    enddefine;

    if func == "symm" then
        if prec == sfloat then
            EXTCALL(SSYMM, SVEC, SREF)
        elseif prec == dfloat then
            EXTCALL(DSYMM, DVEC, DREF)
        elseif prec == cfloat then
            EXTCALL(CSYMM, CVEC, CREF)
        elseif prec == zfloat then
            EXTCALL(ZSYMM, ZVEC, ZREF)
        endif
    elseif func == "hemm" then
        if prec == cfloat then
            EXTCALL(CHEMM, CVEC, CREF)
        elseif prec == zfloat then
            EXTCALL(ZHEMM, ZVEC, ZREF)
        else
            mishap(0, 'lapack: xHER2 needs complex arguments')
        endif
    endif
enddefine;

define xSYMM(/* side, uplo, alpha, a, ar, b, br, beta, c, cr */) with_nargs 10;
    xSYMM_HEMM("symm")
enddefine;

define xHEMM(/* side, uplo, alpha, a, ar, b, br, beta, c, cr */) with_nargs 10;
    xSYMM_HEMM("hemm")
enddefine;


define lconstant xSYRK_HERK(uplo, trans, alpha, a, ar, beta, c, cr, func);
    checkstring(uplo, uplo_opts) -> ;

    lvars (av, ai, lda, n, k, _, prec) = array_spec(a, ar, 2, "float");

    lconstant to_r = [`N` `T` `C`], to_c = [`N` `T`], to_h = [`N` `C`];
    lvars trans_opts
        = func == "herk" and to_h or realprec(prec) and to_r or to_c,
        trans_opt = checkstring(trans, trans_opts);

    unless trans_opt == `N` then (n, k) -> (k, n) endunless;

    lvars (cv, ci, ldc, mc, nc, _, _) = array_spec(c, cr, 2, prec);
    unless mc == n and nc == n then
        mishap(a,ar,c,cr, 4,
            'lapack: C dimensions not compatible with A')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item, REF=item);
        excall check=CHK PROC(
            FSTRING         uplo,
            FSTRING         trans,
            IREF            n,
            IREF            k,
            REF             alpha,
            VEC             av[ai],
            IREF            lda,
            REF             beta,
            VEC             cv[ci],
            IREF            ldc)
    enddefine;

    if func == "syrk" then
        if prec == sfloat then
            EXTCALL(SSYRK, SVEC, SREF)
        elseif prec == dfloat then
            EXTCALL(DSYRK, DVEC, DREF)
        elseif prec == cfloat then
            EXTCALL(CSYRK, CVEC, CREF)
        elseif prec == zfloat then
            EXTCALL(ZSYRK, ZVEC, ZREF)
        endif
    elseif func == "herk" then
        if prec == cfloat then
            EXTCALL(CHERK, CVEC, SREF)  ;;; alpha, beta real
        elseif prec == zfloat then
            EXTCALL(ZHERK, ZVEC, DREF)  ;;; alpha, beta real
        else
            mishap(0, 'lapack: xHERK needs complex arguments')
        endif
    endif
enddefine;

define xSYRK(/* uplo, trans, alpha, a, ar, beta, c, cr */) with_nargs 8;
    xSYRK_HERK("syrk")
enddefine;

define xHERK(/* uplo, trans, alpha, a, ar, beta, c, cr */) with_nargs 8;
    xSYRK_HERK("herk")
enddefine;


define lconstant xSYR2K_HER2K(
        uplo, trans, alpha, a, ar, b, br, beta, c, cr, func);
    checkstring(uplo, uplo_opts) -> ;

    lvars (av, ai, lda, n, k, _, prec) = array_spec(a, ar, 2, "float");

    lconstant to_r = [`N` `T` `C`], to_c = [`N` `T`], to_h = [`N` `C`];
    lvars trans_opts
        = func == "her2k" and to_h or realprec(prec) and to_r or to_c,
        trans_opt = checkstring(trans, trans_opts);

    unless trans_opt == `N` then (n, k) -> (k, n) endunless;

    lvars (bv, bi, ldb, mb, nb, _, _) = array_spec(b, br, 2, prec);
    unless trans_opt == `N` then (mb, nb) -> (nb, mb) endunless;
    unless mb == n and nb == k then
        mishap(a,ar,b,br, 4,
            'lapack: B dimensions not compatible with A')
    endunless;

    lvars (cv, ci, ldc, mc, nc, _, _) = array_spec(c, cr, 2, prec);
    unless mc == n and nc == n then
        mishap(a,ar,c,cr, 4,
            'lapack: C dimensions not compatible with A')
    endunless;

    define :inline lconstant
            EXTCALL(PROC=item, VEC=item, REF1=item, REF2=item);
        excall check=CHK PROC(
            FSTRING         uplo,
            FSTRING         trans,
            IREF            n,
            IREF            k,
            REF1            alpha,
            VEC             av[ai],
            IREF            lda,
            VEC             bv[bi],
            IREF            ldb,
            REF2            beta,
            VEC             cv[ci],
            IREF            ldc)
    enddefine;

    if func == "syr2k" then
        if prec == sfloat then
            EXTCALL(SSYR2K, SVEC, SREF, SREF)
        elseif prec == dfloat then
            EXTCALL(DSYR2K, DVEC, DREF, DREF)
        elseif prec == cfloat then
            EXTCALL(CSYR2K, CVEC, CREF, CREF)
        elseif prec == zfloat then
            EXTCALL(ZSYR2K, ZVEC, ZREF, ZREF)
        endif
    elseif func == "her2k" then
        if prec == cfloat then
            EXTCALL(CHER2K, CVEC, CREF, SREF) ;;; beta is real
        elseif prec == zfloat then
            EXTCALL(ZHER2K, ZVEC, ZREF, DREF)
        else
            mishap(0, 'lapack: xHER2K needs complex arguments')
        endif
    endif
enddefine;

define xSYR2K(/* uplo, trans, alpha, a, ar, b, br, beta, c, cr */)
        with_nargs 10;
    xSYR2K_HER2K("syr2k")
enddefine;

define xHER2K(/* uplo, trans, alpha, a, ar, b, br, beta, c, cr */)
        with_nargs 10;
    xSYR2K_HER2K("her2k")
enddefine;


/*
-- Interface routines - Lapack ----------------------------------------
*/


;;; Block size routine

define lconstant optblock(name, opt1, opt2, opt3, n1, n2, n3, n4)
        -> bsize ;
    lconstant opts = inits(3);
    (opt1, opt2, opt3) -> explode(opts);
    excall check=CHK int ILAENV(
        ICONST      1,      ;;; optimal blocksize
        FSTRING     name,
        FSTRING     opts,
        IREF        n1,
        IREF        n2,
        IREF        n3,
        IREF        n4) -> bsize;
    if bsize fi_<= 0 then
        mishap(bsize, 1, 'lapack: Illegal result from ILAENV')
    endif
enddefine;


;;; Auxiliary routines

define xLACGV(x, xr, incx);
    lvars (xv, xi, incx, n, prec)
    = array_spec_incr(x, xr, incx, "complex");

    define :inline lconstant EXTCALL(PROC=item, VEC=item);
        excall check=CHK PROC(
            IREF            n,
            VEC             xv[xi],
            IREF            incx)
    enddefine;

    if prec == cfloat then
        EXTCALL(CLACGV, CVEC)
    elseif prec == zfloat then
        EXTCALL(ZLACGV, ZVEC)
    endif
enddefine;


define xLACPY(uplo, a,ar, b,br);
    ;;; uplo can be any character in this unusual case
    unless uplo.isstring and not(uplo.isdstring) then
        mishap(uplo, 1, 'lapack: String (not dstring) expected')
    endunless;

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");

    lvars (bv, bi, ldb, bm, bn, _, _) = array_spec(b, br, 2, prec);
    unless bm == m and bn == n then
        mishap(b, br, m, n, 4, 'lapack: B wrong size')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item);
        excall check=CHK PROC(
            FSTRING         uplo,
            IREF            m,
            IREF            n,
            VEC             av[ai],
            IREF            lda,
            VEC             bv[bi],
            IREF            ldb);
    enddefine;

    if prec == sfloat then
        EXTCALL(SLACPY, SVEC)
    elseif prec == dfloat then
        EXTCALL(DLACPY, DVEC)
    elseif prec == cfloat then
        EXTCALL(CLACPY, CVEC)
    elseif prec == zfloat then
        EXTCALL(ZLACPY, ZVEC)
    endif
enddefine;


;;; Linear equations

define xGESV(a,ar, ipiv,ipivr, b,br);
    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    unless m == n then
        mishap(a,ar, 2, 'lapack: Expecting square array A')
    endunless;

    lvars (ipivv, ipivi, _, ipivn, _,_,_) = array_spec(ipiv, ipivr, 1, "int");
    unless ipivn == n then
        mishap(ipiv, ipivr, n, 3, 'lapack: IPIV wrong size')
    endunless;

    lvars (bv, bi, ldb, bm, nrhs, _, _) = array_spec(b, br, 2, prec);
    unless bm == n then
        mishap(b, br, n, 3, 'lapack: Wrong number of rows in B')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item);
        excall check=CHK PROC(
            IREF            n,
            IREF            nrhs,
            VEC             av[ai],
            IREF            lda,
            IVEC            ipivv[ipivi],
            VEC             bv[bi],
            IREF            ldb,
            IVCTR           info);
    enddefine;

    if prec == sfloat then
        EXTCALL(SGESV, SVEC)
    elseif prec == dfloat then
        EXTCALL(DGESV, DVEC)
    elseif prec == cfloat then
        EXTCALL(CGESV, CVEC)
    elseif prec == zfloat then
        EXTCALL(ZGESV, ZVEC)
    endif;
    check_error();
enddefine;


define lconstant xSYSV_HESV(uplo, a,ar, ipiv,ipivr, b,br, func);
    lvars uplo_opt = checkstring(uplo, uplo_opts);

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    unless m == n then
        mishap(a,ar, 2, 'lapack: Expecting square array A')
    endunless;

    lvars (ipivv, ipivi, _, ipivn, _,_,_) = array_spec(ipiv, ipivr, 1, "int");
    unless ipivn == n then
        mishap(ipiv, ipivr, n, 3, 'lapack: IPIV wrong size')
    endunless;

    lvars (bv, bi, ldb, bm, nrhs, _, _) = array_spec(b, br, 2, prec);
    unless bm == n then
        mishap(b, br, n, 3, 'lapack: Wrong number of rows in B')
    endunless;

    lconstant namess = fnames('_SYTRF'), namesh = fnames('_HETRF');
    lvars
        names = func == "sysv" and namess or namesh,
        nb = optblock(names(prec), uplo_opt,0,0, n, -1,-1,-1),
        lwork = n * nb, work = workfvec(ltag, [1 ^lwork], prec);

    define :inline lconstant EXTCALL(
            PROC=item, VEC=item, REF=item, VCTR=item);
        excall check=CHK PROC(
            FSTRING         uplo,
            IREF            n,
            IREF            nrhs,
            VEC             av[ai],
            IREF            lda,
            IVEC            ipivv[ipivi],
            VEC             bv[bi],
            IREF            ldb,
            VCTR            work,
            IREF            lwork,
            IVCTR           info)
    enddefine;

    if func == "sysv" then
        if prec == sfloat then
            EXTCALL(SSYSV, SVEC, SREF, SVCTR)
        elseif prec == dfloat then
            EXTCALL(DSYSV, DVEC, DREF, DVCTR)
        elseif prec == cfloat then
            EXTCALL(CSYSV, CVEC, CREF, CVCTR)
        elseif prec == zfloat then
            EXTCALL(ZSYSV, ZVEC, ZREF, ZVCTR)
        endif
    elseif func == "hesv" then
        if prec == cfloat then
            EXTCALL(CHESV, CVEC, CREF, CVCTR)
        elseif prec == zfloat then
            EXTCALL(ZHESV, ZVEC, ZREF, ZVCTR)
        else
            mishap(0, 'lapack: xHESV needs complex arguments')
        endif
    endif;
    check_error();
enddefine;

define xSYSV(/* uplo, a,ar, ipiv,ipivr, b,br */) with_nargs 7;
    xSYSV_HESV("sysv")
enddefine;

define xHESV(/* uplo, a,ar, ipiv,ipivr, b,br */) with_nargs 7;
    xSYSV_HESV("hesv")
enddefine;


define xPOSV(uplo, a,ar, b,br);
    checkstring(uplo, uplo_opts) -> ;

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    unless m == n then
        mishap(a,ar, 2, 'lapack: Expecting square array A')
    endunless;

    lvars (bv, bi, ldb, bm, nrhs, _, _) = array_spec(b, br, 2, prec);
    unless bm == n then
        mishap(b, br, n, 3, 'lapack: Wrong number of rows in B')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item, REF=item);
        excall check=CHK PROC(
            FSTRING         uplo,
            IREF            n,
            IREF            nrhs,
            VEC             av[ai],
            IREF            lda,
            VEC             bv[bi],
            IREF            ldb,
            IVCTR           info)
    enddefine;

    if prec == sfloat then
        EXTCALL(SPOSV, SVEC, SREF)
    elseif prec == dfloat then
        EXTCALL(DPOSV, DVEC, DREF)
    elseif prec == cfloat then
        EXTCALL(CPOSV, CVEC, CREF)
    elseif prec == zfloat then
        EXTCALL(ZPOSV, ZVEC, ZREF)
    endif;
    check_error();
enddefine;


define xGESVX(fact, trans, a,ar, af,afr, ipiv,ipivr, equed, r,rr,
        c,cr, b,br, x,xr, ferr,ferrr, berr,berrr) -> rcond;
    lconstant
        fact_opts = [`F` `N` `E`],
        trans_opts = [`N` `T` `C`],
        equed_opts = [`N` `R` `C` `B`];
    lvars
        fact_opt = checkstring(fact, fact_opts),
        trans_opt = checkstring(trans, trans_opts),
        equed_opt = fact_opt == `F` and checkstring(equed, equed_opts);

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    unless m == n then
        mishap(a,ar, 2, 'lapack: Expecting square array A')
    endunless;

    lvars rprec = singprec(prec) and sfloat or dfloat; ;;; for real args

    lvars (afv, afi, ldaf, afm, afn, _, _) = array_spec(af, afr, 2, prec);
    unless afm == n and afn == n then
        mishap(af, afr, n, 3,
            'lapack: Expecting square array AF same size as A')
    endunless;

    lvars (ipivv, ipivi, _, ipivn, _,_,_) = array_spec(ipiv, ipivr, 1, "int");
    unless ipivn == n then
        mishap(ipiv, ipivr, n, 3, 'lapack: IPIV wrong size')
    endunless;

    if fact_opt == `N`
    or (fact_opt == `F` and (equed_opt == `N` or equed_opt == `C`))
    then
        lvars (rv, ri) = dummyvec(rprec);
    else
        lvars (rv, ri, _, rn, _,_,_) = array_spec(r, rr, 1, rprec);
        unless rn == n then
            mishap(r, rr, n, 3, 'lapack: R wrong size')
        endunless
    endif;

    if fact_opt == `N`
    or (fact_opt == `F` and (equed_opt == `N` or equed_opt == `R`))
    then
        lvars (cv, ci) = dummyvec(rprec);
    else
        lvars (cv, ci, _, cn, _,_,_) = array_spec(c, cr, 1, rprec);
        unless cn == n then
            mishap(c, cr, n, 3, 'lapack: C wrong size')
        endunless
    endif;

    lvars (bv, bi, ldb, bm, nrhs, _, _) = array_spec(b, br, 2, prec);
    unless bm == n then
        mishap(b, br, n, 3, 'lapack: Wrong number of rows in B')
    endunless;

    lvars (xv, xi, ldx, xm, xn, _, _) = array_spec(x, xr, 2, prec);
    unless xm == n and xn == nrhs then
        mishap(x, xm, b, br, 4, 'lapack: X does not match size of B')
    endunless;

    0.0 -> rcond;

    lvars (ferrv, ferri, _, ferrn, _,_,_)
        = array_spec(ferr, ferrr, 1, rprec);
    unless ferrn == nrhs then
        mishap(ferr, ferrr, nrhs, 3, 'lapack: FERR wrong size')
    endunless;

    lvars (berrv, berri, _, berrn, _,_,_)
        = array_spec(berr, berrr, 1, rprec);
    unless berrn == nrhs then
        mishap(berr, berrr, nrhs, 3, 'lapack: BERR wrong size')
    endunless;

    lvars work, riwork;
    if prec == sfloat or prec == dfloat then
        workfvec(ltag, [1 ^(4*n)], prec) -> work;
        workivec(ltag, [1 ^n]) -> riwork;
    else
        workfvec(ltag, [1 ^(2*n)], prec) -> work;
        workfvec(ltag, [1 ^(2*n)], rprec) -> riwork;
    endif;

    define :inline lconstant EXTCALL(PROC=item, VEC1=item, VEC2=item,
            REF=item, VCTR1=item, VCTR2=item);
        excall check=CHK PROC(
            FSTRING         fact,
            FSTRING         trans,
            IREF            n,
            IREF            nrhs,
            VEC1            av[ai],
            IREF            lda,
            VEC1            afv[afi],
            IREF            ldaf,
            IVEC            ipivv[ipivi],
            FSTRING         equed,
            VEC2            rv[ri],
            VEC2            cv[ci],
            VEC1            bv[bi],
            IREF            ldb,
            VEC1            xv[xi],
            IREF            ldx,
            REF             rcond,
            VEC2            ferrv[ferri],
            VEC2            berrv[berri],
            VCTR1           work,
            VCTR2           riwork,
            IVCTR           info)
    enddefine;

    if prec == sfloat then
        EXTCALL(SGESVX, SVEC, SVEC, SREF, SVCTR, IVCTR)
    elseif prec == dfloat then
        EXTCALL(DGESVX, DVEC, DVEC, DREF, DVCTR, IVCTR)
    elseif prec == cfloat then
        EXTCALL(CGESVX, CVEC, SVEC, SREF, CVCTR, SVCTR)
    elseif prec == zfloat then
        EXTCALL(ZGESVX, ZVEC, DVEC, DREF, ZVCTR, DVCTR)
    endif;
    check_error();
enddefine;


define lconstant xSYSVX_HESVX(fact, uplo, a,ar, af,afr, ipiv,ipivr,
        b,br, x,xr, ferr,ferrr, berr,berrr, func) -> rcond;
    lconstant fact_opts = [`F` `N`];
    lvars
        fact_opt = checkstring(fact, fact_opts),
        uplo_opt = checkstring(uplo, uplo_opts);

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    unless m == n then
        mishap(a,ar, 2, 'lapack: Expecting square array A')
    endunless;

    lvars rprec = singprec(prec) and sfloat or dfloat; ;;; for real args

    lvars (afv, afi, ldaf, afm, afn, _, _) = array_spec(af, afr, 2, prec);
    unless afm == n and afn == n then
        mishap(af, afr, n, 3,
            'lapack: Expecting square array AF same size as A')
    endunless;

    lvars (ipivv, ipivi, _, ipivn, _,_,_) = array_spec(ipiv, ipivr, 1, "int");
    unless ipivn == n then
        mishap(ipiv, ipivr, n, 3, 'lapack: IPIV wrong size')
    endunless;

    lvars (bv, bi, ldb, bm, nrhs, _, _) = array_spec(b, br, 2, prec);
    unless bm == n then
        mishap(b, br, n, 3, 'lapack: Wrong number of rows in B')
    endunless;

    lvars (xv, xi, ldx, xm, xn, _, _) = array_spec(x, xr, 2, prec);
    unless xm == n and xn == nrhs then
        mishap(x, xm, b, br, 4, 'lapack: X does not match size of B')
    endunless;

    0.0 -> rcond;

    lvars (ferrv, ferri, _, ferrn, _,_,_) = array_spec(ferr, ferrr, 1, rprec);
    unless ferrn == nrhs then
        mishap(ferr, ferrr, nrhs, 3, 'lapack: FERR wrong size')
    endunless;

    lvars (berrv, berri, _, berrn, _,_,_) = array_spec(berr, berrr, 1, rprec);
    unless berrn == nrhs then
        mishap(berr, berrr, nrhs, 3, 'lapack: BERR wrong size')
    endunless;

    lconstant namess = fnames('_SYTRF'), namesh = fnames('_HETRF');
    lvars work, lwork, riwork,
        names = func == "sysvx" and namess or namesh,
        nb = optblock(names(prec), fact_opt, uplo_opt, 0, n, -1, -1, -1);
    if realprec(prec) then
        n * max(3, nb) -> lwork;
        workivec(ltag, [1 ^n]) -> riwork;
    else
        n * max(2, nb) -> lwork;
        workfvec(ltag, [1 ^n], rprec) -> riwork;
    endif;
    workfvec(ltag, [1 ^lwork], prec) -> work;

    define :inline lconstant EXTCALL(
            PROC=item, VEC1=item, VEC2=item, REF=item, VCTR1=item, VCTR2=item);
        excall check=CHK PROC(
            FSTRING         fact,
            FSTRING         uplo,
            IREF            n,
            IREF            nrhs,
            VEC1            av[ai],
            IREF            lda,
            VEC1            afv[afi],
            IREF            ldaf,
            IVEC            ipivv[ipivi],
            VEC1            bv[bi],
            IREF            ldb,
            VEC1            xv[xi],
            IREF            ldx,
            REF             rcond,
            VEC2            ferrv[ferri],
            VEC2            berrv[berri],
            VCTR1           work,
            IREF            lwork,
            VCTR2           riwork,
            IVCTR           info)
    enddefine;

    if func == "sysvx" then
        if prec == sfloat then
            EXTCALL(SSYSVX, SVEC, SVEC, SREF, SVCTR, IVCTR)
        elseif prec == dfloat then
            EXTCALL(DSYSVX, DVEC, DVEC, DREF, DVCTR, IVCTR)
        elseif prec == cfloat then
            EXTCALL(CSYSVX, CVEC, SVEC, SREF, CVCTR, SVCTR)
        elseif prec == zfloat then
            EXTCALL(ZSYSVX, ZVEC, DVEC, DREF, ZVCTR, DVCTR)
        endif
    elseif func == "hesvx" then
        if prec == cfloat then
            EXTCALL(CHESVX, CVEC, SVEC, SREF, CVCTR, SVCTR)
        elseif prec == zfloat then
            EXTCALL(ZHESVX, ZVEC, DVEC, DREF, ZVCTR, DVCTR)
        else
            mishap(0, 'lapack: xHESVX needs complex arguments')
        endif
    endif;
    check_error();
enddefine;

define xSYSVX(/* fact, uplo, a,ar, af,afr, ipiv,ipivr,
    b,br, x,xr, ferr,ferrr, berr,berrr */) /* -> rcond */ with_nargs 16;
    xSYSVX_HESVX("sysvx")
enddefine;

define xHESVX(/* fact, uplo, a,ar, af,afr, ipiv,ipivr,
    b,br, x,xr, ferr,ferrr, berr,berrr */) /* -> rcond */ with_nargs 16;
    xSYSVX_HESVX("hesvx")
enddefine;


define xPOSVX(fact, uplo, a,ar, af,afr, equed, s,sr,
        b,br, x,xr, ferr,ferrr, berr,berrr) -> rcond;
    lconstant
        fact_opts = [`F` `N` `E`],
        equed_opts = [`N` `Y`];
    lvars
        fact_opt = checkstring(fact, fact_opts),
        equed_opt = checkstring(equed, equed_opts);
    checkstring(uplo, uplo_opts) -> ;

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    unless m == n then
        mishap(a,ar, 2, 'lapack: Expecting square array A')
    endunless;

    lvars rprec = singprec(prec) and sfloat or dfloat; ;;; for real args

    lvars (afv, afi, ldaf, afm, afn, _, _) = array_spec(af, afr, 2, prec);
    unless afm == n and afn == n then
        mishap(af, afr, n, 3,
            'lapack: Expecting square array AF same size as A')
    endunless;

    if equed_opt == `N` then
        lvars (sv, si) = dummyvec(rprec);
    else
        lvars (sv, si, _, sn, _,_,_) = array_spec(s, sr, 1, rprec);
        unless sn == n then
            mishap(s, sr, n, 3, 'lapack: S wrong size')
        endunless
    endif;

    lvars (bv, bi, ldb, bm, nrhs, _, _) = array_spec(b, br, 2, prec);
    unless bm == n then
        mishap(b, br, n, 3, 'lapack: Wrong number of rows in B')
    endunless;

    lvars (xv, xi, ldx, xm, xn, _, _) = array_spec(x, xr, 2, prec);
    unless xm == n and xn == nrhs then
        mishap(x, xm, b, br, 4, 'lapack: X does not match size of B')
    endunless;

    0.0 -> rcond;

    lvars (ferrv, ferri, _, ferrn, _,_,_)
        = array_spec(ferr, ferrr, 1, rprec);
    unless ferrn == nrhs then
        mishap(ferr, ferrr, nrhs, 3, 'lapack: FERR wrong size')
    endunless;

    lvars (berrv, berri, _, berrn, _,_,_)
        = array_spec(berr, berrr, 1, rprec);
    unless berrn == nrhs then
        mishap(berr, berrr, nrhs, 3, 'lapack: BERR wrong size')
    endunless;

    lvars work, riwork;
    if prec == sfloat or prec == dfloat then
        workfvec(ltag, [1 ^(3*n)], prec) -> work;
        workivec(ltag, [1 ^n]) -> riwork;
    else
        workfvec(ltag, [1 ^(2*n)], prec) -> work;
        workfvec(ltag, [1 ^n], rprec) -> riwork;
    endif;

    define :inline lconstant EXTCALL(PROC=item, VEC1=item, VEC2=item,
            REF=item, VCTR1=item, VCTR2=item);
        excall check=CHK PROC(
            FSTRING         fact,
            FSTRING         uplo,
            IREF            n,
            IREF            nrhs,
            VEC1            av[ai],
            IREF            lda,
            VEC1            afv[afi],
            IREF            ldaf,
            FSTRING         equed,
            VEC2            sv[si],
            VEC1            bv[bi],
            IREF            ldb,
            VEC1            xv[xi],
            IREF            ldx,
            REF             rcond,
            VEC2            ferrv[ferri],
            VEC2            berrv[berri],
            VCTR1           work,
            VCTR2           riwork,
            IVCTR           info)
    enddefine;

    if prec == sfloat then
        EXTCALL(SPOSVX, SVEC, SVEC, SREF, SVCTR, IVCTR)
    elseif prec == dfloat then
        EXTCALL(DPOSVX, DVEC, DVEC, DREF, DVCTR, IVCTR)
    elseif prec == cfloat then
        EXTCALL(CPOSVX, CVEC, SVEC, SREF, CVCTR, SVCTR)
    elseif prec == zfloat then
        EXTCALL(ZPOSVX, ZVEC, DVEC, DREF, ZVCTR, DVCTR)
    endif;
    check_error();
enddefine;


;;; Least-squares problems


define xGELS(trans, a,ar, b,br);
    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");

    lconstant trans_opts_r = [`N` `T`], trans_opts_c = [`N` `C`];
    if realprec(prec) then
        lvars trans_opt = checkstring(trans, trans_opts_r);
    else
        lvars trans_opt = checkstring(trans, trans_opts_c);
    endif;

    lvars (bv, bi, ldb, bm, nrhs, _, _) = array_spec(b, br, 2, prec);
    unless bm == max(m,n) then
        mishap(b, br, a, ar, 4,
            'lapack: Expecting no. rows of B to be max dimension of A')
    endunless;

    lconstant names = fnames('_GELS');
    lvars nb = optblock(names(prec), trans_opt,0,0, m,n,nrhs,-1);
    lvars
        lwork = min(m, n) + nb * max(1, max(m, max(n, nrhs))),
        work = workfvec(ltag, [1 ^lwork], prec);

    define :inline lconstant EXTCALL(
            PROC=item, VEC=item, REF=item, VCTR=item);
        excall check=CHK PROC(
            FSTRING         trans,
            IREF            m,
            IREF            n,
            IREF            nrhs,
            VEC             av[ai],
            IREF            lda,
            VEC             bv[bi],
            IREF            ldb,
            VCTR            work,
            IREF            lwork,
            IVCTR           info)
    enddefine;

    if prec == sfloat then
        EXTCALL(SGELS, SVEC, SREF, SVCTR)
    elseif prec == dfloat then
        EXTCALL(DGELS, DVEC, DREF, DVCTR)
    elseif prec == cfloat then
        EXTCALL(CGELS, CVEC, CREF, CVCTR)
    elseif prec == zfloat then
        EXTCALL(ZGELS, ZVEC, ZREF, ZVCTR)
    endif;
    check_error();
enddefine;


define xGELSX(a,ar, b,br, jpvt,jpvtr, rcond) -> rank;
    ;;; This is for Lapack 2.0. Should include xGELSY if later Lapack
    ;;; available, as it is faster.

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");

    lvars (bv, bi, ldb, bm, nrhs, _, _) = array_spec(b, br, 2, prec);
    unless bm == max(m,n) then
        mishap(b, br, a, ar, 4,
            'lapack: Expecting no. rows of B to be max dimension of A')
    endunless;

    lvars (jpvtv, jpvti, _, jpvtn,_,_,_) = array_spec(jpvt, jpvtr, 1, "int");
    unless jpvtn == n then
        mishap(jpvt, jpvtr, n, 3, 'lapack: JPVT wrong size')
    endunless;

    0 -> rank;

    if realprec(prec) then
        lvars work = workfvec(ltag,
            [1 ^(max(min(m,n)+3*n, 2*min(m,n)+nrhs))], prec);
    else
        lvars
            work = workfvec(ltag,
            [1 ^(min(m,n) + max(n, 2*min(m,n)+nrhs))], prec),
            rprec = prec == cfloat and sfloat or dfloat,
            rwork = workfvec(ltag, [1 ^(2*n)], rprec);
    endif;

    define :inline lconstant EXTCALL(
            PROC=item, VEC=item, REF=item, VCTR1=item, VCTR2=item);
        excall check=CHK PROC(
            IREF            m,
            IREF            n,
            IREF            nrhs,
            VEC             av[ai],
            IREF            lda,
            VEC             bv[bi],
            IREF            ldb,
            IVEC            jpvtv[jpvti],
            REF             rcond,
            IREF            rank,
            VCTR1           work,
            VCTR2           rwork,
            IVCTR           info)
    enddefine;

    if prec == sfloat then
        EXTCALL(SGELSX, SVEC, SREF, SVCTR, VOID)
    elseif prec == dfloat then
        EXTCALL(DGELSX, DVEC, DREF, DVCTR, VOID)
    elseif prec == cfloat then
        EXTCALL(CGELSX, CVEC, SREF, CVCTR, SVCTR)
    elseif prec == zfloat then
        EXTCALL(ZGELSX, ZVEC, DREF, ZVCTR, DVCTR)
    endif;
    check_error();
enddefine;


define xGELSS(a,ar, b,br, s,sr, rcond) -> rank;
    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    dlvars minmn = min(m, n), maxmn = max(m,n);

    lvars rprec = singprec(prec) and sfloat or dfloat; ;;; for real args

    lvars (bv, bi, ldb, bm, nrhs, _, _) = array_spec(b, br, 2, prec);
    unless bm == maxmn then
        mishap(b, br, maxmn, 3,
            'lapack: Expecting no. rows of B to be max dimension of A')
    endunless;

    lvars (sv, si, _, sn, _,_,_) = array_spec(s, sr, 1, rprec);
    unless sn == minmn then
        mishap(s, sr, minmn, 3, 'lapack: S wrong size')
    endunless;

    0 -> rank;

    define lconstant lworkdef(prec, m, n, nrhs);
        if realprec(prec) then
            3*minmn + max(nrhs, max(2*minmn, maxmn))
        else
            2*minmn + max(nrhs, max(m, n))
        endif
    enddefine;
    lconstant lworks = newanysparse(4, lworkdef, apply);
    lvars
        lwork = lworks(prec, m, n, nrhs),
        work = workfvec(ltag, [1 ^lwork], prec);
    if compprec(prec) then
        lvars rwork = workfvec(ltag, [1 ^(5*minmn-1)], rprec);
    endif;

    define :inline lconstant EXTCALL(
            PROC=item, VEC1=item, VEC2=item, REF=item, VCTR1=item, VCTR2=item);
        excall check=CHK PROC(
            IREF            m,
            IREF            n,
            IREF            nrhs,
            VEC1            av[ai],
            IREF            lda,
            VEC1            bv[bi],
            IREF            ldb,
            VEC2            sv[si],
            REF             rcond,
            IREF            rank,
            VCTR1           work,
            IREF            lwork,
            VCTR2           rwork,
            IVCTR           info)
    enddefine;

    if prec == sfloat then
        EXTCALL(SGELSS, SVEC, SVEC, SREF, SVCTR, VOID)
    elseif prec == dfloat then
        EXTCALL(DGELSS, DVEC, DVEC, DREF, DVCTR, VOID)
    elseif prec == cfloat then
        EXTCALL(CGELSS, CVEC, SVEC, SREF, CVCTR, SVCTR)
    elseif prec == zfloat then
        EXTCALL(ZGELSS, ZVEC, DVEC, DREF, ZVCTR, DVCTR)
    endif;

    check_error();
    round(realpart(work(1))) -> lworks(prec, m, n, nrhs);
enddefine;


;;; Generalised linear least-squares


define xGGLSE(a,ar, b,br, c,cr, d,dr, x,xr);
    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");

    lvars (bv, bi, ldb, p, bn, _, _) = array_spec(b, br, 2, prec);
    unless bn == n then
        mishap(b, br, n, 3,
            'lapack: B has different number of columns to A')
    endunless;
    unless p <= n and n <= m+p then
        mishap(b, br, m, n, 4,
            'lapack: B has incorrect number of rows')
    endunless;

    lvars (cv, ci, _, cn, _,_,_) = array_spec(c, cr, 1, prec);
    unless cn == m then
        mishap(c, cr, m, 3, 'lapack: C wrong size')
    endunless;

    lvars (dv, di, _, dn, _,_,_) = array_spec(d, dr, 1, prec);
    unless dn == p then
        mishap(d, dr, p, 3, 'lapack: D wrong size')
    endunless;

    lvars (xv, xi, _, xn, _,_,_) = array_spec(x, xr, 1, prec);
    unless xn == n then
        mishap(x, xr, n, 3, 'lapack: X wrong size')
    endunless;

    define lconstant lworkdef(prec, m, n, p);
        max(1, m+n+p)
    enddefine;
    lconstant lworks = newanysparse(4, lworkdef, apply);
    lvars
        lwork = lworks(prec, m, n, p),
        work = workfvec(ltag, [1 ^lwork], prec);

    define :inline lconstant EXTCALL(PROC=item, VEC=item, VCTR=item);
        excall check=CHK PROC(
            IREF            m,
            IREF            n,
            IREF            p,
            VEC             av[ai],
            IREF            lda,
            VEC             bv[bi],
            IREF            ldb,
            VEC             cv[ci],
            VEC             dv[di],
            VEC             xv[xi],
            VCTR            work,
            IREF            lwork,
            IVCTR           info);
    enddefine;

    if prec == sfloat then
        EXTCALL(SGGLSE, SVEC, SVCTR)
    elseif prec == dfloat then
        EXTCALL(DGGLSE, DVEC, DVCTR)
    elseif prec == cfloat then
        EXTCALL(CGGLSE, CVEC, CVCTR)
    elseif prec == zfloat then
        EXTCALL(ZGGLSE, ZVEC, ZVCTR)
    endif;
    check_error();
    round(realpart(work(1))) -> lworks(prec, m, n, p);
enddefine;


define xGGGLM(a,ar, b,br, d,dr, x,xr, y,yr);
    lvars (av, ai, lda, n, m, _, prec) = array_spec(a, ar, 2, "float");
    unless m <= n then
        mishap(a, ar, 2, 'lapack: A must have no more columns than rows')
    endunless;

    lvars (bv, bi, ldb, bn, p, _, _) = array_spec(b, br, 2, prec);
    unless bn == n then
        mishap(b, br, n, 3,
            'lapack: B has different number of rows to A')
    endunless;
    unless p >= n-m then
        mishap(b, br, m, n, 4, 'lapack: B has too few columns')
    endunless;

    lvars (dv, di, _, dn, _,_,_) = array_spec(d, dr, 1, prec);
    unless dn == n then
        mishap(d, dr, n, 3, 'lapack: D wrong size')
    endunless;

    lvars (xv, xi, _, xn, _,_,_) = array_spec(x, xr, 1, prec);
    unless xn == m then
        mishap(x, xr, n, 3, 'lapack: X wrong size')
    endunless;

    lvars (yv, yi, _, yn, _,_,_) = array_spec(y, yr, 1, prec);
    unless yn == p then
        mishap(y, yr, n, 3, 'lapack: Y wrong size')
    endunless;

    define lconstant lworkdef(prec, m, n, p);
        max(1, m+n+p)
    enddefine;
    lconstant lworks = newanysparse(4, lworkdef, apply);
    lvars
        lwork = lworks(prec, m, n, p),
        work = workfvec(ltag, [1 ^lwork], prec);

    define :inline lconstant EXTCALL(PROC=item, VEC=item, VCTR=item);
        excall check=CHK PROC(
            IREF            n,
            IREF            m,
            IREF            p,
            VEC             av[ai],
            IREF            lda,
            VEC             bv[bi],
            IREF            ldb,
            VEC             dv[di],
            VEC             xv[xi],
            VEC             yv[yi],
            VCTR            work,
            IREF            lwork,
            IVCTR           info)
    enddefine;

    if prec == sfloat then
        EXTCALL(SGGGLM, SVEC, SVCTR)
    elseif prec == dfloat then
        EXTCALL(DGGGLM, DVEC, DVCTR)
    elseif prec == cfloat then
        EXTCALL(CGGGLM, CVEC, CVCTR)
    elseif prec == zfloat then
        EXTCALL(ZGGGLM, ZVEC, ZVCTR)
    endif;
    check_error();
    round(realpart(work(1))) -> lworks(prec, m, n, p);
enddefine;


;;; Eigenvalue problems


define lconstant xSYEV_HEEV(jobz, uplo, a, ar, w, wr, func);
    lconstant jobz_opts = [`N` `V`];
    checkstring(jobz, jobz_opts) -> ;
    lvars uplo_opt = checkstring(uplo, uplo_opts);

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    unless m == n then
        mishap(a, ar, 2, 'lapack: Expecting square array A')
    endunless;

    lvars rprec = singprec(prec) and sfloat or dfloat; ;;; for real args

    lvars (wv, wi, _, wn, _, _, _) = array_spec(w, wr, 1, rprec);
    unless wn == n then
        mishap(w, wr, n, 3, 'lapack: W wrong size for eigenvalues')
    endunless;

    lconstant names = fsynames('_SYTRD');
    lvars nb = optblock(names(prec), uplo_opt,0,0, n, -1,-1,-1);
    if func == "syev" then
        lvars
            lwork = max(max(1, 3*n-1), n*(nb+2)),
            work = workfvec(ltag, [1 ^lwork], prec);
    else
        lvars
            lwork = max(max(1, 2*n-1), n*(nb+1)),
            work = workfvec(ltag, [1 ^lwork], prec),
            rwork = workfvec(ltag, [1 ^(max(1, 3*n-2))], rprec);
    endif;

    define :inline lconstant EXTCALL(
            PROC=item, VEC1=item, VEC2=item, VCTR1=item, VCTR2=item);
        excall check=CHK PROC(
            FSTRING         jobz,
            FSTRING         uplo,
            IREF            n,
            VEC1            av[ai],
            IREF            lda,
            VEC2            wv[wi],
            VCTR1           work,
            IREF            lwork,
            VCTR2           rwork,
            IVCTR           info)
    enddefine;

    if func == "syev" then
        if prec == sfloat then
            EXTCALL(SSYEV, SVEC, SVEC, SVCTR, VOID)
        elseif prec == dfloat then
            EXTCALL(DSYEV, DVEC, DVEC, DVCTR, VOID)
        else
            mishap(0, 'lapack: xSYEV needs real arguments')
        endif
    elseif func == "heev" then
        if prec == cfloat then
            EXTCALL(CHEEV, CVEC, SVEC, CVCTR, SVCTR)
        elseif prec == zfloat then
            EXTCALL(ZHEEV, ZVEC, DVEC, ZVCTR, DVCTR)
        else
            mishap(0, 'lapack: xHEEV needs complex arguments')
        endif
    endif;
    check_error()
enddefine;

define xSYEV(/* jobz, uplo, a, ar, w, wr */) with_nargs 6;
    xSYEV_HEEV("syev")
enddefine;

define xHEEV(/* jobz, uplo, a, ar, w, wr */) with_nargs 6;
    xSYEV_HEEV("heev")
enddefine;


define lconstant xSYEVD_HEEVD(jobz, uplo, a, ar, w, wr, func);
    lconstant jobz_opts = [`N` `V`];
    lvars jobz_opt = checkstring(jobz, jobz_opts);
    checkstring(uplo, uplo_opts) -> ;

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    unless m == n then
        mishap(a, ar, 2, 'lapack: Expecting square array A')
    endunless;

    lvars rprec = singprec(prec) and sfloat or dfloat; ;;; for real args

    lvars (wv, wi, _, wn, _, _, _) = array_spec(w, wr, 1, rprec);
    unless wn == n then
        mishap(w, wr, n, 3, 'lapack: W wrong size for eigenvalues')
    endunless;

    ;;; Get work arrays
    if func == "syevd" then
        lvars lwork, work, liwork, iwork;
        if jobz_opt == `N` then
            2*n + 1 -> lwork;
            1 -> liwork
        else
            lvars lgn = 1, twok = 2;
            until twok >= n do
                lgn fi_+ 1 -> lgn;
                2 fi_* twok -> twok
            enduntil;
            1 + 5*n + 2*n*lgn + 3*n*n -> lwork;
            3 + 5*n -> liwork       ;;; compatible with Lapack 3.0
        endif;

        workfvec(ltag, [1 ^lwork], prec) -> work;
        workivec(ltag, [1 ^liwork]) -> iwork;
    else
        lvars lwork, work, lrwork, rwork, liwork, iwork;
        if jobz_opt == `N` then
            n + 1 -> lwork;
            max(1, n) -> lrwork;
            1 -> liwork
        else
            max(1, 2*n + n*n) -> lwork;
            lvars lgn = 1, twok = 2;
            until twok >= n do
                lgn fi_+ 1 -> lgn;
                2 fi_* twok -> twok
            enduntil;
            1 + 4*n * 2*n*lgn + 3*n*n -> lrwork;
            3 + 5*n -> liwork       ;;; compatible with Lapack 3.0
        endif;

        workfvec(ltag, [1 ^lwork], prec) -> work;
        workfvec(ltag, [1 ^lrwork], rprec) -> rwork;
        workivec(ltag, [1 ^liwork]) -> iwork;
    endif;

    define :inline lconstant EXTCALL(
            PROC=item, VEC1=item, VEC2=item,
            VCTR1=item, VCTR2=item, IREF2=item);
        excall check=CHK PROC(
            FSTRING         jobz,
            FSTRING         uplo,
            IREF            n,
            VEC1            av[ai],
            IREF            lda,
            VEC2            wv[wi],
            VCTR1           work,
            IREF            lwork,
            VCTR2           rwork,
            IREF2           lrwork,
            IVCTR           iwork,
            IREF            liwork,
            IVCTR           info)
    enddefine;

    if func == "syevd" then
        if prec == sfloat then
            EXTCALL(SSYEVD, SVEC, SVEC, SVCTR, VOID, VOID)
        elseif prec == dfloat then
            EXTCALL(DSYEVD, DVEC, DVEC, DVCTR, VOID, VOID)
        else
            mishap(0, 'lapack: xSYEVD needs real arguments')
        endif
    elseif func == "heevd" then
        if prec == cfloat then
            EXTCALL(CHEEVD, CVEC, SVEC, CVCTR, SVCTR, IREF)
        elseif prec == zfloat then
            EXTCALL(ZHEEVD, ZVEC, DVEC, ZVCTR, DVCTR, IREF)
        else
            mishap(0, 'lapack: xHEEVD needs complex arguments')
        endif
    endif;
    check_error()
enddefine;

define xSYEVD(/* jobz, uplo, a, ar, w, wr */) with_nargs 6;
    xSYEVD_HEEVD("syevd")
enddefine;

define xHEEVD(/* jobz, uplo, a, ar, w, wr */) with_nargs 6;
    xSYEVD_HEEVD("heevd")
enddefine;


define lconstant xSYEVX_HEEVX(jobz, range, uplo, a,ar, vl,vu, il,iu,
        abstol, w,wr, z,zr, ifail,ifailr, func) -> m;
    lconstant
        jobz_opts = [`N` `V`],
        range_opts = [`A` `V` `I`];
    lvars
        jobz_opt = checkstring(jobz, jobz_opts),
        range_opt = checkstring(range, range_opts),
        uplo_opt = checkstring(uplo, uplo_opts);

    lvars (av, ai, lda, am, n, _, prec) = array_spec(a, ar, 2, "float");
    unless am == n then
        mishap(a, ar, 2, 'lapack: Expecting square array A')
    endunless;

    lvars rprec = singprec(prec) and sfloat or dfloat; ;;; for real args

    if range_opt == `V` then
        unless vl < vu then
            mishap(vl, vu, 2, 'lapack: VL must be less than VU')
        endunless;
        n -> m;         ;;; max no. of eigenvals to find
    elseif range_opt == `I` then
        fi_check(il, 1, false) -> _;
        fi_check(iu, il, n) -> _;
        iu fi_- il fi_+ 1 -> m;
    else   ;;; == A
        n -> m;
    endif;

    lvars (wv, wi, _, wn, _, _, _) = array_spec(w, wr, 1, rprec);
    unless wn == n then
        mishap(w, wr, n, 3, 'lapack: W wrong size for eigenvalues')
    endunless;

    if jobz_opt == `N` then
        lvars (zv, zi) = dummyvec(prec);
    else
        lvars (zv, zi, ldz, zm, zn, _, _) = array_spec(z, zr, 2, prec);
        unless zm == n and zn == m then
            mishap(z, zr, n, m, 4, 'lapack: Z wrong size')
        endunless
    endif;

    lconstant names = fsynames('_SYTRD');
    lvars nb = optblock(names(prec), uplo_opt,0,0, n, -1,-1,-1);
    if func == "syevx" then
        lvars lwork = max(1, max(8, nb+3) * n);
    else
        lvars
            lwork = max(1, n*(nb+1)),
            rwork = workfvec(ltag, [1 ^(7*n)], rprec);
    endif;
    lvars
        work = workfvec(ltag, [1 ^lwork], prec),
        iwork = workivec(ltag, [1 ^(5*n)]);

    if jobz_opt == `N` then
        lvars (ifailv, ifaili) = dummyvec(prec);
    else
        lvars (ifailv, ifaili, _, ifailn, _, _, _)
            = array_spec(ifail, ifailr, 1, "int");
        unless ifailn == n then
            mishap(ifail, ifailr, n, 3, 'lapack: IFAIL wrong length')
        endunless
    endif;

    define :inline lconstant EXTCALL(
            PROC=item, VEC1=item, VEC2=item, REF=item, VCTR1=item, VCTR2=item);
        excall check=CHK PROC(
            FSTRING         jobz,
            FSTRING         range,
            FSTRING         uplo,
            IREF            n,
            VEC1            av[ai],
            IREF            lda,
            REF             vl,
            REF             vu,
            IREF            il,
            IREF            iu,
            REF             abstol,
            IREF            m,
            VEC2            wv[wi],
            VEC1            zv[zi],
            IREF            ldz,
            VCTR1           work,
            IREF            lwork,
            VCTR2           rwork,
            IVCTR           iwork,
            IVEC            ifailv[ifaili],
            IVCTR           info)
    enddefine;

    if func == "syevx" then
        if prec == sfloat then
            EXTCALL(SSYEVX, SVEC, SVEC, SREF, SVCTR, VOID)
        elseif prec == dfloat then
            EXTCALL(DSYEVX, DVEC, DVEC, DREF, DVCTR, VOID)
        else
            mishap(0, 'lapack: xSYEVX needs real arguments')
        endif
    elseif func == "heevx" then
        if prec == cfloat then
            EXTCALL(CHEEVX, CVEC, SVEC, SREF, CVCTR, SVCTR)
        elseif prec == zfloat then
            EXTCALL(ZHEEVX, ZVEC, DVEC, DREF, ZVCTR, DVCTR)
        else
            mishap(0, 'lapack: xHEEVX needs complex arguments')
        endif
    endif;
    check_error()
enddefine;

define xSYEVX(/* jobz, range, uplo, a,ar, vl,vu, il,iu,
abstol, w,wr, z,zr, ifail,ifailr */) /* -> m */
        with_nargs 16;
    xSYEVX_HEEVX("syevx")
enddefine;

define xHEEVX(/* jobz, range, uplo, a,ar, vl,vu, il,iu,
abstol, w,wr, z,zr, ifail,ifailr */) /* -> m */
        with_nargs 16;
    xSYEVX_HEEVX("heevx")
enddefine;


define xGEEV(jobvl, jobvr, a,ar, w,wr, vl,vlr, vr,vrr);
    /* Alternative form:
    define xGEEV(jobvl, jobvr, a,ar, wr,wrr, wi,wir, vl,vlr, vr,vrr);
    */
    lvars iw, iwr=false;
    unless jobvr.isstring then   ;;; have arguments for real case
        (jobvl,jobvr,a,ar,w,wr) -> (jobvl,jobvr,a,ar,w,wr,iw,iwr)
    endunless;

    lconstant jobv_opts = [`N` `V`];
    lvars
        jobvl_opt = checkstring(jobvl, jobv_opts),
        jobvr_opt = checkstring(jobvr, jobv_opts);

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    unless m == n then
        mishap(a, ar, 2, 'lapack: Expecting square array A')
    endunless;

    lvars rprec = singprec(prec) and sfloat or dfloat; ;;; for real args

    lvars (wv, wi, _, wn, _, _, _) = array_spec(w, wr, 1, prec);
    if iwr then
        unless realprec(prec) then
            mishap(0, 'lapack: Expecting real arguments')
        endunless;
        unless wn == n then
            mishap(w, wr, n, 3, 'lapack: WR wrong size')
        endunless;
        lvars (iwv, iwi, _, iwn, _, _, _) = array_spec(iw, iwr, 1, prec);
        unless iwn == n then
            mishap(iw, iwr, n, 3, 'lapack: WI wrong size')
        endunless;
    else
        unless compprec(prec) then
            mishap(0, 'lapack: Expecting complex arguments')
        endunless;
        unless wn == n then
            mishap(w, wr, n, 3, 'lapack: W wrong size')
        endunless;
    endif;

    if jobvl_opt == `N` then
        lvars (vlv, vli) = dummyvec(prec), ldvl = 1;
    else
        lvars (vlv, vli, ldvl, vlm, vln, _, _) = array_spec(vl, vlr, 2, prec);
        unless vlm == n and vln == n then
            mishap(vl, vlr, n, 3, 'lapack: VL wrong size')
        endunless
    endif;

    if jobvr_opt == `N` then
        lvars (vrv, vri) = dummyvec(prec), ldvr = 1;
    else
        lvars (vrv, vri, ldvr, vrm, vrn, _, _) = array_spec(vr, vrr, 2, prec);
        unless vrm == n and vrn == n then
            mishap(vr, vrr, n, 3, 'lapack: VL wrong size')
        endunless
    endif;

    define lconstant lworkdef(prec, n);
        if realprec(prec) then
            max(1, 4*n)
        else
            max(1, 2*n)
        endif
    enddefine;
    lconstant lworks = newanysparse(2, lworkdef, apply);
    lvars
        lwork = lworks(prec, n),
        work = workfvec(ltag, [1 ^lwork], prec);
    if compprec(prec) then
        lvars rwork = workfvec(ltag, [1 ^(2*n)], rprec);
    endif;

    define :inline lconstant EXTCALL(
            PROC=item, VEC1=item, VEC2=item, VCTR1=item, VCTR2=item);
        excall check=CHK PROC(
            FSTRING         jobvl,
            FSTRING         jobvr,
            IREF            n,
            VEC1            av[ai],
            IREF            lda,
            VEC1            wv[wi],
            VEC2            iwv[iwi],
            VEC1            vlv[vli],
            IREF            ldvl,
            VEC1            vrv[vri],
            IREF            ldvr,
            VCTR1           work,
            IREF            lwork,
            VCTR2           rwork,
            IVCTR           info)
    enddefine;

    if prec == sfloat then
        EXTCALL(SGEEV, SVEC, SVEC, SVCTR, VOID)
    elseif prec == dfloat then
        EXTCALL(DGEEV, DVEC, DVEC, DVCTR, VOID)
    elseif prec == cfloat then
        EXTCALL(CGEEV, CVEC, VOID, CVCTR, SVCTR)
    elseif prec == zfloat then
        EXTCALL(ZGEEV, ZVEC, VOID, ZVCTR, DVCTR)
    endif;
    check_error();
    round(realpart(work(1))) -> lworks(prec, n);
enddefine;


define xGEEVX(balanc, jobvl, jobvr, sense, a,ar, w,wr,
        vl,vlr, vr,vrr, scale,scaler, rconde,rconder, rcondv,rcondvr)
        -> (ilo, ihi, abnrm);
    /*
    define xGEEVX(balanc, jobvl, jobvr, sense, a,ar, wr,wrr, wi,wir,
        vl,vlr, vr,vrr, scale,scaler, rconde,rconder, rcondv,rcondvr)
        -> (ilo, ihi, abnrm);
    */
    lvars iw, iwr = false;
    unless sense.isstring then   ;;; have arguments for real case
        (balanc,jobvl,jobvr,sense,a,ar,w,wr)
            -> (balanc,jobvl,jobvr,sense,a,ar,w,wr,iw,iwr)
    endunless;

    lconstant
        balanc_opts = [`N` `P` `S` `B`],
        jobv_opts = [`N` `V`],
        sense_opts = [`N` `E` `V` `B`];
    dlvars
        balanc_opt = checkstring(balanc, balanc_opts),
        jobvl_opt = checkstring(jobvl, jobv_opts),
        jobvr_opt = checkstring(jobvr, jobv_opts),
        sense_opt = checkstring(sense, sense_opts);
    unless sense_opt == `V` or sense_opt == `N`
    or (jobvl_opt == `V` and jobvr_opt == `V`) then
        mishap(sense, jobvl, jobvr, 3,
            'lapack: SENSE, JOBVL, JOBVR, options inconsistent')
    endunless;

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    unless m == n then
        mishap(a, ar, 2, 'lapack: Expecting square array A')
    endunless;

    lvars rprec = singprec(prec) and sfloat or dfloat; ;;; for real args

    lvars (wv, wi, _, wn, _, _, _) = array_spec(w, wr, 1, prec);
    if iwr then
        unless realprec(prec) then
            mishap(0, 'lapack: Expecting real arguments')
        endunless;
        unless wn == n then
            mishap(w, wr, n, 3, 'lapack: WR wrong size')
        endunless;
        lvars (iwv, iwi, _, iwn, _, _, _) = array_spec(iw, iwr, 1, prec);
        unless iwn == n then
            mishap(iw, iwr, n, 3, 'lapack: WI wrong size')
        endunless;
    else
        unless compprec(prec) then
            mishap(0, 'lapack: Expecting complex arguments')
        endunless;
        unless wn == n then
            mishap(w, wr, n, 3, 'lapack: W wrong size')
        endunless;
    endif;

    if jobvl_opt == `N` then
        lvars (vlv, vli) = dummyvec(prec), ldvl = 1;
    else
        lvars (vlv, vli, ldvl, vlm, vln, _, _) = array_spec(vl, vlr, 2, prec);
        unless vlm == n and vln == n then
            mishap(vl, vlr, n, 3, 'lapack: VL wrong size')
        endunless
    endif;

    if jobvr_opt == `N` then
        lvars (vrv, vri) = dummyvec(prec), ldvr = 1;
    else
        lvars (vrv, vri, ldvr, vrm, vrn, _, _) = array_spec(vr, vrr, 2, prec);
        unless vrm == n and vrn == n then
            mishap(vr, vrr, n, 3, 'lapack: VL wrong size')
        endunless
    endif;

    0 ->> ilo -> ihi;

    lvars (scalev, scalei,_,scalen,_,_,_)
        = array_spec(scale, scaler, 1, rprec);
    unless scalen == n then
        mishap(scale, scaler, n, 3, 'lapack: SCALE wrong size')
    endunless;

    0.0 -> abnrm;

    if sense_opt == `E` or sense_opt == `B` then
        lvars (rcondev, rcondei, _,rconden, _,_,_)
            = array_spec(rconde, rconder, 1, rprec);
        unless rconden == n then
            mishap(rconde, rconder, n, 3, 'lapack: RCONDE wrong size')
        endunless
    else
        lvars (rcondev, rcondei) = dummyvec(prec);
    endif;

    if sense_opt == `V` or sense_opt == `B` then
        lvars (rcondvv, rcondvi, _,rcondvn, _,_,_)
            = array_spec(rcondv, rcondvr, 1, rprec);
        unless rcondvn == n then
            mishap(rcondv, rcondvr, n, 3, 'lapack: RCONDV wrong size')
        endunless
    else
        lvars (rcondvv, rcondvi) = dummyvec(prec);
    endif;

    define lconstant lworkdef(prec, n);
        if realprec(prec) then
            if sense_opt == `N` or sense_opt == `E` then
                max(1, 3*n)
            else
                max(1, n*(n+6))
            endif
        else
            if sense_opt == `N` or sense_opt == `E` then
                max(1, 2*n)
            else
                max(1, (n+2)*n)
            endif
        endif
    enddefine;
    lconstant lworks = newanysparse(2, lworkdef, apply);
    lvars
        lwork = lworks(prec, n),
        work = workfvec(ltag, [1 ^lwork], prec);

    if realprec(prec) then
        if sense == `N` or sense == `E` then
            lvars (riwork, _) = dummyvec(prec);
        else
            lvars riwork = workivec(ltag, [1 ^(2*n-2)]);
        endif
    else
        lvars riwork = workfvec(ltag, [1 ^(2*n)], rprec);
    endif;

    define :inline lconstant EXTCALL(
            PROC=item, VEC1=item, VEC2=item, VEC3=item,
            REF=item, VCTR1=item, VCTR2=item);
        excall check=CHK PROC(
            FSTRING         balanc,
            FSTRING         jobvl,
            FSTRING         jobvr,
            FSTRING         sense,
            IREF            n,
            VEC1            av[ai],
            IREF            lda,
            VEC1            wv[wi],
            VEC3            iwv[iwi],
            VEC1            vlv[vli],
            IREF            ldvl,
            VEC1            vrv[vri],
            IREF            ldvr,
            IREF            ilo,
            IREF            ihi,
            VEC2            scalev[scalei],
            REF             abnrm,
            VEC2            rcondev[rcondei],
            VEC2            rcondvv[rcondvi],
            VCTR1           work,
            IREF            lwork,
            VCTR2           riwork,
            IVCTR           info)
    enddefine;

    if prec == sfloat then
        EXTCALL(SGEEVX, SVEC, SVEC, SVEC, SREF, SVCTR, IVCTR)
    elseif prec == dfloat then
        EXTCALL(DGEEVX, DVEC, DVEC, DVEC, DREF, DVCTR, IVCTR)
    elseif prec == cfloat then
        EXTCALL(CGEEVX, CVEC, SVEC, VOID, SREF, CVCTR, SVCTR)
    elseif prec == zfloat then
        EXTCALL(ZGEEVX, ZVEC, DVEC, VOID, DREF, ZVCTR, DVCTR)
    endif;
    check_error();
    round(realpart(work(1))) -> lworks(prec, n);
enddefine;


;;; Singular value decomposition


define xGESVD(jobu, jobvt, a, ar, s, sr, u, ur, vt, vtr);
    lconstant job_opts = [`A` `S` `O` `N`];
    lvars
        jobu_opt = checkstring(jobu, job_opts),
        jobvt_opt = checkstring(jobvt, job_opts);
    if jobu_opt == `O` and jobvt_opt == `O` then
        mishap(0, 'lapack: JOBU and JOBVT cannot both be O')
    endif;

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    dlvars minmn = min(m,n);

    lvars rprec = singprec(prec) and sfloat or dfloat; ;;; for real args

    lvars (sv, si, _, sn, _, _, _) = array_spec(s, sr, 1, rprec);
    unless sn == minmn then
        mishap(s, sr, minmn, 3, 'lapack: S wrong size')
    endunless;

    lvars ldu = 1, urows = 1, ucols = 1;
    if jobu_opt == `A` or jobu_opt == `S` then
        if jobu_opt == `A` then m else minmn endif -> ucols;
        lvars (uv, ui, ldu, um, un, _, _) = array_spec(u, ur, 2, prec);
        unless m == um and ucols == un then
            mishap(u, ur, m, ucols, 4, 'lapack: U wrong size')
        endunless
    else
        lvars (uv, ui) = dummyvec(prec);
    endif;

    lvars ldvt = 1, vtrows = 1, vtcols = 1;
    if jobvt_opt == `A` or jobvt_opt == `S` then
        if jobvt_opt == `A` then n else minmn endif -> vtrows;
        lvars (vtv, vti, ldvt, vtm, vtn, _, _) = array_spec(vt, vtr, 2, prec);
        unless vtrows == vtm and n == vtn then
            mishap(vt, vtr, vtrows, n, 4, 'lapack: V wrong size')
        endunless
    else
        lvars (vtv, vti) = dummyvec(prec);
    endif;

    define lconstant lworkdef(prec, m, n);
        if realprec(prec) then
            max(1, max(3*minmn + max(m,n), 5*minmn-4))
        else
            max(1, 2*minmn + max(m,n))
        endif
    enddefine;
    lconstant lworks = newanysparse(3, lworkdef, apply);
    lvars
        lwork = lworks(prec, m, n),
        work = workfvec(ltag, [1 ^lwork], prec);
    if compprec(prec) then
        lvars rwork
            = workfvec(ltag, [1 ^(max(3*min(m,n),5*min(m,n)-4))], rprec);
    endif;

    define :inline lconstant EXTCALL(
            PROC=item, VEC1=item, VEC2=item, VCTR1=item, VCTR2=item);
        excall check=CHK PROC(
            FSTRING     jobu,
            FSTRING     jobvt,
            IREF        m,
            IREF        n,
            VEC1        av[ai],
            IREF        lda,
            VEC2        sv[si],
            VEC1        uv[ui],
            IREF        ldu,
            VEC1        vtv[vti],
            IREF        ldvt,
            VCTR1       work,
            IREF        lwork,
            VCTR2       rwork,
            IVCTR       info)
    enddefine;

    if prec == sfloat then
        EXTCALL(SGESVD, SVEC, SVEC, SVCTR, VOID)
    elseif prec == dfloat then
        EXTCALL(DGESVD, DVEC, DVEC, DVCTR, VOID)
    elseif prec == cfloat then
        EXTCALL(CGESVD, CVEC, SVEC, CVCTR, SVCTR)
    elseif prec == dfloat then
        EXTCALL(ZGESVD, ZVEC, DVEC, ZVCTR, DVCTR)
    endif;
    check_error();
    round(realpart(work(1))) -> lworks(prec, m, n);
enddefine;


;;; Generalised Eigenvalue/vector and SVD


define lconstant xSYGV_HEGV(itype, jobz, uplo, a,ar, b,br, w,wr, func);
    lconstant jobz_opts = [`N` `V`];
    checkstring(jobz, jobz_opts) -> ;
    lvars uplo_opt = checkstring(uplo, uplo_opts);

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    unless m == n then
        mishap(a, ar, 2, 'lapack: Expecting square array A')
    endunless;

    lvars rprec = singprec(prec) and sfloat or dfloat; ;;; for real args

    lvars (bv, bi, ldb, bm, bn, _, _) = array_spec(b, br, 2, prec);
    unless bm == n and bn == n then
        mishap(b, br, n, 3, 'lapack: B wrong size or not square')
    endunless;

    lvars (wv, wi, _, wn, _, _, _) = array_spec(w, wr, 1, rprec);
    unless wn == n then
        mishap(w, wr, n, 3, 'lapack: W wrong size for eigenvalues')
    endunless;

    lconstant names = fsynames('_SYTRD');
    lvars nb = optblock(names(prec), uplo_opt,0,0, n, -1,-1,-1);
    if func == "sygv" then
        lvars
            lwork = max(max(1, 3*n-1), n*(nb+2)),
            work = workfvec(ltag, [1 ^lwork], prec);
    else
        lvars
            lwork = max(max(1, 2*n-1), n*(nb+1)),
            work = workfvec(ltag, [1 ^lwork], prec),
            rwork = workfvec(ltag, [1 ^(max(1, 3*n-2))], rprec);
    endif;

    define :inline lconstant EXTCALL(
            PROC=item, VEC1=item, VEC2=item, VCTR1=item, VCTR2=item);
        excall check=CHK PROC(
            IREF            itype,
            FSTRING         jobz,
            FSTRING         uplo,
            IREF            n,
            VEC1            av[ai],
            IREF            lda,
            VEC1            bv[bi],
            IREF            ldb,
            VEC2            wv[wi],
            VCTR1           work,
            IREF            lwork,
            VCTR2           rwork,
            IVCTR           info)
    enddefine;

    if func == "sygv" then
        if prec == sfloat then
            EXTCALL(SSYGV, SVEC, SVEC, SVCTR, VOID)
        elseif prec == dfloat then
            EXTCALL(DSYGV, DVEC, DVEC, DVCTR, VOID)
        else
            mishap(0, 'lapack: xSYGV needs real arguments')
        endif
    elseif func == "hegv" then
        if prec == cfloat then
            EXTCALL(CHEGV, CVEC, SVEC, CVCTR, SVCTR)
        elseif prec == zfloat then
            EXTCALL(ZHEGV, ZVEC, DVEC, ZVCTR, DVCTR)
        else
            mishap(0, 'lapack: xHEGV needs complex arguments')
        endif
    endif;
    check_error()
enddefine;

define xSYGV(/* itype, jobz, uplo, a,ar, b,br, w,wr */) with_nargs 9;
    xSYGV_HEGV("sygv")
enddefine;

define xHEGV(/* itype, jobz, uplo, a,ar, b,br, w,wr */) with_nargs 9;
    xSYGV_HEGV("hegv")
enddefine;


define xGEGV(jobvl, jobvr, a,ar, b,br, alpha,alphar, beta,betar,
        vl,vlr, vr,vrr);
    /* Alternative form:
    define xGEGV(jobvl, jobvr, a,ar, b,br, alphar,alpharr, alphai,alphair,
        beta,betar, vl,vlr, vr,vrr);
    */
    lvars ialpha, ialphar=false;
    unless jobvr.isstring then   ;;; have arguments for real case
        (jobvl,jobvr,a,ar,b,br,alpha,alphar)
            -> (jobvl,jobvr,a,ar,b,br,alpha,alphar,ialpha,ialphar)
    endunless;

    lconstant jobv_opts = [`N` `V`];
    lvars
        jobvl_opt = checkstring(jobvl, jobv_opts),
        jobvr_opt = checkstring(jobvr, jobv_opts);

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    unless m == n then
        mishap(a, ar, 2, 'lapack: Expecting square array A')
    endunless;

    lvars rprec = singprec(prec) and sfloat or dfloat; ;;; for real args

    lvars (bv, bi, ldb, bm, bn, _, _) = array_spec(b, br, 2, prec);
    unless bm == n and bn == n then
        mishap(b, br, n, 3, 'lapack: B wrong size or not square')
    endunless;

    lvars (alphav, alphai, _, alphan, _, _, _)
        = array_spec(alpha, alphar, 1, prec);
    if ialphar then
        unless realprec(prec) then
            mishap(0, 'lapack: Expecting real arguments')
        endunless;
        unless alphan == n then
            mishap(alpha, alphar, n, 3, 'lapack: ALPHAR wrong size')
        endunless;
        lvars (ialphav, ialphai, _, ialphan, _, _, _)
            = array_spec(ialpha, ialphar, 1, prec);
        unless ialphan == n then
            mishap(ialpha, ialphar, n, 3, 'lapack: ALPHAI wrong size')
        endunless;
    else
        unless compprec(prec) then
            mishap(0, 'lapack: Expecting complex arguments')
        endunless;
        unless alphan == n then
            mishap(alpha, alphar, n, 3, 'lapack: ALPHA wrong size')
        endunless;
    endif;

    lvars (betav, betai, _, betan, _, _, _) = array_spec(beta, betar, 1, prec);
    unless betan == n then
        mishap(beta, betar, n, 3, 'lapack: BEATwrong size')
    endunless;

    if jobvl_opt == `N` then
        lvars (vlv, vli) = dummyvec(prec), ldvl = 1;
    else
        lvars (vlv, vli, ldvl, vlm, vln, _, _) = array_spec(vl, vlr, 2, prec);
        unless vlm == n and vln == n then
            mishap(vl, vlr, n, 3, 'lapack: VL wrong size')
        endunless
    endif;

    if jobvr_opt == `N` then
        lvars (vrv, vri) = dummyvec(prec), ldvr = 1;
    else
        lvars (vrv, vri, ldvr, vrm, vrn, _, _) = array_spec(vr, vrr, 2, prec);
        unless vrm == n and vrn == n then
            mishap(vr, vrr, n, 3, 'lapack: VL wrong size')
        endunless
    endif;

    define lconstant lworkdef(prec, n);
        if realprec(prec) then
            max(1, 8*n)
        else
            max(1, 2*n)
        endif
    enddefine;
    lconstant lworks = newanysparse(2, lworkdef, apply);
    lvars
        lwork = lworks(prec, n),
        work = workfvec(ltag, [1 ^lwork], prec);
    if compprec(prec) then
        lvars rwork = workfvec(ltag, [1 ^(8*n)], rprec);
    endif;

    define :inline lconstant EXTCALL(
            PROC=item, VEC1=item, VEC2=item, VCTR1=item, VCTR2=item);
        excall check=CHK PROC(
            FSTRING         jobvl,
            FSTRING         jobvr,
            IREF            n,
            VEC1            av[ai],
            IREF            lda,
            VEC1            bv[bi],
            IREF            ldb,
            VEC1            alphav[alphai],
            VEC2            ialphav[ialphai],
            VEC1            betav[betai],
            VEC1            vlv[vli],
            IREF            ldvl,
            VEC1            vrv[vri],
            IREF            ldvr,
            VCTR1           work,
            IREF            lwork,
            VCTR2           rwork,
            IVCTR           info)
    enddefine;

    if prec == sfloat then
        EXTCALL(SGEGV, SVEC, SVEC, SVCTR, VOID)
    elseif prec == dfloat then
        EXTCALL(DGEGV, DVEC, DVEC, DVCTR, VOID)
    elseif prec == cfloat then
        EXTCALL(CGEGV, CVEC, VOID, CVCTR, SVCTR)
    elseif prec == zfloat then
        EXTCALL(ZGEGV, ZVEC, VOID, ZVCTR, DVCTR)
    endif;
    check_error();
    round(realpart(work(1))) -> lworks(prec, n);
enddefine;


define xGGSVD(jobu, jobv, jobq, a,ar, b,br, alpha,alphar, beta,betar,
        u,ur, v,vr, q,qr) -> (k, l);
    lconstant
        jobu_opts = [`U` `N`],
        jobv_opts = [`V` `N`],
        jobq_opts = [`Q` `N`];
    lvars
        jobu_opt = checkstring(jobu, jobu_opts),
        jobv_opt = checkstring(jobv, jobv_opts),
        jobq_opt = checkstring(jobq, jobq_opts);

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");
    dlvars minmn = min(m,n);

    lvars rprec = singprec(prec) and sfloat or dfloat; ;;; for real args

    lvars (bv, bi, ldb, p, bn, _, _) = array_spec(b, br, 2, prec);
    unless bn == n then
        mishap(b, br, n, 3, 'lapack: B wrong no. columns')
    endunless;

    0 ->> k -> l;

    lvars (alphav, alphai, _, alphan, _, _, _)
        = array_spec(alpha, alphar, 1, rprec);
    unless alphan == n then
        mishap(alpha, alphar, n, 3, 'lapack: ALPHA wrong size')
    endunless;

    lvars (betav, betai, _, betan, _, _, _)
        = array_spec(beta, betar, 1, rprec);
    unless betan == n then
        mishap(beta, betar, n, 3, 'lapack: BETA wrong size')
    endunless;

    if jobu_opt == `U` then
        lvars (uv, ui, ldu, um, un, _, _) = array_spec(u, ur, 2, prec);
        unless um == m and un == m then
            mishap(u, ur, m, 3, 'lapack: U wrong size or not square')
        endunless
    else
        lvars (uv, ui) = dummyvec(prec), ldu = 1;
    endif;

    if jobv_opt == `V` then
        lvars (vv, vi, ldv, vm, vn, _, _) = array_spec(v, vr, 2, prec);
        unless vm == p and vn == p then
            mishap(v, vr, p, 3, 'lapack: V wrong size or not square')
        endunless
    else
        lvars (vv, vi) = dummyvec(prec), ldv = 1;
    endif;

    if jobq_opt == `Q` then
        lvars (qv, qi, ldq, qm, qn, _, _) = array_spec(q, qr, 2, prec);
        unless qm == n and qn == n then
            mishap(q, qr, p, 3, 'lapack: Q wrong size or not square')
        endunless
    else
        lvars (qv, qi) = dummyvec(prec), ldq = 1;
    endif;

    lvars
        work = workfvec(ltag, [1 ^(max(3*n, max(m,p))+n)], prec),
        iwork = workivec(ltag, [1 ^n]);
    if compprec(prec) then
        lvars rwork = workfvec(ltag, [1 ^(max(1, 2*n))], rprec);
    endif;

    define :inline lconstant EXTCALL(
            PROC=item, VEC1=item, VEC2=item, VCTR1=item, VCTR2=item);
        excall check=CHK PROC(
            FSTRING     jobu,
            FSTRING     jobv,
            FSTRING     jobq,
            IREF        m,
            IREF        n,
            IREF        p,
            IREF        k,
            IREF        l,
            VEC1        av[ai],
            IREF        lda,
            VEC1        bv[bi],
            IREF        ldb,
            VEC2        alphav[alphai],
            VEC2        betav[betai],
            VEC1        uv[ui],
            IREF        ldu,
            VEC1        vv[vi],
            IREF        ldv,
            VEC1        qv[qi],
            IREF        ldq,
            VCTR1       work,
            VCTR2       rwork,
            IVCTR       iwork,
            IVCTR       info)
    enddefine;

    if prec == sfloat then
        EXTCALL(SGGSVD, SVEC, SVEC, SVCTR, VOID)
    elseif prec == dfloat then
        EXTCALL(DGGSVD, DVEC, DVEC, DVCTR, VOID)
    elseif prec == cfloat then
        EXTCALL(CGGSVD, CVEC, SVEC, CVCTR, SVCTR)
    elseif prec == dfloat then
        EXTCALL(ZGGSVD, ZVEC, DVEC, ZVCTR, DVCTR)
    endif;
    check_error();
enddefine;


/*
-- Extra routines -----------------------------------------------------

These are not direct interfaces like the other routines, but are
here because the calling conventions are such that what they do cannot
efficiently be provided at a higher level.

*/


define xLPCOL(a, ar, ia, b, br, ib);
    ;;; Copy column of matrix. ia and ib are matrix not array indices.

    lvars (av, ai, lda, m, na, _, prec) = array_spec(a, ar, 2, "float");
    fi_check(ia, 1, na) -> _;

    lvars (bv, bi, ldb, mb, nb, _, _) = array_spec(b, br, 2, prec);
    fi_check(ib, 1, nb) -> _;
    unless mb == m then
        mishap(a, ar, b, br, 4,
            'lapack: A and B have different numbers of rows')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item);
        excall check=CHK PROC(
            IREF            m,
            VEC             av[ai fi_+ lda fi_* (ia fi_- 1)],
            ICONST          1,
            VEC             bv[bi fi_+ ldb fi_* (ib fi_- 1)],
            ICONST          1);
    enddefine;

    if prec == sfloat then
        EXTCALL(SCOPY, SVEC)
    elseif prec == dfloat then
        EXTCALL(DCOPY, DVEC)
    elseif prec == cfloat then
        EXTCALL(CCOPY, CVEC)
    elseif prec == zfloat then
        EXTCALL(ZCOPY, ZVEC)
    endif
enddefine;


define xLPROW(a, ar, ia, b, br, ib);
    ;;; Copy row of matrix. ia and ib are matrix not array indices.

    lvars (av, ai, lda, ma, n, _, prec) = array_spec(a, ar, 2, "float");
    fi_check(ia, 1, ma) -> _;

    lvars (bv, bi, ldb, mb, nb, _, _) = array_spec(b, br, 2, prec);
    fi_check(ib, 1, mb) -> _;
    unless nb == n then
        mishap(a, ar, b, br, 4,
            'lapack: A and B have different numbers of columns')
    endunless;

    define :inline lconstant EXTCALL(PROC=item, VEC=item);
        excall check=CHK PROC(
            IREF            n,
            VEC             av[ai fi_+ ia fi_- 1],
            IREF            lda,
            VEC             bv[bi fi_+ ib fi_- 1],
            IREF            ldb);
    enddefine;

    if prec == sfloat then
        EXTCALL(SCOPY, SVEC)
    elseif prec == dfloat then
        EXTCALL(DCOPY, DVEC)
    elseif prec == cfloat then
        EXTCALL(CCOPY, CVEC)
    elseif prec == zfloat then
        EXTCALL(ZCOPY, ZVEC)
    endif
enddefine;


define xLPTRANS(a, ar, b, br);
    ;;; Matrix transpose

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "float");

    lvars (bv, bi, ldb, mb, nb, _, _) = array_spec(b, br, 2, prec);
    unless mb == n and nb == m then
        mishap(a, ar, b, br, 4,
            'lapack: Incompatible array dimensions for A and B')
    endunless;

    lvars inca, incb, incai, incbi, ncopy, ncopies;
    if m fi_>= n then
        n -> ncopies;   m -> ncopy;   ;;; no of copies; no in each copy
        1 -> inca;      lda -> incai;
        ldb -> incb;    1 -> incbi;
    else
        m -> ncopies;   n -> ncopy;
        lda -> inca;    1 -> incai;
        1 -> incb;      ldb -> incbi;
    endif;

    define :inline lconstant EXTCALL(PROC=item, VEC=item);
        repeat ncopies times
            excall check=CHK PROC(
                IREF            ncopy,
                VEC             av[ai],
                IREF            inca,
                VEC             bv[bi],
                IREF            incb);
            ai fi_+ incai -> ai;
            bi fi_+ incbi -> bi;
        endrepeat;
    enddefine;

    if prec == sfloat then
        EXTCALL(SCOPY, SVEC)
    elseif prec == dfloat then
        EXTCALL(DCOPY, DVEC)
    elseif prec == cfloat then
        EXTCALL(CCOPY, CVEC)
    elseif prec == zfloat then
        EXTCALL(ZCOPY, ZVEC)
    endif
enddefine;


define xLPADJOINT(a, ar, b, br);
    ;;; Matrix adjoint

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "complex");

    lvars (bv, bi, ldb, mb, nb, _, _) = array_spec(b, br, 2, prec);
    unless mb == n and nb == m then
        mishap(a, ar, b, br, 4,
            'lapack: Incompatible array dimensions for A and B')
    endunless;

    lvars inca, incb, incai, incbi, ncopy, ncopies;
    if m fi_>= n then
        n -> ncopies;   m -> ncopy;   ;;; no of copies; no in each copy
        1 -> inca;      lda -> incai;
        ldb -> incb;    1 -> incbi;
    else
        m -> ncopies;   n -> ncopy;
        lda -> inca;    1 -> incai;
        1 -> incb;      ldb -> incbi;
    endif;

    define :inline lconstant EXTCALL(PROC1=item, PROC2=item, VEC=item);
        repeat ncopies times
            excall check=CHK PROC1(
                IREF            ncopy,
                VEC             av[ai],
                IREF            inca,
                VEC             bv[bi],
                IREF            incb);
            excall check=CHK PROC2(
                IREF            ncopy,
                VEC             bv[bi],
                IREF            incb);
            ai fi_+ incai -> ai;
            bi fi_+ incbi -> bi;
        endrepeat;
    enddefine;

    if prec == cfloat then
        EXTCALL(CCOPY, CLACGV, CVEC)
    elseif prec == zfloat then
        EXTCALL(ZCOPY, ZLACGV,ZVEC)
    endif
enddefine;


define xLPRESHAPE(abycol, bbycol, a, ar, b, br);
    ;;; Reshape a matrix.
    checkstring(abycol, [`C` `R`]) == `C` -> abycol;
    checkstring(bbycol, [`C` `R`]) == `C` -> bbycol;

    lvars (av, ai, lda, ma, na, _, prec) = array_spec(a, ar, 2, "float");

    lvars (bv, bi, ldb, mb, nb, _, _) = array_spec(b, br, 2, prec);
    lvars N = ma fi_* na;
    unless N == mb fi_* nb then
        mishap(a, ar, b, br, 4,
            'lapack: A and B have different numbers of elements')
    endunless;

    if na == 1 or (abycol and ma /== 1) then
        lvars incai = 1, incaistart = lda;
        if ma == lda then       ;;; 1-D equivalent so optimise
            N -> ma; 1 -> na
        endif
    else
        lvars incai = lda, incaistart = 1;
        (ma, na) -> (na, ma);
    endif;
    if nb == 1 or (bbycol and mb /== 1) then
        lvars incbi = 1, incbistart = ldb;
        if mb == ldb then       ;;; 1-D equivalent so optimise
            N -> mb; 1 -> nb
        endif
    else
        lvars incbi = ldb, incbistart = 1;
        (mb, nb) -> (nb, mb);
    endif;

    lvars
        aistart = ai fi_- incaistart,
        bistart = bi fi_- incbistart,
        aistop = aistart fi_+ na fi_* incaistart,
        i1 = ma, k1 = mb, ni, nk, ncopy;

    define :inline lconstant EXTCALL(PROC=item, VEC=item);
        repeat
            if i1 == ma then
            quitif (aistart == aistop);
                aistart fi_+ incaistart ->> aistart -> ai;
                0 -> i1;
                ma -> ni;
            else
                ai fi_+ ncopy fi_* incai -> ai;
                ma fi_- i1 -> ni;
            endif;
            if k1 == mb then
                bistart fi_+ incbistart ->> bistart -> bi;
                0 -> k1;
                mb -> nk;
            else
                bi fi_+ ncopy fi_* incbi -> bi;
                mb fi_- k1 -> nk;
            endif;
            if nk fi_>= ni then
                ma -> i1;
                k1 fi_+ ni -> k1;
                ni -> ncopy;
            else
                mb -> k1;
                i1 fi_+ nk -> i1;
                nk -> ncopy;
            endif;
            excall check=CHK PROC(
                IREF            ncopy,
                VEC             av[ai],
                IREF            incai,
                VEC             bv[bi],
                IREF            incbi);
        endrepeat
    enddefine;

    if prec == sfloat then
        EXTCALL(SCOPY, SVEC)
    elseif prec == dfloat then
        EXTCALL(DCOPY, DVEC)
    elseif prec == cfloat then
        EXTCALL(CCOPY, CVEC)
    elseif prec == zfloat then
        EXTCALL(ZCOPY, ZVEC)
    endif
enddefine;


define xLPRITOC(a, ar, b, br, c, cr);
    ;;; Copy real matrix a to the real part of complex matrix c,
    ;;; and real matrix b to the imaginary part of c

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "real");
    lvars cprec = singprec(prec) and cfloat or zfloat;

    lvars (bv, bi, ldb, mb, nb, _, _) = array_spec(b, br, 2, prec);
    unless mb == m and nb == n then
        mishap(a, ar, b, br, 4, 'lapack: A and B different sizes')
    endunless;

    lvars (cv, ci, ldc, mc, nc, _, _) = array_spec(c, cr, 2, cprec);
    unless mc == m and nc == n then
        mishap(a, ar, c, cr, 4, 'lapack: A and C different sizes')
    endunless;

    ;;; We pretend C is real, and use vector copy with doubled
    ;;; increment to skip over parts we do not want to change.
    if lda == m and ldb == m and ldc == m then
        m fi_* n -> m; 1 -> n       ;;; optimise 1-D equivalence
    endif;
    lvars inca, incb, incc, incai, incbi, incci;
    if m fi_>= n then
        1 ->> inca -> incb; 2 -> incc;
        lda -> incai; ldb -> incbi; 2 fi_* ldc -> incci
    else
        1 ->> incai -> incbi; 2 -> incci;
        lda -> inca; ldb -> incb; 2 fi_* ldc -> incc;
        (m, n) -> (n, m)
    endif;

    2 fi_* (ci fi_- 1) fi_+ 1 -> ci;

    define :inline lconstant EXTCALL(PROC=item, VEC=item);
        repeat n times
            excall check=off PROC(      ;;; check=off as cheating
                IREF            m,
                VEC             av[ai],
                IREF            inca,
                VEC             cv[ci],
                IREF            incc);
            excall check=off PROC(
                IREF            m,
                VEC             bv[bi],
                IREF            incb,
                VEC             cv[ci fi_+ 1],
                IREF            incc);
            ai fi_+ incai -> ai;
            bi fi_+ incbi -> bi;
            ci fi_+ incci -> ci;
        endrepeat
    enddefine;

    if prec == sfloat then
        EXTCALL(SCOPY, SVEC)
    elseif prec == dfloat then
        EXTCALL(DCOPY, DVEC)
    endif
enddefine;


define xLPCTORI(c, cr, a, ar, b, br);
    ;;; Copy real part of C to A, imaginary part to B.

    lvars (cv, ci, ldc, mc, nc, _, cprec) = array_spec(c, cr, 2, "complex");
    lvars prec = singprec(cprec) and sfloat or dfloat;

    lvars (av, ai, lda, m, n, _, _) = array_spec(a, ar, 2, prec);
    unless mc == m and nc == n then
        mishap(a, ar, c, cr, 4, 'lapack: A and C different sizes')
    endunless;

    lvars (bv, bi, ldb, mb, nb, _, _) = array_spec(b, br, 2, prec);
    unless mb == m and nb == n then
        mishap(a, ar, b, br, 4, 'lapack: A and B different sizes')
    endunless;

    ;;; We pretend C is real, and use vector copy with doubled
    ;;; increment to skip over parts we do not want to access.
    if lda == m and ldb == m and ldc == m then
        m fi_* n -> m; 1 -> n       ;;; optimise 1-D equivalence
    endif;
    lvars inca, incb, incc, incai, incbi, incci;
    if m fi_>= n then
        1 ->> inca -> incb; 2 -> incc;
        lda -> incai; ldb -> incbi; 2 fi_* ldc -> incci
    else
        1 ->> incai -> incbi; 2 -> incci;
        lda -> inca; ldb -> incb; 2 fi_* ldc -> incc;
        (m, n) -> (n, m)
    endif;

    2 fi_* (ci fi_- 1) fi_+ 1 -> ci;

    define :inline lconstant EXTCALL(PROC=item, VEC=item);
        repeat n times
            excall check=off PROC(      ;;; check=off as cheating
                IREF            m,
                VEC             cv[ci],
                IREF            incc,
                VEC             av[ai],
                IREF            inca);
            excall check=off PROC(
                IREF            m,
                VEC             cv[ci fi_+ 1],
                IREF            incc,
                VEC             bv[bi],
                IREF            incb);
            ai fi_+ incai -> ai;
            bi fi_+ incbi -> bi;
            ci fi_+ incci -> ci;
        endrepeat
    enddefine;

    if prec == sfloat then
        EXTCALL(SCOPY, SVEC)
    elseif prec == dfloat then
        EXTCALL(DCOPY, DVEC)
    endif
enddefine;


define xLPRTOC(a, ar, c, cr);
    ;;; Copy real matrix a to the real part of complex matrix c,
    ;;; setting the imaginary part to 0,

    lvars (av, ai, lda, m, n, _, prec) = array_spec(a, ar, 2, "real");
    lvars cprec = singprec(prec) and cfloat or zfloat;

    lvars (cv, ci, ldc, mc, nc, _, _) = array_spec(c, cr, 2, cprec);
    unless mc == m and nc == n then
        mishap(a, ar, c, cr, 4, 'lapack: A and C different sizes')
    endunless;

    ;;; We pretend C is real, and use vector copy with doubled
    ;;; increment to skip over parts we do not want to change.
    if lda == m and ldc == m then
        m fi_* n -> m; 1 -> n       ;;; optimise 1-D equivalence
    endif;
    lvars inca, incc, incai, incci;
    if m fi_>= n then
        1 -> inca; 2 -> incc;
        lda -> incai; 2 fi_* ldc -> incci
    else
        1 -> incai; 2 -> incci;
        lda -> inca; 2 fi_* ldc -> incc;
        (m, n) -> (n, m)
    endif;

    2 fi_* (ci fi_- 1) fi_+ 1 -> ci;

    define :inline lconstant EXTCALL(PROC1=item, PROC2=item, VEC=item, CONST=item);
        repeat n times
            excall check=off PROC1(      ;;; check=off as cheating
                IREF            m,
                VEC             av[ai],
                IREF            inca,
                VEC             cv[ci],
                IREF            incc);
            excall check=off PROC2(
                IREF            m,
                CONST           0,
                VEC             cv[ci fi_+ 1],
                IREF            incc);
            ai fi_+ incai -> ai;
            ci fi_+ incci -> ci;
        endrepeat
    enddefine;

    if prec == sfloat then
        EXTCALL(SCOPY, SSCAL, SVEC, SCONST)
    elseif prec == dfloat then
        EXTCALL(DCOPY, DSCAL, DVEC, DCONST)
    endif
enddefine;


define xLPSCAL(alpha, a, ar);
    ;;; xSCAL applied to matrices

    lvars (av, ai, incai, m, n, _, prec) = array_spec(a, ar, 2, "float");

    lvars inca=1;
    if incai == m then
        m fi_* n -> m; 1 -> n       ;;; optimise 1-D equivalence
    elseif m fi_< n then
        (inca, incai, m, n) -> (incai, inca, n, m) ;;; do by row
    endif;

    define :inline lconstant EXTCALL(PROC=item, VEC=item, REF=item);
        repeat n times
            excall check=CHK PROC(
                IREF            m,
                REF             alpha,
                VEC             av[ai],
                IREF            inca);
            ai fi_+ incai -> ai;
        endrepeat
    enddefine;

    if prec == sfloat then
        EXTCALL(SSCAL, SVEC, SREF)
    elseif prec == dfloat then
        EXTCALL(DSCAL, DVEC, DREF)
    elseif prec == cfloat then
        EXTCALL(CSCAL, CVEC, CREF)
    elseif prec == zfloat then
        EXTCALL(ZSCAL, ZVEC, ZREF)
    endif
enddefine;


define xLPAXPY(alpha, a, ar, b, br);
    ;;; xAXPY applied to matrices

    lvars (av, ai, incai, m, n, _, prec) = array_spec(a, ar, 2, "float");

    lvars (bv, bi, incbi, mb, nb, _, _) = array_spec(b, br, 2, prec);
    unless mb == m and nb == n then
        mishap(a, ar, b, br, 4, 'lapack: A and B different sizes')
    endunless;

    lvars inca=1, incb=1;
    if incai == m and incbi == m then
        m fi_* n -> m; 1 -> n       ;;; optimise 1-D equivalence
    elseif m fi_< n then
        (inca, incb, incai, incbi, m, n) ;;; do by row
            -> (incai, incbi, inca, incb, n, m)
    endif;

    define :inline lconstant EXTCALL(PROC=item, VEC=item, REF=item);
        repeat n times
            excall check=CHK PROC(
                IREF            m,
                REF             alpha,
                VEC             av[ai],
                IREF            inca,
                VEC             bv[bi],
                IREF            incb);
            ai fi_+ incai -> ai;
            bi fi_+ incbi -> bi;
        endrepeat
    enddefine;

    if prec == sfloat then
        EXTCALL(SAXPY, SVEC, SREF)
    elseif prec == dfloat then
        EXTCALL(DAXPY, DVEC, DREF)
    elseif prec == cfloat then
        EXTCALL(CAXPY, CVEC, CREF)
    elseif prec == zfloat then
        EXTCALL(ZAXPY, ZVEC, ZREF)
    endif
enddefine;


vars lapack = true;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 29 2006
		Removed '-lm' in exload commands
--- Aaron Sloman, Jan  7 2005
		Removed some library specifications that generate warnings
		on some systems, but do not seem to be needed.
--- David Young, Dec 15 2004
        Increasing LIWORK in xSYEVD_HEEVD to work with Lapack 3.0
--- David Young, Sep 29 2003
        Added xLP... additional routines.
--- David Young, Sep 24 2003
        Corrected handling of SENSE argument in xGEEVX
--- David Young, Sep 16 2003
        Added xLACGV and xLACPY
 */
