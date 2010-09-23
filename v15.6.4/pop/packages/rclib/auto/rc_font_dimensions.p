/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_font_dimensions.p
 > Purpose:			Get font width, height, ascent
 > Author:          Aaron Sloman, Jun 13 2000
 > Documentation:
 > Related Files:	HELP RCLIB,
 >		REF XpwFontAscent XpwFontDescent XpwFontHeight XpwTextWidth
 */

/*

uses rclib

rc_font_dimensions('8x13', 'Now is the time for all')=>
** 184 13 11 2

rc_font_dimensions('12x24', 'Now is the time for all')=>
** 276 24 22 2

*/

section;

uses rclib
uses rc_default_window_object

define rc_font_dimensions(font, text)-> (width, height, ascend, descend);
	lvars
		win = rc_widget(rc_default_window_object);

	font -> rc_font(win);
	XpwTextWidth(win, text) -> width;
	XpwFontAscent(win) -> ascend;
	XpwFontDescent(win) -> descend;
	ascend fi_+ descend -> height;
enddefine;

endsection;
