/* --- Copyright University of Sussex 2004. All rights reserved. ----------
 > File:            $popvision/lib/arrpack.p
 > Purpose:         Operations on arrays of numbers
 > Author:          David Young, Dec 16 2003 (see revisions)
 > Documentation:   HELP * ARRPACK
 > Related Files:   LIB * ARRPACK.C
 */

compile_mode:pop11 +strict;

section;

uses popvision, excall, objectfile;

/*
-- A list of the routines to be generated -----------------------------
-----------------------------------------------------------------------
*/

/* This was originally simply the top-level code. By putting it in a
list it is possible to generate a list of external routine names first
for the external load, then to use it to drive the procedure generation.

Each routine spec starts APROCO for ordinary, APROCC for copying, or
APROCS for special cases. There follows its base name, its versions (a
string containing some of n for normal, m for masked, i for indexed),
no. of input scalars, no. of output scalars, no. of main arrays, and
list of types or type combinations.

Some special cases are flagged as follows. For APROCC a 3 indicating the
no. of arrays can be replaced by iio or ioo indicating the input/output
pattern (which affects the typing). For APROCO the number of input
scalars can be replaced by: I which means a single integer input
independent of the array type; V which means a 1-D array of the same
type as the main array and as long as the number of indexed elements; F
which means provide arrays and results for the "find" operation.
*/

