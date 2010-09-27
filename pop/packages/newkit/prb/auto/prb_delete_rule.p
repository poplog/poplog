/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_delete_rule.p
 > Purpose:			Remove a rule from a list of rules
 > Author:          Aaron Sloman, Oct 30 1994
 > Documentation:	HELP * POPRULEBASE
 > Related Files:	LIB * POPRULEBASE
 */

section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;


define procedure prb_delete_rule(word, ruletype);
	lvars word, assoc_list = valof(ruletype), last, ruletype;
	if assoc_list == [] then
	elseif prb_rulename(fast_front(assoc_list)) == word then
		fast_back(assoc_list) -> valof(ruletype);
		return();
	else
		assoc_list -> last;
		fast_back(assoc_list) -> assoc_list;
		until assoc_list == [] do
			if prb_rulename(fast_front(assoc_list)) == word then
				fast_back(assoc_list) -> fast_back(last);
				return()
			else
				assoc_list -> last;
				fast_back(assoc_list) -> assoc_list
			endif
		enduntil;
	endif;
	mishap(word,1,'PRB RULE NOT FOUND IN LIST');
enddefine;

endsection;
