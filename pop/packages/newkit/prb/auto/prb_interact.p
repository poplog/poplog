/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_interact.p
 > Purpose:			interactive procedures for POPRULEBASE actions
 > Author:          Aaron Sloman, Oct 30 1994 (see revisions)
 > Documentation:	HELP * POPRULEBASE
 > Related Files:
 */

section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
include WID.ph

uses prb_trace;
uses prb_untrace;

global vars procedure prb_interact; ;;; defined below

global vars prb_walk_fast;
if isundef(prb_walk_fast) then false -> prb_walk_fast endif;

;;; Uses macro WID defined in poprulebase

define lconstant prb_displayrule(action, rule_instance);
	;;; The action has already been instantiated
	lvars action, rule_instance;
	[^action 'is an action of the rule'] ==>
	prb_trace_rule(rule_instance, false);
	pr(newline);
enddefine;

define lconstant prb_expound();
	;;; "why" has just been typed
	lvars rule_instance;
	if ispair(prb_remember) then
		'Previous rule was' =>
		destpair(prb_remember) -> prb_remember-> rule_instance;
		prb_trace_rule(rule_instance, true)
	else
		'No more reasons, sorry' =>
	endif
enddefine;


section $-prb prb_trace prb_untrace => prb_interact;

vars key, rest;	;;; needed for matches, in next procedure

define prb_interact(message, action, rule_instance, accept_empty) -> answer;
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
	returnif(prb_walk_fast)([] -> answer);
		readline() -> answer;
	returnif(accept_empty and answer == []);
		if answer matches #_< [: ?? ^WID rest] >_# then
			;;; it's a Pop-11 command
			[%compile(rest)%] -> answer;
			unless answer == [] then
				compile([^^answer =>])
			endunless
		elseif answer matches #_< [. ? ^WID key ?? ^WID rest] >_# then
			if key == "show" then
				prb_displayrule(action, rule_instance)
			elseif key == "why" then
				if first then
					false -> first;
					if isvector(last(action)) then
						;;; It's a "canned" explnation
						appdata(last(action),
							procedure(item); lvars item;
								if isword(item) then spr(valof(item))
								elseif islist(item) then spr(prb_value(item))
								else spr(item)
								endif
							endprocedure);
						pr(newline)
					else
						prb_displayrule(action, rule_instance)
					endif
				else
					;;; display previous rules
					prb_expound();	;;; alters prb_remember non-locally
				endif
			elseif key == "data" and rest == [] then
				prb_print_database();
			elseif key == "data" then
				'DATA ITEMS' =>
				prb_foreach(rest, procedure; prb_found ==> endprocedure)
			elseif key == "stop" then
				'Stopping' =>
				exitto(prb_run_with_matchvars)
			elseif key == "trace" then
				prb_trace(rest)
			elseif key == "untrace" and rest = #_< [all] >_# then
				prb_untrace("all");
				false -> prb_walk;
			elseif key = "untrace" then
				prb_untrace(rest)
			elseif key == "show_conditions" and rest == [] then
				true -> prb_show_conditions
			elseif key == "show_conditions" then
				compile(rest) -> prb_show_conditions
			elseif key == "chatty" and rest == [] then
				true -> prb_chatty
			elseif key == "chatty" then
				compile(rest) -> prb_chatty
			elseif key == "walk" and rest == [] then
				true -> prb_walk
			elseif key == "walk" then
				compile(rest) -> prb_walk
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
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec 12 1996
	Added prb_walk_fast
--- Aaron Sloman, Apr 10 1996
     changed prb_run to prb_run_with matchvars
--- Aaron Sloman, Jul  1 1995
	Altered for new database format
 */
