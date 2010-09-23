/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_print_menu.p
 > Purpose:			Used in [MENU ...] actions
 > Author:          Aaron Sloman, Oct 30 1994
 > Documentation:	HELP * POPRULEBASE
 > Related Files:	LIB * POPRULEBASE
 */

section;

compile_mode:pop11 +strict;

;;; compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
;;; uses poprulebase;

define vars prb_print_menu(question, options);
	;;; a list of question items and a list of options
	lvars item, question, options;
	spr('**');
	if isstring(question) then pr(question)
	else applist(question, spr);
	endif;
	for item in options do
		pr(newline);
		pr(front(item)); spr(":");
		applist(back(item), spr)
	endfor;
	pr('\nPlease select response by typing in item in first column.\n');
enddefine;



endsection;
