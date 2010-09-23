/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/newkit/prb/lib/prbriver.p
 > Purpose:			Demonstrate	use of poprulebase for searching
 > Author:          Aaron Sloman, Oct 10 2000
 > Documentation:	TEACH RULEBASE, HELP POPRULEBASE
 > Related Files:	TEACH PRBRIVER
 */


/*
Load the file then do
;;; Set up goal state. This will be initial database item.
vars goal_state =
    [goal
        [[isat man right]
        [isat fox right]
        [isat chicken right]
        [isat grain right]]];

prb_run(depth_first, [^goal_state]);


;;; Or equivalently
prb_run(depth_first, [[goal [[NOT isat = left]] ]]);

;;; It should also be able to achieve the following goal
prb_run(depth_first, [[goal [[isat man left] [isat grain right]] ]]);

prb_run(depth_first,
	[[goal [[isat chicken left] [isat fox right][NOT isat man right]] ]]);

;;; an impossible goal set
prb_run(depth_first,
	[[goal [[isat chicken left] [isat grain left] [NOT isat man left]] ]]);

true -> prb_walk;         ;;; Make this true for more interaction
true -> prb_chatty;       ;;; Make this true or an integer for tracing
true -> prb_show_conditions;  ;;; Make true for detailed tracing of
                            ;;; condition testing
*/



section;

uses poprulebase;



true -> prb_copy_modify;   ;;; normally safer
false -> prb_walk;         ;;; Make this true for more interaction
false -> prb_chatty;       ;;; Make this true or an integer for tracing
false -> prb_show_conditions;  ;;; Make true for detailed tracing of
                            ;;; condition testing
false -> prb_allrules;     ;;; Always run the first applicable rule
true -> prb_repeating;     ;;; The rules do their own checking
true -> prb_pausing;       ;;; Make [PAUSE] actions work

;;; Because prb_sortrules is not re-defined, the default strategy of
;;; selecting the first applicable rule will operate.

true -> prb_explain_trace; ;;; run [EXPLAIN ...] actions

/* DEFINE SOME UTILITIES */


define thing_data() -> data;
    ;;; Return alphabetically ordered list of database facts
    ;;; Convenient "canonical" form, for detecting circular moves

    lvars data;

    [%prb_foreach([isat = =], procedure(); prb_found endprocedure)%]
        -> data;

	;;; Order things on the basis of their second element
    syssort(data,
        procedure(item1,item2) -> boole;
            lvars item1, item2, boole;
            alphabefore(item1(2), item2(2)) -> boole
        endprocedure) -> data

enddefine;

define display_data;
    ;;; Prints out a visual display, showing what isat left and right

    vars x;
    ;;; create a list and print it out
    [%
	    'THE WORLD',
        prb_foreach([isat ?x left], procedure(); x endprocedure),
        '.....',
        prb_foreach([isat ?x right], procedure(); x endprocedure)
    %] ==>

enddefine;

/* NOW DEFINE THE RULES */


define :ruleset start_rules;
	;;; This rule sets up the database and fires the rest off.
	;;; It runs only once and then sets up the ruleset "solve_rules".
	;;; So it does not require any further action to stop itself being
	;;; re-invoked, as it is not in that ruleset.


  RULE start
    ==>
    ;;; initial state
    [isat chicken left]
    [isat fox left]
    [isat grain left]
    [isat man left]
    [plan]
    [history]

    ;;; some useful facts
    [opposite right left]
    [fox can eat chicken]
    [chicken can eat grain]

    ;;; Now the constraints - checked by rule check
    ;;; first constraint - fail if something can eat something
    [constraint Eat
        [[isat ?thing1 ?side]
            [NOT isat man ?side]
            [?thing1 can eat ?thing2]
            [isat ?thing2 ?side]]
        [?thing1 can eat ?thing2 GO BACK]]

    ;;; second constraint, is the current state one that's in the history?
    [constraint Loop
        [[state ?state] [history == [= ?state] == ]]
        ['LOOP found - Was previously in state: ' ?state]]


    ;;; describe the goal as a list of patterns

    ;;; set up initial state record in the database
    [state [apply thing_data]]

    ;;; display initial state
    [POP11 display_data()]
    [EXPLAIN 'Setting up "solve" ruleset']
    [RESTORERULESET solve_rules]
enddefine;


;;; The next rule is used to complete the book-keeping for different
;;; move actions, and display the result. It is invoked only after
;;; [complete_move] has been added to the database by a move operator

