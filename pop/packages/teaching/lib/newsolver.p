/* --- Copyright University of Birmingham 2001. All rights reserved. ------
 > File:            $poplocal/local/lib/newsolver.p
 > Purpose:         Update Steve Hardy's LIB * SOLVER
 > Author:          Aaron Sloman, Oct 29 1995 (see revisions)
 > Documentation:   TEACH * NEWSOLVER
 > Related Files:   LIB * SOLVER
 */

/*
;;; Based on the original LIB * SOLVER by Steve Hardy, circa 1978?
 >  File:           C.all/lib/lib/solver.p
 >  Documentation:  TEACH * SOLVER

NOTE: there is an index at the end. To use it, do
		ENTER g define
 */

section;


/*
define : GLOBAL VARIABLES CONTROLLING THE BEHAVIOUR
*/

global vars
    picture_file = 'tree.p',    ;;; The VED graphical trace file
    save_picture_file = true,   ;;; If false,make the file non-writeable
    check_all = true,           ;;; If true, check database and operators
    clever_solve = false,       ;;; If true, do extra checks in runstrips
    lookahead = 2,              ;;; Controls effort to estimate costs
    noclobber = false,          ;;; If true, check for subgoal-clobbering
    noloops = false,            ;;; If true check for looping
    operators = [],             ;;; The list of operators available
    searchlimit = 10000,        ;;; Used as a last resort to control
                                ;;; the search. It is compared with treenumber

    ;;; Some variables to control "trace" information
    pausing = true,             ;;; If true, pause repeatedly
    draw_solving = true,        ;;; If true, do tracing in the VED window
	no_show_plan = false,   	;;; If false use showplan at end
;

;;; Global, but restricted access, variables (file-local lexicals).

lvars
    wasdrawing = false,      ;;; used to control restoration of draw_solving.
    estimating = false,     ;;; used in runastar
    lastgoals = [[NO LAST GOALS]],  ;;; Initial value. Does nothing.
;

/*
define : DEFAULT BLOCKSWORLD DOMAIN
*/

vars X, Y;  ;;; Matcher variables used in default operators

define blocksworld();
    ;;; Running this procedure gives a default set of operators and
    ;;; a default database, for blocks world planning.

    [
        [[take ?X off table]
            [[emptyhand] [cleartop ?X] [ontable ?X]]
            [[emptyhand] [ontable ?X]]
            [[holding ?X]]]
        [[place ?X on table]
            [[holding ?X]]
            [[holding ?X]]
            [[ontable ?X] [emptyhand]]]
        [[pick up ?X from ?Y]
            [[emptyhand] [?X on ?Y] [cleartop ?X]]
            [[emptyhand] [?X on ?Y]]
            [[holding ?X] [cleartop ?Y]]]
        [[put ?X on ?Y]
            [[holding ?X] [cleartop ?Y]]
            [[holding ?X] [cleartop ?Y]]
            [[emptyhand] [?X on ?Y]]]
        ] -> operators;
    ;;;
    [[ontable b1]
        [b2 on b1] [cleartop b2]
        [holding b3] [cleartop b3]
        [ontable b4] [cleartop b4]
        [ontable b5] [cleartop b5]
        ] -> database;
enddefine;

global vars procedure (getvars, pattern_instance);  ;;; defined below.

define checkdomain(data,  operators);
    ;;; This procedure can be applied to the database and operator list
    ;;; to check that they are in an appropriate format

    lvars
        data, operators,
        bound, datum, variable, variables, op;

    unless check_all then return endunless;

    unless islist(operators) then
        mishap('THE VALUE OF OPERATORLIST IS NOT A LIST', [%operators%])
    endunless;

    for op in operators do

        unless islist(op) then
            mishap('NON LIST POSING AS A OPERATOR', [%op%])
        endunless;

        unless listlength(op) == 4 then
            mishap('OPERATOR HAS MORE THAN FOR ELEMENTS',
                        [%'THE OPERATOR NAMED', op(1)%])
        endunless;

        for datum in op do
            unless islist(datum) then
                    mishap('ONE ELEMENT OF A OPERATOR IS NOT A LIST',
                        [%datum, 'IN THE OPERATOR NAMED', op(1)%])
            endunless
        endfor;

        for datum in op(2) <> op(3) <> op(4) do
            unless islist(datum) then
                mishap('ONE ELEMENT OF A OPERATOR ELEMENT IS NOT A LIST',
                        [%datum, 'IN THE OPERATOR NAMED', op(1)%])
            endunless
        endfor;

        getvars(op(1)) -> variables;

        getvars(op(2)) -> bound;
        for variable in bound do
            unless member(variable, variables) then
                mishap('VARIABLE NOT MENTIONED IN NAME OF OPERATOR',
                            [%variable, 'IN OPERATOR NAMED', op(1)%])
            endunless
        endfor;

        bound -> variables;

        getvars(op(3)) <> bound -> bound;
        getvars(op(4)) <> bound -> bound;
        for variable in bound do
            unless member(variable, variables) then
                mishap('VARIABLE NOT MENTIONED IN PRECONDITIONS OF OPERATOR',
                            [%variable, 'IN OPERATOR NAMED', op(1)%])
            endunless
        endfor;
        for datum in op(3) do
            unless member(datum, op(2)) do
                mishap('OPERATOR MIGHT REMOVE ITEM BUT IT IS NOT A PRECONDITION',
                            [%datum, 'IN THE OPERATOR NAMED', op(1)%])
            endunless
        endfor;
    endfor;
    for op on operators do
        for datum on tl(op) do
            if pattern_instance(hd(hd(op))) matches hd(hd(datum)) then
                mishap('TWO OPERATORs HAVE MATCHING NAMES',
                    [%'THE OPERATOR NAMED', hd(hd(op)),
                            'AND THE OPERATOR NAMED', hd(hd(datum))%])
            endif
        endfor
    endfor;

    unless islist(database) then
        mishap('THE VALUE OF DATABASE IS NOT A LIST', [%database%])
    endunless;

    for datum in database do
        unless islist(datum) then
            mishap('ONE ELEMENT OF DATABASE IS NOT A LIST', [%datum%])
        endunless;
        getvars(datum) -> bound;
        unless bound == [] then
            mishap('ONE ELEMENT OF DATABASE CONTAINS VARIABLES', [%datum%]);
        endunless;
    endfor;
