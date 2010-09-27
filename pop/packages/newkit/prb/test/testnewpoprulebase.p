
;;; A simple test of the new poprulebase facility [->> Cond], allowing
;;; variables to name items satisfying conditions.
;;; Also tests POP11 conditions, CUT conditions.
;;; New [VAL var] expressions.

;;; A.Sloman July 1995

uses poprulebase;

[TEST 1]=>
;;; A test for CUT conditions. Thu Jun 15 20:16:20 BST 1995
[] -> prb_rules;
vars data =
	[[a 1] [a 2] [a 3]
	 [b 1] [b 2]
	 [c 1] [c 2]
	 [d 1] [d 2]
	 [e 1] [e 2]];

define :rule silly
	[a =] [b =] [c =][POP11 'after c'=>]
	[CUT] [d =][->>C1] [e =][->>C2] [POP11 [^C1 ^C2]==>]
	;
	[STOP 'IT IS ALL DONE' [?C1 ?C2] ]
enddefine;

define test();
	dlocal
		prb_show_conditions = true,
		prb_chatty = true,
		prb_walk = true,
		prb_allrules = false;
	prb_run(prb_rules, data, 2);
enddefine;

test();
[END TEST 1]=>

[TEST 2] =>
;;; Silly example
;;; test use of [->> var] format for conditions in Poprulebase
;;; Also test use of POP11 conditions, and LVARS, including initialisations

vars testrules;

;;; The front and back of this pair will be accessed in conditions
;;; and in actions
vars test_pair = conspair("a", "b");

define testfn( item );
	lvars item;
	printf('Action given database item: %p\n', [^item]);
enddefine;


define :ruleset testrules;

RULE rule1  ;;; in testrules

	[POP11 'testing rule1' =>]
	[LVARS [g1 = front(test_pair)] ]
	[NOT ?g1 ==]
	[is a b]
	==>
	[LVARS [[f1 f2] = destpair(test_pair)]]
	[SAY 'Rule1 : adding to rule database']
	[?f1 ?f2]
	[POP11 prb_print_database()]
	[POP11 'done it' =>]

RULE rule2  ;;; in testrules

	[POP11 'testing rule2' =>  ]
	[LVARS [[first second] = destpair(test_pair)] ]
	;;; see if database contains the items
	[?first ?second][->> Cond1]
	;;; [POP11 [found ^Cond1] =>]
	;;; this one should cause an error as previous condition is not simple
	;;; [->> Cond2]
	[is ?x1 ?x2]
	[is ?x2:isword ?x3]
	==>
	[SAY 'Rule2  actions starting. Found' ?first ?second]
	[NULL [apply testfn ?Cond1]]
	[POP11 ['Also works with POP11 action: ' ^Cond1] =>]
	[SAY deleting ?Cond1]
	[DEL ?Cond1]
	[POP11 gensym("a") ,gensym("b"), fill(test_pair) =>]

RULE rule3  ;;; in testrules

	[NOT is a b]	
	==>
	[is a b]
	[is b c]
enddefine;

define go ( n );
	;;; trace database changes
     13->prb_chatty;
    ;;;; 7*11*17->prb_chatty;
    prb_run(testrules, [], n);
enddefine;

untrace prb_applicable;
go(6) =>

[END TEST 2] =>

[TEST use of "VAL" in actions]=>


global vars finish_now = false, val = false;

define :ruleset prb_rules;

RULE valrule1

	[finish_now ?val]
	[WHERE val = true]
	[done [VAL true]]
	==>
	[STOP 'all done']

RULE valrule2

	[WHERE finish_now]
	==>
	[finish_now [VAL finish_now]]
	[done [VAL true]]
	[SAY 'finished recorded']

RULE valrule3
    ;;; no conditions
	==>
	[POP11 true -> finish_now]
	[SAY 'set the variable']
enddefine;

true -> prb_walk;
prb_run(prb_rules, []);

[END TEST use of "VAL" in actions]=>

[TEST true for prb_use_sections] =>

uses timediff;
section test_sections => doSWITCHON;

true -> prb_use_sections;

"doSWITCHON" -> prb_action_type("SWITCHON");

define doSWITCHON(rule_instance, action);
	lvars ruleinstance, action, rest, key;
	;;; form is [SWITCHON key val1 action1 val2 action2 .... default]
	destpair(action) -> rest -> key;
	dest(rest) -> rest -> key;
	;;; key is now the key, see if it matches any value in rest
	repeat
	quitif(rest == []);
		if back(rest) == [] then
			;;; only the default action remains
			fast_front(rest) -> rest; quitloop();
		elseif (fast_destpair(rest) -> rest) = key then
			front(rest) -> rest; quitloop();
		else
			;;; prepare for next key
			back(rest) -> rest
		endif
	endrepeat;
	chain(rest, prb_ruleof(rule_instance), rule_instance, prb_do_action)
enddefine;

define :ruleset prb_rules;

RULE fac1
    [go] [factorial ?n val ?y] [start ?n]
	==>
	;;; goal achieved
	[DEL 1 2 3]
	[POP11 prb_add(if y > 10 then [big] else [small] endif) ]
	[SWITCHON ?y
		2 [SAY SMALL]  6 [SAY SMALL ] 24 [SAY MEDIUM] [SAY BIG]]
	[NOT want =]
	[SAY time [popval timediff()]]
	[SAY factorial of ?n is ?y]


RULE fac2

	;;; unwind
		 [go] [factorial ?n val ?y] [->> FacCond]
	==>
	[LVARS [val1 = ((n + 1)*y) ] [val2 = (n + 1)]]
	[MODIFY ?FacCond val ?val1 factorial ?val2]


RULE fac3
	;;; terminate preparation
		 [want 1]
	==>
	[DEL 1]
	[go]
	[factorial 1 val 1]
	[READ 'preparation finished' [==] []]


RULE fac4
	;;; prepare
		 [want ?x]
	==>
	[LVARS [nextx = x - 1]]
	[MODIFY 1 want ?nextx]

RULE fac5
    [start ?x]
	==>
	[want ?x]

RULE fac6
	==>
	[READ 'What number?' [?x:isinteger] [start ANSWER]]
	[POP11 timediff() ->]
enddefine;


endsection;

false -> prb_chatty;
false-> prb_walk;
true -> prb_repeating;
false -> prb_allrules;
true -> prb_copy_modify;

prb_run(prb_rules, []) =>

false -> prb_use_sections;

[END TEST for prb_use_sections] =>
