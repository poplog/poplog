/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_text_area.p
 > Purpose:			Work out space required for a list of strings
 > Author:          Aaron Sloman, Apr 12 1997 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
;;;Tests

;;; rc_new_window(300,200,700,20,true);
vars strings=
	['Now is the time''for all good men and women''to stand up'
	 'and be counted'];
rc_start();
rc_window=>
'9x15' -> rc_font(rc_window);
rc_font(rc_window) =>
1 -> rc_xscale;
rc_text_area(strings, '6x13') =>

*/

section;

uses rclib
uses Xpw
uses XpwCore

uses rc_default_window_object;

define rc_text_area(strings, font) ->(widths, maxwidth, height, ascent);
	;;; Given a list of strings, and a font, return
	;;; a list of text widths, the maximum width, and the text height and ascent
	;;; for that font.
	;;; Use the window in rc_default_window_object.
	;;; All the numbers are integers, in pixel values, ignoring
	;;; current values of rc_xscale and rc_yscale.

	lvars
		w, string,
		maxwidth = 0,
		win = rc_widget(rc_default_window_object);

	font -> rc_font(win);

	XpwFontHeight(win) -> height;
	XpwFontAscent(win) -> ascent;

		[%for string in strings do
			lvars w = XpwTextWidth(win, string);

			if abs(w) > abs(maxwidth) then w -> maxwidth endif;
			w
    	endfor%]  -> widths;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Apr 29 1997
	Changed to use
		rc_default_window_object
		and to return pixel values, not scaled values
 */
