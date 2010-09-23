/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/menu_do_scroll.p
 > Purpose:			Scroll a VED file vertically or horizontally
 > Author:          Aaron Sloman, Aug 25 1999 (see revisions)
 > Documentation:	Below
 > Related Files:	menu toplevel and others
 */

/*
;;; tests
menu_do_scroll(-1, "vert");
menu_do_scroll(1, "vert");
menu_do_scroll(1, "horiz");
menu_do_scroll(-1, "horiz");
*/


section;

uses rclib

define menu_do_scroll(direction, orientation);
	;;; Scroll up or down, left or right a half or 1/3 of screenful.
	;;; direction should be 1 or -1
	;;; 1 = vedscrollup or vedscrollleft

	if orientation == "vert" then
		lvars wline = vedline - vedlineoffset;
		vedscrollvert(direction * vedwindowlength div 2);
		vedjumpto(vedlineoffset + wline, vedcolumn);
	else ;;; assume orientation "hor"
		lvars wcol = vedcolumn - vedcolumnoffset;
		vedscrollhorz(direction * vedscreenwidth div 3);
		vedjumpto(vedline, vedcolumnoffset + wcol);
	endif;
	vedcheck();
	vedsetcursor();
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  3 1999
	Moved to rclib/auto, for use in some rc_ utilities.
 */
