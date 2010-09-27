/* --- Copyright University of Sussex 2003. All rights reserved. ----------
 > File:            $popvision/lib/excall.p
 > Purpose:         Call external functions with offset-vector arguments
 > Author:          David Young, May 16 2003 (see revisions)
 > Documentation:   HELP * EXCALL
 */

/*

         CONTENTS - (Use <ENTER> g to access required sections)

 -- Introduction
 -- Miscellaneous
 -- Compiling pre-argument information
 -- Making vectors for call-by-reference
 -- Argument checking procedures
 -- Compiling the arguments
 -- Typespec routines
 -- Indexed vector addressing
 -- Main routine


-- Introduction -------------------------------------------------------

Simplifies calling external routines. Helps with:

1. Calling external routines which require addresses of vector elements.

The main issue is avoiding garbage collections between getting addresses
and calling the external procedure. The code below is designed to avoid
this by avoiding creating structures or expanding the stack above the
immediately previous high point between the sysFIELDs that get the
addresses and the sysFIELD that calls the external routine. One apparent
exception might be a routine that returns a ddecimal, but testing
suggests that the structure is not built until after the external
function returns.

It's hard to be certain that this means a GC can *never* take place at
this point - so an option is provided to set pop_after_gc to trigger a
mishap after any GC in the critical region. When this option is on,
routines that return ddecimals cannot be used.

The sysFIELDs should not trigger a GC themselves, as they use fixed
records.

2. Calling external routines which require call-by-reference. Provides
vectors to pass values in, and automatically copies between a variable
and the vector.

3. Calling external routines which require string lengths as hidden
arguments.

4. Checking the types of arguments.

*/

compile_mode:pop11 +strict;

section;

/*
-- Miscellaneous ------------------------------------------------------
*/

lvars excall_vecno = 0;
define lconstant excall_name /* -> word */;
    ;;; New name for an lconstant. (Cannot trust gensym not to get reset!)
    consword('excall_bXbZmahb_' >< (excall_vecno + 1 ->> excall_vecno))
enddefine;

define lconstant list_read /* item_or_list */;
    ;;; System listread does not expand macros (why not?). This replacement
    ;;; uses itemread instead of readitem. Also, no need to deal with nested
    ;;; lists in the present case.
    lvars item = itemread();
    if item == "[" then
        [% until (itemread() ->> item) == "]" do item enduntil %]
    else
        item
    endif
enddefine;

define lconstant pop11_ignore_expr_to(/* ends */) /* -> result */;
    dlocal pop_syntax_only = true;
    pop11_comp_expr_to()
enddefine;

/*
-- Compiling pre-argument information ---------------------------------
*/

define lconstant compile_checks
        -> (checkr, checkf, checka, checki, checks, checkg);
    ;;; Read check=checkopt syntax. If omitted do all checks, except gc.
    true ->> checkr ->> checkf ->> checka ->> checki -> checks;
    false -> checkg;
    if pop11_try_nextitem("check") then
        if pop11_try_nextitem("=") then
            lvars opts = list_read();
            unless opts == "on" then
                false ->> checkr ->> checkf ->> checka ->> checki -> checks;
                unless opts == "off" then
                    lvars opt;
                    for opt in opts do
                        if isstartstring(opt, "recurse") then
                            true -> checkr
                        elseif isstartstring(opt, "funcspec") then
                            true -> checkf
                        elseif isstartstring(opt, "argtypes") then
                            true -> checka
                        elseif isstartstring(opt, "indices") then
                            true -> checki
                        elseif isstartstring(opt, "stacklen") then
                            true -> checks
                        elseif isstartstring(opt, "gc") then
                            true -> checkg
                        else
                            mishap(opt, 1, 'excall: Unexpected check option')
                        endif
                    endfor
                endunless
            endunless
        else
            "check" :: proglist -> proglist ;;; "check" might be func name
        endif
    endif
enddefine;


