/* --- Copyright University of Birmingham 1993. All rights reserved. ------
 > File:			$poplocal/local/auto/ved_getlib.p
 > Purpose:			Get yourself a copy of a library file
 > Author:			Aaron Sloman, Oct 26 1993
 > Documentation:	Below
 > Related Files:	LIB ved_showlib
 */

/*

ENTER getlib <name>

This command will get you a private copy, in your current directory, of the
library file called <name>.p

It does the equivalent of

	ENTER showlib <name>

	ENTER name <name>.p

	ENTER w1

So that the file is both written to disk and kept in the VED buffer.

*/

section;

define global vars ved_getlib();
	;;; Invoke as ENTER getlib <name>

	;;; Get the desired library file, using vedargument
	ved_showlib();

	;;; extract the file name from the path name
	lvars file_name = sys_fname_name(vedpathname);

	;;; Use it to rename the current file
	veddo('name ' <> file_name);

	;;; make sure it's on disk
	ved_w1();

enddefine;

endsection;
