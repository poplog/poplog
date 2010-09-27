/* --- Copyright University of Birmingham 1992. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_wappcm.p
 > Purpose:			Mark current message, copy it to disk, and delete
 > Author:          Aaron Sloman, Jan 14 1990 (see revisions)
 > Documentation:	(See below)
 > Related Files:	LIB * VED_MCM, * VED_WAPPR, * VED_WAPPDR
 */
/*
Write, append, and delete current message to named file.
<ENTER> wappcm <file>
=
	1. ved_mcm
		(mark current message)
	2. ved_wappdr <file>
		(append and delete current message)

	3. Tidy up and find suitable new location for cursor.

The append mechanism uses -discappend- rather than ved_mmo. So it is
very fast, and doesn't produce VED backup files - it just sticks the
message on the end of the disk file.

*/

;;; Get procedure to go back to last message header line: ved_lm.
uses ved_lm

uses ved_wappr;

section;

define ved_wappcm;
	dlocal vvedmarkprops, vedediting;
	sysfileok(vedargument) -> vedargument;

	if vedargument = vedpathname then
		vederror('CAN\'T APPEND TO CURRENT FILE')
	endif;
	;;; make search state local. See HELP VEDSEARCH
    dlocal vvedanywhere, vvedoldsrchdisplay,
	    vvedsrchstring, vvedsrchsize;
	vedmarkpush();
	false -> vvedmarkprops;
	vedmarkpush();
	false -> vvedmarkprops;
	ved_mcm();
	;;; ensure there's a blank line output at end
	if vedusedsize(subscrv(vvedmarkhi,vedbuffer)) /== 0 then
		vedjumpto(vvedmarkhi,1);
		vedlinebelow();
		vedmarkhi()
	endif;
	ved_wappdr();
	vedmarkpop();
	vedmarkpop();
	if vedatend() then ved_lm()
	elseunless vvedlinesize == 0 or vedline == 1 then
		vedlinebelow();
	endif;
	unless vedatend() then
		vedlocate('@?');
	endunless;
	;;; vedrefreshrange(vvedmarklo,vvedmarkhi,undef);
	;;;vedrefreshrange(vvedmarklo,vvedmarkhi,undef);
enddefine;

endsection;



/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, 31 Jan 1991.
		made search variables local
--- Aaron Sloman, Mar 18 1992
		stopped writing to same file
 */
