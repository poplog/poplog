/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_truncate.p
 > Purpose:			Used to shorten memory in poprulebase
 > Author:          Aaron Sloman, Oct 30 1994
 > Documentation:
 > Related Files:
 */

'prb_truncate is withdrawn' =>
nil -> proglist;
section;

;;; WARNING MAY BE IRRELEVANT SINCE PRB_MEMLIM HAS BEEN WITHDRAWN

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

;;; check that this is consistent with poprulebase.p
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


define global constant procedure prb_truncate(list,num) -> list;
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
	if prb_divides_chatty(DATABASE_CHANGE) then
		'Database truncated to ' sys_><  prb_memlim =>
	endif
enddefine;

endsection;
