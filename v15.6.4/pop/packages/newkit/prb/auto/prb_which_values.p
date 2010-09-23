/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_which_values.p
 > Purpose:         POPRULEBASE version of which_values
 > Author:          Aaron Sloman,  23 Nov 1996
 > Documentation:	HELP * READPATTERN, HELP * WHICH
 > Related Files:	LIB * READPATTERN, LIB * !
 */

/*

HELP PRB_WHICH_VALUES                              Aaron Sloman Nov 1996

prb_which_values(Vars, Patternlist) -> List;

The procedure prb_which_values, which works with Poprulebase, is a
replacement for "which_values", as explained in HELP * WHICH_VALUES,
which does not work with Poprulebase.

It takes a list of pattern variables, each indicated by "?" followed by
a word or identifier, and a list of patterns. It tries all possible ways
of consistently matching the patterns in Patternlist against items in
the database (prb_database), and for each of them it makes a list of the
values of the variables in the Vars list. All such lists are then put
into a single large list, in the order in which they are found, and that
list is returned as the value of prb_which_values.

This can be compared with the somewhat more simple prb_collect_values,
which can handle only one variable at a time.

Example of use:

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
vars x,y;
prb_which_values(! [?x ?y], ! [[?x lives_in ?y]])==>
** [[jill brighton] [sue paris] [bill london] [joe london]]

prb_which_values(![?person], ! [[?person isa woman]])==>
** [[jill] [sue]]

prb_which_values(![?person],
	! [[?person isa woman][NOT ?person lives_in paris]])==>
    ** [[jill]]

*/

uses poprulebase;

compile_mode :pop11 +strict;
section;


define global vars prb_which_values(Vars, Patternlist) -> List;
	;;; Vars should be a list of variables prefixed by "?" transformed by "!"
	;;; Patternlist should be a list of patterns, the whole having been transformed
	;;; by "!"

	dlocal popmatchvars;	;;; use existing value of popmatchvars

	lconstant err_string = 'LIST NEEDED FOR "WHICH_VALUES"';

    if ispair(Vars) then
        if ispair(Patternlist) then

			[] -> List;

            prb_forevery(Patternlist,
				procedure(/* locations, counter */); ->, ->;
              	lvars list;
				conspair(
                	[%for list on Vars do
						if front(list) == "?" or fast_front(list) == "??" then
                    		valof(front(fast_back(list)))
						endif
                  	endfor%], List) -> List;
              	endprocedure);

		  fast_ncrev(List) -> List

        else mishap(err_string, [^Patternlist])
        endif;
    else
        mishap(err_string, [^Vars] )
    endif;
enddefine;

endsection;
