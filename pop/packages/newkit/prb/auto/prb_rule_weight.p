/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_rule_weight.p
 > Purpose:			Acces or change a rule's weight
 > Author:          Aaron Sloman, Oct 30 1994
 > Documentation:	HELP * POPRULEBASE
 > Related Files:	LIB * POPRULEBASE
 */

section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;


define vars procedure prb_rule_weight(word, /*type*/) -> weight;
	;;; can have an optional list as second argument
	lvars word, weight;
	;;; probably should check that rule exists. If not prb_weight
	;;; will give an error anyway
	prb_weight(prb_rule_named(word, /*type*/)) -> weight;
enddefine;

define updaterof prb_rule_weight(word, /*type*/);
	;;; can have an optional list as second argument
	lvars word;
	-> prb_weight(prb_rule_named(word, /*type*/))
enddefine;

endsection;
