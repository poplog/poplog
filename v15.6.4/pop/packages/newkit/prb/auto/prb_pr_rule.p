/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_pr_rule.p
 > Purpose:			Printing rules so that they can be recompiled
 > Author:          Aaron Sloman, Oct 30 1994
 > Documentation:	HELP * POPRULEBASE
 > Related Files:	LIB * POPRULEBASE
 */

section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;


define procedure prb_pr_rule(rule);
	;;; can have an optional list as second argument
	;;; Prints a rule so that it can be re-compiled.
	lvars rule, word, list;
	if islist(rule) then rule -> list -> rule
	else prb_rules -> list
	endif;
	if isword(rule) then
		rule -> word;
		unless prb_rule_named(word, list) ->> rule then
			mishap(word,1,'NO SUCH RULE')
		endunless
	endif;
	pr('\ndefine :rule '); spr(prb_rulename(rule));
	spr('in'); spr(prb_ruletype(rule));
	applist(prb_conditions(rule), spr);
	pr(';\n\t');
	applist(prb_actions(rule), spr);
	pr('\nenddefine;')
enddefine;

endsection;
