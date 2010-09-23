/* --- Copyright University of Birmingham 2001. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_dial.p
 > Purpose:			Make a dial with moving pointer, supporting interaction
					(Not sure this has the right generalisations).
 > Author:          Aaron Sloman, 29 Aug 2000 (see revisions)
 > Documentation:   HELP RCLIB, TEACH RC_DIAL, TEACH RC_CONSTRAINED_POINTER
 > Related Files:	LIB  RC_CONSTRAINED_POINTER LIB RC_SLIDER, RC_CONTROL_PANEL,
 */

/*

rc_kill_window_object(win2);
rc_kill_window_object(win1);
vars win1 = rc_new_window_object( 750, 20, 400, 400, true, 'win1');
vars win2 = rc_new_window_object( 650, 20, 500, 500, {250 250 2 -2}, 'win2');


*/

section;
compile_mode :pop11 +strict;

uses rclib
uses rc_linepic
uses rc_window_object
uses rc_draw_blob_sector
uses rc_draw_pointer
uses rc_defaults
uses rc_informant
uses rc_constrained_pointer


;;; The width of the pivot will be multiplied by this to give
;;; the offset of the centre of the dial
global vars rc_dial_pivot_offset = 0.5;


define vars rc_dial(x, y, orient, angwidth, range, len, width, colour, bg) -> pointer;

	lvars specs = false, wid = false, typespec = false,
		rangemin = 0, rangemax = false, rangestep = false,
		defaultval = 0, win = rc_current_window_object,
		marks = false, labels = false, captions = false;

	ARGS
		x, y, orient, angwidth, range, len, width, colour, bg,
			&OPTIONAL
				wid:iswident, specs:isspecvector, typespec:isrctypespec,
				win:isrc_window_object,
				marks:ismarkspec, labels:islabelspec,
				captions:iscaptionspec;

	
	dlocal popradians = false;

	rc_check_window(win);

	lvars y_up = rc_yscale < 0 ;

	if isword(orient) then uppertolower(orient) -> orient endif;
	
	if orient == "up" then
		if y_up then 0 else 180 endif
	elseif orient == "down" then
		if y_up then 180 else 0 endif
	elseif orient == "right" then
		90
	elseif orient == "left" then
		-90
	elseif isnumber(orient) then orient
	else
		mishap('Number or orientation word wanted', [^orient]);
	endif -> orient;

	if isword(angwidth) then uppertolower(angwidth) -> angwidth endif;
	
	if angwidth == "semi" then 180
	elseif angwidth == "quarter" then 90
	elseif angwidth == "circle" then 360
	elseif isnumber(angwidth) then angwidth
	else
		mishap('Number or angwidthation word wanted', [^angwidth]);
	endif -> angwidth;
	

	;;; Fix offset of dial, previously done differently.
	lvars
		minang = 0,
		maxang = minang + angwidth,

	;

	create_rc_pointer_dial(
		x, y, orient, minang, maxang, len, width, colour, bg,
			range, marks, labels, captions,
				wid, specs, typespec) -> pointer;
	

	;;; now install it in window and draw it
	rc_install_pointer(pointer, win);

enddefine;

endsection;

/*

CONTENTS - (Use <ENTER> gg to access required sections)

 define vars rc_dial(x, y, orient, angwidth, range, len, width, colour, bg) -> pointer;

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 18 2001
	Added symbolic dial specs

--- Aaron Sloman, Mar 17 2001
	Transferred pivot adjustment to create_rc_pointer_dial

--- Aaron Sloman, Mar 11 2001
	Transferred much code to rc_constrained_pointer.
	Fixed offset for new drawing mechanisms.
 */
