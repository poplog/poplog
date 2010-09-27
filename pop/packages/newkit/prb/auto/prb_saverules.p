/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_saverules.p
 > Purpose:         Write a ruleset to a file
 > Author:          Aaron Sloman, Dec  8 1996
 > Documentation:	Below. Still experimental
 > Related Files:
 */

/*
HELP PRB_SAVERULES

prb_saverules(<ruleset>, <rulesetname>, <filename>)

This is intended only for saving relatively simple rulesets in a file.

Saves the ruleset given with the rulesetname in the specified file.
Will overwrite any existing contents in the file.

Does not handle conditions and actions that are capable of including
Pop-11 code, e.g.

	[VARS ...]
	[LVARS ...]
	[WHERE ...]
	[POP11 ...]

Examples from teach prbriver


define :ruleset start_rules;

  RULE start
    ==>
    [chicken isat left]
    [fox isat left]
    [grain isat left]
    [man isat left]
    [plan]
    [history]

    [opposite right left]
    [fox can eat chicken]
    [chicken can eat grain]

    [constraint Eat
        [[?thing1 isat ?side]
            [NOT man isat ?side]
            [?thing1 can eat ?thing2]
            [?thing2 isat ?side]]
        [?thing1 can eat ?thing2 GO BACK]]

    [constraint Loop
        [[state ?state] [history == [= ?state] == ]]
        ['LOOP found - Was previously in state: ' ?state]]

    [state [apply thing_data]]

    [POP11 display_data()]	;;; does not handle this
    [EXPLAIN 'Setting up "solve" ruleset']
    [RESTORERULESET solve_rules]
enddefine;

;;; Try saving that in temp1.p
prb_saverules(start_rules, "start_rules", 'temp1.p');


define :ruleset check_rules;

  RULE check_constraints
    [constraint ?name ?checks ?message]
    [ALL ?checks]
    ==>
    [SAY Constraint ?name violated]
    [SAY ??message]
    [RESTORERULESET backtrack_rules]

  RULE checks_ok
    ==>
    [RESTORERULESET solve_rules]
enddefine;

;;; Try saving that in temp2.p
prb_saverules(check_rules, "check_rules", 'temp2.p');

*/

section;

define lconstant pr_header(string);
	dlocal pop_pr_quotes = false;
	sys_syspr(string);
enddefine;

define prb_saverules(ruleset, rulesetname, filename);

	define dlocal print_ident(id);
		;;; replace identifiers with their names
		lvars wd = word_of_ident(id);
		if wd then pr(wd)
		else
			sys_syspr(id)
		endif
	enddefine;

	dlocal
		;;; Ensure strings are printed with quotes
		pop_pr_quotes = true,
		cucharout = discout(filename);

	;;; print each condition, or action, in the database separately,
	;;; each starting on
	;;; a new line

	pr_header('define :ruleset ');
	pr_header(rulesetname);
	pr_header(';\n\s\s\s\s');

	until isprbrule(hd(ruleset)) do
		pr(dest(ruleset) -> ruleset);
		pr_header('\n\s\s\s\s');
	enduntil;

	lvars rule, condition, action;
	for rule in ruleset do
		pr_header('\n\s\sRULE ');
		pr_header(prb_rulename(rule));
		pr_header('\n\s\s\s\s');
		for condition in prb_conditions(rule) do
			pr(condition);
			pr_header('\n\s\s\s\s');
		endfor;

		pr_header('\s\s==>\n\s\s\s\s');

		for action in prb_actions(rule) do
			pr(action);
			pr_header('\n\s\s\s\s');
		endfor;
		cucharout(`\n`);
	endfor;
	pr_header('enddefine;\n');

    cucharout(termin);

enddefine;

endsection;