enddefine;



/*
define : UTILITY PROCEDURES

define : DRAWING TREES IN VED AND PAUSING
*/

define PAUSE();
    lvars char;
    if pausing then
        vedscr_flush_output();
        vedinascii() -> char;
        if char == `c` or char == `C` then
            ;;; stop pausing, and drawing i.e. just continue
            false -> pausing; false -> draw_solving;
        elseif char == `p` or char == `P` then
            ;;; valof("popready")();
            vedselect('output.p');
            vedendfile();
            vedsetpop();
        endif;
    endif;
enddefine;


define ved_cont();
    ;;; do "ENTER cont" to finish a break entered in PAUSE
    ved_end_im();
enddefine;

define lconstant islinegraphic(c);
    lvars c;
    `\Gle` <= c and c <= `\G+`
enddefine;

define sameline(s1, n1, s2, n2) -> boole;
    lvars s1, n1, s2, n2, boole;
    lvars n, c1, c2;

    for n from 1 to min(n1, n2) do
        subscrs(n, s1) -> c1;
        subscrs(n, s2) -> c2;
        unless c1 == c2 or islinegraphic(c1) or islinegraphic(c2) or c1 == ` `
            or c2 == ` ` or c1 + `a` == c2 + `A` or c1 + `A` == c2 + `a`
        then
            return(false -> boole)
        endunless
    endfor;
    true -> boole;
enddefine;


define pr_upper(x);
    ;;; print in upper case
    lvars x,
        procedure output = cucharout;

    define dlocal cucharout(c);
        lvars c;
        output(lowertoupper(c))
    enddefine;

    pr(x)
enddefine;



;;; this property keeps track of which goals are current
lvars activeprops = newproperty([], 64, false, "tmparg");

define isactivetree(tree) -> boole;
    ;;; Used for drawing and other purposes
    ;;; Recursive check that a tree is active.
	;;; I.e. it contains a subtree in activeprops
    lvars tree, boole;
    if activeprops(tree) then
        true -> boole
    else
        until atom(tree) do
            if isactivetree(destpair(tree) -> tree) then
                return(true -> boole)
            endif
        enduntil;
        false -> boole;
    endif
enddefine;


define display(indent, tree);
    ;;; subroutine for pshowtree

    lvars indent, tree, item, x;

    lvars procedure do_print = pr;

    if isactivetree(tree) then pr_upper -> do_print endif;

    unless draw_solving then
        return()
    endunless;

    destpair(tree) -> (x, tree);
    if islist(x) then
        for item in x do do_print(item); pr(space); endfor;
    else
        do_print(x); pr(space);
    endif;
    if x == "achieve" then
        for x in destpair(tree) -> tree do do_print(x); pr(space) endfor
    else
        do_print(destpair(tree) -> tree)
    endif;
    if tree == [] then return endif;
    destpair(tree) ->(x, tree);
    until tree == [] do
        pr(indent);
        cucharout(`\Glt`);
        cucharout(`\G-`);
        cucharout(` `);
        display(indent >< consstring(`\G|`, ` `, ` `, 3), x);
        destpair(tree) ->(x, tree);
    enduntil;
    pr(indent);
    cucharout(`\Gbl`);
    cucharout(`\G-`);
    cucharout(` `);
    display(indent >< '   ', x);
enddefine;

define pshowtree(treenumber, tree);
    ;;; Draw a planning tree using VED's graphic characters. But do
    ;;;     nothing if drawing is false.
    ;;; Does not use treenumber at present. Can be used for
    ;;;     debugging.

    lvars treenumber, tree;

    dlvars index;       ;;; Not lvars because used in cucharout

    lconstant text = inits(512);    ;;; a string buffer to print into

    unless draw_solving then return() endunless;

    define dlocal cucharout (c);
        ;;; Change current character consumer for printing
        lvars c, char;
        if c == `\n` then
            ;;; insert new line
            vedsetlinesize();
            unless vedline <= vvedbuffersize
			and sameline(text, index, vedbuffer(vedline), vvedlinesize)
			then
                if vedline >= vedlineoffset + vedwindowlength then
                    vedcheck()
                endif;
                vedlineabove()
            endunless;
            lvars n;
            for n from 1 to index do
                if (subscrs(n,text) ->> char) == vedcurrentchar() then
                    vedcharright()
                else
                    vedcheck(); char -> vedcurrentchar();
                    vedcharright(); ;;; kluge for vt100
                endif
            endfor;
            vednextline();
            ;;; check whether to expand window size
            if vedusewindows /== "x"                    ;;; not in XVED
                and vedline > vedwindowlength           ;;; window too short
                and vedwindowlength < vedscreenlength   ;;; could be expanded
            then
                vedsetwindow()                          ;;; expand it
            endif;
            0 -> index;
            vedscr_flush_output();
        else
            index + 1 -> index;
            c -> subscrs(index, text);
        endif
    enddefine;

    vedselect(picture_file);
    save_picture_file -> vedwriteable;  ;;; if false will not save the file

    false -> vedbreak;
    nullstring -> vedcommand;
    vedputmessage('Press RETURN to continue, "c" to stop pausing');
    vedscr_flush_output();
    0 -> index;
    vedjumpto(1, 1);
    display('\n  ', tree);
    pr(newline);
    until vedatend() do vedlinedelete() enduntil;
    vedscr_flush_output();
    PAUSE();
