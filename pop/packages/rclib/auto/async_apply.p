/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/async_apply.p
 > Purpose:         Apply a procedure that may change Ved
 > Author:          Aaron Sloman, Jan  4 1997 (see revisions)
 > Documentation:
 > Related Files:	Based on LIB * MENU_APPLY
 */


compile_mode :pop11 +strict;

section;

define lconstant ved_apply(proc);
	lvars
		procedure proc, oldfile = vedcurrentfile,
		oldline = vedline,
		oldcolumn = vedcolumn;
	dlocal vedwarpcontext = false;
	;;; Run the procedure
	proc();
	;;; Now update edit buffers if in Xved
	if vedusewindows = "x" and vedinvedprocess and vedediting then
		if vedline /== oldline or vedcolumn /== oldcolumn then
			vedcheck();
			vedsetcursor();
			if vedcurrentfile /== oldfile then
			 	true -> xved_value("currentWindow", "raised");
			endif;
			false -> wvedwindowchanged;
		endif
	endif;
enddefine;


define async_apply(proc);
	;;; apply the procedure, raise any new file, but don't
	;;; warp context. Suitable for buttons rotating or swapping
	;;; files, etc.
	lvars procedure proc, oldfile = vedcurrentfile;

	dlocal vedwarpcontext = false;
	;;; Run the procedure
	if vedusewindows == "x" and vedinvedprocess then
		vedinput(ved_apply(%proc%));
	else
		ved_apply(proc);
		;;; Process any remaining signals
		sys_raise_ast(false);
		lvars p;
		if not(null(ved_char_in_stream)) and isprocedure(hd(ved_char_in_stream) ->> p) then
			tl(ved_char_in_stream) -> ved_char_in_stream;
			ved_apply(p)
		endif;
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 22 1997
	Changed conditionals to loops
--- Aaron Sloman, Jun 21 1997
	Attempted to catch things liked pop_ui_edittool which insist on putting things
	in ved input stream, rather than checking if it is safe to execute now.
 */
