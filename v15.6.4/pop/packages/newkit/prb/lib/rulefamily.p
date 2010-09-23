/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/prb/lib/rulefamily.p
 > Purpose:         Record class and procedures for rulefamilies
 > Author:          Aaron Sloman, Apr  5 1996 (see revisions)
 > Documentation:	HELP * POPRULEBASE, HELP * RULESYSTEMS
 */

uses poprulebase;

;;; a variable used in sim_agent

global vars
    sim_use_ruleset_names;

if isundef(sim_use_ruleset_names) then true -> sim_use_ruleset_names endif;


/*
-- RECORD CLASS FOR RULESYSTEM (set of rulesets)
*/

section;

defclass vars procedure prb_rulefamily{
	prb_rulefamily_name,
		;;; usually a word?

	prb_family_prop,
        ;;; A property in which names (words) are associated with rulesets,
        ;;; i.e. lists of names of rules. (Then the same name can be
        ;;; associated with different rulesets in different agents.)

	prb_next_ruleset,
        ;;; The name of the ruleset to be run next, or the ruleset itself.

	prb_family_stack,
        ;;; A (possibly empty stack) of rulesets waiting to be restored.

	prb_family_limit,	;;;; used since  23 Jul 1996
        ;;; False or an integer specifying how many cycles this
        ;;; rulefamily should be allowed in each time-slice.

	prb_family_section,
		;;; False or a section to be used if prb_use_sections is true

	prb_family_matchvars,
		;;; A two element vector, containing a list of words to be
		;;; added to popmatchvars and a procedure to run after that
		;;; to initialise the variables. See setup_matchvars in
		;;; LIB POPRULEBASE

	prb_family_dlocal,
		;;; A list of the form [DLOCAL <procedure> v1 v2 v3 ...]
		;;; where v1, v2, .... are variables whose values are set
		;;; by the procedure, but which must be restored when the
		;;; rulefamily exits.
};

;;; procedure to print a rulefamily
define prb_print_rulefamily(rulefam);
	spr('<prb_rulefamily');
	spr(prb_rulefamily_name(rulefam));
	pr('>');
enddefine;

prb_print_rulefamily -> class_print(prb_rulefamily_key);

/*
;;; testing printing
vars prbsys =
consprb_rulefamily("testrules", false, [hi there], [], 3, false, [], [], []);

prbsys=>
datakey(prbsys) =>
isprb_rulefamily(prbsys) =>
*/

/*
-- -- Actions manipulating prb_current_family

;;; Tracing facilities should be added?

*/


define lconstant derefrules(rules) -> rules;
	;;; dereference rules if necessary.
	if isident(rules) then idval(rules) -> rules
	elseif isword(rules) then
		valof(rules) -> rules;
	endif;
enddefine;

define lconstant check_ruleset(rules, rule_instance, action) -> the_rules;
	lvars the_rules = derefrules(rules);

	unless islist(the_rules) then
		mishap('RULESET NOT FOUND',
			[^rules ^action in %prb_rulename(prb_ruleof(rule_instance))%])
	endunless;
enddefine;



define lconstant prb_SAVERULESET(rule_instance, action);
	;;; [SAVERULESET <name>]
	;;;	This will associate the current ruleset with the <name>
	;;;		in the property.
	prb_rules -> prb_current_rule_prop(front(fast_back(action)));
enddefine;

prb_SAVERULESET -> prb_action_type("SAVERULESET");

define lconstant prb_RESTORERULESET(rule_instance, action);
	;;; [RESTORERULESET <name>]
	;;; 	This makes the ruleset associated with <name> the
	;;;		current ruleset.
	lvars name = front(fast_back(action));

	check_ruleset(
			prb_current_rule_prop(name), rule_instance, action) -> prb_rules;

	;;; should this be name, or identof(name) or prb_rules ???
	if pop_debugging and sim_use_ruleset_names then
		name
	else
		prb_rules
	endif-> prb_next_ruleset(prb_current_family);
	name -> prb_ruleset_name;
enddefine;

prb_RESTORERULESET -> prb_action_type("RESTORERULESET");

define lconstant prb_SWITCHRULESET(rule_instance, action);
	;;; [SWITCHRULESET <name1> <name2>]
	;;; 	Equivalent to [SAVERULESET <name1>] [RESTORERULESET <name2>]
	lvars
		rest = fast_back(action),
		name1 = front(rest),
		name2 = front(fast_back(rest));
	;;; save current rules under name1
	if pop_debugging and sim_use_ruleset_names then
		prb_ruleset_name
	else
		prb_rules
	endif -> prb_current_rule_prop(name1);
;;;	prb_rules -> prb_family_prop(prb_current_family)(name1);

	;;; restore rules from name2

	check_ruleset(
			prb_current_rule_prop(name2), rule_instance, action) -> prb_rules;

	name2 -> prb_ruleset_name;

	;;; should this be name2, or the ident or prb_rules ???
	if pop_debugging and sim_use_ruleset_names then
		identof(name2)
	else
		prb_rules
	endif-> prb_next_ruleset(prb_current_family);
enddefine;

prb_SWITCHRULESET -> prb_action_type("SWITCHRULESET");

define lconstant prb_PUSHRULESET(rule_instance, action);
    ;;; [PUSHRULESET <name>]
	;;; Save current ruleset on the current rule system stack, and then
	;;; make the named ruleset current.
	lvars name = front(fast_back(action));

	;;; Stack the current ruleset (or its name)
    conspair(
		if pop_debugging and isword(prb_ruleset_name)
			and sim_use_ruleset_names then
			prb_ruleset_name
		else
			prb_rules
		endif,
		prb_family_stack(prb_current_family)) -> prb_family_stack(prb_current_family);

	;;; Make the rules associate with name current
	check_ruleset(
			prb_current_rule_prop(name), rule_instance, action) -> prb_rules;

	name -> prb_ruleset_name;
	if pop_debugging and sim_use_ruleset_names then
		name
	else
		prb_rules
	endif-> prb_next_ruleset(prb_current_family);
enddefine;

prb_PUSHRULESET -> prb_action_type("PUSHRULESET");

define lconstant prb_POPRULESET(rule_instance, action);
    ;;; [POPRULESET]
    ;;; Restores previously stacked ruleset.
	lvars rest = fast_back(action), stack;
	;;; Unstack last stacked ruleset. (Could use sys_grbg_destpair??)

	prb_family_stack(prb_current_family) -> stack;
	unless ispair(stack) then
		mishap('No rules to pop in rulefamily',
			[POPRULESET ^prb_current_family=])
	endunless;
	
    destpair(stack) -> (prb_rules, prb_family_stack(prb_current_family));
	if isword(prb_rules) then
		prb_rules -> prb_ruleset_name;
		unless pop_debugging then
			derefrules(prb_rules) -> prb_rules;
		endunless;
	endif;

    prb_rules -> prb_next_ruleset(prb_current_family);
enddefine;

prb_POPRULESET -> prb_action_type("POPRULESET");

;;; for uses
global vars rulefamily = true;
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Feb 21 2002
	Put in some changes to cope with introduction of
		sim_use_ruleset_names
	in sim_agent.
--- Aaron Sloman, May 27 1996
	Many revisions since first draft. Documentation revised
 */
