/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/ved_setwindow.p
 > Purpose:         Replacement for vedsetwindow
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

/*

This is somewhat better than vedsetwindow, in XVed it can be mapped
onto ESC w. Instead of switching between two sizes it will cycle
between sizes determined by ved_set_win_multipliers

*/

;;; Users can set this. It depends on screen size and font size
global vars max_screen_lines = 43;

;;; Successive multipliers for window size. Occurrences of 0 will be
;;;	replaced by a reference holding original size of the window,
;;; and the list will be made circular.
global vars ved_set_win_multipliers = {0.5 0.25 0.5 1 1.3 1};


define ved_setwindow();
    ;;; Toggle window size, depending on its current state

    ;;; Create a property to record state for each window
    lconstant procedure file_prop = newvedfileprop();

	;;; if not running XVED, do vedsetwindow and return
	returnunless(vedusewindows == "x")(vedsetwindow());

	;;; get the size_info and state for this window
    lvars oldsize, index, size_info = file_prop();

	if size_info == undef then
		;;; Initialize it
		conspair(0, vedscreenlength) ->> size_info -> file_prop();
	endif;
	
	destpair(size_info) -> (index, oldsize);

	(index mod datalength(ved_set_win_multipliers)) -> index;
	index + 1 -> front(size_info);

	;;; multiply window size
	min(max_screen_lines,
		 round(
			oldsize * ved_set_win_multipliers(index + 1)))
		-> xved_value("currentWindow", "numRows");

	;;; Ensure focus remains in the window. Doesn't always work
	vedcurrentfile -> vedinputfocus;
	true -> wvedwindowchanged
enddefine;
