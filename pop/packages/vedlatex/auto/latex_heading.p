/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/ved_latex/auto/latex_heading.p
				linked to
 > 					$poplocal/local/ved_latex/auto/latex_g.p
 >             		$poplocal/local/ved_latex/auto/latex_indexify.p
 > Purpose:			Extends ENTER latex with indexify facilities
 > Author:          Aaron Sloman, May 10 1992
 > Documentation:	HELP * VED_LATEX, HELP * VED_INDEXIFY
 > Related Files:	LIB * VED_LATEX
 */

;;; Should be linked to latex_g.p and latex_indexify.p

/*
Based on correspondence with Roger Evans
*/

;;; autoloadable lib latex_heading

section;

global vars latex_g_string = '% -- ';

define latex_heading();
	lvars line = vedthisline();
	dlocal vedbreak = false;

	vedpositionpush();
	if vedline > 1
	and isstartstring(latex_g_string, vedbuffer(vedline - 1)) then
		;;; already a comment line, so delete
		vedjumpto(vedline - 1, 1);
		vedcleartail()
	else
		vedlineabove();
	endif;

	vedinsertstring(latex_g_string); vedinsertstring(line);
	vedtextright(); vedcharright();
	until vedcolumn > vedlinemax do vedcharinsert(`-`) enduntil
enddefine;

;;; lib latex_indexify

define latex_g_do(proc);
	;;; do proc() in appropriate context
	lvars procedure proc;
	dlocal ved_g_string = latex_g_string, vedargument = nullstring;
	proc();
enddefine;

define latex_indexify =
	latex_g_do(% ved_indexify %)
enddefine;

;;; lib latex_g

define latex_g =
	latex_g_do(%ved_g%)
enddefine;

endsection;
