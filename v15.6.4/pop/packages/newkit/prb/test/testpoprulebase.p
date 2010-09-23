/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/prb/test/testpoprulebase.p
 > Purpose:			Some tests for poprulebase
 > Author:          Aaron Sloman, Jul  2 1995 (see revisions)
 > Documentation:
 > Related Files:
 */


uses poprulebase;

/*
false -> prb_chatty;
false -> prb_walk;
vars x,y,z, prb_chatty = 1;

vars prb_rules = [];

define pshow;
	[[prb_found ^ prb_found ]] ==>
	[[ x ^x ][ y ^y ][ z ^z]] ==>
	prb_print_database();
enddefine;

define pstart;
	[] -> popmatchvars;
	false ->> x ->>y -> z;
	[] -> prb_found;
	prb_newdatabase(8,
		[[r a b] [ r b c] [r c d] [r b e] [r e a] [ s a b] [p q]])
		-> prb_database;
	'RESTARTING' =>
	pshow();
enddefine;

pstart();

[] -> popmatchvars;
;;; No longer exported
;;; prb_has_variables([ ?y [ ?x ] z??]) =>

prb_present([r ?x =]),x   =>
prb_present([p ?x =]),x =>
pshow();

pstart();
prb_flush([r ==]);

pshow();
prb_found ==>

pstart();
true -> prb_recording;
prb_flush([r ==]);
prb_found ==>

false -> prb_recording;
pstart();
[] -> popmatchvars;
prb_print_database();
popmatchvars =>

prb_forevery([[r ?x ?y] [NOT s ?x ?q] [r ?y ?z]],
	procedure(p,q); lvars p,q; [derived: r ^x ^z] => endprocedure);

pstart();

prb_forevery([[r ?x ?y][r ?y ?z]],
	procedure (p,q); lvars p,q;
	[derived: r ^x ^z] => exitfrom(prb_forevery) endprocedure);
pshow();

prb_forevery([[r ?x b] [OR [r ?y ?x] [s ?x ?y]][ == ?y ==]],
	procedure (p,q); lvars p,q;
		[found: ^x ^y ^prb_found] ==>
	endprocedure);


;;; stuff for testing rule manipulation

vars x, prb_rules ;
define rstart();
	[%
		for x to 5 do
		consprbrule(
			consword('rule' >< x),
			1,
			[[ test ^x][NOT foo ^x]],
			[[do ^x]],
			"prb_rules")
		endfor;
	%] -> prb_rules;
enddefine;
rstart();
prb_rules ==>
prb_show_rules(prb_rules);

;;;TEST rule definitions.

vars foo_rules = [];

define :rule rule4 in foo_rules [test four] [NOT foo four] ;
    [do four]
enddefine;

prb_pr_rule("rule4", foo_rules);

define :rule rule6 in foo_rules [test 6] [NOT foo 6] ;
    [do 6]
enddefine;

prb_pr_rule("rule2");
prb_pr_rule("rule66", foo_rules);
prb_rule_named("rule6") ==>
prb_rule_named("rule6", foo_rules) ==>
prb_rule_named("rule3") ==>
prb_delete_rule("rule3", "prb_rules");
prb_rules ==>
prb_delete_rule("rule4", "foo_rules");
prb_rules ==>
foo_rules ==>

*/
[START addup example. Includes tests for DEL ] ==>


[] -> prb_rules;
false -> prb_repeating;
false -> prb_copy_modify;	;;; should be set true when it runs
;;; true -> prb_walk;

define :rule r1a [finish] [total ?x] [remember ?y] ;
	[SAY Total of numbers up to ?y is ?x.]
	[SAY not failing this time ]
	[STOP Thank You]
enddefine;

lvars x; ;;; used in WHERE condition
define :rule r2 [target ?x][WHERE x == 1]; [finish] enddefine;

define :rule r3 [target ?x] [NOT total =] ;
	[remember ?x] [total 1] [SAY Starting with target = ?x total = 1]
enddefine;

define :rule r4 [target ?x] [total ?y] [WHERE x /== 1] ;
	[DEL 1 2]		;;; could be [NOT target =] [NOT total =]
	;;; Next READ action as built in explanation in vector
	[READ [What is ?x + ?y] [:isinteger] [total ANSWER]
		{'I need to get the next subtotal' x '+' y}]
	[READ [What is ?x - 1] [:isinteger] [target ANSWER]]
enddefine;