lconstant arrpack_proclist = [

/*
-- Interface routines - 1 array ---------------------------------------
*/

APROCO zero      nmi 0 0 1 [b i s d c z]
APROCO inc       nmi 0 0 1 [b i s d c z]
APROCO dec       nmi 0 0 1 [b i s d c z]
APROCO neg       nmi 0 0 1 [i s d c z]
APROCO sqr       nmi 0 0 1 [b i s d c z]
APROCO conj      nmi 0 0 1 [c z]
;;; log etc. need complex versions once the complex library is available
APROCO log       nmi 0 0 1 [s d]
APROCO sin       nmi 0 0 1 [s d]
APROCO cos       nmi 0 0 1 [s d]
APROCO tan       nmi 0 0 1 [s d]
APROCO asin      nmi 0 0 1 [s d]
APROCO acos      nmi 0 0 1 [s d]
APROCO atan      nmi 0 0 1 [s d]
APROCO sinh      nmi 0 0 1 [s d]
APROCO cosh      nmi 0 0 1 [s d]
APROCO tanh      nmi 0 0 1 [s d]
APROCO exp       nmi 0 0 1 [s d]
APROCO sqrt      nmi 0 0 1 [s d]
APROCO ceil      nmi 0 0 1 [s d]
APROCO floor     nmi 0 0 1 [s d]
APROCO abs       nmi 0 0 1 [i s d]
APROCO logistic  nmi 0 0 1 [s d]
APROCO not       nmi 0 0 1 [i]

/*
-- Interface routines - 1 array and scalars ---------------------------
*/

APROCO k          nmi 1 0 1 [b i s d c z]
APROCO plusk      nmi 1 0 1 [b i s d c z]
APROCO minusk     nmi 1 0 1 [b i s d c z]
APROCO kminus     nmi 1 0 1 [b i s d c z]
APROCO timesk     nmi 1 0 1 [b i s d c z]
APROCO divk       nmi 1 0 1 [b i s d c z]
APROCO kdiv       nmi 1 0 1 [b i s d c z]
APROCO powk       nmi 1 0 1 [b i s d]
APROCO modk       nmi 1 0 1 [b i s d]
APROCO maxk       nmi 1 0 1 [b i s d]
APROCO mink       nmi 1 0 1 [b i s d]
APROCO link       nmi 2 0 1 [b i s d c z]
APROCO quadk      nmi 3 0 1 [b i s d c z]
APROCO sumof      nmi 0 1 1 [b i s d c z]
APROCO maxof      nmi 0 1 1 [b i s d]
APROCO minof      nmi 0 1 1 [b i s d]
APROCO minmaxof   nmi 0 2 1 [b i s d]

/*
-- Interface routines - 2 arrays --------------------------------------
*/

APROCO plus     nmi 0 0 2 [b i s d c z]
APROCO minus    nmi 0 0 2 [b i s d c z]
APROCO minusrev nmi 0 0 2 [b i s d c z]
APROCO times    nmi 0 0 2 [b i s d c z]
APROCO div      nmi 0 0 2 [b i s d c z]
APROCO divrev   nmi 0 0 2 [b i s d c z]
APROCO pow      nmi 0 0 2 [b i s d]
APROCO mod      nmi 0 0 2 [b i s d]
APROCO max      nmi 0 0 2 [b i s d]
APROCO min      nmi 0 0 2 [b i s d]
APROCO sumsqr   nmi 0 0 2 [s d]
APROCO hypot    nmi 0 0 2 [s d]
APROCO arctan2  nmi 0 0 2 [s d]
APROCO cartopol nmi 0 0 2 [s d]
APROCO poltocar nmi 0 0 2 [s d]
APROCO and      nmi 0 0 2 [i]
APROCO or       nmi 0 0 2 [i]
APROCO xor      nmi 0 0 2 [i]

/*
-- Interface routines - 2 arrays and scalars --------------------------
*/

APROCO lincomb  nmi 2 0 2  [b i s d c z]
APROCO keq      nmi 1 0 2  [bi ii si di ci zi]
APROCO kne      nmi 1 0 2  [bi ii si di ci zi]
APROCO kgt      nmi 1 0 2  [bi ii si di]
APROCO kge      nmi 1 0 2  [bi ii si di]
APROCO klt      nmi 1 0 2  [bi ii si di]
APROCO kle      nmi 1 0 2  [bi ii si di]

/*
-- Interface routines - 3 arrays --------------------------------------
*/

APROCO eq       nmi 0 0 3  [bbi iii ssi ddi cci zzi]
APROCO ne       nmi 0 0 3  [bbi iii ssi ddi cci zzi]
APROCO gt       nmi 0 0 3  [bbi iii ssi ddi]
APROCO ge       nmi 0 0 3  [bbi iii ssi ddi]
APROCO lt       nmi 0 0 3  [bbi iii ssi ddi]
APROCO le       nmi 0 0 3  [bbi iii ssi ddi]

/*
-- Interface routines - copying and conversion ------------------------
*/

;;; Head of each sublist is first type which may be combined
;;; with each type in the tail of the sublist. e.g. [[a b c] [d e]]
;;; gives type combinations ab ac de

APROCC cop      nmi 0 0 2   [[b b i s d c z] [i b i s d c z]
                            [s b i s d c z] [d b i s d c z]
                            [c c z] [z c z]]

APROCC real     nmi 0 0 2   [[c b i s d] [z b i s d]]
APROCC imag     nmi 0 0 2   [[c b i s d] [z b i s d]]
APROCC ctori    nmi 0 0 ioo [[c b i s d] [z b i s d]]
APROCC ritoc    nmi 0 0 iio [[b c z] [i c z] [s c z] [d c z]]

/*
-- Interface routines - reshape, index, find, get/set -----------------
*/

APROCO reshape  n   0 0 2   [b i s d c z]

APROCO index    nm  I 0 1 [b i s d c z]

APROCO find     nm  F 0 1 [b i s d c z]

APROCO getvals  i   V 0 1 [b i s d c z]
APROCO setvals  i   V 0 1 [b i s d c z]

/*
-- Interface routines - special ---------------------------------------
*/

APROCS specv    n   0 0 1 [x]
APROCS indv     n   0 0 1 [x]

];

/*
-----------------------------------------------------------------------
-- End of the list of routine specifications --------------------------
*/

/*
-- Utilities for compilation ------------------------------------------
*/

