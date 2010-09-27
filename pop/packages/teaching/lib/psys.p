/*  --- Copyright University of Sussex 1986.  All rights reserved. ---------
 >  File:           C.all/lib/lib/psys.p
 >  Purpose:        Production system interpreter.
 >  Author:         Steven Hardy, 1978
 >  Documentation:  TEACH * PSYS
 >  Related Files:  LIB * PRODYSYS (upgraded version)
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

/*
	 A typical call of the system looks like:
			 : interpret(system);

	 There are two control variables:
			 chatty
					 if this is set true then the system prints out
					 the database before each rule is activated
					 and also prints out the rule being used
			 repeating
					 if this is set false the system will not trigger the
					 same rule on the same database items twice.
					 Use of this option slows the system up considerably


	 A production system is a list of rules

	 A production rule looks like:
			 [trigger ... => action ...]

	 A trigger is either:
			 [not data item]
			 in which case [data item] must NOT be in the
			 DATABASE
	 or it is
			 [data item]
			 in which case [data item] must be in the DATABASE

	 A data item is a list, some of whose leelements may be proceded
	 by "?" or "??"


	 An action is either:
			 [say some thing]
			 in which case [some thing] is printed out
	 or
			 [read some thing]
			 in which case a line is read in and the item
					 [some thing ...]
			 is added to the database where ... is what was read in
	 or
			 [stop message]
			 in which case the production system run is halted and
					 [message]
			 printed out
	 or
			 [not data item]
			 in which case [data item] is removed from the DATABASE
	 or
			 [data item]
			 in which case [data item] is added to the DATABASE

	 The system needs improvement. Some possible improvements
	 are:
	 (a)     Keep the individual rules in variables
			 and add two new actions
			 [use rulename]
			 which adds rulename to the current set of rules
			 [drop rulename]
			 which deletes rulename from the current set of rules

	 (b)     Some facility fro constructing new rules
			 dynamically, for example:
					 [new ... => ...]

	 (c)     A 'compute' action to call for a POP11 computation
			 For example,
					 [compute ?x > ?y]
			 would cause either
					 [pop true]
			 or      [pop false]
			 to be added to the STM.

*/

vars Used;
define value(Pattern);
	if hd(Pattern) = "not" then return(tl(Pattern)) endif;
	[%until Pattern = [] then
			 if hd(Pattern) = "?" then
				 tl(Pattern) -> Pattern;
				 if member(hd(Pattern), Used) then
					 valof(hd(Pattern))
				 else
					 hd(Pattern) :: Used -> Used;
					 "?", hd(Pattern)
				 endif
			 elseif hd(Pattern) = "??" then
				 tl(Pattern) -> Pattern;
				 if member(hd(Pattern), Used) then
					 dl(valof(hd(Pattern)))
				 else
					 hd(Pattern) :: Used -> Used;
					 "??", hd(Pattern)
				 endif
			 elseif atom(hd(Pattern)) then
				 hd(Pattern)
			 else
				 value(hd(Pattern))
			 endif;
			 tl(Pattern) -> Pattern
		 enduntil%]
enddefine;

define alleq(x, y);
	if x = [] then
		y = []
	elseif hd(x) == hd(y) then
		alleq(tl(x), tl(y))
	else
		false
	endif
enddefine;

vars Tried; [] -> Tried;
define tried(rule, triggers);
	vars Tried;
	until Tried = [] then
		if hd(hd(Tried)) == rule and alleq(tl(hd(Tried)), triggers) then
			return(true)
		endif;
		tl(Tried) -> Tried
	enduntil;
	false
enddefine;

vars chatty, system; false -> chatty;
vars repeating; true -> repeating;
vars Triggers;
define try(rule);
	vars Used;
	if hd(rule) = "=>" then
		if tried(hd(system), Triggers) then
			false
		else
			if chatty then
				[rule] <> value(hd(system)) ==>
			endif;
			hd(system) :: Triggers :: Tried -> Tried;
			tl(rule) -> rule;
			until rule = [] then
				if hd(hd(rule)) = "say" then
					value(tl(hd(rule))) =>
				elseif hd(hd(rule)) = "read" then
					add(value(tl(hd(rule))) <> readline())
				elseif hd(hd(rule)) = "not" then
					remove(value(tl(hd(rule))))
				elseif hd(hd(rule)) = "stop" then
					value(hd(rule)) =>
					setpop()
				else
					add(value(hd(rule)))
				endif;
				tl(rule) -> rule
			enduntil;
			true
		endif
	elseif hd(hd(rule)) = "not" then
		if present(value(tl(hd(rule)))) then
			false
		else
			try(tl(rule))
		endif
	else
		foreach value(hd(rule)) then
			it :: Triggers -> Triggers;
			if try(tl(rule)) then
				return(true)
			endif;
			tl(Triggers) -> Triggers;
		endforeach;
		false
	endif
enddefine;

define findrule(system);
	vars Used, Triggers;
	until system = [] then
		[] -> Used;
		[] -> Triggers;
		if try(hd(system)) then
			return;
		endif;
		tl(system) -> system;
	enduntil;
	mishap('no relevant rule',[])
enddefine;

define gone(item);
	vars database;
	until database = [] then
		if hd(database) = item then
			return(false)
		else
			tl(database) -> database
		endif
	enduntil;
	true
enddefine;

define anygone(list);
	if list = [] then
		false
	elseif gone(hd(list)) then
		true
	else
		anygone(tl(list))
	endif
enddefine;

define prune(Tried);
	if Tried = [] then
		[]
	elseif anygone(tl(hd(Tried))) then
		prune(tl(Tried))
	else
		hd(Tried) :: prune(tl(Tried))
	endif
enddefine;

define interpret(system);
	vars database, Tried;
	[] -> database;
	[] -> Tried;
	while true then
		if repeating then
			[] -> Tried
		endif;
		prune(Tried) -> Tried;
		if chatty then
			[database] <> database ==>
		endif;
		findrule(system)
	endwhile
enddefine;
