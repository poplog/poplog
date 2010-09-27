/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_walk_trace.p
 > Purpose:			interactive procedures for POPRULEBASE actions
 > Author:          Aaron Sloman, Oct 30 1994
 > Documentation:	HELP * POPRULEBASE
 > Related Files:
 */

section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;


define prb_walk_trace(rule_instance, action);
	lvars rule_instance, action,
		rule = prb_ruleof(rule_instance),
		name = prb_rulename(rule);

	dlocal prb_remember, pop_readline_prompt = 'Walking> ';

		prb_interact(
		[['Doing RULE' ^name] [ACTION ^action] ],
				action, rule_instance, true) ->
enddefine;

endsection;