;;; Macro to execute the list of procedure definitions, when APROCO etc.
;;; have been defined.
define lconstant macro compile_procs; explode(arrpack_proclist) enddefine;

;;; Get a 1-character subword
define lconstant 3 ch (word, ind) /* -> 1-char-word */;
    consword(word(ind), 1)
enddefine;

;;; mapping from type letters to scalar argument types for excall
lconstant scalwords = newassoc([
    [b INT][i INT][s SFLOAT][d DFLOAT][c CREF][z ZREF]
]);
;;; mapping to references when results are returned
lconstant scalrefwords = newassoc([
    [b IREF][i IREF][s SREF][d DREF][c CREF][z ZREF]
]);

define lconstant readspec
        -> (name, special, nsin, nsout, narr, types);
    ;;; Called from macros to read a procedure spec
    readitem() -> name;
    readitem() -> special;
    readitem() -> nsin;
    unless lmember(nsin, [I V F]) then
        fi_check(nsin, 0, false) -> _
    endunless;
    fi_check(readitem(), 0, false) -> nsout;
    readitem() -> narr;
    unless narr == "ioo" or narr == "iio" then
        fi_check(narr, 1, false) -> _
    endunless;
    listread() -> types
enddefine;

define lconstant addprefix(special, name)
        -> (newname, with_mask, with_ind);
    (false, false) -> (with_mask, with_ind);
    if special == "n" then
        "A"
    elseif special == "m" then
        true -> with_mask;
        "AM"
    elseif special == "i" then
        true -> with_ind;
        "AI"
    else
        mishap(special, name, 2, 'Unexpected variant letter')
    endif <> name -> newname
enddefine;

;;; uncomment second line for list of procedures
define :inline lconstant printnames(name); enddefine;
;;; define :inline lconstant printnames(name); npr(name); enddefine;
printnames('List of procedures generated');
printnames('');

/*
-- ...  Macro syntax simplifier ---------------------------------------
*/

/* This avoids having to type lots of quote marks and commas, or
explode([...]) constructions, in macro definitions where code is
to be compiled conditionally. It is rather simple and does no checking,
so should be beefed up if it is to be used more generally. */

lconstant arrpack_debugging = false;

define lconstant syntax <_;
    ;;; quoted program text for macro procedures - just puts what it finds
    ;;; on the stack, except pushes the value of a variable or bracketed
    ;;; expression preceded by "^" and concatenates two items with ## between
    ;;; to a word.

    define lconstant pushitem;
        if poplastitem == "^" then
            if readitem() == "(" then
                pop11_comp_stmnt_seq_to(")") -> _;
            else
                sysPUSH(poplastitem)
            endif
        else
            sysPUSHQ(poplastitem)
        endif
    enddefine;

    until readitem() == "_>" do
        if poplastitem == termin then
            mishap(0, 'End of range reached, expecting _>')
        endif;
        if poplastitem == "##" then
            readitem() -> _;
            pushitem();
            sysCALLQ(nonop sys_><);
            sysCALLQ(consword);
        else
            pushitem();
        endif;
        #_IF arrpack_debugging      ;;; print record
            lvars save_plist = proglist;
            unless pop11_try_nextreaditem("##") then
                sysPUSHS(0);
                sysCALLQ(spr)
            endunless;
            save_plist -> proglist;
        #_ENDIF
    enduntil
enddefine;

/*
-- Utilities for run-time ---------------------------------------------
*/

define lconstant arr_type(arr) /* -> typeword */;
    ;;; Returns b, i, s, d, c, z
    lconstant
        (sfloat_spec, _) = field_spec_info("sfloat"),
        (dfloat_spec, _) = field_spec_info("dfloat"),
        (int_spec, _) = field_spec_info("int"),
        (byte_spec, _) = field_spec_info("byte");
    lvars
        arrvec = arr.arrayvector,
        arr_name = arrvec.dataword;
    if arr_name == "cfloatvec" then   ;;; must check these cases first
        "c"
    elseif arr_name == "zfloatvec" then
        "z"
    else
        lvars arr_spec = arrvec.datakey.class_spec;
        switchon arr_spec ==
        case sfloat_spec then "s"
        case dfloat_spec then "d"
        case int_spec then "i"
        case byte_spec then "b"
        else
            mishap(arr_spec, 1, 'arrpack: Array type not recognised')
        endswitchon
    endif
