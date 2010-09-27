/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/ved_latex/auto/ved_dvi2tty.p
 > Purpose:			Previewing .dvi file in VED using dvi2tty
 > Author:          Aaron Sloman, Jun 18 1992
 > Documentation:	HELP * VED_LATEX
 > Related Files:
 */

section;

define global procedure ved_dvi2tty();
	lvars arg, dvifile, file, extn, flagloc, spaceloc, flags;
	lconstant dvi = '.dvi';

	if vedargument = nullstring then
		vedpathname -> arg;
		nullstring -> flags;
	else
		locchar_back(`-`, 9999, vedargument) -> flagloc;
		locchar(`\s`, flagloc + 1, vedargument) -> spaceloc;
		if spaceloc then
			locchar(`\s`, spaceloc + 1, vedargument) -> spaceloc;
		endif;
		if spaceloc then
			;;; get flags including space
			substring(1, flagloc, vedargument) -> flags;
			sysfileok(allbutfirst(flagloc,vedargument)) -> arg;
		else
			;;; it's all flags
			vedpathname -> arg;
			vedargument sys_>< space -> flags
		endif;
	endif;
	sys_fname_extn(arg) -> extn;
	;;; get .dvi file
	if extn = dvi then
		arg -> dvifile;
		allbutlast(4,arg) -> file;
	elseif extn = '.tex' then
		allbutlast(4, arg) -> file;
		file sys_>< dvi -> dvifile
	elseif extn /= nullstring then
		allbutlast(datalength(extn), arg) -> file;
		file sys_>< dvi -> dvifile
	else
		arg -> file;
		arg sys_>< dvi -> dvifile
	endif;

	vedputmessage('RUNNING dvi2tty');
	veddo('sh dvi2tty ' sys_>< flags sys_>< dvifile);
	vedputmessage('DONE');
enddefine;

global vars procedure latex_dvi2tty = ved_dvi2tty;

endsection;