define :rule r5 ;
	;;; Checking default READ constraint
	[READ 'What is the target number?' [?x:isinteger] [target ANSWER]]
enddefine;

;;;prb_show_rules();

false -> prb_chatty;
false -> prb_walk;

untrace prb_flush;
prb_run(prb_rules,[]);


[END addup example 1] =>

[START new addup. Does not ask user for decremented values] =>


define :ruleset prb_rules;

RULE r1
    [target 1] [total ?x] [remember ?y]
	==>
	[SAY Total of numbers up to ?y is ?x] [STOP Thank You]

RULE r2
    [target ?x] [NOT total =]
	==>
	[remember ?x] [total 1] [SAY Starting with (target = ?x) (total = 1)]

RULE r3
    [target ?x] [total ?y]
	==>
	[DEL 2]
	[REPLACE [target =] [target [popval x - 1]]]
	[SAY target reduced to [apply - ?x 1]]
	;;; ^^^ could have used [popval x - 1]
	[READ [What is ?x + ?y][:isinteger] [total ANSWER] ]
	[NULL [apply prb_print_database]]

;;; The next rule gets invoked first, because it has no conditions.

RULE r4
    ==>

	[SAY 'starting to compute addup']
	[READ 'What is the target number' [:isinteger] [target ANSWER]]
enddefine;

false -> prb_allrules; ;;; does not work with this true.

false -> prb_chatty;
false -> prb_walk;
prb_untrace("all");
prb_trace([r3 r2]);
untrace prb_applicable;
prb_run(prb_rules,[]);

define prb_finish(rules, data);
	prb_print_table(data);
enddefine;

[END addup 2] =>

[START iterative factorial] =>

define :ruleset prb_rules;

RULE f1
    ==>
	[READ 'What number is the input?' [:isinteger] [fact ANSWER]]
	[total 1]

RULE f2
	[fact ?x] [WHERE x /== 1] [total ?y]
	==>
	[DEL 1] [DEL 2]
	[fact [apply - ?x 1]] [total [apply * ?y ?x]]

RULE f3
	[DLOCAL [prb_walk = true]]
    [fact 1] [total ?y]
	==>
	[STOP the answer is ?y]
enddefine;

false -> prb_repeating;	;;; otherwise it fails
false -> prb_walk;
false -> prb_chatty;
false -> prb_show_conditions;
false -> prb_allrules;
false -> prb_sortrules;	;;;; needed if prb_repeating is false
prb_run(prb_rules, []);

[END factorial] =>


[START nested iterative factorial] =>
[Testing that nested rule definitions work.] =>

define test_fac(N);
	lvars N;
	dlocal
		 prb_repeating = false,	;;; otherwise it fails
 		 prb_walk = false,
 		 ;;;prb_show_conditions = true,
		 prb_chatty = false;

	define :ruleset fac_rules;
 		;;; [DLOCAL [prb_show_conditions = true][prb_walk = true]];
		RULE fr1
			==>
			[total 1]

		RULE fr2
			[fact ?x] [WHERE x /== 1] [total ?y]
			==>
			[DEL 1] [DEL 2]
			[LVARS [newx = x - 1][newy = y*x]]
			[fact ?newx] [total ?newy]

		RULE fr3
			[fact 1] [total ?y]
			==>
			[STOP the answer is ?y]
	enddefine;

	prb_run(fac_rules, [[fact ^N]]);
enddefine;

define fact(x);
	lvars x;
	if x == 0 then 1 else x * fact(x - 1) endif
enddefine;

[trying test_fac(5); should give answer 120]=>
test_fac(5);
[trying test_fac(10). Answer should be ^(fact(10))] =>
test_fac(10);
[END factorial] =>

[START iterative factorial going up] =>
[] -> prb_rules;

define :rule f1;
	[READ 'What number is the input?' [:isinteger] [fact [apply + ANSWER 1]]]
	[total 1][counter 1]
enddefine;

define :rule f2 [fact ?x] [counter ?c] [WHERE c = x] [total ?y];
	[SAY 'rule f2 succeeded']
	[STOP the answer is ?y]
enddefine;

define :rule f3
	[counter ?x]
	[total ?y][->>It] ;
	[SAY 'rule f3 triggered' counter ?x total ?y]
	[MODIFY 1 counter [popval x + 1]]
	[MODIFY ?It total [$$ y * x]]
enddefine;

false -> prb_repeating;	;;; otherwise it fails
false-> prb_walk;
false -> prb_chatty;
true -> prb_copy_modify;
erasenum(%2%) -> prb_finish;
prb_run(prb_rules, []);

