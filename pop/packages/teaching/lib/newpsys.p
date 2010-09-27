/*  --- Copyright University of Sussex 1993.  All rights reserved. ---------
 >  File:           C.all/lib/lib/newpsys.p
 >  Purpose:        Production system interpreter.
 >  Author:         Aaron Sloman December 1989. (see revisions)
 >  Documentation:  HELP * NEWPSYS, TEACH * PSYSRIVER, TEACH * EXPERTS
 >  Related Files:  LIB * PSYS, LIB * PRODYSYS (More primitive)
 */
compile_mode:pop11 +strict;

/*
This is a replacement for LIB PSYS offering a large number of extensions.

It uses the format

	define :rule in <ruleset> <conditions>  ; <actions>   enddefine;

which means that VED's commands for the "current procedure" will work,
E.g. <ENTER> mcp, jcp, lcp (See HELP * MARK)

The "in <ruleset>" component is optional, in which case <ruleset> defaults
to psys_rules. For more details see HELP * NEWPSYS

The use of "WHERE" conditions is not restricted to the end of the condition
list as in LIB PRODSYS.

Also, unlike LIB PRODSYS all rules are interpreted, not compiled.

In addition there are some extra features, including more flexible
tracing and debugging options, user specifiable conflict resolution
strategy, user specifiable limit on working memory, etc.

See HELP * NEWPSYS for details

*/
/*
A typical call of the system looks like:
		psys_run(psys_rules, psys_database);

Where -psys_rules- is a list of rules of the form described below,
and the second argument is the initial, possibly empty, working
memory.

*/

section;


/* TRACING UTILITIES */

;;; Define numbers for different divisors of psys_chatty, to give different
;;; kinds of tracing
lconstant
	INSTANCES = 2,
	WHERETESTS = 3,
	DATABASE = 5,
	APPLICABILITY = 7,
	APPLICABLE = 11,
	DATABASE_CHANGE = 13,
	SHOWRULES = 17,
;

;;; For getting word identifiers in pattern lists
define lconstant macro WID;
	[ ("ident %readitem()% ") ].dl
enddefine;


syscancel("rule");	;;; in case defined as a syntax word

define :define_form lconstant defaults;
;;; A syntax word for declaring global variables and specifying their
;;; default values.
	lvars identifier, value;
	dlocal prwarning = erase;
	itemread() ->;	;;; should be ";"
	repeat
		itemread() -> identifier;
	quitif(identifier = "enddefine");
		itemread() -> ;	 ;;;should be "="
		itemread() -> value;
		sysVARS(identifier, 0);
		sysGLOBAL(identifier);
		if isundef(valof(identifier)) then
			if isword(value) then valof(value) -> value endif;
			value -> valof(identifier)
		endif
	endrepeat
enddefine;


define :defaults;
	psys_chatty = false
		;;; If true =  print out rules. If a number then print more
		;;; see HELP * NEWPSYS for details

	psys_show_conditions = false
		;;; it true, show all conditions tested, including the outcome.

	psys_repeating = true
		;;; If true allow rule to be used twice on same data

	psys_walk = false
		;;; If true pause just after each rule is invoked.

	psys_allrules = false
		;;; If true, run all the rules that match. If 1 then run
		;;; only one of them, after sorting. If false just run first
		;;; one found that is applicable.

	psys_remember = false
		;;; If its a list add activated rules to the front of this

	psys_debugging = false
		;;; If true,  error messages are not suppressed

	psys_backtrack = false
		;;; If true, allows backtracking via "fail"

	psys_sortrules = false
		;;; If non-false,  it's a procedure that sorts rules
		;;; that are applicable. See HELP * NEWPSYS

	psys_recency =	false
		;;; If true, enables recording of recency of condition instances
		;;; in possibilities list given to psys_sortules

	psys_memlim = false
		;;; If an integer keep psys_database to this length

	psys_copy_modify = true
		;;; If made false, then "MODIFY" actions re-use database structures,
		;;; to reduce garbage collections. (risky)

	psys_get_input = false
		;;; If made true, then on each cycle check if there's a line of
		;;; input and if so add it to psys_database

	psys_explain_trace = true
		;;; if true then all [EXPLAIN ...] actions will be carried out

	psys_max_conditions = 30
	;;; maximum number of conditions in a rule

	psys_pausing = true
	;;; makes [PAUSE] action work
enddefine;


vars procedure psys_run;		;;; The top level procedure

/* UTILITIES */
define lconstant procedure psys_divides_chatty(int);
	;;; a utility for checking whether int divides psys_chatty
	lvars  int;
	isinteger(psys_chatty) and (psys_chatty mod int) == 0
enddefine;

define lconstant procedure psys_assoc(item, assoc_list);
	;;; given "b" and [a 1 b 2 c 3] this returns 2
	lvars item, assoc_list;
	until assoc_list == [] do
		if fast_front(assoc_list) == item then
			return(fast_front(fast_back(assoc_list)))
		else
			fast_back(fast_back(assoc_list)) -> assoc_list
		endif
	enduntil;
	false
enddefine;

define lconstant procedure psys_assoc_memb(item, assoc_list);
	;;; given "b" and [[a] 1 [b c] 2 d 3] this returns 2
	;;; given "d" and the above list it returns 3.
	lvars item, next, assoc_list;
	until assoc_list == [] do
		if item == (front(assoc_list) ->> next)
		or ispair(next) and lmember(item, next)
		then
			return(fast_front(fast_back(assoc_list)))
		else
			fast_back(fast_back(assoc_list)) -> assoc_list
		endif
	enduntil;
	false
enddefine;



/* FACILITIES FOR INSTANTIATING PATTERNS WITH VARIABLES */

/* Instantiation of query variables that are on popmatchvars
   and evaluation of [popval ...] and [apply ...] list elements.
*/

define lconstant procedure psys_has_variables(list) -> boole;
	;;; TRUE if the list contains "?" or "??" or a list starting with
	;;; "popval" or "apply"
	lvars item,list, boole = true;
	if atom(list) then false -> boole; return()
	elseif (front(list) ->> item) == "popval" then return()
	elseif item == "apply" then return()
	endif;
	repeat
		quitif(list == []);
		fast_front(list) -> item;
		if (item == "?" or item == "??") then
			if ispair(fast_back(list) ->> list)
			and fast_lmember(fast_front(list), popmatchvars)
			then return()
			endif
		elseif ispair(item) then
			if psys_has_variables(item) then return() endif
		endif;
		fast_back(list) -> list
	endrepeat;
	false -> boole
enddefine;

define lconstant procedure psys_dl(list);
	;;; put contents of list on stack, but for items preceded by
	;;; "?" put their value on the stack
	lvars item, list, var = false ;
	for item in list do
		if var then
			if lmember(item, popmatchvars) then
				valof(item);
				if var == 1 then dl() endif;
			else "?", item
			endif;
			false -> var
		elseif item == "?" then true -> var
		elseif item == "??" then 1 -> var
		else item
		endif
	endfor
enddefine;

vars procedure psys_value;		;;; defined below

section $-psys;

vars question, constraint, assertion, explanation;	;;; for matches

