/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:           $poplocal/local/newkit/prb/lib/poprulebase.p
 > Purpose:        Production system interpreter. POPRULEBASE Version 6
 > Author:         Aaron Sloman October 1994 (see revisions)
 					Revisions for Version 2 by Darryl Davis, June 1995
					Revisions for Version 3 by Aaron Sloman, Jan 1996
					Revisions for Version 4 by Aaron Sloman, Apr 1996
					Revisions for Version 5 by Aaron Sloman, Jul 1999
					Version 6 (with INDATA) by Aaron Sloman, Jul 2000
					Further revisions at end.
 > Documentation:
		SEE HELP * NEWKIT for changes in Version 5.
 			HELP * POPRULEBASE, TEACH * RULEBASE, HELP * RULESYSTEMS,
			TEACH * POPRULEBASE, * PRBWINE, * PRBRIVER,
			TEACH * EXPERTS * SIM_DEMO (needs LIB * SIM_AGENT)
			HELP * PRB_EXTRA

		NEWS file: HELP PRB_NEWS
 >  Related Files:
		LIB RULESYSTEMS, SETP_RULESETS, * PRB_EXTRA, * SIM_AGENT
	Older, more primitive, libraries:
			LIB * PSYS, LIB * PRODYSYS, LIB * NEWPSYS
 */

/*

CONTENTS:

 -- VERSION SPEC
 -- LIBRARIES REQUIRED
 -- TRACING UTILITIES
 -- DEFAULTS FOR GLOBAL VARIABLES
 -- USER DEFINABLE TRACE PROCEDURES
 -- GENERAL UTILITIES
 -- -- Utilities concerned with variables in patterns
 -- Version of sysmatch for tracing in prb_forevery
 -- POPRULEBASE DATABASE FACILITIES (prb_add, prb_present, etc.)
 -- Database - related utilities
 -- FACILITIES FOR INSTANTIATING PATTERNS
 -- RECORD CLASS FOR RULES
 -- RECORD CLASS FOR RULE-ACTIVATIONS
 -- FACILITIES FOR CHECKING THAT ALL CONDITIONS OF A RULE ARE SATISFIED
 -- -- prb_forevery
 -- FACILITIES FOR DEFINING AND MANIPULATING RULES
 -- Stuff for reading in lexical variables in patterns
 -- -- User-definable procedures for reading conditions and actions
 -- readaction
 -- FACILITIES FOR TRACING AND INTERACTING
 -- FACILITIES FOR FINDING APPLICABLE RULES
 -- -- prb_applicable
 -- FACILITIES FOR DOING THE ACTIONS OF RULES
 -- -- Property for mapping keywords to action types
 -- -- Autoloadable action types
 -- -- Other action types defined here
 -- -- Template for new action types
 -- -- prb_do_action
 -- -- prb_do_rule_actions
 -- THE TOP LEVEL FACILITIES FOR prb_run
 -- -- prb_do_rules
 -- -- prb_finish
 -- -- prb_run
 -- VERSION 5 July 1999
 -- VERSION 4 (V4.5)
 -- VERSION 4 (V4.1)
 -- VERSION 3 (V3.4)
 -- VERSION 2
 -- VERSION 1
 -- PROCEDURE INDEX. Access using "ENTER g define"

*/

/*
This is a Production system interpreter

It uses this format for defining rules:

	define :rule <name> weight <weight> in <ruleset>
		<conditions>  ;
		<actions>
	enddefine;

which means that VED's commands for the "current procedure" will work,
E.g. <ENTER> mcp, jcp, lcp (See HELP * MARK)

The "in <ruleset>" component is optional, in which case <ruleset> defaults
to prb_rules. For more details see HELP * POPRULEBASE

The "weight <weight>" component is also optional.

A typical call of the system looks like:
		prb_run(rules, data);

or
		prb_run(rules, data, N);

Where -rules- is a list of rules of the form described below,
and the second argument is the initial, possibly empty, working
memory. N, the optional third argument is an integer specifying
the maximum number of cycles allowed, or false, implying no limit.

*/

section;

compile_mode:pop11 +strict;

;;; compile_mode:pop11 +varsch +defpdr -lprops +constr +global :vm +prmfix :popc -wrdflt -wrclos;

/*
-- VERSION SPEC
*/

;;; Version is a list, with major version name, and date last changed
global constant prb_version = ['V6.0' '00.08.12'];

/*
-- LIBRARIES REQUIRED
*/

;;; Next two needed for reading in patterns with lvars
#_INCLUDE '$usepop/pop/lib/include/pop11_flags.ph'
#_INCLUDE '$usepop/pop/lib/include/vm_flags.ph'


uses prblib;

include WID


uses readpattern;	;;; provides word_of_ident property, "!", and other things.

uses int_parameters;	;;; provides pop_max_int, pop_min_int

syscancel("rule");	;;; in case defined as a syntax word


/*
-- TRACING UTILITIES
*/

;;; This should go into a .ph file to be "included".

;;; Define numbers for different divisors of prb_chatty, to give different
;;; kinds of tracing
lconstant
	INSTANCES = 2,
	WHERETESTS = 3,
	DATABASE = 5,
	APPLICABILITY = 7,
	APPLICABLE = 11,
	DATABASE_CHANGE = 13,
	SHOWRULES = 17,
	TRACE_WEIGHTS = 19,
;

;;; This is used as error string when popautolist is supposed to
;;; have been saved but has not been
lvars savedautolist = 'NO AUTOLIST SAVED';



/*
-- DEFAULTS FOR GLOBAL VARIABLES
*/

;;; First some procedures used to define the "define :defaults" syntax

define lconstant try_set_default(varval, newval, word);
	;;; try_set_default takes current and new values for word
	lvars varval, newval, word;

	if isundef(varval) then newval -> valof(word) endif;
enddefine;

define :define_form lconstant defaults;
	;;; A syntax word for declaring global variables and specifying their
	;;; default values.
	;;; Used below as define :defaults ...

	lvars identifier, value;

	dlocal prwarning = erase;

	pop11_need_nextreaditem(";") ->;

	;;; repeatedly read <identifier> = <expression> ;
	;;; Use the expression to set up the default for the identifier
	repeat
		;;; read the identifier
		itemread() -> identifier;
	quitif(identifier = "enddefine");
		pop11_need_nextreaditem("=") ->;
		;;; plant code to declare the identifier, and push its current value
		sysVARS(identifier, 0);
		sysGLOBAL(identifier);
		sysPUSH(identifier);
		;;; Plant code to compute the default value
		pop11_comp_expr();
		pop11_need_nextreaditem(";") ->;
		;;; Push the identifier itself, then call the setting procedure
		sysPUSHQ(identifier);
		sysCALLQ(try_set_default);
	endrepeat
enddefine;


define :defaults;

	prb_chatty = false;
		;;; If true =  print out rules. If a number then print more
		;;; see HELP * POPRULEBASE for details

	prb_show_conditions = false;
		;;; if true, show all conditions tested, including the outcome.

	prb_show_ruleset = false;
		;;; if true, show name of ruleset, where possible

	prb_repeating = true;
		;;; If true allow rule to be used twice on same data

	prb_walk = false;
		;;; If true pause just after each rule is invoked.

	prb_allrules = false;
		;;; If true, run all the rules that match. If 1 then run
		;;; only one of them, after sorting. If false just run first
		;;; one found that is applicable.

	prb_remember = false;
		;;; If its a list add activated rules to the front of this

	prb_debugging = true;
		;;; If true,  error messages are not suppressed

/*
;;; Disabled July 1995
	prb_backtrack = false;
		;;; If true, allows backtracking via "fail"
*/

	prb_sortrules = false;
		;;; If non-false,  it's a procedure that sorts rules
		;;; that are applicable. See HELP * POPRULEBASE

	prb_useweights = false;
		;;; If true, do final sorting of rules according to weight

	prb_recency =	false;
		;;; If true, enables recording of recency of condition instances
		;;; in possibilities list given to prb_sortrules

	prb_copy_modify = true;
		;;; If made false, then "MODIFY" actions re-use database structures,
		;;; to reduce garbage collections. (risky) Also "RMODIFY"

	prb_get_input = false;
		;;; If made true, then on each cycle check if there's a line of
		;;; input and if so add it to prb_database

	prb_explain_trace = true;
		;;; if true then all [EXPLAIN ...] actions will be carried out

	prb_max_conditions = 30;
	;;; maximum number of conditions in a rule

	prb_pausing = true;
	;;; makes [PAUSE] action work

	prb_sayif_trace = [];
	;;; a list of conditions for SAYIF actions

	;;; prb_prwarning = sysprwarning
	prb_prwarning = erase;
	 ;;; Make that different if undeclared variables are to be announced.

	prb_default_rule_weight = pop_min_int;
	;;; default weight

	;;; the default ruleset
	;;; a list of rules, where each rule is an instance of prbrule
	prb_rules = [];

	;;; the current rulefamily, or false
	prb_current_family = false;

	;;; its name, or false
	prb_family_name = false;


	;;; The maximum likely number of keys for the database.
	prb_max_keys = 64;


/*
	;;; Disabled for hashed databases
	prb_memlim = false;
		;;; If an integer keep prb_database to this length
		;;; No longer used in here with hash table changes
*/

	;;; make this true if you want each rule to have its current
	;;; section recorded, and then reinstated at run time.
	;;; controls IFSECTIONS
	prb_use_sections = false;

	;;; make this true to ensure that prb_flush records things removed,
	;;; etc
	prb_recording = false;

	;;; record items found in database when searching
	prb_found = false;

	;;; record whether a runnable rule was found in prb_run
	prb_rule_found = false;

	;;; Control IFTRACING. Make this false before compiling, to turn
	;;; off various kinds of tracing.
	prb_tracing_on = true;

	;;; make this true to turn on the "self tracing" procedures.
	;;; this can be done before or after compiling
	prb_self_trace = false;

	;;; If this is false, use of a query variable that is already
	;;; declared as global will leave it as a global, not a lexical
	;;; variable.
	prb_force_lvars = true;

	;;; If this is true, then unrecognized action types are
	;;; treated as database items to be added. Otherwise
	;;; only [ADD ..] actions will cause additions and
	;;; actions with no recognized keyword will cause an error.
	prb_auto_add = true;

	;;; If this is made true then when a ruleset changes a message
	;;; will be printed. This may be useful for tracing changes between
	;;; rulesets within a rulefamily. See the procedure prb_ruleschanged_trace
	prb_trace_ruleschanged = false;
enddefine;

;;; These must come AFTER declarations of prb_tracing_on and prb_use_sections
include IFTRACING
include IFSECTIONS

;;; The next two global variables must always have properties
;;; as values

;;; The current database, a property mapping keys to lists of items
global vars procedure prb_database;

;;; The name to ruleset mapping in the current rulefamily.
global vars procedure prb_current_rule_prop;

;;; Declare exported procedures [may not be complete]
global vars procedure (
	prb_value,
	prb_instance,
	prb_do_action,
	prb_run,
	prb_present,
	prb_newdatabase,
	prb_print_table,
	prb_print_database,
	prb_run_with_matchvars,
	prb_add,
	prb_new_rule,
	prb_forevery,
);

global constant procedure (
	prb_rule_named,
);

;;; This is used in the sim_agent library
global vars prb_actions_run = false;

;;; Allow name of current ruleset to be accessed where available
global vars prb_ruleset_name = false;


/*

-- USER DEFINABLE TRACE PROCEDURES

For machine-readable tracing:
(human-readable tracing is produced by "prb_show_conditions" etc.)

These procedures will do nothing if
	prb_self_trace = false;
*/

define vars procedure prb_checking_conditions_trace(agent, ruleset, rule);
	;;; agent will be the current value of sim_myself
	;;; invoked when about to check conditions, before call of prb_forevery

enddefine;

define vars procedure prb_checking_one_condition_trace(agent, condition, rule);
	;;; invoked in prb_forevery_sub just before the condition is processed
enddefine;

define vars procedure prb_all_conditions_satisfied_trace(agent, ruleset, rule, matchedvars);
	;;; invoked if all conditions satisified.
	;;; matchedvars is the list of variables bound
enddefine;

define vars procedure prb_condition_satisfied_trace(agent, condition, item, rule, matchedvars);
	;;; invoked when one condition is satisified. matchedvars is the list of variables bound
	;;; if the condition is a simple pattern, then item will be the item in the
	;;; database that matched it. Otherwise item may be undef.
enddefine;

define vars procedure prb_doing_actions_trace(agent, ruleset, rule_instance);
	;;; agent will be the current value of sim_myself
	;;; invoked when about to run actions of rule after conditions checked

enddefine;

define vars procedure prb_do_action_trace(agent, action, rule_instance);
	;;; invoked in prb_do_action with each individual action
    ;;; just before it is performed.
enddefine;

define vars procedure prb_adding_trace(agent, item);
	;;; adding item to the current database
enddefine;

define vars procedure prb_deleting_trace(agent, item);
	;;; deleting one item from the current database
enddefine;

define vars procedure prb_deleting_pattern_trace(agent, deleted, pattern);
	;;; Deleting everything that matches the pattern, e.g. prb_flush
	;;; deleted is a list of the items deleted. May not be available if
	;;; the global variable prb_recording is false (the default)
enddefine;

define vars procedure prb_modify_trace(agent, item, action, rule_instance);
	;;; action is a list of form [MODIFY <item> <key> <value> <key> <value> ...]
	;;; where <item> should refer to item, though it may be a number
enddefine;

define vars procedure prb_pattern_matched_trace(agent, pattern, item);
	;;; not yet used
enddefine;


define vars procedure prb_condition_failed_trace(agent, condition, rule);
enddefine;


/*
-- GENERAL UTILITIES
*/

define global vars procedure prb_divides_chatty(int) /* -> boolean */;
	;;; a utility for checking whether int divides prb_chatty
	isinteger(prb_chatty) and (prb_chatty fi_mod int) == 0 /* -> boolean */;
enddefine;


;;; The next line can be changed for debugging
global constant procedure prb_member = fast_lmember;
;;; global constant procedure prb_member = lmember;

/*
;;; for popindex and sourcefile
define global constant procedure prb_member(item, list)
enddefine;

*/

define prb_assoc(item, assoc_list);
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

/*
The following property maps identifiers onto the corresponding words
and the class_print for idents is change to show the word
*/

/*
;;; now done in lib readpattern, compiled in advance.

define global vars word_of_ident = newproperty([],64, false, "tmparg")
enddefine;

global vars pop_oc_print_level;	;;; for objectclass instances

define vars print_ident(id);
	;;; User definable procedure for printing identifiers. Can be changed
	;;; according to context.
	dlocal pop_pr_level = 3, pop_oc_print_level = 3;

    lvars word;
    if isproperty(word_of_ident) and (word_of_ident(id)->>word) then
        printf('<ID %p %p>', [%word, idval(id)%])
    else
        printf('<ident %p>', [%idval(id)%])
    endif
enddefine;

define vars sys_print_ident(id);
	;;; call user-definable procedure
	print_ident(id)
enddefine;

sys_print_ident -> class_print(ident_key);
*/

/*
identof("ident_key") =>
identof("sqrt") =>
"sqrt" -> word_of_ident(identof("sqrt"));
identof("sqrt") =>
*/

/*
-- -- Utilities concerned with variables in patterns

*/

define lconstant procedure prb_has_variables(list) -> boole;
	;;; TRUE if the list contains "?" or "??" followed by a variable
	;;; in popmatchvars (which can therefore be instantiated) or a list
	;;; starting with "popval" (or "$$") or "apply" (or "$:")

	lvars item,list, boole = true;

	;;; first deal with simple cases
	if atom(list) then
		false -> boole; return()
	elseif (fast_front(list) ->> item) == "popval" or item == "$$"
		or item == "apply" or item == "$:" or item == "VAL"
	then return()
	endif;
	;;; Now search down the list for variables or patterns with variables
	repeat
		quitif(list == []);
		fast_front(list) -> item;
		if (item == "?" or item == "??") then
			unless popmatchvars == [] then
				;;; is this followed by a variable in popmatchvars
				if ispair(fast_back(list) ->> list)
				and fast_lmember(fast_front(list), popmatchvars)
				then return()
				endif
			endunless
		elseif ispair(item) then
			;;; recursively check the list
			if prb_has_variables(item) then return() endif
		endif;
		fast_back(list) -> list
	endrepeat;
	false -> boole
enddefine;

define lconstant procedure prb_no_variables(list) -> boole;
	;;; Return true if the list has no variables that the matcher
	;;; can set and no "=" or "==" pattern elements.
	;;; Then at most one match in the database should be possible.
	lvars item, list, boole ;

	if atom(list) then
		true -> boole;
		return()
/*
	Remove this. It causes patterns containing "==" or "=" not to be
	classified correctly.
	elseif popmatchvars == [] then
		true -> boole;
		return()
*/
	else
		;;; Now search down the list for variables or patterns with variables
		repeat
		quitif(list == []);
			fast_front(list) -> item;
			if (item == "=" or item == "==") then
				false -> boole; return;
			elseif (item == "?" or item == "??") then
				;;; is this followed by a variable in popmatchvars
				if ispair(fast_back(list) ->> list) then
					unless fast_lmember(fast_front(list), popmatchvars) then
						;;; variable found, and not in popmatchars
						false -> boole; return
					endunless;
				endif
			elseif ispair(item) then
				;;; recursively check the list
				unless prb_no_variables(item) then
					false -> boole; return()
				endunless
			endif;
			fast_back(list) -> list
		endrepeat;
		;;; no variables found
		true -> boole
	endif
enddefine;


define prb_variables_in(list, varlist, VARlist) -> (varlist, VARlist);
	;;; list is a list of conditions or a list of actions.
	;;; varlist is a list of the variables found so far, to which new ones
	;;; should be added. VARlist is a list of the VARS and LVARS variables

	;;; Return the variables following "?" or "??" in list. Exclude those in
	;;; VARlist, and any that are [VARS...] or [LVARS ....] forms, adding
	;;; the latter to VARlist. Add the variables to varlist
	;;; May be words or identifiers.
	;;; Return a list of the variables found and a list of those in
	;;; [VARS ..] or [LVARS ..] forms
	lvars item, list, var, VARlist ;

	if atom(list) then
		return()
	else
		;;; Now search down the list for variables or patterns with variables
		repeat
		quitif(list == []);
			fast_front(list) -> item;
			if item == "WHERE" or item == "POP11" then
				return
			elseif item == "VARS" or item == "LVARS" then
				;;; add the variables to VARlist
				for item in fast_back(list) do
					unless isprocedure(item) then
						unless fast_lmember(item, VARlist) then
							conspair(item, VARlist) -> VARlist
						endunless
					endunless
				endfor;
				return();
			elseif (item == "?" or item == "??") then
				if ispair(fast_back(list) ->> list) then
					unless fast_lmember((fast_front(list) ->> var), varlist)
					or fast_lmember(var, VARlist)
					then
						;;; new variable found,
						conspair(var, varlist) -> varlist
					endunless;
				endif
			elseif ispair(item) then
				;;; recursively check the list
				prb_variables_in(item, varlist, VARlist) -> (varlist, VARlist);
			endif;
			fast_back(list) -> list
		endrepeat;
	endif
enddefine;

/*
untrace prb_variables_in;
prb_variables_in([a ?b [[c ??d] ?c [e ?f ?c] ?g]],[],[]) =>
prb_variables_in([a ?b [[c ??d] ?c [e ?f ?c] ?g]],[b x],[y g]) =>
prb_variables_in([a ?b [[c ??d] ?c [e ?f ?c] ?g]],[],[g]) =>
prb_variables_in([a ?b [[c ??d] ?c [e ?f ?c] ?g]],[d],[g]) =>
prb_variables_in([[a ?b] [LVARS d e] [[c ??d] ?c [e ?f ?c] ?g]],[b x],[y g]) =>


*/

define prb_extend_popmatchvars(list, matchvars) -> matchvars;
	lvars item;
	fast_for item in list do
		unless fast_lmember(item, matchvars) then
			conspair(item, matchvars) -> matchvars
		endunless
	endfor
enddefine;
/*
prb_extend_popmatchvars([], [a b c d])=>
prb_extend_popmatchvars([a d e], [a b c d])=>
prb_extend_popmatchvars([a b d e f], [a b c d])=>

*/

/*
-- Version of sysmatch for tracing in prb_forevery
*/

global vars
	;;; Two global variables available while rules are being
	;;; checked, etc.
	this_rule, this_rule_name,

	;;; This one made true in get_rules, inside prb_applicable,
	;;; if conditions are to be shown. It is controlled by prb_show_conditions
	showing_conditions = false,

	;;; let the matcher know if checking conditions
	checking_conditions = false;
;


global vars do_trace_match;

