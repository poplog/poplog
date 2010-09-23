/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_font.p
 > linked to:       $poplocal/local/auto/rc_font.p
 > Purpose:         Get or set font of rc_graphic window
 > Author:          Aaron Sloman,  31 Dec 1996 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:	LIB RCLIB,  LIB RC_FOREGROUND
 */

/*

rc_start();
rc_font(rc_window) =>


'6x13bold' -> rc_font(rc_window);

vars fff = rc_font(rc_window);
fff =>

rc_print_at(-150, 175, 'What a PRETTY picture');
'9x15bold' -> rc_font(rc_window);
rc_print_at(-150, 130, 'What a PRETTY picture');
fff -> rc_window(XtN font);
fff -> rc_font(rc_window);
'r13' -> rc_font(rc_window);
rc_print_at(-150, 100, 'What a PRETTY picture');
'r16' -> rc_font(rc_window);
rc_print_at(-150, 85, 'What a PRETTY picture');
'r24' -> rc_font(rc_window);
rc_print_at(-150, 50, 'What a PRETTY picture');

'lucidasans-bold-10' -> rc_font(rc_window);
rc_print_at(-150, 15, 'What a PRETTY picture');
'lucidasans-bold-12' -> rc_font(rc_window);
rc_print_at(-150, 0, 'What a PRETTY picture');
'lucidasans-bold-14' -> rc_font(rc_window);
rc_print_at(-150, -30, 'What a PRETTY picture');
'lucidasans-bold-18' -> rc_font(rc_window);
rc_print_at(-150, -55, 'What a PRETTY picture');
'lucidasans-bold-24' -> rc_font(rc_window);
rc_print_at(-150, -80, 'What a PRETTY picture');

*/

uses rc_graphic;
uses rclib;

compile_mode :pop11 +strict;
section;

;;; Cached value of font and mapping. Could be generalised
;;; by remembering current font of any window in a property?
lvars
	current_font = false,
	current_window = false,
	procedure font_mapping = newmapping([], 32, false, false);

define global rc_font(window) -> font;
	rc_check_window(window);
	;;; return current font
	if isXptDescriptor(current_font)
	and window == current_window then
		current_font
	else
		;;; remember which window it is
		window -> current_window;
		;;; get the current font (a descriptor)
		window(XtN font) ->> current_font;
	endif -> font;
enddefine;

define updaterof rc_font(font, window);
	rc_check_window(window);
	;;; change current font
	if isXptDescriptor(font) and font == current_font
	and current_window == window
	then
		;;; do nothing -- already current
	else
		if isstring(font) then
			lvars desc = font_mapping(font);
			if isXptDescriptor(desc) then
				desc -> window(XtN font)
			else
				;;; Font not recognized. Use the string
				;;; Set font and save string-to-descriptor mapping
				font -> window(XtN font);
				window(XtN font) ->> desc -> font_mapping(font)
			endif;
		elseif isXptDescriptor(font) then
			;;; It is already a saved font descriptor
			font ->> window(XtN font) -> desc;
		else
			mishap(font, 1, 'String (font name) needed')
		endif;
		;;; Remember most recent window and font.
		desc -> current_font;
		window -> current_window;						
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  8 1999
	Changed to use XptDescriptor rather than integers to remember
	fonts.
--- Aaron Sloman, Aug  4 1997
		Introduced check for live window
*/
