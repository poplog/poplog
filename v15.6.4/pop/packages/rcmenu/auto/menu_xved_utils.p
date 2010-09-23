/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/menu_xved_utils.p
 > Purpose:         Stuff for clipboards, etc. in XVED
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

/*
See    REF * xved / Clipboard

I have not really sussed out how these xved utilities work on the
current selection and clipboard. There are probably better ways
of doing things. Undo does not seem to work.

*/

section;
uses xved;
;;; uses set_output;

#_IF pop_internal_version > 142300
	
	uses vedselection_clear;

	uses vedselection_compile;

	uses vedselection_cut;

	uses vedselection_undo;

#_ELSE

global vars procedure(
	vedselection_clear   = $-xved$-xved_seln_clear,

	vedselection_compile = $-xved$-ved_lmr_from_clipboard,

	vedselection_cut     = $-xved$-xved_seln_cut,

	vedselection_undo    = $-xved$-xved_seln_undo);

#_ENDIF


define lconstant check_clipboard();
	;;; ved_w();	;;; a precaution in case of crashes
	unless isstring(vvedclipboard) then
		vederror('THE CLIPBOARD IS EMPTY')
	endunless
enddefine;

define menu_clipboard_help();
	;;; Get help on current selection
	;;; similar to vedgetsysfile_from_clipboard();
	check_clipboard();
	menu_vedinput(menu_veddo(%'help ' sys_>< vvedclipboard, true%))
enddefine;


define menu_clipboard_paste();
	check_clipboard();
	dlocal vedbreak = false, vedediting = true;
	vedinsertstring(vvedclipboard);
enddefine;

define menu_clipboard_clear();
	menu_vedinput(vedselection_clear(%false%));
enddefine;

define menu_clipboard_cut();
	;;; Delete selected text
	check_clipboard();
	dlocal vedediting = true;
	vedselection_cut();
enddefine;

define menu_clipboard_move();
	;;; move selected text to current location
	check_clipboard();
	dlocal vedediting = true, vedbreak = false;
	vedpositionpush();
	lvars stack = copylist(vedpositionstack);
	vedselection_cut();
	stack -> vedpositionstack;
	vedpositionpop();
	vedinsertstring(vvedclipboard);
enddefine;


define menu_clipboard_transcribe();
	;;; copy selected text to current location
	check_clipboard();
	dlocal vedediting = true, vedbreak = false;
	vedinsertstring(vvedclipboard);
enddefine;

define menu_clipboard_undo();
	;;; Not sure what this is supposed to do!
	dlocal vedediting = true, vedbreak = false;
	menu_vedinput(vedselection_undo);
enddefine;

define menu_clipboard_compile();
	;;; compile selected text from clipboard and redirect to
	;;; vedlmr_print_in file
	lvars string = vedlmr_print_in_file;
	unless isstring(string) then
		if string = true then true
		else 'output.p'
		endif -> string
	endunless;

	dlocal cucharout = set_output(string), vedwarpcontext = false;
	;;; No need to call menu_vedinput here. See menu
	vedselection_compile();
	;;; put mouse pointer back
	false -> wvedwindowchanged;
enddefine;

global vars menu_xved_utils = true;
endsection;
