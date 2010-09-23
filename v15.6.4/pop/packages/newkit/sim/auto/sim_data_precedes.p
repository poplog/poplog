/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/newkit/sim/auto/sim_data_precedes.p
 > Purpose:			General purpose "less than" procedure, e.g. for use in sorting
 > Author:          Aaron Sloman, Jul 21 1999
 > Documentation:   To be added
 > Related Files:	LIB SIM_PR_DB
 */


section;
compile_mode :pop11+strict;
uses poprulebase
uses sim_agent

/*

Since database items can contain arbitrary pop-11 structures, not
just words, we need a way to order database keys which generalises
alphabetic ordering.

One solution would be to print the items to be compared into a string
(e.g. item sys_>< nullstring -> string) and then compare the strings
alphabetically. That would cause garbage.

The following, instead, uses syshash, which is guaranteed to produce
the same number for two items which are =

If finer discrimination is required, increase sim_hash_lim (default
value 3).
See REF SYSHASH

;;; Test commands
sim_data_precedes(pr, "cat") =>
sim_data_precedes(pr, "dog") =>
sim_data_precedes("hat", "dog") =>
sim_data_precedes("hat", 'dog') =>
sim_data_precedes("hat", 'dog') =>
sim_data_precedes({1 2 3}, 'dog') =>

*/

global vars sim_hash_lim = 3;

define vars procedure sim_data_precedes (item1, item2) -> boole;
	;;; users can redefine this if they wish

	dlocal pop_hash_lim = sim_hash_lim;

    if isnumber(item1) and isnumber(item2) then

       item1 <= item2

    elseif (isword(item1) or isstring(item1))
	   and (isword(item2) or isstring(item2))
    then
        alphabefore(item1, item2)
    else

        syshash(item1) <= syshash(item2)

    endif -> boole
enddefine;


endsection;
