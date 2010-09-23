/* --- Copyright University of Birmingham 1998. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_cleanup.p
 > Purpose:			Get rid of backup versions of current file.
 > Author:          Aaron Sloman, Feb  9 1995 (see revisions)
 > Documentation:	Do "ENTER cleanup" to delete backups for current file
 > Related Files:   LIB * VED_PURGEFILES, HELP * VED_PURGEFILES
 */

section;

define ved_cleanup();
	lvars char;
	if vedwriteable then
		if vedchanged then
			ved_w1();
			vedputmessage(
				'File written. Delete backup versions? OK?(n=NO,RETURN=yes):');
		else
			vedputmessage(
				'No changes. Cleanup anyway? (n=NO,RETURN=yes):');
		endif;
		sys_clear_input(poprawdevin);
		vedscr_read_ascii() -> char;
		if strmember(char, 'yY\r') then
			vedputmessage('PLEASE WAIT, DELETING BACKUP FILES');
			veddo('sh /bin/rm ^%*-');
			vedputmessage('DONE');
		else
			vederror('NOTHING DELETED')
		endif;
	else
		vederror('File protected, not written')
	endif
	
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul  7 1998
	Deals better with unchanged files, or non-writeable files.
	Put in more checking.
 */