define lconstant compile_funcname -> (name, result);
    ;;; Returns name of function and type of result (not checked to be sensible)
    itemread() -> name;
    false -> result;
    unless pop11_try_nextitem("(") then
        name -> result;
        itemread() -> name;
        pop11_need_nextitem("(") -> _;
    endunless;
enddefine;

/*
-- Making vectors for call-by-reference -------------------------------
*/

defclass lconstant sfv :sfloat;
defclass lconstant dfv :dfloat;

define lconstant ref_vector(type) -> (vec, access);
    lvars procedure access;
    ;;; Return a vector suitable for holding data of the type given,
    ;;; and an update/access procedure for it.
    switchon type ==
    case "BREF" orcase "BCONST" then
        inits(1) -> vec;
        fsub_b(% 1, vec %) -> access;
    case "IREF" orcase "ICONST" then
        initintvec(1) -> vec;
        fast_subscrintvec(% 1, vec %) -> access;
    case "SIREF" orcase "SICONST" then
        initshortvec(1) -> vec;
        fast_subscrshortvec(% 1, vec %) -> access;
    case "FREF" orcase "SREF" orcase "FCONST" orcase "SCONST" then
        initsfv(1) -> vec;
        fast_subscrsfv(% 1, vec %) -> access;
    case "DREF" orcase "DCONST" then
        initdfv(1) -> vec;
        fast_subscrdfv(% 1, vec %) -> access;
    case "CREF" orcase "CCONST" then
        initsfv(2) -> vec;
        define lvars procedure access;
            fast_subscrsfv(1, vec) +: fast_subscrsfv(2, vec)
        enddefine;
        define updaterof access(c);
            realpart(c) -> fast_subscrsfv(1, vec);
            imagpart(c) -> fast_subscrsfv(2, vec);
        enddefine;
    case "ZREF" orcase "ZCONST" then
        initdfv(2) -> vec;
        define lvars procedure access;
            fast_subscrdfv(1, vec) +: fast_subscrdfv(2, vec)
        enddefine;
        define updaterof access(c);
            realpart(c) -> fast_subscrdfv(1, vec);
            imagpart(c) -> fast_subscrdfv(2, vec);
        enddefine;
    endswitchon
enddefine;

/*
-- Argument checking procedures ---------------------------------------
*/

define lconstant check_index(v, i) /* -> (v, i) */;
    ;;; Check that the index i is an integer and in the bounds of v,
    ;;; replacing them on the stack.
    v, fi_check(i, 1, datalength(v))
enddefine;


;;; The list of keywords that may precede arguments.

lconstant
    vecwords = [BVEC SIVEC IVEC FVEC SVEC DVEC CVEC ZVEC],
    arrwords = [BARR SIARR IARR FARR SARR DARR CARR ZARR],
    refwords = [BREF SIREF IREF FREF SREF DREF CREF ZREF],
    constwords = [BCONST SICONST ICONST FCONST SCONST DCONST CCONST ZCONST],
    specialwords = [STRING FSTRING VOID],
    vectorwords = [BVCTR IVCTR SIVCTR FVCTR SVCTR DVCTR CVCTR ZVCTR],
    scalarwords = [INT BOOLEAN SF SFLOAT DFLOAT],
    keywords = vecwords <> arrwords <> refwords <> constwords <>
    specialwords <> vectorwords <> scalarwords;


lconstant checkprocs = newassoc([]);

define lconstant type_mishap(/* expect1, expect2, found */) with_nargs 3;
    mishap(3, '%excall: Argument wrong type - expecting %s %s')
enddefine;

define:inline lconstant checkvec(NAME=item, TYPE=item);
    procedure(v) -> v;
        lconstant (s, _) = field_spec_info("TYPE");
        unless v.datakey.class_spec == s then
            type_mishap(word_string("TYPE"), 'vector', datakey(v))
        endunless
    endprocedure -> checkprocs("NAME");
enddefine;

