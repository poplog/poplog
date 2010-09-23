/* --- Copyright University of Sussex 2003. All rights reserved. ----------
 > File:            $popvision/lib/filesequence.p
 > Purpose:         Write and read sequences of files
 > Author:          David S Young, Nov 10 1993 (see revisions)
 > Documentation:   HELP *FILESEQUENCE
 */

compile_mode:pop11 +strict;

section;

define lconstant ncintstr(int, pos, wid, str) -> str;
    ;;; Puts an integer into an existing string, starting at pos,
    ;;; with width wid, padded on left with zeroes
    lvars int pos wid str;
    define dlocal cucharout(c);
        lvars c;
        c -> str(pos);
        pos + 1 -> pos
    enddefine;

    pr_field(int, wid, `0`, false, syspr);
enddefine;

define lconstant intlen(int) -> len;
    ;;; This should give the length needed by syspr to print the integer,
    ;;; without having to create a string each time. (Could use
    ;;; logs except rounding errors make for problems.)
    lvars int, len = 1;
    fi_check(int, false, false) -> ;
    if int fi_< 0 then
        2 -> len;
        -int -> int
    endif;
    until int fi_< 10 do
        len fi_+ 1 -> len;
        int fi_div 10 -> int
    enduntil
enddefine;

define lconstant getname(base_name, nwid, suffix, n0) -> (filename, npos);
    lvars base_name, nwid, suffix, n0, filename, npos;
    ;;; set up the file name in fixed-width case
    if intlen(n0) > nwid then
        mishap(n0, nwid, 2, 'Sequence number too large for width')
    endif;
    length(base_name) + 1 -> npos;
    base_name sys_>< inits(nwid) sys_>< suffix -> filename
enddefine;

define lconstant makename(int, npos, nwid, filename, suffix) /* -> filename */;
    lvars int, npos, nwid, filename, suffix;
    if nwid then
        if intlen(int) > nwid then
            mishap(int, nwid, 2, 'Sequence number too large for width')
        endif;
        ncintstr(int, npos, nwid, filename)
    else
        filename sys_>< int sys_>< suffix
    endif
enddefine;

define lconstant filesequence_nums(base_name, nwid, suffix, n0, ninc, n1)
        -> rep;
    lvars procedure rep;
    checkinteger(n0, false, false);
    checkinteger(ninc, false, false);
    lvars npos, sgn = sign(ninc), n = n0;
    if nwid then
        getname(base_name, nwid, suffix, n0) -> (base_name, npos)
    endif;

    define lvars procedure rep() /* -> filename */;
        if n1 and sgn * n > sgn * n1 then
            termin /* -> filename */
        else
            makename(n, npos, nwid, base_name, suffix) /* -> filename */;
            n + ninc -> n
        endif
    enddefine;

    define updaterof rep;
        n0 -> n
    enddefine;
enddefine;

define lconstant filesequence_list(base_name, nwid, suffix, l) -> rep;
    lvars procedure rep;
    lvars npos, ll = l;
    if nwid then
        getname(base_name, nwid, suffix, hd(ll)) -> (base_name, npos)
    endif;

    define lvars procedure rep() /* -> filename */;
        if ll == [] then
            termin /* -> filename */
        else
            makename(hd(ll), npos, nwid, base_name, suffix) /* -> filename */;
            tl(ll) -> ll
        endif
    enddefine;

    define updaterof rep;
        l -> ll
    enddefine;
enddefine;

lvars n1set;        ;;; for communication to filesout

define global filesequence(base_name, nwid, suffix) /* -> rep */;
    lvars n0 = 1, ninc = 1, n1 = false;
    if suffix.isinteger or suffix.islist then   ;;; optional n0 arg
        (base_name, nwid, suffix) -> (base_name, nwid, suffix, n0)
    endif;
    if suffix.isinteger then            ;;; optional ninc argument
        (base_name, nwid, suffix, n0) -> (base_name, nwid, suffix, n0, ninc)
    endif;
    if suffix.isinteger then            ;;; optional n1 argument
        (base_name, nwid, suffix, n0, ninc)
            -> (base_name, nwid, suffix, n0, ninc, n1)
    endif;
    n1 -> n1set;

    if n0.isinteger then
        filesequence_nums(base_name, nwid, suffix, n0, ninc, n1)
    elseif n0.islist then
        filesequence_list(base_name, nwid, suffix, n0)
    else
        mishap(n0, 1, 'Expecting list or integer')
    endif;
enddefine;

define global filesin(/* reader, base_name etc. */) -> rep with_nargs 4;
    lvars procedure (
        rep,
        reader,
        namerep = filesequence(/* base_name etc. */));
    -> reader;          ;;; off stack

    define lvars procedure rep() /* -> arr */;
        lvars dev, fname = namerep();
        if fname == termin or reader == identfn then
            fname /* -> arr */
        elseif readable(fname) ->> dev then
            sysclose(dev);
            reader(fname) /* -> arr */
        else
            false /* -> arr */
        endif
    enddefine;

    define updaterof rep;
            -> namerep()
    enddefine;
enddefine;

define global filesout(/* writer, base_name etc. */) -> consumer with_nargs 4;
    lvars procedure (
        consumer,
        writer,
        namerep = filesequence(/* base_name etc. */)),
        n1 = n1set;         ;;; via file local
    -> writer;          ;;; off stack

    define lvars procedure consumer(arr) /* -> finished - optionally */;
        ;;; Only returns a result if n1 is given.  Result is false until
        ;;; last file is written, when it becomes true.
        ;;; If the argument is <false>, just increments the index.
        lvars arr, filename = namerep();
        if arr and filename /== termin then
            arr -> writer(filename)
        endif;
        if n1 then
            filename == termin  /* -> finished */
        endif;
    enddefine;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Feb 28 2003
        Made n0 and ninc optional, and added list option
--- David S Young, Oct 23 1998
        filesequence procedure added and filesin and filesout modified to
        call it.
--- David S Young, Jun 23 1998
        filesin no longer tests for file existence if the 'reader' is
        identfn, to allow the caller access to a sequence of names.
        filesout now calls filesin to simplify the code.
--- David S Young, Aug  9 1996
        Allows negative increments in sequence numbering.
--- David S Young, Nov 12 1993
        N1 optional argument added to filesout, and data consumer allowed
        to skip a file if given <false> as argument.
 */