[END factorial going up.] =>

[START factorial going up, but with prb_repeating true] =>

define :ruleset prb_rules;

RULE f1
    [fact ?x] [counter ?c] [WHERE c == x] [total ?y]
	==>
	[STOP the answer is ?y]

RULE f2
	[counter ?x]
	[total ?y] [->>It]
	==>
	[MODIFY 1 counter [apply + ?x 1]]
;;;	[MODIFY 1 counter [popval x + 1]]
	[MODIFY ?It total [popval y * x]]

RULE f3	 ;;; must be last rule if prb_repeating
    ==>
	[READ 'What number is the input?' [:isinteger] [fact [apply + ANSWER 1]]]
	[total 1][counter 1]
	[SAY 'problem stored']
	[POP11 prb_print_database()]
enddefine;

true-> prb_repeating;	;;; OK because rule f3 is last.
true-> prb_walk;
false-> prb_walk;
false -> prb_allrules;	;;; can't work if true
false-> prb_chatty;
false-> prb_copy_modify;
false -> prb_remember;	;;; saves storage
define test_pp;
	dlocal popgctrace = true;
	sysgarbage();
;;;	dlocal cucharout = erase;
	timediff() ->;
	prb_run(prb_rules, []);
	timediff();
enddefine;
test_pp() =>
[END factorial going up] =>

[START wine example] =>
[Next example is the wine example from TEACH PRODSYS] =>
/*
 true -> prb_recency;
 true -> prb_allrules;
identfn -> prb_sortrules;
*/

define :ruleset wine_rules;

RULE get_dish
    [wine property main_dish is unknown]
	==>
    [READ 'Is the main dish fish, meat, or poultry'
		[LOR [fish] [meat] [poultry] []]	;;; constraints on answer
    	[wine property main_dish is ANSWER]
		{'Because the best colour depends on the dish'}]
    [NOT wine property main_dish is unknown]

/* The next three rules determine the colour of the wine */

RULE colour1
    [wine property main_dish is fish]
	==>
    [wine property chosen_colour is white certainty 0.9]
    [wine property chosen_colour is red certainty 0.1]

RULE colour2
    [wine property main_dish is poultry]
	==>
    [wine property chosen_colour is white certainty 0.9]
    [wine property chosen_colour is red certainty 0.3]

RULE colour3
    [wine property main_dish is meat]
	==>
    [wine property chosen_colour is red certainty 0.7]
    [wine property chosen_colour is white certainty 0.2]

/* This rule is fired if the user does not state the main dish */

RULE dish_unknown
    [wine property main_dish is ]
	==>
    [wine property chosen_colour is red certainty 0.5]
    [wine property chosen_colour is white certainty 0.5]

/* Discover which colour of wine the user prefers */

RULE find_colour
    [wine property preferred_colour is unknown]
	==>
    [READ 'Do you prefer red or white wine'
		[LOR [red] [white] []]	;;; possible answers
    	[wine property preferred_colour is ANSWER  certainty 1.0]
		{'Because your preference should be taken into account'}]
    [NOT wine property preferred_colour is unknown]


/* This rule is fired if the user does not express a preference */

RULE no_preference
         [wine property preferred_colour is certainty 1.0]
	==>
    [wine property preferred_colour is red certainty 0.5 ]
    [wine property preferred_colour is white certainty 0.5]

/* The next two rules merge the user's preference with the program's
 *  choice of colour (based on the type of dish)
 */

RULE merge1

	[wine property chosen_colour is ?colour1 certainty ?cert1]
    [wine property preferred_colour is ?colour1 certainty ?cert2]
	==>
    [wine property colour is ?colour1
		certainty [popval cert1 + (0.4 * cert2 * (1 - cert1))]]
    [NOT wine property chosen_colour is ?colour1 certainty ?cert1]
    [NOT wine property preferred_colour is ?colour1 certainty ?cert2]

/* Cannot reconcile colours (ie. no preferred_colour for a particular
 * colour)
 */

RULE merge2

	[wine property chosen_colour is ?colour certainty ?cert]
	==>
    [NOT wine property chosen_colour is ?colour certainty ?cert]
    [wine property colour is ?colour certainty ?cert]

/* Print out the suggested wine.
 The special condition beginning with "where" specifies that
 this rule only applies if cert2 is greater than cert1.
 This ensures that the colour with the greater certainty is
 printed out. A "where clause" can be included in any rule. It
 consists of the word "where", followed by any POP-11 expression,
 which ends at the semi-colon at the end of the condition.
 The expression must return true or false, and the rule is only
 fired if in addition to all the patterns being present, the
 "where" expression returns true.
*/

