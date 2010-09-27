/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_rrr.p
 > Purpose:			Look up records of old mail sent, using ENTER send(mr)
 > Author:          Aaron Sloman, Nov  2 1994 (see revisions)
 > Documentation:	HELP VED_GETMAIL
 > Related Files:
 */


;;; For use with VED_MAIL

define ved_rrr;
	;;; read in records of recent mail sent
	dlocal vedscreenbell = identfn;
	;;; as a precaution, write all writeable files
	ved_w();
	veddo('pved $MAILREC');
	vedendfile();
enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 29 2000
	Made it write writeable files
--- Aaron Sloman, Jan 23 1999
	Slightly simplified, using veddo
 */