define $-psys_instance(Pattern) -> value;
	;;; Used to instantiate pattern, using current popmatchvars
	lvars item, Pattern, value, key, func;
	if isvector(Pattern) then psys_value(Pattern) -> value
	elseif atom(Pattern) then Pattern -> value
	elseif (front(Pattern) ->> key) == "popval" then
		popval(psys_instance(fast_back(Pattern))) -> value
	elseif key == "apply" then
		fast_back(Pattern) -> Pattern;
		if Pattern == [] then mishap(0, 'NOTHING AFTER "apply"')
		else
			recursive_valof(fast_destpair(Pattern) -> Pattern) -> func;
			if isprocedure(func) then
				func(psys_dl(psys_instance(Pattern))) -> value;
			else
				mishap(func::Pattern, 1, 'NO PROCEDURE(NAME) AFTER "apply"')
			endif
		endif
	elseif key == "READ" then
		;;; assertion element may include unbound uses of ANSWER
		back(Pattern) -> Pattern;
		procedure ();
			dlocal question, constraint, assertion, explanation;	;;; for matches

			if Pattern matches #_< [? ^WID question ?? ^WID constraint ? ^WID assertion ? ^WID explanation:isvector] >_#
			or Pattern matches #_< [? ^WID question ?? ^WID constraint ? ^WID assertion] >_#
			then
				[READ %psys_instance(question), dl(constraint), assertion,
					 if isvector(explanation) then explanation endif%] -> value

			else
				mishap(Pattern, 1, 'BAD "READ" ACTION FORMAT')
			endif
		endprocedure()
	else
		[%
			 until Pattern == [] do
				 front(Pattern) -> item;
				 if item == "?" then
					 back(Pattern) -> Pattern;
					 front(Pattern) -> item;
					 if lmember(item, popmatchvars) then
						 valof(item)
					 else
						 "?", item
					 endif
				 elseif item == "??" then
					 fast_back(Pattern) -> Pattern;
					 front(Pattern) -> item;
					 if lmember(item, popmatchvars) then
						 dl(valof(item))
					 else
						 "??", item
					 endif
				 elseif atom(item) then
					 item
				 else
					 psys_instance(item),
					 ;;; value left on stack
				 endif;
				 back(Pattern) -> Pattern;
			 enduntil
			 %] -> value
	endif
enddefine;

endsection;

define vars psys_value(Pattern) -> Pattern;
	;;; Used to evaluate a rule, or pattern, etc.
	;;; Don't instantiate if there are no variables or calls of Popval
	lvars Pattern;
	if isvector(Pattern) then
		{% appdata(Pattern, psys_value) %} -> Pattern
	elseif not(psys_copy_modify) or psys_has_variables(Pattern) then
		psys_instance(Pattern) -> Pattern
	endif;
enddefine;

define lconstant procedure psys_replace(item, value, list) -> list;
	;;; replace all occurrences of item with contents of value in list,
	;;; making a copy
	lvars element, item, value, list;
	[% fast_for element in list do
		if ispair(element) then psys_replace(item, value, element)
		elseif element == item then
			if islist(value) then dl(value) else value endif
		else element
		endif
		endfast_for %] -> list
enddefine;


/* END FACILITIES FOR INSTANTIATION */

/* NEWPSYS DATABASE FACILITIES
These mostly don't use "matches"  because it localises popmatchvars.
*/

global vars
	psys_database = [],
	psys_found,
	;

define lconstant procedure psys_truncate(list,num) -> list;
	;;; truncate list to length num
	lvars l = list, list, num;
	returnif(l == []);
	repeat;
		fast_back(l) -> l;
	returnif(l == []);
		num fi_- 1 -> num;
	quitif(num == 1)
	endrepeat;
	[] -> back(l);
	if psys_divides_chatty(DATABASE_CHANGE) then
		'Database truncated to ' sys_><  psys_memlim =>
	endif
enddefine;

define procedure psys_add(item);
	;;; add item to psys_database
	lvars item;
	dlocal psys_memlim;
	if psys_divides_chatty(DATABASE_CHANGE) then
		[Add ^item] ==>
	endif;
	conspair(item, psys_database) -> psys_database;
	if isinteger(psys_memlim) and psys_memlim fi_> 0 then
		psys_truncate(psys_database, psys_memlim) -> psys_database;
	endif;
enddefine;

define procedure psys_present(pattern);
	;;; Return first item in psys_database matching pattern, or false.
	;;; If something matches then assign it to psys_found
	;;; will set popmatchvars if anything matches
	lvars pattern, item;
	fast_for item in psys_database do
		if sysmatch(pattern,item) then
			item -> psys_found;
			return(item);
		endif;
	endfast_for;
	return(false)
enddefine;

lvars psys_recording = false;

define procedure psys_flush(pattern);
	;;; remove matching items, but don't expand popmatchvars outside this
	lvars item, pattern, next, temp, oldmatchvars = popmatchvars;
	dlocal popmatchvars;
	unless psys_copy_modify then
	[] -> psys_found;
		;;; delete all matching patterns, using old list links
	returnif(psys_database == []);
		;;; first delete from front of psys_database
		repeat
			oldmatchvars -> popmatchvars;
			fast_front(psys_database) -> item;
		quitunless(sysmatch(pattern, item));
			conspair(item, psys_found) -> psys_found;
			fast_back(psys_database) -> psys_database;
		returnif(psys_database == [])
		endrepeat;
		;;; Now delete any non-leading matching items
		psys_database -> temp;
		until (fast_back(temp) ->> next) == [] do
			fast_front(next) -> item;
			oldmatchvars -> popmatchvars;
			if sysmatch(pattern, fast_front(next)) then
				conspair(item, psys_found) -> psys_found;
				fast_back(next) -> fast_back(temp)
			else
				next -> temp
			endif
		enduntil
	elseif psys_present(pattern) then
		[] -> psys_found;
		;;; do the copying deletion.
		[%fast_for item in psys_database do
				 oldmatchvars -> popmatchvars;
				 if sysmatch(pattern, item) then
					 if psys_recording or psys_divides_chatty(DATABASE_CHANGE) then
						 conspair(item, psys_found) -> psys_found
					 endif
				 else
					 item
				 endif
			 endfast_for
			 %] -> psys_database
	endunless;
	if psys_divides_chatty(DATABASE_CHANGE) then
		'REMOVED' =>
		psys_found ==>
	endif;
enddefine;


define procedure psys_foreach(pattern, proc);
	;;; Apply proc for every match between pattern and a database item
	;;; use "matches" so that popmatchvars is restored each time
	lvars item, pattern, procedure proc;
	dlocal popmatchvars;	;;; don't extend popmatchvars
	fast_for item in psys_database do
		if item matches pattern then
			item -> psys_found;
			proc();
		endif;
	endfast_for;
enddefine;

/* END OF PSYS DATABASE FACILITIES */

/* FACILITIES FOR CHECKING THAT ALL CONDITIONS OF A RULE ARE SATISFIED */

define lconstant procedure psys_check_condition(pattern) -> boole;
	;;; Invoked when a condition starts with "WHERE"
	lvars pattern, boole, oldprmishap = prmishap, len;

	define dlocal prmishap(string, list);
		;;; treat an error as equivalent to false, unless debugging
		lvars string, list;
		if psys_debugging then oldprmishap(string, list)
		else false, exitfrom(psys_check_condition)
		endif
	enddefine;

	fast_back(pattern) -> pattern;
	if psys_has_variables(pattern) then
		psys_instance(pattern) -> pattern;
	endif;
	stacklength() -> len;
	popval(pattern) -> boole;
	unless stacklength() == len then
		oldprmishap -> prmishap;
		mishap(pattern, boole, 2, 'WHERE condition altered stack');
	endunless;
	if psys_show_conditions or psys_divides_chatty(WHERETESTS) then
		['Tested WHERE' ^pattern ] ==>
		['Result is:' ^boole] ==>
	endif;
enddefine;

vars procedure psys_forevery;	;;; defined below


define procedure psys_allpresent(patternlist) -> found;
	lvars patternlist, found;

	define lconstant procedure report_success(/* vec, num */);
		;;; return the items found.
		->; ->; 	;;; ignore vector and number
		ncrev(psys_found);
		exitfrom(psys_allpresent)
	enddefine;

	psys_forevery(patternlist, report_success);
	false -> found;
enddefine;