RULE print_wine

        [wine property colour is ?colour1 certainty ?cert1]
        [wine property colour is ?colour2 certainty ?cert2]
		[WHERE cert2 > cert1]
		==>
    [NOT wine property colour is ?colour1 certainty ?cert1]
    [NOT wine property colour is ?colour2 certainty ?cert2]
    [SAY I would suggest a ?colour2 wine with a certainty of ?cert2]
	[STOP have a nice meal]


/* Default rule, fired if certainties for red and white are equal.
 Again, a "where clause" is used to check part of the condition,
 namely that colour1 and colour2 are different.
*/


RULE either
         [wine property colour is ?colour1 certainty ?cert1]
         [wine property colour is ?colour2 certainty ?cert1]
         [WHERE colour1 /= colour2]
	==>
    [NOT wine property colour is ?colour1 certainty ?cert1]
    [NOT wine property colour is ?colour1 certainty ?cert2]
    [SAY Either a red or a white wine would be appropriate]
	[STOP Sorry I cannot be more specific]

;;; Run the rules with the following initial database

RULE start
    [NOT wine property ==]
	==>
    [wine property main_dish is unknown]
    [wine property preferred_colour is unknown]
enddefine;

2 ->> prb_chatty -> prb_walk;
false -> prb_repeating;
[] -> prb_remember;
;;; true-> prb_allrules;	;;; shows and runs list of possibles each time
untrace prb_applicable;
prb_run(wine_rules,[]);
[END wine example] =>

[START animal rules] =>

;;; Now a set of rules to guess an animal by asking questions

[] -> prb_rules;

define :rule guess1 [class mammal] [legs 4] [milk no] [meat no];
    [STOP Its a horse]
enddefine;

define :rule guess2 [class mammal] [legs 4] [milk yes];
    [STOP Its a cow]
enddefine;

define :rule guess3 [class mammal] [meat no] [NOT milk =];
    [MENU
		{['Does it produce milk?']
		 [[1 'yes it does'] [2 'no it does not'][3 'dont know']]
		}
		[[1] [milk yes] [2] [milk no] [3] [milk unknown]]
	]
enddefine;

define :rule guess4 [class mammal];
    [READ 'does it eat meat' [OR yes no] [meat ANSWER]]
enddefine;

define :rule guess5 [class reptile];
    [STOP Its a crocodile]
enddefine;

define :rule guess6 [category animal] [legs 2] [wings no];
    [STOP Its a human]
enddefine;

define :rule guess7 [category animal] [legs 2] [wings yes];
    [STOP Its a  bird]
enddefine;

define :rule guess8 [category animal] [legs 2];
    [READ 'does it have wings' [OR yes no]  [wings ANSWER]]
enddefine;

define :rule guess9 [category animal] [legs 4];
    [MENU
		{'Is it a mammal or a reptile?'
		 [[1 mammal] [2 reptile]]
		 [1 mammal 2 reptile]}
		[[class ANSWER]]]
enddefine;

define :rule guess10 [category animal] [legs 6];
    [STOP Its an insect]
enddefine;

define :rule guess11 [category animal];
    [READ 'how many legs' [OR 2 4 6]  [legs ANSWER]]
enddefine;

define :rule guess12 [category vegetable];
	[STOP sorry I only eat meat]
enddefine;

define :rule guess13 [category mineral];
	[STOP sorry I know only about life]
enddefine;


define :rule guess14;
    [MENU
		{'Is it animal vegetable or mineral?'
		 [[1 animal] [2 vegetable] [3 mineral]]
		 [1 animal 2 vegetable 3 mineral]}
		[[category ANSWER]]
	]
enddefine;

false-> prb_walk; ;;; suppress interaction;
1 -> prb_chatty;
true -> prb_repeating;
false -> prb_allrules;
;;; Test the animals rules
popready -> interrupt;
prb_run(prb_rules, []);

[END animals] =>

[START animals reversed] =>
;;; Why won't it work with the rules in reverse order?
false-> prb_walk; ;;; suppress interaction;
false -> prb_chatty;
true -> prb_repeating;
false -> prb_allrules;
prb_run(rev(prb_rules),[], 3);

[END] =>

[START partitioned animal rules] =>

;;; Now a set of rules to guess an animal by asking questions

