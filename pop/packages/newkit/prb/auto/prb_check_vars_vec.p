/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_check_vars_vec.p
 > Purpose:			Check contents of vector specifying matcher environment.
 > Author:          Aaron Sloman, Apr 20 1996
 > Documentation:	HELP RULESYSTEMS
 > Related Files:
 */

compile_mode :pop11 +strict;
section;

define prb_check_vars_vec(vars_vec) -> vars_vec;
	;;; If vars_vec is not a vector, return false.
	;;; otherwise ensure that it is a two element vector with a
	;;; list of words to go into popmatchvars and a procedure to initialise them
	;;; and return it
	lvars words, proc, item;
	if isvector(vars_vec) then
		if datalength(vars_vec) == 2 and
			(destvector(vars_vec) ->(words, proc, ); islist(words))
		and isprocedure(recursive_valof(proc) ->> proc)
		then
			;;; set up environment for matcher
			prb_extend_popmatchvars(words, popmatchvars) -> popmatchvars;
			proc();									;;; set up values
		else
			mishap(vars_vec, 1,
				'VECTOR WITH LIST AND PROCEDURE REQUIRED IN RULESET')
		endif
	else
		false -> vars_vec;
	endif;
enddefine;

endsection;
