/* --- Copyright University of Sussex 1992.  All rights reserved. ---------
 > File:            $poplocal/local/lib/newmaster/install.p
 > Purpose:         Installs new or changed POPLOG master files.
 > Author:          Robert Duncan and Simon Nichols, May 1987 (see revisions)
 > Documentation:   HELP * NEWMASTER
 > Related Files:   LIB * NEWMASTER
 */


section $-newmaster;

define lconstant install_master(version, name);
    lvars	version, name, rootdir, cmd, version_n, file_version_n, exists,
			srcfile, logfile, msgfile, tmpfile, srclock, loglock, keep_files;
    dlocal	vedargument, vednotabs, pop_file_mode = 8:664;

	dlocal	0 %
		;;; Normal entry code
		if dlocal_context == 1 then
			false ->> keep_files ->> srclock ->> loglock ->> tmpfile -> msgfile;
		endif,
		;;; Exit code
		if dlocal_context <= 2 then
		    unless keep_files then
			    if loglock == true then unlocklog(logfile) endif;
			    if tmpfile then sysdelete(tmpfile) -> endif;
			    if msgfile then sysdelete(msgfile) -> endif;
		    endunless;
		    unless option("lock") then
			    ;;; unlock the source file if this is a normal exit
			    ;;; or if it was not previously locked
		        if dlocal_context == 1 or srclock == true then
				    unlockfile(srcfile);
		        endif;
		    endunless;
		endif
	%;

    vedputmessage('Checking ...');
	;;; check the master root directory
	check_version_root("install", version) -> rootdir;
    ;;; check that the LOG file exists and is writeable
	check_version_log("install", version) -> logfile;
	;;; check that the installation script is accessible
	check_version_command("install", version) -> cmd;
	;;; get the master version number
	check_version_number("install", version) -> version_n;
	;;; get the pop internal version number
	(name = PopVersionFile and get_pop_internal_version()) -> file_version_n;
    ;;; if the file exists, lock it before installing it ...
	rootdir dir_>< name -> srcfile;
    if readable(srcfile) ->> exists then
		lockfile("install", srcfile) -> srclock;
	;;; ... otherwise ensure the directory is valid
	elseunless sysisdirectory(sys_fname_path(srcfile)) then
		newmaster_error("install", 'no such master directory');
    endif;
    ;;; lock the LOG file
	locklog("install", logfile) -> loglock;
    ;;; set tabs appropriately before writing the file
	if option("doc") then
		true -> vednotabs;
	else
		false -> vednotabs;
#_IF pop_internal_version >= 141100
		;;; VED no longer strips trailing tabs, so make ved_tabify do it
		;;; instead
        '-strip' -> vedargument;
#_ELSE
        nullstring -> vedargument;
