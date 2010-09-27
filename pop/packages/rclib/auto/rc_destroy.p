/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/auto/rc_destroy.p
 > Purpose:         Destroy rc_window
 > Author:          Aaron Sloman, Feb  7 1995
 > Documentation:
 > Related Files:
 */

section;
define rc_destroy();
	XptDestroyWindow(rc_window);
enddefine;
endsection;
