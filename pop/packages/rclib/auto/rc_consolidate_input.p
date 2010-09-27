/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/rc_consolidate_input.p
 > Purpose:			Consolidate text or number input button, if necessary
 > Author:			Aaron Sloman, Aug  4 2002
 > Documentation:
 > Related Files:
 */

section:

uses rclib
uses rc_text_input

define vars procedure rc_consolidate_input(item);
	
	if rc_text_input_active(item) then
		consolidate_or_activate(item)
	endif;

enddefine;

endsection:
