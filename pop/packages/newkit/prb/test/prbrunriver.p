;;; VERSION FOR TESTING "DO" CONDITIONS

;;; Extract from TEACH PRBRIVER
;;;                                     Aaron Sloman. Updated April 1996
/*

Search for "define :ruleset"

Look at rules "start", "done" "undo" "move_man" "check_constraints"

*/


define instruct();
pr('\nInitially the man, fox, chicken and grain are on the left bank\
\
         [man fox chicken grain {boat} ............       ]\
\
   and the man can move only one item over at a time. This program works\
   out a plan to achieve a goal subject to the constraint that the fox is\
   not left alone with the chicken, or the chicken with the grain\
\Type:\
\tgo1(); - to get grain at right and man at left\
OR\
\tgo2(); - to get everything on the right\
OR\
\tgo3([[man isat right][chicken isat left]]);\
\
- or something similar with a different goal [[note the double brackets]]\
\
OR\
\tbye;  - to leave poplog\
\
\tWhen prompted with "?" just press RETURN to continue.\n');
enddefine;


uses prblib;

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

    [%prb_foreach([= isat =], procedure(); prb_found endprocedure)%]
        -> data;

    syssort(data,
        procedure(item1,item2) -> boole;
            lvars item1, item2, boole;
            alphabefore(front(item1), front(item2)) -> boole
        endprocedure) -> data

enddefine;

define display_data;
    ;;; Prints out a visual display, showing what isat left and right

    vars x;
    'THE WORLD' =>
    ;;; create a list and print it out
    [%
        prb_foreach([?x isat left], procedure(); x endprocedure),
        '.....',
        prb_foreach([?x isat right], procedure(); x endprocedure)
    %] ==>

enddefine;

/* NOW DEFINE THE RULES */

;;; This rule sets up the database and fires the rest off.
;;; It runs only once and then sets up the ruleset "solve_rules".
;;; So it does not require any further action to stop itself being
;;; re-invoked, as it is not in that ruleset.

define :ruleset prb_rules;

RULE start
    ==>
    ;;; initial state
    [chicken isat left]
    [fox isat left]
    [grain isat left]
    [man isat left]
    [plan]
    [history]

    ;;; some useful facts
    [opposite right left]
    [fox can eat chicken]
    [chicken can eat grain]

    ;;; Now the constraints - checked by rule check
    ;;; first constraint - fail if something can eat something
    [constraint Eat
        [[?thing1 isat ?side]
            [NOT man isat ?side]
            [?thing1 can eat ?thing2]
            [?thing2 isat ?side]]
        [?thing1 can eat ?thing2 GO BACK]]

    ;;; second constraint, is the current state one that's in the history?
    [constraint Loop
        [[state ?state] [history == [= ?state] == ]]
        ['LOOP found - Was previously in state: ' ?state]]

    [EXPLAIN 'Setting up "solve" ruleset']
    [RESTORE RULES solve_rules]

    ;;; describe the goal as a list of patterns

    ;;; set up initial state record in the database
    [state [apply thing_data]]

    ;;; display initial state
    [POP11 display_data()]
enddefine;

;;; The next rule is used to complete the book-keeping for different
;;; move actions, and display the result. It is invoked only after
;;; [complete_move] has been added to the database by a move operator

define :ruleset solve_rules;

RULE complete_move  ;;; in solve_rules
        [complete_move ?move][->>It1]
        [state ?state][->>It2]
    [DO DEL ?It1]
    ;;; Extend the history - used for checking circularity
	[DO SAY pushing [?move ?state] onto history]
    [DO PUSH [?move ?state] history]
    ;;; Extend the plan
	[DO SAY pushing ?move  onto plan]
    [DO PUSH ?move plan]
    [DO SAY 'plan is' [popval rev(tl(prb_present([plan ==])))]]
    ;;; Create up to date state record (in canonical form)
    [DO MODIFY ?It2 state [apply thing_data]]
    ;;; record that this move has been tried in this state
    [DO tried ?move ?state]
    ;;; report move
    [DO SAY Trying ?move]
    ;;; print result
    [DO POP11 display_data()]

    ;;; Next line is simply to pause till user presses RETURN key
    [DO PAUSE]

    [DO RESTORE RULES check_rules] ;;; the check_rules ruleset is below
    ==>


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
    [STOP 'Everything successfully moved over']


