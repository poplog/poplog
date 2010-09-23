/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/lib/prb_replace.p
 > Purpose:			Do substitution
 > Author:          Aaron Sloman, Oct 30 1994
 > Documentation:
 > Related Files:
 */

section;

compile_mode:pop11 +strict;

;;;compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;


define global constant procedure prb_replace(item, value, list) -> list;
	;;; replace all occurrences of item with contents of value in list,
	;;; making a copy
	lvars element, item, value, list;
	[% fast_for element in list do
		if ispair(element) then prb_replace(item, value, element)
		elseif element == item then
			if islist(value) then dl(value) else value endif
		else element
		endif
	  endfast_for %] -> list
enddefine;

endsection;