enddefine;

define ved_printify();
    ;;; transform graphic characters to printing characters
    ;;; lconstant trans = '---|\\/-|/\\-|||+o#.___________';
    lconstant trans = '---|**-|**-|||+o#.___________';

    vedpositionpush();
    vedputmessage('PLEASE WAIT');
    vedjumpto(1,1);
    lvars char, c;
    repeat
        if vedcolumn > vvedlinesize then vednextline(); endif;
        if vedatend() then vedpositionpop(); quitloop(); endif;
        vedcurrentchar() -> char;
        if islinegraphic(char) then
            subscrs(char-16:80, trans) -> c;
            if c /== `_` then c -> vedcurrentchar() endif;
        endif;
        vedcharright();
    endrepeat;
    vedputmessage('DONE');
enddefine;


define showplan(plan);
    ;;; Display the plan in the picture file if drawing is true,
    ;;; otherwise in the normal output file.
    lvars plan, planstep;
	if no_show_plan then
		return();
    elseif draw_solving then
        define dlocal cucharout(c);
            lvars c;
            vedcheck();
            if c == `\n` then
                vednextline();
            else
                vedcharinsert(c);
            endif;
        enddefine;
        vedselect(picture_file);
    else
        vedselect('output.p');
    endif;
    vedendfile();
    pr('\nCOMPLETE PLAN IS:\n');
    for planstep in plan do
        pr('\t'); pr(planstep); pr('\n');
    endfor;
enddefine;

define report(message);
    unless draw_solving then
        return()
    endunless;

    vedscreenbell();
    vedputmessage('$$$ ' >< message >< ' $$$');
    PAUSE();
enddefine;


/*
define : GENERAL UTILITIES
*/

define prune(list);
    if list = [] then
        []
    elseif member(hd(list), tl(list)) then
        prune(tl(list))
    else
        hd(list) :: prune(tl(list))
    endif
enddefine;



/*
define : UTILITIES CONCERNED WITH OPERATORS
*/



;;; pattern_instance takes a pattern with ? or ?? and instantiates ALL the variables
;;; in a copy of the pattern. Used in FOREVERY, etc.


define pattern_instance(Pattern);
	lvars item, undefaction, Pattern;
	if Pattern.isprocedure then
		Pattern -> undefaction;
		-> Pattern
	else
		false -> undefaction;
	endif;

	[%  until null(Pattern) do
			fast_destpair(Pattern) -> (item, Pattern);
			if item = "?" then
				destpair(Pattern) ->(item, Pattern);
				if undefaction
				and (identprops(item) == undef or isundef(valof(item))) then
					undefaction("?", item)
				else
					valof(item);
				endif;
chop:
				if ispair(Pattern) and fast_front(Pattern) == ":" then
					back(fast_back(Pattern)) -> Pattern
				endif
			elseif item == "??" then
				destpair(Pattern) -> (item, Pattern);
				if undefaction
				and (identprops(item) == undef or not(item.valof.ispair)) then
					undefaction("??", item)
				else
					dl(valof(item));
				endif;
				goto chop
			elseif atom(item) then
				item
			elseif undefaction then
				pattern_instance(item, undefaction)
			else
				pattern_instance(item)
			endif
		enduntil %]
enddefine;


/*
define : FINDING VARIABLES TO BE BOUND
*/

define lconstant get_sub_binding(binding);
    ;;; Recursive utility procedure called by getvars
    ;;; Puts all variables after "?" or "??" on stack
    lvars item, binding;
    until atom(binding) do
        front(binding) -> item;
        if item == "?" or item == "??" then
            back(binding) -> binding;
            front(binding);     ;;; leave next item on stack
        else
            get_sub_binding(item)
        endif;
        back(binding) -> binding;
    enduntil;
enddefine;

define getvars(binding) -> bound;
    ;;; find all the variables to be bound
    lvars binding, bound;
    [% get_sub_binding(binding) %] -> bound;

enddefine;


define instantiated(pattern) -> boole;
    lvars pattern, boole = true, item;
    if islist(pattern) then
        for item in pattern do
            if item == "?" or item == "??" then
                return(false -> boole)
            elseunless instantiated(item) then
                return(false -> boole)
            endif;
            back(pattern) -> pattern;
        endfor
    endif;
    true -> boole
enddefine;


define partinstantiate(binding, pattern) -> partinstance;
    ;;; Partialy instantiate the pattern, using the variables in binding
    lvars binding, pattern, partinstance;
    lvars bound;

    define sub_partial(pattern);
        if atom(pattern) then
            pattern
        elseif front(pattern) == "?" then
            back(pattern) -> pattern;
            if lmember(front(pattern), bound) then
                valof(front(pattern)) :: sub_partial(back(pattern))
            else
                "?" :: sub_partial(pattern)
            endif
        elseif front(pattern) == "??" then
            back(pattern) -> pattern;
            if lmember(front(pattern), bound) then
                valof(front(pattern)) <> sub_partial(back(pattern))
            else
                "??" :: sub_partial(pattern)
            endif
        else
            sub_partial(front(pattern))
                :: sub_partial(back(pattern))
        endif
    enddefine;
    getvars(binding) -> bound;
    sub_partial(pattern) -> partinstance
