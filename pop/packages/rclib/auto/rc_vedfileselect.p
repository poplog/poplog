/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_vedfileselect.p
 > Purpose:         Show files in Ved buffer.
 > Author:          Aaron Sloman, May 10 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/*

rc_vedfileselect(300, 300, '9x15');

*/

section;

uses rclib
uses rc_popup_strings

define global vars procedure rc_vedfileselect(x, y, font);
	lvars container = false;

	ARGS x, y, font, &OPTIONAL container:isrc_window_object;

	lvars
		file,
		files =
			{%vedappfiles(procedure; vedpathname endprocedure)%};

	;;; prevent mouse warping
	dlocal vedwarpcontext = false;

	;;; present options in 1 column
    rc_popup_strings(x,y, files, ['Select a file'],
		0,0, font, if container then container endif) -> file;

	edit(file);
	vedcurrentfile -> vedinputfocus;
	true -> wvedwindowchanged;
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, May 19 1999
	 Allowed optional container argument for parent rc_window_object
 */
