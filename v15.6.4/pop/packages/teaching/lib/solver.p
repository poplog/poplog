/*  --- Copyright University of Sussex 2008.  All rights reserved. ---------
 >  File:           C.all/lib/lib/solver.p
 >  Purpose:        problem solver?
 >  Author:         S.Hardy, 1982 (see revisions)
 >  Documentation:  TEACH * SOLVER
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

vars isactivetree, astar, achieves, blocks, cando, check, clobbers, clever,
	current, differences, display, estimate, estimating, expand,getbound,
	getschema, howdo, howdoscan, insert, instantiated, lastgoals, leadstoaloop, lookahead,
	node, noclobber, noloops, partial, perform, plan, raise, recurses,
	report, schemalist, showplan, ShowTree, splice, splitup, startstrips, stripsstate,
	treenumber, unique, uppr, verbose;

global vars solverdelay;

unless isinteger(solverdelay) then
	50 -> solverdelay
endunless;

0 -> treenumber;
true -> check;
[[b1 on b2] [b2 on b3]] -> lastgoals;
2 -> lookahead;
false -> clever;
true -> verbose;
false -> noloops;
false -> noclobber;
false -> estimating;

define checkdomain();
	vars bound, datum, variable, variables, schema;
	unless check then return endunless;
	unless islist(schemalist) then
		mishap('THE VALUE OF SCHEMALIST IS NOT A LIST', [%schemalist%])
	endunless;
	for schema in schemalist do
		unless islist(schema) then
			mishap('NON LIST POSING AS A SCHEMA', [%schema%])
		endunless;
		unless length(schema) = 4 then
			mishap('SCHEMA HAS MORE THAN FOR ELEMENTS',
						[%'THE SCHEMA NAMED', schema(1)%])
		endunless;
		for datum in schema do
			unless islist(datum) then
					mishap('ONE ELEMENT OF A SCHEMA IS NOT A LIST',
						[%datum, 'IN THE SCHEMA NAMED', schema(1)%])
			endunless
		endfor;
		for datum in schema(2) <> schema(3) <> schema(4) do
			unless islist(datum) then
				mishap('ONE ELEMENT OF A SCHEMA ELEMENT IS NOT A LIST',
						[%datum, 'IN THE SCHEMA NAMED', schema(1)%])
			endunless
		endfor;
		[] -> bound;
		getbound(schema(1));
		bound -> variables;
		[] -> bound;
		getbound(schema(2));
		for variable in bound do
			unless member(variable, variables) then
				mishap('VARIABLE NOT MENTIONED IN NAME OF SCHEMA',
							[%variable, 'IN SCHEMA NAMED', schema(1)%])
			endunless
		endfor;
		bound -> variables;
		getbound(schema(3));
		getbound(schema(4));
		for variable in bound do
			unless member(variable, variables) then
				mishap('VARIABLE NOT MENTIONED IN PRECONDITIONS OF SCHEMA',
							[%variable, 'IN SCHEMA NAMED', schema(1)%])
			endunless
		endfor;
		for datum in schema(3) do
			unless member(datum, schema(2)) do
				mishap('SCHEMA MIGHT REMOVE ITEM BUT IT IS NOT A PRECONDITION',
							[%datum, 'IN THE SCHEMA NAMED', schema(1)%])
			endunless
		endfor;
	endfor;
	for schema on schemalist do
		for datum on tl(schema) do
			if pattern_instance(hd(hd(schema))) matches hd(hd(datum)) then
				mishap('TWO SCHEMA HAVE MATCHING NAMES',
					[%'THE SCHEMA NAMED', hd(hd(schema)),
							'AND THE SCHEMA NAMED', hd(hd(datum))%])
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
		[] -> bound;
		getbound(datum);
		unless bound = [] then
			mishap('ONE ELEMENT OF DATABASE CONTAINS VARIABLES', [%datum%]);
		endunless;
	endfor;
enddefine;

define achieves(plan, goals);
	vars database;
	perform(plan);
	allpresent(goals)
enddefine;

define isactivetree(tree);
	until atom(tree) do
		if isactivetree(destpair(tree) -> tree) then return(true) endif
	enduntil;
	tree == "*"
enddefine;

define astarsplit(tree);
	if back(back(tree)) == [] then
		if front(back(tree)) < front(back(current)) then
			tree -> current
		endif
	else
		applist(back(back(tree)), astarsplit)
	endif
enddefine;

define astarplan(tree);
	vars subtree;
	if front(tree) = "*" then
		[%front(back(tree))%]
	else
		for subtree in back(back(tree)) do
			if isactivetree(subtree) then
				return(front(tree) :: astarplan(subtree))
			endif
		endfor
	endif
enddefine;

define runastar(goals);
	vars best, newplan, newtree, option, tree, treenumber, plan, current;
	checkdomain();
	vars size; stacklength() -> size;
	flush([plan ==]);       ;;; *** get rid of old plan
	unless goals then lastgoals -> goals endunless;
	goals -> lastgoals;
	[%goals, estimate([], goals)%] -> tree;
	0 -> treenumber;
	repeat
		[foo 100000] -> current;
		astarsplit(tree);
		if current = [foo 100000] then
			report('FAILED TO ACHIEVE GOALS');
			return
		endif;
		front(current) :: back(current) -> back(current);
		"*" -> front(current);
		back(astarplan(tree)) -> plan;
		treenumber + 1 -> treenumber;
		if achieves(plan, goals) then
			unless stacklength() = size then mishap('STACK ERROR', [1]) endunless;
			ShowTree(treenumber, tree);
			unless stacklength() = size then mishap('STACK ERROR', [2]) endunless;
			report('GOALS ACHIEVED');
			add([plan ^plan]);              ;;; ***
			unless stacklength() = size then mishap('STACK ERROR', [3]) endunless;
			showplan(plan);
			unless stacklength() = size then mishap('STACK ERROR', [4]) endunless;
			return;
		endif;
		[%for option in cando(plan) do
			plan <> [%option%] -> newplan;
			unless leadstoaloop(newplan) then
				[%option, estimate(newplan, goals) + length(newplan)%]
			endunless
		  endfor%] -> newtree;
		newtree -> back(back(back(current)));
		100000 * current(3) + treenumber -> current(3);
		ShowTree(treenumber, tree);
		front(back(current)) -> front(current);
		back(back(current)) -> back(current);
		if isinteger(solverdelay) and solverdelay /== 0 then
			syssleep(solverdelay)
		endif;
	endrepeat
enddefine;

define blocks();
	vars X, Y;
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
		] -> schemalist;
	;;;
	[[ontable b1]
		[b2 on b1] [cleartop b2]
		[holding b3] [cleartop b3]
		[ontable b4] [cleartop b4]
		[ontable b5] [cleartop b5]
		] -> database;
enddefine;

define prune(list);
	if list = [] then
		[]
	elseif member(hd(list), tl(list)) then
		prune(tl(list))
	else
		hd(list) :: prune(tl(list))
	endif
enddefine;

define cando(plan);
	vars action, database, schema;
	perform(plan);
	prune([%for schema in schemalist do
		forevery front(back(schema)) do
			pattern_instance(front(schema)) -> action;
			if unique(action, front(schema)) then action endif;
		endforevery
	  endfor%])
enddefine;

define clobbers(tree);
	vars subtree, goals;
	if front(tree) == "*" then back(tree) -> tree endif;
	if front(tree) == "achieve" then
		[] -> goals;
		for subtree in back(back(tree)) do
			if front(subtree) == "*" then back(subtree) -> subtree endif;
			if member(front(back(subtree)), goals) then return(true) endif;
			front(back(subtree)) :: goals -> goals
		endfor
	endif;
	for subtree in back(back(tree)) do
		if clobbers(subtree) then return(true) endif
	endfor;
	return(false)
enddefine;

define differences(plan, goals) -> tasks;
	vars database, goal;
	perform(plan);
	[] -> tasks;
	for goal in goals do
		unless present(goal) then
			insert(estimate(%[], [%goal%]%) :: goal, tasks) -> tasks
		endunless
	endfor;
	rev(maplist(tasks, back)) -> tasks;
enddefine;

define display(indent, tree);
	lvars x, f;
	pr -> f;
	if isactivetree(tree) then uppr -> f endif;
	destpair(tree) -> tree -> x;
	if x == "*" then destpair(tree) -> tree -> x endif;
	if islist(x) then
		applist(x, procedure x; f(x); pr(space) endprocedure)
	else
		f(x); pr(space);
	endif;
	if x == "achieve" then
		for x in destpair(tree) -> tree do f(x); pr(space)endfor
	else
		f(destpair(tree) -> tree)
	endif;
	if tree == [] then return endif;
	destpair(tree) -> tree -> x;
	until tree == [] do
		pr(indent);
		cucharout(`\Glt`);
		cucharout(`\G-`);
		cucharout(` `);
		display(indent sys_>< consstring(`\G|`, ` `, ` `, 3), x);
		destpair(tree) -> tree -> x;
	enduntil;
	pr(indent);
	cucharout(`\Gbl`);
	cucharout(`\G-`);
	cucharout(` `);
	display(indent sys_>< '   ', x);
enddefine;

define estimate(plan, goals) -> result;
	vars actions, database, estimating, goal, newgoal,
			considered, newgoals, lookahead;
	perform(plan);
	0 -> result;
	goals -> considered;
	true -> estimating;
	until lookahead == 0 do
		lookahead - 1 -> lookahead;
		[] -> newgoals;
		for goal in goals do
			unless present(goal) then
				result + 1 -> result;
				howdo([], goal) -> actions;
				if actions = [] then 100000 -> result; return endif;
				for newgoal
					in pattern_instance(front(back(getschema(front(actions)))))
				do
					unless member(newgoal, considered) then
						newgoal :: considered -> considered;
						newgoal :: newgoals -> newgoals
					endunless
				endfor
			endunless
		endfor;
		newgoals -> goals
	enduntil;
	for goal in goals do
		unless present(goal) then
			result + 1 -> result;
		endunless
	endfor
enddefine;

define expand(current, plan, tree);
	vars action, actions, node, goals, subgoal;
	if front(current) == "achieve" then
		front(back(current)) -> goals;
		if achieves(plan, goals) then
			raise(tree)
		else
			for subgoal in differences(plan, goals) do
				[[* reduce ^subgoal]] -> node;
				splice(tree);
			endfor
		endif
	elseif front(current) == "reduce" and back(back(current)) == [] then
		howdo(plan, front(back(current))) -> actions;
		if actions = [] then
			report('CANNOT REDUCE ' sys_>< front(back(current)));
		else
			for action in actions do
				pattern_instance(front(back(getschema(action)))) -> goals;
				if achieves(plan, goals) then
					[[* perform ^action]] -> node;
					raise(raise(splice(tree)))
				else
					[[* achieve ^goals] [perform ^action]] -> node;
					splice(tree);
				endif;
			endfor
		endif
	else
		raise(tree)
	endif
enddefine;

define getschema(action) -> schema;
	for schema in schemalist do
		if action matches front(schema) then
			return;
		endif
	endfor;
	mishap('MISSING SCHEMA', [%action%])
enddefine;

define howdo(plan, goal) -> actions;
	vars database, effect, schema;
	perform(plan);
	[] -> actions;
	for schema in schemalist do
		for effect in front(back(back(back(schema)))) do
			if goal matches effect then
				howdoscan(partial(effect, front(schema)),
						partial(effect, front(back(schema))))
			endif;
		endfor;
	endfor;
	maplist(actions, back) -> actions;
enddefine;

define howdoscan(action, goals);
	if instantiated(action) then
		if unique(action, front(schema)) then
			insert(
				estimate(%[],
					pattern_instance(front(back(getschema(action))))%) :: action,
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
				howdoscan(partial(front(goals), action),
					partial(front(goals), back(goals)))
			endforeach
		endunless;
		howdoscan(action, back(goals));
	endif
enddefine;

define instantiated(pattern);
	repeat
		if atom(pattern) then return(true) endif;
		if front(pattern) == "?" or front(pattern) == "??" then return(false) endif;
		unless instantiated(front(pattern)) then return(false) endunless;
		back(pattern) -> pattern;
	endrepeat
enddefine;

define leadstoaloop(plan);
	vars action, database, fact, history, oldstate, schema;
	[] -> history;
	for action in plan do
		database :: history -> history;
		pattern_instance(back(back(getschema(action)))) -> schema;
		allremove(front(schema));
		alladd(front(back(schema)));
	endfor;
	for oldstate in history do
		for fact in database do
			unless member(fact, oldstate) then nextloop(2) endunless
		endfor;
		for fact in oldstate do
			unless member(fact, database) then nextloop(2) endunless
		endfor;
		return(true);
	endfor;
	return(false)
enddefine;

define getbound(binding);
	until atom(binding) do
		if front(binding) == "?" or front(binding) == "??" then
			back(binding) -> binding;
		   (destpair(binding) -> binding) :: bound -> bound
		else
			getbound(destpair(binding) -> binding)
		endif
	enduntil
enddefine;

define partial(binding, pattern);
	vars bound;
	define partial(pattern);
		if atom(pattern) then
			pattern
		elseif front(pattern) == "?" then
			back(pattern) -> pattern;
			if member(front(pattern), bound) then
				valof(front(pattern)) :: partial(back(pattern))
			else
				"?" :: partial(pattern)
			endif
		elseif front(pattern) == "??" then
			back(pattern) -> pattern;
			if member(front(pattern), bound) then
				valof(front(pattern)) <> partial(back(pattern))
			else
				"??" :: partial(pattern)
			endif
		else
			partial(front(pattern))
				:: partial(back(pattern))
		endif
	enddefine;
	[] -> bound;
	getbound(binding);
	partial(pattern)
enddefine;

define perform(plan);
	vars action, schema;
	for action in plan do
		pattern_instance(back(back(getschema(action)))) -> schema;
		allremove(front(schema));
		alladd(front(back(schema)));
	endfor
enddefine;

define insert(plan, others);
	if others == [] then
		plan :: others
	elseif back(plan) = back(front(others)) then
		others
	else
		if isprocedure(front(plan)) then
			front(plan)() -> front(plan)
		endif;
		if isprocedure(front(front(others))) then
			front(front(others))() -> front(front(others))
		endif;
		if front(plan) < front(front(others)) then
			plan :: others
		else
			front(others) :: insert(plan, back(others))
		endif
	endif
enddefine;

define raise(tree);
	vars done;
	define raise(tree);
		vars this;
		unless isactivetree(tree) then return(tree) endunless;
		false -> this;
		[%front(tree), front(back(tree)),
			for subtree in back(back(tree)) do
				if done then
					subtree
				elseif front(subtree) == "*" then
					true -> this;
					true -> done;
					back(subtree);
				else
					raise(subtree)
				endif
			endfor%] -> tree;
		if this then "*" :: tree else tree endif
	enddefine;
	if front(tree) == "*" then
		back(tree)
	else
		false -> done;
		raise(tree)
	endif
enddefine;

define recurses(commands, tree);
	vars subtree;
	if front(tree) == "*" then back(tree) -> tree endif;
	if front(tree) == "reduce" then
		if member(front(back(tree)), commands) then return(true) endif;
		front(back(tree)) :: commands -> commands
	endif;
	for subtree in back(back(tree)) do
		if recurses(commands, subtree) then return(true) endif
	endfor;
	return(false);
enddefine;

define showplan(plan);
	vars cucharout;
	procedure (c);
		vedcheck();
		if c == `\n` then
			vednextline();
		else
			vedcharinsert(c);
		endif;
	endprocedure -> cucharout;
	vedselect('tree');
	pr('\nCOMPLETE PLAN IS:\n');
	until plan = [] do
		pr('\t');
		pr(dest(plan) -> plan);
		pr('\n');
	enduntil;
enddefine;

define islinegraphic(c);
	lvars c;
	`\Gle` <= c and c <= `\G+`
enddefine;

define sameline(s1, n1, s2, n2);
	lvars n, c1, c2;
	for n from 1 to min(n1, n2) do
		s1(n) -> c1;
		s2(n) -> c2;
		unless c1 == c2 or islinegraphic(c1) or islinegraphic(c2) or c1 == ` `
			or c2 == ` ` or c1 + `a` == c2 + `A` or c1 + `A` == c2 + `a`
		then
			return(false)
		endunless
	endfor;
	return(true)
enddefine;

define ShowTree(treenumber, tree);
	dlvars index, text;

	define dlocal cucharout(c);
		lvars c, n;;
		if c == `\n` then
			vedsetlinesize();
			unless sameline(text, index, vedthisline(), datalength(dup())) do
				vedcheck();
				vedlineabove()
			endunless;
			for n from 1 to index do
				text(n) -> c;
				if c == vedcurrentchar() then
					vedcharright()
				else
					vedcheck();
					veddotdelete();
					if islinegraphic(c) then c || `\[6]` -> c endif;
					vedcharinsert(c)
				endif
			endfor;
			vednextline();
			if vedline > (vedscreenlength div 2)
			and vedwindowlength /== vedscreenlength
			then
				vedsetwindow()
			endif;
			0 -> index;
			vedscreenflush();
		else
			index + 1 -> index;
			c -> text(index)
		endif
	enddefine;

	vedselect('tree');
	false -> vedbreak;
	'' -> vedcommand;
	vedjumpto(1, 1);
	vedputmessage('DRAWING');
	vedscreenflush();
	inits(256) -> text;
	0 -> index;
	display('\n  ', tree);
	pr(newline);
	vedputmessage('TREE NUMBER ' sys_>< treenumber);
	until vedatend() do vedlinedelete() enduntil;
	vedscreenflush();
enddefine;

define splice(tree);
	vars subtree, done;
	define splice(tree);
		unless isactivetree(tree) then return(tree) endunless;
		if hd(tree) == "*" then
			true -> done;
			back(tree) <> node
		else
			[%front(tree), front(back(tree)),
				for subtree in back(back(tree)) do
					if done then subtree else splice(subtree) endif
				endfor%]
		endif
	enddefine;
	false -> done;
	splice(tree);
enddefine;

define splitup(tree);
	if front(tree) == "*" then
		applist(back(back(back(tree))), splitup);
		back(tree) -> current;
	elseif front(tree) == "perform" then
		front(back(tree)) :: plan -> plan;
	else
		back(back(tree)) -> tree;
		until current or tree == [] do
			splitup(destpair(tree) -> tree)
		enduntil
	endif
enddefine;

define runstrips(goals);
	vars current, goals, plan, tree;
	dlocal vedautowrite = false, vednotabs = true;
	checkdomain();
	flush([plan ==]);       ;;; *** get rid of old plan
	unless goals then lastgoals -> goals endunless;
	goals -> lastgoals;
	[[* achieve ^goals]] -> stripsstate;
	0 -> treenumber;
	repeat
		if stripsstate == [] then
			report('COULD NOT ACHIEVE GOALS'); return;
		endif;
		destpair(stripsstate) -> stripsstate -> tree;
		false -> current;
		[] -> plan;
		splitup(tree);
		rev(plan) -> plan;
		treenumber + 1 -> treenumber;
		ShowTree(treenumber, tree);
		unless current then
			report('GOALS ACHIEVED');
			add([plan ^plan]);              ;;; ***
			showplan(plan);
			return
		endunless;
		if (clever or noloops) and leadstoaloop(plan) then
			report('PLAN ABANDONED BECAUSE LEADS TO LOOP');
		elseif recurses([], tree) then
			report('PLAN ABANDONED BECAUSE RECURSIVE GOALS');
		elseif (clever or noclobber) and clobbers(tree) then
			report('PLAN ABANDONED BECAUSE CLOBBERS AN ACHIEVED GOAL');
		else
			[%expand(current, plan, tree)%] <> stripsstate -> stripsstate;
		endif;
		if isinteger(solverdelay) and solverdelay /== 0 then
			syssleep(solverdelay)
		endif;
	endrepeat
enddefine;

define unique(inst, pattern);
	vars popmatchvars;
	[] -> popmatchvars;
	erase(sysmatch(pattern, inst));
	maplist(popmatchvars, valof) -> popmatchvars;
	until popmatchvars == [] do
		if member(destpair(popmatchvars)) then return(false) endif;
		back(popmatchvars) -> popmatchvars
	enduntil;
	return(true);
enddefine;

define uppr(x);
	vars output;
	cucharout -> output;
	define cucharout(c);
		output(if `a` <= c and c <= `z` then c + `A` - `a` else c endif)
	enddefine;
	pr(x)
enddefine;

define report(message);
	vedscreenbell();
	repeat 10 times
		vedputmessage('*' <> message <> '*');
		vedputmessage(' ' <> message <> ' ');
		vedscreenflush();
	endrepeat
enddefine;

define ved_strips();
	dlocal pop_pr_quotes = false;
	vededitor(identfn, 'tree');
	false -> vedchanged;
	ved_clear();
	if vedargument = '' then
		runstrips(false);
	else
		unless strmember(`[`, vedargument) then
			'[' <> vedargument <> ']' -> vedargument
		endunless;
		runstrips(pop11_compile(stringin('[' <> vedargument <> ']')));
	endif;
enddefine;

unless islist(schemalist) then blocks() endunless;

define ved_printify();
	;;; not necessary with new graphic chars
enddefine;

define ved_astar();
	dlocal pop_pr_quotes = false;
	vededitor(identfn, 'tree');
	ved_clear();
	if vedargument = '' then
		runastar(false);
	else
		unless strmember(`[`, vedargument) then
			'[' <> vedargument <> ']' -> vedargument
		endunless;
		runastar(pop11_compile(stringin('[' <> vedargument <> ']')));
	endif;
enddefine;

define runsolver(solver);
	vars goals;
	dlocal pop_pr_quotes = false;
	if poplastchar = `\n` then
		false -> goals
	else
		pop11_compile(stringin('[' <> readstringline() <> ']')) -> goals
		;;; popval([%"["%] <> readline() <> [%"]"%]) -> goals
	endif;
	vedobey('tree', procedure; ved_clear(); solver(goals) endprocedure)
enddefine;

define macro strips; runsolver(runstrips) enddefine;

define macro astar; runsolver(runastar) enddefine;



/*  --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jun 18 2008
		Also introduced solverdelay to slow down display: it's too fast
		for modern computers otherwise.
--- Aaron Sloman, Jun 17 2008
		Replaced all occurrences of inst*ance with pattern_inst*ance,
		because the former clashes with objectclass.
--- John Williams, Nov 28 1995
		Uses readstringline instead of readline due to problems with
		the latter if strips commands are loaded with ved_lmr.
--- John Williams, Nov 24 1995
		Line graphics drawn in blue!
		>< replaced by sys_>< and <> as appropriate.
		vedbuffer(vedline) replaced by vedthisline().
		pop_pr_quotes set false in various places.
		Hardwired screen and window lengths replaced with vedscreenlength
		and vedwindowlength.
--- John Gibson, Aug  1 1995
		Added +oldvar at top
--- John Gibson, Mar  4 1992
		Changed to use new graphic chars
 */