enddefine;

define bindings_unique(inst, pattern) -> boole;
    ;;; do two variables get matched to the same object?
    lvars inst, pattern, vals;
    dlocal popmatchvars = [];

    sysmatch(pattern, inst) ->;

    maplist(popmatchvars, valof) -> vals;

    until vals == [] do
        if member(destpair(vals) ->> vals) then return(false -> boole) endif;
    enduntil;

    true -> boole;
enddefine;


/*
define : GETTING THE SUBLISTS OF OPERATORS
*/

define op_name(operator) -> list ;
    front(operator) -> list;
enddefine;

define op_preconditions(operator) -> list;
    front(back(operator)) -> list;
enddefine;

define op_deletes(operator) -> list;
    front(back(back(operator))) -> list;
enddefine;

define op_adds(operator) -> list;
    front(back(back(back(operator)))) -> list;
enddefine;

define adds_and_deletes(operator) -> (adds, deletes);
	lvars list;
    back(back(operator)) -> list;

    front(list) -> deletes;
    front(back(list)) -> adds;
enddefine;

/*
define : COMPONENTS OF PLANNING TREES

Typically a planning tree will be a list containing

1. A word, which is one of "achieve" or "reduce" or "perform"
    This is accessed by tree_type

2. A list of goals.
    This is accessed by tree_goals

3. Other planning subtrees (possibly none).
    This is accessed by tree_plan

e.g.
    [achieve [[...][...]] [...] [...] [...]]
*/


define tree_type(tree);
    lvars tree;
    front(tree);
enddefine;

define tree_goals(tree);
    lvars tree;
    front(fast_back(tree));
enddefine;

define tree_plan(tree);
    lvars tree;
    fast_back(fast_back(tree))
enddefine;


/*
define : FINDING RELEVANT OPERATORS AND CHECKING PLANS
*/

define get_operator(action, operators) -> operator;
    ;;; Find the first operator in operators that can perform the action

    lvars action, operators, operator;
    for operator in operators do
        if action matches front(operator) then
            return()
        endif
    endfor;

    mishap('MISSING OPERATOR', [%action%])
enddefine;


define perform(plan, operators);
    ;;; Perform all the actions in the plan
    ;;; uses database non-locally
    lvars plan, operators;

    lvars action, adds, deletes;
    for action in plan do
        adds_and_deletes(get_operator(action, operators)) -> (adds, deletes);
        ;;; apply delete lists
        allremove(pattern_instance(deletes));
        ;;; apply add lists
        alladd(pattern_instance(adds));
    endfor;
enddefine;

define achieves(plan, goals) -> boole;
    ;;; check that the plan achieves all the goals, in the current database
    lvars plan, goals, boole, planstep;
    dlocal database;
    perform(plan, operators);
    allpresent(goals) -> boole;
enddefine;

define insert(plan, others) -> plan;
    ;;; Plan has a number or a procedure which produces a number
    ;;; as its front. So has each item in others.
    ;;; Use the number to determine where the plan should be inserted
    ;;; in others.
    lvars plan, others, val1, val2;

    if others == [] then
        plan :: others -> plan
    elseif back(plan) = back(front(others)) then
        ;;; The new plan duplicates an existing step. Use others
        others -> plan
    else
        if isprocedure(front(plan) ->> val1) then
            ;;; Evaluate it. That should produce a number
            val1() ->> front(plan) -> val1;
        endif;
        if isprocedure(front(front(others)) ->> val2) then
            ;;; Do the same for the first plan step in others
            val2() ->> front(front(others)) -> val2;
        endif;
        ;;; Now compare the new plan with the first element in others
        if val1 < val2 then
            plan :: others
        else
            front(others) :: insert(plan, back(others))
        endif -> plan
    endif
enddefine;


define same_state(state1, state2) -> boole;
    ;;; Do the two states constitute equivalent databases?
    lvars state1, state2, boole, fact;
    for fact in state1 do
        unless member(fact, state2) then
            return(false -> boole);
        endunless
    endfor;
    for fact in state2 do
        unless member(fact, state1) then
            return(false -> boole);
        endunless
    endfor;
    true -> boole;
enddefine;

define leadstoaloop(plan, operators) -> boole;
    lvars plan, operators, boole;

    lvars
        action, fact, oldstate, adds, deletes,
        history = [];

    dlocal database;

    for action in plan do
        database :: history -> history;
        adds_and_deletes(get_operator(action, operators))-> (adds, deletes);
        ;;; the delete list
        allremove(pattern_instance(deletes));
        ;;; the addlist
        alladd(pattern_instance(adds));
    endfor;

    for oldstate in history do
        if same_state(oldstate, database) then
            return(true -> boole);
        endif;
    endfor;
    false -> boole;
enddefine;


define clobbers(tree) -> boole;
    ;;; Check if the delete list of one action undoes
    ;;; something achieved in another
    lvars tree, boole;
    lvars subtree, goals, subgoal;
    if tree_type(tree) == "achieve" then
        [] -> goals;
        for subtree in tree_plan(tree) do
            if member((tree_type(subtree) ->> subgoal), goals) then
                return(true -> boole)
            else
                conspair(subgoal, goals) -> goals
            endif
        endfor
    endif;
    for subtree in tree_plan(tree) do
        if clobbers(subtree) then return(true -> boole) endif
    endfor;
    false -> boole