[] -> prb_rules;
vars animal = [], vegetable = [], mineral = [];

define :rule guess1 in animal [class mammal] [legs 4] [milk no] [meat no];
    [STOP Its a horse]
enddefine;

define :rule guess2 in animal [class mammal] [legs 4] [milk yes];
    [STOP Its a cow]
enddefine;

define :rule guess3 in animal [class mammal] [meat no] [NOT milk =];
    [MENU
		{['Does it produce milk?']
		 [[1 'yes it does'] [2 'no it does not'][3 'dont know']]
		}
;;; Either of the following will do
;;;		[[1] [milk yes] [2] [milk no] [3] [milk unknown]]
		[1 [milk yes] 2 [milk no] 3 [milk unknown]]
	]
enddefine;

define :rule guess4 in animal [class mammal] [legs 4] [meat yes];
	[STOP 'Of course its a tiger!']
enddefine;

define :rule guess5 in animal [class mammal];
    [READ 'does it eat meat' [OR yes no] [meat ANSWER]]
enddefine;


define :rule guess6 in animal [class reptile];
    [STOP Its a crocodile]
enddefine;

define :rule guess7 in animal [legs 2] [wings no];
    [STOP Its a human]
enddefine;

define :rule guess8 in animal [legs 2] [wings yes];
    [STOP Its a  bird]
enddefine;

define :rule guess9 in animal [legs 2];
    [READ 'does it have wings' [OR yes no]  [wings ANSWER]]
enddefine;

define :rule guess10 in animal [legs 4];
    [MENU
		{'Is it a mammal or a reptile?'
		 [[1 mammal] [2 reptile]]
		 [1 mammal 2 reptile]}
		[[class ANSWER]]]
enddefine;

define :rule guess11 in animal [legs 6];
    [STOP Its an insect]
enddefine;

define :rule guess12 in animal;
    [READ 'how many legs' [OR 2 4 6]  [legs ANSWER]]
enddefine;

define :rule guess13 in vegetable ;
	[STOP sorry I only eat meat]
enddefine;

define :rule guess14 in mineral;
	[STOP sorry I know only about life]
enddefine;


define :rule guess14;
    [MENU
		{'Is it animal vegetable or mineral?'
		 [[1 animal] [2 vegetable] [3 mineral]]
		 [1 animal 2 vegetable 3 mineral]}
		[[RESTORE RULES ANSWER]]
	]
enddefine;

true -> prb_walk;
1 -> prb_chatty;
true -> prb_repeating;
false -> prb_allrules;
;;; Test the animals rules
popready -> interrupt;
prb_run(prb_rules, []);

[END animals with partitioned rules] =>

[START testing sort by recency. Probably pointless] =>
[] -> prb_rules ;
true -> prb_walk;
true -> prb_chatty;
true -> prb_recency;	;;; needed for fourth element in possibility vector
1-> prb_allrules;

'Test uses prb_recof. To be withdrawn' =>
define prb_sortrules(possibles) -> possibles;
    lvars possibles;
    ;;; prefer rule with condition made true most recently

    define lconstant prb_youngest(instance) -> num;
        ;;; Given a rule instance find the "age" of the most recently
        ;;; added item making one of its conditions true.
        lvars n, instance, num=9999999;
        for n in_vector prb_recof(instance) do
            unless n == 0 then
                min(num, n) -> num
            endunless
        endfor
    enddefine;

    define lconstant prb_more_recent(instance1, instance2);
        ;;; given two rule instances return true if the first has the
        ;;; most recent enabling condition
        lvars instance1, instance2;
        prb_youngest(instance1)
            <=
        prb_youngest(instance2)
    enddefine;

    syssort(possibles, prb_more_recent) -> possibles
enddefine;

trace prb_sortrules;
untrace prb_applicable;
true -> prb_walk;
true -> prb_recency;
true -> prb_allrules;
[] -> prb_rules;

define :rule r1 [a ?x];
	[b ?x]
	[a [popval x + x]]
enddefine;

define :rule r2 [b ?x];
	[c ?x]
	[b ?x]
enddefine;

define :rule r3 [c ?x];
	[d ?x]
enddefine;

define :rule r4 [d ?x];
	[STOP 'That is all']
enddefine;

11 -> prb_chatty;
prb_run(prb_rules, [[a 1]]);
untrace prb_sortrules;
identfn -> prb_sortrules;



[END] =>

