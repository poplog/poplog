/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_browser_action.p
 > Purpose:			Determine what to do with "accepted" files
					User definable
 > Author:          Aaron Sloman, May 14 1999 (see revisions)
 > Documentation:
 > Related Files:	LIB rc_browsefiles.p
 */

section;

compile_mode :pop11 +strict;

/*

;;; tests

sys_is_executable('$usepop/pop/help/news/')=>
sys_is_executable('$usepop/pop/pop')=>
sys_is_executable('$usepop/pop/pop/basepop11')=>

*/

define sys_is_executable(file) -> boole;
	lvars mode = sysfilemode(file);
	if sysisdirectory(file) then false
	else
		testbit(mode, 0) or testbit(mode, 3) or testbit(mode, 6)
	endif-> boole
enddefine;


define vars rc_browser_action(file);
	if isendstring('.ps', file) then
		veddo('bg ghostview -a4 -magstep -1 ' <> file);
	elseif isendstring('.ps.gz', file) then
		veddo('bg gunzip -c ' <> file <> '| ghostview -a4 -magstep -1 -');
	elseif isendstring('.dvi', file) then
		veddo('bg /bham/pd/packages/tex/bin/xdvi -s 4 -paper a4 ' <> file);
	elseif isendstring('.pdf', file) then
		veddo('bg acroread ' <> file);
	elseif isendstring('.html', file)
	or isendstring('.pdf.gz', file)
	or isendstring('.html.gz', file)
	then
		veddo('bg netscape ' <> file);
	elseif sys_is_executable(file) then
		dlocal vedargument = file, show_output_on_status = false;
		vedgenshell(systranslate('SHELL'), false)
	else
		edit(file);
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 26 1999
	Extended to detect executables and run them
 */
