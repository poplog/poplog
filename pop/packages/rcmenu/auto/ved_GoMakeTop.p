/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/ved_GoMakeTop.p
 > Purpose:         Go to part of a library file and set it at top of window
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

section;

define lconstant settopwindow();
	;;; set the current line at the top of the window;
	vedline - 1 -> vedlineoffset;
	vedalignscreen();
enddefine;

define global constant procedure ved_GoMakeTop;
	;;; like ved_g, but puts located line at top of screen
	ved_g();
	settopwindow();	
enddefine;

define global constant procedure ved_#_/();
	;;; like search, but puts line with found string at top of screen
	veddo('/'<>vedargument);
	settopwindow();	
enddefine;

endsection;