checkvec(BVEC, byte);
checkvec(SIVEC, short);
checkvec(IVEC, int);
checkvec(SVEC, sfloat);
checkprocs("SVEC") -> checkprocs("FVEC");
checkvec(DVEC, dfloat);

procedure(v) -> v;
    unless v.dataword == "cfloatvec" then
        type_mishap('single-complex', 'vector', datakey(v))
    endunless
endprocedure -> checkprocs("CVEC");
procedure(v) -> v;
    unless v.dataword == "zfloatvec" then
        type_mishap('double-complex', 'vector', datakey(v))
    endunless
endprocedure -> checkprocs("ZVEC");

lvars name;
for name in vectorwords do
    checkprocs(allbutlast(4,name) <> "VEC") -> checkprocs(name)
endfor;

define:inline lconstant checktype(NAME=item, TEST=item);
    procedure(v) -> v;
        unless v.TEST then
            type_mishap(allbutfirst(2, pdprops(TEST)), 'value', v)
        endunless
    endprocedure -> checkprocs("NAME");
enddefine;

checktype(BOOLEAN,isboolean);
checktype(STRING,isstring);
checkprocs("STRING") -> checkprocs("FSTRING");
checktype(INT,isintegral);
checktype(SFLOAT,isdecimal);
checkprocs("SFLOAT") -> checkprocs("DFLOAT");

;;; These are not checked: SF as SFLOAT is the checking alternative,
;;; xREF and xCONST as checked implicitly by assignment to the vector,
;;; xARR as will have been converted to xVEC.

define lconstant check_arg(type);
    ;;; Plant code to check that the object on the top of the stack is
    ;;; the type given.
    lvars checkproc = checkprocs(type);
    if checkproc then
        sysCALLQ(checkproc)
    endif
enddefine;

/*
-- Compiling the arguments --------------------------------------------
*/

