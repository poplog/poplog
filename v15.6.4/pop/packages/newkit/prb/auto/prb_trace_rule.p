/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_trace_rule.p
 > Purpose:			Prints out rule instances
 > Author:          Aaron Sloman, Oct 30 1994 (see revisions)
 > Documentation:	HELP * POPRULEBASE
 > Related Files:	LIB * POPRULEBASE
 */


section;
;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;


define prb_trace_rule(rule_instance, instantiate);
	;;; Print out a rule instance
	;;; If instantiate is true then instantiate.
	lvars rule_instance, instantiate, name, weight, actions, conditions,
		rule=prb_ruleof(rule_instance);

	;;; Bug in ==> fixed, so remove next line:
	;;;	dlocal cucharout = charout;

	destprbrule(rule) -> (name, weight, conditions, actions, /*type*/, /*vars*/);

	if instantiate then
		prb_value(actions) -> actions;
	endif;
	pr(newline);
	[RULE INSTANCE ^name] =>
	if prb_useweights then
	    [WEIGHT ^weight] =>
	endif;
	[CONDITIONS ^conditions] ==>
	[MATCHED ^(prb_foundof(rule_instance))] ==>
	[ACTIONS ^actions] ==>
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, May  5 1996
	fixed extra result in dest*prbrule
--- Aaron Sloman, Nov  4 1995
	Removed redirection of cucharout, originally put in because of
	bug in ==> print routine
 */