[START] =>
[Testing ordering by specificity of rules] =>
;;; This should stop faster than previous ruleset
define prb_sortrules(possibles) -> possibles;
    lvars possibles;

    define lconstant prb_more_specific(instance1, instance2);
        lvars instance1, instance2;

        listlength(prb_conditions(prb_ruleof(instance1)))
            >=
               listlength(prb_conditions(prb_ruleof(instance2)))
    enddefine;

    syssort(possibles, prb_more_specific) -> possibles;
	'Possible rules' =>
	possibles ==>
enddefine;

;;;identfn-> prb_sortrules;
untrace prb_sortrules;

[] -> prb_rules;
true -> prb_walk;
true -> prb_chatty;
true -> prb_repeating;
true-> prb_allrules;

define :rule r1 [a ?x];
	[b ?x]
enddefine;

define :rule r2 [a ?x] [b ?x];
	[c ?x]
enddefine;

define :rule r3 [a ?x] [b ?x] [c ?x];
	[d ?x]
enddefine;

define :rule r4 [a ?x] [b ?x] [c ?x] [d ?x];
	[STOP 'That is all']
enddefine;

prb_run(prb_rules, [[a 1]]);

false -> prb_sortrules;
[END] =>

[START] =>
[testing prevention of re-run of action on same database item.] =>
;;; should eventually get to r4
[] -> prb_rules;
true -> prb_walk;
false -> prb_chatty;
false -> prb_recency;
true -> prb_allrules;
false -> prb_repeating;
untrace prb_applicable;

false -> prb_sortrules;

define :rule r1 [c 2];
	[d 2]
enddefine;

define :rule r2 [a ?x];
	[b ?x]
enddefine;

uses oneof;

define :rule r3 [b ?x];
	[LVARS [item = oneof([1 2 3 2])]]
	[c ?item]
	[a ?x]
enddefine;


define :rule r4 [d =];
	[STOP 'd in database - so stop']
enddefine;

prb_run(prb_rules, [[a 1]]);

[END] =>

[START] =>
'Testing a user-defined action type ' =>

define doREPORT(rule_instance, action);
	lvars rule_instance, action, rule = prb_ruleof(rule_instance);
	;;; test prb_action_type;
	prb_value([Obeying rule with conditions [apply prb_conditions ^rule]]) ==>
	[Action is ^(tl(action))] ==>
enddefine;

"doREPORT" -> prb_action_type("REPORT");

[] -> prb_rules;

define :rule rr1 [n ?a][n ?b][WHERE a > b][n ?c][WHERE b > c];
	[REPORT doing ?a ?b ?c]
	[n [popval random(a + b + c)]]
	[READ 'look at data'[]]
enddefine;

define :rule rr2 [NOT n =];
	[SAY adding n values]
	[n 3] [n 5] [n 7]
enddefine;

define :rule rr3 [n ?a][WHERE a mod 2 == 0];
	[STOP found [n ?a]]
enddefine;

true -> prb_recency;
true -> prb_walk;;
true -> prb_chatty;
true -> prb_repeating;
true -> prb_allrules;
prb_run(prb_rules,[]);
[END] =>

[START test MODIFY] =>
[] -> prb_rules;

define :rule r1 ;
	[a 1]
	[a 2]
	[a 3]
enddefine;

define :rule r2 [a ?x]
	[WHERE x < 5];
	[SAY changing a]
	[MODIFY 1 a 99]
	[READ '[a ?x] changed' []]
enddefine;

define :rule r3 ;
	[b 1]
	[b 2]
	[b 3]
	[READ 'Check b values (.data)' []]
enddefine;

define :rule r4 [b ?x] [WHERE x < 5];
	[SAY changing b]
	;;; This should change ALL the b values
	[MODIFY [b =] b 99]
	[READ 'b changed. Check (.data)' []]
enddefine;

false -> prb_allrules;
false -> prb_chatty;
true -> prb_walk;
false -> prb_walk;
false -> prb_repeating;

untrace prb_flush;
untrace prb_add;
prb_run (prb_rules, []);

[END modify test] =>

[START test dynamic addition of rule] =>

[] -> prb_rules;
uses gensym;
false-> prb_walk;
true -> prb_allrules;
true -> prb_repeating;

define :rule rr1 [== ?x:isinteger ==] [WHERE x mod 2 = 0];
	[DEL 1]
	[RULE TYPE prb_rules
		[popval gensym("rrr") ]			;;; new rule name
		;;; note: a weight is optional here
		[[== ?y:isinteger ==] [WHERE y mod 2 = 0]]	;;; conditions
		[[STOP Found even number ?y]]]				;;; actions
