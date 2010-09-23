/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/prb/lib/prb_extra.p
 > Purpose:			Extensions to LIB POPRULEBASE, described below
 > Author:          Aaron Sloman, Sep 11 1994 (see revisions)
 > Documentation:	HELP * PRB_EXTRA
 > Related Files:	LIB * POPRULEBASE, HELP * POPRULEBASE
 */

/*
This library was changed 15th July to allow stacks for databases and
for rulesets to be stored in prb_database. This allows multiple stacks,
e.g. for different objects.
*/

uses prblib;
uses poprulebase;

section;

;;; These stacks should not be directly accessed by user code,
;;; so that sys_grbg_destpair can safely be used when popping.

define prb_clearstacks();
	;;; needed in case process is aborted
	[] ->> prb_database($-prb$-datastackkey)
		-> prb_database($-prb$-rulestackkey);
enddefine;

define prb_current_data_stack() /* -> list */;
	;;; To enable agent to get a copy of the current data stack
	;;; Probably should be recursively copied
	prb_database($-prb$-datastackkey)
enddefine;

define updaterof prb_current_data_stack(/*list*/);
	;;; To enable agent to update the current data stack
	;;; should this ever be allowed?
	copylist(/*list*/) -> prb_database($-prb$-datastackkey)
enddefine;

define prb_current_rule_stack() /* -> list */;
	;;; to enable agent to access the current rule stack
	prb_database($-prb$-rulestackkey) /* -> list */
enddefine;

define updaterof prb_current_rule_stack(/*list*/);
	;;; to enable agent to restore a stack
	copylist(/*list*/) -> prb_database($-prb$-rulestackkey)
enddefine;



;;; Set up the association with procedure name and action type
;;; Using the name so that the procedure can be traced, or redefined.

"prb_do_PUSHRULES" -> prb_action_type("PUSHRULES");
"prb_do_POPRULES" -> prb_action_type("POPRULES");
"prb_do_PUSHDATA" -> prb_action_type("PUSHDATA");
"prb_do_POPDATA" -> prb_action_type("POPDATA");

;;; define the procedures
define prb_do_PUSHRULES(rule_instance, action);
	;;; Run an action to push current ruleset onto the rulestack and
	;;; start a new ruleset.
    ;;; ignore rule_instance in this case
    ;;; action will be [PUSHRULES <rulespec>]
    lvars rule_instance, action, rulespec;

	;;; get rid of keyword
    back(action) -> rulespec;
	if rulespec == [] then
		mishap('NO RULESET TO PUSH', [^rule_instance ^action])
	endif;

    prb_rules::prb_database($-prb$-rulestackkey)
		-> prb_database($-prb$-rulestackkey);

	;;; get the new ruleset to be made current

    if back(rulespec) == [] then
        ;;; it's a one-element list
        recursive_valof(front(rulespec))
    else
        compile(rulespec)
    endif -> prb_rules;

enddefine;

define prb_do_PUSHDATA(rule_instance, action);
	;;; Run an action to push the current database onto the
	;;; database stack and set up a new database.
    ;;; ignore rule_instance in this case
    ;;; The action will be [PUSHDATA <database>]
    ;;; or possibly   [PUSHDATA [<patternlist>] <database>]

    lvars rule_instance, action, dataspec, patternlist, data,
		transferdata = false;

	;;; remove keyword
	back(action) -> action;

	;;; If necessary remove transfer data
	if islist(front(action) ->> patternlist) then
		;;; assume it is a list of patterns
		prb_remove_all(patternlist) -> transferdata;
		fast_back(action) -> dataspec;
	else
		action -> dataspec
	endif;

	if dataspec == [] then
		mishap('NO DATABASE TO PUSH', [^rule_instance ^action])
	endif;

	;;; Push the current (copied) database
	;;; should all the lists be copied? Probably !!!
    copy(prb_database)::prb_database($-prb$-rulestackkey)
			-> prb_database($-prb$-rulestackkey);

	;;; get the new database to be made current
    if fast_back(dataspec) == [] then
        ;;; it's a one-element list
        recursive_valof(front(dataspec))
    else
		;;; there's code to be run to get the database.
        compile(dataspec)
    endif -> data;

	if isproperty(data) then
		data
	else
		prb_newdatabase(prb_max_keys, data) -> prb_database;
	endif -> prb_database;

	;;; Now add transferdata, if necessary
	if transferdata then
		applist(transferdata, prb_add);
		sys_grbg_list(transferdata)
	endif;
enddefine;

define prb_do_POPRULES(rule_instance, action);
    ;;; ignore rule_instance in this case
    ;;; action will be [POPRULES] or [POPRULES <ruleset>]
    lvars rule_instance, action, rulespec;
	if prb_database($-prb$-rulestackkey) == [] then
		mishap('Cannot do POPRULES, stack empty', [^rule_instance ^action])
	endif;

	;;; check for format [POPRULES <ruleset>]
	back(action) -> rulespec;
	if rulespec /== [] then ;;; Save current rules
		if back(rulespec) == [] then ;;; one element, assume it's a word
			prb_rules -> valof(fast_front(rulespec))
		else
			;;; something more efficient than this could be used,
			;;; to reduce garbage created by compile
			compile(prb_rules, [-> ^^rulespec])
		endif
	endif;

	sys_grbg_destpair(prb_database($-prb$-rulestackkey))
		-> (prb_rules, prb_database($-prb$-rulestackkey));

enddefine;

define prb_do_POPDATA(rule_instance, action);
    ;;; ignore rule_instance in this case
    ;;; action will be [POPDATA] or [POPDATA <database>]
    ;;; or [POPDATA [<patternlist>] ] or [POPDATA [<patternlist>} <database>]
    lvars rule_instance, action, patternlist, dataspec,
		transferdata = false;

	if prb_database($-prb$-datastackkey) == [] then
		mishap('Cannot do POPDATA, stack empty', [^rule_instance ^action])
	endif;

	;;; get rid of keyword
	back(action) -> action;

	;;; Check for <patternlist> -- if necessary remove transfer data
	if action /== [] and islist(front(action) ->> patternlist) then
		;;; assume it is a list of patterns
		if patternlist = [[==]] then
			;;; transfer everything to old database
			copylist(prb_database)
		else
			prb_remove_all(patternlist)
		endif -> transferdata;
		fast_back(action) -> action;
	endif;

	;;; check for format [POPDATA .... <ruleset>]
	if action /== [] then
		;;; Save current database
		back(action) -> dataspec;
		if back(action) == [] then ;;; one element, assume it's a word
			prb_database -> valof(fast_front(action))
		else
			;;; something more efficient could be used, to reduce garbage
			compile(prb_database, [-> ^^action])
		endif
	endif;

	sys_grbg_destpair(prb_database($-prb$-datastackkey))
			-> (prb_database, prb_database($-prb$-datastackkey));

	;;; Now add transferdata, if necessary
	if transferdata then
		applist(transferdata, prb_add);
		sys_grbg_list(transferdata);	;;; return temporary store
	endif;

enddefine;


global vars prb_extra = true; 	;;; to prevent "uses" reloading this.

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 29th 1995
		Fixed syntax errors in section pathnames
--- Aaron Sloman, July 18th 1995.
		Fixed to store stacks in the property table
--- Aaron Sloman, Nov 1 1994
	Moved prb_remove_all to a separate autoloadable file
--- Aaron Sloman, Oct 17 1994
	Changed to use poprulebase. Changed all identifiers to start
	prb_ instead of psys_
 */