define procedure psys_implies(patternlist, pattern) -> boole;
	lvars patternlist, pattern, boole;

	define lconstant procedure test(/* vec, num */);
		;;; check that the pattern is also there
		->; ->; 	;;; ignore vector and number
		unless psys_present(pattern) then
			exitfrom(false, psys_implies)
		endunless;
	enddefine;

	psys_forevery(patternlist, test);
	true -> boole;
enddefine;


define vars psys_forevery(patternlist, proc);
	;;; Apply proc for every consistent match between patterns in patternlist
	;;; and a set of database items. Use sysmatch so that popmatchvars is
	;;; accessible for subsequent calls.
	;;; proc will be applied to the value of counter and patternlocations.
	lvars patternlist, procedure proc,
		start_data = psys_database, counter = 0, pattlist, foundname;

	;;; a vector to record age of items matched in database.
	lconstant patternlocations = initv(psys_max_conditions);

	dlocal psys_found = [], pop_=>_flag;

	define lconstant procedure psys_forevery_sub(patternlist);
		;;; uses proc and start_data non-locally
		lvars item, pattern, key, patternlist,
			oldmatchvars = popmatchvars, oldfound = psys_found;

		dlocal popmatchvars,		;;; re-set popmatchvars on exit
			counter,	;;; index into patternlocations
			psys_found,
			pop_=>_flag;

		if psys_show_conditions then
			'|' sys_>< pop_=>_flag -> pop_=>_flag;
		endif;

		define lconstant procedure isindata(patt);
			lvars item, patt, n;
			0 -> n;	;;; count along database
			fast_for item in start_data do
				n fi_+ 1 -> n;
				oldmatchvars -> popmatchvars;
				oldfound -> psys_found;
				if sysmatch(patt,item) then
					if psys_show_conditions then
						[SUCCESS ^item] ==>
					endif;
					conspair(item,psys_found) -> psys_found;
					;;; store location at which pattern found
					n -> subscrv(counter,patternlocations);
					psys_forevery_sub(patternlist);
				endif;
			endfor;
			if psys_show_conditions then
				[FAILED ^patt] ==>
			endif;
		enddefine;

		if patternlist == [] then
			if psys_show_conditions then
				'CONDITIONS SATISFIED: Variables bound:'=>
				unless null(popmatchvars) then
					pr(pop_=>_flag);
					lblock; lvars var;
						for var in popmatchvars do
							spr(var);spr("=");spr(valof(var));spr(";")
						endfor;
					endlblock;
					pr(newline);
				endunless
			endif;
			proc(patternlocations, counter);
		else
			counter fi_+ 1 -> counter;
			fast_destpair(patternlist) ->patternlist -> pattern;
			front(pattern) -> key;
			while key == "ALL" do
				;;; list [ALL ?patternlist] - splice them in

				destpair(fast_back(pattern)) -> pattern -> pattlist;
				unless pattlist == "?" then
					mishap(pattern,1,'"?" EXPECTED AFTER "ALL"')
				endunless;
				destpair(pattern) -> pattern -> pattlist;
				unless lmember(pattlist, popmatchvars) then
					mishap(pattlist, 1, 'UNBOUND AFTER "ALL"')
				endunless;
				valof(pattlist) -> pattlist;
				pattlist <> patternlist -> patternlist;
				fast_destpair(patternlist) ->patternlist -> pattern;
				front(pattern) -> key;
			endwhile;

			if key == "NOT" then
				fast_back(pattern) -> pattern;
				fast_for item in start_data do
					oldmatchvars -> popmatchvars;
					oldfound -> psys_found;
					if sysmatch(pattern,item) then
						;;; failed
						if psys_show_conditions then
							[FAILED [NOT ^^(psys_instance(pattern))]] ==>
						endif;
						return();
					endif;
				endfast_for;
				if psys_show_conditions then
					[SUCCESS [NOT ^^(psys_instance(pattern))]] ==>
				endif;
				;;; succeeded with negative condition
				0 -> subscrv(counter,patternlocations);
				oldmatchvars -> popmatchvars;
				psys_forevery_sub(patternlist)
			elseif key == "NOT_EXISTS" then
				fast_back(pattern) -> pattern;
				oldmatchvars -> popmatchvars;
				oldfound -> psys_found;
				if psys_allpresent(pattern) then
					;;; failed
					if psys_show_conditions then
						[FAILED [NOT_EXISTS ^^(psys_instance(pattern))]] ==>
					endif;
					return();
				elseif psys_show_conditions then
					[SUCCESS [NOT_EXISTS ^^(psys_instance(pattern))]] ==>
				endif;
				;;; succeeded with negative condition
				0 -> subscrv(counter,patternlocations);
				oldmatchvars -> popmatchvars;
				psys_forevery_sub(patternlist)
			elseif key == "IMPLIES" then
				;;; [IMPLIES <list of patterns> <pattern>]
				fast_back(pattern) -> pattern;
				oldmatchvars -> popmatchvars;
				oldfound -> psys_found;
				if psys_implies(dl(pattern)) then
					;;; success
					if psys_show_conditions then
						[SUCCESS [IMPLIES ^^(psys_instance(pattern))]] ==>
					endif;
					;;; succeeded so continue with rest
					0 -> subscrv(counter,patternlocations);
					oldmatchvars -> popmatchvars;
					psys_forevery_sub(patternlist)
				elseif psys_show_conditions then
					[FAILED [IMPLIES ^^(psys_instance(pattern))]] ==>
					return()
				endif;
			elseif key == "OR" then
				;;; It's a list of patterns. See if at least one works.
				lblock lvars patt;
					for patt in fast_back(pattern) do
						isindata(patt);
						;;; if it returns, that one is no good
					endfor;
				endlblock;
				if psys_show_conditions then
					[FAILED [^^pattern]] ==>
				endif;
				return ;;; failed
			elseif key == "WHERE" then
				oldmatchvars -> popmatchvars;
				if psys_check_condition(pattern) then
					;;; test succeeded, proceed with rest of patternlist
					0 -> subscrv(counter,patternlocations);
					psys_forevery_sub(patternlist)
					else
					return ;;; failed
					endif
				else
				isindata(pattern)
				endif
			endif
	enddefine;

	psys_forevery_sub(patternlist)
enddefine;
/* END FACILITIES FOR CHECKING CONDITIONS */

/* FACILITIES FOR DEFINING AND MANIPULATING RULES */

;;; Records for rules - name, conditions, actions
recordclass constant psysrule
	psys_rulename psys_conditions psys_actions psys_ruletype;

;;; Records for rule-activations. Each record contains
;;; The rule, the variables bound, the values, the record of
;;;		psys_found, and the recency information.

recordclass constant psysactivation
	psys_ruleof psys_varsof psys_valsof psys_foundof psys_recof;

;;; a list of rules, where each rule has elements
;;;		<name> <conditions> <actions>

global vars psys_rules; ;;; The rule base
if isundef(psys_rules) then [] -> psys_rules endif;

define procedure psys_rule_named(word) -> rule;
	;;; can have an optional list as second argument
	lvars rule, word, list;
	if islist(word) then word -> list; -> word
	else psys_rules -> list
	endif;
	fast_for rule in list do
		if psys_rulename(rule) == word then
			return();
		endif
	endfast_for;
	false -> rule;
enddefine;

define procedure psys_delete_rule(word, ruletype);
	lvars word, assoc_list = valof(ruletype), last, ruletype;
	if assoc_list == [] then
	elseif psys_rulename(fast_front(assoc_list)) == word then
		fast_back(assoc_list) -> valof(ruletype);
		return();
	else
		assoc_list -> last;
		fast_back(assoc_list) -> assoc_list;
		until assoc_list == [] do
			if psys_rulename(fast_front(assoc_list)) == word then
				fast_back(assoc_list) -> fast_back(last);
				return()
			else
				assoc_list -> last;
				fast_back(assoc_list) -> assoc_list
			endif
		enduntil;
	endif;
	mishap(word,1,'PSYS RULE NOT FOUND');
