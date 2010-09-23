/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_delete_handler.p
 > Purpose:			Remove event handler from object
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

define rc_delete_handler(obj, handler, slot, /*num*/);

	lvars num = false;

	;;; check for optional arguments
	ARGS obj, handler, slot, &OPTIONAL num:isinteger;

	unless isprocedure(recursive_valof(handler)) then
		mishap('PROCEDURE OR ITS NAME NEEDED AS HANDLER', [%handler, obj, slot%])
	endunless;

	define lconstant SAME(item1, item2);
		item1 == item2
		or recursive_valof(item1) == recursive_valof(item2)
	enddefine;

	;;; Get the current handler(s)
	lvars handlers =
		rc_current_handlers(obj, slot, if num then num endif);

	;;; Now delete the handler
	if handlers then
		;;; something to delete, possibly
		if ispair(handlers) then
			;;; delete handler from the list
			delete(handler, handlers, SAME, 1)
		else
			;;; Return false, if deleting actual object
			if SAME(handlers, handler) then
				false
			else
				handlers
			endif;
		endif -> handlers;

		if handlers == [] then false else handlers endif
			-> rc_current_handlers(obj, slot, if num then num endif);
	else
		;;; no previous handler, so nothing to delete.
		mishap('CANNOT DELETE HANDLER', [%handler, obj, slot, if num then num endif%]);
	endif

enddefine;


endsection;