enddefine;


define plan_recurses(tree) -> boole;
    ;;; Check for recursion in a planning tree
    lvars tree, boole;

    define lconstant sub_recurses(commands, tree) -> boole;
        ;;; Recursively check whether the tree has a goal that is a
        ;;; subgoal of itself
        lvars commands, tree, boole;
        lvars subtree;
        if front(tree) == "reduce" then
            if member(tree_goals(tree), commands) then
                return(true -> boole)
            else
                tree_goals(tree) :: commands -> commands
            endif;
        endif;
        for subtree in tree_plan(tree) do
            if sub_recurses(commands, subtree) then return(true -> boole) endif
        endfor;
        return(false -> boole);
    enddefine;

    sub_recurses([], tree) -> boole;
enddefine;


/*
define : UTILITIES FOR ESTIMATING PLAN COSTS
*/

;;; Procedures defined below
global vars procedure (estimate, howdo);

lvars actions;  ;;; used nonlocally

define howdoscan(action, goals, op, operators);
    lvars action, goals, op, operators;
    if instantiated(action) then
        if bindings_unique(action, front(op)) then
            insert(
                estimate(%
                    [],
                    pattern_instance(op_preconditions(get_operator(action, operators))),
                    operators%) :: action,
                actions)
                -> actions;
            if estimating then
                if front(front(actions)) == 0 then
                    exitfrom([%back(front(actions))%], howdo)
                endif;
                actions -> action;
                until atom(action) or atom(back(action)) do
                    if isprocedure(front(back(action))) then
                        back(back(action)) -> back(action)
                    endif;
                    back(action) -> action;
                enduntil;
            endif;
        endif;
    elseunless goals == [] then
        unless instantiated(front(goals)) then
            foreach front(goals) do
                howdoscan(
                    partinstantiate(front(goals), action),
                    partinstantiate(front(goals), back(goals)),
                    op,
                    operators),
            endforeach
        endunless;
        howdoscan(action, back(goals), op, operators);
    endif
enddefine;

define howdo(plan, goal, operators) -> actions;
    ;;; actions used non-locally by howdoscan
    lvars plan, goal, operators, op, effect;
    dlocal database, actions;
    perform(plan, operators);
    [] -> actions;
    for op in operators do
        for effect in op_adds(op) do
            if goal matches effect then
                howdoscan(
                    partinstantiate(effect, op_name(op)),
                    partinstantiate(effect, op_preconditions(op)),
                    op,
                    operators)
            endif;
        endfor;
    endfor;
    maplist(actions, back) -> actions;
enddefine;

define estimate(plan, goals, operators) -> result;
    ;;; Estimate the cost of doing something
    lvars plan, goals, operators, result;

    lvars
        actions, goal, newgoal, newgoals, preconds,
        considered = goals;

    dlocal database, lookahead, estimating = true;

    perform(plan, operators);

    0 -> result;

    until lookahead == 0 do
        lookahead - 1 -> lookahead;
        [] -> newgoals;
        for goal in goals do
            unless present(goal) then
                result + 1 -> result;
                howdo([], goal, operators) -> actions;

                ;;; If failed, then use very high cost
                if actions == [] then 100000 -> result; return endif;

                pattern_instance(
                    op_preconditions(get_operator(front(actions), operators)))
                        -> preconds;

                for newgoal in preconds do
                    unless member(newgoal, considered) then
                        newgoal :: considered -> considered;
                        newgoal :: newgoals -> newgoals
                    endunless
                endfor

            endunless
        endfor;
        newgoals -> goals
    enduntil;

    ;;; compute cost of unachieved goals
    for goal in goals do
        unless present(goal) then
            result + 1 -> result;
        endunless
    endfor
enddefine;


/*
define : PROCEDURES FOR TESTING FEASIBILITY OF PLANS
*/

define cando(plan, database, operators);
    lvars plan, operators, op, action;

    dlocal database;

    perform(plan, operators);

    prune([%for op in operators do
        ;;; see if preconditions are satisifed
        forevery op_preconditions(op) do
            pattern_instance(op_name(op)) -> action;
            if bindings_unique(action, op_name(op)) then action endif;
        endforevery
      endfor%])
enddefine;

define differences(plan, goals) -> tasks;
    lvars plan, goals, tasks, goal;
    dlocal database;
    perform(plan, operators);
    [] -> tasks;
    for goal in goals do
        unless present(goal) then
            insert(estimate(%[], [^goal], operators%) :: goal, tasks) -> tasks
        endunless
    endfor;
    rev(maplist(tasks, back)) -> tasks;
enddefine;

/*
define : PROCEDURES REQUIRED FOR RUNSTRIPS
*/


define strips_raise(tree);
    ;;; Raise the active point in the tree
    lvars tree;

    lvars done;     ;;; used non-locally in sub_raise

    define lconstant sub_raise(tree);
        lvars tree, active_found;
        lvars subtree;
        ;;;        unless isactivetree(tree) then return() endunless;
        false -> active_found;
        for subtree in tree_plan(tree) do
            if done then
                ;;; don't recurse,
            elseif activeprops(subtree) then
                true -> active_found;
                false -> activeprops(subtree);
                true -> done;
                quitloop();
            else
                sub_raise(subtree);
            endif
        endfor;
        ;;; found active node one level down, make this one active
        if active_found then
            true -> activeprops(tree);
        endif
    enddefine;


    if activeprops(tree) then
        false -> activeprops(tree)
    else
        false -> done;
        sub_raise(tree)
    endif;
