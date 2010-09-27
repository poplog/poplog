/* --- Copyright University of Birmingham 1998. All rights reserved. ------
 > File:            $poplocal/local/sim/lib/prb_DEL_THIS_RULESET.p
 > Purpose:			Define action for deleting current ruleset
 > Author:          Aaron Sloman, Feb 18 1998
 > Documentation:	
 > Related Files:
 */

/*
Action formats
     [DEL_THIS_RULESET]
     [DEL_THIS_RULESET <message>]

A rule action might be like this:

     [LVARS [myself = sim_myself]]
     [DEL_THIS_RULESET [Deleting a ruleset in ?myself]]

Note: if a ruleset using this action is put into a rulesystem, it is advisable
to set cycle limit to 1, e.g:

	define :rulesystem ...
		....
	 	include: startup_rules with_limit = 1
		....
	enddefine;

*/

section;

uses poprulebase
uses sim_agent

define prb_DEL_THIS_RULESET(rule_instance, action);

	;;; Get current rulesystem and remove current ruleset from it
	;;; current ruleset (or rulefamily) is held in the variable
	;;; prb_rules.

	unless back(action) == [] then
		;;; Some trace message follows the keyword. Print it out.
		prb_instance(fast_back(action)) ==>
	endunless;

	lvars rulesystem = sim_rulesystem(sim_myself);

	;;; Rebuild the rulesystem without the ruleset:
	;;; simpler and safer than a non-constructive rebuild.
	[%
		lvars item, r;
		for item in rulesystem do
			unless item == prb_rules
			;;; or ruleset name replaced by the list
			or (isword(item) and valof(item) == prb_rules)
			;;; or it's a pair with ruleset and cycle limit
			or (ispair(item) and
					((fast_front(item) ->> r) == prb_rules
						;;; this should not occur, but may later...
						or (isword(r) and valof(r) == prb_rules)))
			then
				item
			endunless;
		endfor;
	%] -> sim_rulesystem(sim_myself);
enddefine;

;;; Now make this a recognized action type
"prb_DEL_THIS_RULESET" -> prb_action_type("DEL_THIS_RULESET");

endsection;
