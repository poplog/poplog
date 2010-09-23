/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_mems.p
 > Purpose:			Record or return to file and line number
 > Author:          Aaron Sloman, Feb  1 1996
 > Documentation:	HELP * VEDMEMFILE
 > Related Files:	ved_gomems.p gomems.p
 */

;;; Based in part on an idea suggested by Nicola Yuill

section;

uses sysdefs

global vars vedmemsfile; 		;;; Information is stored in files
								;;; whose names start with this string


#_IF DEF UNIX
	lconstant memjoiner = '.';	;;; precedes suffix in memory files.
#_ELSE
	lconstant memjoiner = '_';
#_ENDIF

unless isstring(vedmemsfile) then
#_IF DEF UNIX
	'$HOME/.memsfile' -> vedmemsfile
#_ELSE
	systranslate('SYS$LOGIN') dir_>< 'memsfile' -> vedmemsfile
#_ENDIF
endunless;

define lconstant memsfilename(string) -> string;
	;;; The argument to ved_mems, or ved_gomems, or gomems is -string-. To
	;;; get the name of the file where information is stored append it to
	;;; vedmemsfile, unless it is empty.
	lvars string;
	if string = nullstring then
		vedmemsfile
	else
		vedmemsfile sys_>< memjoiner sys_>< string
	endif -> string
enddefine;

define global ved_mems;
    ;;; Remember current files and line numbers in the appropriate file
    ;;; for later use by gomems or ved_gomems.
    dlocal pop_pr_quotes = true, pop_file_versions = 1,
		cucharout = discout(memsfilename(vedargument));


	vedappfiles(
		procedure();
			lvars pathname = vedpathname;

			if isstartstring('/tmp_mnt', pathname) then
				allbutfirst(8, pathname) -> pathname
			endif;

    		printf(if vedwriteable then "true" else "false" endif,
					vedline,pathname,'%p\n%p\n%p\n');
			endprocedure);
		
	cucharout(termin);
enddefine;

define global ved_gomems;
	;;; Go to remembered file, of type specified by -vedargument-
	;;; or default file otherwise.
	;;; It will contain information about one or more files.
	;;; Restore those files, their saved value for vedline and
	;;; whether they are iswriteable or not.
    lvars
		filerep, filename, iswriteable,
		dev = readable(memsfilename(vedargument)),
		visible = vedstartwindow >> 1 ;
	if dev then
		;;; File exists. Create item repeater
		incharitem(discin(dev)) -> filerep;
		;;; Read in saved file information
		lvars item, list;
		[%
			repeat

    			filerep() -> filename;					;;; get the filerep name
			quitif(filename == termin);
    			filerep() -> vvedgotoplace;			;;; get the line number
				filerep() -> iswriteable;
				[^filename ^vvedgotoplace ^(iswriteable == "true")]

			endrepeat %] -> list;

		sysclose(dev);

		for item in fast_ncrev(list) do
			dl(item) -> (filename, vvedgotoplace, iswriteable);

			edit(filename);
			;;; subtract -visible- to get some context visible
			vedjumpto(vedline + visible, 1);
			iswriteable -> vedwriteable;
		endfor
	else
		vederror('NO MEMFILE FOR ' sys_>< vedargument)
	endif
enddefine;

define global syntax gomems;
	;;; For use outside VED. Go to the remembered file and line number
	;;; stored in the "memsfile" corresponding to the argument.
    dlocal popnewline = true;
	;;; read the argument and push appropriate instrunction onto VED
	;;; input stream
	sysPUSHQ(rdstringto([; ^termin ^newline]));
	sysPOP("vedargument");
	sysPUSH("ved_gomems");
	sysCALL("vedinput");
	;;; start ved
	sysPUSH("vedvedname");
	sysCALL("edit");
	";" :: proglist -> proglist;
enddefine;

endsection;
