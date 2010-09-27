/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_print_strings.p
 > Purpose:			Print strings in graphic window, possibly centred
 > Author:          Aaron Sloman, Apr 12 1997 (see revisions)
 > Documentation:
 > Related Files:
 */
/*

rc_print_strings(x, y, strings, spacing, centre, font, bgcol, fgcol) -> (maxwidth, totalheight);

Print a list of strings in a box starting at location x,y (top left corner);

strings is a list of strings. Spacing indicates additional vertical
	spacing between strings.

x, and y are scaled relative to rc_xscale and rc_yscale and
	the current origin.

spacing is absolute, in pixels

centre is a boolean or he word "centre", or the word "left", or the word
	"right", indicating whether strings should be centred relative to the
	longest string.

font is a string specifying the font to be used.

bgcol and fgcol can each be either false (meaning use current defaults)
	or a string specifying background colour and foreground colour of the
	area within which the printing is to be done. In the case of bgcol the
	complete rectangular area is given the colour.

Note: the results returned may not be integers.

    uses rclib
    uses rc_window_object

    vars win1 = rc_new_window_object(400, 40, 500, 400,{250 200 1 -1} , 'win1');
    vars win1 = rc_new_window_object(400, 40, 500, 400,{250 200 -2 1} , 'win1');
rc_kill_window_object(win1);

vars strings=
	['Now is the time''for all good men and women''to stand up'
	 'and be counted'];
rc_destroy();
rc_start();
rc_window=>
'9x15' -> rc_font(rc_window);
'10x20' -> rc_font(rc_window);
rc_font(rc_window) =>
rc_text_area(strings, '6x13') =>

rc_start();
-1 -> rc_xscale; -1 -> rc_yscale;
rc_drawline(-200,145,200,145);
rc_print_strings(-25,45, strings,1, false, '8x13', 'pink', false) =>
rc_print_strings(25,-45, strings,1, false, '8x13', 'pink', false) =>
rc_print_strings(-150,145, strings,2, "left", '10x20', 'red', false) =>
rc_drawline(-200,85,200,85);
rc_print_strings(-150,85, strings,15, true, '10x20', 'gold', 'blue') =>
rc_print_strings(-150,85, strings,15, "centre", '10x20', 'cyan', 'blue') =>
rc_print_strings(-150,85, strings,15, "right", '10x20', 'yellow', 'blue') =>
rc_print_strings(-150,85, strings,15, "left", '10x20', 'grey85', 'blue') =>
rc_drawline(-200,-55,200,-55);
rc_print_strings(-150,-55, strings,5, "right", 'lucidasans-15', 'blue', 'yellow') =>

2 -> rc_xscale; -2 -> rc_yscale;
rc_print_strings(-150/2,145/2, strings,2, false, '8x13', 'pink', false) =>
rc_drawline(-100,-45,100,-45);
rc_print_strings(-75,-45, strings,0, true, '6x13', 'LightGrey', 'saddlebrown') =>
rc_print_strings(-75,-45, strings,2, true, '6x13', 'LightGrey', 'saddlebrown') =>
rc_drawline(-100,-75,100,-75);
rc_print_strings(-75,-75, strings,1, "right", '6x13', 'pink', 'blue') =>
rc_print_strings(-75,-75, strings,1, true, '6x13', 'white', false) =>
rc_drawline(-100,75,100,75);
rc_print_strings(-75,75, strings,10, true, '10x20', 'darkgreen', 'white') =>
*/

compile_mode :pop11 +strict;
section;

uses rclib;
uses rc_graphic;
uses rc_text_area;

global vars rc_print_strings_offset = 2;

define rc_print_strings(x, y, strings, spacing, centre, font, bgcol, fgcol) -> (maxwidth, totalheight);

	lvars (widths, maxwidth, height, ascent) = rc_text_area(strings, font);

	;;; add a bit to left and right
	maxwidth + rc_print_strings_offset*2 -> maxwidth;

	rc_window_sync();

	dlocal
		%rc_foreground(rc_window)%,
		%rc_font(rc_window)% = font;

	(height+spacing)*listlength(strings) -> totalheight;

	if bgcol then
		rc_draw_bar(x, y + totalheight*0.5/rc_yscale,
				totalheight/abs(rc_yscale), maxwidth/rc_xscale, bgcol);
	endif;

	if fgcol then
		fgcol -> rc_foreground(rc_window);
	endif;

	;;; Adjust y by ascender height, for location of first string
	y + ascent/rc_yscale -> y;

	lvars string, w;
	for string, w in strings, widths do
		lvars
			offset =
				if centre == "right" then maxwidth - rc_print_strings_offset - w
				elseif centre == "left" or not(centre) then
					rc_print_strings_offset
				else
					(maxwidth - w)/2.0
				endif,
			xloc = x + offset/rc_xscale;
		rc_print_at(xloc, y, string);
		y + (height + spacing)/rc_yscale -> y
	endfor;
	sys_grbg_list(widths);
	maxwidth -> maxwidth;
	totalheight -> totalheight;	
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov  9 1997
	Made to work with rc_xscale negative
--- Aaron Sloman, Nov  9 1997
	Changed to make the output width and heigh scale independent
--- Aaron Sloman, Sep  2 1997
	Added rc_print_strings_offset for spacing to left and right of strings
		Allowed "left" and "centre" as argument.
--- Aaron Sloman, Jul 15 1997
	Changed to allow centre argument to be "right", for right-aligned
	strings.
 */
