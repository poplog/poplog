/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_set_window_scale.p
 > Purpose:			Replace LIB rc_set_scale, to suit RCLIB
 > Author:          Aaron Sloman, Jul  9 2000
 > Documentation:	HELP * RCLIB, HELP RC_GRAPHIC/rc_set_scale
 > Related Files:	LIB * rc_window_object, LIB * rc_set_scale
 */

;;; based on this
/* --- Copyright University of Sussex 1990. All rights reserved. ----------
 > File:            C.x/x/pop/lib/rc_set_scale.p
 > Purpose:			Easy setting of units in inches etc.
 > Author:          Poplog System, May 24 1990
 > Documentation:
 > Related Files:	LIB * RC_GRAPHIC
 */

section;
compile_mode :pop11 +strict;

/*
rc_set_window_scale(win_obj, type, xscale, yscale)

Type can be
	"inches"
		Then xscale is the number of inches per user unit to right
		Then yscale is the number of inches per user unit up screen

	"cm"
		Then xscale is the number of centimetres per user unit to right
		Then yscale is the number of centimetres per user unit up screen
	"frame"
		Then xscale is the number of window widths per user unit to right
		Then yscale is the number of window heights per user unit up screen
	false
		Just use xscale and yscale as given (y positive upwards)

*/

uses rclib
uses rc_window_object
uses rc_defaults

define: rc_defaults;
	rc_pixels_per_inch = 90;
enddefine;

define :method rc_set_window_scale(win_obj:rc_window_object, type, xscale, yscale);

	dlocal rc_current_window_object = win_obj;

	;;; remove all displayed objects. Will be redrawn by rc_shift_frame_by
	applist(rc_window_contents(win_obj), rc_undraw_linepic);

	if type == "inches" or type == "in" then
		;;; set to xscale inches per user unit, etc.
		rc_pixels_per_inch * xscale,
		-rc_pixels_per_inch * yscale

	elseif type == "cm" or type == "c" then
		;;; set to xscale centimetres per user unit, etc.
		rc_pixels_per_inch * xscale / 2.54,
		-rc_pixels_per_inch * yscale / 2.54

	elseif type = "frame" then
		;;; set to xscale frames per user unit etc.
		rc_setsize();
		rc_window_xsize * xscale,
		-rc_window_ysize * yscale

	else
		xscale,
		-yscale
	endif	  -> rc_yscale -> rc_xscale;


	rc_shift_window_frame_by(0, 0, win_obj);

enddefine;

endsection;
