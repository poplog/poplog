/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            $poplocal/local/lib/newmaster/mark.p
 > Purpose:         Add a mark to the NEWMASTER log
 > Author:          Robert John Duncan, Mar 10 1992
 > Documentation:   HELP * NEWMASTER
 > Related Files:   LIB * NEWMASTER
 */

section $-newmaster;

define lconstant do_mark();
	lvars version, logfile, i = 0, mark = option("mark");
	;;; get the master version record
	vername_search(option("version") or 'default', newmaster_versions)
		-> version;
	;;; check the LOG file exists and is writeable
	check_version_log("mark", version) -> logfile;
	;;; lock it
	locklog("mark", logfile) -> ;
	;;; replace any single quotes in the mark (used as a delimiter)
	while locchar(`'`, i+1, mark) ->> i do
		if mark == option("mark") then copy(mark) -> mark endif;
		``` -> mark(i);
	endwhile;
	;;; write the mark to the LOG
	mark_log(mark, logfile);
	vedputmessage('LOG file locked');
enddefine;
;;;
do_mark -> command("mark");

endsection;		/* $-newmaster */
