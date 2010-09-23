/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/ved_latex/auto/ved_jlp.p
 > File:            $poplocal/local/auto/ved_jlp.p
 > Purpose:			justify paragraph in .tex files specially
 > Author:          Aaron Sloman, Apr 28 1992 (see revisions)
 > Documentation:	HELP * VED_LATEX
 > Related Files:	LIB * VED_JP, LIB * VED_LATEX
 */


;;; LIB ved_jlp (version of ved_jp for LaTeX files)

section;

global vars latex_para_breaks;
unless isstring(latex_para_breaks) then
	;;; allow backslash and percent to mark paragraph breaks in .tex files
	'\\%' -> latex_para_breaks
endunless;

global vars html_para_breaks;
unless isstring(html_para_breaks) then
	;;; When editing an html file treat lines starting with these as new
	;;; paragraphs
	'<' -> html_para_breaks
endunless;


global vars non_latex_para_breaks;
unless isstring(non_latex_para_breaks) then
	;;; use '.' at begining of line as an indication that line should not
	;;; be joined, as in nroff/troff files.
	'.' -> non_latex_para_breaks
endunless;


define global procedure ved_jlp();
	;;; justify current paragraph

	if vedcompileable and not(issubstring('teach', vedpathname)) then
		ved_jcp()
	else
    	lvars formatchars, filetype = sys_fname_extn(vedpathname);
		if filetype = '.tex' then
			latex_para_breaks
		elseif filetype = '.html' or filetype = '.htm' then
			html_para_breaks
		else
			non_latex_para_breaks
		endif -> formatchars;

		define lconstant formatline() /* -> boole */ ;
			;;; decide whether current line is a "format" control line.
			strmember(
				fast_subscrs(1, fast_subscrv(vedline, vedbuffer)),
				formatchars) /* -> boole */ ;
		enddefine;

		vedmarkpush();
		false -> vvedmarkprops;
		;;; find beginning of range to mark
		until vedline == 1 or vvedlinesize == 0 or formatline() do
			vedcharup();
		enduntil;
		if vvedlinesize == 0 or formatline() then vedchardown() endif;
		vedline -> vvedmarklo;

		;;; find end of range to mark
		until vedline == vvedbuffersize or vvedlinesize == 0 or formatline() do
			vedchardown();
			if isstartstring('Received: ', vedthisline()) then
				Veddebug('In mail header. Are you sure?')
			endif;
		enduntil;
		if vvedlinesize == 0 or formatline() then vedcharup() endif;
		vedline -> vvedmarkhi;
		;;; now run normal ved justify command.
		if issubstring('teach', vedpathname) then
			ved_fill();
		else
			ved_j();
		endif;
		vedmarkpop();
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, May 23 1999
	Extended to work better with teach files ending in .p
--- Aaron Sloman, Mar 24 1999
	Made it give warnings in mail messages.
--- Aaron Sloman, Jan  3 1999
	Added html_para_breaks for use when editing .html files.
 */
