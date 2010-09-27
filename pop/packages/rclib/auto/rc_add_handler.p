/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_add_handler.p
 > Purpose:			Add event handler
 > Author:          Aaron Sloman, Mar  6 2000
 > Documentation:	HELP * RCLIB
 > Related Files:
 */


section;
compile_mode :pop11 +strict;

uses rclib
uses rc_mousepic
uses rc_window_object
uses rc_current_handlers
uses ARGS

define rc_add_handler(obj, handler, slot, /*num, atend*/);

	lvars num = false, atend = false;

	;;; check for optional arguments
	ARGS obj, handler, slot, &OPTIONAL num:isinteger, atend:isboolean;

	unless not(handler) or isprocedure(recursive_valof(handler)) then
		mishap('PROCEDURE OR ITS NAME NEEDED AS NEW HANDLER', [%handler, obj, slot%])
	endunless;

	if handler then

		;;; Get the current handler(s) to add handler
		lvars handlers =
			rc_current_handlers(obj, slot, if num then num endif);

		;;; Now add the new handler
		if handlers then
			;;; If there's a procedure or word, not in a list, put it in a list.
			if ispair(handlers) then
				;;; it's already a list: add the new one at end or front
				if atend then
					handlers <> [^handler]
				else
					[^handler ^^handlers]
				endif
			else
				;;; old handler not a list, so start a list with old and new
				if atend then
					[^handlers ^handler]
				else
					[^handler ^handlers]
				endif
			endif
		else
			;;; no previous handler, so just install the new one.
			handler
		endif
	else
		;;; false, i.e. remove all handlers
		false
	endif
			-> rc_current_handlers(obj, slot, if num then num endif);

enddefine;


endsection;
