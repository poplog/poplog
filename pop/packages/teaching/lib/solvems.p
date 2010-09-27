/*  --- Copyright University of Sussex 1986.  All rights reserved. ---------
 >  File:           C.all/lib/lib/solvems.p
 >  Purpose:        Computer problem solving?
 >  Author:         Steve Hardy 1982 (see revisions)
 >  Documentation:  TEACH * SOLVEMS
 >  Related Files:
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

define adjacent(old) -> result;
	vars index, new;
	[] -> result;
	for index from 1 to length(old) - 1 do
		copylist(old) -> new;
		old(index) -> new(index + 1);
		old(index + 1) -> new(index);
		[^new ^^result] -> result;
	endfor
enddefine;

define isgoal(state) -> result;
	vars index;
	for index from 1 to length(state) - 1 do
		if state(index) > state(index + 1) then
			false -> result;
			return;
		endif;
	endfor;
	true -> result;
enddefine;

define perfect(state) -> result;
	vars x, y;
	0 -> result;
	for x on state do
		for y on tl(x) do
			if x(1) > y(1) then
				result + 1 -> result
			endif
		endfor
	endfor;
enddefine;

define mediocre(state) -> result;
	vars index;
	0 -> result;
	for index from 1 to length(state) - 1 do
		if state(index) > state(index + 1) then
			result + 1 -> result;
		endif;
	endfor
enddefine;

vars estimate;
unless isprocedure(estimate) then mediocre -> estimate endunless;

define depth(new, old);
	length(new) >= length(old)
enddefine;

define breadth(new, old);
	length(new) < length(old)
enddefine;

define best(new, old);
	estimate(last(new)) <= estimate(last(old))
enddefine;

define astar(new, old);
	estimate(last(new)) + length(new) < estimate(last(old)) + length(old)
enddefine;

define hill(new, old);
	if length(new) < length(old) then
		false
	elseif length(new) > length(old) then
		true
	else
		best(new, old)
	endif
enddefine;

vars compare; unless isprocedure(compare) then astar -> compare endunless;

define insert(this, others) -> result;
	vars first, rest;
	if others matches [?first ??rest] then
		if compare(this, first) then
			[^this ^first ^^rest] -> result;
		else
			insert(this, rest) -> rest;
			[^first ^^rest] -> result;
		endif
	else
		[^this] -> result;
	endif
enddefine;

vars verbose; unless isboolean(verbose) then false -> verbose endunless;
vars debug; unless isboolean(debug) then false -> debug; endunless;

define search(initial);
	vars current, history, count, untried, option, new, maxmemory;
	initial -> current;
	[] -> history;
	[] -> untried;
	0 -> count;
	0 -> maxmemory;
	until isgoal(current) do
		count + 1 -> count;
		if debug then
			repeat length(history) + 1 times pr(".") endrepeat;
			repeat estimate(current) times pr("*") endrepeat;
			pr(newline);
		endif;
		if verbose then
			[Considering state number ^count
				Estimate for this state is ^(estimate(current))
				Number of untried paths is ^(length(untried))
				History and state is] =>
			[^^history ^current] ==>
		endif;
		for option in adjacent(current) do
			unless member(option, history) do
				[^^history ^current ^option] -> new;
				insert(new, untried) -> untried;
				if length(untried) > 2000 then
					rev(tl(rev(untried))) -> untried
				endif;
			endunless;
		endfor;
		if length(untried) > maxmemory then
			length(untried) -> maxmemory
		endif;
		untried  --> [[??history ?current] ??untried];
	enduntil;
	[Solution has been found after considering ^count states
		The length of the solution is ^(length(history) + 1)
		Maximum memory requirements were ^maxmemory
		Search strategy was ^(pdprops(compare))
		Estimation method was ^(pdprops(estimate))
		The solution itself is] =>
	[^^history ^current] ==>
enddefine;

vars intial; unless islist(initial) then [3 4 1 2] -> initial endunless;

define 4 go;
	search(initial)
enddefine;