enddefine;

define strips_splice(tree, node) -> tree;
    ;;; Rebuild the tree inserting the new node after the first node
    ;;; making the new node active
    lvars tree, node;
    lvars
        subtree,
        done;   ;;; used non-locally in subsplice


    define lconstant subsplice(tree, node) -> tree;
        lvars tree, node, subtree;
        if isactivetree(tree) then
            if activeprops(tree) then
                ;;; Found it, Append the node to this tree and return.
                true -> done;
                false -> activeprops(tree);
                tree <> node -> tree;
            else
                ;;; rebuild tree down to active node
                [%tree_type(tree), tree_goals(tree),
                    for subtree in tree_plan(tree) do
                        if done then subtree else subsplice(subtree, node) endif
                    endfor%] -> tree;
            endif
        endif
    enddefine;

    false -> done;
    subsplice(tree, node) -> tree;
enddefine;

define strips_expand(current, plan, tree);
    ;;; Leave new nodes on stack
    lvars current, plan, tree, action, actions, subgoal, goals, newtree;

    if tree_type(current) == "achieve" then
        tree_goals(current) -> goals;
        if achieves(plan, goals) then
            strips_raise(tree);
            tree
        else
            for subgoal in differences(plan, goals) do
                [reduce ^subgoal] -> newtree;
                true -> activeprops(newtree);
                strips_splice(tree, [^newtree]);
            endfor
        endif
    elseif tree_type(current) == "reduce" and tree_plan(current) == [] then
        howdo(plan, tree_goals(current), operators ) -> actions;
        if actions == [] then
            report('CANNOT REDUCE ' >< tree_goals(current));
        else
            for action in actions do
                pattern_instance(op_preconditions(get_operator(action, operators))) -> goals;
                if achieves(plan, goals) then
                    [perform ^action] -> newtree;
                    true -> activeprops(newtree);
                    ;;; raise active point twice, after splicing
                    strips_splice(tree, [^newtree]) -> newtree;
                    strips_raise(newtree);
                    strips_raise(newtree);
                    newtree;
                else
                    [achieve ^goals] -> newtree;
                    true -> activeprops(newtree);
                    strips_splice(tree, [^newtree [perform ^action]]);
                endif;
            endfor
        endif
    else
        strips_raise(tree);
        tree
    endif
enddefine;


define expand_state(plan_tree, plan) -> (plan_tree, plan, current);
    ;;; current starts off false
    lvars plan_tree, plan, current = false;

    define lconstant splitup(plan_tree);
        ;;; uses plan non-locally
        lvars plan_tree;
        if activeprops(plan_tree) then

            applist(tree_plan(plan_tree), splitup);
            plan_tree -> current;    ;;; the current goal

        elseif tree_type(plan_tree) == "perform" then
            tree_goals(plan_tree) :: plan -> plan;
        else
            lvars subtree;
            for subtree in tree_plan(plan_tree) do
                quitif(current);
                splitup(subtree)
            endfor
        endif
    enddefine;
    splitup(plan_tree);
enddefine;

define runstrips(goals, database, operators) -> plan;
    lvars goals, operators, plan;

    lvars current, plan_tree, treenumber, states_to_explore;

    dlocal
        draw_solving, pausing,
        database,
        vedautowrite = false,
        vednotabs = true;

    ;;; Reuse previous goals if none specified
    unless goals then lastgoals -> goals endunless;
    ;;; Save goals for next time.
    goals -> lastgoals;

    ;;; See if database and operators are OK
    checkdomain(database, operators);

    [[achieve ^goals]] -> states_to_explore;
    true -> activeprops(front(states_to_explore));

    0 -> treenumber;	;;; used as a search limiter, and possibly for tracing

    repeat
        if states_to_explore == [] then
            report('COULD NOT ACHIEVE GOALS');
            return(false -> plan);
        endif;

        destpair(states_to_explore) -> (plan_tree, states_to_explore);
        [] -> plan;

        expand_state(plan_tree, plan) -> (plan_tree, plan, current);
        rev(plan) -> plan;

        treenumber + 1 -> treenumber;
        if plan_tree /== current then
            false -> activeprops(plan_tree);
        endif;

        pshowtree(treenumber, plan_tree);

        unless current then
            report('GOALS ACHIEVED');
            unless draw_solving then
                if wasdrawing then
                    ;;; Now draw the final search plan_tree
                    true -> draw_solving;
                    pshowtree(treenumber, plan_tree);
                endif
            endunless;
            showplan(plan);
            return();
        endunless;
        if treenumber > searchlimit then
            ;;; plan_tree ==>
            'SEARCHLIMIT EXCEEDED - FAILED' =>
            return();
        endif;

		;;; Some checks that involve optional heuristics
        if (clever_solve or noloops) and leadstoaloop(plan, operators) then
            report('SUBPLAN ABANDONED BECAUSE IT LEADS TO LOOP');
        elseif plan_recurses(plan_tree) then
            report('SUBPLAN ABANDONED BECAUSE OF RECURSIVE GOALS');
        elseif (clever_solve or noclobber) and clobbers(plan_tree) then
            report('SUBPLAN ABANDONED BECAUSE IT CLOBBERS A HIGHER GOAL');
        else
            [%strips_expand(current, plan, plan_tree)%] <> states_to_explore
				-> states_to_explore;
            false -> activeprops(current);
        endif;
    endrepeat;
    false -> plan;
