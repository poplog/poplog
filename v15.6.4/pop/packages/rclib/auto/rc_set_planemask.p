/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_set_planemask.p
 > Purpose:         Utility for setting the PlaneMask
 > Author:          Aaron Sloman and Riccardo Poli, Jan  7 1997
 > Documentation:
 > Related Files:	LIB * RC_LINEPIC
 */


compile_mode :pop11 +strict;

uses xlib;
uses XGraphicsContext;

section;

define rc_set_planemask(window, mask);
	XSetPlaneMask( XtDisplay(window),
				  fast_XptValue(window, XtN usersGC),
				  mask);
enddefine;

endsection;
