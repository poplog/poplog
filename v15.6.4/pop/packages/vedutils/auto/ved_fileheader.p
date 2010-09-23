/* --- Copyright University of Birmingham 1998. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_fileheader.p
 > Purpose:			Start a file header, for students etc
 > Author:          Aaron Sloman, Oct 19 1996 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
ENTER fileheader
Produces a heading in something like this format
    /*
    FILE:            /home/staff/axs/output.p
    AUTHOR:          Aaron Sloman
    CREATION DATE:   19 Oct 1996
    COURSE:          ???
    PURPOSE:         ???
    LAST MODIFIED:   19 Oct 1996

    */

*/

section;

define lconstant next_field(string);
	vedlinebelow(); ;;; vedinsertstring(' > ');
	vedinsertstring(string);
enddefine;

define ved_fileheader();
	lvars filename = vedpathname;
	if isstartstring('/tmp_mnt', filename) then
		allbutfirst(8, filename) -> filename
	endif;

	vedtopfile();
	vedlineabove();
	vedinsertstring('/*');
	next_field('FILE:            '); vedinsertstring(filename);
	next_field('AUTHOR:          ' sys_>< (sysgetusername(popusername) or popusername));
	next_field('CREATION DATE:  '); ved_day();
	next_field('COURSE:          ???');
	next_field('PURPOSE:         ???');
	next_field('LAST MODIFIED:  '); ved_day();
	vedlinebelow();
	vedlinebelow(); vedinsertstring('*/');
	vedlinebelow();
	vedtopfile();
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov 27 1998
	Changed to remove /tmp_mnt
 */
