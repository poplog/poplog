/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            $poplocal/local/lib/rc_swap_context.p
 > Purpose:         Save and restore rc_contexts
 > Author:          David S Young, Nov 26 1992
 > Documentation:   HELP RC_SWAP_CONTEXT
 > Related Files:   LIB *RC_GRAPHIC, LIB *RC_CONTEXT
 */


/* Package to allow procedures to conveniently save and restore an
rc_context.  A procedure that wishes to save the current rc_context
on entry and restore it on exit, and to restore its "own" context
on entry and restore it on exit, simply has to include the
statement

    rc_swap  <identifier>

where identifier is a unique identifier for the context to be used by
this procedure. */

uses rc_graphic
uses rc_context

;;; Properties for holding window contexts.

lconstant
    my_contexts = newproperty([], 10, false, "tmparg"),
    their_contexts = newproperty([], 10, false, "tmparg"),
    in_my_contexts = newproperty([], 10, false, "tmparg");

;;; Recursive calls with same id are forbidden to avoid having to stack
;;; contexts, and the procedures check dlocal_context in order to avoid
;;; overwriting my_context and their_context when requestline
;;; (or anything else) suspends the current process.

define rc_swap_context(dl_cont, id); lvars dl_cont, id;
    ;;; Save global context and set up current context
    lvars my_context;

    ;;; Only act on normal entry
returnunless(dl_cont == 1);

    ;;; check for recursive entry
    if in_my_contexts(id) then
        mishap(0, 'Recursive calls to rc_swap_context not allowed')
    endif;
    true -> in_my_contexts(id);

    if rc_window.xt_islivewindow then
        rc_context(their_contexts(id))
    else
        false
    endif -> their_contexts(id);

    if (my_contexts(id) ->> my_context) then
        my_context -> rc_context()
    else
        false -> rc_window
    endif
enddefine;

define updaterof rc_swap_context(dl_cont, id); lvars dl_cont, id;
    ;;; Save current context and set up global context
    lvars their_context;

    ;;; Only act on normal exit or mishap
returnunless(dl_cont == 1 or dl_cont == 2);

    if rc_window.xt_islivewindow then
        rc_context(my_contexts(id))
    else
        false
    endif -> my_contexts(id);

    if (their_contexts(id) ->> their_context) then
        their_context -> rc_context()
    else
        false -> rc_window
    endif;

    false -> in_my_contexts(id)
enddefine;

define macro rc_swap(id);
    lvars id;
    "dlocal", 0, "%", "rc_swap_context", "(",
    "dlocal_context", ",", id, ")", "%", ";"
enddefine;
