/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/prb/test/prbriver.p
 > Purpose:			A test file for poprulebase
 > Author:          Aaron Sloman, Jul  2 1995
 > Documentation:	TEACH PRBRIVER OLD VERSION
 > Related Files:
					$poplocal/local/prb/test/prbriver2.p
 */


/*
THIS VERSION HAS VARIABLES AT THE FRONT OF PATTERNS

SEE TEACH PRBRIVER

Load the file then do
;;; Set up goal state. This will be initial database item.
vars goal_state =
    [goal
        [[man isat right]
        [fox isat right]
        [chicken isat right]
        [grain isat right]]];

prb_run(prb_rules, [^goal_state]);


;;; Or equivalently
prb_run(prb_rules, [[goal [[NOT = isat left]] ]]);

;;; It should also be able to achieve the following goal
prb_run(prb_rules, [[goal [[man isat left] [grain isat right]] ]]);

prb_run(prb_rules,
	[[goal [[chicken isat left] [fox isat right][NOT man isat right]] ]]);

prb_run(prb_rules,
	[[goal [[chicken isat left] [grain isat right][NOT man isat left]] ]]);

;;; an impossible goal set
prb_run(prb_rules,
	[[goal [[chicken isat left] [grain isat left] [NOT man isat left]] ]]);

;;; Optional extra tracing and interaction
true -> prb_walk;         ;;; Make this true for more interaction
true -> prb_chatty;       ;;; Make this true or an integer for tracing
true -> prb_show_conditions;  ;;; Make true for detailed tracing of

*/

uses poprulebase;


vars                    ;;; declare four empty rule sets
    prb_rules = [],
    check_rules = [],
    solve_rules = [],
    backtrack_rules = [];

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
    ;;; create a list and print it out
    [%
    	'THE WORLD',
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

define :rule start;

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

define :rule complete_move in solve_rules
        [complete_move ?move][->>Cond1]
        [state ?state][->>Cond2]
    ;
    [DEL ?Cond1 ]
    ;;; Extend the history - used for checking circularity
    [PUSH [?move ?state] history]
    ;;; Extend the plan
    [PUSH ?move plan]
    ;;; Create up to date state record (in canonical form)
    [MODIFY ?Cond2 state [apply thing_data]]
    ;;; record that this move has been tried in this state
    [tried ?move ?state]
    ;;; report move
    [SAY Trying ?move]
    ;;; print result
    [POP11 display_data()]

    ;;; Next line is simply to pause till user presses RETURN key
    [PAUSE]

    [RESTORE RULES check_rules]
enddefine;


;;; The next rule checks whether the problem has been solved, and
;;; if so aborts the program. The goal description is stored in
;;; the database, to make it easy to change, instead of always using the
;;; same goal.

define :rule done in solve_rules
         [goal ?goallist]
         [ALL ?goallist]    ;;; As if the conditions were in this rule.
         [plan ??plan]
         ;
    [SAY 'Goal state achieved']
    [POP11 display_data()]
    [SAY 'THE SUCCESSFUL PLAN WAS']
    [SAY [apply rev ?plan]]
    [PAUSE]
    [STOP 'Everything successfully moved over']
enddefine;


;;; On failure this rule is triggered to back-track by restoring a
;;; previous state, and re-displaying it.

define :rule undo in backtrack_rules
         [history [?move ?oldstate] ??history]
         [state =]
         ;
    [SAY undoing ?move]
    [MODIFY 2 state ?oldstate]
    [NOT = isat = ]
    [POP history]       ;;; Remove latest addition to history
    [POP plan ]         ;;;   ... and to plan
    [ADDALL ??oldstate] ;;; Restore the previous [... isat ...] items
    [POP11 display_data()]
    [SAY 'Restored previous state']
    [PAUSE]
    [RESTORE RULES solve_rules]
enddefine;


;;; The next rule checks that an attempted move is legal, and if
;;; not causes back-tracking, by restoring a previous state,
;;; and re-displaying it. Legality is determined by constraints
;;; in the constraints database.

define :rule check_constraints in check_rules
         [constraint ?name ?checks ?message]
         [ALL ?checks]  ;;; ( [WHERE [apply prb_allpresent ?checks]] )
         ;
    [SAY Constraint ?name violated]
    [SAY ??message]
    [RESTORE RULES backtrack_rules]
enddefine;

define :rule checks_ok in check_rules
    ;;; If no constraint violations were detected by previous rules,
    ;;; restore normal rules to continue searching for a solution.
         ;
    [RESTORE RULES solve_rules]
enddefine;


;;; Now the move operators. Because prb_allrules is set
;;; FALSE, only one will be fired on each cycle. (Note the use of
;;; the word quotes in the "WHERE" condition.)

global vars thing;

define :rule move_thing in solve_rules
         [man isat ?place]
         [?thing isat ?place]
         [WHERE thing /== "man"]
         [OR [opposite ?place ?other][opposite ?other ?place]]
         [state ?state]
         [NOT tried [move ?thing] ?state]
         [NOT history [[move ?thing] =] ==] ;;; not last thing moved
         ;
    [MODIFY 2 isat ?other]
    [MODIFY 1 isat ?other]
    [complete_move [move ?thing]]
enddefine;

define :rule move_man in solve_rules
         [man isat ?place][->> Cond1]
         [OR [opposite ?place ?other][opposite ?other ?place]]
         [state ?state]
         [NOT tried [move man] ?state]
         [NOT history [move man] ==]    ;;; man not last thing moved
    ;
    [MODIFY ?Cond1 isat ?other]
    [complete_move [move man]]
enddefine;

;;; This must be the second last rule.
;;; When there's nothing else left to try, try to undo last move

define :rule goback in solve_rules [history = ==];
    [SAY 'no more options - retracing']
    [RESTORE RULES backtrack_rules]
enddefine;

;;; This must be the last rule.
;;; When you cannot even undo, just fail

define :rule failed in solve_rules [history ];
    [STOP 'No more options - FAILED']
enddefine;

;;; Uncomment the following for selective tracing of rules
;;;prb_trace([goback complete_move undo done]);