;;; Now the move operators. Because prb_allrules is set
;;; FALSE, only one will be fired on each cycle. (Note the use of
;;; the word quotes in the "WHERE" condition.)


vars thing;  ;;; used in the WHERE condition.

RULE move_thing  ;;; in solve_rules
         [man isat ?place][->>It1]
         [?thing isat ?place][->>It2]
         [WHERE thing /== "man"]
         [OR [opposite ?place ?other][opposite ?other ?place]]
         [state ?state]
         [NOT tried [move ?thing] ?state]
         [NOT history [[move ?thing] =] ==] ;;; not last thing moved
         ==>
    [SAY 'trying to move the' ?thing]
    [MODIFY ?It1 isat ?other]
    [MODIFY ?It2 isat ?other]
    [complete_move [move ?thing]]

RULE move_man  ;;; in solve_rules
         [man isat ?place][->>It]
         [OR [opposite ?place ?other][opposite ?other ?place]]
         [state ?state]
         [NOT tried [move man] ?state]
         [NOT history [move man] ==]    ;;; man not last thing moved
    ==>
    [SAY 'trying to move the man']
    [MODIFY ?It isat ?other]
    [complete_move [move man]]

;;; This must be the last rule.
;;; When there's nothing left to try, try to undo last move

RULE goback  ;;; in solve_rules
    [history = ==]
    ==>
    [SAY 'no more options - retracing']
    [RESTORE RULES backtrack_rules]     ;;; defined below
enddefine;

;;; Now the backtracking ruleset

define :ruleset backtrack_rules;

;;; On failure this rule is triggered to back-track by restoring a
;;; previous state, and re-displaying it.

RULE undo  ;;; in backtrack_rules
         [history [?move ?oldstate] ??history][->>It]
         [state =]
         ==>
    [SAY undoing ?move]
    [MODIFY ?It state ?oldstate]
    [NOT = isat = ]
    [POP history]       ;;; Remove latest addition to history
    [POP plan ]         ;;;   ... and to plan
    [ADDALL ??oldstate] ;;; Restore the previous [... isat ...] items
    [POP11 display_data()]
    [SAY 'Restored previous state']
    [SAY 'plan is' [popval rev(tl(prb_present([plan ==])))]]
    [PAUSE]
    [RESTORE RULES solve_rules]     ;;; solve_rules defined above
enddefine;

;;; The next rule checks that an attempted move is legal, and if
;;; not causes back-tracking, by restoring a previous state,
;;; and re-displaying it. Legality is determined by constraints
;;; in the constraints database.

define :ruleset check_rules;

RULE check_constraints  ;;; in check_rules
         [constraint ?name ?checks ?message]
         [ALL ?checks]  ;;; ( [WHERE prb_allpresent(?checks)] )
         ==>
    [SAY Constraint ?name violated]
    [SAY ??message]
    [RESTORE RULES backtrack_rules]     ;;; defined above

RULE checks_ok  ;;; in check_rules
    ;;; If no constraint violations were detected by previous rules,
    ;;; restore normal rules to continue searching for a solution.
         ==>
    [RESTORE RULES solve_rules]
enddefine;

;;; Uncomment the following for selective tracing of rules
;;;prb_trace([goback complete_move undo done]);

;;; Set up goal state. This will be initial database item.
vars goal_state =
    [goal
        [[man isat right]
        [fox isat right]
        [chicken isat right]
        [grain isat right]]];

2 -> prb_chatty;

define go1();
    'Trying to achieve [goal [[man isat left] [grain isat right]] ]'=>
    prb_run(prb_rules, [[goal [[man isat left] [grain isat right]] ]]);
enddefine;

define go2();
    'Trying to get everything across' =>
    goal_state ==>
    prb_run(prb_rules, [^goal_state]);
    /*
    ;;; Or equivalently
    prb_run(prb_rules, [[goal [[NOT = isat left]] ]]);

    ;;; It should also be able to achieve the following goal
    */
enddefine;

define go3(goal);
    prb_run(prb_rules, [[goal ^goal]]);
enddefine;

;;; instruct();

pr('\nFor information type \n\tinstruct();\n');

/*
--- $poplocal/local/newprb/teach/prbrunriver.p
--- Copyright University of Birmingham 1996. All rights reserved. ------
*/
