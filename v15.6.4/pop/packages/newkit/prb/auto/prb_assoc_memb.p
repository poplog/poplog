/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_assoc_memb.p
 > Purpose:			Part of LIB * POPRULEBASE
 > Author:          Aaron Sloman, Oct 30 1994
 > Documentation:
 > Related Files: 	LIB * PRBLIB
 */

section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;



define global constant procedure prb_assoc_memb(item, assoc_list);
	;;; given "b" and [[a] 1 [b c] 2 d 3] this returns 2
	;;; given "d" and the above list it returns 3.
	lvars item, next, assoc_list;
	until assoc_list == [] do
		if item == (front(assoc_list) ->> next)
		or ispair(next) and prb_member(item, next)
		then
			return(fast_front(fast_back(assoc_list)))
		else
			fast_back(fast_back(assoc_list)) -> assoc_list
		endif
	enduntil;
	false
enddefine;


endsection;
