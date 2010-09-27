/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_collect_values.p
 > Purpose:         special case of prp_which_values
 > Author:          Aaron Sloman,  23 Nov 1996
 > Documentation:	HELP * READPATTERN, HELP * WHICH
 > Related Files:	LIB * READPATTERN, LIB * !
 */

/*

HELP PRB_COLLECT_VALUES                            Aaron Sloman Nov 1996

prb_collect_values(Spec) -> List;

This procedure takes a list which contains a pattern variable (indicated
by "?" followed by an identifier) followed by one or more patterns. It
finds all possible ways of consistently matching the patterns against
items in the database, and for each of them it remembers the value of
the identifier. It returns a list, possibly empty, of all the values.
Repeated values are pruned.

Here are some examples.


	uses poprulebase;

	prb_newdatabase(16,
   	          [[joe isa man]
              [jill isa woman]
              [joe lives_in london]
              [jill lives_in brighton]
              [bill isa man]
              [sue isa woman]
              [bill lives_in london]
              [sue lives_in paris]]) -> prb_database;


;;; test that
vars x, town, person;
prb_collect_values(! [?x [?x lives_in =]])==>
** [jill sue bill joe]

prb_collect_values(! [?town [= lives_in ?town]])==>
** [brighton paris london]

prb_collect_values(! [?town [mickey lives_in ?town]])==>
** []

prb_add([mickey lives_in moscow]);
prb_collect_values(! [?town [mickey lives_in ?town]])==>
** [moscow]

prb_collect_values(![?person [?person isa woman][?person lives_in paris]])==>
** [sue]

prb_collect_values(
	![?person [?person isa woman][NOT ?person lives_in paris]])==>
** [jill]

prb_collect_values(![?town [?person isa man][?person lives_in ?town]])==>
** [london]

prb_add([mickey isa man]);

prb_collect_values(![?town [?person isa man][?person lives_in ?town]])==>
** [moscow london]

*/

uses poprulebase;

compile_mode :pop11 +strict;
section;


define global vars prb_collect_values(Spec) -> List;
	;;; Spec should be a list starting with "?" then an identifier,
	;;; followed by one or more patterns, the whole having been transformed
	;;; by "!"

	dlocal popmatchvars;	;;; use existing value of popmatchvars

	lvars id, Patternlist;

	unless front(Spec) == "?" and listlength(Spec) fi_> 2
	and (destpair(fast_back(Spec)) -> (id, Patternlist);
			isword(id) or isident(id))
	then
		mishap(Spec, 1, 'List of form [?var <pattern><pattern>..] needed')
	endunless;

	[] -> List;

    prb_forevery(Patternlist,
		procedure(/* locations, counter */); ->,->;
			lvars val = valof(id);
			unless fast_lmember(val, List) then
				conspair(val , List) -> List;
			endunless;
        endprocedure);

	fast_ncrev(List) -> List

enddefine;

endsection;