;;; User can set this true before compiling poprulebase
if isundef(do_trace_match) then false -> do_trace_match endif;

;;; Save original sysmatch
constant procedure old_sysmatch;

if do_trace_match then
	if isundef(old_sysmatch) then sysmatch -> old_sysmatch endif;
endif;

;;; prepare to redefine it
sysunprotect("sysmatch");

global vars procedure sysmatch;

/*
Define a property for storing information about matches.
For each rulename associate an association list with it of
	the following form:

[
  <object_name>
	[ {<pattern> <numtried> <numsucceeded>}
	  {<pattern> <numtried> <numsucceeded>}
	...
	]

  <object_name>
	[ {<pattern> <numtried> <numsucceeded>}
	  {<pattern> <numtried> <numsucceeded>}
	...
	]
 ]

Where
	<object_name>
		is the name of the object in whose context the rule is invoked
	<pattern>
		is one of the patterns in the conditions in the rule
	<numtried>
		is the number of occasions on which attempts were made to
		match that pattern
	<numsucceeded> is the number of occasions on which the match
		was successful.
*/


global vars sim_myself;	;;; set in sim_agent

;;; A procedure which works if sim_agent is loaded, otherwise
;;; just returns "noname".
lvars procedure sim_object_name =
	procedure(agent);
		if identprops("sim_agent") == undef then
			"noname"
		else
			;;; replaces itself with sim_name, when first run
			valof("sim_name") -> sim_object_name;
			sim_object_name(agent)
		endif
	endprocedure;


;;; 128 is a guess at the likely number of rules. Increase if necessary
;;; system table starts with that number of words.
global vars procedure trace_match_prop = newproperty([], 128, false, "perm");

define global constant procedure trace_match(Patt, Datum) -> result;
	;;; this replaces sysmatch, and keeps records of matches
	;;; succeeding and failing.
	;;; don't trace recursive calls
	dlocal sysmatch = old_sysmatch;

	if do_trace_match and checking_conditions then
		;;; In prb_forevery
		lvars
			myname = sim_object_name(sim_myself),
			rule_info = trace_match_prop(this_rule_name),
			obj_info = false,
			patt_info = false,
			;

		unless rule_info then
			;;; initialise the record for this rule
			{^(copylist(Patt)) 0 0} -> patt_info;
			[^patt_info] -> obj_info;
			[^myname ^obj_info]
				->> rule_info -> trace_match_prop(this_rule_name);
		endunless;
		;;; rule_info must be defined now
		unless obj_info then
			prb_assoc(myname, rule_info) -> obj_info;
			unless obj_info then
				{^(copylist(Patt)) 0 0} -> patt_info;
				[^patt_info] -> obj_info;
				[^myname ^obj_info ^^rule_info]
					->> rule_info -> trace_match_prop(this_rule_name);
			endunless;
		endunless;
		;;; rule_info and obj_info must be defined now
		unless patt_info then
			lvars vec;
			for vec in obj_info do
				if Patt = fast_subscrv(1, vec) then
					vec -> patt_info;
					quitloop();
				endif;
			endfor;
			unless patt_info then
				{^(copylist(Patt)) 0 0} -> patt_info;
				;;; make this the front of the list of obj_info
				copy(obj_info) -> fast_back(obj_info);
				patt_info -> fast_front(obj_info);
			endunless;
		endunless;
		;;; increment tried count
		fast_subscrv(2,patt_info) fi_+ 1 -> fast_subscrv(2,patt_info);
		old_sysmatch(Patt, Datum) -> result;
		if result then
			;;; increment success count
			fast_subscrv(3,patt_info) fi_+ 1 -> fast_subscrv(3,patt_info);
		endif;
	else
		;;; outside prb_forevery
		old_sysmatch(Patt, Datum) -> result
	endif;
enddefine;


define global vars show_trace_match(rules);
	;;; rules can be
	;;;		false (show everything)
	;;;		a rule name (show information about patterns in that rule)
	;;;		a list of rule names (show information about patterns in those rules)
	if isword(rules) then
		[^rules] -> rules;
	endif;
	if islist(rules) then
		lvars name;
		for name in rules do
			[Patterns in ^name] =>
			trace_match_prop(name) ==>
			nl(1)
		endfor
	else
		appproperty(trace_match_prop,
			procedure(name, info);
				[Patterns in ^name] =>
				info ==>
				nl(1)
			endprocedure)
	endif
enddefine;

define clear_trace_match();
	clearproperty(trace_match_prop)
enddefine;

if do_trace_match then
	trace_match -> sysmatch;
else
	identfn -> trace_match_prop;
	applist([trace_match trace_match_prop show_trace_match clear_trace_match],
		syscancel);
	sysgarbage();
endif;

define prb_forget_rules();
	;;; Used to clear memory of remembered rule instances, e.g.
	;;; when changing rulesets
	
	if ispair(prb_remember) then sys_grbg_list(prb_remember) endif;

	[] -> prb_remember
enddefine;

/*
-- POPRULEBASE DATABASE FACILITIES (prb_add, prb_present, etc.)

As of Wed Jun 21 16:55:56 BST 1995 prb_database makes use of hash tables
produced by newproperty and so ensures smaller databases to search, in
most cases.

N.B. Poprulebase uses prb_database, not database. prb_database must
be a property.

The procedures mostly don't use "matches"  because it localises popmatchvars.
Instead use sysmatch. popmatchvars then has to be manipulated explicitly,
with values localised and carefully restored after backtracking in
prb_forevery.
*/

define global vars procedure prb_newdatabase(hashlen, userlist) -> procedure newdb;

	;;; given an integer and a default list of database items
	;;; return a database
	;;; Possible third argument, name, is a name for the property
	lvars name = false;

	if isword(userlist) then
		hashlen, userlist -> (hashlen, userlist, name)
	endif;

	lvars
		item, hashkey,
		revlist = rev(userlist),	;;; insert things in reverse order
		procedure newdb=newproperty([],hashlen,[],"perm");

	if name then name -> pdprops(newdb) endif;

	;;; can't use fast_ procedures as list is user-supplied
	fast_for item in revlist do
		front(item) -> hashkey;
		conspair(item, newdb(hashkey)) -> newdb(hashkey);
	endfor;
	sys_grbg_list(revlist);
enddefine;

;;; set up default database
if isundef(prb_database) then
	prb_newdatabase(prb_max_keys, []) -> prb_database;
endif;

section $-prb;
global vars
	;;; Two words used as database keys by procedures for pushing
	;;; and popping rulesets and data, in LIB * PRB_EXTRA
	rulestackkey = "'PRB#RULE#STACK'",
	datastackkey = "'PRB#DATA#STACK'",

	;;; List of keys in prb_database to be ignored by normal
	;;; database operations.
	private_keys = [^rulestackkey ^datastackkey];
endsection;


define prb_empty(dbtable) /* -> boolean */;
	;;; return true if there's nothing in the table, otherwise false
	lvars dbtable;

	fast_appproperty(
		dbtable,
		procedure(/* key,value */); /* lvars key, value; */
			;;; ignore value
			-> ;
			unless fast_lmember(/* key */, $-prb$-private_keys) then
				false; exitfrom(prb_empty)
			endunless
		endprocedure);

	return(true)
enddefine;

define global constant procedure prb_database_keys(dbtable) /* -> keys */;
	;;; Given a database, return a list of keys. (Optimised for frequent use)

	lvars dbtable, /* keys */;

	;;; Make a list of the keys in the property, except for those in
	;;; private_keys
	[%
	  fast_appproperty(
		dbtable,
		procedure(/*key,val*/);
			lvars /* key, val*/ ;
			;;; ignore val, leaving key on the stack
			-> ;			
			if fast_lmember(dup(), $-prb$-private_keys) then
				-> ;	;;; remove the key
			endif;
		endprocedure
		);
	%] /* -> keys */
enddefine;

global vars prb_noprint_keys = [];

define global vars procedure prb_print_table(dbtable, /*keys*/);
	;;; Print all the sub-databases in the table
	;;; Allow optional second argument, a list of keys to use
	lvars
		dbtable, key, keys;

	if islist(dbtable) then
		;;; optional list of keys provided
		dbtable -> (dbtable, keys);
	else
		sort(prb_database_keys(dbtable)) -> keys;
		;;; Printing can cause context switching. Don't try to GC keys ???
		;;; dlocal 0 % ,if dlocal_context < 3 then sys_grbg_list(keys) endif%;
	endif;

	if keys = [] then
		[] =>
	else
		;;; Print items separately, grouped by common key
		lvars found = false;
		fast_for key in keys do
			unless fast_lmember(key, prb_noprint_keys) then
				dbtable(key) ==>
				true -> found;
			endunless;
		endfor;
		unless found then
			;;; for backward compatibility with previous version without
			;;; prb_noprint_keys.
			[]=>
		endunless;
	endif

enddefine;


define global vars procedure prb_print_database();
	if isword(pdprops(prb_database)) then
		printf(pdprops(prb_database), '** DATABASE %p:')
	else
		'DATABASE' =>
	endif;
	dlocal pop_=>_flag = '   ';
	prb_print_table(prb_database);
enddefine;


/*

-- Database - related utilities

*/

define prb_add_db_to_db(db1, db2, /*copying*/);
	;;; This has an optional third argument, a boolean, with default true

	;;; Add all items of db1 to db2, and if copying is false use
	;;; nc_<>, which will corrupt db1.

	lvars db1, db2, copying, procedure targetdb;

	if isboolean(db2) then
		;;; Third argument provided
		db2 -> copying;
		db1 -> db2;
			-> db1;
	else
		true -> copying
	endif;
	db2 -> targetdb;	;;; use procedure variable for speed
	
	if copying then
		fast_appproperty(
			db1,
			procedure(key,val);
				lvars key, val;
				unless fast_lmember(key, $-prb$-private_keys) then
					val <> targetdb(key) -> targetdb(key);
				endunless
			endprocedure
		);
	else
		;;; Should this be fast_appproperty? (No, it changes db1 ??)
		appproperty(
			db1,
			procedure(key,val);
				lvars key, val;
				unless fast_lmember(key, $-prb$-private_keys) then
					val nc_<> targetdb(key) -> targetdb(key);
				endunless;
			endprocedure
		);
	endif
enddefine;