enddefine;



define procedure psys_pr_rule(rule);
	;;; can have an optional list as second argument
	;;; Prints a rule so that it can be re-compiled.
	lvars rule, word, list;
	if islist(rule) then rule -> list -> rule
	else psys_rules -> list
	endif;
	if isword(rule) then
		rule -> word;
		unless psys_rule_named(word, list) ->> rule then
			mishap(word,1,'NO SUCH RULE')
		endunless
	endif;
	pr('\ndefine :rule '); spr(psys_rulename(rule));
	spr('in'); spr(psys_ruletype(rule));
	applist(psys_conditions(rule), spr);
	pr(';\n\t');
	applist(psys_actions(rule), spr);
	pr('\nenddefine;')
enddefine;

define procedure psys_show_rules();
	;;; Display all rules
	lvars rule;
	applist(psys_rules, psys_pr_rule <> pr(%newline%));
enddefine;

/* SYNTAX FOR DEFINING OR CHANGING RULES */


define global procedure read_list_of_items() -> result;
	;;; Read in text items between "["... amd "]" but don't make
	;;; embedded lists. Used for reading actions
	lvars item, brackets = 0, result;
	readitem() -> item;
	if item == "[" then
		[%
			repeat
				readitem() -> item;
				if item == "[" or item == "{" then
					;;; keep a count of unquoted list or vector brackets
					brackets + 1 -> brackets;
					item;
					nextloop();
				elseif item == "]" and brackets == 0 then quitloop()
				elseif item == "]" or item == "}" then
					brackets - 1 -> brackets;
					if brackets < 0 then
						mishap(item, 1, 'UNEXPECTED CLOSING BRACKET')
					else
						item
					endif
				elseif item == """ then
					item,
					readitem();	;;; get quoted item.
					;;; Now check for closing quote
					readitem() ->> item;
					unless item == """ then
						mishap(item,1,'MISSING CLOSING WORD QUOTE "')
					endunless;
				elseif item == termin then
						mishap(0,'FOUND <termin>, MISSING "]"')
				else
					item
				endif
			endrepeat
		%] -> result;
	else
		;;; just return next item if it's not a list.
		item -> result;
	endif
enddefine;

;;; The next two procedures are user-assignable so that they can easily
;;; be replaced by checking versions.
define vars procedure psys_readcondition =
	listread(%%);
enddefine;

define vars procedure psys_readaction() -> action;
	;;; If changed by the user, then care is needed if POP11 actions are
	;;; to be supported.
	lvars action;
	;;; if the action type is POP11, read a list of text items.
	if hd(proglist) == "[" and hd(tl(proglist)) == "POP11" then
		read_list_of_items()
	else
	listread()
	endif -> action;

	if islist(action) and front(action) == "POP11"
	and action matches #_< [POP11 = = ==] >_#	;;; i.e. more than two elements
	then
		;;; the tail of the list is code for a procedure. Compile it and
		;;; replace the tail with a list containing only the compiled
		;;; procedure
		[POP11 ^(popval([procedure; ^^(back(action)) endprocedure]))]
			 -> action
	endif;
enddefine;

define vars psys_new_rule(name, conditions, actions, type);
	;;; if there's an existing rule in psys_rules with that name
	;;; change it, otherwise create a new one at the end.
	lvars name, conditions, actions, rule, type;
	psys_rule_named(name, valof(type)) -> rule;
	if rule then
		;;; rule already exists, so simply update it
		conditions -> psys_conditions(rule);
		actions -> psys_actions(rule);
	else
		;;; new rule, so append to the list
		valof(type) nc_<>
			[%conspsysrule(name, conditions, actions, type)%]
				-> valof(type)
	endif;
enddefine;

global vars psys_condition_terminators = [; ==> -->];

define :define_form rule;
	;;; read in rule of form
	;;; define :rule <name> <conditions>; <actions> enddefine;
	;;; where each condition and each action is a list, possibly
	;;; containing variables indicated by "?" and "??"
	lvars name, item, conditions, actions, rule, ruletype;
	readitem() -> name;
	unless isword(name) then
		mishap(name,1,'WORD NEEDED FOR NAME OF RULE')
	endunless;
	if pop11_try_nextreaditem("in") then
		readitem()
	else
		"psys_rules"
	endif -> ruletype;

	unless isword(ruletype) and islist(valof(ruletype)) then
		mishap(name, ruletype, 2, 'INVALID RULE TYPE IN RULE DEFINITION')
	endunless;

	[%
		repeat
			psys_readcondition() -> item;
		quitif(lmember(item, psys_condition_terminators));
			unless islist(item) then
				mishap(item,1,'EACH CONDITION MUST BE A LIST. END WITH A TERMINATOR')
			endunless;
			item
		endrepeat;
	%] -> conditions;

	[%
		repeat
			psys_readaction() -> item;
		quitif(item == "enddefine");
			unless islist(item) then
				mishap(item,1,'EACH ACTION MUST BE A LIST. END WITH enddefine')
			endunless;
			item
		endrepeat;
	%] -> actions;

	sysPUSHQ(name);
	sysPUSHQ(conditions);
	sysPUSHQ(actions);
	sysPUSHQ(ruletype);
	sysCALL("psys_new_rule")
enddefine;



/* END OF FACILITIES FOR RULES */

/* FACILITIES FOR TRACING AND INTERACTING */

define vars psys_print_menu(question, options);
	;;; a list of question items and a list of options
	lvars item, question, options;
	spr('**');
	if isstring(question) then pr(question)
	else applist(question, spr);
	endif;
	for item in options do
		pr(newline);
		pr(front(item)); spr(":");
		applist(back(item), spr)
	endfor;
	pr('\nPlease select response by typing in item in first column.\n');
enddefine;

define vars psys_istraced =
	newproperty([], 100, false, true);
	;;; A property to store information about which rules are to be traced
enddefine;

define psys_trace(list);
	lvars word, list;
	for word in list do
		true -> psys_istraced(word)
	endfor;
enddefine;

define psys_untrace(list);
	lvars word, list;
	if list = "all" or list = #_< [all] >_# then
		newproperty([], 100, false, true) -> psys_istraced
	else
		for word in list do
			false -> psys_istraced(word)
		endfor
	endif
enddefine;

define psys_trace_rule(rule_instance, instantiate);
	;;; Print out a rule instance
	;;; If instantiate is true then instantiate.
	lvars rule_instance, instantiate, name, actions, conditions,
		rule=psys_ruleof(rule_instance);
	dlocal cucharout = charout;	;;;;; till bug in ==> is fixed.

	destpsysrule(rule) -> /*type*/; -> actions -> conditions -> name;
	if instantiate then
		psys_value(actions) -> actions;
	endif;
	pr(newline);
	[RULE INSTANCE ^name] =>
	[CONDITIONS ^conditions] ==>
	[MATCHED ^(psys_foundof(rule_instance))] ==>
	[ACTIONS ^actions] ==>
enddefine;

psys_trace_rule(%false%) -> class_print(psysactivation_key);

define psys_displayrule(action, rule_instance);
	;;; The action has already been instantiated
	lvars action, rule_instance;
	[^action 'is an action of the rule'] ==>
	psys_trace_rule(rule_instance, false);
	pr(newline);
enddefine;

define psys_expound();
	;;; "why" has just been typed
	lvars rule_instance;
	if ispair(psys_remember) then
		'Previous rule was' =>
		destpair(psys_remember) -> psys_remember-> rule_instance;
		psys_trace_rule(rule_instance, true)
	else
		'No more reasons, sorry' =>
	endif
enddefine;


section $-psys;

vars key, rest;	;;; needed for matches, in next procedure

