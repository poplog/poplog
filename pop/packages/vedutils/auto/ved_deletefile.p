/* --- Copyright University of Birmingham 1992. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_deletefile.p
 > Purpose:			Delete current file
 > Author:          Aaron Sloman, Feb  6 1992 (see revisions)
 > Documentation:   HELP * VED_DELETEFILE
 > Related Files:
 */

section;

define global ved_deletefile();
	dlocal pop_file_versions = false, vedversions = false;
	if vedargument = nullstring then
		;;; delete current file
		if sysdelete(vedpathname) then
			vedputmessage('DELETED');
		endif;
		false -> vedwriteable;
		ved_q();
	else
		vederror('"ENTER deletefile" takes no additional arguments');
	endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jun 21 1992
	Removed reference to vedmaildirectory
 */
