/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/ved_latex/auto/ved_latex2e.p
 > Linked to:       $poplocal/local/auto/ved_latex2e.p
 > Purpose:			Version of ENTER latex for latex2e
 > Author:          Aaron Sloman, Oct 24 1994 (see revisions)
 > Documentation:	See HELP * VED_LATEX
 > Related Files:
 */

;;; Invoke as ENTER latex2e

section;
uses ved_latex;	;;; to ved get_latex_command declared

define ved_latex2e();
	dlocal ved_latex_command = 'latex2e ';
	ved_latex();
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec 25 1996
	Changed header
 */