define lconstant compile_exargs(checka, checki, checks)
        -> (nargs, sf_flags, veclist, reflist);
    ;;; Compiles an argument list for excall.
    ;;; If checka is true, argument types are checked. If checki is true
    ;;; indices are checked to be within vector bounds. If checks is
    ;;; true the stack length is checked after compilation.
    ;;; Returns
    ;;; -  Actual number of arguments, including hidden ones for fstrings.
    ;;; -  An integer giving the positions of single-float arguments.
    ;;; -  A list containing a vector for each indexed vector argument.
    ;;;    Each of these vectors has:
    ;;;     - the type of argument vector as specified by the keyword
    ;;;       in the code
    ;;;     - its position in the argument list
    ;;;     - the name of the variable holding the index at run-time
    ;;; -  A list containing a pair for each reference argument.
    ;;;    Each pair has the name of the variable as its front and the
    ;;;    access procedure for the vector as its back.

    if checks then ;;; Plant code to save stack length
        lvars stacklen = sysNEW_LVAR();
        sysCALL("stacklength");
        sysPOP(stacklen);
    endif;

    ;;; Compile argument expressions, noting positions of any that
    ;;; are vectors with subscripts in veclist, and planting code to store the
    ;;; subscripts themselves in variables at run-time. Likewise
    ;;; note those that are references, and plant code to put values into
    ;;; vectors. These vectors are fixed, hence ban on recursive calls.

    ;;; Also supports complex vectors by changing the index at this point -
    ;;; assumes that the calling procedure will provide the index as if
    ;;; pop-11 really had complex vectors, but sysFIELD needs index to
    ;;; underlying sfloat or dfloat vector.

    lconstant commaket = [ , ) ];

    [] ->> veclist -> reflist;
    0 ->> nargs ->  sf_flags;
    lvars nxt, index_no = 0, fstringlist = [];
    unless pop11_try_nextitem(")") then ;;; trap empty case
        repeat
            nargs + 1 -> nargs;
            lvars opt = pop11_try_nextitem(keywords);

            lvars arropt = lmember(opt, arrwords);
            if lmember(opt, vecwords) or arropt then
                if arropt then      ;;; array argument
                    pop11_comp_expr_to(commaket) -> nxt;
                    sysPUSHS(true);
                    sysCALL("arrayvector");
                    sysSWAP(1,2);
                    sysCALL("arrayvector_bounds");
                    sysSWAP(1,2);
                    sysERASE(true);
                    allbutlast(3, opt) <> "VEC" -> opt
                else
                    pop11_comp_expr_to("[") -> _;
                    pop11_comp_expr_to("]") -> _;
                    if checki then
                        sysCALLQ(check_index)
                    endif;
                    pop11_need_nextitem(commaket) -> nxt
                endif;
                lvars index_var = sysNEW_LVAR();
                consvector(opt, nargs, index_var, 3) :: veclist -> veclist;
                if opt == "CVEC" or opt == "ZVEC" then ;;; complex
                    sysPUSHQ(1);
                    sysCALL("fi_<<");
                    sysPUSHQ(1);
                    sysCALL("fi_-");
                endif;
                sysPOP(index_var);

            elseif lmember(opt, refwords) then  ;;; introduces a reference
                lvars
                    varname = itemread(),
                    (refvec, refaccess) = ref_vector(opt);
                sysPUSH(varname);
                sysUCALLQ(refaccess);
                sysPUSHQ(refvec);
                conspair(varname, refaccess) :: reflist -> reflist;
                pop11_need_nextitem(commaket) -> nxt

            elseif lmember(opt, constwords) then  ;;; introduces a constant
                lvars (refvec, refaccess) = ref_vector(opt);
                itemread() -> refaccess();
                sysPUSHQ(refvec);
                pop11_need_nextitem(commaket) -> nxt

            elseif opt == "SFLOAT" or opt == "SF" then
                true -> testbit(sf_flags, nargs-1) -> sf_flags;
                pop11_comp_expr_to(commaket) -> nxt;
                if opt == "SFLOAT" then
                    sysCALLQ(number_coerce(% 0.0s0 %))
                endif

            elseif opt == "DFLOAT" then
                pop11_comp_expr_to(commaket) -> nxt;
                sysCALLQ(number_coerce(% 0.0d0 %))

            elseif opt == "INT" then
                pop11_comp_expr_to(commaket) -> nxt;
                sysCALLQ(number_coerce(% 0 %))

            elseif opt == "FSTRING" then
                pop11_comp_expr_to(commaket) -> nxt;
                sysPUSHS(true);
                sysCALL("length");      ;;; get length of string
                lvars fstring_var = sysNEW_LVAR();
                sysPOP(fstring_var);
                fstring_var :: fstringlist -> fstringlist;

            elseif opt == "VOID" then
                nargs-1 -> nargs;
                pop11_ignore_expr_to([ , ) ^("[") ]) -> nxt;
                if nxt == "[" then
                    pop11_ignore_expr_to("]") -> _;
                    pop11_need_nextitem(commaket) -> nxt
                endif

            else
                pop11_comp_expr_to(commaket) -> nxt

            endif;

            if checka and opt then
                check_arg(opt)
            endif;

        quitif (nxt == ")") endrepeat;
    endunless;

    ;;; Plant code for string lengths
    ncrev(fstringlist) -> fstringlist;  ;;; correct order
    for fstring_var in fstringlist do
        nargs + 1 -> nargs;
        sysPUSH(fstring_var)
    endfor;

    if checks then ;;; Run-time check on number of arguments
        sysCALL("stacklength");
        sysPUSH(stacklen);
        sysCALL("-");
        sysPUSHQ(nargs);   ;;; stack should have increased this much
        sysCALL("==");
        lvars l4 = sysNEW_LABEL();
        sysIFSO(l4);
        sysPUSHQ(0); sysPUSHQ('excall: Stack length incorrect');
        sysCALL("mishap");
        sysLABEL(l4);
    endif