#_ENDIF
		valof("ved_tabify")();
    endif;
    ;;; write the file out to a spool file
    systmpfile(
		sys_fname_path(logfile),
		sys_fname_nam(srcfile),
		sys_fname_extn(srcfile)) ->> tmpfile -> vedargument;
	ved_w();
    ;;; run the installation command
	tmpfile <> '.install' -> msgfile;
	true -> keep_files;
    vedputmessage(
	    if exists then
		    'Installing file ...'
	    else
		    'Installing new file ...'
	    endif);
	sysobey(consstring(#|
		lvars s;
		for s in [%
            cmd,
			if newmaster_verbose then '-v' endif,
			if version_test(version) and not(exists) then
				'-test', sysfileok(version_test(version))
			endif,
            if exists then 'MOD' else 'NEW' endif,
            if option("doc") then 'DOC' else 'SRC' endif,
            rootdir,
            sys_fname_path(name),
            sys_fname_name(name),
            tmpfile,
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
	else
		procedure;
			dlocal cucharout = discappend(msgfile);
			printf('\n\t** INSTALLATION FAILED **\n');
			cucharout(termin);
		endprocedure();
    endif;
	if file_version_n and file_version_n /= version_n and not(keep_files) then
		;;; version number has changed
		set_version_number(file_version_n, version);
	endif;
	if option("quit") and not(keep_files) then
	    if sysfilesize(msgfile) == 0 then
		    ved_q();
	    else
			vedqget(vedhelpdefaults, msgfile, vededitor);
	    endif;
	elseif sysfilesize(msgfile) /== 0 then
		vededitor(vedhelpdefaults, msgfile);
	endif;
	vedputmessage(
	    if keep_files then
		    'Installation failed'
	    else
		    'File installed'
	    endif);
enddefine;

define lconstant installation_name() -> (name, version);
    lvars version, name = false;
    if option("doc") then
        is_doc_file() or option("name") -> name;
    elseif is_doc_file() ->> name then
        true -> option("doc");
    else
        is_src_file() or option("name") -> name;
    endif;
    if not(name) then
        newmaster_error(
			"install",
            if option("force") then
                'no filename given'
            elseif option("doc") then
                'no document file footer'
            else
                'no source file header'
            endif);
    elseif issubstring('???', 1, name) then
        newmaster_error("install", 'incomplete filename');
    elseif option("name") and name /= option("name") then
        newmaster_error("install", 'ambiguous filename');
    elseif not(option("doc")) and not(option("force"))
    and not(changed_header(vedpathname))
    then
        newmaster_error("install", 'no revision note added');
    endif;
	locate_file("install", name) -> (name, version);
	if not(version) then
		newmaster_error("install", 'not a master file');
	elseif version_name(version) = 'local' then
		true -> option("local");
	elseif version /= file_version(vedpathname) then
		unless option("version")
		and confirm_action('Different master version -- install anyway')
		then
		    newmaster_error("install", 'different master version');
		endunless;
	endif;
enddefine;

define lconstant do_install();
    lvars version, name, this_file = vedpathname;
    installation_name() -> (name, version);
    if option("local") then
		version_root(version) dir_>< name -> name;
        valof("newmaster_transport")(name, option("transport"))
    elseif option("transport") then
        newmaster_error("transport", 'not a local file');
    else
        install_master(version, name);
    endif;
	false -> changed_header(this_file);
enddefine;
;;;
do_install -> command("install");

endsection;		/* $-newmaster */


/* --- Revision History ---------------------------------------------------
--- Robert John Duncan, Mar 16 1992
		Major reorganisation.
--- John Gibson, Mar 10 1992
		Added '-strip' arg for ved_tabify when pop_internal_version >= 141100
--- Jonathan Meyer, Jun 20 1991
		Added additional parenthesis around the sysobey so that consstring
		wasn't being passed -false- as its last arg.
--- John Gibson, Jun 20 1991
		Added extra false arg to sysobey for pop_internal_version >= 140500
--- Robert John Duncan, Dec 10 1990
		Simplified -install_master- to use new utility procedures shared by
		-newmaster_delete-.
		Added "verbose" and "test" options to installation command.
--- Robert John Duncan, Nov 16 1990
		Added -installation_confirmed- to allow installation into a different
		master system after confirmation from user.
--- Robert John Duncan, Sep  7 1990
		Added more checks to -install_master-.
		Added exit code to remove temporary files and locks on interrupt
		or error.
		Redirected error output from the "installmaster" script to a VED
		file rather than to the log.
--- John Williams, Sep  5 1990
		Should now work from any CRN machine
--- Rob Duncan, Jun 12 1990
		Fixed a bug with unlocking files in -install_master-
--- Rob Duncan, Jun  6 1990
		Changed to use the new -locate_file- mechanism.
--- Rob Duncan, Aug 22 1989
	Added check for non-existent master directory in -install_master-
--- Rob Duncan, Jun 29 1989
	Renamed -writeable- to -iswriteable- to avoid clashing with new system
	identifier. Added assignments to -vednotabs- inside -install_master-.
--- John Williams, Feb  7 1989
	Revised interface to -newmaster_transport-
--- John Williams, Jan 13 1989
    Re-interfaced to transport stuff
--- Rob Duncan, Jan 13 1989
    Substantially rewritten to move much of the work done by the
    "installmaster" script into -install_master-
--- Rob Duncan, Dec  5 1988
    Changed -install- to run the "installmaster" script directly instead of
    via "doinstall". This means the installation is done in the foreground,
    which is simpler to control and synchronises properly with the
    'transport' command
--- John Williams, Dec  2 1988
    Now copes with 'transport' option
--- Rob Duncan, Sep 12 1988
    Reinstated the test against the master machine, as remote installation
    still doesn't work properly. Reorganised quite heavily to allow
    installation to absolute pathnames and to get rid of some silly
    restrictions
--- Simon Nichols, Nov  6 1987
    Replaced test which checked that this_machine = master_machine with a
    test that the master directory is accessible from this_machine.
--- Simon Nichols, Jul 16 1987
    changed 'trylockfile' to 'valof("trylockfile")' and 'lockkey_of' to
    'valof("lockkey_of")' so that the lockfiles utilities be loaded when
    the newmaster saved image is restored.
 */
