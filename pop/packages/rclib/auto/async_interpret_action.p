/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/async_interpret_action.p
 > Purpose:			Interpret button action
 > Author:          Aaron Sloman, Apr 21 1997 (see revisions)
 > Documentation:
 > Related Files:  menu_interpret_action
 */

;;; compile_mode :pop11 +strict;

section;

;;;uses rcmenulib;
;;; uses menu_new_menu;
;;; uses menu_vedinput;

/*
-- Interpreting menu actions
*/
;;; menu_unix_obey defined separately

define async_interpret_action(action);
	;;; This procedure is run when the action is a list.
	;;; Only certain keywords are currently recognized.
	;;; More may be later.

	define lconstant do_action(action);
		lvars action, key = hd(action);
		if key == "ENTER" then
			valof("menu_set_command")(tl(action));
		elseif key == "MENU" then
			valof("menu_new_menu")(action(2), false);
		elseif key == "POP11" then
			;;; postpone action if appropriate
			;;; no longer needed
			;;; async_apply(async_compile(%tl(action)%));
			async_compile(tl(action));
		elseif key == "POPNOW" then
			;;; Do it now
			async_compile(tl(action));
		elseif key == "DEFER" then
			;;; 'DEFERRING in async_interpret_action'=>
			rc_defer_apply(async_interpret_action(%tl(action)%));
		elseif key == "VEDDO" then
			;;; should be followed by a string
			veddo(tl(action)(1), true);
		elseif key == "UNIX" then
			;;; postpone autoloading, via valof
			valof("async_unix_obey")(tl(action))
		else
			mishap('UNRECOGNIZED TYPE OF MENU ACTION', [^action])
		endif;
	enddefine;
	
	rc_handle_vedwarpcontext(action, rc_active_window_object, do_action);
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  7 2002
		Adjusted to take account of recent change in lib rc_mousepic
--- Aaron Sloman, Aug  4 2002
		Made to use rc_handle_vedwarpcontext
--- Aaron Sloman, Sep 19 1999
	Modified for rcmenus
--- Aaron Sloman, Jun 26 1997
	Introduced DEFER type action
--- Aaron Sloman, Jun 21 1997
	Reintroduced distinction between [POP11 ..] and [POPNOW ...]
 */
