/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/ved_write_to_file.p
 > Purpose:			Allow an action to write to a specified file
 > Author:          Aaron Sloman, Aug 20 2000
 > Documentation:	HELP RCLIB
 > Related Files:	LIB ved_open_file
 */

section;

compile_mode :pop11 +strict;


define ved_write_to_file(item, file);
	;;; Item should be a printable pop-11 item, e.g. a list, string number, etc.
	;;; Print it in the file.

	dlocal cucharout = vedcharinsert;

	vededit(file);

	vedendfile();

	pr(item);
	pr(newline);
	vedcheck();
	vedsetcursor();
	vedrefresh();
enddefine;

endsection;
