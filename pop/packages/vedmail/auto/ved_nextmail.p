/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/auto/ved_nextmail.p
 > Purpose:			Get next or previous mail file
 > Author:          Aaron Sloman, Feb  6 1992 (see revisions)
 > Documentation:	HELP * VED_GETMAIL
 > Related Files:	LIB * VED_GETMAIL
 */

/*
NB The two files
	$poplocal/local/auto/ved_prevmail.p
	$poplocal/local/auto/ved_nextmail.p
are linked together.
*/

;;; LIB VED_PREVMAIL                                         A.Sloman Nov 1991

;;; ved_prevmail, ved_nextmail. Used with LIB VED_GETMAIL

;;; Uses the variable vedmailfile, in ved_getmail

section;

define lconstant path_and_num() -> (path, numchars);
	;;; if file name does not end in a number then error, otherwise
	;;; return the pathname minus the number and the number
	lvars
		numchars = 0, path,
		char, n, mult = 1,
		pathlen = datalength(vedpathname),
		list;

	;;; get the digits at end of file name
	[% for n from pathlen by -1 to 1 do
		subscrs(n, vedpathname) -> char;
		quitunless(isnumbercode(char));
		char - `0`
		endfor %] -> list;

	if list == [] then
		vederror('FILENAME DOES NOT END IN NUMBER')
	endif;

	for n in list do
    	numchars + mult*n -> numchars;
		mult*10 -> mult
	endfor;
	
	allbutlast(length(list), vedpathname) -> path
enddefine;


define global ved_prevmail;
	lvars
		numchars, path;

	path_and_num() -> (path, numchars);

	if vedargument = 'q' then
		vedqget(edit(%path sys_>< (numchars - 1)%));
	else
		edit(path sys_>< (numchars - 1));
	endif
enddefine;

define global ved_nextmail;
	lvars
		numchars, path;

	path_and_num() -> (path, numchars);

	if vedargument = 'q' then
		vedqget(edit(%path sys_>< (numchars + 1)%));
	else
		edit(path sys_>< (numchars + 1));
	endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, May 14 1995
		Fixed to work with any file whose name ends in a number
		Does not need to be a current mail file.
--- Aaron Sloman, Apr 28 1993
	Fixed ismailfile to cope with automounted files.
--- Aaron Sloman, Mar 22 1992
	Added "q" option to allow the current file to be quit first
 */
