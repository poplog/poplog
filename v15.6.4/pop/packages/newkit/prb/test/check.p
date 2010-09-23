;;; A simple test of the new poprulebase facilities.
;;; I.e. FILTER conditions, etc.

;;; load the library
uses prblib
uses poprulebase

/*

false -> prb_chatty;
false -> prb_walk;
*/

;;; set up a database
vars check_data =
   [[a at left]
	[b at left]
	[c in middle]
	[d in middle]
	[e at right]
	[f at right]
	[g at right]
	[e on f]
	[p on q]];

;;; set up a database
vars check_data2 =
   [[a at left]
	[b at left]
;;;	[c in middle]
;;;	[d in middle]
	[e at right]
	[f at right]
	[g at right]
	[e on f]
	[p on q]];


;;; Pattern variables
vars w, x, y, z;

define check_proc(patterns, items) -> result;
	;;; A silly procedure to be used in a FILTER condition
	;;;  Return true if most of the patterns have instances
	lvars patterns,
		len=length(patterns),
		items, patt, data, result = false,
		count = 0;
	'Check_proc mappings in check_proc' =>
	for patt, data  in  patterns, items  do
		;;; print out the pattern, and all matching items
		[^patt ^data] =>
		if data then 1 + count -> count endif;
	endfor;
	'Mappings in check_proc done' =>
	if count*2 >= len then items -> result endif;
enddefine;


define check_map(veclist, actionlist, rule_instance);
	lvars veclist, actionlist, rule_instance;
	;;; A procedure to be used in a MAP action in rule4
	;;;  select actions for which corresponding veclist element
	;;; is non false and has length > 2
	lvars item, action;
	'Check_map mappings starting' =>
	for item, action  in  veclist, actionlist do
		;;; print out the pattern, and all matching items
;;;		[^item ^action] =>
		if item and length(item) > 2 then
			prb_eval(action)
		endif;
	endfor;
	'Mappings in check_map done' =>
enddefine;

define silly_check(pattern) -> result;
	;;; A silly procedure to be linked to a new keyword "SILLY"
	;;; Just print out the pattern, but return true
	lvars pattern, result = true;
	[silly_check ^pattern] ==>
enddefine;

;;; set up the keyword "SILLY"
silly_check -> prb_condition_type("SILLY");

;;; Now rules using the above
define :ruleset prb_rules;

RULE check_rule1

	;;; grotty print instruction, then a FILTER condition with no precursors
	[WHERE 'rule1'=> true]
	[NOT done rule1]
	[FILTER check_proc [?x at right] [?y in middle] [?z at left]]
	==>
	[DOALL [SAY 'action1'][SAY 'action2']]
	[SAY 'done check_rule1']
	[done rule1]

RULE check_rule2

	[WHERE 'rule2'=> true]
	[NOT done rule2]
	;;;;[VARS vec]
	[FILTER check_proc -> vec [?x at right] [?y in middle] [?z at left]]
	[WHERE [vec has value ^vec] ==> true]
	==>
	[SAY ['In rule2 action vec is' ?vec]]
	[SELECT ?vec
		[SAY things at right]
		[SAY things in middle]
		[SAY things at left]]
	[SAY 'done check_rule2']
	[done rule2]

RULE check_rule3

	;;; This has a test condition with a precursor that can bind variables
	[WHERE 'rule3'=>; true]
	[NOT done rule3]
	[?x on ?w]
	;;; print out result of binding x and w.
	[WHERE [x is ^x w is ^w] => true]
	[FILTER check_proc [?x at right] [?y in middle] [?z at left]]
	==>
	[SAY 'done check_rule3']
	[done rule3]


RULE check_rule4

	[WHERE 'rule4'=> true]
	[NOT done rule4]
	;;;;[VARS vec]
	[FILTER check_proc -> vec [?x at right] [?y in middle] [?z at left]]
	[WHERE [vec has value ^vec] ==> true]
	==>
	[SAY ['In rule4 action vec is' ?vec]]
	[MAP ?vec check_map
		[SAY things at right in 4]
		[SAY things in middle in 4]
		[SAY things at left in 4]]
	[SAY 'done check_rule4']
	[done rule4]


RULE check_rule5

	;;; this time involve the SILLY test
	[WHERE 'rule5'=>; true]
	[?x on ?w]
	[SILLY [x is ?x w is ?w] ]
	==>
	[STOP 'stopping on rule5']
enddefine;


define vars prb_finish(rules, data);
	lvars rules, data;
	'finished' =>
	prb_print_table(data )
enddefine;

/*
prb_rules ==>
check_data ==>

prb_run(prb_rules, check_data, 2);
prb_run(prb_rules, check_data, 6);
prb_run(prb_rules, check_data2, 5);

*/
