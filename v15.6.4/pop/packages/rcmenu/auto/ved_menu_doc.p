/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/auto/ved_menu_doc.p
 > Purpose:			Get doc file and go to location
 > Author:          Aaron Sloman, Sun Dec  5  1993
 > Documentation:	HELP * VED_MENU
 > Related Files:   LIB * VED_MENU
 */

/*

ENTER menu_doc <command> <arg> <searchstring>

	Does the command with the arg
	Searches for the search string
	Makes the line top of window

E.g.

ENTER menu_doc help strings EQUALITY OF STRINGS

	Does, in appropriate environment

		HELP STRINGS
		Search for 'EQUALITY OF STRINGS'
		etc

*/


section;

uses ved_GoMakeTop;

define global vars procedure ved_menu_doc();
	lvars command, name, extras, strings, len;
	dlocal vedwarpcontext = false;
	sysparse_string(vedargument, false) -> strings;
	if listlength(strings) < 2 then
		vederror('menu_doc: ARGUMENT MISSING AFTER:- ' sys_>< vedargument)
	else
		destpair(strings) -> (command, strings);
		destpair(strings) -> (name, strings);
		veddo(command sys_>< vedspacestring sys_>< name, true);
		if strings /== [] then
			;;; extra argument, get from vedargument
			datalength(command) + datalength(name) + 2 -> len;
    		allbutfirst(len, vedargument) -> extras;
			vedlocate(extras);
			dlocal vedargument = nullstring;
			ved_GoMakeTop();
		endif
	endif;
	if vedusewindows = "x" then
		;;; raise the new file
		true -> xved_value("currentWindow", "raised");
		;;; But don't make it the focus
		false -> wvedwindowchanged;
	endif;
enddefine;

endsection;