enddefine;



/*
define : UTILITIES FOR ASTAR ALGORITHM
*/

define astarplan(tree);
    lvars tree, subtree;
    if activeprops(tree) then
        [%tree_type(tree)%]
    else
        for subtree in tree_plan(tree) do
            if isactivetree(subtree) then
                return(tree_type(tree) :: astarplan(subtree))
            endif
        endfor
    endif
enddefine;




define lconstant goal_cost(tree);
    front(back(tree));
enddefine;


define astar_expand(tree, current) -> current;
    lvars tree, current;

    define astarsplit(tree);
        ;;; Look for goal with lowest cost, and make it current

        lvars tree, plan = tree_plan(tree);
        if plan == [] then
            if goal_cost(tree) < goal_cost(current) then
                tree -> current
            endif
        else
            applist(plan, astarsplit)
        endif
    enddefine;

    astarsplit(tree);
enddefine;



define runastar(goals, database, operators) -> plan;
    ;;; Run the A* forward chaining (branch and bound) algorithm.
    lvars goals, operators, plan;

    dlocal
        database,
        draw_solving, pausing,
        vedautowrite = false,
        vednotabs = true;

    ;;; Reuse previous goals if none specified
    unless goals then lastgoals -> goals endunless;
    ;;; Save goals for next time.
    goals -> lastgoals;

    checkdomain(database, operators);

    lvars
        best, newplan, newtree, option,
        current, tree, treenumber, plan;

    lvars size = stacklength();

    ;;; set up initial state, including initial estimate
    [%goals, estimate([], goals, operators)%] -> tree;

    0 -> treenumber;	;;; used as a search limiter, and possibly for tracing

    ;;; Include a dummy goal with a very high cost
    lconstant dummy_goal = [foo 1000000];

    repeat
        astar_expand(tree, dummy_goal) -> current;
        if current == dummy_goal then
            report('FAILED TO ACHIEVE GOALS');
            return(false -> plan);
        endif;
        ;;; record current
        true -> activeprops(current);
        back(astarplan(tree)) -> plan;
        treenumber + 1 -> treenumber;
        if achieves(plan, goals) then
            unless stacklength() == size then
                mishap('STACK ERROR', [1])
            endunless;
            if wasdrawing then
                true -> draw_solving;
                pshowtree(treenumber, tree);
            endif;
            unless stacklength() == size then
                mishap('STACK ERROR', [2])
            endunless;

            report('GOALS ACHIEVED');

            ;;; add([plan ^plan]);              ;;; ***
            unless stacklength() == size then
                mishap('STACK ERROR', [3])
            endunless;

            showplan(plan);

            unless stacklength() == size then
                mishap('STACK ERROR', [4])
            endunless;
            return();
        endif;
        if treenumber > searchlimit then
            'SEARCHLIMIT EXCEEDED - FAILED' =>
            return();
        endif;
        ;;; consider ways of extending plan
        [%for option in cando(plan, database, operators) do
                plan <> [%option%] -> newplan;
                unless leadstoaloop(newplan, operators) then
                    [%option, estimate(newplan, goals, operators) + length(newplan)%]
                endunless
            endfor
        %] -> newtree;
        newtree -> back(back(current));
        100000 * current(2) + treenumber -> current(2);
        pshowtree(treenumber, tree);

        ;;; Make sure old current goal is no longer assumed current
        false -> activeprops(current);

    endrepeat;
    false -> plan;
enddefine;


/*
define : PROCEDURES FOR RUNNING THE SOLVERS
*/

define runinved(solver);
    ;;; This is a procedure to drive the solver procedure from
    ;;; VED's status line, e.g.
    ;;;     ENTER strips [b1 on b2]
    ;;;     ENTER astart [b1 on b2] [p2 on b5]
    lvars solver;
    dlocal pausing, draw_solving, wasdrawing;
    draw_solving -> wasdrawing;
    if draw_solving then
        vededitor(vedveddefaults, picture_file);
        false -> vedchanged;
        ved_clear();
        vedputmessage('');
    endif;
    if vedargument = nullstring then
        solver(false, database, operators) ->
    else
        unless strmember(`[`, vedargument) then
            '[' >< vedargument >< ']' -> vedargument
        endunless;
        solver(
            pop11_compile(stringin('[' >< vedargument >< ']')),
            database,
            operators) ->;
    endif;
enddefine;

define ved_strips();
    runinved(runstrips);
enddefine;

define ved_astar();
    runinved(runastar);
enddefine;

define runsolver(solver, goals, data, operators) -> data;
    ;;; The solver can be procedure runstrips or runastar.
    ;;; goals is a list of lists, each specifying a goal.

    lvars procedure solver, goals, data, operators;
    dlocal draw_solving, pausing, wasdrawing = draw_solving;

    unless islist(goals) and goals /== [] then
        mishap('LIST OF GOALS NEEDED', [^goals])
    endunless;

    if draw_solving then
        ;;; Run the solver with the goals inside a VED file: picture_file
        vedobey(picture_file,
            procedure;
                ved_clear();    ;;; clear the VED file if necessary
                solver(goals, data, operators)
            endprocedure) -> data;
    else
        solver(goals, data, operators) -> data;
    endif;
enddefine;

/*
define : SOME UTILITIES TO ENABLE INVOCATION VIA MACROS
*/