enddefine;

define lconstant specvec(N);
    initintvec(5*N+4)   ;;; must be consistent with arrscan.c
enddefine;

define lconstant makespecvecs(maxargs, maxdim) /* -> specvecs */;
    lvars N;
    consvector(
        repeat maxargs times
            consvector(
                for N from 1 to maxdim do
                    specvec(N)
                endfor, maxdim)
        endrepeat, maxargs)
enddefine;

define lconstant spec(argno, arr, reg, samp) -> specv;
    ;;; Return spec vectors for arrscan.h. Argument checking is done
    ;;; by the external routine, so none here.
    ;;; argno is the number of the argument - spec vectors are recycled
    ;;; for a given argument no. and dimensionality, so they must not
    ;;; be returned to the caller of the caller of this proc. If argno
    ;;; is 0 then a new vector is made which can be returned.
    ;;; maxargs below says how many array args are needed - increase if
    ;;; necessary.

    ;;; cache spec vectors to reduce garbage. Use different ones for each
    ;;; dimensionality just so that ->explode (faster than a loop) can be
    ;;; used to stash the values in the non-complete case
    lconstant
        maxargs = 4, maxdim = 10,
        specvecs = makespecvecs(maxargs, maxdim);   ;;; at compile-time
    lvars N = arr.pdnargs;
    if N > maxdim or argno == 0 then
        specvec(N)
    else
        fast_subscrv(N, fast_subscrv(fi_check(argno,1,maxargs), specvecs))
    endif -> specv;

    lvars firstfastest = arr.isarray_by_row, bds = arr.boundslist;
    if reg == [] and samp == 1 then    ;;; just need array bounds
        firstfastest and 8:22 or 8:20 -> fast_subscrintvec(1, specv);
        N -> fast_subscrintvec(2, specv);
        lvars i;
        explode(bds);       ;;; on stack
        fast_for i from 2*N+3 by -1 to 4 do
                -> fast_subscrintvec(i, specv)
        endfor
    else
        firstfastest and 2:10 or 0,
        N,
        0,
        explode(bds),
        0,
        explode(if reg /== [] then reg else bds endif),
        if samp.isinteger then
            repeat N times samp endrepeat
        else
            explode(samp)
        endif
            -> explode(specv)
    endif
enddefine;

define lconstant wkvec(N);
    initintvec(2*N)   ;;; must be consistent with arrscan.c
enddefine;

define lconstant makewkvecs(maxdim) /* -> wkvecs */;
    lvars N;
    consvector(
        for N from 1 to maxdim do
            wkvec(N)
        endfor, maxdim)
enddefine;

define lconstant getwkvec(arr) /* -> wkvec */;
    ;;; Get a cached work vector. Vector returned depends on no.
    ;;; of dimensions of arr. Only one such vector is available
    ;;; at a time. Contents are undefined.
    lconstant maxdim = 10,
        wkvecs = makewkvecs(maxdim);   ;;; at compile-time
    lvars N = arr.pdnargs;
    if N > maxdim then
        wkvec(N)
    else
        fast_subscrv(N, wkvecs)
    endif
enddefine;

