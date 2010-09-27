/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/isrc_panel_field.p
 > Purpose:			Default recognizer in case lib rc_control_panel has not yet been compiled
 > Author:			Aaron Sloman, Jul 28 2002
 > Documentation:	HELP RCLIB
 > Related Files:	LIB RC_BUTTONS, LIB RC_CONTROL_PANEL
 */


section;
compile_mode :pop11 +strict;

uses objectclass;

define vars isrc_panel_field(item) -> boole;
	;;; this definition is replaced when lib rc_control_panel is compiled
	false -> boole;
enddefine;


endsection;