enddefine;

define :rule rr2;
	[a [popval random(5)]]
enddefine;

define :rule rr3 [a ?x];
	[a [popval x + 1]]
enddefine;

true -> prb_walk;
prb_run(prb_rules, []);
[END] =>

[START test of prb_get_input and OR ] =>

[] -> prb_rules;
false -> prb_sortrules;
define procedure fac(n);
	if n == 0 then 1
	else fac(n-1)*n
	endif
enddefine;

false-> prb_chatty;
true-> prb_chatty;
false -> prb_walk;
true ->> prb_repeating ->> prb_allrules -> prb_get_input;

define :rule g0
	[NOT start]
	;
	[SAY type 'a ...' or 'd ...' then RETURN]
	[ADD start]
enddefine;

define :rule g1 [fact 600 ?x];
	[STOP final case - factorial 600 is ?x]
enddefine;

define :rule g2 [OR [d ==] [a ==]] [fact ?y ?z]
	==>
	;;; because prb_get_input is true, if user types a d or a followed by
	;;; anything it will be added to the database, and this rule will then
	;;; be triggered. This will make the program pause.
	[DEL 1]
	[SAY factorial ?y is ?z]
	[READ 'OK?' []]
enddefine;

define :rule g3 [fact ?x ==];
	;;; repeatedly do this until interrupted by above
	[DEL 1]
	[SAY fact ?x deleted]
	[fact [popval x + 1] [popval fac(x + 1) ]]
enddefine;

/*
define :rule g4
	[WHERE sys_input_waiting(popdevin)]
	==>
	[POP11 prb_add(readline())]
	[POP11 'input waiting:'=> sys_input_waiting(popdevin) =>]
;;;	[POP11 sysflush(popdevout);]
	[POP11 syssleep(200)]
	[SAY Flushed]
enddefine;
*/

define :rule g5
	==>
	[POP11 'input waiting:'=> sys_input_waiting(popdevin) =>]
	[POP11 syssleep(100)]
enddefine;

prb_run(prb_rules, [[fact 1 1]]);
false -> prb_get_input;

[END test of prb_get_input] =>

[START test of recursive factorial and SWITCHON] =>

uses timediff;
[] -> prb_rules;

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


define :rule fac1 [go] [factorial ?n val ?y] [start ?n];
	;;; goal achieved
	[DEL 1 2 3]
	[POP11 prb_add(if y > 10 then [big] else [small] endif) ]
	[SWITCHON ?y
		2 [SAY SMALL]  6 [SAY SMALL ] 24 [SAY MEDIUM] [SAY BIG]]
	[NOT want =]
	[SAY time [popval timediff()]]
	[SAY factorial of ?n is ?y]
enddefine;


define :rule fac2
	;;; unwind
		 [go] [factorial ?n val ?y] [->> FacCond];
	[MODIFY ?FacCond val [popval (n + 1) * y] factorial [popval n + 1] ]
enddefine;


define :rule fac3
	;;; terminate preparation
		 [want 1];
	[DEL 1]
	[go]
	[factorial 1 val 1]
	[READ 'preparation finished' [==] []]
enddefine;

define :rule fac4
	;;; prepare
		 [want ?x];
	[MODIFY 1 want [popval x - 1]]
enddefine;

define :rule fac5 [start ?x];
	[want ?x]
enddefine;

define :rule fac6;
	[READ 'What number?' [?x:isinteger] [start ANSWER]]
	[POP11 timediff() ->]
enddefine;

false -> prb_chatty;
false-> prb_walk;
true -> prb_repeating;
false -> prb_allrules;
true -> prb_copy_modify;
prb_run(prb_rules, []) =>

[END] =>

[START TESTING NOT_EXISTS] =>
[] -> prb_rules;
17*13 -> prb_chatty;
true -> prb_chatty;
true -> prb_walk;
false-> prb_show_conditions;
true -> prb_repeating;
false -> prb_allrules;
true -> prb_copy_modify;
true -> prb_debugging;

define :rule pstart
	[NOT started];
	[r a z] [r a b] [ r b c] [r c d] [ s a q ] [s d c]
	[started]
	[SAY started]
	[POP11 prb_print_database() ]
enddefine;

define :rule test1
	[NOT_EXISTS [r a ?x] [NOT r ?x ?y]]
	[POP11 prb_print_database() ]
	[POP11 [[r a ^x] [r ^x ^y]] =>]
	;
	[SAY FOUND 1]
	[STOP]
