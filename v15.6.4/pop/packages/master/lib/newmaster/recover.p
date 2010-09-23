/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            $poplocal/local/lib/newmaster/recover.p
 > Purpose:         Recovers back versions of master files from "diff" records
 > Author:          Rob Duncan, Jan 16 1989 (see revisions)
 > Documentation:	HELP * NEWMASTER
 > Related Files:	LIB * NEWMASTER
 */


section $-newmaster;

lconstant
	RecoveryString = 'newmaster recover',
		;;; added to the start of each recovered file
;

define lconstant make_message(n, name) -> s;
	lvars	n, name, s;
	dlocal	pop_pr_quotes = false;
	sprintf('%P %P %P', [^RecoveryString ^n ^name]) -> s;
enddefine;

define lconstant parse_message(s) -> (n, name);
	lvars i, j, s, n, name;
	locspace(skipspace(datalength(RecoveryString)+1, s) ->> i, s) -> j;
	strnumber(substring(i, j-i, s)) -> n;
	locspace(skipspace(j, s) ->> i, s) -> j;
	substring(i, j-i, s) -> name;
	unless n and name /= nullstring then
		newmaster_error("recover", 'garbled file header');
	endunless;
enddefine;

define lconstant getline(input);
	lvars c, procedure input;
	consstring(#|
		until (input() ->> c) == termin or c == `\n` do c enduntil;
		if c == `\n` then c endif;
	|#);
enddefine;

;;; write_script:
;;;		copies lines from the diff file to construct an editor script
;;;		for recovering the -nth- back version. This is more complicated
;;;		than it ought to be because the diffs are stored in the wrong
;;;		order (latest last) so must be written out in reverse order.

define lconstant write_script(n, input, script);
	lvars n, input, script, l, dev, ndiffs = 0, sl = stacklength();
	until (getline(input) ->> l) = nullstring do
		if isstartstring(NEWMASTER, l) then
			popstackmark;
			ndiffs + 1 -> ndiffs;
		else
			l;
		endif;
	enduntil;
	if ndiffs < n then
		erasenum(stacklength() - sl);
		newmaster_error("recover", 'not enough back versions');
	endif;
	syscreate(script, 1, false) -> dev;
    repeat n times
	    for l in sysconslist() do
		    syswrite(dev, l, datalength(l));
	    endfor;
	    syswrite(dev, 'w\n', 2);
    endrepeat;
    syswrite(dev, 'q\n', 2);
    sysclose(dev);
	erasenum(stacklength() - sl);
enddefine;

;;; recover:
;;;		recovers the -nth- back version of -file- using the diff record
;;;		in -dfile-. The back version is recreated using "/bin/ed"

define lconstant recover(n, file, dfile);
	lvars script, spool, ed_status, n, file, dfile;

	define lconstant insert_message(msg);
		lvars	msg;
		dlocal	vedbreak = false;
		vedlineabove();
		vedtextleft();
		vedinsertstring(msg);
		vedtextleft();
		vedcheck();
		vedchardown();
	enddefine;

	;;; write out the editor script
	systmpfile(false, 'ed', nullstring) -> script;
	write_script(n, dfile, script);
	;;; make a copy of the file for editing: the copy should have the
	;;; same file type, to make sure that the defaults are set correctly
	;;; when it's read back into VED
	systmpfile(false, sys_fname_nam(file), sys_fname_extn(file)) -> spool;
	sys_file_copy(file, spool);
	;;; do the edit
	vedputmessage('Recovering file ...');
	sysobey('/bin/ed -s > /dev/null 2>&1 < ' <> script <> ' ' <> spool);
	pop_status -> ed_status;
	sysdelete(script) -> ;
	unless ed_status == 0 then
		sysdelete(spool) -> ;
		newmaster_error("recover", 'editor error');
	endunless;
	;;; VED the changed file (read-only)
	if option("quit") then
		vedqget(vedveddefaults, spool, vededitor);
	else
		vededitor(vedveddefaults, spool);
	endif;
	false -> vedwriteable;
	sysdelete(spool) -> ;
	insert_message(make_message(n, file));
enddefine;

define lconstant recovery_name(n, name) -> (n, name);
	lvars	n, name, line, m = 0;
	dlocal	vedline, vedcolumn, vvedlinesize;
	if name = '.' then
		;;; see if the name's in a recovery message
		vedtopfile();
		vedthisline() -> line;
		if isstartstring(RecoveryString, line) then
			parse_message(line) -> (m, name);
		endif;
	endif;
	unless n then
		;;; default to previous version
		m + 1 -> n;
	endunless;
enddefine;

;;; newmaster_recover:
;;;		recovers a back version of a file.
;;;		option("recover") has the format: [^version-number ^file-name]

define lconstant do_recover();
	lvars name, version, n, dfile, tfile = false;
	recovery_name(dl(option("recover"))) -> (n, name);
	locate_file("recover", name) -> (name, version);
	if version then
		version_root(version) dir_>< name -> name;
	endif;
	unless readable(name) then
		newmaster_error("recover", 'no access to file');
	endunless;
	sys_fname_path(name) dir_><
		('DIFFS/' dir_>< sys_fname_name(name)) -> dfile;
	if readable(dfile <> '.Z') then
		;;; compressed
		systmpfile(false, 'diff', nullstring) -> tfile;
		sysobey('zcat 2>/dev/null >' <> tfile <> ' ' <> dfile);
		tfile -> dfile;
	endif;
	readable(dfile) -> dfile;
	if tfile then sysdelete(tfile) -> endif;
	unless dfile then
		newmaster_error("recover", 'no DIFFS file');
	endunless;
	recover(n, name, discin(dfile));
enddefine;
;;;
do_recover -> command("recover");

endsection;		/* $-newmaster */


/* --- Revision History ---------------------------------------------------
--- Robert John Duncan, Sep  1 1992
		Added dlocal of pop_pr_quotes in make_message.
		Changed creation of editing script to use device I/O.
--- Robert John Duncan, Mar 16 1992
		Major reorganisation.
--- Robert John Duncan, Dec 10 1990
		Changed to use -newmaster_error-
--- Rob Duncan, Jun  6 1990
		Changed to use the new -locate_file- mechanism.
 */
