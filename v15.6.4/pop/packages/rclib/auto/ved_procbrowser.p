/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/ved_procbrowser.p
 > Purpose:			Tool to support navigation of a pop-11 program file
 > Author:          Aaron Sloman, Sep  3 1999 (see revisions)
 > Documentation:	
 > Related Files:	LIB RC_CONTROLPANEL, RC_PROCBROWSER
 */


section;

uses rclib
uses rc_control_panel
uses rc_display_strings


define ved_procbrowser();
	lvars extension = sys_fname_extn(vedpathname);
	if member(extension, lispfiletypes) then
		veddo(':rc_lispbrowser()')
	else
		veddo(':rc_procbrowser()')
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 13 1999
	Extended to invoke lisp browser if needed.
 */
