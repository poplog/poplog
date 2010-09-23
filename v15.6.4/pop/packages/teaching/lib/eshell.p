/*  --- Copyright University of Sussex 1995.  All rights reserved. ---------
 >  File:           C.all/lib/lib/eshell.p
 >  Purpose:        Simple expert system shell inspired by PROSPECTOR
 >  Author:         Chris Mellish, Jan 1985 (see revisions)
 >  Documentation:  TEACH * EXPERTS
 >  Related Files:  LIB * EPROSPECT
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

;;; Simple expert system shell inspired by Prospector and demonstrating
;;; how backwards and forwards chaining can interact in an expert system

;;; Set this variable to TRUE to get more information about
;;; the system's conclusions

vars chatty;
false -> chatty;

;;; Each atomic proposition is represented by a datastructure with components:
;;;
;;; low - lower bound on its probability
;;; high - upper bound on its probability
;;; name - the printable version
;;; expr - an "expression" indicating how its probability depends on that
;;;         of other propositions (false if this is a proposition to
;;;         be asked about)
;;; fixed - a truth value to indicate whether the probabilities have
;;;         been fixed by the user

recordclass atom low high name expr parents fixed;

procedure x; ('<atom '><x.name><'>').syspr endprocedure
	 -> class_print(key_of_dataword("atom"));

;;; All known atoms are kept in ATOMS

vars atoms;

;;; List of all goals

vars goals;

define newatom(n);
	consatom(0,1,n,false,[],false)
enddefine;

;;; Return the atom associated with a given name

define isatomname(n);
	vars x;
	unless n.islist then return(false) endunless;
	for x in n do
		unless x.isword or x.isnumber then
			return(false)
		endunless
	endfor;
	true
enddefine;

define lookup(n);
	vars a;
	unless n.isatomname then
		mishap('Illegal proposition',[^n])
	endunless;
	for a in atoms do
		if a.name = n then return(a) endif
	endfor;
	conspair(newatom(n).dup,atoms) -> atoms
enddefine;

;;; Expressions are formed using logical connectives AND, OR and NOT
;;; With each connective is a weight and a list of daughter expressions

recordclass comb weight connective daughts;

;;; evaluate an expression

define ev(e);
	vars l h x l1 h1 w;
	if e.isatom then [^(e.low) ^(e.high)]
	elseif e.iscomb then
		e.weight -> w;
		if e.connective == "and" then
			1 -> l;
			1 -> h;
			for x in e.daughts do
				ev(x) --> [?l1 ?h1];
				min(l,l1) -> l;
				min(h,h1) -> h
			endfor;
		elseif e.connective == "or" then
			0 -> l;
			0 -> h;
			for x in e.daughts do
				ev(x) --> [?l1 ?h1];
				max(l,l1) -> l;
				max(h,h1) -> h;
			endfor;
		elseif e.connective == "not" then
			ev(hd(daughts(e))) --> [?l1 ?h1];
			1 - h1 -> l;
			1 - l1 -> h;
		endif;
		[^(w*l) ^(w*h)]
	elseif e.isatom then
		[^(e.low) ^(e.high)]
	endif
enddefine;

;;; Reconsider an atom (atomic proposition)
;;; If its probability values have changed, reconsider
;;; atoms that depend on it

define reconsider(a);
	vars l h;
	if a.expr and a.fixed.not then
		ev(a.expr) --> [?l ?h];
		unless l = a.low and h = a.high then
			if chatty then
				[^^(a.name) is now between ^l and ^h (was ^(a.low) and ^(a.high))]=>
			endif;
			l -> a.low;
			h -> a.high;
			for x in a.parents do
				reconsider(x)
			endfor
		endunless
	endif
enddefine;

;;; Given some expression, return the set of atoms which
;;; could change in such a way as to help the probability to
;;; increase above a threshold

vars procedure decrease;

define increase(prop,thresh);
	vars asks, wt, x, ok;
	if thresh < 0 then
		return([])
	elseif thresh >= 1 then
		return(false)
	endif;
	[] -> asks;
	if prop.iscomb then
		prop.weight -> wt;
		if thresh > wt then
			return(false)
		endif;
		if prop.connective == "and" then
			for x in prop.daughts do
				if dup(increase(x,thresh/wt)) then
					<> asks -> asks
				else
					erase();
					return(false)
				endif
			endfor
		elseif prop.connective == "or" then
			false -> ok;
			for x in prop.daughts do
				if dup(increase(x,thresh/wt)) then
					<> asks -> asks;
					true -> ok
				else erase()
				endif;
			endfor;
			unless ok then return(false) endunless
		elseif prop.connective == "not" then
			decrease(prop.daughts.hd,(1-thresh)/wt) -> asks
		endif;
		asks
	elseif prop.isatom then
		if prop.expr and prop.fixed.not then
			increase(prop.expr,thresh)
		elseif prop.low == prop.high then
			if prop.low > thresh then
				[]
			else
				false
			endif
		elseif prop.high <= thresh then
			false
		elseif prop.low > thresh then
			[]
		else
			[^prop]
		endif
	endif
enddefine;

;;; Similar for decreasing an expression below threshold

define decrease(prop,thresh);
	vars asks, wt, x, ok;
	if thresh <= 0 then
		return(false)
	elseif thresh > 1 then
		return([])
	endif;
	[] -> asks;
	if prop.iscomb then
		prop.weight -> wt;
		if wt < thresh then
			return([])
		endif;
		if prop.connective == "or" then
			for x in prop.daughts do
				if dup(decrease(x,thresh/wt)) then
					<> asks -> asks
				else
					erase();
					return(false)
				endif
			endfor
		elseif prop.connective == "and" then
			false -> ok;
			for x in prop.daughts do
				if dup(decrease(x,thresh/wt)) then
					<> asks -> asks;
					true -> ok
				else erase()
				endif;
			endfor;
			unless ok then return(false) endunless
		elseif prop.connective == "not" then
			increase(prop.daughts.hd,(1-thresh)/wt) -> asks
		endif;
		asks
	elseif prop.isatom then
		if prop.expr and prop.fixed.not then
			decrease(prop.expr,thresh)
		elseif prop.low == prop.high then
			if prop.high < thresh then
				[]
			else
				false
			endif
		elseif prop.low >= thresh then
			false
		elseif prop.high < thresh then
			[]
		else
			[^prop]
		endif
	endif
enddefine;

;;; Comparison of numbers

define 3 x =-= y;
	abs(x-y) < 0.00001
enddefine;

;;; Converting the rule set from the list form into datastructures as above

define eval_body(list,parent);
	vars ds d a;
	if list matches [and ??ds] then
		conscomb(1,"and",
			[% for d in ds do
					 eval_body(d,parent)
			endfor%])
	elseif list matches [or ??ds] then
		conscomb(1,"or",
			[% for d in ds do
					 eval_body(d,parent)
			endfor%])
	elseif list matches [not ?d] then
		conscomb(1,"not",[% eval_body(d,parent) %])
	else
		lookup(list) -> a;
		unless member(parent,a.parents) then
			parent::(a.parents) -> a.parents
		endunless;
		a
	endif
enddefine;

define setup(list);
	vars rule concl body cond w a b;
	[] -> atoms;
	for rule in list do
		unless rule matches [??body => ?w ?concl] then
			if member("=>",rule) then
				mishap('Wrong number of elements in rule',[^rule])
			else
				mishap('No implication arrow in rule',[^rule])
			endif
		endunless;
		lookup(concl) -> concl;
		unless w.isnumber and w <=1 and w>= 0 then
			mishap('Illegal weight in rule',[^w])
		endunless;
		conscomb(w,"and",
			[%for b in body do
					 eval_body(b,concl)
			 endfor%]) -> body;
		if concl.expr then
			conscomb(1,"or",[^(concl.expr) ^body]) -> concl.expr
		else
			body -> concl.expr
		endif
	endfor;
	[] -> goals;
	for a in atoms do
		if a.parents == [] then
			unless a.expr then
				mishap('Proposition has no antecedents or consequences',[^(a.name)])
			endunless;
			a::goals -> goals
		endif
	endfor
enddefine;

;;; Display the values of all the goals

define disp_goals();
	vars g;
	for g in goals do
		['  ' ^^(g.name) between ^(g.low) and ^(g.high)].npr; nl(1)
	endfor
enddefine;

define neq();
	l1 /= h1
enddefine;

;;; Given the goals and their current probability ranges in an ordered
;;; "database", decide on a high-level strategy and an atom to be
;;; asked about

define enough_difference(l1,h1,l2,h2);
	vars resp;
	if l2 =-= h2 and l1 =-= h1 then true
	else
		nl(1); [My conclusions are:].npr; nl(1);
		disp_goals(goals);
		'Do I need to investigate further? '.pr;
		readline() -> resp;
		if resp = [yes] or resp = [y] then
			false
		else
			true
		endif
	endif
enddefine;

define decide(database) -> strategy -> ask;
	vars x l1 h1 a1 l2 h2 a2 y askposs;
	if present([0 1 ?x]) then
		[investigate ^^(x.name)] -> strategy;
		hd(increase(x,0)) -> ask
	elseif database matches [[?l1 ?h1 ?a1][?l2 ?h2 ?a2] ==] and
		l1 > h2 and enough_difference(l1,h1,l2,h2) then
		[exit ^^(a1.name)] -> strategy;
		false -> ask
	elseif database matches [[?l1 ?h1 ?a1][?l2 ?h2 ?a2] ==] and
		l1 <= h2 and h1 > h2 and h2 /= 1 and l1 /= h1 and (increase(a1,l1)->> askposs) then
		[confirm ^^(a1.name)] -> strategy;
		increase(a2,l2) -> y;
		if y then
			for x in askposs do
				if not(member(x,y)) then
					x -> ask;
					return
				endif
			endfor
		endif;
		hd(askposs) -> ask
	elseif database matches [[?l1 ?h1 ?a1][?l2 ?h2 ?a2] ==] and
		l1 <= h2 and l2 < l1 and l2 /= h2 and (decrease(a2,h2)->>ask) then
		[disconfirm ^^(a2.name)] -> strategy;
		hd(ask) -> ask
	elseif present([?l1 ?h1:neq ?x]) then
		[investigate ^^(x.name)] -> strategy;
		hd(increase(x,l1)) -> ask
	else
		[exit] -> strategy;
		false -> ask
	endif
enddefine;

;;; Explaining belief in a proposition

vars procedure why1;

define explain(n);
	vars a;
	lookup(n) -> a;
	[I believe ^^(a.name) with a probability between ^(a.low) and ^(a.high) because:].npr;
	nl(1);
	if a.expr.not or a.fixed then
		sp(3);
		if a.low = a.high then
			[you told me so].npr
		else
			[every proposition has a probability in this range].npr
		endif;
		nl(1)
	else
		why1(a.expr);
	endif
enddefine;

define macro why;
	vars popnewline i;
	true -> popnewline;
	explain([%while (.readitem ->> i) /= newline do i endwhile%])
enddefine;

define npr(list);
	if list.islist then
		applist(list,spr)
	else
		list.pr
	endif
enddefine;

define why1(e);
	vars x;
	if e.isatom then
		sp(3);
		[I believe ^^(e.name) with a probability between ^(e.low) and ^(e.high)].npr;
		nl(1)
	else
		for x in e.daughts do
			why1(x)
		endfor
	endif
enddefine;

;;; ask a question

define ask_question(words);
	vars resp, num, n;
	nl(1);
	words.npr;
	readline() -> resp;
	if resp = [why] then
		nl(1);
		[I am attempting to ^^strategy].npr; nl(2);
		[The current hypotheses are:].npr; nl(1);
		disp_goals(goals);
		ask_question(words)
	elseif resp matches [why ??n] then
		nl(1);
		explain(n);
		ask_question(words)
	elseif resp matches [trace] then
		true -> chatty;
		ask_question(words)
	elseif resp matches [stop trace] then
		false -> chatty;
		ask_question(words)
	elseif resp matches [?num] and num.isnumber and num >=0 and num <=1 then
		num
	else
		nl(1);
		[Possible responses are:].npr; nl(2);
		[a number between 0 and 1].npr; nl(1);
		[why - explains the systems current goals].npr; nl(1);
		[why <fact> - gives the grounds for belief in <fact>].npr; nl(1);
		[trace - turns CHATTY mode on].npr; nl(1);
		[stop trace - turns CHATTY mode off].npr; nl(1);
		ask_question(words)
	endif
enddefine;

;;; Get initial facts from the user

define get_user_info();
	vars response a x;
	[Please enter any relevant facts I should know].npr; nl(1);
	[(finish with a blank line)].npr; nl(2);
	until (readline()->>response) == [] do
		for a in atoms do
			if response = a.name then
				1 -> a.low;
				1 -> a.high;
				true -> a.fixed;
				for x in a.parents do
					reconsider(x)
				endfor;
				quitloop
			endif
		endfor;
		unless response = a.name then
			[Sorry, I dont understand that one].npr; nl(1)
		else
			[OK].npr; nl(1)
		endunless
	enduntil
enddefine;

;;; Main procedure

define run();
	vars a strategy ask resp database oldtracing;
	chatty -> oldtracing;
	false -> chatty;
	[explore] -> strategy;
	if atoms.isundef then
		mishap('SETUP not yet called',[])
	endif;
	for a in atoms do
		false -> a.fixed;
	endfor;
	for a in atoms do
		if a.expr then
			reconsider(a)
		else
			0 -> a.low;
			1 -> a.high
		endif
	endfor;
	oldtracing -> chatty;
	get_user_info();
	nl(1); [Perhaps I can now ask some further questions].npr; nl(1);
	repeat
		syssort(goals,
			procedure x y;
				if x.high > y.high then true
				elseif x.high = y.high then x.low > y.low
				else false
				endif
			endprocedure) -> goals;
		[% for a in goals do
				 [% a.low, a.high, a %]
		 endfor %] -> database;
		decide(database) -> strategy -> ask;
		if strategy.hd = "exit" then quitloop endif;
		ask_question(ask.name) -> resp;
		resp ->> ask.low -> ask.high;
		for a in ask.parents do
			reconsider(a)
		endfor
	endrepeat;
	nl(1); [Final conclusions are].npr; nl(1);
	disp_goals(goals)
enddefine;


/* --- Revision History ---------------------------------------------------
--- John Williams, Aug  4 1995
		Now sets compile_mode +oldvar.
 */
