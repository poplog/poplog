/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_poster.p
 > Purpose:			Display a message
 > Author:          Aaron Sloman, 20 May 1997 (see revisions)
 > Documentation:
 > Related Files:	LIB * RC_MESSAGE, RC_MESSAGE_WAIT
 */
/*

vars strings=
	['Now is the time''for all good men and women''to stand up'
	 'and be counted'];

;;;(x,y, strings, spacing, centre, font, bgcol, fgcol) ->win_obj;
vars
	windows =
	  [%
		rc_poster(10,10,strings,0, true, '9x15', false, false),
		rc_poster(300,10,strings,1, "left", '8x13bold', false, false),
		rc_poster(50,200,strings,2, "right", '10x20', 'darkslategrey', 'yellow'),
		rc_poster(400,200,strings,3, true, 'lucidasans-20', 'yellow', 'blue'),
		rc_poster(70,500,['Hi there'],0, true, 'lucidasans-20', 'yellow', 'blue'),
		rc_poster(500,500,['Hi there'],4, true, 'lucidasans-20', 'black', 'white')
	 %];

applist(windows, rc_kill_window_object);

*/

compile_mode :pop11 +strict;

uses rclib;
uses rc_window_object;
uses rc_mousepic;

uses rc_print_strings;
section;


define rc_poster(x,y, strings, spacing, centre, font, bgcol, fgcol) -> message_window;

	lvars
		oldwinobj = rc_current_window_object,
		(list, w, h, ) = rc_text_area(strings, font),
		message_window,
		width = w + max(2, rc_print_strings_offset*2),
		height = (h+spacing)*length(strings);

	rc_new_window_object(x, y, width, height, {0 0 1 1}, 'RC_MESSAGE') -> message_window;

	rc_window_sync();

	rc_print_strings(0, 0, strings, spacing, centre, font, bgcol, fgcol) -> (, );
	sys_grbg_list(list);
	[] -> list;
	if oldwinobj then oldwinobj else false endif -> rc_current_window_object;
enddefine;


endsection;
/*

CONTENTS

 define lconstant destroy_message(win_obj, x, y, modifier);
 define rc_poster(x,y, strings, spacing, centre, font, bgcol, fgcol) -> message_window;


*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov  7 1997
	Put in uses rc_print_*strings
--- Aaron Sloman, Sep  2 1997
	Improved handling of spacing, and left/right margins, controlled by
		rc_print_strings_offset
 */
