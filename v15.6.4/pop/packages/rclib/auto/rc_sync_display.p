/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_sync_display.p
 > Purpose:			Synchronise display
 > Author:          Aaron Sloman, Mar 27 1997 (see revisions)
 > Documentation: 	HELP * XptSyncDisplay
 > Related Files:
 */

compile_mode :pop11 +strict;

section;

global vars
	;;; Possible argument for syssleep in rc_sync_display
	rc_sync_delay_time = false;

define rc_sync_display();
	XptSyncDisplay(XptDefaultDisplay);
	;;; Synchronise display
	if rc_sync_delay_time then
		syssleep(rc_sync_delay_time);
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 30 1997
	made sleep happen after sync
 */
