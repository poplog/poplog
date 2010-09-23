/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_make_rule.p
 > Purpose:			For actions of type [RULE...]
 > Author:          Aaron Sloman, Oct 30 1994 (see revisions)
 > Documentation:	HELP * POPRULEBASE
 > Related Files:	LIB * POPRULEBASE
 */

section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;
include WID.ph
section $-prb;

vars name, weight, conds, acts, ruletype; ;;; needed for patterns, in next procedure


define $-prb_make_rule(rule_instance, action);
	;;; Needed for actions of type RULE. Unlike normal rule definitions,
	;;; this kind of rule puts new actions at the begining of prb_rules.
	lvars list = fast_back(action), rule;
	dlocal name, weight = false, conds, acts, ruletype;
	if list matches #_< [TYPE ? ^WID ruletype:isword ==] >_# then
		fast_back(fast_back(list)) -> list
	else
		"prb_rules" -> ruletype
	endif;

	if list matches #_< [? ^WID name:isword ? ^WID weight:isnumber
							? ^WID conds:islist ? ^WID acts:islist] >_#
	or
		list matches #_< [? ^WID name:isword
							? ^WID conds:islist ? ^WID acts:islist] >_#
	then
		unless weight then pop_min_int -> weight endunless;

		lvars rulevars;
		prb_extract_vars(conds, acts) -> rulevars;

		prb_rule_named(name) -> rule;
		if rule then
			prb_new_rule(name, weight, conds, acts, ruletype)
		else
			valof(ruletype) nc_<>
			[%consprbrule(name, weight, conds, acts, ruletype, rulevars)%] -> valof(ruletype)
		endif
	else
		mishap(list, 1, 'INCORRECT FORMAT FOR "RULE"')
	endif
enddefine;

endsection;
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Apr 26 1996
	changed to include rulevars
--- Aaron Sloman, Jan 29 1996
	Changed to be invoked via table of actions
--- Aaron Sloman, May 21 1995
	Extended to allow weight to be present or absent in the new rule.
	Also fixed stack bug.
 */