define lconstant domacro(solver);
    ;;; Read in list expressions to end of line, then create a list of
    ;;; goals by compiling the expression inside extra list brackets.
    ;;; Then give the list of goals to the appropriate solver

    lvars item, goals, procedure solver;

    ;;; Enable readitem to return the word newline, instead of ignoring
    ;;; newlines.

    dlocal popnewline = true;

    ;;; Read in text specifying one or more lists of goals.
    [% until (readitem()->> item) == newline or item == termin do item
        enduntil%] -> goals;

    if goals == [] then false
    else pop11_compile( [%"["%  ^^goals %"]"%])
    endif -> goals;

    [runsolver(^solver, ^goals, ^database, ^operators) ==>] <> proglist -> proglist;

enddefine;

define macro strips;
    domacro(runstrips);
enddefine;

define macro astar;
    domacro(runastar);
enddefine;

/*
define : SOME TEST CASES
strips [b5 on b1]
** [[place b3 on table]
    [pick up b2 from b1]
    [place b2 on table]
    [take b5 off table]
    [put b5 on b1]]


strips [b3 on b5] [b2 on b3]

astar  [b3 on b5] [b2 on b3]

strips [b5 on b1] [b1 on b2]

astar  [b5 on b1] [b1 on b2]

runstrips([[b5 on b1][b1 on b2]], database, operators)==>

runastar([[b5 on b1][b1 on b2]], database, operators)==>

astar [b3 on b5][b2 on b3]

runsolver(runstrips, [[b2 on b5]], database, operators) ==>

runsolver(runastar, [[b2 on b5]], database, operators) ==>
*/

;;; set default
blocksworld();

global vars newsolver = true;   ;;; for "uses"
endsection;


/*  --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov 15 2001
	replaced rawcharin with vedinascii to make this work with XVed
--- Aaron Sloman, Dec 14 2000
	Replaced "instance" with "pattern_instance" to avoid clash with
	"instance" in objectclass
--- Aaron Sloman, Dec 24 1996
	Fixed missing lvars declaration and fixed bug in printing in new
	tree.p
--- Aaron Sloman, Nov  5 1995
    Given a new name for local file, with various other changes, including
    removing uses of global variables, and using a property activeprops
    instead of putting "*" in the planning tree.

    Removed the code that left completed plans in the database. Instead
    the plans are returned by runstrips, runastar, runsolver

=======================================================================


        PROCEDURE INDEX: Use ENTER g define

 define : GLOBAL VARIABLES CONTROLLING THE BEHAVIOUR
 define : DEFAULT BLOCKSWORLD DOMAIN
 define blocksworld();
 define checkdomain(data,  operators);
 define : UTILITY PROCEDURES
 define : DRAWING TREES IN VED AND PAUSING
 define PAUSE();
 define ved_cont();
 define lconstant islinegraphic(c);
 define sameline(s1, n1, s2, n2) -> boole;
 define pr_upper(x);
 define isactivetree(tree) -> boole;
 define display(indent, tree);
 define pshowtree(treenumber, tree);
 define ved_printify();
 define showplan(plan);
 define report(message);
 define : GENERAL UTILITIES
 define prune(list);
 define : UTILITIES CONCERNED WITH OPERATORS
 define : FINDING VARIABLES TO BE BOUND
 define lconstant get_sub_binding(binding);
 define getvars(binding) -> bound;
 define instantiated(pattern) -> boole;
 define partinstantiate(binding, pattern) -> partinstance;
 define bindings_unique(inst, pattern) -> boole;
 define : GETTING THE SUBLISTS OF OPERATORS
 define op_name(operator) -> list ;
 define op_preconditions(operator) -> list;
 define op_deletes(operator) -> list;
 define op_adds(operator) -> list;
 define adds_and_deletes(operator) -> (adds, deletes);
 define : COMPONENTS OF PLANNING TREES
 define tree_type(tree);
 define tree_goals(tree);
 define tree_plan(tree);
 define : FINDING RELEVANT OPERATORS AND CHECKING PLANS
 define get_operator(action, operators) -> operator;
 define perform(plan, operators);
 define achieves(plan, goals) -> boole;
 define insert(plan, others) -> plan;
 define same_state(state1, state2) -> boole;
 define leadstoaloop(plan, operators) -> boole;
 define clobbers(tree) -> boole;
 define plan_recurses(tree) -> boole;
 define : UTILITIES FOR ESTIMATING PLAN COSTS
 define howdoscan(action, goals, op, operators);
 define howdo(plan, goal, operators) -> actions;
 define estimate(plan, goals, operators) -> result;
 define : PROCEDURES FOR TESTING FEASIBILITY OF PLANS
 define cando(plan, database, operators);
 define differences(plan, goals) -> tasks;
 define : PROCEDURES REQUIRED FOR RUNSTRIPS
 define strips_raise(tree);
 define strips_splice(tree, node) -> tree;
 define strips_expand(current, plan, tree);
 define expand_state(tree, plan) -> (tree, plan, current);
 define runstrips(goals, database, operators) -> plan;
 define : UTILITIES FOR ASTAR ALGORITHM
 define astarplan(tree);
 define lconstant goal_cost(tree);
 define astar_expand(tree, current) -> current;
 define runastar(goals, database, operators) -> plan;
 define : PROCEDURES FOR RUNNING THE SOLVERS
 define runinved(solver);
 define ved_strips();
 define ved_astar();
 define runsolver(solver, goals, data, operators) -> data;
 define : SOME UTILITIES TO ENABLE INVOCATION VIA MACROS
 define lconstant domacro(solver);
 define macro strips;
 define macro astar;
 define : SOME TEST CASES

 */
