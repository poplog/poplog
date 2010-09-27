/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_select_action.p
 > Purpose:         Used to select a collection of actions on the basis of a
					vector
 > Author:          Aaron Sloman, Oct 29 1994
 > Documentation:
 > Related Files:
 */


section;
;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;


define prb_select_action(rule_instance, action);
	;;; invoked by actions of the form
	;;; [SELECT ?veclist <action1> <action2> ... <actionn>]
	;;; where the veclist was produced by a filter condition
	lvars rule_instance, action, veclist, actionlist, val, action;
	destpair(fast_back(action)) -> (veclist, actionlist);
	unless islist(veclist) and length(veclist) == length(actionlist) then
		mishap('SELECT ACTION NEEDS VECTOR AND ACTIONLIST OF SAME LENGTH',
			[^veclist ^actionlist ^(prb_rulename(prb_ruleof(rule_instance)))])
	endunless;

	for val, action in veclist, actionlist do
		if val then
			prb_do_action(action, prb_ruleof(rule_instance), rule_instance)
		endif;
	endfor
enddefine;
		
endsection;
