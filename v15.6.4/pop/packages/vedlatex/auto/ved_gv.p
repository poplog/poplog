/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/ved_latex/auto/ved_gv.p
 > Purpose:         Run Ghostview "gv" on a file derived from the current
					latex file
 > Author:          Aaron Sloman, Oct 15 2000
 > Documentation:
 > Related Files:	LIB VED_LATEX, VED_XDVI
 */


/*
	ENTER gv

First do this to the .tex file to produce the .ps file
	ENTER latex print ps

*/

section;

global vars
	ved_gv_args,			;;; flags for gv
	ved_gv_command,		;;; command to run gv, e.g. 'gv '
;
lconstant
	gv_args = '-antialias -watch -scale -2 -resize ',
	gv_command = 'gv ',
;

unless isstring(ved_gv_args) then
	gv_args -> ved_gv_args
endunless;

unless isstring(ved_gv_command) then
	gv_command -> ved_gv_command
endunless;

define global ved_gv();
	;;; preview file using gv

	lconstant ps = '.ps';

	lvars dvifile, extn,
		dir = sys_fname_path(vedpathname);

	unless vedargument = nullstring then
		if vedargument = 'd' or vedargument = 'default' then
			;;; reset default flags
			gv_args -> vedargument
		elseif isstartstring('-s', vedargument)
		;;; check if space needed after '-s'
		and not(isstartstring('-s ', vedargument)) then
			;;; add space after '-s', e.g. '-s2' becomes '-s 2'
			'-s ' >< allbutfirst(2, vedargument) -> vedargument
		endif;

		;;; assign vedargument
		vedargument -> ved_gv_args
	endunless;

	sys_fname_extn(vedpathname) -> extn;
	;;; get .ps file
	if extn = ps then
		vedpathname -> dvifile;
	elseif extn = '.tex' then
		allbutlast(4, vedpathname) sys_>< ps -> dvifile
	else
		vedpathname sys_>< ps -> dvifile
	endif;

	unless sys_file_exists(dvifile) then
		vederror(dvifile <> ' DOES NOT EXIST. USE ENTER latex')
	endunless;

	vedputmessage('RUNNING gv in background');

	vedscreengraphoff(); ;;; to ensure messages can be read

	sysobey(
		concat_strings({^ved_gv_command ^space ^ved_gv_args
			^space ^dvifile ' > /dev/null &'}), `$`);

	vedputmessage('DONE');
enddefine;


endsection;