define $-psys_interact(message, action, rule_instance, accept_empty) -> answer;
	lvars message, action, rule_instance, accept_empty, answer,
		first = true;
	lconstant options = [why show data trace untrace chatty walk stop];

	dlocal pop_pr_quotes = false;

	dlocal key, rest;	;;; needed for matches

	define lconstant display_help(empty_allowed);
		lvars item, empty_allowed;
		pr('\n-------------------------------------\nPlease type one of:\n');
		if empty_allowed then spr('     RETURN,') endif;
		for item in options do
			pr("."); pr(item);spr(",")
		endfor;
		pr('OR :<pop-11 command>\n-------------------------------------\n')
	enddefine;

	repeat
		if isprocedure(message) then message()
		elseunless message == [] or message = nullstring then
			message ==>
		endif;
		readline() -> answer;
	returnif(accept_empty and answer == []);
		if answer matches #_< [: ?? ^WID rest] >_# then
			;;; it's a Pop-11 command
			[%popval(rest)%] -> answer;
			unless answer == [] then
				popval([^^answer =>])
			endunless
		elseif answer matches #_< [. ? ^WID key ?? ^WID rest] >_# then
			if key == "show" then
				psys_displayrule(action, rule_instance)
			elseif key == "why" then
				if first then
					false -> first;
					if isvector(last(action)) then
						;;; It's a "canned" explnation
						appdata(last(action),
							procedure(item); lvars item;
								if isword(item) then spr(valof(item))
								elseif islist(item) then spr(psys_value(item))
								else spr(item)
								endif
							endprocedure);
						pr(newline)
					else
						psys_displayrule(action, rule_instance)
					endif
				else
					;;; display previous rules
					psys_expound();	;;; alters psys_remember non-locally
				endif
			elseif key == "data" and rest == [] then
				'DATABASE is' =>
				psys_database ==>
			elseif key == "data" then
				'DATA ITEMS' =>
				psys_foreach(rest, procedure; psys_found ==> endprocedure)
			elseif key == "stop" then
				'Stopping' =>
				exitto(psys_run)
			elseif key == "trace" then
				psys_trace(rest)
			elseif key == "untrace" and rest = #_< [all] >_# then
				psys_untrace("all");
				false -> psys_walk;
			elseif key = "untrace" then
				psys_untrace(rest)
			elseif key == "show_conditions" and rest == [] then
				true -> psys_show_conditions
			elseif key == "show_conditions" then
				popval(rest) -> psys_show_conditions
			elseif key == "chatty" and rest == [] then
				true -> psys_chatty
			elseif key == "chatty" then
				popval(rest) -> psys_chatty
			elseif key == "walk" and rest == [] then
				true -> psys_walk
			elseif key == "walk" then
				popval(rest) -> psys_walk
			else
				display_help(false);
			endif
		elseif accept_empty then
				display_help(true);
		else return()
		endif
	endrepeat
enddefine;

endsection;

define psys_walk_trace(rule_instance, action);
	lvars rule_instance, action,
		rule = psys_ruleof(rule_instance),
		name = psys_rulename(rule);

	dlocal psys_remember, pop_readline_prompt = 'Walking> ';

	if psys_walk or psys_istraced(name) then
		psys_interact(
		[['Doing RULE' ^name] [ACTION ^action] ],
				action, rule_instance, true) ->
	endif;
enddefine;

/* END FACILITIES FOR TRACING AND INTERACTING */

/* FACILITIES FOR READ and MENU ACTIONS AND INTERACTION */

vars procedure psys_do_action;	;;; defined below

;;; The next procedure currently handles both READ and MENU actions.
;;; They should be separated out.


section $-psys;

;;; The following dynamic variables are needed in the next procedure
vars Pmessage, Pconstraint, P_act, P_item, P_test, P_rest, ANSWER;

