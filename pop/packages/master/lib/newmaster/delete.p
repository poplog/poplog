/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            $poplocal/local/lib/newmaster/delete.p
 > Purpose:         Delete a file from a master tree
 > Author:          Robert John Duncan, Nov 27 1990 (see revisions)
 > Documentation:   HELP * NEWMASTER
 > Related Files:   LIB * NEWMASTER
 */


section $-newmaster;

define lconstant delete_master(version, name);
    lvars	version, name, rootdir, cmd, srcfile, logfile, msgfile, srclock,
			loglock, keep_files;

    dlocal	0 %
		;;; Normal entry code
		if dlocal_context == 1 then
			false ->> keep_files ->> srclock ->> loglock -> msgfile;
		endif,
		;;; Exit code
		if dlocal_context <= 2 then
            unless keep_files then
                if loglock == true then unlocklog(logfile) endif;
                if srclock == true then unlockfile(srcfile) endif;
                if msgfile then sysdelete(msgfile) -> endif;
            endunless;
		endif
	%;

    vedputmessage('Checking ...');
    ;;; get the master root directory name
    check_version_root("delete", version) -> rootdir;
    ;;; get the log file name
    check_version_log("delete", version) -> logfile;
    ;;; check that the file exists
    rootdir dir_>< name -> srcfile;
    unless sys_file_stat(srcfile, {}) then
        newmaster_error("delete", 'no such master file');
    endunless;
    ;;; check that the delete script is accessible
    check_version_command("delete", version) -> cmd;
    ;;; create a temporary file for messages
    systmpfile(
        sys_fname_path(logfile),
        sys_fname_nam(srcfile),
        sys_fname_extn(srcfile) <> '.delete') -> msgfile;
    ;;; confirm the deletion:
    ;;; the filename is written out to a buffer to make sure it's visible
    procedure;
		dlocal 0 %
			if dlocal_context == 1 then
				vededitor(vedhelpdefaults, msgfile);
			endif,
            if dlocal_context <= 2 then
				ved_q();
			endif
		%;
        vedinsertstring(srcfile);
        confirm_action('Delete this file');
    endprocedure(),
	unless /* confirmed */ then interrupt() endunless;
    ;;; lock the source file
    lockfile("delete", srcfile) -> srclock;
    ;;; lock the LOG file
    locklog("delete", logfile) -> loglock;
    ;;; delete the file
    vedputmessage('Deleting file ...');
    true -> keep_files;
    sysobey(consstring(#|
        ;;; deletemaster [-v] [-test dir] root dir file key >>LOG 2>msgs
        lvars s;
        for s in [%
            cmd,
            if newmaster_verbose then '-v' endif,
            if version_test(version) then
                '-test', sysfileok(version_test(version))
            endif,
            rootdir,
            sys_fname_path(name),
            sys_fname_name(name),
            consword(popusername),
            '>>', logfile,
            '2>', msgfile,
        %] do
            explode(s), `\s`
        endfor
#_IF pop_internal_version >= 140500
	|#), false);	;;; false arg says won't produce terminal output
#_ELSE
	|#));
#_ENDIF
    if pop_status == 0 then
        false -> keep_files;
        true -> srclock;    ;;; this makes sure the file is unlocked on exit
    else
        procedure;
            dlocal cucharout = discappend(msgfile);
            printf('\n\t** DELETION FAILED **\n');
            cucharout(termin);
        endprocedure();
    endif;
    if sysfilesize(msgfile) /== 0 then
        vededitor(vedhelpdefaults, msgfile);
    endif;
    vedputmessage(
        if keep_files then
            'Deletion failed'
        else
            'File deleted'
        endif);
enddefine;

define lconstant do_delete();
    lvars version, name;
    locate_file("delete", option("delete")) -> (name, version);
    unless version and version_type(version) = 'master' then
        newmaster_error("delete", 'not a master file');
    endunless;
    delete_master(version, name);
enddefine;
;;;
do_delete -> command("delete");

endsection;

/* --- Revision History ---------------------------------------------------
--- Robert John Duncan, Mar 16 1992
		Major reorganisation.
--- Adrian Howard, Jul  1 1991 : -dlocal_context- tests added so it works
        properly with VED as a process
*/
