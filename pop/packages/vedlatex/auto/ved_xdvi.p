/* --- Copyright University of Birmingham 2001. All rights reserved. ------
 > File:            $poplocal/local/ved_latex/auto/ved_xdvi.p
 > Linked to: 		$poplocal/local/auto/ved_xdvi.p
 > Purpose:			Invoke xdvi on the corresponding .dvi file
 > Author:          Aaron Sloman, Feb  7 1992 (see revisions)
 > Documentation:	See HELP VED_LATEX. Also man xdvi
 > Related Files:
 */


/*
	ENTER xdvi
	ENTER xdvi <file>

*/

section;

global vars
	ved_xdvi_args,			;;; flags for xdvi
	ved_xdvi_command,		;;; command to run xdvi, e.g. 'xdvi '
;
lconstant
	xdvi_args = '-keep -s 4 -paper a4 -offsets 2.5cm',
	xdvi_command = 'xdvi ',
;

unless isstring(ved_xdvi_args) then
	xdvi_args -> ved_xdvi_args
endunless;

unless isstring(ved_xdvi_command) then
	xdvi_command -> ved_xdvi_command
endunless;

define global ved_xdvi();
	;;; This can be invoked alone or via ENTER latex xdvi
	;;; preview file using xdvi

	lconstant dvi = '.dvi';

	lvars dvifile, extn,
		dir = sys_fname_path(vedpathname);

	unless vedargument = nullstring then
		if vedargument = 'd' or vedargument = 'default' then
			;;; reset default flags
			xdvi_args -> vedargument
		elseif isstartstring('-s', vedargument)
		;;; check if space needed after '-s'
		and not(isstartstring('-s ', vedargument)) then
			;;; add space after '-s', e.g. '-s2' becomes '-s 2'
			'-s ' >< allbutfirst(2, vedargument) -> vedargument
		endif;

		;;; assign vedargument
		vedargument -> ved_xdvi_args
	endunless;

	sys_fname_extn(vedpathname) -> extn;
	;;; get .dvi file
	if extn = dvi then
		vedpathname -> dvifile;
	elseif extn = '.tex' then
		allbutlast(4, vedpathname) sys_>< dvi -> dvifile
	else
		vedpathname sys_>< dvi -> dvifile
	endif;

	unless sys_file_exists(dvifile) then
		vederror(dvifile <> ' DOES NOT EXIST. USE ENTER latex')
	endunless;

	vedputmessage('RUNNING xdvi in background');

	vedscreengraphoff(); ;;; to ensure messages can be read

	sysobey(
		concat_strings({'cd ' ^dir '; ' ^ved_xdvi_command ^space ^ved_xdvi_args
			^space ^dvifile ' > /dev/null &'}), `$`);

	vedputmessage('DONE');
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 26 2001
	Set default offset to 2.5cm, as it was previously cut too fine for some
	documents. (The system default is 1 inch).
--- Aaron Sloman, Oct 15 2000
	Added extra default flags
 */
