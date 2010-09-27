/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/define_rule.p
 > Purpose:			"OLD" syntax for defining individual rules
 > Author:          Aaron Sloman, Apr 27 1996
 > Documentation:	HELP * POPRULEBASE, HELP * RULESYSTEMS
 > Related Files:	LIB * POPRULEBASE, define_ruleset
 */


/*
-- -- Syntax procedure for define :rule
*/

define :define_form global rule;
	;;; read in rule of form
	;;; define :rule <name> [<weight>] [<typespec>]
	;;;		<conditions> <terminator> <actions>
	;;;	enddefine;
	;;; where each condition and each action is a list, possibly
	;;; containing variables indicated by "?" and "??"
	lvars name, next, conditions, actions, rule,
		ruletype = "prb_rules", weight = prb_default_rule_weight;

	readitem() -> name;
;;;	mishap(name, 1, '"define :rule" no longer allowed. Use define :ruleset')

	unless isword(name) and name /== "[" and name /== ";" then
		mishap(name,1,'WORD NEEDED FOR NAME OF RULE')
	endunless;

	;;; allow either order for "weight N" "in ruletype"
	repeat 2 times
		pop11_try_nextreaditem([in weight]) -> next;
		if next == "in" then
			readitem() -> ruletype;
			unless isword(ruletype) and islist(valof(ruletype)) then
				mishap(name, ruletype, 2, 'INVALID RULE TYPE IN RULE DEFINITION')
			endunless;
		elseif next == "weight" then
			readitem() -> weight;
			unless isnumber(weight) then
				mishap(name, weight, 2, 'NON-NUMBER GIVEN FOR WEIGHT IN RULE DEFINITION')
			endunless;
		endif
	endrepeat;

	;;; ignore second result in each of these cases
	prb_read_conditions([]) -> (conditions, );

		lvars condition, vars_list = [];
		for condition in conditions do
			if front(condition) == "VARS" then
				back(condition) <> vars_list -> vars_list;
			endif;
		endfor;
	prb_read_actions(vars_list, [enddefine]) -> (actions, );

	sysPUSHQ(name);
    sysPUSHQ(weight);
	sysPUSHQ(conditions);
	sysPUSHQ(actions);
	sysPUSHQ(ruletype);
	sysPUSHQ([]);	;;; will later have rulevars ???????
	sysCALL("prb_new_rule")
enddefine;
