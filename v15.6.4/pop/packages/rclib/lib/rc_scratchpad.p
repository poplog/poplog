/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_scratchpad.p
 > Purpose:			bridge between rc_graphic and rc_window_object
 > Author:          Brian Logan and Aaron Sloman, Jun 24 1997 (see revisions)
 > Documentation:
 > Related Files:	LIB * RC_WINDOW_OBJECT, * RC_SCRATCH_WINDOW
 */

/*

Procedures for manipulating rc_window and rc_current_window_object as a
`scratchpad' of tear off sheets.  Sheets (windows) which are `torn off'
the scratchpad are kept in a list, i.e. they are not garbage collected
until they are explictly `thrown away'.

uses rclib
uses rc_scratchpad

RCSCRATCH rc_drawline(0,-100,-100,-100);

rc_tearoff();

RCSCRATCH rc_drawline(0,100,-100,-100);

rc_tearoff();

rc_scratchpad('rc_drawline(100,100,-100,-100)');
rc_scratchpad('rc_drawline(100,-100,-100,-100)');

rc_kill_tearoffs();
RCSCRATCH rc_draw_blob(150-random(300),200-random(400),10+random(30),'red');

false -> rc_scratch_window;

RCSCRATCH rc_drawline(0,100,100,-100);

*/

section;
compile_mode :pop11 +strict;

uses rclib
uses rc_window_object
uses rc_scratch_window


;;; Make a scratchpad.
define rc_make_scratchpad();
	;;; not really needed now.
    rc_scratch_window ->;
enddefine;

;;; Call an rc_graphic procedure with the scratchpad as the current window.
define rc_scratchpad(args);
	dlocal ;;; rc_window,
		rc_current_window_object= rc_scratch_window;

	if isprocedure(args) then args()
	elseif islist(args) then
    	apply(dl(tl(args)), recursive_valof(hd(args)));
	elseif isstring(args) then
		pop11_compile(stringin(args))
	elseif islist(args) and front(args) == "POP11" then
		pop11_compile(back(args))
	endif
enddefine;


define syntax RCSCRATCH;
	lvars proc;
	sysPROCEDURE("RCSCRATCH", 0);
		pop11_comp_expr_to(";") ->;
	sysENDPROCEDURE();
	sysPUSHQ();
	sysCALL("rc_scratchpad")
enddefine;


endsection;
nil -> proglist;
/*

CONTENTS

 define rc_make_scratchpad();
 define rc_scratchpad(args);
 define syntax RCSCRATCH;

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 16 1997
	Moved rc_tearoff stuff to rc_scratch_window
	Simplified this stuff a lot by putting more in the other library
--- Aaron Sloman, Jul  4 1997
	Added offsets to rc_tearoff
 */
