/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_coloured_square.p
 > Purpose:			Draw a coloured square
 > Author:          Aaron Sloman, Mar 16 1999
 > Documentation:	HELP RCLIB
 > Related Files:
 */

section;

uses rclib
uses rc_drawline_relative;

;;; Utility used below
define rc_draw_coloured_square(x, y, colour, width);
    ;;; Utility for drawing a square of a given width and colour,
    ;;; centred at x, y;
    rc_drawline_relative(
        x - width div 2, y, x + width div 2, y, colour, width);
enddefine;

endsection;