enddefine;

/*
-- Typespec routines --------------------------------------------------
*/

define lconstant make_typespec(nargs, sf_flags, result) /* -> spec */;
    ;;; Constructs typespec as per cons_access in REF * KEYS
    consvector(conspair(nargs, sf_flags), result, 2)
enddefine;


define lconstant typespec_from_name(wd) -> (nargs, sf_flags, result);
    ;;; Check that the typespec for this word is an external procedure
    ;;; and return the elements of the spec.
    ;;; Code adapted from exacc.p
    lvars id, fldmode, spec = false;
    if sys_current_ident(wd <> "':typespec'") ->> id then
        fast_destpair(fast_idval(id)) -> (fldmode, spec)
    endif;
    unless spec then
        mishap(wd, 1, 'excall: Need external declaration to check typespec')
    endunless;
    ;;; I think deref_struct1 not needed here
    unless spec.isvector then
        mishap(wd, 1, 'excall: External object not declared as a function')
    endunless;

    if ispair(spec(1) ->> nargs) then
        destpair(nargs) -> (nargs, sf_flags)
    else
        0 -> sf_flags
    endif;
    spec(2) -> result
enddefine;


define lconstant check_typespec(fname, nargs, sf_flags, res_type);
    lvars (nargs1, sf_flags1, res_type1) = typespec_from_name(fname);
    unless nargs1 == nargs then
        mishap(fname, nargs1, nargs, 3, 'excall: Wrong no. arguments')
    elseunless sf_flags1 = sf_flags then  ;;; can be bigint
        mishap(fname, sf_flags1, sf_flags, 3,
            'excall: Single-float flags disagree with SFLOAT arguments')
    elseunless (res_type1 or "void") == (res_type or "void") then
        mishap(fname, res_type1, res_type, 3, 'excall: Wrong result type');
    endunless
enddefine;

/*
-- Indexed vector addressing ------------------------------------------
*/

define lconstant exarg_addresses(nargs, veclist);
    ;;; Plant code to convert vector/subscript pairs into addresses.
    ;;; The stack increases by 1 before the first conversion; that
    ;;; high-water-mark is not subsequently exceeded, so we should not
    ;;; get a GC in critical code.

    lconstant twords = newassoc(
        [[BVEC byte] [IVEC int] [SIVEC short]
        [FVEC float] [SVEC float] [DVEC dfloat]
        [CVEC float] [ZVEC dfloat]]);
    lvars v, index_no = 0;
    for v in veclist do
        lvars (type, i, index_var, _) = destvector(v);

        ;;; argument vector to top of stack
        unless i == nargs then
            sysSWAP(1, nargs-i+1)
        endunless;

        ;;; index onto stack
        sysPUSH(index_var);
        sysSWAP(1, 2);          ;;; index below vec

        ;;; Replace n,vec by address
        ;;; Bits 8 & 9 set in final arg: address mode, fixed structure
        sysFIELD(false, conspair(twords(type), 1), false, 8:1400);

        ;;; Replace address in proper place on stack
        unless i == nargs then
            sysSWAP(1, nargs-i+1)
        endunless;
    endfor
enddefine;

/*
-- Main routine -------------------------------------------------------
*/

