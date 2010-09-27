/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/auto/rc_window_dimensions.p
 > Purpose:         Get or update height and width of rc_graphic window
 > Author:          Aaron Sloman, Oct 23 1995
 > Documentation: 	See example below
 > Related Files:	LIB * rc_window_coords
 */

/*

rc_start();

;;; Change window size and check this
rc_window_dimensions() =>

600,800 -> rc_window_dimensions();
60,60 -> rc_window_dimensions();

vars x;
for x from 1 by 10 to 700 do
	;;; just keep changing the x dimension
	;;; try this with different manually adjusted window heights
	x, false -> rc_window_dimensions()
endfor;

*/

section;
;;; We define procedures to access and
;;; update the curent window dimensions.


compile_mode :pop11 +strict;

define vars procedure rc_window_dimensions() -> (width, height);
	;;; Return width and height position of rc_window on screen
	lvars width,height;
	XptWidgetCoords(XptShellOfObject(rc_window)) ->(, ,width, height);

enddefine;

define updaterof rc_window_dimensions(width, height);
	;;; integers width and height should be on the stack
	false,false,width,height,->
		XptWidgetCoords(XptShellOfObject(rc_window));

enddefine;

endsection;
