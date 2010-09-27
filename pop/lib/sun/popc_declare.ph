/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:			C.all/lib/sun/popc_declare.ph
 > Purpose:			Identifier declarations for POPC
 > Author:			John Gibson, Nov 13 1992
 */

library_declare_section '$popsunlib/'

section;

weak global vars procedure (
		vedwin_adjust,
		vedwin_call5,
		vedwin_position,
		vedwin_tty_size,
		vedwin_window_size,
	);

weak global constant
		vedwin_utils,
	;

weak global vars
		vedwin_extracols
	;

endsection;

end_library_declare_section;