define $-psys_read_and_add(action, rule_instance, with_menu);
	;;; Handle "READ" and "MENU" actions.
	lvars action, rule_instance, oldvars = popmatchvars, with_menu,
		options, mappings, rule = psys_ruleof(rule_instance);

	;;; All the following must be dynamic locals
	dlocal Pmessage, Pconstraint = #_< [==] >_#,
		P_act, P_item, P_test, P_rest, ANSWER;

	dlocal psys_remember, popmatchvars;	;;; may be altered by psys_interact

	if with_menu then
		action --> #_< [MENU ? ^WID Pmessage:isvector ?? ^WID P_rest] >_#;
	else
		action --> #_< [READ ? ^WID Pmessage ?? ^WID P_rest] >_#;
	endif;

	if isvector(last(P_rest)) then
		;;; It's an explanation: ignore it here.
			allbutlast(1,P_rest) -> P_rest;
	endif;

	last(P_rest) -> P_act;

	if with_menu then
		[OR ^(applist(Pmessage(2), front))] -> Pconstraint;
		if datalength(Pmessage) == 3 then
			Pmessage(3)
		else
			false
		endif -> mappings;
		psys_print_menu(%Pmessage(1), Pmessage(2)%) -> Pmessage;
	else
		if length(P_rest) == 2 then
			front(P_rest) -> Pconstraint
		endif
	endif;

	repeat
		psys_interact(Pmessage, action, rule_instance, false) -> ANSWER;
		if ANSWER matches Pconstraint
		or	(Pconstraint matches #_< [ : ? ^WID P_test] >_# and length(ANSWER) ==1
			and valof(P_test)(front(ANSWER)))
		or (Pconstraint matches #_< [LOR ?? ^WID P_test] >_# and member(ANSWER,P_test))
		or (Pconstraint matches #_< [OR ?? ^WID P_test] >_#
			and ANSWER matches #_< [? ^WID P_item] >_#
			and member(P_item,P_test))
		then
			if with_menu then
				front(ANSWER) -> ANSWER;
				if mappings then
					psys_assoc_memb(ANSWER, mappings) -> P_item;
					if P_item then P_item -> ANSWER endif;
					;;; otherwise use original ANSWER
				endif;
				if P_act matches #_< [? ^WID P_item] >_# then
					psys_do_action(
						psys_value(psys_replace("ANSWER", ANSWER, P_item)),
						rule, rule_instance)
				else
					psys_assoc_memb(ANSWER, P_act) -> P_item;
					if P_item then
						psys_do_action(psys_value(P_item), rule, rule_instance)
					else
						mishap(ANSWER,action,2, 'NO ACTION FOR ANSWER TYPED')
					endif
				endif
			elseunless P_act == [] then
				psys_do_action(
						psys_value(psys_replace("ANSWER", ANSWER,P_act)),
						rule, rule_instance)
			endif;
			return()
		else [^ANSWER does not match ^Pconstraint] =>
		endif;
	endrepeat
enddefine;

endsection;

/* END FACILITIES FOR READ and MENU ACTIONS */


/* FACILITIES FOR FINDING APPLICABLE RULES */

define lconstant procedure not_rule_done(rule, found) -> boole;
	;;; rule is the current rule being tested, found is the value of
	;;; psys_found after matching against the database.
	;;; This is invoked only if psys_repeating is false
	lvars rule, found, boole;

	define lconstant procedure same_set(l1, l2) -> boole;
		;;; all of l1 in l2 using fast_lmember
		lvars item, l1, l2, boole;
		fast_for item in l1 do
			unless fast_lmember(item, l2) then
				false -> boole;
				return()
			endunless;
		endfast_for;
		true -> boole
	enddefine;

	lblock lvars rule_instance;
	fast_for rule_instance in psys_remember do
		if psys_ruleof(rule_instance) == rule and
			same_set(psys_foundof(rule_instance), found)
		then
			if psys_divides_chatty(APPLICABILITY) then
				['Already done' ^(psys_rulename(rule))] ==>
			endif;
			false -> boole;
			return
		endif
	endfor;
	endlblock;
	true -> boole
enddefine;


define procedure psys_applicable(rules) -> possibles;
	;;; Given a list of all the rules, return a list of possible
	;;; activations. A possible activation is a record containing
	;;; a rule all of whose conditions are satisfied, a list of the
	;;; variables bound, a list of the values, a list of matching
	;;; database items, and if psys_recency is true, a recency record
	;;; - otherwise an empty vector
	lvars rule, rules, possibles, name, conditions, actions,
		ruletype, values;

	define lconstant record_rule_instance(patternlocations, counter);
		;;; Invoked when all conditions of a rule are satisfied.
		;;; Save rule, bound variables and values, for each match
		;;; If psys_recency is true, then the recency values are also saved
		;;; patternlocations and counter come from psys_forevery
		lvars patternlocations, counter, rule_instance,
			bindings = maplist(popmatchvars, valof);
		if psys_repeating
		or not_rule_done(rule, psys_found)	;;; uses global psys_remember
		then
			conspsysactivation(
				rule, popmatchvars, bindings, rev(psys_found),
				if psys_recency then
					lblock lvars n;
					{%fast_for n to counter do
							 fast_subscrv(n, patternlocations)
					 endfor%}
					endlblock;
				else #_< {} >_#
				endif) -> rule_instance;

			rule_instance;

			if psys_divides_chatty(APPLICABILITY)
			or psys_istraced(psys_rulename(rule))
			then
				'FOUND RULE WITH SATISFIED CONDITIONS' =>
				rule_instance ==>
			endif;

			unless psys_backtrack or psys_allrules  then
				exitto(psys_applicable)	;;; i.e. leave get_rules
			endunless;
		elseif psys_divides_chatty(APPLICABILITY) then
			['Rule already done previously'
				^rule
				[' With conditions matching :'^psys_found]
			] ==>
		endif;
	enddefine;

	define lconstant get_rules();
		fast_for rule in rules do
			[] -> popmatchvars;
			destpsysrule(rule) -> ruletype -> actions -> conditions -> name;
			if psys_show_conditions or psys_divides_chatty(APPLICABILITY) then
				['Checking conditions for:' ^name in ^ruletype] =>
				conditions ==>
			endif;
			psys_forevery(conditions, record_rule_instance)
		endfast_for
	enddefine;

	[% get_rules() %] -> possibles
enddefine;

/* END FACILITIES FOR FINDING APPLICABLE RULES */

/* FACILITIES FOR DOING THE ACTIONS OF RULES */

lconstant
	procedure psys_do_rule;		;;; defined below

;;; The next two must be non-local for state-saving and back-tracking
;;; Make them lvars eventually.
lvars psys_statestack = [],
	psys_possibles;

define global vars procedure psys_action_type =
	newproperty([], 50, false, true)
enddefine;


define lconstant procedure psys_DEL(item, foundlist);
	;;; for use in DEL or REPLACE actions.
	;;; item is an integer or database item, foundlist is a list of
	;;; database items.
	lvars item, foundlist;
	if islist(item) then psys_flush(item)
	elseif isinteger(item) then
		if listlength(foundlist) fi_< item then
			mishap(0, 'Not enough items for DEL ' sys_>< item)
		else
			psys_flush(foundlist(item))
		endif
	else
		mishap(item, 1, 'WRONG ARGUMENT FOR DEL OR REPLACE')
	endif
enddefine;


define lconstant procedure psys_MODIFY(modlist, foundlist);
	;;; modlist is what followed [MODIFY .. It should start with
	;;; either an integer n, or a pattern, followed by attribute
	;;; value pairs.
	;;; Remove the nth item of foundlist from psys_database, and
	;;; replace it with a modified version where the item following
	;;; key is the value. If psys_copy_modify is false then the
	;;; replacement is non-constructive, but modified items are
	;;; brought to the front of the database
	lvars n, key, value, foundlist, modlist, next;

	dlocal psys_found = [], psys_recording = true; ;;; for psys_flush

	destpair(modlist) -> modlist -> n;

	unless (listlength(modlist) mod 2) == 0 then
		mishap(modlist, 1, 'MODIFY list has wrong number of elements')
	endunless;

	if isinteger(n) then psys_DEL(n, foundlist) else psys_flush(n) endif;
	;;; things deleted will now be in psys_found

	if psys_copy_modify then
		lblock lvars list;
		fast_for list in psys_found do
			;;; do substitution, and then add to database
			[% until list == [] do
					 if back(list) == [] then
						fast_front(list);
						quitloop()
					 endif;
					 front(list) -> next;
					 if psys_assoc(next, modlist) ->> value then
						 next, value,
						 fast_back(list) -> list;	;;; ignore next element of list
					 else next
					 endif;
					 back(list) -> list;
				 enduntil %] -> list;

			psys_add(list)
		endfor;
		endlblock;
		sys_grbg_list(psys_found);
	else
		lblock lvars list;
		repeat
		quitif(psys_found == []);
			sys_grbg_destpair(psys_found) -> psys_found -> list;	;;; danger
			;;; Add to database and then do destructive substitution
			setfrontlist(list, psys_database) -> psys_database;
			until list == [] do
				fast_front(list) -> next;
				if psys_assoc(next, modlist) ->> value then
				quitif(fast_back(list) == []);
					fast_back(list) -> list;	;;; ignore next element of list
					value -> fast_front(list);
				endif;
				fast_back(list) -> list;
			enduntil;
		endrepeat
		endlblock;
	endif;
enddefine;


section $-psys;

vars rest; ;;; needed in next procedure, for matcher

define $-psys_push_or_pop(list, pushing);
	lvars list, item, stackname, pushing, stack;
	lconstant pattern = [0 ?? ^WID rest];
	dlocal rest, popmatchvars = [];
	if pushing then
		unless length(list) == 2 then
			mishap(list,1,'WRONG ARGUMENTS FOR PUSH')
		endunless;
		dl(list) -> stackname -> item;
	elseunless length(list) == 1 then
		mishap(list,1,'WRONG ARGUMENTS FOR POP')
	else
		front(list) -> stackname
	endif;
	stackname -> fast_front(pattern);
	psys_present(pattern) -> stack;
	unless islist(stack) then mishap(list, 1, 'NO SUCH STACK') endunless;
	setfrontlist(stack, psys_database) -> psys_database;
	if psys_copy_modify then
		;;; get rid of previous one.
		fast_back(psys_database) -> psys_database;
		if pushing then
			psys_add([^stackname ^item ^^rest])
		else
			if rest == [] then mishap(stackname, 1, 'NOTHING TO POP')
			else psys_add([^stackname ^^(back(rest))])
			endif
		endif
	else
		;;; destructive modification. Item already at front of list
		if pushing then
			conspair(item, back(stack)) -> fast_back(stack)
		else
			back(back(stack)) -> fast_back(stack)
		endif
	endif
enddefine;


vars name, conds, acts, ruletype; ;;; needed for patterns, in next procedure

define lconstant psys_make_rule(list);
	;;; Needed for actions of type RULE. Unlike normal rule definitions,
	;;; this kind of rule puts new actions at the begining of psys_rules.
	lvars list, rule;
	dlocal name, conds, acts, ruletype;
	if list matches #_< [TYPE ? ^WID ruletype:isword ==] >_# then
		fast_back(fast_back(list)) -> list
	else
		"psys_rules" -> ruletype
	endif;

	if list matches #_< [? ^WID name:isword ? ^WID conds:islist ? ^WID acts:islist] >_# then
		psys_rule_named(name) -> rule;
		if rule then
			psys_new_rule(name, conds, acts, ruletype)
		else
			conspsysrule(name, conds, acts, ruletype)
				:: valof(ruletype) -> valof(ruletype)
		endif
	else
		mishap(list, 1, 'INCORRECT FORMAT FOR "RULE"')
	endif
enddefine;

vars Pname;		;;; needed for patterns in next procedure

define $-psys_save_or_restore(action, list);
	;;; For [SAVE ...] or [RESTORE ...] actions
	lvars action list;
	dlocal Pname;

	lconstant	Dpattern = [DATA ? ^WID Pname ==],
				Rpattern = [RULES ? ^WID Pname ==];

	until list == [] or back(list) == [] do
		if list matches Dpattern then
			if action == "SAVE" then
				psys_database -> valof(Pname);
			else /* action == "RESTORE" */
				valof(Pname) -> psys_database
			endif
		elseif list matches Rpattern then
			if action == "SAVE" then
				psys_rules -> valof(Pname);
			else /* action == "RESTORE" */
				valof(Pname) -> psys_rules
			endif
		endif;
		fast_back(fast_back(list)) -> list
	enduntil
enddefine;

endsection;

lvars psys_failed;	;;; can be set true in psys_do_action

lvars
	current_rule, rule_instance;	;;; used by psys_do_action and psys_eval

define vars psys_do_action(action, current_rule, rule_instance);
	lvars rest, key, action, action_procedure;
	dlocal current_rule, rule_instance;

	psys_value(action) -> action;	;;; does nothing if no variables
	destpair(action) -> rest -> key;

	;;; Do "walking: pause if necessary
	psys_walk_trace(rule_instance, action);

	if (psys_action_type(key) ->> action_procedure) then
		;;; User-defined action, so do it. (It could be a procedure name)
		recursive_valof(action_procedure)(rule_instance, action)
	elseif key == "MODIFY" then
		;;; rest should be a list starting with item to be
		;;; modified then a set of key value pairs
		psys_MODIFY(rest, psys_foundof(rule_instance));
	elseif key == "NOT" then
		if psys_divides_chatty(DATABASE_CHANGE) then
			[Remove ^^rest] ==>
		endif;
		psys_flush(rest);
	elseif key == "DEL" then
		if rest == [] then
			mishap(current_rule,1,'NO NUMBER GIVEN IN DEL ACTION')
		endif;
		lblock lvars num;
		fast_for num in rest do
			unless isinteger(num) then
				mishap(action,2, 'DEL not followed by integer')
			else
				psys_DEL(num, psys_foundof(rule_instance))
			endunless
		endfor
		endlblock;
	elseif key == "REPLACE" then
		psys_DEL(front(rest), psys_foundof(rule_instance));
		psys_add(front(fast_back(rest)))
	elseif key == "PUSH" then
		;;; [PUSH <item> <stackname>]
		psys_push_or_pop(rest, true)
	elseif key == "POP" then
		;;; [POP <stackname>]
		psys_push_or_pop(rest, false)
	elseif key == "STOP" then
		if rest /== [] then rest ==> endif;
		exitto(psys_run)
	elseif key == "ADDALL" then
		applist(rest, psys_add)
	elseif key == "RULE" then
		psys_make_rule(rest);
	elseif key == "SAVE" or key == "RESTORE" then
		;;; save or restore rules, or data
		psys_save_or_restore(key, rest)
	elseif key == "NULL" then ;;; do nothing
	elseif key == "POP11" then
		;;; next item should be a pop procedure or its name. Run it.
		apply(recursive_valof(front(rest)))
	elseif key == "SAY" then
		rest ==>
	elseif key == "EXPLAIN" then
		if psys_explain_trace then
			rest ==>
		endif
	elseif key == "FAIL" then
		if rest /== [] then rest ==> endif;
		if psys_statestack == [] then
			[CANNOT FAIL - State Stack Empty] =>
		else
			explode(destpair(psys_statestack) -> psys_statestack)
				-> psys_database -> psys_possibles;
		endif;
		true -> psys_failed;
		exitfrom(psys_do_rule);
	elseif key == "PAUSE" then
		if psys_pausing then
			;;; wait for user to press return
			psys_read_and_add(#_< [READ '' [==] []] >_#, rule_instance, false)
		endif
	elseif key == "READ" then
		psys_read_and_add(action, rule_instance, false)
	elseif key == "MENU" then
		psys_read_and_add(action, rule_instance, true)
	else
		psys_add(action)
	endif;
enddefine;

define psys_eval(action);
	;;; user interface to psys_do_acition
	lvars action;
	psys_do_action(action, current_rule,rule_instance);
enddefine;

define psys_eval_list(actions);
	;;; user interface to psys_do_acition
	lvars action, actions;
	for action in actions do
		psys_do_action(action, current_rule,rule_instance);
	endfor
enddefine;



define lconstant procedure psys_do_actions(rule_instance);
	;;; This runs the actions of a particular rule rule_instance
	lvars
		 current_rule = psys_ruleof(rule_instance),
		 actions = psys_actions(current_rule),
		 bindings = psys_valsof(rule_instance),
		 rule_instance;

	dlocal popmatchvars = psys_varsof(rule_instance), psys_found;


	;;; Setup environment for actions
	lblock lvars var, val;
		for var,val in popmatchvars, bindings do
			val -> valof(var)
		endfor;
	endlblock;

	if psys_divides_chatty(SHOWRULES) and not(psys_walk) then
		[['Doing RULE' ^(psys_rulename(current_rule))] [ACTIONS ^actions]] ==>
	endif;

	lblock lvars action;
		for action in actions do
			psys_do_action(action, current_rule, rule_instance)
		endfor
	endlblock;

enddefine;

define lconstant procedure psys_do_rule(rule_instance, number);
	;;; A rule has been selected from the list of pssibilities
	;;; Set up the environment for the rule and run it.
	lvars rule, rule_instance, bindings, name, instances, number;
	dlocal popmatchvars, psys_found;
	psys_ruleof(rule_instance) -> rule;

	psys_rulename(rule) -> name;

	;;; Check that the conditions are still valid, if necessary

	if number /== 1 and (psys_allrules or psys_backtrack)
	then
		if psys_divides_chatty(APPLICABILITY) or psys_istraced(name) then
			['Checking if rule' ^name 'is still applicable'] =>
		endif;
		lblock lvars item;
			psys_foundof(rule_instance) -> psys_found;
			fast_for item in psys_found do
				unless fast_lmember(item, psys_database) then
					if psys_divides_chatty(APPLICABILITY) or psys_istraced(name) then
						[^name 'inapplicable' ^item 'missing'] ==>
					endif;
				return()
				endunless;
			endfast_for
		endlblock
	endif;
	if psys_divides_chatty(APPLICABILITY) or psys_istraced(name) then
		[^name 'Is still applicable'] =>
	endif;
	;;; All conditions found still true, so
	psys_do_actions(rule_instance);
	if psys_remember or not(psys_repeating) then
		;;; used for "why" questions, and for checking repetitions
		conspair(rule_instance, psys_remember) -> psys_remember
	elseunless psys_backtrack or isinheap(psys_sortrules)
	or psys_allrules == true
	then
		;;; restore re-usable list cells.
		sys_grbg_list(psys_varsof(rule_instance));
		sys_grbg_list(psys_valsof(rule_instance));
		sys_grbg_list(psys_foundof(rule_instance))
	endif;
enddefine;

define lconstant procedure psys_do_rules(rules) ;
	;;; find applicable rules and run them (or it)
	lvars rule_instance, rules, counter = 0;
	dlocal psys_possibles,
		psys_failed = false; 	;;; possibly set in psys_do_rule

	psys_applicable(rules) -> psys_possibles;

	if psys_divides_chatty(APPLICABLE) then
		'Possible rules before sorting' =>
		psys_possibles ==>
	elseif psys_chatty then
		['Possible rules' ^(applist(psys_possibles, psys_ruleof <> psys_rulename))] ==>
	endif;

	;;; Sort possible rule instances. Perhaps should be done every
	;;; time round the until loop below?
	if isprocedure(psys_sortrules) then
		psys_sortrules(psys_possibles) -> psys_possibles;
		if psys_divides_chatty(APPLICABLE) then
			'Rules after sorting' =>
			maplist(psys_possibles, psys_ruleof <> psys_rulename) ==>
		endif
	endif;


	if psys_possibles == [] then
		'NO MORE RULES APPLICABLE' =>
		exitto(psys_run)
	else
		until psys_possibles == [] do
			counter fi_+ 1 -> counter;
			if isinheap(psys_sortrules) and not(psys_backtrack) then
				destpair
			else
				sys_grbg_destpair
			endif(psys_possibles) -> psys_possibles -> rule_instance;
			if psys_backtrack then
				;;; remember where to come back to. FAIL, exits back here
				conspair({^psys_possibles ^psys_database}, psys_statestack)
					-> psys_statestack;
			endif;
			psys_do_rule(rule_instance, counter);

			if psys_get_input and sys_input_waiting(popdevin) then
				pr(newline);
				psys_add(readline())
			endif;
		nextif(psys_backtrack and psys_failed);
		quitif(not(psys_allrules) or psys_allrules == 1)
		enduntil
	endif;
enddefine;

/* END FACILITIES FOR DOING THE ACTIONS OF RULES */

/* THE TOP LEVEL */

define vars psys_finish(rules, data);
	lvars rules, data;
	;;; A user defineable procedure that takes the rules and the
	;;; data when psys_run is finished.
	;;; The default version does nothing.
enddefine;

define vars psys_run(psys_rules, psys_database);
	dlocal psys_rules, psys_remember, psys_statestack = [],
		psys_database,		;;;  = [], should it be initialised each time?
		prwarning = erase,	;;; prevent "declaring variable" messages
		popautolist = [];	;;; prevent autoloading in popval

	;;; test that the two arguments are proper lists.
	listlength(psys_rules) ->;
	listlength(psys_database) ->;

	;;; check that psys_repeating and psys_copy_modify are not both
	;;; false
	if not(psys_repeating) and not(psys_copy_modify) then
		'PSYS_REPEATING is false, so PSYS_COPY_MODIFY is being set true' =>
		true -> psys_copy_modify
	endif;
	if psys_backtrack and not(psys_copy_modify) then
		'PSYS_BACKTRACK is true, so PSYS_COPY_MODIFY is being set true' =>
		true -> psys_copy_modify
	endif;

	;;; Initialise psys_remember
	if psys_remember or not(psys_repeating) then [] -> psys_remember endif;

	procedure();
		;;; run a procedure, so that exitto psys_run comes out of this
		repeat
			[] -> popmatchvars;
			if psys_divides_chatty(DATABASE) then
				'DATABASE' =>
				psys_database ==>
			endif;
			psys_do_rules(psys_rules);
			if not(psys_repeating) and psys_divides_chatty(INSTANCES) then
				[RULES_DONE ^(applist(psys_remember, psys_ruleof))] ==>
			endif;
		endrepeat;
	endprocedure();
	;;; perform user-definable cleanup action
	chain(psys_rules,psys_database, psys_finish);
enddefine;

global vars newpsys = true;	;;; for "uses"

endsection;


/* --- Revision History ---------------------------------------------------
--- John Gibson, Mar 10 1993
		Fixed missing ^WID before Pname in patterns in psys_save_or_restore
		and restored some procedures to vars.
--- John Gibson, Oct 29 1992
		Made define_defaults lconstant. Put all vars needed for matching
		in section psys.
--- John Williams, Oct  6 1992
	New version with Aaron's last two fixes installed at Sussex.
--- Aaron Sloman Sep 22 1992
	Fixed case of action [POP11 <pop11 instructions> by replacing
	listread with read_list_of_items
--- Aaron Sloman and Luc Beaudoin, Sep 19 1992
	Made current_rule and rule_instance in psys_do_action accessible
	to define interface procedures psys_eval and psys_eval_list
--- Andreas Schoter, Sep  9 1991
	Changed occurrances of -popliblist- to -popautolist-
--- Simon Nichols, Aug 23 1991
		Fixed definition of -psys_readcondition-, making it a closure and
		therefore having writeable pdprops (see bugreport isl.fr-4377).
--- Aaron Sloman, Jun  2 1991
	Inserted compile_mode declaration. Required subsequent changes
--- Aaron Sloman, Jun  7 1990
	Used #_< ... >_# to make sure patterns were constants.
--- Aaron Sloman, Mar 22 1990
	Added IMPLIES and NOT_EXISTS conditions and did considerable
		reorganisation of this and the HELP file.
	Added POP11 actions
	Changed the prompt when psys_walk is true.
--- Aaron Sloman, Feb 19 1990
	Put in some more lblocks.
--- Aaron Sloman, Feb 18 1990
	Slightly re-ordered, to prevent "declaring variable" messages.
--- Aaron Sloman, Feb 18 1990
	Added psys_show_conditions for extra debugging information, and
		updated help file accordingly.
	Re-implemented [PAUSE] actions as equivalent to trivial READ
	actions, so that interactive commands can be used during pauses.
--- Aaron Sloman, Jan 31 1990
	Added psys_pausing and [PAUSE] actions. (Used in TEACH PSYSRIVER)
--- Aaron Sloman, Jan 18 1990
	Added missing lvars declarations.
--- Aaron Sloman, Jan 11 1990
	Improved the implementation of "ALL" conditions. Now finds all cases.
	Added SAVE and RESTORE actions for rules and data.
	Introduced rulesets and extended the rule record structure. Had
	to fix some  procedures.
	Speeded up rule compilation by using nc_<>
	Allowed RULE actions to specify the ruleset.
--- Aaron Sloman, Jan 10 1990
	Added an extra type field to rules, and extended define :rule to
	cope with rule-types.
--- Aaron Sloman, Jan 10 1990
	Added psys_allpresent and the "ALL" type condition. Not sure the
	design is right yet (for supporting meta-level reasoning).
--- Aaron Sloman, Jan  7 1990
	Added MENU actions (still a bit of a mess)
	Separated out procedure psys_do_action.
--- Aaron Sloman, Jan  6 1990
	Added PUSH and POP actions.
--- Aaron Sloman, Jan  6 1990
	Added [OR ... ] conditions
	Allowed [MODIFY .. ] to have multiple key-value pairs
	Added help option to psys_interact
	Fixed bugs to do with psys_copy modify.
	Added [apply func args ...] option.
	Put pattern variables into local nested procedure for READ actions.
	Added "number" argument to psys_do_rule
--- Aaron Sloman, Jan  4 1990
	Changed psys_interact to require commands to start with "." or ":"
--- Aaron Sloman, Jan  3 1990
	Added psys_get_input option for asynchronous interaction.
--- Aaron Sloman, Jan  2 1990
	Fixed READ actions that call popval in the assertion
--- Aaron Sloman, Jan  1 1990
	Introduced [RULE ...] type action.
	Declared many of the procedures lconstant.
	Fixed bug in use of sys_grbg_list, and allowed "data <pattern>" as
		an interactive option.
	Changed not_rule_done to use psys_remember
--- Aaron Sloman, Jan  1 1990
	Added to the options for psys_chatty, and reduced unwanted trace
	printing.
--- Aaron Sloman, Dec 27 1989
	Slightly improved format of psys_trace_rule, printout, and made it
		the class_print procedure for psysactivations
	Added extra calls of sys_grbg_destpair where they appear to be safe.
	Added extra action type ADDALL
	Un-commented psys_foreach. It was useful for TEACH PSYSRIVER
	Slightly improved trace printing for rules
	Added NULL actions, e.g. for printing or other routines.
	Allowed conditions and actions to be separated by anything in
		psys_condition_terminators. Unfortunately a semi_colon is
		needed for ved_lcp, etc to work (unless redefined).
 */
