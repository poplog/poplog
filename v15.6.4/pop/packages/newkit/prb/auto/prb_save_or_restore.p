/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File: 			$poplocal/local/prb/auto/prb_save_or_restore.p
 > Purpose:			Deal with saving and restoring rulesets or database
 > Author:          Aaron Sloman, Oct 30 1994 (see revisions)
 > Documentation:	HELP * POPRULEBASE
 > Related Files:	LIB * POPRULEBASE
 */

section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
include WID.ph
uses poprulebase;

section $-prb;

vars Pname;		;;; needed for patterns in next procedure

define $-prb_save_or_restore(rule_instance, action);
	;;; For [SAVE ...] or [RESTORE ...] actions
	lvars type, list;
	fast_destpair(action) ->( type, list );

	dlocal Pname;

	lconstant Dpattern = [DATA ? ^WID Pname ==],
				Rpattern = [RULES ? ^WID Pname ==];

	until list == [] or back(list) == [] do
		if list matches Dpattern then
			if type == "SAVE" then
				;;; should this be a recursive copy?
				copy(prb_database) -> valof(Pname);
			else /* type == "RESTORE" */
				valof(Pname) -> prb_database
			endif
		elseif list matches Rpattern then
			if type == "SAVE" then
				prb_rules -> valof(Pname);
			else /* type == "RESTORE" */
				valof(Pname) -> prb_rules
			endif
		endif;
		fast_back(fast_back(list)) -> list
	enduntil
enddefine;

endsection;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 29 1996
	Changed to be directly associated with action_type
--- Aaron Sloman, Jul  2 1995
	Changed for new hashed database mechanism. May need a deeper copy
	for saving database.
 */
