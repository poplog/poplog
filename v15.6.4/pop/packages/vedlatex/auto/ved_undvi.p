/* --- Copyright University of Birmingham 2001. All rights reserved. ------
 > File:            $poplocal/local/ved_latex/auto/ved_undvi.p
 > Linked to:       $poplocal/local/auto/ved_undvi.p
 > Purpose:         Display latex output in plain text in Ved
 > Author:          Aaron Sloman, Jan 23 1998 (see revisions)
 > Documentation:	Below
 > Related Files:	LIB ved_latex, ved_dvi2tty, HELP ved_latex,
 */

/*

See HELP ved_latex/dvi2tty

ENTER undvi
This program works only if you have the dvi2tty program installed,
which takes the .dvi file produced by latex, and then displays it in
plain text mode.

So edit foo.tex

Then do this to produce foo.dvi

	ENTER latex

Then do

	ENTER undvi

to view the output. This is equivalent to

	ENTER dvi2tty -w130

followed by a command to get rid of asterisks produced by dvi2tty
to show lines that have been broken.

*/

define ved_undvi();
	dlocal ved_search_state;
    veddo('dvi2tty -w130');
    veddo('sgs/*@z@a *//');
enddefine;
