/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/ved_latex/auto/latex_spell.p
 > Purpose:			detex current file and pipe output through spell
 > Author:          Aaron Sloman, Sep 25 1994
 > Documentation:
 > Related Files:
 */

section;
uses ved_spell;     ;;; sets vedspellflags

define latex_spell();
	;;; detex current file and pipe output through spell
	if vedwriteable then ved_w1(); endif;
	veddo('sh detex ' <> vedpathname <> ' | spell ' <> vedspellflags)
enddefine;

endsection;