define global constant procedure prb_is_var_key(key);
	;;; Return true if the key is a variable, otherwise false
	;;; This procedure will need to be changed if the pattern
	;;; matcher is changed so as to allow new sorts of pattern elements
	lvars key;
	fast_lmember(key, #_< [ ? = ?? ==] >_# )
enddefine;

;;; A pattern that should never match anything in the database
lvars nokey_pattern = ['Non-key-string'];

define lconstant procedure prb_instantiate_first(patt) -> patt;
	;;; For pattern starting with a variable. Just instantiate
	;;; that variable, if it is in popmatchvars, and return new patt.
	;;; Otherwise return false.
	lvars patt, key, var;

	if ispair(back(patt)) then
		fast_destpair(fast_destpair(patt)) -> (key,var,patt);
		if key == "?" and fast_lmember(var, popmatchvars) then
			if front(patt) == ":"
			and valof(front(back(patt)))(valof(var))
			then conspair(valof(var), patt)
			else nokey_pattern
			endif
		elseif key == "??" and fast_lmember(var, popmatchvars) then
			if front(patt) == ":"
			and valof(front(back(patt)))(valof(var))
			then valof(var) <> patt
			else nokey_pattern
			endif
		else
			false
			;;;mishap(patt, 1, 'PATTERN WITH CONSTANT FIRST ITEM NEEDED')
		endif;
	else false
	endif -> patt
enddefine;

define global vars procedure prb_match_apply_keys(dbtable, pattern, keys, proc);
	;;; Apply the procedure proc to every item in dbtable starting with
	;;; one of the keys, which matches the pattern.
	;;; See note about popmatchvars in next procedure
	lvars
		item, pattern,
		procedure(proc,dbtable) pattern,
		oldmatchvars = popmatchvars,
		key, keys;

	fast_for key in keys do
		fast_for item in dbtable(key) do
			oldmatchvars -> popmatchvars;
			if sysmatch(pattern, item) then proc(item) endif
		endfor
	endfor
enddefine;

define global vars procedure prb_match_apply(dbtable, pattern, proc);
	;;; Apply the procedure proc to every item in dbtable matching
	;;; the pattern. Note that this can set popmatchvars as it
	;;; uses sysmatch.
	;;; It will also use popmatchvars to control sysmatch, so the
	;;; value of popmatchvars has to be reset before each call of sysmatch

	lvars item, pattern, key, keys, procedure (dbtable, proc),
		oldmatchvars = popmatchvars,
		hashkey = fast_front(pattern);

	if prb_is_var_key(hashkey) then
		;;; get the list of keys and deal with them separately
		prb_database_keys(dbtable) -> keys;

		;;; Garbage collect the list of keys on exit (See HELP * DLOCAL)
		;;; Doesn't work on alphas, unless keys initialised
		;;;???;;;		dlocal 0 % ,if dlocal_context < 3 then sys_grbg_list(keys) endif%;

		prb_match_apply_keys(dbtable, pattern, keys, proc);
		sys_grbg_list(keys); [] -> keys;

	else
		;;; just look in one list determined by the pattern key
		fast_for item in dbtable(hashkey) do
			oldmatchvars -> popmatchvars;
			if sysmatch(pattern, item) then proc(item) endif
		endfor
	endif
enddefine;

define vars procedure prb_add(item);
	;;; add item to prb_database
	lvars item, key = front(item);

	;;; should include a check that the key is not a variable?

	IFTRACING
	if prb_self_trace then
		prb_adding_trace(sim_myself, item)
	endif;

	IFTRACING
	if prb_chatty and prb_divides_chatty(DATABASE_CHANGE) then
		['ADD' ^item] ==>
	endif;

	conspair(item, prb_database(key)) -> prb_database(key);

enddefine;

define procedure prb_add_to_db(item, dbtable);
	;;; add item to prb_database
	lvars item, procedure dbtable, key = front(item);

	;;; should include a check that the key is not a variable?

	conspair(item, dbtable(key)) -> dbtable(key);

enddefine;


define vars procedure prb_present(pattern) /* -> item */;
	;;; prb_database is a property

	;;; Use first item in pattern to index prb_database
	;;;	and look through that list for the given pattern.
	;;; If the first item is not constant, search everything.

	;;; If something matches then assign it to prb_found, and return it.
	;;; This will set popmatchvars if anything matches.
	lvars pattern;

	define lconstant procedure found_item(/* data */);
		;;; if something matches record it and return
		/* lvars data; */
		/* data */ ->> prb_found;	;;; result left on stack
		exitfrom(prb_present)
	enddefine;

	prb_match_apply(prb_database, pattern, found_item);

	;;; failed so
	false

enddefine;

define procedure prb_present_keys(pattern, keys) -> item;
	;;; Like prb_present, but specify database keys to use

	;;; This will set popmatchvars if anything matches.
	lvars pattern, keys;
	dlvars item = false;

	define lconstant procedure found_item(data);
		;;; if something matches record it and return
		lvars data;
		data ->> prb_found -> item;
		exitto(prb_present_keys)
	enddefine;

	prb_match_apply(prb_database, pattern, keys, found_item);

enddefine;

		


define global procedure prb_in_data(pattern, data) -> item;
	;;; first item in the list data that matches pattern,
	;;; otherwise false. Assume data is a list, so use fast_for

	lvars pattern, data, item, oldmatchvars = popmatchvars;

	fast_for item in data do
		oldmatchvars -> popmatchvars;
		if sysmatch(pattern, item) then
			return
		endif
	endfor;

	false -> item;
enddefine;

define global procedure prb_del1(pattern, data) -> (item, data);
	;;; Delete the first item in the list data that matches pattern.
	;;; Return the item found, or false, and the new (or unchanged) list
	;;; Assume data is a list, so use fast_for

	lvars pattern, data, item, next, temp, oldmatchvars = popmatchvars;

	if data == [] then
		false -> item;
	elseunless prb_copy_modify then
		;;; delete the first matching item, using old list links
		;;; First delete occurrence from front of list
		fast_front(data) -> item;
		if sysmatch(pattern, item) then
			fast_back(data) -> data;
			return();
		endif;
		;;; Now non-constructively delete any non-leading matching items,
		;;; after saving the pointer to the list in data.
		data -> temp;
		until (fast_back(temp) ->> next) == [] do
			fast_front(next) -> item;
			oldmatchvars -> popmatchvars;
			if sysmatch(pattern, item) then
				fast_back(next) -> fast_back(temp);
				return();
			else
				next -> temp
			endif
		enduntil;
		
	elseif prb_in_data(pattern, data) ->> item then
		;;; do the copying deletion, of ONE item.
		delete(item, data, 1) -> data;
	;;;; else item is false
	endif
enddefine;


define vars procedure prb_flush1(pattern);
	;;; Remove one item from the database matching the pattern
	;;; It should have a constant first item, otherwise which item
	;;; is found may be arbitrary.
	lvars pattern, hashkey, data, newpatt = false, keys = false;

	define lconstant record_found(found, data, hashkey) -> found;

		;;; insert new list of data minus found
		data -> prb_database(hashkey);

		IFTRACING
		if prb_self_trace then
			prb_deleting_trace(sim_myself, found)
		endif;

		IFTRACING
		if prb_chatty and prb_divides_chatty(DATABASE_CHANGE) then
			['REMOVED1'  ^found] ==>
		endif;
		[^found] -> found;
	enddefine;

	fast_front(pattern) -> hashkey;
	if prb_is_var_key(hashkey) then
		;;; starts with a variable
		if prb_instantiate_first(pattern) ->> newpatt then
			fast_front(newpatt ->> pattern) -> hashkey;
		else
			prb_database_keys(prb_database) -> keys;
		endif
	endif;

	if keys then
		;;; the pattern did not determine a fixed key
		fast_for hashkey in keys do
			;;; find the first one that can be deleted, and stop
			prb_del1(pattern, prb_database(hashkey)) -> (prb_found, data);
			if prb_found then
				record_found(prb_found, data, hashkey) -> prb_found;
				sys_grbg_list(keys);
				return();
			endif;
		endfor;
		false -> prb_found;
	else
		prb_del1(pattern, prb_database(hashkey)) -> (prb_found, data);
		if prb_found then
			record_found(prb_found, data, hashkey) -> prb_found;
		endif;
		;;; see if temporary pattern was created, and if so return link
		;;;; ??? NOT REALLY SAFE pattern could be result of restriction procedure
		;;;;if newpatt then sys_grbg_destpair(pattern) ->; ->; endif
	endif
enddefine;


define lconstant procedure prb_subflush_fixed(pattern, hashkey);
	;;; This is called if non-var first in pattern
	lvars
		item, pattern, next, temp, hashkey, data,
		oldmatchvars = popmatchvars,
		;;; record items found and deleted, in prb_found
		recordfound = prb_recording;

		IFTRACING
		if prb_chatty and prb_divides_chatty(DATABASE_CHANGE) then
			true -> recordfound
		endif;

	prb_database(hashkey) -> data;
	;;; Assume prb_found is already a list, e.g. set up in prb_flush

	if listlength(pattern) == 2 and fast_front(fast_back(pattern)) == "=="
	then
		;;; Pattern is of form [<item> ==]
		;;; Get rid of all database entries starting with <item>
		[] -> prb_database(hashkey);
		if recordfound then
			data <> prb_found -> prb_found;
		endif;
		return();
	endif;

	dlocal popmatchvars;

	unless prb_copy_modify then
		;;; delete all matching patterns, using old list links
	returnif(data == []);
		;;; first delete occurrences from front of list
		repeat
			oldmatchvars -> popmatchvars;
			fast_front(data) -> item;
		quitunless(sysmatch(pattern, item));
			if recordfound then
				conspair(item, prb_found) -> prb_found;
			endif;
			fast_back(data) -> data;
			if data == [] then
				;;; ensure empty database in table
				data -> prb_database(hashkey);
				return();
			endif;
		endrepeat;
		;;; Now delete any non-leading matching items
		;;; after saving the pointer
		data ->> temp -> prb_database(hashkey);
		until (fast_back(temp) ->> next) == [] do
			fast_front(next) -> item;
			oldmatchvars -> popmatchvars;
			if sysmatch(pattern, item) then
				if recordfound then
					conspair(item, prb_found) -> prb_found;
				endif;
				fast_back(next) -> fast_back(temp)
			else
				next -> temp
			endif
		enduntil;
	
	elseif prb_in_data(pattern, data) then
		;;; There is at least one matching occurrence

		;;; Do the copying deletion of all matching occurrences.
		
		[%fast_for item in data do
				oldmatchvars -> popmatchvars;
				if sysmatch(pattern, item) then
					if recordfound then
						conspair(item, prb_found) -> prb_found
					endif
				else
					item
				endif
			endfast_for
		%] -> prb_database(hashkey);
	endunless;
enddefine;

;;; Pattern has variable or don't care as its first item.
;;; so cycle through all the hashkeys associated with prb_database
;;;	and call prb_subflush_fixed on each one.
define lconstant procedure prb_subflush_var(pattern);
	lvars pattern;
	appproperty(
		prb_database,
		procedure(key,val);
			lvars key, val;
			unless fast_lmember(key, $-prb$-private_keys) then
				prb_subflush_fixed(pattern, key);
			endunless;
		endprocedure
	);
enddefine;

define vars procedure prb_flush(pattern);
	;;; Remove all occurrences of items matching pattern from prb_database
	lvars pattern, hashkey, newpatt, recording = false;

	IFTRACING	
	if prb_chatty and prb_divides_chatty(DATABASE_CHANGE) then
		true -> recording
	endif;

	[] -> prb_found;
	if listlength(pattern) == 2 and fast_front(fast_back(pattern)) == "=="
	then
		;;; Pattern is of form [<item> ==]
		;;; Get rid of all database entries starting with <item>
		fast_front(pattern) -> hashkey;
		if recording then
			prb_database(hashkey) -> prb_found;
		endif;
		[] -> prb_database(hashkey)
		
	elseif prb_no_variables(pattern) then
		;;; It has no variables that can be set by the matcher,
		;;; and no occurrences of "=" or "=="
		;;; so should match at most one thing.
		prb_flush1(pattern);
		return();
	else
		fast_front(pattern) -> hashkey;
		if prb_is_var_key(hashkey) then
			;;; starts with a variable
			if prb_instantiate_first(pattern) ->> newpatt then
				;;; managed to instantiate the first item
				;;; so get the key and look in only one subdatabase
				fast_front(newpatt ->> pattern) -> hashkey;
				prb_subflush_fixed(pattern, hashkey);
				;;;sys_grbg_destpair(pattern) ->; ->;	;;;;NOT SAFE ?? see previous case
			else
				prb_subflush_var(pattern)
			endif
		else
			prb_subflush_fixed(pattern, hashkey)
		endif;

	endif;

	IFTRACING
	if prb_self_trace then
		prb_deleting_pattern_trace(sim_myself, prb_found, pattern)
	endif;

	IFTRACING
	if recording then
		['REMOVED'  ^prb_found] ==>
	endif;

enddefine;


/* END OF PRB DATABASE FACILITIES */


/*
-- FACILITIES FOR INSTANTIATING PATTERNS
*/

/*
   Instantiation of query variables that are on popmatchvars
   and evaluation of [popval ...] and [apply ...] list elements.
*/

define global constant procedure prb_valof(word) -> word;
	;;; autoload if necessary, and dereference if necessary
	lvars word;

	;;; Restore popautolist as it was before prb_run
	dlocal popautolist = savedautolist;

	;;; Changed to dereference only once
	if isword(word) then
		valof(word) -> word
	elseif isident(word) then
		idval(word) -> word
	;;; otherwise it must be a procedure.
	endif;
enddefine;



define lconstant procedure prb_dl(list);
	;;; put contents of list on stack, but for items preceded by
	;;; "?" put their value on the stack
	lvars item, list, var = false ;
	for item in list do
		if var then
			if prb_member(item, popmatchvars) then
				valof(item);
				if var == 1 then dl() endif;
			elseif var == 1 then "??", item
			else "?", item
			endif;
			false -> var
		elseif item == "?" then true -> var
		elseif item == "??" then 1 -> var
		else item
		endif
	endfor
enddefine;


/*
-- RECORD CLASS FOR RULES
*/
;;; Fields are - name, weight, conditions, actions, ruleset, rulevars

defclass vars procedure prbrule
	{prb_rulename, prb_weight, prb_conditions, prb_actions, prb_ruleset,
		prb_rulevars};

syssynonym("prb_ruletype","prb_ruleset");

;;; will be ignored if prb_use_sections is false.
IFSECTIONS
define procedure prb_rule_section =
	newproperty([], 64, false, "tmparg")
enddefine;

;;; procedure to print a rule
define prb_print_rule(rule);
	lvars rule;
	spr('\n<prb_rule');
	spr(prb_rulename(rule));
	spr("in");
	spr(prb_ruleset(rule));
	if prb_useweights then
		pr('weight:'); spr(prb_weight(rule));
	endif;
	pr('\n\tconditions:');
	spr(prb_conditions(rule));
	pr('\n\tactions:');
	spr(prb_actions(rule));
	pr('>');
enddefine;

prb_print_rule -> class_print(prbrule_key);


#_IF prb_use_sections
;;; procedure to check whether section for current rules needs to be changed
define vars procedure prb_check_section(rule);
	;;; Can be redefined as erase if not used.
	lvars rule, sect;
	
	;;; Check if necessary to change section for this rule type
		if current_section /== (prb_rule_section(rule) ->> sect) and sect then
			sect -> current_section;
		endif;

enddefine;

#_ENDIF

;;; procedures used in connection with rulefamilies

global vars procedure
	(prb_rulefamily_name,
	prb_family_prop,
	prb_next_ruleset,
	;;;prb_family_stack,
	prb_family_limit,
	prb_family_section,
	prb_family_matchvars,
	prb_family_dlocal
	)
;

#_IF identprops("isprb_rulefamily") == undef

define vars procedure isprb_rulefamily(x);
	;;; this will be overridden if lib rulefamily is compiled
	false
enddefine;

#_ENDIF

/*
-- RECORD CLASS FOR RULE-ACTIVATIONS
*/
;;; Each record contains:
;;; 	the rule, the variables bound, the values of the variables,
;;;		a list of matched database items, and the recency information.

defclass vars procedure prbactivation
	{prb_ruleof, prb_varsof, prb_valsof, prb_foundof, prb_recof}
;

define lconstant prb_activation_name(/*instance*/);
	prb_rulename(prb_ruleof(/*instance*/))
enddefine;

section $-prb;


;;; This is used in lib sim_agent. Don't remove it
vars in_prb_instance = false;

define vars $-prb_instance(Pattern) -> value;
	;;; Used to instantiate pattern, using current popmatchvars
	lvars item, Pattern, value, key, func;

	dlocal in_prb_instance = true;

	if isvector(Pattern) then
		;;; Just instantiate the contents
		prb_value(Pattern) -> value
	elseif atom(Pattern) then
		Pattern -> value
	elseif (front(Pattern) ->> key) == "popval" or key == "$$" then
		/*
		;;; Changed  11 May 1996 by precompiling popval forms. So this is
		;;; no longer necessary:
		;;; evaluate the rest of the pattern, after instantiating
		;;;		pop11_compile(prb_instance(fast_back(Pattern))) -> value
		*/
		;;; run the procedure following the keyword
		front(fast_back(Pattern))() -> value
	elseif key == "apply" or key == "$:" then
		;;; should be [apply func arg1 arg2 arg3....] or [$: func arg....]
		fast_back(Pattern) -> Pattern;
		if Pattern == [] then mishap(0, 'NOTHING AFTER "apply"')
		else
			prb_valof(fast_destpair(Pattern) -> Pattern) -> func;
			if isprocedure(func) then
				;;; instantiate arguments and apply func to them
				func(prb_dl(prb_instance(Pattern))) -> value;
			else
				mishap(func::Pattern, 1, 'NO PROCEDURE(NAME) AFTER "apply"')
			endif
		endif
	elseif key == "VAL" then
		;;; Assume the rest of the pattern contains only a word.
		;;; get its value
		valof(fast_front(fast_back(Pattern))) -> value
	elseif key == "READ" then
		;;; assertion element may include unbound uses of ANSWER
		back(Pattern) -> Pattern;
		;;; Run code in a procedure so that pattern variables can be localised
		procedure ();
			;;; pattern variables used below
			lvars question, constraint, assertion, explanation;

			if Pattern matches
				! [?question ??constraint ?assertion ?explanation:isvector]
				;;; PREVIOUSLY
				;;; #_< [? ^WID question ?? ^WID constraint ? ^WID assertion ? ^WID explanation:isvector] >_#
			or Pattern matches
				! [?question ??constraint ?assertion]
				;;; PREVIOUSLY
				;;; #_< [? ^WID question ?? ^WID constraint ? ^WID assertion] >_#
			then
				[READ %prb_instance(question), dl(constraint), assertion,
					if isvector(explanation) then explanation endif%] -> value

			else
				mishap(Pattern, 1, 'BAD "READ" ACTION FORMAT')
			endif
		endprocedure()
	else
		;;; No special keywords, so just instantiate the whole pattern
		lvars rest, val;
		[%
			until Pattern == [] do
				front(Pattern) -> item;
				if item == "?" then
					back(Pattern) -> Pattern;
					front(Pattern) -> item;
					if fast_lmember(item, popmatchvars) then
						valof(item) -> val;
						if (fast_back(Pattern) ->> rest) == [] then
							val
						else
							if front(rest) == ":" then
								if (fast_back(rest) ->> rest) /== []
								and
									;;; run restriction
									prb_valof(front(rest))(val)
								then
									rest -> Pattern;
									val;
								else
							 		"?", item
								endif
							else val
							endif
						endif
					else
						"?", item
					endif
				elseif item == "??" then
					fast_back(Pattern) -> Pattern;
					front(Pattern) -> item;
					if fast_lmember(item, popmatchvars) then
						valof(item) -> val;
						if (fast_back(Pattern) ->> rest) == [] then
							dl(val)
						else
							if front(rest) == ":" then
								if (fast_back(rest) ->> rest) /== []
								and
									;;; run restriction
									prb_valof(front(rest))(val)
								then
									rest -> Pattern;
									dl(val);
								else
							 		"?", item
								endif
							else dl(val)
							endif
						endif
					else
						"??", item
					endif
				elseif atom(item) then
					item
				else
					prb_instance(item),
					;;; value left on stack
				endif;
				back(Pattern) -> Pattern;
			enduntil
		%] -> value;
	endif
enddefine;


define vars $-prb_value(Pattern) -> Pattern;
	;;; Used to evaluate a rule, or pattern, etc.
	;;; Don't instantiate if there are no variables or calls of Popval
	lvars Pattern;
	if isvector(Pattern) then
		{% appdata(Pattern, prb_value) %} -> Pattern
	elseif not(prb_copy_modify) or prb_has_variables(Pattern) then
		prb_instance(Pattern) -> Pattern
	endif;
enddefine;


endsection;

/* END FACILITIES FOR INSTANTIATION */


/*
-- FACILITIES FOR CHECKING THAT ALL CONDITIONS OF A RULE ARE SATISFIED
*/


#_IF identprops("prb_condition_type") == undef
;;; Prevent re-initialisation of this property

;;; Property for user-defined condition types
define global vars procedure prb_condition_type =
	newproperty([], 24, false, true)
enddefine;

#_ENDIF

define lconstant add_and_set_popmatchvars(list);
	;;; add items to popmatchvars, running any initialisation procedure
	lvars list, item;
    fast_for item in list do
		if isprocedure(item) then item();	;;; initialise variable values
		elseunless fast_lmember(item, popmatchvars) then
	    	conspair(item, popmatchvars) -> popmatchvars;
		endif;
	endfor
enddefine;


define lconstant prb_add_condition_vars(list);
	;;; put the variables in list into popmatchvars if not already there.
	;;; if there's a procedure in the list, run it
	lvars list;
	add_and_set_popmatchvars(list);
	;;; Conditions must evaluate to true
	true;
enddefine;

prb_add_condition_vars -> prb_condition_type("VARS");
prb_add_condition_vars -> prb_condition_type("LVARS");

define lconstant prb_add_action_vars(rule_instance, action);
	;;; this is used to run a VARS type action
	add_and_set_popmatchvars(fast_back(action));
enddefine;

define lconstant prb_check_pop_code(pattern, result_expected) -> boole;
	;;; Invoked when a condition starts with "WHERE" or "POP11"
	lvars oldprmishap = prmishap;

	define dlocal prmishap(string, list);
		;;; treat an error as equivalent to false, unless debugging
		lvars string, list;
		if prb_debugging then oldprmishap(string, list)
		else false, exitfrom(prb_check_pop_code)
		endif
	enddefine;

;;;	fast_back(pattern) -> pattern;

	;;; save stack, for checking.
	;;; lvars len = stacklength();

	if fast_back(pattern) == [] then
		;;; There's only one item in the pattern. It should be a procedure,
		;;; so run it
		lblock lvars proc = fast_front(pattern);
		if isprocedure(proc) then
			
			proc();
			if result_expected then -> boole;
			else true -> boole
			endif
		else
			mishap('WHERE condition does not have a procedure',[^proc])
		endif;
		endlblock
	else
		;;;;; Should no longer be needed, if "?" and "??" are
		;;;; disallowed in WHERE conditions.
		if prb_has_variables(pattern) then
			prb_instance(pattern) -> pattern;
			;;; no longer needed A.S. Fri Jun  9 11:42:18 BST 1995
			;;; reset autoloading
			dlocal popautolist = savedautolist;
		endif;
		pop11_compile(pattern);
			if result_expected then -> boole;
			else true -> boole
			endif
	endif;

	IFTRACING
	if showing_conditions or (prb_chatty and prb_divides_chatty(WHERETESTS)) then
		['Tested WHERE or POP11' ^pattern ] ==>
		['Result is:' ^boole] ==>
	endif;
enddefine;

prb_check_pop_code(%true%) -> prb_condition_type("WHERE");
prb_check_pop_code(%false%) -> prb_condition_type("POP11");

/*
-- -- prb_forevery
*/

;;; A section to hide some global variables for prb_forevery
;;; May no longer be needed! (13 Aug 2000)

section $-prb  => prb_forevery;

lvars
	;;; This global variable is needed for use with conditions of the form
	;;;		[->> variable]
	last_item_matched = false,
	last_stacklength,
;

define lconstant procedure prb_check_stack(num);
	;;; num items on stack to go into "Involving:" part of error message.
	lvars len = stacklength(), list;
	if len == last_stacklength + num then
		erasenum(num)
	else
		if len > last_stacklength + num then
			this_rule, len - last_stacklength + 1
		else
			this_rule, num + 1
		endif;
		mishap(
			'Stack altered: old ' >< (last_stacklength ) ><
			' new ' >< (len - num))
	endif;
enddefine;

define lconstant prb_assign_->> (pattern);
	;;; invoked in conditions of the form [->> var]
	lvars pattern, var = front(pattern);
	if last_item_matched then
		last_item_matched -> valof(var);
		if fast_lmember(var, popmatchvars) then
			mishap(0, '[->> ' >< var
					>< '] condition uses existing variable: ' >< var)
		endif;
		conspair(var, popmatchvars) -> popmatchvars;
	else
		mishap('->> used after non-simple condition', [^pattern])
	endif;
	true;
enddefine;

prb_assign_->> -> prb_condition_type("->>");

;;; This global variable is used to determine whether to continue
;;; trying to instantiate patterns in the condition list.
lvars prb_cut_fail = false;

define lconstant prb_do_cut();
	;;; Procedure activated by [CUT]
	;;; ignore empty list
		->;
	;;; Ensure that no more matching will be tried if prb_forevery_sub
	;;; returns from recursion.
	true -> prb_cut_fail;
	;;; always make it succeed
	true;
enddefine;

prb_do_cut -> prb_condition_type("CUT");

;;; This is used to save a pushed database that needs to be restored,
;;; after using using [INDATA ...]
lvars indata_saved_database = false;


define vars prb_forevery(patternlist, proc);
	;;; Apply proc for every consistent match between patterns in patternlist
	;;; and a set of database items. Use sysmatch so that popmatchvars is
	;;; accessible for subsequent calls.
	;;; proc will be applied to the value of counter and patternlocations.
	lvars patternlist, procedure proc,
		counter = 0,
		pattlistvar,
		foundname;

	dlocal indata_saved_database;

	;;; A vector to record relative age of items matched in database.
	;;; probably no longer useful with partitioned database
	lconstant patternlocations = initv(prb_max_conditions);

	dlocal prb_found = [], pop_=>_flag,
		checking_conditions = true,
		last_stacklength = stacklength();

	define lconstant procedure prb_forevery_sub(patternlist);
		;;; uses proc and start_data non-locally
		lvars pattern, key, patternlist,
			oldmatchvars = popmatchvars, oldfound = prb_found,
			condition_procedure;

		dlocal popmatchvars,		;;; re-set popmatchvars on exit
			counter = counter fi_+ 1,	;;; index into patternlocations
			prb_found,
			last_item_matched;
		
		IFTRACING
		dlocal pop_=>_flag;

		IFTRACING
		if showing_conditions then
			'|' sys_>< pop_=>_flag -> pop_=>_flag
		endif;


		;;; has the stack changed?
		prb_check_stack(
			'remaining patterns',
			patternlist,
			'Stack changed in prb_forevery', 3);

		define lconstant procedure isindata(patt);
			;;; Check if pattern matches an item in the database
			;;; uses patternlist, prb_found, oldmatchvars,
			;;; and others non-locally.

			;;;; [isindata ^patt [database ^(prb_database.datalist)]]==>
			lvars
				item, patt,
				key = fast_front(patt), keys,
				found = false;

			;;; Make a list of database keys through which to cycle
			;;; seeking items to match patt. If patt starts
			;;; with a variable, then get all the database keys, otherwise use
			;;; only the first item in patt.
			if prb_is_var_key(key) then
				prb_database_keys(prb_database)
			else
				conspair(key,[])
			endif -> keys;

			;;; ensure keys is garbage collected on exit
			dlocal 0 % ,if dlocal_context < 3 then sys_grbg_list(keys) endif%;

			;;; All relevant popmatchvars have already been used in instantiating
			;;;; patt
			dlocal popmatchvars;
			#_IF prb_recency
			lvars n;
			if prb_recency then 0 -> n;	endif; ;;; count along database
			#_ENDIF
			fast_for key in keys do
			  	fast_for item in prb_database(key) do
					#_IF prb_recency
					if prb_recency then n fi_+ 1 -> n endif;
					#_ENDIF
					;;;				oldmatchvars -> popmatchvars;
					;;;				lvars oldvars = oldmatchvars;
					[]  -> popmatchvars;
					oldfound -> prb_found;
					if sysmatch(patt,item) then
						IFTRACING
						if prb_self_trace then
							prb_condition_satisfied_trace(
								sim_myself, patt, item, this_rule, popmatchvars)
						endif;

						if showing_conditions then
							true -> found;
							IFTRACING
							['MATCH FOUND:' ^patt ^item] ==> ;
						endif;
						;;; Add the found item to the list of found items
						conspair(item,prb_found) -> prb_found;
						;;; and save it for "->>" conditions
						item -> last_item_matched;
						#_IF prb_recency
						if prb_recency then
							;;; store location at which pattern found
							n -> fast_subscrv(counter, patternlocations);
						endif;
						#_ENDIF
						;;; Try to match the remaining patterns. But first restore
						;;; and extend previous popmatchvars
						prb_extend_popmatchvars(popmatchvars, oldmatchvars)
							-> popmatchvars;
						prb_forevery_sub(patternlist);
					/*
					;;; Unsafe. Don't do.
					until popmatchvars == oldvars do
						sys_grbg_destpair(popmatchvars) -> (, popmatchvars);
    				enduntil
						*/
					endif;
			  	endfor
			endfor;

			;;; come here if no match was found
			IFTRACING
			if prb_self_trace then
     			prb_condition_failed_trace(sim_myself, patt, this_rule)
			endif;

			IFTRACING
			if showing_conditions and not(found) then
				['NO MATCH FOR:' ^patt] ==>
			endif;
		enddefine;

		define lconstant procedure all_matches(patt) -> list;
			;;; Return all the items in database that match patt
			;;; consistent with current popmatchars
			;;; uses patternlist, start_data, oldmatchvars,
			;;; and others non-locally
			;;; return false if no matching items are found
			;;; Used for FILTER conditions
			lvars list, patt;

			dlocal popmatchvars;

			[% prb_match_apply(prb_database, patt, identfn) %] -> list;

			if list == [] then
				false -> list;	
				IFTRACING
				if prb_self_trace then
     				prb_condition_failed_trace(sim_myself, patt, this_rule)
				endif;

			else
				IFTRACING
				if showing_conditions then
					['MATCHES FOUND in FILTER: ' ^patt ^^list] ==>
				endif;
			endif;
		enddefine;

		if patternlist == [] then
			IFTRACING
			if prb_self_trace then
				prb_all_conditions_satisfied_trace(
					sim_myself, prb_ruleset(this_rule), this_rule, popmatchvars)
			endif;

			;;; matched all patterns, recursion ends
			if showing_conditions then
				dlocal pop_pr_level = 5, pop_oc_print_level = 2;
				'CONDITIONS SATISFIED: Variables bound:'=>
				;;;unless popmatchvars = oldmatchvars then
				pr(pop_=>_flag);
				lblock; lvars var;
					for var in popmatchvars do
						spr(var);spr("=");spr(valof(var));spr(";")
					endfor;
				endlblock;
				pr(newline);
				;;;endunless
			endif;
			proc(patternlocations, counter fi_- 1);
		else
			;;; Some more patterns to match. Continue to recurse
			
			fast_destpair(patternlist) ->(pattern, patternlist);
			lvars fullpattern = pattern;

			if pattern == "POPINDATA" then
				;;; Need to restore previous database
				if indata_saved_database then
					procedure();
                    	dlocal indata_saved_database;
							indata_saved_database -> prb_database;
							false -> indata_saved_database;
						prb_forevery_sub(patternlist);
					endprocedure();
					return();
				else
					mishap('INDATA RESTORE ERROR, REPORT TO A.SLOMAN', patternlist)
				endif
			else
				IFTRACING
				if prb_self_trace then
					prb_checking_one_condition_trace(sim_myself, pattern, this_rule)
				endif;

				front(pattern) -> key;
				while key == "ALL" do
					;;; Ensure that all the patterns apart from the first one from the
					;;; ALL condition are in patternlist, for use in the recursive
					;;; call if the first one succeeds.
					false -> last_item_matched;
					;;; pattern is [ALL ?pattlistvar], where pattlistvar must
					;;; already have a value. Its value is a list of patterns
					;;; splice them into patternlist.

					destpair(fast_back(pattern)) -> (pattlistvar, pattern);
					unless pattlistvar == "?" then
						mishap(pattern,1,'"?" EXPECTED AFTER "ALL"')
					endunless;
					destpair(pattern) ->(pattlistvar, pattern);
					unless prb_member(pattlistvar, popmatchvars) then
						mishap(pattlistvar, 1, 'UNBOUND VARIABLE AFTER "ALL"')
					endunless;
					;;; It's in popmatchvars, so get the value and prepend to
					;;; patternlist
					valof(pattlistvar) <> patternlist -> patternlist;
					fast_destpair(patternlist) -> (pattern, patternlist);
					front(pattern) -> key;
				endwhile;

        		
				if (prb_condition_type(key) ->> condition_procedure) then
					;;; should allow autoloading of new condition types
					;;; User-defined condition so run it. (It could be a procedure name)

					false -> prb_cut_fail;	;;; assume no cut. May be changed
					if prb_valof(condition_procedure)
						(prb_instance(fast_back(pattern)))
					then
						prb_check_stack(
							'\n;;; STACK CHANGED BY CONDITION', pattern, 2);
						false -> last_item_matched;
						;;; Succeeded with user condition, so continue

						IFTRACING
						if prb_self_trace then
							prb_condition_satisfied_trace(
								sim_myself, pattern, undef, this_rule, popmatchvars)
						endif;

						;;; Don't reset popmatchvars. The condition may have
						;;; set it.

						;;; Save the value of prb_cut_fail, possibly set by user's
						;;; condition handler
						lblock lvars once = prb_cut_fail;

							prb_forevery_sub(patternlist);

							if once then ;;; don't try any more with this rule
								exitfrom(prb_forevery);
							endif;
						endlblock;
					else
						IFTRACING
						if prb_self_trace then
     						prb_condition_failed_trace(sim_myself, pattern, this_rule)
						endif;

						IFTRACING
						if showing_conditions then
							[FAILED 'USERTEST' ^^(prb_instance(pattern))] ==>
						endif;
						return();
						endif
				elseif key == "NOT" then
					false -> last_item_matched;
					fast_back(pattern) -> pattern;

					dlvars found = false;

					define lconstant procedure fail_on_item(/*item*/);
						;;; applied to each item that matches the pattern
							/*item*/ -> found;
						exitfrom(prb_match_apply);	;;; added. A.S.  17 Dec 1995
					enddefine;

					oldfound -> prb_found;
					oldmatchvars -> popmatchvars;
					lvars grbg;
					if prb_has_variables(pattern) ->> grbg then
						prb_instance(pattern) -> pattern;
					endif;
					prb_match_apply(prb_database, pattern, fail_on_item);

					oldmatchvars -> popmatchvars;


					if found then
						IFTRACING
						if prb_self_trace then
     						prb_condition_failed_trace(sim_myself, [NOT ^^pattern], this_rule)
						endif;

						IFTRACING
						if showing_conditions then
							[FAILED [NOT ^^pattern] ^found] ==>
						endif;
					else
						IFTRACING
						if prb_self_trace then
							prb_condition_satisfied_trace(
								sim_myself, [NOT ^^pattern], undef, this_rule, popmatchvars)
						endif;

						IFTRACING
						if showing_conditions then
							[SUCCESS [NOT ^^pattern]] ==>
						endif;
					endif;

					;;; restore temporary list at top level. SAFE ???
					if grbg then sys_grbg_list(pattern) endif;

					unless found then
						;;; succeeded with negative condition
						prb_forevery_sub(patternlist)
					endunless;

				elseif key == "OR" then
					;;; It's a list of patterns. See if at least one works.
					lblock lvars patt;
						for patt in fast_back(pattern) do
					    	oldmatchvars -> popmatchvars;
					    	prb_forevery_sub(patt::patternlist)	
							;;; if it returns, try another
						endfor;
					endlblock;
					IFTRACING
					if prb_self_trace then
     					prb_condition_failed_trace(sim_myself, pattern, this_rule)
					endif;

					IFTRACING
					if showing_conditions then
						[FAILED [^^pattern]] ==>
					endif;
					return ;;; failed
				elseif key == "NOT_EXISTS" then
					false -> last_item_matched;
					fast_back(pattern) -> pattern;
					oldmatchvars -> popmatchvars;
					oldfound -> prb_found;
					;;; postpone autoloading of prb_allpresent
					if prb_valof("prb_allpresent")(pattern) then
						;;; failed
						IFTRACING
						if prb_self_trace then
     						prb_condition_failed_trace(sim_myself, fullpattern, this_rule)
						endif;

						IFTRACING
						if showing_conditions then
							[FAILED ^(prb_instance(fullpattern))] ==>
						endif;
						return();

					else
						IFTRACING
						if prb_self_trace then
							prb_condition_satisfied_trace(
								sim_myself, fullpattern, undef, this_rule, popmatchvars)
							endif;

						IFTRACING
						if showing_conditions then
							[SUCCESS ^(prb_instance(fullpattern))] ==>
						endif;	;;; for IFTRACING
					endif;
					;;; succeeded with negative condition
					oldmatchvars -> popmatchvars;
					prb_forevery_sub(patternlist)
				elseif key == "IMPLIES" then
					false -> last_item_matched;
					;;; [IMPLIES <list of patterns> <pattern>]
					fast_back(pattern) -> pattern;
					oldmatchvars -> popmatchvars;
					oldfound -> prb_found;

					;;; translate to NOT_EXISTS format
					lvars trans_condition =
						[%dl(front(pattern)), "NOT_EXISTS" :: back(pattern)%];

					;;; trans_condition ==>

					;;; prb_forevery_sub(trans_condition::patternlist);
					if prb_valof("prb_allpresent")(trans_condition) then
						;;; failed
						;;; sys_grbg_list(trans_condition);
						IFTRACING
						if prb_self_trace then
     						prb_condition_failed_trace(sim_myself, fullpattern, this_rule)
						endif;

						IFTRACING
						if showing_conditions then
							[FAILED ^(prb_instance(fullpattern))] ==>
						endif;
						return();

					else
						;;; sys_grbg_list(trans_condition);
						IFTRACING
						if prb_self_trace then
							prb_condition_satisfied_trace(
								sim_myself, fullpattern, undef, this_rule, popmatchvars)
							endif;

						IFTRACING
						if showing_conditions then
							[SUCCESS ^(prb_instance(fullpattern))] ==>
						endif;	;;; for IFTRACING
					endif;

					;;; succeeded with implies condition, so continue, but
					;;; reset popmatchvars (as with NOT_EXISTS)
					oldmatchvars -> popmatchvars;
					prb_forevery_sub(patternlist)
						
				elseif key == "FILTER" then
					false -> last_item_matched;
					;;; of form [FILTER pred patt1 patt2 ... pattn]
					;;; or form [FILTER pred -> var patt1 patt2 ... pattn]
					;;; for each patt get a list of matching items consistent
					;;; with original popmatchvars, then apply pred to the
					;;; list of lists (some possily false, not empty)
					lblock	 lvars pred, items, patt, patterns, vec;
						lvars vectorvar, rest_patt;

						destpair(back(pattern)) -> (pred, pattern);
						prb_valof(pred) -> pred;	;;; test procedure
						if pattern matches
							! [ -> ?vectorvar ??rest_patt ]
							;;; previously
							;;; #_< [ -> ? ^WID vectorvar ?? ^WID rest_patt ] >_#
						then
							rest_patt -> pattern
						else
							false -> vectorvar
						endif;

						;;; pattern is actually a list of patterns
						;;; for each patt in pattern, make a list of matching items
						[% for patt in pattern do
								all_matches(patt)
							endfor
						%] -> items;
						lvars len = stacklength();					
						[%pred(pattern, items)%] -> vec;
						;;; pred may return false or a list (See HELP PRB_FILTER)
						unless stacklength() == len then
							mishap('FILTER PROCEDURE ALTERED STACK',
								[%pred, pattern%]);
						elseif listlength(vec) == 1 then
							sys_grbg_destpair(vec) -> (vec, );
						elseif vec == [] then
							mishap('FILTER PROCEDURE PRODUCED NO RESULT',
								[%pred, pattern%]);
						else
							mishap('FILTER PROCEDURE PRODUCED EXTRA RESULTS',
								[%pred, pattern, vec%]);
						endunless;

						if vec then
							oldmatchvars -> popmatchvars;
							if vectorvar then
								if fast_lmember(vectorvar, popmatchvars) then
									mishap(0,
										'[FILTER ' >< vectorvar
										><
										'] condition uses existing variable: '
										>< vectorvar)
								endif;
								conspair(vectorvar, popmatchvars) -> popmatchvars;
								vec -> valof(vectorvar);
							endif;

							IFTRACING
							if prb_self_trace then
								prb_condition_satisfied_trace(
									sim_myself, fullpattern, vec, this_rule, popmatchvars)
							endif;

							IFTRACING
							if showing_conditions then
								[SUCCESS ^(prb_instance(fullpattern))] ==>
							endif;

							prb_forevery_sub(patternlist)
						else
							IFTRACING
							if prb_self_trace then
     							prb_condition_failed_trace(sim_myself, fullpattern, this_rule)
							endif;

							IFTRACING
							if showing_conditions then
								[FAILED ^(prb_instance(fullpattern))] ==>
							endif;	;;; for IFTRACING
							return() ;;; failed
						endif
					endlblock
					;;; end of FILTER CASE
				elseif key == "INDATA" then
					lvars db;
					destpair(back(prb_instance(pattern))) -> (db, pattern);
					if db == prb_database then
						;;; already current database, so just continue
						prb_forevery_sub(conspair(front(pattern), patternlist))
					else
						;;; save previous database, then recurse
						;;; with new database, and reminder to restore
						;;; spliced into conditions
						procedure(db);
							dlocal prb_database, indata_saved_database;
							prb_database -> indata_saved_database;
							db -> prb_database;
							prb_forevery_sub(
								conspair(front(pattern),
									conspair("POPINDATA", patternlist)))
						endprocedure(db);
						IFTRACING
						if prb_self_trace then
     						prb_condition_failed_trace(sim_myself, pattern, this_rule)
						endif;

					endif;
				else
					if prb_has_variables(pattern) then
						;;; see if the pattern can be partially
						;;; instantiated. This will speed up matching.
						prb_instance(pattern) -> pattern;
						isindata(pattern);
						;;; SAFE ???
						sys_grbg_list(pattern);
					else
						isindata(pattern)
					endif
				endif
			endif
		endif
	enddefine;

	prb_forevery_sub(patternlist)
enddefine;

endsection;

/* END FACILITIES FOR CHECKING CONDITIONS */

/*
-- FACILITIES FOR DEFINING AND MANIPULATING RULES
*/

define global procedure read_in_items();
	;;; Read in text items between "["... amd "]" but don't make
	;;; embedded lists. Used for reading WHERE conditions, and
	;;; some actions
	lvars item, brackets = 0, parens = 0;
	repeat
		readitem() -> item;
		if item == """ then
			item,
			readitem();	;;; get quoted item.
			;;; Now check for closing quote
			readitem() ->> item;
			unless item == """ then
				mishap(item,1,'MISSING CLOSING WORD QUOTE "')
			endunless;
		elseif item == "("  then
			parens + 1 -> parens,
			item
		elseif item == ")"  then
			parens - 1 -> parens;
			if parens < 0 then
				mishap(0,'FOUND SPURIOUS ")" IN CONDITION OR ACTION OR DECLARATION')
			endif;
			item
		elseif item == "[" or item == "{" then
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
		elseif item == termin then
			mishap(0,'FOUND <termin>, MISSING "]"')
		else
			item
		endif
	endrepeat;
		
enddefine;

define global procedure read_list_of_items() -> result;
	;;; read in text items making up a list, without creating any
	;;; of the nested lists.
	lvars result, item = readitem();
	if item == "[" then
		[% read_in_items() %] -> result;
	else
		item -> result;
	endif
enddefine;

section prb;

define constant procedure prb_declare(word);
	lvars word;
;;;	unless isdefined(word) then
		ident_declare(word, 0, false);
		sysGLOBAL(word, true);
;;;	endunless;
enddefine;

define constant procedure prb_ldeclare(word);
	lvars word;
	unless isdefined(word) then
		sysLVARS(word, 0)
	endunless;
enddefine;


endsection;

/*
-- Stuff for reading in lexical variables in patterns
*/

global vars pop_pattern_lvars;
if isundef(pop_pattern_lvars) then
	true -> pop_pattern_lvars
endif;

applist([readpattern sysPUSHQ], sysunprotect);


lvars procedure oldPUSHQ =sysPUSHQ;

define lconstant newLVAR(item, declare);
	;;; item is a word
	;;; Make it a new lvar and associate the ident
	;;; with the word item.
	if declare then sysLVARS(item, 0) endif;
	;;; push the identifier
	sysIDENT(item);
	;;; Associate the identifier with the word, for trace printing
	;;; 	item -> word_of_ident(identof(item));
	oldPUSHQ(item);
	sysIDENT(item);
	sysUCALL("word_of_ident");
enddefine;

define vars prb_declare_lvar(item);
	;;; declare item as an lvar, and plant code to create an identifier record
	;;; and to associate the identifier with the word
	lvars idprops = identprops(item), id;

    unless sys_current_ident(item) ->> id then
        ;;; not declared, use sysLVARS to declare
		newLVAR(item, true);
    elseif identprops(id) /== 0 then
        ;;; mishap, e.g. op, macro or syntax word used as pattern
        ;;; variable.
		mishap(item, 1, 'INAPPROPRIATE PATTERN VARIABLE')
    elseif isident(id) == "perm" then
        ;;; item not declared as lex, but is declared as perm
        ;;; decide whether to force a lexical declaration or use the
        ;;; permanent identifier
		if prb_force_lvars then
			newLVAR(item, true)
		else ;;; use the word
			oldPUSHQ(item)
		endif
	else
		;;; Must be a pre-declared lexical. Just use the identifier
		newLVAR(item, false)
    endunless;
enddefine;

define constant Read_Pattern(vars_spec) -> item;
	;;; Read in a list or vector expression minus the closing bracket,
	;;; replacing words following "?", "??" with the corresponding
	;;; identifier, in nested lists, but not inside nested vectors.
	lvars item;

	readitem() -> item;
	if item /== "[" then
		return()
	endif;

	;;; Now read in the list, replacing pattern variables with
	;;; identifiers

	dlvars
		was_query = false,
		in_vector = iscaller(nonsyntax {);

		;;; It would be nice to make patterns constants where possible,
		dlocal pop_pop11_flags = pop_pop11_flags || POP11_CONSTRUCTOR_CONSTS;

		;;; Discount lexical idents pushed in patterns. I.e. don't treat as type 3
		;;; See REF * VMCODE, and REF * pop_vm_flags
		;;; IS THIS SAFE ???? A.S. Nov 1995
		dlocal pop_vm_flags = pop_vm_flags || VM_DISCOUNT_LEX_PROC_PUSHES;

		dlocal oldPUSHQ;
		if isundef(oldPUSHQ) then sysPUSHQ -> oldPUSHQ endif;

    define dlocal sysPUSHQ(item);
	    lvars invec, inlist, inpat;

	    if was_query == ":" then
		    if isinteger(item) or isprocedure(item) or isword(item)
		    then
			    oldPUSHQ(item)
		    else
			    mishap('WRONG RESTRICTION IN PATTERN', [^item])
		    endif;
			false -> was_query;
	    elseif was_query then
		    dlocal pop_autoload = false;
		    ;;; after "?" or "??". Should be a word or an identifier

		    if isword(item) then
				if fast_lmember(item, vars_spec) then
					;;; it's already declared as global using [VARS...]
					;;; so leave it
				    oldPUSHQ(item)
				else
					prb_declare_lvar(item)
				endif
		    elseif isident(item) then
			    oldPUSHQ(item)
		    else
			    mishap(item, 1, 'NON-WORD AFTER ' sys_>< was_query)
		    endif;
		    false -> was_query;
	    else
		    oldPUSHQ(item);
		    ;;;; 			Removed the colon. A.S. 29Nov95
		    ;;;;			if lmember(item, #_< [? ?? :] >_#) then
		    if lmember(item, #_< [? ?? ] >_#) then
			    ;;; Could the next item be a query variable?
			    if lmember(nextreaditem(), #_<[% "]", "}", "%", "^", """ %]>_# ) then
				    ;;; end of expression
				    false;
			    elseif in_vector then
				    ;;; make sure "{" is higher in calling chain than Readpattern
				    ;;; and that current context is a list expression lower down
				    lvars
					    invec = iscaller(nonsyntax {),
					    inlist = iscaller(nonsyntax [),
						    inpat = iscaller(Read_Pattern);

						    (inpat < invec) and (inlist < inpat) and item
			    elseif iscaller(nonsyntax {) then
				    ;;; in an embedded vector
				    false
			    else
				    item
			    endif
		    else
			    false
		    endif ->  was_query
	    endif
    enddefine;

	;;; Read in the list expression, planting special code
	apply(nonsyntax [); -> item;

enddefine;


applist([sysPUSHQ], sysprotect);


/*
-- -- User-definable procedures for reading conditions and actions
*/
;;; The two main procedures prb_readcondition and prb_readaction are
;;; are user-definable so that they can easily be replaced by checking
;;; versions, or versions for a different sort of syntax.

;;; A utility for compiling procedures in the current lexical environment

define lconstant prb_compile_procedure(codelist, name, closer, endtrue);
	;;; If codelist is a list then compile it using a temporary proglist,
	;;; with closer as given. Otherwise compile from proglist with closer
	;;; as given. If endtrue is true, plant a push of true at the end, e.g.
	;;; for POP11 actionsin conditions.
	unless closer then ")" -> closer endunless;
	if codelist then
		procedure();
			dlocal proglist = codelist nc_<>[^closer];
			sysPROCEDURE(name, 0);
			pop11_comp_stmnt_seq_to(closer) ->;
			if endtrue then sysPUSHQ(true) endif;
			sysENDPROCEDURE();
		endprocedure();
	else
		;;; code still in proglist, so compile from there
		sysPROCEDURE(name, 0);
		pop11_comp_stmnt_seq_to(closer) ->;
		if endtrue then sysPUSHQ(true) endif;
		sysENDPROCEDURE();
	endif;
	;;; see REF sysENDPROCEDURE on need for sysPUSHQ
	;;; to convert compilation structure to procedure
	sysPUSHQ();
	;;; sysEXECUTE()
enddefine;

;;; Next a utility for reading in VARS actions and conditions

define prb_read_VARS(usevector, name, lexical) -> varspec;
	;;; usevector is a boolean. If true return a two element usevector, otherwise
	;;; a list
	;;; name is the name of the rule, ruleset, rulefamily, or rulesystem,
	;;; and is used to compose a name for the anonymous procedure
	;;; created, if appropriate
	;;; If lexical is true, all variables default to lexical
	;;;  if it is false or the word "DLOCAL" then not lexical
	;;; Reads formats like:
	;;;		[VARS v1 v2 [v3 = <exp>] v4 [[v5 v6] = <exp>] v7]
	;;;		[LVARS v1 v2 [v3 = <exp>] v4 [[v5 v6] = <exp>] v7]
	;;;		[DLOCAL v1 v2 [v3 = <exp>] v4 [[v5 v6] = <exp>] v7]
	;;; It would be nice to make patterns constants where possible,
	dlocal pop_pop11_flags = pop_pop11_flags || POP11_CONSTRUCTOR_CONSTS;

	;;; Discount lexical idents pushed in patterns. I.e. don't treat as type 3
	;;; See REF * VMCODE, and REF * pop_vm_flags
	;;; IS THIS SAFE ???? A.S. Nov 1995
	dlocal pop_vm_flags = pop_vm_flags || VM_DISCOUNT_LEX_PROC_PUSHES;

	lvars codelist = [] , varlist, item, var, initialised = false;
	readitem() ->;	;;; the "["
	readitem() ->;	;;; the keyword "VARS", "LVARS", "DLOCAL"
	
	[%
		until (hd(proglist) ->> item) == "]"  do
			if item == "[" then
				;;; initialised variable, in format
				;;; 	[var = <expression>] or
				;;;     [[var1 var2 ...] = <expression>]

				true -> initialised;
				readitem() -> ;	;;; the "["
				if hd(proglist) == "[" then
					;;;  It's a list of variables for a multiple
					;;; assignment
					listread() -> var;
					lvars item;

					for item in var do
						if lexical == true then
							prb_declare_lvar(item);
							sysEXECUTE();
						else
							$-prb$-prb_declare(dup(item))
						endif
					endfor;
				else
					readitem() ->>item-> var;
					if lexical == true then
						prb_declare_lvar(item);
						sysEXECUTE();
					else
						$-prb$-prb_declare(dup(item))
					endif
                endif;

				if islist(var) then
					;;; prepare code for multiple assignment
					[-> ( %
						fast_for item in var do
							item, ","
						endfor, erase(), % ) ;]
				else
					copylist([-> ^var;])
				endif -> var;

				pop11_need_nextitem("=") ->;
				"[" :: proglist -> proglist;
				codelist nc_<> (read_list_of_items() nc_<> var) -> codelist;
			else
				;;; an uninitialised variable, read it in and declare it
				readitem() -> item;
				if lexical == true then
					prb_declare_lvar(item);
					sysEXECUTE();
				else
					$-prb$-prb_declare(dup(item))
				endif;
			endif
	    enduntil;
	%] -> varlist;

	readitem() -> ; 	;;; the final "]"

	if not(initialised) and not(usevector) then
		if lexical == "DLOCAL" then
			if varlist == [] then
				['WARNING empty [DLOCAL] expression at line ' ^poplinenum]=>
				false
			else
				[DLOCAL ^^varlist]
			endif;
		elseif lexical then
			[LVARS ^^varlist]
		else
			[VARS ^^varlist]
		endif
	else
		;;; Create initialisation procedure for the variables. Default is identfn
		;;; which does nothing.
		lvars string =
			if lexical == "DLOCAL" then 'DLOCAL_'
			elseif lexical then 'LVARS_'
			else 'VARS_' endif;

		if initialised then
			;;; compile the procedure
			prb_compile_procedure(codelist, name and string sys_>< name, ")", false);
			sysEXECUTE();
		else
			identfn
		endif -> initialised;
		if usevector then {^varlist ^initialised}
		else
			if lexical == "DLOCAL" then
				[DLOCAL ^initialised ^^varlist]
			elseif lexical then
				[LVARS ^initialised ^^varlist]
			else
				[VARS ^initialised ^^varlist];
			endif;
		endif
	endif -> varspec;	;;; the result

enddefine;

/*
;;; test it

prb_read_VARS(false, "test", true) =>
[LVARS w1 w2 [w3 = <exp>] w4 [[w5 w6] = <exp>] w7];

prb_read_VARS(false, "test", false),proglist(3),proglist =>
[LVARS v1 v2 [v3 = <exp>] v4 [[v5 v6] = <exp>] v7]
;2,3;
;

prb_read_VARS(true, "test", false) =>
[VARS v1 v2 v3 v4]

prb_read_VARS(true, "TEST",true) =>
[VARS v1 v2 v3 v4]
*/


define $-prb$-readVARS(name, lexical) -> varlist;
	prb_read_VARS(false, name, lexical) -> varlist;
enddefine;


;;; syntax word separating conditions and actions in rule definition
global vars prb_condition_terminators = [; ==> -->];

;;; prb_readcondition pre-compiles WHERE conditions and POP11 conditions

global vars procedure prb_readaction;		;;; defined below

define vars procedure prb_readcondition(vars_spec) -> condition;
	lvars condition, type, item;
	;;; if the condition type is WHERE, read a list of text items.
	dlocal pop_pop11_flags = pop_pop11_flags || POP11_CONSTRUCTOR_CONSTS;

	;;; Discount lexical idents pushed in patterns. I.e. don't treat as type 3
	;;; See REF * VMCODE, and REF * pop_vm_flags
	;;; IS THIS SAFE ???? A.S. Nov 1995
	dlocal pop_vm_flags = pop_vm_flags || VM_DISCOUNT_LEX_PROC_PUSHES;
	if hd(proglist) == "[" then
		hd(tl(proglist)) -> type;
		if type == "WHERE" then
			read_list_of_items() -> condition;
			;;; the tail of the list is code for a procedure. Compile it and
			;;; replace the tail with a list containing only the compiled
			;;; procedure, unless the code includes query variables
			if fast_lmember("?", condition) or fast_lmember("??", condition)
			then
				;;; do not precompile WHERE conditions using query variables.
				;;; SHOULD THIS BE CHANGED?
				mishap(condition, 1, '[WHERE ...] includes "?" or "??"');
				;;; condition
			else
				;;; pre-compile and leave new condition on stack
				sysPUSHQ("WHERE");
				prb_compile_procedure(back(condition), false, ")", false);
				sysPUSHQ(2);
				sysCALLQ(conslist);
				sysEXECUTE();
				[] -> condition;
			endif
		elseif type == "POP11" then
			;;; the tail of the list is code for a procedure. Compile it and
			;;; replace the tail with a list containing only the compiled
			;;; procedure
			readitem() -> ; ;;; the "["
			readitem() -> ; ;;; the "POP11"
				sysPUSHQ("POP11");
				prb_compile_procedure(false, false, "]", false);
				sysPUSHQ(2);
				sysCALLQ(conslist);
				sysEXECUTE();
			[] -> condition;
		elseif member(type, [NOT_EXISTS OR]) then
			;;; make sured embedded WHERE or POP11 conditions are pre-compiled
	    	readitem() ->;	;;; the "["
			[%  readitem();	;;; the keyword
				until hd(proglist) == "]"  do
				 	prb_readcondition(vars_spec);
	            enduntil;
			%];
			readitem() -> ; 	;;; the final "]"
		elseif member(type, [NOT_EXISTS OR]) then
			;;; make sured embedded WHERE or POP11 conditions are pre-compiled
	    	readitem() ->;	;;; the "["
			[%  readitem();	;;; the keyword
				until hd(proglist) == "]"  do
				 	prb_readcondition(vars_spec);
	            enduntil;
			%];
			readitem() -> ; 	;;; the final "]"
		elseif type == "IMPLIES" then
			;;; make sured embedded WHERE or POP11 conditions are pre-compiled
	    	readitem() ->;	;;; the "["
			[%  readitem();	;;; the keyword IMPLIES

				;;; read in condition list for IMPLIES
				[% readitem() ->; ;;; another "["
				 	until hd(proglist) == "]"  do
				 		prb_readcondition(vars_spec);
	            	enduntil;
					readitem() -> ; 	;;; the final "]" for condition list
				%];

				;;; read in then condition for IMPLIES
				prb_readcondition(vars_spec);
			%]; ;;;.dup ==>;
			readitem() -> ; 	;;; the final "]"
		elseif type == "->>" then
			readitem() ->; 	;;; the "["
			readitem() ->; 	;;; the "->>"
			dlocal pop_autoload = false;
			sysPUSHQ(type); readitem() -> item;	;;; the variable
			if isword(item) then
				prb_declare_lvar(item);
			else
				mishap(item, 1, 'NON-WORD AFTER ->> ')
			endif;

			readitem() -> ;		;;; final "]"
			sysPUSHQ(2); sysCALL("conslist"); sysEXECUTE();
		elseif type == "VARS" then
			$-prb$-readVARS('in_rule', false);
		elseif type == "LVARS" then
			$-prb$-readVARS('in_rule', true);
		elseif type == "DLOCAL" then
			;;; don't compile anything if the list is empty
			lvars list = $-prb$-readVARS('in_rule', "DLOCAL");
			if list then list endif;
		elseif type == "FILTER" and proglist(4) == "->" and isword(proglist(5) ->> item) then
			newLVAR(item, true);
			sysEXECUTE();
				-> proglist(5);
			Read_Pattern(vars_spec); sysEXECUTE();
		elseif type == "DO" then
			;;; Read in the action after "DO"
			readitem() -> ;	;;; the "["
			readitem() -> ; ;;; the "DO"
			"[" :: proglist -> proglist;
			[DO] <> prb_readaction(vars_spec)
		else
			Read_Pattern(vars_spec); sysEXECUTE();
		endif
	else
		Read_Pattern(vars_spec); sysEXECUTE();
	endif -> condition;
enddefine;

/*
-- readaction
*/

define lconstant prb_fix_embedded_forms(action)->action;
	;;; precompile any embedded [POP11 ..] or [WHERE ...] or
	;;; or [popval ...] or [$$ ...] forms
	;;; clauses as if they were conditions.
	lvars name;

	if ispair(action)
	and fast_lmember((fast_front(action)->> name), #_< [POP11 WHERE popval $$] >_#)
	and listlength(action) > 2
	then
;;;		[pre-compiling ^action] ==>
		;;; it needs compiling
		prb_compile_procedure
			(back(action), 'EMBEDDED_'sys_><name, ")", false);
				sysEXECUTE();
				 -> front(back(action));
		[] -> back(back(action));
	elseif atom(action) then
		;;; do nothing
	else
		lvars item;
		for item in action do
			prb_fix_embedded_forms(item) ->
		endfor
	endif
enddefine;


define vars procedure prb_readaction(vars_spec) -> action;
	;;; If changed by the user, then care is needed if POP11 actions are
	;;; to be supported.
	lvars action;
	;;; if the action type is POP11, read a list of text items.
	if hd(proglist) == "[" and hd(tl(proglist)) == "POP11" then
		;;; the tail of the list is code for a procedure. Compile it and
		;;; replace the tail with a list containing only the compiled
		;;; procedure
		tl(tl(proglist)) -> proglist;
		
;;;		read_in_items() -> action;
		sysPUSHQ("POP11");
		prb_compile_procedure(false, false, "]", false);
		sysPUSHQ(2);
		sysCALLQ(conslist);
		sysEXECUTE();
	elseif hd(proglist) == "[" and hd(tl(proglist)) == "VARS" then
		$-prb$-readVARS('in_rule', false)	;;; should get rule name
	elseif hd(proglist) == "[" and hd(tl(proglist)) == "LVARS" then
		$-prb$-readVARS('in_rule', true)	;;; should get rule name
	elseif hd(proglist) == "[" and lmember(proglist(2), #_< [MAP SELECT] >_#)
		and isword(proglist(4))
	then
		;;; it's a MAP or select action. Replace the variable with a lexical.
		lvars item = proglist(4); 	;;; the variable
		newLVAR(item, true);
		sysEXECUTE();
		-> proglist(4);	;;; it is now an identifiter
		Read_Pattern(vars_spec); sysEXECUTE();
	else
		Read_Pattern(vars_spec); sysEXECUTE();
	endif -> action;
	prb_fix_embedded_forms(action)->action;
enddefine;

define prb_read_conditions(vars_spec) -> (list, item);
	lvars item;
	if ispair(vars_spec) and fast_front(vars_spec) == "VARS" then
		;;; it is a list, starting with "VARS" then possibly a procedure then
		;;; names of non-lexical variables
		back(vars_spec) -> vars_spec;
		if isprocedure(front(vars_spec)) then
			back(vars_spec) -> vars_spec
		endif
	endif;
		
	[%
		repeat
			prb_readcondition(vars_spec) -> item;
		quitif(lmember(item, prb_condition_terminators));
			unless islist(item) then
				mishap(item,1,'EACH CONDITION MUST BE A LIST. END WITH A TERMINATOR')
			endunless;
			if front(item) == "VARS" then
				;;; extra globals not to be made lexical. Add them
				if isprocedure(item(2)) then back(back(item))
				else back(item)
				endif <> vars_spec -> vars_spec;
			endif;
			item
		endrepeat;
	%] -> list;
enddefine;

define prb_read_actions(vars_spec, terminators) -> (list, item);
	lvars item;
	[%
		repeat
			prb_readaction(vars_spec) -> item;
			quitif(fast_lmember(item, terminators));
			unless islist(item) then
				mishap(item,1,'EACH ACTION MUST BE A LIST. END WITH enddefine')
			endunless;
			if front(item) == "VARS" then
				;;; extra globals not to be made lexical. Add them
				if isprocedure(item(2)) then back(back(item))
				else back(item)
				endif <> vars_spec -> vars_spec;
			endif;
			item
		endrepeat;
	%] -> list;
enddefine;

define prb_rule_named(word /*, list*/) -> rule;
	;;; Given a word, return the rule with that name.
	;;; Can have an optional list as second argument
	;;; otherwise use the default prb_list

	lvars rule, word, list;

	;;; Check for optional second argument
	if islist(word) then word -> list; -> word
	else prb_rules -> list
	endif;

	if list == [] then ;;; empty -- do nothing
	else
		fast_for rule in list do
			;;; ignore things at beginning of list, e.g. integer, vector, section
			if isprbrule(rule) and prb_rulename(rule) == word then
				return();
			endif
		endfast_for;
	endif;
	false -> rule;
enddefine;


define prb_extract_vars(conditions, actions) -> rulevars ;
	;;; extract list of variables in conditions and actions
	;;; But don't include any introduced via [VARS...] or [LVARS....]

	lvars item, VARlist, rulevars = [];

	prb_variables_in(conditions,[],[]) -> (rulevars, VARlist);
	prb_variables_in(actions, rulevars,VARlist) -> (rulevars, VARlist);
	;;; get rid of the list of VARS and LVARS variables
	sys_grbg_list(VARlist);
enddefine;


define init_prb_rule(name, weight, conditions, actions, type, rulevars, create);
	;;; Type determins which rule list to use.
	;;; If there's an existing rule in the list with the name
	;;; change the rule, otherwise create a new rule at the end of
	;;; the list. (So that rule order corresponds to order of
	;;; definition.)

	lvars name, weight, conditions, actions, rule, type;

	;;; Do some checks;
	unless isnumber(weight) then
		mishap('Number needed for weight in rule', [^weight ^name ^type])
	endunless;
	unless islist(conditions) then
		mishap('List needed for conditions in rule', [^conditions ^name ^type])
	endunless;
	unless islist(actions) then
		mishap('List needed for actions in rule', [^actions ^name ^type])
	endunless;

	;;; add names (pdprops) to anonymous procedures in POP11, WHERE
	;;; conditions and actions
	lvars
		POP11name = name sys_>< 'POP11_',
		WHEREname = name sys_>< 'WHERE_',
		VARSname = name sys_>< 'VARS_',
		wherecounter = 1,
		popcounter = 1,
		varscounter = 1,
		list, proc;

	for list in conditions do
		if front(list) == "WHERE" then
			front(fast_back(list)) -> proc;
			unless not(isprocedure(proc)) or pdprops(proc) then
				WHEREname sys_>< wherecounter -> pdprops(proc);
				wherecounter fi_+ 1 -> wherecounter;
			endunless;
		elseif fast_front(list) == "POP11" then
			front(fast_back(list)) -> proc;
			unless pdprops(proc) then
				POP11name sys_>< popcounter -> pdprops(proc);
				popcounter fi_+ 1 -> popcounter;
			endunless;
		elseif fast_front(list) == "VARS" then
			front(fast_back(list)) -> proc;
			if isprocedure(proc) then
				VARSname sys_>< varscounter -> pdprops(proc);
				varscounter fi_+ 1 -> varscounter;
				endif
		endif;
	endfor;

	for list in actions do
		if fast_front(list) == "POP11" then
			front(fast_back(list)) -> proc;
			unless pdprops(proc) then
				POP11name sys_>< popcounter -> pdprops(proc);
				popcounter fi_+ 1 -> popcounter;
			endunless;
		elseif fast_front(list) == "VARS" then
			front(fast_back(list)) -> proc;
			if isprocedure(proc) then
				VARSname sys_>< varscounter -> pdprops(proc);
				varscounter fi_+ 1 -> varscounter;
				endif
		endif;
	endfor;

	lvars rulevars = prb_extract_vars(conditions, actions);
	if create then
		;;; simply create a new rule
		consprbrule(name, weight, conditions, actions, type, rulevars)
	else
		;;; put rule in rulesystem list
		prb_rule_named(name, valof(type)) -> rule;
		if rule then
			;;; rule already exists, so simply update it
        	weight -> prb_weight(rule);
			conditions -> prb_conditions(rule);
			actions -> prb_actions(rule);
			rulevars -> prb_rulevars(rule);
		else
			;;; new rule, so append to the list
			valof(type) nc_<>
			[%consprbrule(name, weight, conditions, actions, type, rulevars)
					->> rule %] -> valof(type);
		endif
	endif
enddefine;


define vars prb_new_rule = init_prb_rule(%false%)
enddefine;

/* END OF FACILITIES FOR DEFINING RULES */

/*
-- FACILITIES FOR TRACING AND INTERACTING
*/

define global vars procedure prb_istraced =
	newproperty([], 100, false, true);
	;;; A property to store information about which rules are to be traced
enddefine;

procedure(x);
	;;; postpone autoloading of prb_trace_rule
	prb_valof("prb_trace_rule")(x,false)
endprocedure -> class_print(prbactivation_key);

define lconstant print_if_non_empty(list);
	if ispair(list) then
		list ==>
	endif
enddefine;

/*
-- FACILITIES FOR FINDING APPLICABLE RULES
*/


define lconstant procedure not_rule_done(rule, found) -> boole;
	;;; rule is the current rule being tested, found is the value of
	;;; prb_found after matching against the database.
	;;; This is invoked only if prb_repeating is false
	lvars rule, found, boole, instance;

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

	fast_for instance in prb_remember do
		if prb_ruleof(instance) == rule and
			same_set(prb_foundof(instance), found)
		then
			IFTRACING
			if prb_chatty and prb_divides_chatty(APPLICABILITY) then
				['Already done' ^(prb_rulename(rule))] ==>
			endif;
			false -> boole;
			return
		endif
	endfor;
	true -> boole
enddefine;

/*
-- -- prb_applicable
*/

lconstant DLOCAL_pattern = [[DLOCAL ==] ==] ;

define lconstant restore_dlocal(dlocal_vars, dlocal_vals, grbg);
	;;; for resetting saved DLOCAL vars
	lvars var, val;
	for var, val in dlocal_vars, dlocal_vals do
		val -> valof(var)
	endfor;
	;;;if grbg then sys_grbg_list(dlocal_vals) endif;
enddefine;
	

global vars rule_instance;	;;; used non locally in prb_eval and prb_eval_list(bad!)

define vars procedure prb_applicable(rules) -> possibles;
	;;; Given a list of all the rules, return a list of possible
	;;; activations. A possible activation is a record containing
	;;; a rule all of whose conditions are satisfied, a list of the
	;;; variables bound, a list of the values, a list of matching
	;;; database items, and if prb_recency is true, a recency record
	;;; - otherwise an empty vector
	lvars rules, possibles, weight, conditions, actions,
		ruletype, rulevars, values;

	dlvars newlen;

	;;; stuff used for tracing etc.
	dlocal
		this_rule, this_rule_name,
		last_stacklength,
		showing_conditions = false;


	define lconstant record_rule_instance(patternlocations, counter);
		;;; Invoked when all conditions of a rule are satisfied.
		;;; Save rule, bound variables and values, for each match
		;;; If prb_recency is true, then the recency values are also saved
		;;; patternlocations and counter come from prb_forevery
		lvars patternlocations, counter, instance,
			bindings = maplist(popmatchvars, valof);

		if prb_repeating
		or not_rule_done(this_rule, prb_found)	;;; uses global prb_remember
		then
			if prb_actions(this_rule) == [] then
			;;; If there are no actions, there's no point creating an activation record.
			;;; (Even without actions there may have been "DO" conditions.)
			;;; But indicate that something was found

				this_rule -> prb_rule_found;
			
			elseif (not(prb_allrules) or not(prb_sortrules)) and prb_repeating then
			;;; if only one action at a time, or there's no user-defined sorting
			;;; procedure, do the actions now. Requires a dummy rule instance.
			;;; Use a dlocal expression to ensure the contents of the dummy are
			;;; reset
				this_rule -> prb_rule_found;	;;; indicate action already done.
				procedure() with_props do_rule_actions;
					;;; Create dummy_instance, to be accessible in actions
					;;; (Actions currently expect an instance. Could change this?)
					lconstant dummy_instance = consprbactivation(false, [], [], [], {});

					lvars found = rev(prb_found);

					this_rule -> prb_ruleof(dummy_instance);
					found -> prb_foundof(dummy_instance);

					define lconstant cleanup();
						;;; action to be executed on exit
						false -> prb_ruleof(dummy_instance);
						[] -> prb_foundof(dummy_instance);
						;;; I think this is safe ???
;;;						sys_grbg_list(found);
						[] -> found;
					enddefine;

					;;; ensure dummy_instance is cleared on exit
					dlocal
						0 %, if dlocal_context == 1 then cleanup() endif%;


					;;; in prb_forevery in prb_applicable
					IFTRACING
					if prb_self_trace then
                    	prb_doing_actions_trace(
							sim_myself,
							prb_ruleset(this_rule),
							copy(dummy_instance))     ;;; rule has fired
					endif;

					IFTRACING
					if prb_chatty then
						if not(prb_walk) and prb_divides_chatty(SHOWRULES) then
							[['Doing RULE' ^(prb_rulename(this_rule))] [ACTIONS ^actions]] ==>
						else
							[Rule found ^(prb_rulename(this_rule))] =>
						endif
					endif;

					;;; Now perform all the actions in the rule, using the environment
					;;; for matcher variables set up in prb_forevery
					lvars action;

					fast_for action in prb_actions(this_rule) do
						prb_do_action(action, this_rule, dummy_instance);
						quitif(prb_rule_found == "QUIT")
					endfor;

					;;;; clear the instance
					stacklength() -> newlen;
					unless last_stacklength == newlen then
						mishap('Stack altered in prb_forevery: old ' >< last_stacklength ><
							' new ' >< newlen, [rule ^this_rule])
					endunless;
				endprocedure();

				unless prb_allrules then
					exitto(prb_applicable)	;;; i.e. leave get_rules
				elseif prb_allrules == 1 and not(prb_sortrules) then
					exitto(prb_applicable)	;;; i.e. leave get_rules
				endunless;

			else
				;;; create a rule instance
				consprbactivation(
					this_rule, popmatchvars, bindings, rev(prb_found),
#_IF prb_recency
					if prb_recency then
						lblock lvars n;
							{%fast_for n to counter do
							 		fast_subscrv(n, patternlocations)
					 			endfor%}
						endlblock;
					else #_< {} >_#		;;; a constant empty vector
					endif
#_ELSE
					#_< {} >_#		;;; a constant empty vector
				
#_ENDIF
					) ->> instance -> prb_rule_found;

				stacklength() -> newlen;
				unless last_stacklength == newlen then
					mishap('Stack altered in prb_forevery: old ' >< last_stacklength ><
						' new ' >< newlen, [rule ^this_rule])
				endunless;

				instance;	;;; the result

				last_stacklength + 1 -> last_stacklength;

				IFTRACING
				if (prb_chatty and prb_divides_chatty(APPLICABILITY))
				or prb_istraced(prb_rulename(this_rule))
				then
					'FOUND RULE WITH SATISFIED CONDITIONS' =>
					instance ==>
				endif;

				unless prb_allrules  /* or prb_backtrack */ then
					exitto(prb_applicable)	;;; i.e. leave get_rules
				endunless;
			endif

		else

			IFTRACING
			if prb_chatty and prb_divides_chatty(APPLICABILITY) then
				['Rule already done previously'
					^this_rule
					[' With conditions matching :'^prb_found]
				] ==>
			endif;
		endif;
	enddefine;

	define lconstant get_rules();
		lvars oldmatchvars = popmatchvars,
		dlocal_spec = false,
		dlocal_vars = [],
		dlocal_vals = [],
		;
		;;; set dlocal to restore values changed by [DLOCAL ...]
		dlocal 0
			%, (if dlocal_context < 3 and dlocal_spec then
					restore_dlocal(dlocal_vars, dlocal_vals, true) endif)%;

		;;; NB "this_rule" is global

		fast_for this_rule in rules do
			oldmatchvars -> popmatchvars;

			if dlocal_spec then
				;;; reset environment since last ruleset
;;; [DLOCAL [VARS ^dlocal_vars][VALS ^dlocal_vals]] =>
				restore_dlocal(dlocal_vars, dlocal_vals, true);
;;; [DLOCAL [VARS ^dlocal_vars][VALS ^dlocal_vals]] =>
				false -> dlocal_spec;
				[] -> dlocal_vals;
			endif;


			destprbrule(this_rule) ->
				(this_rule_name, weight, conditions, actions, ruletype, rulevars);

			;;; Now see if the conditions start with [[DLOCAL ..] ..]
			if conditions matches  DLOCAL_pattern then
				fast_destpair(conditions) -> (dlocal_spec, conditions);
				destpair(fast_back(dlocal_spec)) -> (dlocal_spec, dlocal_vars);
				;;; dlocal_spec is now the procedure
				;;; save the values

		;;;;[DLOCAL_SETTING vars ^dlocal_vars]==>

				maplist(dlocal_vars, valof)-> dlocal_vals;
				;;; set the new values
				dlocal_spec();

		;;;;[DLOCAL_OLD vals ^dlocal_vals]==>
			endif;


			IFTRACING
			if prb_show_conditions == true
			or (ispair(prb_show_conditions)
				and lmember(this_rule_name, prb_show_conditions))
			then
				;;; set the variable that controls a lot of trace printing
				true -> showing_conditions
			else
				false -> showing_conditions
			endif;

			IFTRACING
			if prb_self_trace then
				prb_checking_conditions_trace(sim_myself, ruletype, this_rule)
			endif;

			IFTRACING
			if showing_conditions or (prb_chatty and prb_divides_chatty(APPLICABILITY))
			then
				['Checking conditions for:' ^this_rule_name in ^ruletype] =>
				conditions ==>
			endif;

			;;; Check if necessary to change section for this rule type
			IFSECTIONS
			prb_check_section(this_rule);

			stacklength() -> last_stacklength;
			prb_forevery(conditions, record_rule_instance);

			;;; Reset the rulevars which may have been set by the matcher
			;;; this will not affect variables introduced via VARS or LVARS
			lvars item;
			for item in rulevars do
				unless fast_lmember(item, oldmatchvars) then
					undef -> valof(item)
				endunless
			endfor;

			IFTRACING
			if showing_conditions then
				['Finished checking conditions for:' ^this_rule_name] ==>
			endif;
		endfast_for
	enddefine;

	;;; run get_rules, and make a list of everything new on the
	;;; stack. Should be only rule instances.
	lvars len = stacklength();
	get_rules();
	conslist(stacklength() fi_- len) -> possibles;

enddefine;

/* END FACILITIES FOR FINDING APPLICABLE RULES */

/*
-- FACILITIES FOR DOING THE ACTIONS OF RULES
*/

/*
-- -- Property for mapping keywords to action types
*/

#_IF identprops("prb_action_type") == undef
;;; Prevent re-initialisation of this property

define global vars procedure prb_action_type =
	newproperty([], 64, false, true)
enddefine;

#_ENDIF

/*
-- -- Autoloadable action types
*/
;;; Some actions provided via autoloadable library files.
;;; Postpone autoloading till the actions are selected

;;; Procedures must be of form  do_something(rule_instance, action)

"prb_read_info"  -> prb_action_type("READ");

"prb_menu_interact" -> prb_action_type("MENU");

"prb_pause_read" -> prb_action_type("PAUSE");

"prb_do_all" -> prb_action_type("DOALL");
"prb_select_action" -> prb_action_type("SELECT");
"prb_map_action" -> prb_action_type("MAP");
prb_add_action_vars -> prb_action_type("VARS");
prb_add_action_vars -> prb_action_type("LVARS");

"prb_push_or_pop" -> prb_action_type("PUSH");
"prb_push_or_pop" -> prb_action_type("POP");

"prb_make_rule"   -> prb_action_type("RULE");

"prb_save_or_restore" -> prb_action_type("SAVE");
"prb_save_or_restore" -> prb_action_type("RESTORE");

erasenum(%2%) -> prb_action_type("NULL");

/*
-- -- Other action types defined here
*/

define prb_do_DEL(item, foundlist);
	;;; for use in DEL, MODIFY or REPLACE actions.
	;;; item is an integer or database item, foundlist is a list of
	;;; database items.
	lvars item, foundlist;
	if islist(item) then prb_flush1(item)
	elseif isinteger(item) then
		if listlength(foundlist) fi_< item then
			mishap(0, 'Not enough items for DEL ' sys_>< item)
		else
			prb_flush1(foundlist(item))
		endif
	else
		mishap(item, 1, 'WRONG ARGUMENT FOR DEL OR REPLACE')
	endif;
enddefine;

define prb_DEL(rule_instance, action);
	lvars rest = fast_back(action), item;
	if rest == [] then
		mishap(prb_ruleof(rule_instance), 1, 'NO VALUE GIVEN IN DEL ACTION')
	else
		fast_for item in rest do
			prb_do_DEL(item, prb_foundof(rule_instance))
		endfor
	endif;
enddefine;

prb_DEL -> prb_action_type("DEL");


define lconstant procedure prb_MODIFY(rule_instance, action);
	;;; Changed  29 Jan 1996 to be in an action property, instead of inline

	;;; Modlist is what followed [MODIFY .. It should start with
	;;; either an integer n, or a pattern or list, followed by attribute
	;;; value pairs.
	;;; Remove the nth item of foundlist from prb_database, and
	;;; replace it with a modified version where the item following
	;;; key is the value. If prb_copy_modify is false then the
	;;; replacement is non-constructive, but modified items are
	;;; brought to the front of the database
	lvars n, key, value,
		foundlist = prb_foundof(rule_instance),
		modlist = fast_back(action),
		found,
		next;

	dlocal prb_found = [], prb_recording = true; ;;; for prb_flush

	destpair(modlist) -> (n,  modlist);

	unless (listlength(modlist) mod 2) == 0 then
		mishap(modlist, 1, 'MODIFY list has wrong number of elements')
	endunless;

	if isinteger(n) then
		;;; so should match at most one thing.
		prb_do_DEL(n, foundlist);
	elseif ispair(n) then
		prb_flush(n)
	else
		mishap('INTEGER OR LIST NEEDED AFTER "MODIFY"',
				[^action ^rule_instance])
	endif;

	;;; things deleted will now be in prb_found

	unless ispair(prb_found) then
		mishap('Nothing found for MODIFY action',
			[^action ^rule_instance])
	endunless;

	IFTRACING
	if prb_self_trace then
		prb_modify_trace(sim_myself, prb_found, action, rule_instance)
	endif;

	if prb_copy_modify then
		lblock lvars list;
		fast_for list in prb_found do
			;;; do substitution, and then add to database
			[% until list == [] do
					 if back(list) == [] then
						fast_front(list);
						quitloop()
					 endif;
					 front(list) -> next;
					 if prb_assoc(next, modlist) ->> value then
						 next, value,
						 fast_back(list) -> list;	;;; ignore next element of list
					 else next
					 endif;
					 back(list) -> list;
				 enduntil %] -> list;

			prb_add(list)
		endfor;
		endlblock;
		sys_grbg_list(prb_found);  ;;; ????? SAFE???
	else
		lblock lvars list, key;
		repeat
		quitif(prb_found == []);
			 sys_grbg_destpair(prb_found) ->(list,  prb_found);	;;; danger ???
			;;;;;destpair(prb_found) ->(list,  prb_found);	;;; danger
			;;; Add to database and then do destructive substitution
			front(list) -> key;
			conspair(list, prb_database(key)) -> prb_database(key);
			until list == [] do
				fast_front(list) -> next;
				if prb_assoc(next, modlist) ->> value then
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

prb_MODIFY -> prb_action_type("MODIFY");

;;; Make this autoloadable
"prb_RMODIFY" -> prb_action_type("RMODIFY");

define lconstant prb_REPLACE(rule_instance, action);
	lvars rest = fast_back(action);
	prb_do_DEL(front(rest), prb_foundof(rule_instance));
	prb_add(front(fast_back(rest)))
enddefine;

prb_REPLACE -> prb_action_type("REPLACE");

define lconstant prb_STOP(rule_instance, action);
	print_if_non_empty(fast_back(action));
;;;	"STOP" -> prb_rule_found;
	exitto(prb_run_with_matchvars)
enddefine;

prb_STOP -> prb_action_type("STOP");

define lconstant prb_STOPIF(rule_instance, action);
	lvars rest = fast_back(action);
	if ispair(rest) then
		if recursive_valof(fast_front(rest)) then
			print_if_non_empty(fast_back(rest));
			exitto(prb_run_with_matchvars)
		endif
	else
		mishap('MISSING ITEM AFTER STOPIF', [^action])
	endif;
enddefine;

prb_STOPIF -> prb_action_type("STOPIF");


define lconstant prb_QUIT(rule_instance, action);
	print_if_non_empty(fast_back(action));
	"QUIT" -> prb_rule_found;
enddefine;

prb_QUIT -> prb_action_type("QUIT");

define lconstant prb_QUITIF(rule_instance, action);
	lvars rest = fast_back(action);
	if ispair(rest) then
		if recursive_valof(fast_front(rest)) then
			print_if_non_empty(fast_back(rest));
			"QUIT" -> prb_rule_found;
		endif
	else
		mishap('MISSING ITEM AFTER QUITIF', [^action])
	endif;
enddefine;

prb_QUITIF -> prb_action_type("QUITIF");



define lconstant prb_ADDALL(rule_instance, action);
	applist(fast_back(action), prb_add)
enddefine;

prb_ADDALL -> prb_action_type("ADDALL");

define lconstant prb_do_POP11(rule_instance, action);
	;;; First item should be a pop procedure or its name. Run it.
	prb_valof(front(fast_back(action)))()
enddefine;

prb_do_POP11 -> prb_action_type("POP11");

define lconstant prb_SAY(rule_instance, action);
	prb_instance(fast_back(action)) ==>
enddefine;

prb_SAY -> prb_action_type("SAY");


define lconstant prb_SAYIF(rule_instance, action);
	lvars rest = fast_back(action);
	;;; conditional reporting, easily turned on or off.
	if member(front(rest), prb_sayif_trace) then
		prb_instance(fast_back(rest)) ==>
	endif
enddefine;

prb_SAYIF -> prb_action_type("SAYIF");

define lconstant prb_EXPLAIN(rule_instance, action);
	if prb_explain_trace then
		prb_instance(fast_back(action)) ==>
	endif
enddefine;

prb_EXPLAIN -> prb_action_type("EXPLAIN");

define lconstant prb_ADD(rule_instance, action);
	;;; for explicit [ADD ...] action types
	prb_add(fast_back(action));
enddefine;

prb_ADD -> prb_action_type("ADD");

define prb_instance_present(list) /* -> boolean */;
	;;; list is instantiated, so use first item as key, and
	;;; see if list is in the relevant list in the database
	member(list, prb_database(front(list)))
enddefine;

define lconstant prb_TEST_ADD(rule_instance, action);
	lvars rest = fast_back(action);
	unless prb_instance_present(rest) then prb_add(rest) endunless
enddefine;

prb_TEST_ADD -> prb_action_type("TEST_ADD");
prb_TEST_ADD -> prb_action_type("TESTADD");

define prb_ADDIF(rule_instance, action);
	lvars rest = fast_back(action);
	if prb_present(front(rest)) then
		applist(fast_back(rest), prb_add)
	endif
enddefine;

define prb_ADDUNLESS(rule_instance, action);
	lvars rest = fast_back(action);
	unless prb_present(front(rest)) then
		applist(fast_back(rest), prb_add)
	endunless
enddefine;

prb_ADDIF -> prb_action_type("ADDIF");
prb_ADDUNLESS -> prb_action_type("ADDUNLESS");

/*
-- -- Template for new action types


define lconstant prb_XXX(rule_instance, action);
	lvars rest = fast_back(action);
enddefine;

prb_XXX -> prb_action_type("XXX");

*/


/*
-- -- prb_do_action
*/

define vars procedure prb_do_action(action, current_rule, rule_instance);
	lvars action, current_rule;
	dlocal
		rule_instance,
		popautolist = savedautolist;

	lvars rest, key, action_procedure, len = stacklength();

	returnif(action == []);		;;; another type of NULL action

	prb_value(action) -> action;	;;; does nothing if no variables
	destpair(action) -> (key, rest);

	;;; Do "walking: pause if necessary (Autoload, if needed)

	IFTRACING
	if prb_walk or prb_istraced(prb_rulename(current_rule)) then
		prb_valof("prb_walk_trace")(rule_instance, action)
	endif;

	IFTRACING
	if prb_self_trace then
    	prb_do_action_trace(sim_myself, action, rule_instance)
	endif;

	if prb_actions_run then
		unless fast_lmember(key, #_< [STOP STOPIF STOPAGENT STOPAGENTIF] >_#) then
			;;; This counter is used by LIB * SIM_AGENT to tell whether an
			;;; agent has been able to do anything in the current time slice.
			prb_actions_run + 1 -> prb_actions_run
		endunless;
	endif;

	if (prb_action_type(key) ->> action_procedure) then
		;;; Allows autoloading of new action types, if originally
		;;; only name is declared
		;;; User-defined action, so do it. (It could be a procedure name)
		prb_valof(action_procedure)(rule_instance, action)
	elseif key == "NOT" then
		IFTRACING
		if prb_chatty and prb_divides_chatty(DATABASE_CHANGE) then
			['REMOVE' ^^rest] ==>
		endif;
		prb_flush(rest);
/*
;;; Moved the following action types to property 29 Jan 1996:
	MODIFY DEL REPLACE PUSH POP STOP ADDALL RULE SAVE RESTORE POP11 SAY
	SAYIF NOT
*/
	else
		if prb_auto_add then
			prb_add(action)
		else
			mishap('UNRECOGNIZED ACTION FORM (prb_auto_add is false)',
					[^action])
		endif;
	endif;
	lvars len2 = stacklength(), items = false;
	unless len2 == len then
		if len2 > len then
		consvector(len2 - len)  -> items;
		endif;
		mishap('STACK CHANGED IN ACTION: old='sys_>< len sys_>< ', new='sys_>< len2,
			[%
				if items then
					'\n;;; ON THE STACK:', explode(items),
				endif,
				'\n;;; RULE INSTANCE:\n', rule_instance%])
	endunless;

enddefine;

define vars prb_do_action_now(list);
	;;; Invoked in a condition of form [DO <action>]
	;;; which allows actions and conditions to be interleaved
	;;; the [<action>] is passed to this procedure
	lconstant dummy_instance = consprbactivation(false, [], [], [], {});

	dlocal %prb_ruleof(dummy_instance)% = this_rule;

	prb_do_action(list, this_rule, dummy_instance);
	true
enddefine;

"prb_do_action_now" -> prb_condition_type("DO");

define prb_do_in_data(rule_instance, action);
	lvars
		rest = fast_back(action),
		db = front(rest),
		rule = prb_ruleof(rule_instance),
		;
	unless isproperty(db) then
		mishap('DATABASE needed in [INDATA ...] action',
			[^action ^rule])
	endunless;

	;;; set up new database, then do the action
	dlocal prb_database = db;

	prb_do_action(front(fast_back(rest)), rule, rule_instance);

enddefine;

prb_do_in_data -> prb_action_type("INDATA");


;;; The next two use rule_instance non-locally.

define prb_eval(action);
	;;; user interface to prb_do_action
	lvars action;
	prb_do_action(action, prb_ruleof(rule_instance), rule_instance);
enddefine;

define prb_eval_list(actions);
	;;; user interface to prb_do_action applied to a list
	lvars action, actions;
	for action in actions do
		prb_do_action(action, prb_ruleof(rule_instance), rule_instance);
	returnif(prb_rule_found == "QUIT")
	endfor
enddefine;


define lconstant procedure prb_do_actions(rule_instance);

	;;; This runs the actions of a particular rule rule_instance
	dlocal rule_instance;

	lvars
		 current_rule = prb_ruleof(rule_instance),
		 actions = prb_actions(current_rule),
		 bindings = prb_valsof(rule_instance),
		 ;

	dlocal popmatchvars = prb_varsof(rule_instance), prb_found;

	;;; Setup environment for actions
	lblock lvars var, val;
		for var,val in popmatchvars, bindings do
			val -> valof(var)
		endfor;
	endlblock;

	;;; in prb_do_actions
	IFTRACING
	if prb_self_trace then
    	prb_doing_actions_trace(
			sim_myself, prb_ruleset(current_rule), rule_instance)
	endif;

	IFTRACING
	if prb_chatty then
		if not(prb_walk) and prb_divides_chatty(SHOWRULES) then
			[['Doing RULE' ^(prb_rulename(current_rule))] [ACTIONS ^actions]] ==>
		endif
	endif;

	prb_eval_list(actions);

enddefine;

/*
-- -- prb_do_rule_actions
;;; was prb_do_rule
*/

define lconstant prb_do_rule_actions(rule_instance, counter);
	;;; A rule has been selected from the list of possibilities, and
	;;; an instance created
	;;; Set up the environment for the rule and run it.
	;;; The counter is the counter used in prb_do_rules
	lvars rule, rule_instance, bindings, name, instances, counter;

	dlocal popmatchvars, prb_found;
	prb_ruleof(rule_instance) -> rule;

	prb_rulename(rule) -> name;

	;;; Check that the conditions are still valid, if necessary

	if counter /== 1 and (prb_allrules /* or prb_backtrack */)
	then
		IFTRACING
		if (prb_chatty and prb_divides_chatty(APPLICABILITY)) or prb_istraced(name) then
			['Checking if rule' ^name 'is still applicable'] =>
		endif;

		lblock lvars item;
			prb_foundof(rule_instance) -> prb_found;
			;;; Changed to use hash tabled databases
			fast_for item in prb_found do
				;;; use front of item to key into prb_database
				unless fast_lmember(item, prb_database(fast_front(item))) then
					IFTRACING
					if (prb_chatty and prb_divides_chatty(APPLICABILITY)) or prb_istraced(name) then
						[^name 'inapplicable' ^item 'missing'] ==>
					endif;
					return()
				endunless;
			endfast_for
		endlblock
	endif;

	IFTRACING
	if (prb_chatty and prb_divides_chatty(APPLICABILITY)) or prb_istraced(name) then
		[^name 'Is still applicable'] =>
	endif;

    ;;; All conditions found still true, so  do actions

/*
	;;; in prb_do_rule_actions
	;;; NOT HERE. already invoked in prb_do_actions
	prb_doing_actions_trace(sim_myself, prb_ruleset(rule), rule_instance);
*/
	prb_do_actions(rule_instance);

	if prb_remember or not(prb_repeating) then
		;;; used for "why" questions, and for checking repetitions
		conspair(rule_instance, prb_remember) -> prb_remember
	elseunless /* prb_backtrack or */ prb_sortrules
	or (prb_allrules == true)
	then
		;;; restore re-usable list cells.
;;;		sys_grbg_list(prb_varsof(rule_instance));
		sys_grbg_list(prb_valsof(rule_instance));
		sys_grbg_list(prb_foundof(rule_instance))
	endif;
enddefine;

/* END FACILITIES FOR DOING THE ACTIONS OF RULES */

/*
-- THE TOP LEVEL FACILITIES FOR prb_run
*/

/*
-- -- prb_do_rules
*/

define lconstant setup_matchvars(vec);
	;;; vec should be a procedure with two components,
	;;; a list of words to be added to popmatchvars and a
	;;; procedure to run to set up the values of the variables, or a
	;;; word naming a procedure.
	lvars list = fast_subscrv(1, vec);
	;;; Set up the variables. Assume they have already been declared.
	prb_extend_popmatchvars(list, popmatchvars) -> popmatchvars;
	;;; now run the procedure
	prb_valof(fast_subscrv(2, vec))()
enddefine;

;;; This runs in the main top level loop in prb_run
;;; define lconstant procedure prb_do_rules(rules);
define procedure prb_do_rules(rules);
	;;; Find applicable rules and run them (or it)

	lvars rules, rule_instance, counter = 0, possibles;

	dlocal
		popmatchvars,
		;

	;;;; false -> prb_rule_found;	;;; done in prb_run_with_matchvars
	prb_applicable(rules) -> possibles;
	

	IFTRACING
	if prb_chatty then  ;;; previously "or prb_divides_chatty(APPLICABLE) then"
		unless possibles == [] and prb_rule_found then
			['Possible rules'
				^(maplist(possibles, prb_activation_name))] ==>
		endunless
	endif;


	;;; Sort possible rule instances. Perhaps should be done every
	;;; time round the until loop below?
	if prb_sortrules then
		if isprocedure(prb_sortrules) then
			prb_sortrules(possibles) -> possibles;

			IFTRACING
			if prb_chatty and prb_divides_chatty(APPLICABLE) then
				'Rules after sorting' =>
				maplist(possibles, prb_activation_name) ==>
			endif;
		else
			mishap('Procedure value expected for PRB_SORTRULES',
						[^prb_sortrules])
		endif;
	endif;


	if possibles == [] then
		unless prb_rule_found then
			exitto(prb_run_with_matchvars)
		endunless
	else
		true -> prb_rule_found;
		if prb_useweights then
			IFTRACING
			if prb_chatty and prb_divides_chatty(TRACE_WEIGHTS) then
				'About to select by weight' =>
			endif;
		  	lblock
    			lvars best_rule, max_weight, weight;
	    		;;; get rule with highest weight
				destpair(possibles) ->(best_rule, rules);
				prb_weight(prb_ruleof(best_rule)) -> max_weight;
				for rule_instance in rules do
					prb_weight(prb_ruleof(rule_instance)) -> weight;
					if weight > max_weight then
						rule_instance -> best_rule;
						weight -> max_weight
					endif;
					IFTRACING
					if prb_chatty and prb_divides_chatty(TRACE_WEIGHTS) then
						['best_rule so far' ^best_rule weight ^max_weight] =>
					endif;
				endfor;
				[^best_rule] -> possibles;
		  	endlblock
		endif;

		until possibles == [] do
			counter fi_+ 1 -> counter;
			if prb_sortrules /* and not(prb_backtrack) */ then
				destpair
			else
				sys_grbg_destpair
				;;; destpair
			endif(possibles) -> (rule_instance, possibles);

			;;; Check if necessary to change section for this rule type
			IFSECTIONS
			prb_check_section(prb_ruleof(rule_instance));

			;;; Now go through all the actions
			prb_do_rule_actions(rule_instance, counter);

			unless prb_remember or not(prb_repeating) then
				;;; Return temporary found list, produced by "rev", to free store
				sys_grbg_list(prb_foundof(rule_instance));
				[] -> prb_foundof(rule_instance);
			endunless;

		quitunless(prb_allrules);
		quitif(prb_allrules == 1);
		enduntil
	endif;
enddefine;

/*
-- -- prb_finish
*/

define vars procedure prb_finish(rules, data);
	lvars rules, data;
	;;; A user defineable procedure that takes the rules and the
	;;; data when prb_run is finished. E.g. could save them on stack
	;;; The default version does nothing.
enddefine;

/*
-- -- prb_run
*/

;;; To allow degree of flexibility with change from database of lists to
;;; property tables this can be called with 3 options for the second argument:
;;; 1) List of lists (inc []) : create internal property table
;;; 2) a property table, in which case assign locally to prb_database
;;; 3) a list of property tables which need concatenating
;;;		to a single list and put in new property table

;;; Also allow prb_rulefamily for prb_rules

define global vars procedure prb_no_rule_found_trace(rules, data);
	;;; Should this have a default definition like this or should it
	;;; do nothing?
	lvars type;

	if isword(rules) then rules
	elseif rules == [] then "empty"
	else prb_ruleset(hd(rules))
	endif -> type;
	IFTRACING
	if prb_chatty then
		[no runnable rules found for ^type] =>
	endif;
enddefine;

define global vars prb_ruleschanged_trace(ruleset, family);
	;;; User definable
	;;; may run if prb_trace_ruleschanged is true and the current ruleset changes
	;;; Runs before the ruleset gets interpreted.
	;;; ['New ruleset' ^ruleset'in family' ^family] ==>
enddefine;

define global vars procedure prb_no_rule_found_action(rules, data, cycle);
	;;; To be defined by users
		prb_no_rule_found_trace(rules, data);
enddefine;

define vars prb_run_with_matchvars(rules, database, limit);
	;;; Version of prb_run that does not reset popmatchvars
	;;; This one does the real work. prb_run, below is provided as the
	;;; interface for stand-alone uses of poprulebase.
	;;; E.g. for use in sim_agent

	lvars limit, database, rflim, rfvarsvec, oldprb_rules
		dlocal_spec = false,
		dlocal_vars = [],
		dlocal_vals = [],
	;

	if limit == 0 then false -> limit endif;

	dlocal
		popmatchvars,
		savedautolist = popautolist,
		prb_rules,
		prb_ruleset_name,
		prb_current_family,
		prb_family_name = undef,
		prb_remember,
		prb_database,
		prwarning = prb_prwarning,	;;; prevent "declaring variable" messages
		popautolist = [],	;;; prevent autoloading in popval
		last_stacklength = stacklength(),
	;

	;;; Save current section and restore it on exit. See HELP * DLOCAL
	IFSECTIONS
	lvars origsect = current_section;

	IFSECTIONS
	dlocal 0 %, (if current_section /== origsect
				and dlocal_context < 3 then
				origsect -> current_section endif)%;

	;;; set dlocal to restore values changed by [DLOCAL ...]
	dlocal 0
		%, (if dlocal_context < 3 and dlocal_spec then restore_dlocal(dlocal_vars, dlocal_vals, true) endif)%;

	;;; Now convert the second argument to a database property if necessary
	if islist(database) then
		if database /== [] and isproperty(front(database)) then
			;;; assume it is a list of databases. Concatenate to
			;;; new database
			prb_newdatabase(prb_max_keys, []) -> prb_database;
			lblock lvars db;
    			for db in database do
					prb_add_db_to_db(db, prb_database)
				endfor
			endlblock;
		else
			;;; List of database items given
			prb_newdatabase(prb_max_keys, database)-> prb_database;
		endif;
	elseif isproperty(database) then database -> prb_database;
	else mishap('Database not of acceptable type for prb_run', [^database]);
	endif;
	;;;; for debugging [^sim_myself ^rules] ==>
	;;; Now work out if rules is a rulefamily or a ruleset,
	;;; and sort out initialisation

	if isword(rules) then
		rules -> prb_ruleset_name;
		recursive_valof(rules) -> rules;
	endif;

	if isprb_rulefamily(rules) then
		if prb_ruleset_name then
			prb_ruleset_name -> prb_family_name;
		endif;

		IFTRACING
		if prb_show_ruleset then
			['Starting prb_run with rulefamily' ^(rules)]=>
		endif;
		;;; restore the appropriate ruleset from the rulefamily
		rules -> prb_current_family;
		prb_next_ruleset(prb_current_family) -> prb_rules;
		if isword(prb_rules) then
			prb_rules -> prb_ruleset_name;
			recursive_valof(prb_rules) -> prb_rules;
		elseif isident(prb_rules) then
			prb_rules -> prb_ruleset_name;
			idval(prb_rules) -> prb_rules
		endif;

		unless prb_rules then
			mishap('NO INITIAL RULESET IN RULESYSTEM', [^prb_current_family])
		endunless;

		;;; get the name->ruleset property
		prb_family_prop(prb_current_family) -> prb_current_rule_prop;

		;;; If necessary, use the section in this rulefamily
		IFSECTIONS
		lvars temp = prb_family_section(prb_current_family);
		IFSECTIONS
		if issection(temp) then
			unless current_section == temp then
				temp -> current_section
			endunless
		endif;

		;;; If there's information about popmatchvars, set it up
		;;; for this rulefamily.
		prb_check_vars_vec(prb_family_matchvars(prb_current_family)) -> rfvarsvec;
		prb_check_stack('in family ', prb_current_family, 2);	

		;;; Check if rulefamily spec included [DLOCAL ...]

		prb_family_dlocal(prb_current_family) -> dlocal_spec;
		if dlocal_spec then
			destpair(back(dlocal_spec)) -> (dlocal_spec, dlocal_vars);
			;;; dlocal_spec is now the procedure
			;;; save the values
			maplist(dlocal_vars, valof) -> dlocal_vals;
			;;; set tne new values
			dlocal_spec();
			prb_check_stack('Setting DLOCAL', dlocal_spec, 2);
		endif;
	else
		false -> prb_current_family;
		rules -> prb_rules;
	endif;

	;;; check that prb_repeating and prb_copy_modify are not both
	;;; false
	if not(prb_repeating) and not(prb_copy_modify) then
	
		IFTRACING
		'PRB_REPEATING is false, so PRB_COPY_MODIFY is being set true' => ;
		true -> prb_copy_modify
	endif;

	;;; Initialise prb_remember. Perhaps withdraw this in sim_agent?
	if prb_remember or not(prb_repeating) then [] -> prb_remember endif;
	lvars
		cycle = 1, 			;;; for counting cycles.
		;;; Next two are used for run-time checks & debugging
		len1 = stacklength();

	procedure();
		;;; run a procedure, so that exitto prb_run_with_matchvars
		;;; comes out of this

		;;; Save initial popmatchvars
		lvars
			oldrules = false,	;;; to record if rules have changed
			rule_type = false,
			origmatchvars = popmatchvars,
			oldmatchvars = popmatchvars,
			orig_dlocal_spec = dlocal_spec,
			orig_dlocal_vars = dlocal_vars,
			orig_dlocal_vals = dlocal_vals,
			newlocal_spec = false,
			newlocal_vars = [],
			newlocal_vals = [],
		;


		dlocal 0
			%, (if dlocal_context < 3 and newlocal_spec then restore_dlocal(newlocal_vars, newlocal_vals, true) endif)%;

		;;; Setup prb_rules. It can be a word, an identifier, or
		;;; a list of rules, the ruleset to be used. It may be changed
		;;; by an action

		repeat
			;;; Restore initial popmatchvars so as to allow those variables to
			;;; be referenced in conditions.
			oldmatchvars -> popmatchvars;
			quitif(prb_rules == []);

			;;; This will be made true if the current ruleset in the current rulefamily
			;;; changes, if a rulefamily is being run.
			;;; It will also become true if some action not concerned with rulefamilies
			;;; changes the current ruleset.
			lvars ruleschanged = false;

			if prb_rules /== oldrules then
				true -> ruleschanged;
				;;; ruleset has changed
				;;; Dereference if necessary
				if isident(prb_rules) then
					prb_rules -> prb_ruleset_name;
					idval(prb_rules) -> prb_rules
				elseif isword(prb_rules) then
					prb_rules -> prb_ruleset_name;
					valof(prb_rules) -> prb_rules;
				endif;

				if prb_current_family then
					IFTRACING
						if prb_trace_ruleschanged then
							/* ruleschanged must be true here */
							prb_ruleschanged_trace(prb_ruleset_name, prb_family_name)
						endif;
				endif;
						
				unless ispair(prb_rules) then
					mishap('LIST OF RULES NEEDED. Is LIB RULESETS loaded?',
						[^prb_rules])
				endunless;

				;;; and the original popmatchvars
				origmatchvars ->> popmatchvars -> oldmatchvars;
				;;; and possibly the section
				IFSECTIONS
				unless current_section == origsect then
					;;; can be expensive to change sections
					origsect -> current_section
				endunless;

				if newlocal_spec then
					;;; reset environment since last ruleset
					restore_dlocal(newlocal_vars, newlocal_vals, true);
					false -> newlocal_spec;
					[] -> newlocal_vals;
				endif;

				;;; see if new ruleset changes environment
				if prb_rules matches DLOCAL_pattern then
					fast_destpair(prb_rules) -> (newlocal_spec, prb_rules);
					destpair(fast_back(newlocal_spec)) -> (newlocal_spec, newlocal_vars);
					;;; newlocal_spec is now the procedure
					;;; save the values
					maplist(newlocal_vars, valof)-> newlocal_vals;
					;;; set tne new values
					newlocal_spec();
					prb_check_stack('setting DLOCALs', newlocal_spec, 2);
				else
					false -> newlocal_spec;
					[] ->> newlocal_vars -> newlocal_vals;
				endif;

				prb_check_cycle_limit_and_vars(prb_rules) -> (rflim, rfvarsvec, prb_rules);
				;;; rflim should always be false
				if rfvarsvec then
					;;; new popmatchvars
					popmatchvars -> oldmatchvars;	;;; reset to this on each cycle
				endif;

				IFTRACING
				if prb_show_ruleset and prb_rules /== [] then
					['Starting ruleset'%prb_ruleset(front(prb_rules))%] ==>
				endif;
				;;; save ruleset, for checking if it has changed later
				prb_rules -> oldrules;
			endif;

			IFTRACING
			if prb_chatty and prb_divides_chatty(DATABASE) then
				'DATABASE before calling prb_do_rules' =>
				prb_print_database()
			endif;

			;;; Now find runnable rules and run the (selected) instances
			false -> prb_rule_found;

			if prb_get_input then
				if sys_input_waiting(popdevin) then
					pr(newline);
					prb_add(readline())
				endif
			endif;

			prb_do_rules(prb_rules);

			lvars len2 = stacklength();

			unless len1 == len2 then
			mishap('Stack changed in prb_do_rules', [len1 ^len1 len2 ^len2])
			endunless;

			IFTRACING
			if prb_chatty then
				if not(prb_repeating) and prb_divides_chatty(INSTANCES) then
					[RULES_DONE ^(applist(prb_remember, prb_ruleof))] ==>
				endif
			endif;

			quitif(limit and cycle >= limit);
			cycle fi_+ 1 -> cycle;

		endrepeat;
	endprocedure();

	lvars len3 = stacklength();

	unless len1 == len3 then
		if len3 > len1 then
			conslist(len3 - len1) <> ['LEFT ON STACK'] ==>
		endif;
		mishap('Stack length changed in prb_run', [old ^len1 new ^len3])
	endunless;

	if prb_remember then prb_forget_rules() endif;

	if isident(prb_rules) then idval(prb_rules) -> prb_rules endif;

	unless prb_rule_found then
		prb_no_rule_found_action(prb_rules, prb_database, cycle)
	endunless;

	;;; perform user-definable cleanup action
	chain(prb_rules, prb_database, prb_finish);
enddefine;


define vars prb_run(rules, database, /*limit*/);
	;;; Optional third argument specifies the number of times to
	;;; cycle. If missing or false, go on until there are no more
	;;; runnable rules
	lvars limit;

	;;; Make sure proper arguments have been extracted
	if isinteger(database) or not(database) then
		;;; there were three items on stack
		rules, database -> (rules, database, limit);
	else
		;;; Default is go on cycling till a STOP action occurs.
		false -> limit;
	endif;

	dlocal popmatchvars = [];

	prb_run_with_matchvars(rules, database, limit);
enddefine;


global vars poprulebase = prb_version;	;;; for "uses"

global vars lprb = true; ;;; for uses
endsection;

nil -> proglist;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 22 2002
	Changed to work with IMPLIES conditions, by translating to NOT_EXISTS
	format. No longer uses prb_implies
--- Aaron Sloman, Jul  4 2002
	fixed a bug in prb_no_variables. If popmatchvars was empty it could
	produce the wrong result. Removed the optimisation that tests for
	popmatchvars first.
--- Aaron Sloman, May 19 2002
	Put in test to complain if WHERE/POP11 conditions and actions have
	spurious ")" at end, or if expressions in LVARS and VARS declarations
	have spurious closing brackets. Bug reported by Nick Hawes, 14 May 2002.
	Required change to procedure read_in_items(), used in conditions, actions,
	DLOCAL expressions, etc.

--- Aaron Sloman, Feb 20 2002
	Added facilities for tracing switch of ruleset in a rulefamily, as
	suggested by Nick Hawes
		Introduced
			prb_trace_ruleschanged:  boolean
			prb_family_name: possibly given name of rulefamily
			prb_ruleschanged_trace: procedure to run if tracing ruleset changes

--- Aaron Sloman, Sep 16 2000
	Fixed bug due to use of [INDATA...] with prb_allrules set true
		Reported by Catriona Kennedy
--- Aaron Sloman, Aug 13 2000
	A few optimisations, especially following IFTRACING

	changed prb_instance(Pattern) and code for FILTER conditions,
		to use "!" pattern prefix instead of WID macro

	Introduced new tracing procedures, all controlled by new
	global variable prb_self_trace

     prb_checking_conditions_trace(agent, ruleset, rule);
     prb_checking_one_condition_trace(agent, condition, rule);
     prb_all_conditions_satisfied_trace(agent, ruleset, rule, matchedvars);
     prb_condition_satisfied_trace(agent, condition, item, rule, matchedvars);
     prb_doing_actions_trace(agent, ruleset, rule_instance);
     prb_do_action_trace(agent, action, rule_instance);
     prb_adding_trace(agent, item);
     prb_deleting_trace(agent, item);
     prb_deleting_pattern_trace(agent, deleted, pattern);
     prb_modify_trace(agent, item, action, rule_instance);
     prb_pattern_matched_trace(agent, pattern, item);
     prb_condition_failed_trace(agent, condition, rule);

--- Aaron Sloman, Aug 12 2000
	prb_newdatabase(hashlen, userlist) -> newdb;
		can take optional extra argument, a word, which will be the name
		of the database.
	The name is now used in prb_print_database
	Fixed nasty design for [INDATA ...] conditions that did not work!!
	Thanks to Steve Allen

--- Aaron Sloman, Aug  8 2000

	uses readpattern;	;;; provides word_of_ident property and other things, e.g. "!"

	changed prb_*ruletype to prb_ruleset, keeping the former as a synonym for
	the latter

	made prb_print_table sort the keys before printing, unless keys provided
	by user.

	changed %P to %p in printf commands, so that user versions of
	print_instance are used, etc.

	Removed sim_*debugging. HELP sim_agent_news will explain

--- Aaron Sloman, Aug  5 2000
	Introduced sim_*debugging to control whether rulesets are represented by
	their names or by themselves.
	Renamed prb_rule*type as prb_ruleset, but left the former as a synonym
	for the latter.
	Introduced tracing procedures required by Catriona Kennedy.
	Still to be modified.
--- Aaron Sloman, Aug  1 2000
	Fixed bug that can occur when prb_allrules = 1 and prb_sortrules is false.
	Put extra check in prb_ODIFY
--- Aaron Sloman, Jul 31 2000
	Slightly optimised support for INDATA. If the same database is used twice
	in a row, no need to switch databases.
--- Aaron Sloman, Jul 29 2000
	Added support for conditions and actions of the form
		[INDATA ?db [...]]
	where db must be a database, and [...] must be one of the standard
	types of conditions or actions.

--- Aaron Sloman, Oct 16 1999
	Increased prb_max_keys to 64.

--- Aaron Sloman, Jul  9 1999
	As suggested by Catriona Kennedy changed
		if prb_sortrules then
	to
		if prb_sortrules then
			if isprocedure(prb_sortrules) then....
			else mishap
--- Aaron Sloman, Jul  4 1999
	Added prb_noprint_keys
--- Aaron Sloman, Jul  4 1999
--- Aaron Sloman, Sep 27 1998
	Allowed empty [DLOCAL] lists in rules, to simplify commenting out
	trace control commands, etc.
--- Aaron Sloman, Nov 12 1997
	Changed prb_valof to accept idents.
--- Aaron Sloman, Nov 12 1997
	Added ADDIF and ADDUNLESS
	Made prb_do_DEL, prb_assoc available to users.
	Added LIB * prb_RMODIFY
--- Aaron Sloman, Mar 18 1997
	Fixed bug reported by Jeremy Baxter. [IMPLIES ]conditions could not
	have embeded POP11 or WHERE conditions
-- VERSION 4 (V4.5)
--- Aaron Sloman, Dec 13 1996
	Reduced occurrences of sys_grbg_list. Uninitialised lvars on
	Alphas can cause problems
-- VERSION 4 (V4.1)

--- Aaron Sloman, Jun 11 1996
	Changed compile_mode back to +strict, and made some corrections to
	dclarations
--- Aaron Sloman, Jun  6 1996
	Prevented resetting of pattern vars that were introduced via [VARS ..]
	or [LVARS ...]
--- Aaron Sloman  26 May 1996
	Added prb_ruleset_name, and adjusted LIB RULEFAMILY to use it.
	Added print level restrictions when showing conditions, etc.
--- Aaron Sloman, May 22 1996
Allowed prb_read_VARS to have "DLOCAL" as third argument.

First argument removed from
	prb_no_rule_found_trace(rules, data)
  and
	prb_no_rule_found_action(rules, data, cycle)
	added prb_actions_run
	removed messing around with cycle limit in prb_run_with_matchvars
--- Aaron Sloman, May 17 1996
	Improved stack checking and error messages

Aaron Sloman  11 May 1996
moved test for prb_input_waiting. Previous changes had stopped it working
	if prb_sortrules was false
fixed bug in prb_MODIFY with prb_copy_modify false
removed prb_*failed completely.

added prb_instance_present(list) /* -> boolean */;
added TESTADD action, ADD action and prb_auto_add

Added STOPIF QUITIF QUIT
Changed check for prb_rules to be a list, so that it is also done
after rulesystem change in a rulefamily.

Aaron Sloman  9 May 1996
Compiled FILTER conditions and MAP and SELECT actions properly

made isindata ignore popmatchvars, because pattern is already fully
	instantiated.
made prb_recency work at compile time.

separated out sys_print_id and print_id

Added [DO ...] conditions

Made it unnecessary for POP11 conditions to return true. This is now handled
by the interpreter procedure. Simplifies metarules.

added IFSECTIONS

moved out define_form for :rule, to an autoloadable file

Major change: pattern variables default to lvars.

warning: lvars cannot be accessed in popval expressions

extra field prb_rulevars

[VARS...] and [LVARS ...] distinguished

variables cleared between rule activations.

Improved tracing for PUSH and POP actions where the stack does not exist
add IFTRACING
changed prb_do_DEL to use flush1 (DEL and REPLACE actions)
	NOW prb_debugging = true;
replaced rule*system with rulefamily. Rulesystem is now a set of rulefamilies
added prb_read_actions, prb_read_conditions

added pdprops to WHERE and POP11 condition procedures and VARS initialisation

allowed ruleset to specify sections
added define_ruleset, define_rulefamily, define_rulesystem

-- VERSION 3 (V3.4)

added prb_run_with_matchvars

--- Aaron Sloman,  5 Apr 1996
	At request of Jeremy Baxter set up support for rule*systems and
	rulesets to have associated matchvars

	Separated code for rule*systems into LIB * RULESYSTEMS
--- Aaron Sloman, Mar 30 1996
	Introduced prb_no_rule_found_action
	Fixed in case prb_rules at the end is an identifier, e.g. result of
	[RESTORERULESET ... ] action. The idval is used instead.
	Allowed rulesets to start with an integer, to determine number
	of cycles in prb_run
	Added prb_forget_rules
--- Aaron Sloman, Mar 24 1996
	Added prb_show_ruleset: if true will show which ruleset is being used.
	Introduced library for creating rule*systems See HELP ?????
	Modified prb_run to allow prb_rules to be a word or identifier
		so that valof or idval can be used to get the ruleset.
		This allows rulesets to be edited without recreating agents.

	Made prb_check_section user definable, so that it can be redefined
	as erase if sections are not used.
--- Aaron Sloman,  19 Mar 1996 (V3.2)
	As suggested by Jeremy Baxter optimised NOT actions of the form
	 	[NOT <item> ==]
	By changes to prb_flush and prb_subflush_fixed. This sort of
		deletion is now handled by [] -> prb_database(<item>)

--- Aaron Sloman, Feb 18 1996
	Optimised NOT conditions, using abnormal exit, and instantiated pattern
	Replaced wrong call of old_sysmatch

--- Aaron Sloman, Feb 15 1996 (V3.1)
	added trace_match, trace_match_prop, show_trace_match, clear_trace_match
	optimised NOT condition
--- Aaron Sloman, Feb 1 1996 (V3)
	Added prb_no_rule_found_trace(prb_rules, prb_database)
	Removed spurious assignment for "FIL*TER" action.
	Removed global $-prb$-prb_pos*sibles. It was previously needed only for
		FA*IL actions and backtracking
	Moved the following action types to property 29 Jan 1996:
		MODIFY DEL REPLACE PUSH POP STOP ADDALL RULE SAVE RESTORE POP11 SAY
		SAYIF NOT
-- VERSION 2
--- Aaron Sloman 21 July 1995
	Removed prb_statestack, disabling fail actions
	Fixed bug in [VARS ....] expressions. Did not read properly if
	there was more than one initialisation.

	Changed use of prb_use_sections so that current_section is
	dlocalised only once. This means that current_section does not
	need to be changed so frequently, and that makes a huge difference
	to speed. It is still slow to use lots of different sections.

--- Aaron Sloman and Darryl Davis, Jul 20 1995
	Fixed some problems in the instantiation of variables with restriction
	procedures.

	finally removed all reference to prb_backtrack
--- Aaron Sloman, Jul 17 1995
	Allowed [VAL var] in actions to evaluate to the value of var as a
		global variable.
	Also allowed it in simple patterns.

	Allowed VARS conditions and VARS actions to have initialised
	variables, including multiple assignments.

	Changed prb_add_rule_vars to prb_add_action_vars, and moved it from
	the autoloadable library to this file.

	Allowed prb_position_stack and prb_rule_stack to be in the
	property table prb_database. Introduced $-prb$-private_keys to ensure
	that the keys used for these stacks are not confused with normal
	database keys.

--- Aaron Sloman, Jul 14 1995
	Added showing_conditions and other global lvars to help with
	tracing.
	Allowed prb_show_conditions to be a list of names of rules.
--- Aaron Sloman, Jul  8 1995
	added prb_add_list_to_db (autoloadable)
	added prb_add_to_db

--- Darryl Davis and Aaron Sloman 1 July 1995
	made prb_recording available
	prb_print_table
	prb_print_database
	Amended prb_run to accept new arguments.
	prb_is_var_key(key);
	prb_list_data (in auto directory)
	prb_valof changed to dereference only once. Could add prb_recursive_valof
	prb_match_apply_keys(dbtable, pattern, keys, proc);
	prb_match_apply(dbtable, pattern, proc);

--- Darryl Davis and Aaron Sloman 1 July 1995
	Had to change the use of the vector patternlocations, and notions
	of recency etc.

	Fixed bug in tracing prb_show_conditions in isindata

	Changed the nature of prb_database from a list to a property table
		i.e. [belief ...] now in prb_database("belief") etc
    Requires changes to number of procedures and nature of default set
		up sequence
	Number of procedures added (eg prb_print_database)

	Changed the way define :default works, to allow expressions.

	Removed prb_memlim and all code using it (prb_truncate?)

--- Aaron Sloman, Jun 16 1995
	Extended OR conditions to allow complex sub-conditions.

	Changed reader to cope with compilation of POP11 or WHERE in
	"OR" conditions.

	Improved error handling when rule name is omitted.

	Made VARS variable declarations and [->> var] check whether
	the variable is already in popmatchvars and if so give an error.

--- Aaron Sloman June 15th 1955
	Added CUT Condition.

	Prepared code for including sections, if prb_use_sections is true.

	Made more procedure names global

--- Aaron Sloman June 12th 1955
	Added new action type and condition type
		[VARS ....]
	(previously announced as [RULE_VARS]
	to allow additional variables to be accessible using "?" and "??
	in conditions and actions. Used procedures
	prb_add_condition_vars
	prb_a*dd_rule_vars

--- Aaron Sloman June 9th 1955
	Changed to do compilation of WHERE conditions at compile time, not
	run time. This means that WHERE conditions cannot use "?" or "??"
	variables.

	Included changing prb_check_pop_code(pattern) -> boole;

--- Aaron Sloman May 20 1955
	Added new condition type [->> variable] based on suggestions from
	Riccardo Poli and Darryl Davis.
	Allowed [DEL ?variable] for such variables.

	Also reorganised file, and introduced ENTER g index.

	Removed some redundant local lvars, and introduced some new
	lblocks.

	re-named prb_check_condition as prb_check_pop_code

-- VERSION 1
--- Aaron Sloman March 12 1995
	Added tests for type of weight, conditions, actions, in prb_new_rule.
--- Aaron Sloman and Riccardo Poli, Mar 2 1995
    Changed the handling of popautolist so that (a) the version
    "remembered" is not the one that existed at compile time but at
    the time that prb_run starts up, and (b) it is restored inside
    prb_do_action, as well as inside prb_valof and prb_check_pop_code.
	This restores autoloading fully when actions are evaluated and in
	WHERE conditions.
--- Aaron Sloman, Jan 11 1995
	Replaced "compile" with "pop11_compile" throughout. (The former
	is obsolete.)
	Made WHERE conditions use read_list_of_items() instead if listread()
		so that use of embedded "^", etc. in lists will work.
--- Aaron Sloman, Nov 11 1994
	Applied prb_instance to lists after SAY, SAYIF, EXPLAIN
--- Aaron Sloman, Nov  8 1994
	switched back prb_eval and prb_eval_list to take only one arg,
	and use rule_instance non-locally.
--- Aaron Sloman Nov 7th 1994
		Corrected documentation on FILTER conditions, in HELP PRB_FILTER
		and added more checking for stack errors in a few places.
--- Aaron Sloman Oct 31 1994
		added extra argument to prb_eval, prb_eval_list (undone later)
--- Aaron Sloman Oct 30 1994
		Added DOALL action types
		Changed prb_do_action to allow empty actions to be null actions.
--- Aaron Sloman Oct 29 1994
		Replaced TEST with FILTER and extended FILTER mechanism.
		Added Tim Read's extensions to newprb providing optional
		weights in rule definitions. New identifiers:
			TRACE_WEIGHTS = 19,
			prb_useweights = false
			prb_default_rule_weight = pop_min_int
			prb_weight(rule) -> integer
			psys_rule_weight(word, /*type*/) -> weight;
		(Birmingham only - This makes local LIB WEIGHTED NEWPSYS redundant.)
--- Aaron Sloman Oct 18 1994
		Added conditions of form [TE*ST pred patt1 patt2 ... pattn]
		and user-defined conditions, using prb_condition_type
--- Aaron Sloman Oct 14 1994
	Changed name to POPRULEBASE
	Globally changed all prb_ prefixes to prb_ prefixes
	gave prb_run an option extra argument: a limit
--- Aaron Sloman Oct 9 1994
	Added SAYIF and prb_sayif_trace
	Stopped it always printing NO MORE RULES

For earlier revision notes, see LIB * NEWPSYS

-- PROCEDURE INDEX. Access using "ENTER g define"

 define lconstant try_set_default(varval, newval, word);
 define :define_form lconstant defaults;
 define :defaults;
 define vars procedure prb_checking_conditions_trace(agent, ruleset, rule);
 define vars procedure prb_checking_one_condition_trace(agent, condition, rule);
 define vars procedure prb_all_conditions_satisfied_trace(agent, ruleset, rule, matchedvars);
 define vars procedure prb_condition_satisfied_trace(agent, condition, item, rule, matchedvars);
 define vars procedure prb_doing_actions_trace(agent, ruleset, rule_instance);
 define vars procedure prb_do_action_trace(agent, action, rule_instance);
 define vars procedure prb_adding_trace(agent, item);
 define vars procedure prb_deleting_trace(agent, item);
 define vars procedure prb_deleting_pattern_trace(agent, deleted, pattern);
 define vars procedure prb_modify_trace(agent, item, action, rule_instance);
 define vars procedure prb_pattern_matched_trace(agent, pattern, item);
 define vars procedure prb_condition_failed_trace(agent, condition, rule);
 define global vars procedure prb_divides_chatty(int) /* -> boolean */;
 define global constant procedure prb_member(item, list)
 define prb_assoc(item, assoc_list);
 define global vars word_of_ident = newproperty([],64, false, "tmparg")
 define vars print_ident(id);
 define vars sys_print_ident(id);
 define lconstant procedure prb_has_variables(list) -> boole;
 define lconstant procedure prb_no_variables(list) -> boole;
 define prb_variables_in(list, varlist, VARlist) -> (varlist, VARlist);
 define prb_extend_popmatchvars(list, matchvars) -> matchvars;
 define global constant procedure trace_match(Patt, Datum) -> result;
 define global vars show_trace_match(rules);
 define clear_trace_match();
 define prb_forget_rules();
 define global vars procedure prb_newdatabase(hashlen, userlist) -> procedure newdb;
 define prb_empty(dbtable) /* -> boolean */;
 define global constant procedure prb_database_keys(dbtable) /* -> keys */;
 define global vars procedure prb_print_table(dbtable, /*keys*/);
 define global vars procedure prb_print_database();
 define prb_add_db_to_db(db1, db2, /*copying*/);
 define global constant procedure prb_is_var_key(key);
 define lconstant procedure prb_instantiate_first(patt) -> patt;
 define global vars procedure prb_match_apply_keys(dbtable, pattern, keys, proc);
 define global vars procedure prb_match_apply(dbtable, pattern, proc);
 define vars procedure prb_add(item);
 define procedure prb_add_to_db(item, dbtable);
 define vars procedure prb_present(pattern) /* -> item */;
 define procedure prb_present_keys(pattern, keys) -> item;
 define global procedure prb_in_data(pattern, data) -> item;
 define global procedure prb_del1(pattern, data) -> (item, data);
 define vars procedure prb_flush1(pattern);
 define lconstant procedure prb_subflush_fixed(pattern, hashkey);
 define lconstant procedure prb_subflush_var(pattern);
 define vars procedure prb_flush(pattern);
 define global constant procedure prb_valof(word) -> word;
 define lconstant procedure prb_dl(list);
 define procedure prb_rule_section =
 define prb_print_rule(rule);
 define vars procedure prb_check_section(rule);
 define vars procedure isprb_rulefamily(x);
 define lconstant prb_activation_name(/*instance*/);
 define vars $-prb_instance(Pattern) -> value;
 define vars $-prb_value(Pattern) -> Pattern;
 define global vars procedure prb_condition_type =
 define lconstant add_and_set_popmatchvars(list);
 define lconstant prb_add_condition_vars(list);
 define lconstant prb_add_action_vars(rule_instance, action);
 define lconstant prb_check_pop_code(pattern, result_expected) -> boole;
 define lconstant procedure prb_check_stack(num);
 define lconstant prb_assign_->> (pattern);
 define lconstant prb_do_cut();
 define vars prb_forevery(patternlist, proc);
 define global procedure read_in_items();
 define global procedure read_list_of_items() -> result;
 define constant procedure prb_declare(word);
 define constant procedure prb_ldeclare(word);
 define lconstant newLVAR(item, declare);
 define vars prb_declare_lvar(item);
 define constant Read_Pattern(vars_spec) -> item;
 define lconstant prb_compile_procedure(codelist, name, closer, endtrue);
 define prb_read_VARS(usevector, name, lexical) -> varspec;
 define $-prb$-readVARS(name, lexical) -> varlist;
 define vars procedure prb_readcondition(vars_spec) -> condition;
 define lconstant prb_fix_embedded_forms(action)->action;
 define vars procedure prb_readaction(vars_spec) -> action;
 define prb_read_conditions(vars_spec) -> (list, item);
 define prb_read_actions(vars_spec, terminators) -> (list, item);
 define prb_rule_named(word /*, list*/) -> rule;
 define prb_extract_vars(conditions, actions) -> rulevars ;
 define init_prb_rule(name, weight, conditions, actions, type, rulevars, create);
 define vars prb_new_rule = init_prb_rule(%false%)
 define global vars procedure prb_istraced =
 define lconstant print_if_non_empty(list);
 define lconstant procedure not_rule_done(rule, found) -> boole;
 define lconstant restore_dlocal(dlocal_vars, dlocal_vals, grbg);
 define vars procedure prb_applicable(rules) -> possibles;
 define global vars procedure prb_action_type =
 define prb_do_DEL(item, foundlist);
 define prb_DEL(rule_instance, action);
 define lconstant procedure prb_MODIFY(rule_instance, action);
 define lconstant prb_REPLACE(rule_instance, action);
 define lconstant prb_STOP(rule_instance, action);
 define lconstant prb_STOPIF(rule_instance, action);
 define lconstant prb_QUIT(rule_instance, action);
 define lconstant prb_QUITIF(rule_instance, action);
 define lconstant prb_ADDALL(rule_instance, action);
 define lconstant prb_do_POP11(rule_instance, action);
 define lconstant prb_SAY(rule_instance, action);
 define lconstant prb_SAYIF(rule_instance, action);
 define lconstant prb_EXPLAIN(rule_instance, action);
 define lconstant prb_ADD(rule_instance, action);
 define prb_instance_present(list) /* -> boolean */;
 define lconstant prb_TEST_ADD(rule_instance, action);
 define prb_ADDIF(rule_instance, action);
 define prb_ADDUNLESS(rule_instance, action);
 define lconstant prb_XXX(rule_instance, action);
 define vars procedure prb_do_action(action, current_rule, rule_instance);
 define vars prb_do_action_now(list);
 define prb_do_in_data(rule_instance, action);
 define prb_eval(action);
 define prb_eval_list(actions);
 define lconstant procedure prb_do_actions(rule_instance);
 define lconstant prb_do_rule_actions(rule_instance, counter);
 define lconstant setup_matchvars(vec);
 define procedure prb_do_rules(rules);
 define vars procedure prb_finish(rules, data);
 define global vars procedure prb_no_rule_found_trace(rules, data);
 define global vars procedure prb_no_rule_found_action(rules, data, cycle);
 define global vars prb_ruleschanged_trace(ruleset, family);
 define global vars procedure prb_no_rule_found_action(rules, data, cycle);
 define vars prb_run_with_matchvars(rules, database, limit);
 define vars prb_run(rules, database, /*limit*/);

 */
