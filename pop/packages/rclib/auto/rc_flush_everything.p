/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_flush_everything.p
 > Purpose:         User definable procedure to flush all buffers
 > Author:          Aaron Sloman, May  1 1997 (see revisions)
 > Documentation:
 > Related Files:
 */

section;
compile_mode :pop11 +strict;

define vars rc_flush_everything();
	sysflush(pop_charout_device);
	sysflush(pop_charerr_device);
	if vedediting then
		vedcheck();
		vedsetcursor();
		vedscr_flush_output();
	endif;
	unless vedusewindows then
		sysflush(poprawdevout);
	endunless;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed to use recommended devices.
--- Aaron Sloman, Dec  9 1998
	inserted test for vedusewindows, since
		sysflush(poprawdevout);
	causes xved to hang.
 */
