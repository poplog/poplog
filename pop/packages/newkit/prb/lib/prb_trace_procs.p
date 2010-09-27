/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/lib/prb_trace_procs.p
 > Purpose:         Interrogating trace_match_prop
 > Author:          Aaron Sloman, Feb 16 1996
 > Documentation:	HELP PRB_TRACE_PROCS
 > Related Files:
 */


section;

;;; Load this library before loading poprulebase
global vars do_trace_match = true;

;;; This is a property, defined in poprulebase.
global vars procedure trace_match_prop;

;;; Defined in poprulebase
global vars procedure show_trace_match;

define prb_trace_rule_stats(ruleinfo, name) -> stats;
	;;; ruleinfo is the result of trace_match_prop(name)
	lvars objects = 0, patts = [], tries = 0, succeeded = 0;
	vars objname, patterns, rest;	 ;;; pattern vars

	if ruleinfo then
		while ruleinfo matches [ ?objname ?patterns ??rest] do
			rest -> ruleinfo;
			objects + 1 -> objects;
			lvars vec;
			for vec in patterns do
				vec(2) + tries -> tries;
				vec(3) + succeeded -> succeeded;
				lvars patt = vec(1);
				unless member(patt, patts) then
					conspair(patt, patts) -> patts
				endunless;
			endfor;
		endwhile;
	endif;
	[^name tries ^tries hits ^succeeded patterns ^(length(patts))
			objects ^objects] -> stats;
enddefine;

define prb_rules_traced() -> names;
	;;; return a list of names of rules in trace_match_prop
	[%
		appproperty(trace_match_prop,
			procedure(key,val); key endprocedure)
	%] -> names
enddefine;

define prb_sort_traces(names, num) -> sorted;
	;;; Given a list of names of rules,
	;;; produce a list of stats sorted in decreasing order of number
	;;; of tries. If names is false, get all the names.
	;;; If num is an integer, show only the first num items
	;;; after sorting.

	unless names then prb_rules_traced() -> names endunless;
	lvars name, count = 0;
	[%	for name in names do
			count fi_+ 1 -> count;
			prb_trace_rule_stats(trace_match_prop(name), name)
		endfor
	%] -> sorted;

	;;; now sort according to number of tries (3rd element in each list)
	nc_listsort(sorted, procedure(l1, l2); l1(3) > l2(3) endprocedure)
		-> sorted;
	if num and num < count then
		;;; only include first num
		allbutlast(count - num, sorted) ->  sorted
	endif;
enddefine;

define prb_show_full_trace(num);
	;;; show full information about the first num rules sorted
	;;; by number of matches tried
	lvars name, item;
		for item in prb_sort_traces(false, num) do
			item =>
			show_trace_match(hd(item));
			nl(1)
		endfor;
enddefine;

define prb_object_matches(objname) -> list;
	;;; Given an object name, extract information about rules run
	;;; within that object. Sort the rules in decreasing order
	;;; of numbers of matches. Also work out total matches tried
	;;; for that object, and total succeeded

	lvars rulename, rulenames = prb_rules_traced(),
		total_tries = 0, total_hits = 0;

	vars obj_info;

	[%
		for rulename in rulenames do
		lvars rule_info = trace_match_prop(rulename);

		if rule_info matches [ == ^objname ?obj_info ==] then
			;;; obj_info is a list of vectors
			;;; could add up total number of matches tried?
			lvars tries = 0, hits = 0, vec;
			for vec in obj_info do
				tries + vec(2) -> tries;
				hits + vec(3) -> hits;
			endfor;
			tries + total_tries -> total_tries;
			hits + total_hits -> total_hits;
			[^rulename tries ^tries hits ^hits ^^obj_info]
		endif

	endfor %] -> list;

	nc_listsort(list, procedure(l1, l2); l1(3) > l2(3) endprocedure) -> list;

	[^objname totaltries ^total_tries totalhits ^total_hits ^list] -> list;

enddefine;


;;; for uses
global vars prb_trace_procs = true;

endsection;
