/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/auto/menu_set_command.p
 > Purpose:			Present a text input panel to set up an ENTER command
 > Author:          Aaron Sloman, Aug 10 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/menu_set_command.p
 > Purpose:			Setting up ENTER commands
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */


/*
-- Utilities for ENTER menu items

See HELP * VED_MENU for permitted formats

	[ENTER <commandstring>  {xloc yloc} <explanation>]

Where the {xloc yloc} vector is optional.
*/

section;

uses rclib
uses rc_text_input
uses rc_getinput

uses rcmenulib

define menu_set_command(enterlist);
	;;; Invoked by menu items whose action is of the form
	;;; [ENTER <string> {x y} <strings>] or
	 ;;; The location specifier {x y} is optional
	;;; Where <strings> can either be a single string
	;;; Or a list of strings.

	;;; Creates a pop up explanation box, and puts the command string on
	;;; the status line.
	;;; The first time the propbox is created it is inserted in place of
	;;; <strings> in the list datastructure, so that it can be reused.

	lvars
		list, explanation, instruct, command,
		commands, coords = false;

    lconstant tellstrings
		= ['Edit the command,' 'then click on the OK button.'];

	;;; List should start with command format string
	dest(enterlist) ->(command, list);

	;;; See if it contains explanation string and/or location vector
	if null(list) then
		false -> explanation;
	else
		if isvector(hd(list)) then
			;;; location specifier
			dest(list) -> (coords, list);
		endif;
		if null(list) then false else hd(list) endif -> explanation;
	endif;

	if vedonstatus then vedstatusswitch() endif;

	lvars string;
	rc_getinput(
		if coords then explode(coords) else "middle", "middle" endif,
		[^^tellstrings
			% if islist(explanation) then dl(explanation)
			  elseif isstring(explanation) then explanation
			  endif %],
		command, [{font '9x15'}], 'ENTER Command')
		-> string;

	;;; Now obey the command and put it in the status line also
	if string then veddo(string, true) endif;
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 10 1999
	Converted to rclib version
*/