enddefine;

define :rule test2 [NOT_EXISTS [s a ?x] [s ?x ?y]];
	[SAY FOUND 2]
	[STOP]
enddefine;

prb_run(prb_rules, []) =>

[END] =>

[START TESTING IMPLIES] =>
[] -> prb_rules;
true -> prb_chatty;
true -> prb_walk;
false -> prb_repeating;
false -> prb_allrules;
true -> prb_copy_modify;
true -> prb_debugging;

define :rule pstart [NOT started];
	[r a z] [r a b] [ r b c]  [r b e] [r q a] [ s b q ] [s c c]
	[male fred] [human fred]
	[male joe] [human joe]
	[started]
enddefine;

define :rule panic [IMPLIES [[human ?x]] [male ?x]];
	[SAY 'PANIC no more women']
enddefine;


define :rule test1 [IMPLIES [[r ?x ==]] [r = ?x]];
	[SAY FOUND 1]
	[STOP]
enddefine;

define :rule test2 [IMPLIES [[s ?x =]] [r == ?x ==]];
	[SAY FOUND 2]
	[STOP]
enddefine;

procedure();
	dlocal prb_show_conditions = [pstart panic];
	prb_run(prb_rules, []);
endprocedure();

[END] =>

[START TESTING IMPLIES implemented as NOT_EXISTS] =>
[] -> prb_rules;
true -> prb_chatty;
true -> prb_walk;
true-> prb_show_conditions;
false -> prb_repeating;
false -> prb_allrules;
true -> prb_copy_modify;
true -> prb_debugging;

define :rule pstart [NOT started];
	[r a z] [r a b] [ r b c]  [r b e] [r q a] [ s b q ] [s c c]
	[male fred] [human fred]
	[male joe] [human joe]
	[started]
enddefine;

define :rule panic [NOT_EXISTS [human ?x] [NOT male ?x]];
	[SAY 'PANIC no more women']
enddefine;


define :rule test1 [NOT_EXISTS [r ?x ==] [NOT r = ?x]];
	[SAY FOUND 1]
	[STOP]
enddefine;

define :rule test2 [NOT_EXISTS [s ?x =] [NOT r == ?x ==]];
	[SAY FOUND 2]
	[STOP]
enddefine;

prb_run(prb_rules, []) =>

[END] =>

[START] =>
'Testing multiple instances' =>

define :ruleset mult;

	RULE start
		[NOT started]
		==>
		[on a b]
		[on a c]
		[on b d]
		[on c e]
		[started]

	RULE above
		[on ?x ?y]
		[on ?y ?z]
		[NOT done ?x ?z]
		==>
		[SAY ?x above ?z via ?y]
		[done ?x ?z]

	RULE stop
		;;; The next line is not needed if prb_sortrules is false.
		[started]
		==>
		[STOP stopping]

enddefine;

true ->> prb_walk -> prb_show_conditions;	
true -> prb_allrules;
false -> prb_sortrules;
identfn -> prb_sortrules;


prb_run(mult, []);

[END] =>

[START] =>
'Testing STOPIF QUIT QUITIF' =>

define :ruleset mult;

	RULE start
		[NOT started]
		==>
		[on a b]
		[on a c]
		[on b d]
		[on c e]
		[started]

	RULE above
		[on ?x ?y]
		[on ?y ?z]
		[NOT done ?x ?z]
		==>
		;;; "done" should never come out true.
		[LVARS [done = prb_present([done ?x ?z])]]
		[QUITIF ?done already done ?x above ?z]
		[SAY ?x above ?z via ?y]
		[done ?x ?z]
		[QUIT 'quitting']
		[SAY quit failed]

	RULE stop
		;;; The next line is not needed if prb_sortrules is false.
		[started]
		==>
		[STOP stopping]

enddefine;


true ->> prb_walk -> prb_show_conditions;	
;;;false -> prb_show_conditions;	
true -> prb_allrules;
false -> prb_sortrules;

prb_run(mult, []);
true ->> prb_walk -> prb_show_conditions;	
false -> prb_show_conditions;	
true -> prb_allrules;
identfn -> prb_sortrules;

prb_run(mult, []);

true ->> prb_walk -> prb_show_conditions;	
false -> prb_show_conditions;	
false -> prb_allrules;
identfn -> prb_sortrules;

prb_run(mult, []);


[END] =>


/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 14 1995
	Included test for prb_show_conditions as a list.
 */