;;; Code to enable testing for recursive calls (need to dlocalise the flag so
;;; that mishaps don't disable excall). Maybe there's a neater way than this.
lvars inuse = false;
define lconstant in_use; inuse enddefine;
define updaterof in_use; -> inuse enddefine;
lconstant plant_inuse = sysCALLQ(% in_use %);
sysUCALLQ(% in_use %) -> updater(plant_inuse);
1 -> pdprops(plant_inuse);


define syntax excall;

    dlocal pop_autoload = false;

    lvars (checkr, checkf, checka, checki, checks, checkg) = compile_checks();

    if checkr then ;;; Mishap if recursive call
        sysLOCAL(plant_inuse);
        sysCALLQ(in_use);
        lvars l1 = sysNEW_LABEL(), l2 = sysNEW_LABEL();
        sysIFNOT(l1);
            sysPUSHQ(0); sysPUSHQ('Recursive use of excall not allowed');
            sysCALL("mishap");
        sysGOTO(l2);
        sysLABEL(l1);
            sysPUSHQ(true);
            sysUCALLQ(in_use);
        sysLABEL(l2);
    endif;

    lvars
        (func_name, res_type) = compile_funcname(),
        (nargs, sf_flags, veclist, reflist)
        = compile_exargs(checka, checki, checks);

    lvars spec = make_typespec(nargs, sf_flags, res_type);
    if checkf then
        check_typespec(func_name, nargs, sf_flags, res_type)
    endif;

    if checkg then  ;;; Protect against GC
        unless lmember(res_type, [^false void int sfloat]) then
            mishap(func_name, res_type, 2,
                'excall: Can not do GC check with this result type')
        endunless;
        lconstant gc_error = mishap(% 0,
            'excall error: GC during critical code, please report' %);
        sysLOCAL("pop_after_gc");       ;;; to restore if mishap occurs
        lvars save_pop_after_gc = sysNEW_LVAR();  ;;; to restore in other cases
        sysPUSH("pop_after_gc");        ;;; stack increases by 2 here
        sysPUSHQ(gc_error);             ;;; so GC should not occur when
        sysPOP("pop_after_gc");         ;;; exarg_addresses code runs
        sysPOP(save_pop_after_gc);
    endif;

    ;;; Get addresses of vector elements.
    ;;; From here run-time code is GC-sensitive, but should not trigger one
    exarg_addresses(nargs, veclist);

    ;;;   V V V V V   Plant call to the external function.

    sysPUSH(func_name);
    sysFIELD(nargs, spec, true, 1); ;;; can checking (or whatever) trigger GC?

    ;;;   ^ ^ ^ ^ ^

    if checkg then
        ;;; End of GC-sensitive code - restore pop_after_gc
        ;;; (Does not rely on localisation as current procedure may do more work.)
        sysPUSH(save_pop_after_gc);
        sysPOP("pop_after_gc");
    endif;

    ;;; Restore call-by-reference values
    lvars refpair;
    for refpair in reflist do
        sysCALLQ(back(refpair));
        sysPOP(front(refpair))
    endfor;

    if checkr then ;;; Unlock - again cannot rely on localisation
        sysPUSHQ(false);
        sysUCALLQ(in_use);
    endif;

    pop11_FLUSHED(%%) -> pop_expr_inst;
    false -> updater(pop_expr_inst);    ;;; no update mode
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Jul 25 2003
        Major revision:
          - Introduced syntax to control checking options, and did
            away with excall_check_gc.
          - Added support for:
            - argument type checking;
            - array arguments;
            - coercion of float and int arguments;
            - complex-valued arguments;
            - call-by-reference;
            - Fortran string arguments.
          - Generates typespecs from excall code rather than from
            exload code. Result type must now be given in front of
            function name (non-compatible change).
--- David Young, Jul  7 2003
        Set pop_autoload to <false> in compile_exargs (was v.v. slow)
--- David Young, Jun  4 2003
        Changed code that stores the vector indices during argument
        compilation. Originally these were kept on the stack, and stack
        swapping was used to bring them to the top then reinsert the
        address into the correct place. This meant a potentially large
        number of swaps for a long argument list. Now a vector is used
        to store the indices - this is allocated at compile-time for the
        normal case, but if a recursive call to the same code is made
        from the argument list it is necessary to allocate a vector at
        run-time, creating garbage.
--- David Young, May 19 2003
        Made GC-checking optional so that function results can be ddecimal.
        Testing indicates that this is safe under V15.52 on Solaris.
--- David Young, May 17 2003
        Corrected "double" in field spec to "dfloat"
 */
