/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/ved_latex/auto/ved_latex209.p
 > Linked to        $poplocal/local/auto/ved_latex209.p
 > Purpose:         Run Latex209 (old latex) from VED
 > Author:          Aaron Sloman, Dec 25 1996
 > Documentation:	See HELP * VED_LATEX and LIB * ved_latex2e.p
 > Related Files:
 */

;;; Invoke as ENTER latex209

section;
uses ved_latex;	;;; to ved get_latex_command declared

define ved_latex209();
	dlocal ved_latex_command = 'latex209 ';
	ved_latex();
enddefine;

endsection;
