/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_push_or_pop.p
 > Purpose:			Procedure to perform actions required
					of PUSH and POP keywords in rule ACTIONS
					ie add or take off top element of the back of
					a list assocaited with a named head of a list
 > Author:          Aaron Sloman, Oct 30 1994 (see revisions)
   Changed to cope with property table version of prb_database
					Darryl Davis, June 27, 1995.
 > Documentation:	HELP * POPRULEBASE
 > Related Files:	LIB * POPRULEBASE
 */

section;

;;; compile_mode:pop11 +strict;

;;; compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
include WID.ph

uses poprulebase;

section $-prb;

vars rest; ;;; needed in next procedure, for matcher

;;; changed

define $-prb_push_or_pop(rule_instance, action);
	lvars list = fast_back(action),
		item,
		stackname,
		pushing = (fast_front(action) == "PUSH"),
		stack, dblist,
		len = listlength(list);

	lconstant pattern = [0 ?? ^WID rest];

	dlocal rest, popmatchvars = [];

	if pushing then
		unless len == 2 then
			mishap(list,1,'WRONG ARGUMENTS FOR PUSH')
		endunless;
		dl(list) -> (item, stackname);
	elseunless len == 1 then
		mishap(list,1,'WRONG ARGUMENTS FOR POP')
	else
		front(list) -> stackname
	endif;

	stackname -> fast_front(pattern);

	prb_present(pattern) -> stack;

	unless islist(stack) then
		mishap(
			if pushing then 'PUSHING TO NON-EXISTENT STACK '
			else 'POPPING FROM NON-EXISTENT STACK '
			endif >< stackname,
			[%list, prb_rulename(prb_ruleof(rule_instance))%])
	endunless;

	prb_database(stackname) -> dblist;

	setfrontlist(stack, dblist) -> dblist;
	if prb_copy_modify then
		;;; get rid of previous one.
		fast_back(dblist) -> prb_database(stackname);
		if pushing then
			prb_add([^stackname ^item ^^rest])
		else
			if rest == [] then mishap(stackname, 1, 'NOTHING TO POP')
			else prb_add([^stackname ^^(back(rest))])
			endif
		endif
	else
		;;; Overwriting instead of copying
		;;; save list in the database
		dblist -> prb_database(stackname);
		;;; destructive modification. Item already at front of list
		if pushing then
			conspair(item, back(stack)) -> fast_back(stack)
		else
			back(fast_back(stack)) -> fast_back(stack)
		endif
	endif
enddefine;

endsection;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 29 1996
	Changed to be take new arguments so that it can be directly mapped
	onto action type
--- Aaron Sloman and Darryl Davis 2 July 1995
	Changed to cope with property table definition of prb_database
	(Revised by AS on 2nd July)
 */