define lconstant indvec(n, arr, ind) -> (ind, offset, len);
    ;;; Get index vector. External routine expects the dimension
    ;;; the index refers to to change most rapidly.
    ;;; Takes the number of points to process, the array
    ;;; to process, the index array or vector.
    ;;; Returns index vector, any offset in it, and its length
    ;;; in terms of sets of indices into arr.
    ;;; Type of ind will get checked later by excall.
    fi_check(n, 0, false) -> _;
    lvars ndim = pdnargs(arr);
    if ind.isarray then
        unless pdnargs(ind) == 2 then
            mishap(ind, 1, 'arrpack: expecting 2-D index array')
        endunless;
        lvars
            (b1, b2, b3, b4) = explode(boundslist(ind)),
            ff = ind.isarray_by_row;            ;;; first fastest
        unless b1 == 1 and b3 == 1 then
            mishap(ind, 1, 'arrpack: index array dimensions not 1-based')
        endunless;
        unless (ff and b2 == ndim) or (not(ff) and b4 == ndim) then
            mishap(ndim, ind, 2,
                'arrpack: index array does not match no. dimensions')
        endunless;
        unless (ff and b4 >= n) or (not(ff) and b2 >= n) then
            mishap(n, ind, 2,
                'arrpack: index array does not have enough entries')
        endunless;
        arrayvector_bounds(ind) -> (_, offset);
        arrayvector(ind) -> ind;
        ff and b4 or b2 -> len
    else
        1 -> offset;
        length(ind) div ndim -> len;
        unless len >= n then
            mishap(ind, n, 2, 'arrpack: index vector not long enough')
        endunless
    endif
enddefine;

define lconstant valcheck(n, vals);
    fi_check(n, 0, false) -> _;
    unless pdnargs(vals) == 1 then
        mishap(vals, 1, 'arrpack: expecting 1-D values array')
    endunless;
    lvars (b1, b2) = explode(boundslist(vals));
    unless b2 - b1 + 1 >= n then
        mishap(vals, n, 2, 'arrpack: values array too small')
    endunless
enddefine;

define lconstant arrpack_errt(atype);
    mishap(atype, 1, 'arrpack: Array type not suitable for this operation')
enddefine;

lconstant arrayscan_errs = {
    'array high bound less than low bound'              ;;; 1
    'region high bound less than low bound'             ;;; 2
    'not all sample points inside array bounds'         ;;; 3
    'sample increment zero or negative'                 ;;; 4
    'indices out of range'                              ;;; 5
    'number of dimensions less than 1'                  ;;; 6
    ''                                                  ;;; 7
    'arrays inconsistent (no. of dimensions differs)'   ;;; 8
    'arrays inconsistent (no. of elements to process differs on some dimension)'
    'arrays inconsistent (total no. of elements differs)' ;;; 10
    'dimension number out of range'                     ;;; 11
};

define lconstant arrscan_err(err) /* -> errmess */;
    if err > 0 and err <= length(arrayscan_errs) then
        arrayscan_errs(err)
    else
        err
    endif
enddefine;

define lconstant arrpack_mishap(/* arrgs, nargs, */ err);
    mishap('arrpack: ' >< arrscan_err(err))
enddefine;

/*
-- External load list generation --------------------------------------
*/

define lconstant extnames_o
        (NAME, special, nscalsin, nscalsout, narrays, TYPES);
    ;;; Puts the external procedure name on the stack, preceded by
    ;;; a word containing a comma.
    addprefix(special, NAME) -> (NAME, _, _);
    lvars t;
    for t in TYPES do
        <_ ",", "^(t <> NAME)", _>
    endfor
enddefine;

define lconstant extnames_c
        (NAME, special, nscalsin, nscalsout, narrays, TYPES);
    addprefix(special, NAME) -> (NAME, _, _);
    lvars types;
    for types in TYPES do
        lvars t1 = hd(types), t2;
        for t2 in tl(types) do
            <_ ",", "^(t1 <> t2 <> NAME)", _>
        endfor
    endfor
enddefine;

/*
-- Procedure generation -----------------------------------------------
*/