define :ruleset solve_rules;

  RULE complete_move  ;;; in solve_rules
    [complete_move ?move]
    [state ?state]
    [POP11 'Checking complete_move in solve_rules' => ]
    ==>
    [DEL 1 ]
    ;;; Extend the history - used for checking circularity
    [PUSH [?move ?state] history]
    ;;; Extend the plan
    [PUSH ?move plan]
    [SAY 'plan is' [popval rev(tl(prb_present([plan ==])))]]
    ;;; Create up to date state record (in canonical form)
    [MODIFY 2 state [apply thing_data]]
    ;;; record that this move has been tried in this state
    [tried ?move ?state]
    ;;; report move
    [SAY Trying ?move]
    ;;; print result
    [POP11 display_data()]

    ;;; Next line is simply to pause till user presses RETURN key
    [PAUSE]

    [RESTORERULESET check_rules] ;;; the check_rules ruleset is below


;;; The next rule checks whether the problem has been solved, and
;;; if so aborts the program. The goal description is stored in
;;; the database, to make it easy to change, instead of always using the
;;; same goal.

  RULE done  ;;; in solve_rules
    [goal ?goallist]
    [ALL ?goallist]    ;;; As if the conditions were in this rule.
    [plan ??plan]
    ==>
    [SAY 'Goal state achieved']
    [POP11 display_data()]
    [SAY 'THE SUCCESSFUL PLAN WAS']
    [SAY [apply rev ?plan]]
    [PAUSE]
    ;;; Reset the rulefamily to its starting state so that it can be
    ;;; used on another problem
    [RESTORERULESET start_rules]
    [STOP 'Everything successfully moved over']


;;; Now the move operators. Because prb_allrules is set
;;; FALSE, only one will be fired on each cycle. (Note the use of
;;; the word quotes in the "WHERE" condition.)

  RULE move_thing  ;;; in solve_rules
    [isat man ?place]
    [isat ?thing ?place]
    [WHERE thing /== "man"]
    [OR [opposite ?place ?other][opposite ?other ?place]]
    [state ?state]
    [NOT tried [move ?thing] ?state]
    [NOT history [[move ?thing] =] ==] ;;; not last thing moved
    ==>
    [SAY 'trying to move the' ?thing]
    [DEL 1 2 ]
    [isat man ?other]
    [isat ?thing ?other]
    [complete_move [move ?thing]]

  RULE move_man  ;;; in solve_rules
    [isat man ?place]
    [OR [opposite ?place ?other][opposite ?other ?place]]
    [state ?state]
    [NOT tried [move man] ?state]
    [NOT history [move man] ==]    ;;; man not last thing moved
    ==>
    [SAY 'trying to move the man']
	[DEL 1]
	[isat man ?other]
    [complete_move [move man]]

;;; This must be the last rule.
;;; When there's nothing left to try, try to undo last move

  RULE goback  ;;; in solve_rules
    [history = ==]
    ==>
    [SAY 'no more options - retracing']
    [RESTORERULESET backtrack_rules]     ;;; defined below
enddefine;


;;; Now the backtracking ruleset

define :ruleset backtrack_rules;

;;; On failure this rule is triggered to back-track by restoring a
;;; previous state, and re-displaying it.

  RULE undo  ;;; in backtrack_rules
    [history [?move ?oldstate] ??history]
    [state =]
    ==>
    [SAY undoing ?move]
    [MODIFY 2 state ?oldstate]
    [NOT isat = =]
    [POP history]       ;;; Remove latest addition to history
    [POP plan ]         ;;;   ... and to plan
    [ADDALL ??oldstate] ;;; Restore the previous [... isat ...] items
    [POP11 display_data()]
    [SAY 'Restored previous state']
    [SAY 'plan is' [popval rev(tl(prb_present([plan ==])))]]
    [PAUSE]
    [RESTORERULESET solve_rules]     ;;; solve_rules defined above
enddefine;

;;; The next rule checks that an attempted move is legal, and if
;;; not causes back-tracking, by restoring a previous state,
;;; and re-displaying it. Legality is determined by constraints
;;; in the constraints database.

define :ruleset check_rules;

  RULE check_constraints  ;;; in check_rules
    [constraint ?name ?checks ?message]
    [ALL ?checks]  ;;; ([WHERE prb_allpresent(checks)] ;;; )
    ==>
    [SAY Constraint ?name violated]
    [SAY ??message]
    [RESTORERULESET backtrack_rules]     ;;; defined above

  RULE checks_ok  ;;; in check_rules
    ;;; If no constraint violations were detected by previous rules,
    ;;; restore normal rules to continue searching for a solution.
    ==>
    [RESTORERULESET solve_rules]
enddefine;

/*
-- -- Defining the rulefamily for the depth first program
*/

;;; This is now to combine several rulesets into a rulefamily.

define :rulefamily depth_first;
    ruleset: start_rules
    ruleset: solve_rules
    ruleset: backtrack_rules
    ruleset: check_rules
enddefine;

/*

depth_first.datalist ==>

*/


;;; for uses
global constant prbriver = true;

endsection;
