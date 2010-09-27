/* --- Copyright University of Sussex 1990. All rights reserved. ----------
 > File:            $poplocal/local/auto/ved_mem.p
 > Purpose:			Record or return to file and line number
 > Author:          Aaron Sloman, Dec 22 1988 (see revisions)
 > Documentation:	HELP * VEDMEMFILE
 > Related Files:	ved_gomem.p gomem.p (all linked)
 */

;;; Based in part on an idea suggested by Nicola Yuill

section;

uses sysdefs

global vars vedmemfile; 		;;; Information is stored in files
								;;; whose names start with this string


#_IF DEF UNIX
	lconstant memjoiner = '.';	;;; precedes suffix in memory files.
#_ELSE
	lconstant memjoiner = '_';
#_ENDIF

unless isstring(vedmemfile) then
#_IF DEF UNIX
	'$HOME/.memfile' -> vedmemfile
#_ELSE
	systranslate('SYS$LOGIN') dir_>< 'memfile' -> vedmemfile
#_ENDIF
endunless;

define lconstant memfilename(string) -> string;
	;;; The argument to ved_mem, or ved_gomem, or gomem is -string-. To
	;;; get the name of the file where information is stored append it to
	;;; vedmemfile, unless it is empty.
	lvars string;
	if string = nullstring then
		vedmemfile
	else
		vedmemfile sys_>< memjoiner sys_>< string
	endif -> string
enddefine;

define global ved_mem;
    ;;; Remember current file and line number in the appropriate file
    ;;; for later use by gomem or ved_gomem.
    dlocal pop_pr_quotes = true, pop_file_versions = 1,
		cucharout = discout(memfilename(vedargument));
    printf(vedline,vedpathname,'%p\n%p\n');
	cucharout(termin);
enddefine;

define global ved_gomem;
	;;; Go to remembered file, of type specified by -vedargument-
	;;; and go to line number stored there. This also works outside
	;;; VED if -vedargument- has been set up.
    lvars file, dev = readable(memfilename(vedargument)),
		filename, visible = vedstartwindow >> 1 ;
	if dev then
		incharitem(discin(dev)) -> file;	;;; create item repeater
    	file() -> filename;					;;; get the file name
    	file() -> vvedgotoplace;			;;; get the line number
		;;; subtract -visible- to get some context visible
		max(1, vvedgotoplace - visible) -> vvedgotoplace;
		sysclose(dev);
		vedinput(
			procedure;
				;;; go to required place
				vedjumpto(vedline + visible, 1);
			endprocedure);
		edit(filename);
	else
		vederror('NO MEMFILE FOR ' sys_>< vedargument)
	endif
enddefine;

define global syntax gomem;
	;;; For use outside VED. Go to the remembered file and line number
	;;; stored in the "memfile" corresponding to the argument.
    dlocal popnewline = true;
	sysPUSHQ(rdstringto([; ^termin ^newline]));
	sysPOP("vedargument");
	sysCALL("ved_gomem");
	";" :: proglist -> proglist;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 27 1990
	removed call of vedmidwindow and achieved the same effect better.
--- Aaron Sloman, Apr 17 1990 Changed to use syntax word for "gomem".
	Also tidied up, and generalised for VMS. Updated HELP file.
--- Aaron Sloman, May 31 1989 better error message if file not found
 */
