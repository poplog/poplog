/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_current_handlers.p
 > Purpose:			Access or update event handling method or
 >					list of handlers in an instance.
 > Author:          Aaron Sloman, Mar  6 2000
 > Documentation:	HELP * RCLIB
 > Related Files:
 */

section;
compile_mode :pop11 +strict;

uses rclib
uses rc_mousepic
uses rc_window_object
uses ARGS

define rc_current_handlers(obj, slot, /*num*/) -> handlers;

	lvars num=false;

	;;; check for optional arguments
	ARGS obj, slot, &OPTIONAL num:isinteger;

	slot(obj) -> handlers;
	if num then
		;;; it's a vector and the numth item is wanted, e.g. 2 for button 2
		subscrv(num, handlers) -> handlers
	endif;

enddefine;


define updaterof rc_current_handlers(obj, slot, /*num*/);

	lvars num=false;

	;;; check for optional arguments
	ARGS obj, slot, &OPTIONAL num:isinteger;

	if num then
		;;; Handlers stored in a vector and the numth item is to be updated,
		;;; e.g. 2 for button 2
		-> subscrv( num, slot(obj))
	else
		-> slot(obj)
	endif;

enddefine;

endsection;
