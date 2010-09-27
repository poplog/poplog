/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/ved_read_from_file.p
 > Purpose:			Allow rclib action to read from specified file
 > Author:          Aaron Sloman, Aug 20 2000 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:	LIB ved_open_file, ved_write_to_file
 */

section;

compile_mode :pop11 +strict;

uses rc_defaults;

define :rc_defaults;

	;;; default location for file

	rc_ved_x_default = 300;
	rc_ved_y_default = 300;

	;;; default number of rows and columns

	rc_ved_cols_default = 40;
	rc_ved_rows_default = 8;
	
enddefine;

define vars ved_read_from_file(string, file) -> list;
	;;; Print the string in the file window then read a line of
	;;; text from the window, typed in by the user, and return it
	;;; as a list of text items

    define lconstant read_from_file();
		unless vedpresent(file) then
			;;; make sure the file is open
			ved_open_file(file,
				rc_ved_x_default, rc_ved_y_default,
				rc_ved_cols_default, rc_ved_rows_default, false);
		endunless;

		;;; Make the file current, and go to the end of it
		vededit(file);
		vedendfile();

		;;; Make all printing go to it.
		dlocal cucharout = vedcharinsert;

		define lconstant newcharin(dev) -> char;
			;;; read a character from device dev
			lconstant string = '0';
			sysread(dev, string, 1) ->;
			fast_subscrs(1, string) -> char
		enddefine;

		lvars
		;;; create a pseudo device for the file
			dev = consveddevice(sysfileok(file), 0, true),

		;;; create an item repeater for it
			itemrep = incharitem(newcharin(%dev%));
		
		;;; print the prompt string followed by a newline
		pr(string);
		pr(newline);
		vedcheck();
		vedcursorset();

		dlocal popnewline = true, popprompt = pop_readline_prompt;
			;;; Now read in a line of text

		lvars item;
		[% until (itemrep() ->> item) == newline do item enduntil %] -> list;
	enddefine;

	;;; cannot work if vedediting is false and xved not in use
	;;; so just use readline then:

	if not(vedediting) and vedusewindows/== "x" then
		readline() -> list
	elseif vedediting then read_from_file()
	else
		dlocal vedvedname;
		file -> vedvedname;
		vedinput(read_from_file);
		chain(ved_ved);
	endif;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 16 2002
		changed to work if invoked outside ved, but to use readline if
		xved not running
 */