define lconstant pushproc_o
        (NAME, special, nscalsin, nsclsout, narrays, TYPES);
    ;;; DO NOT USE AUTOMATIC FORMATTING ON THIS PROCEDURE
    ;;; Outputs code for one procedure, placing it on the stack.
    lvars i, with_mask, with_index;
    addprefix(special, NAME) -> (NAME, with_mask, with_index);
    printnames(NAME);

    lvars
        iarg = nscalsin == "I",
        dovals = nscalsin == "V",
        dofind = nscalsin == "F";
    if iarg or dovals then 1 -> nscalsin endif;
    if dofind then 0 -> nscalsin endif;

    ;;; Compile-time code           Generated code (ignore quotes
    ;;;                             and commas between quoted items)

                                 <_ define ^NAME (                      _>;
    for i from 1 to nscalsin do  <_         k ## ^i,                    _>
    endfor;
    for i from 1 to nsclsout do  <_         r ## ^i,                    _>
    endfor;
    if dofind then               <_         farr,                       _>
    endif;
    if with_mask then            <_         mask, regm, sampm,          _>
    elseif with_index then       <_         n,                          _>
    endif;
    for i from 1 to narrays do   <_         arr ## ^i,                  _>;
        if with_index then       <_         ind ## ^i,                  _>
        else                     <_         reg ## ^i,
                                            samp ## ^i,                 _>
        endif
    endfor;                      <_         )                           _>;
    if nsclsout > 0 or dofind then  <_          -> (                    _>;
        for i from 1 to nsclsout do <_      r ## ^i,                    _>
        endfor;
        if dofind then           <_         nf                          _>
        endif;                   <_                 )                   _>
    endif;                       <_         ;                           _>;
                                 <_     lvars err,
                                            atype = arr_type(arr1),     _>;
    for i from 1 to narrays do   <_         specv ## ^i = spec(^i,
                                                arr ## ^i,              _>;
        if with_index then       <_             [], 1),
                                            (indv ## ^i, indoff ## ^i, _)
                                                = indvec(n, arr ## ^i,
                                                    ind ## ^i),         _>
        else                     <_             reg ## ^i, samp ## ^i), _>
        endif
    endfor;
    if with_mask then            <_         specvm = spec(^(narrays+1),
                                                mask, regm, sampm)      _>
    endif;                       <_         ;                           _>;
    if iarg then                 <_     fi_check(k1, 1, false) -> _;    _>
    endif;
    if dofind then               <_     lvars (fvec, foff, nf)
                                            = indvec(0, arr1, farr);
                                        lvars wk = getwkvec(arr1);      _>
    endif;
    if dovals then               <_     valcheck(n, k1);                _>
    endif;

    lvars t, ife = "if";
    for t in TYPES do
        ;;; arrays can have different types
        ;;; but the first type letter still determines
        ;;; the test for which external procedure to call
        lvars
            t1 = t ch 1,
            T = lowertoupper(t),
            lT = length(T),
            s = iarg and "INT"
                or dovals and (T ch 1) <> "ARR"
                or scalwords(t1),
            r = scalrefwords(t1);
                                 <_     ^ife atype == "^t1" then
                                            excall check =              _>;
        if with_mask or with_index or
        dofind or dovals or
        narrays > 1 or nscalsin > 0 or
        nsclsout > 0 then        <_                 [a]                 _>
        else                     <_                 []                  _>
        endif;
                                 <_             int ^(t <> NAME) (      _>;
        for i from 1 to nscalsin do <_          ^s  k ## ^i,            _>
        endfor;
        for i from 1 to nsclsout do <_          ^r  r ## ^i,            _>
        endfor;
        if with_mask then        <_             IARR mask,
                                                IVCTR specvm,           _>
        elseif with_index then   <_             n,                      _>
        endif;
        for i from 1 to narrays do
            if i > 1 then        <_             ,                       _>
            endif;
                                 <_             ^(T ch min(i, lT)) ## ARR
                                                        arr ## ^i
                                                , IVCTR specv ## ^i     _>;
            if with_index then   <_             , IVEC indv ## ^i
                                                        [indoff ## ^i]  _>
            endif
        endfor;
        if dofind then           <_             , IVCTR wk
                                                , IREF nf
                                                , IVEC fvec[foff]       _>
        endif;                   <_             )                       _>;
        "elseif" -> ife
    endfor;
                                 <_     else
                                            arrpack_errt(atype)
                                        endif -> err;
                                        if err /== 0 then
                                            arrpack_mishap( #|          _>;
    if with_mask then            <_             mask,regm,sampm,specvm, _>
    elseif with_index then       <_             n,                      _>
    endif;
    for i from 1 to narrays do   <_             arr ## ^i, specv ## ^i, _>;
        if with_index then       <_             ind ## ^i,              _>
        else                     <_             reg ## ^i, samp ## ^i,  _>
        endif
    endfor;
    if dofind then               <_             wk, nf, farr            _>
    endif;                       <_             |#, err)
                                        endif
                                    enddefine;                          _>
enddefine;


define lconstant pushproc_c
        (NAME, special, nscalsin, nsclsout, narrays, TYPES);
    ;;; DO NOT USE AUTOMATIC FORMATTING ON THIS PROCEDURE
    ;;; Outputs code for one procedure, placing it on the stack,
    ;;; for the copying case - has to test on two arrays to get
    ;;; name of external procedure.
    ;;; Should not have any scalar arguments or results.
    unless nscalsin == 0 and nsclsout == 0 then
        mishap(NAME, nscalsin, nsclsout, 3,
            'Not expecting scalar arguments/results')
    endunless;
    lvars i, with_mask, with_index;
    addprefix(special, NAME) -> (NAME, with_mask, with_index);
    printnames(NAME);

    lvars iospec = "io";
    unless narrays.isinteger then
        narrays -> iospec;
        length(narrays) -> narrays
    endunless;

    ;;; Compile-time code           Generated code (ignore quotes
    ;;;                             and commas between quoted items)

                                 <_ define ^NAME (                      _>;
    if with_mask then            <_         mask, regm, sampm,          _>
    elseif with_index then       <_         n,                          _>
    endif;
    for i from 1 to narrays do   <_         arr ## ^i,                  _>;
        if with_index then       <_         ind ## ^i,                  _>
        else                     <_         reg ## ^i,
                                            samp ## ^i,                 _>
        endif
    endfor;                      <_         );                          _>;
                                 <_     lvars err,
                                            atype1 = arr_type(arr1),
                                            atype2 = arr_type(
                                                arr ## ^narrays),       _>;
    for i from 1 to narrays do   <_         specv ## ^i = spec(^i,
                                                arr ## ^i,              _>;
        if with_index then       <_             [], 1),
                                            (indv ## ^i, indoff ## ^i, _)
                                                = indvec(n, arr ## ^i,
                                                    ind ## ^i),         _>
        else                     <_             reg ## ^i, samp ## ^i), _>
        endif
    endfor;
    if with_mask then            <_         specvm = spec(^(narrays+1),
                                                mask, regm, sampm)      _>
    endif;                       <_         ;                           _>;

    lvars types, ife1 = "if";
    for types in TYPES do
        lvars
            ife2 = "if",
            t1 = hd(types), t2,
            A1 = lowertoupper(t1)
                 <> "ARR";         <_   ^ife1 atype1 == "^t1" then      _>;
        for t2 in tl(types) do
            lvars A2 = lowertoupper(t2)
                       <> "ARR";
                                 <_         ^ife2 atype2 == "^t2" then
                                                excall check =          _>;
            if with_mask or with_index or
            narrays > 2 or nscalsin > 0 or
            nsclsout > 0 then    <_                 [a]                 _>
            else                 <_                 []                  _>
            endif;
                                 <_             int ^(t1<>t2<>NAME) (   _>;
            if with_mask then    <_             IARR mask,
                                                IVCTR specvm,           _>
            elseif with_index then <_           n,                      _>
            endif;
            for i from 1 to narrays do
                if i > 1 then    <_             ,                       _>
                endif;
                if iospec(i) == `i` then <_     ^A1                     _>
                else             <_             ^A2                     _>
                endif;           <_             arr ## ^i
                                                , IVCTR specv ## ^i     _>;
                if with_index then <_           , IVEC indv ## ^i
                                                        [indoff ## ^i]  _>
                endif
            endfor;              <_             )                       _>;
            "elseif" -> ife2;
        endfor;                  <_         else
                                                arrpack_errt(atype2)
                                            endif;                      _>;
        "elseif" -> ife1
    endfor;
                                 <_     else
                                            arrpack_errt(atype1)
                                        endif -> err;
                                        if err /== 0 then
                                            arrpack_mishap( #|          _>;
    if with_mask then            <_             mask,regm,sampm,specvm, _>
    elseif with_index then       <_             n,                      _>
    endif;
    for i from 1 to narrays do   <_             arr ## ^i, specv ## ^i, _>;
        if with_index then       <_             ind ## ^i,              _>
        else                     <_             reg ## ^i, samp ## ^i,  _>
        endif
    endfor;                      <_             |#, err)
                                        endif
                                    enddefine;                          _>
enddefine;

/*
-- Generate list of external names for external load ------------------
*/

define lvars macro APROCO;
    lvars i,
        (name, special, nsin, nsout, narr, types) = readspec();
    for i from 1 to length(special) do
        extnames_o(name, special ch i, nsin, nsout, narr, types)
    endfor
enddefine;

define lvars macro APROCC;
    lvars i,
        (name, special, nsin, nsout, narr, types) = readspec();
    for i from 1 to length(special) do
        extnames_c(name, special ch i, nsin, nsout, narr, types)
    endfor
enddefine;

define lvars macro APROCS = nonmac APROCO; enddefine;

lvars macro extnames = tl([% compile_procs %]);

/*
-- External load ------------------------------------------------------
*/

lconstant macro extname1 = 'arrpack', extname2 = 'arrscan',
    obfile1 = objectfile(extname1), obfile2 = objectfile(extname2);

unless obfile1 and obfile2 then
    mishap(0, 'arrpack: Cannot file object file')
endunless;

exload extname1 [^obfile1 ^obfile2]
    (language C)
lconstant extnames;
endexload;

/*
-- Define most of the procedures --------------------------------------
*/

define lvars macro APROCO;
    lvars i,
        (name, special, nsin, nsout, narr, types) = readspec();
    for i from 1 to length(special) do
        pushproc_o(name, special ch i, nsin, nsout, narr, types)
    endfor
enddefine;

define lvars macro APROCC;
    lvars i,
        (name, special, nsin, nsout, narr, types) = readspec();
    for i from 1 to length(special) do
        pushproc_c(name, special ch i, nsin, nsout, narr, types)
    endfor
enddefine;

define lvars macro APROCS;
    ;;; Define these procedures specially below
    erasenum(#| readspec() |#)
enddefine;

compile_procs;

/*
-- Define remaining procedures ----------------------------------------
*/

define Aspecv(arr, reg, samp, t, cdopt, ordopt) -> specv;
    ;;; Returns a spec vector
    spec(t, arr, reg, samp) -> specv;
    excall check=[a] xAspecv(IVCTR specv, BOOLEAN cdopt, BOOLEAN ordopt)
enddefine;

define Aindv(arr, t) -> indv;
    ;;; Returns an indexing vector
    spec(t, arr, [], 1) -> indv;
    excall check=[] xAindv(IVCTR indv)
enddefine;

vars arrpack = true;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Apr 26 2004
        Added minusrev and divrev
--- David Young, Apr  1 2004
        Added indexed procedures, Afind etc.
        Introduced automatic generation of external names for exload,
        and <_ _> syntax for program fragments in macro procedures.
--- David Young, Dec 19 2003
        Added Aspecv
 */
