/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_show_rules.p
 > Purpose:			Print out all rules in a given list
 > Author:          Aaron Sloman, Oct 30 1994
 > Documentation:	HELP * POPRULEBASE
 > Related Files:	LIB * POPRULEBASE
 */

section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;


define procedure prb_show_rules(rule_list);
	;;; Display all rules in the list
	lvars rule,rule_list, rule;
	for rule in rule_list do
		prb_pr_rule(rule);
		pr(newline);
	endfor;
enddefine;

endsection;
