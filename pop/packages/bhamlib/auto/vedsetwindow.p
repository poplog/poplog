/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/auto/vedsetwindow.p
 > Purpose:         Improved (faster) version of vedsetwindow
 > Author:          Aaron Sloman, Nov 24 1995
 > Documentation:	See HELP * VEDSETWINDOW
 > Related Files:
 */


vars oldvedsetwindow = vedsetwindow; ;;; precaution

sysunprotect("vedsetwindow");		;;; it should be a VARS but isn't

define vedsetwindow();
	if vedwindowlength < vedscreenlength then
		;;; expand to full window
		vedscreenlength -> vedwindowlength;
		0 -> vedscreenoffset;
		vedcurrentfile -> vedupperfile;
		false -> vedlowerfile;		
		vedcheck();
		vedrefresh();
	else
		;;; Reduce to half window in bottom half of screen, adding 1
		;;; if vedscreenlength is odd.
		vedscreenlength div 2 + vedscreenlength mod 2 -> vedwindowlength;
		vedscreenlength - vedwindowlength -> vedscreenoffset;
		false -> vedupperfile;
		vedcurrentfile -> vedlowerfile;
		vedcheck();
		vedrefresh();
	endif
enddefine;

;;; Make ESC w use this version

vedsetkey('\^[w', "vedsetwindow");
