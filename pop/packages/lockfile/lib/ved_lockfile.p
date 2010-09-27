/* --- Copyright University of Birmingham 2006. All rights reserved. ------
 > File:			$usepop/pop/packages/lockfile/lib/ved_lockfile.p
 > Linked to		$usepop/pop/packages/vedutils/lib/ved_lockfile.p
 > Purpose:			Lock and unlock ved files
 > Author:          Aaron Sloman, May  9 1992 (see revisions)
 > Documentation: HELP * VED_LOCKFILE
 > Related Files:
 */

section;

;;; Warning, to prevent files read using pved from being locked,
;;; redefine pved and ved_pved to ensure that vedwriteable is made
;;; false early enough. The complex definition is given to ensure
;;; that vedsearchlist is used.

vars pvedtemp;

define ved_pved;
	if vedinvedprocess and vedargument = nullstring then
		false -> vedwriteable
	else
		define dlocal vedsysfileerror(type,name);
			;;; catch the case where new file is to be created
			lvars type, name;
			vededitor(vedhelpdefaults, name)
		enddefine;

		;;; give this a search list able to cope with relative and
		;;; absolute path names, as well as with vedsearchlist
		vedsysfile("pvedtemp",['.' ^^vedsearchlist '/'],false)
	endif
enddefine;


;;; Check that file was locked in this process
lconstant procedure ved_locked
	= newproperty([], 64, false, "tmparg");

global constant
	ved_lock_extn = '.VLCK',
;

;;; The user's login directory name will be assigned to this

;;; Make ved_lock_files false locally or globally to turn off locking
;;; Make it "mine" to ensure only locking of files in your own directory
global vars ved_lock_files = true;

;;; in case ved_autosave has not been compiled.
global vars vedautosaving;  ;;; made false during file locking/unlocking

lvars user_id = false;


define lconstant sys_file_owner(file) -> owner;
	lconstant vec = {0 0 0 0};
	sys_file_stat(file, vec, true) -> owner;

	if owner then fast_subscrv(4, owner) -> owner endif;

enddefine;

define lconstant procedure vedlockable(file) -> locking;
	lvars path;

	unless user_id then
		;;; Find the user's id. There should be a better way.
		sys_file_owner(popdirectory) -> user_id
	endunless;

	if ved_lock_files == "mine" then
		;;; must own file or directory?
		(sys_file_owner(file) == user_id or
		 sys_file_owner(sys_fname_path(file)) == user_id) -> locking
	elseif isstring(ved_lock_files) then
		;;; Is it in a subdirectory of the specified directory
		isstartstring(ved_lock_files, file) -> locking
	elseif isprocedure(ved_lock_files) then
		ved_lock_files(file) -> locking
	elseif islist(ved_lock_files) then
		;;; assume its a list of strings

		for path in ved_lock_files do
		;;; check if path of form [not <string> ] and string
		;;; starts vedpathname
		returnif(
			islist(path) and hd(path) == "not"
			and isstartstring(sysfileok(hd(tl(path))), file)
			)(false -> locking);
		;;; check if path of form <string> and string starts vedpathname
		returnif(
			isstring(path)
			and isstartstring(sysfileok(path), file)
			)(true -> locking)
		endfor;
		false -> locking;

	elseif isstartstring('/tmp/', file)
	or isstartstring('/usr/tmp/', file)
	then
		;;; don't lock temporary files
		false -> locking
	elseif ved_lock_files == true then
		true -> locking
	else
		vederror('ved_lock_files has unexpected value. See HELP VED_LOCKFILE')
	endif
enddefine;



define ved_lockfile();
	;;; Lock the current file if necessary.
	;;; Warn user if it is already locked

	;;; prevent autosaving during locking
	dlocal vedautosaving = false;

	if vedwriteable and ved_lock_files then
		lvars lockfile = vedpathname <> ved_lock_extn;

		if ved_locked(vedpathname) or sys_file_exists(lockfile)
		then
			vedscreenbell();
			vedputmessage('WARNING FILE ALREADY LOCKED');
			dlocal vedwiggletimes = 12;
			if vedusewindows == "x" then
				;;; the message will have gone out on the previous file
				;;; (if there was one), which will be -vedupperfile-.
				;;; Do the wiggle on that.
			returnunless(isvector(vedupperfile));
				dlocal ved_current_file = vedupperfile;
			endif;
			vedwiggle(0,min(vedscreencolumn,65));

		else
			if vedlockable(vedpathname) then
				sysobey('touch ' sys_>< lockfile, `$`);
				if pop_status == 0 then
					;;; locking succeeded
					lockfile -> ved_locked(vedpathname)
				else
					;;; something went wrong, e.g. non-writeable directory
					vedinput(
						vedputmessage
							(%'NOT LOCKABLE, DIRECTORY PROTECTED?'%));
				endif
			endif;
		endif;
	endif
enddefine;

define ved_unlockfile();
	lvars path = vedpathname;
	if ved_lock_files and ved_locked(path) then
		false -> ved_locked(path);

		dlocal pop_file_versions = false, vedversions = false;
		;;; delete lock
		if sysdelete( path <> ved_lock_extn ) then
			vedputmessage('DELETED LOCK FILE for ' <> path);
		else
			vedputmessage('COULD NOT DELETE LOCK FILE');
		endif
	else
		;;; For debugging. Will be removed.
;;;		if vedwriteable then vedputmessage('FILE NOT LOCKED') endif;
	endif
enddefine;

define vedlockfileexit();
	'Exiting VED: Checking lock files' =>
	vedappfiles(
		procedure(); vedpathname => ved_unlockfile() endprocedure);
	appproperty(ved_locked,
		procedure(name, val); lvars name, val;
			'WARNING ' <> name <> ' STILL LOCKED' =>
		endprocedure)
enddefine;

;;; Now make sure that files are unlocked by ved_rqq, ved_xx, etc.
;;; and by ved_name.

define ved_rqq();
	vedlockfileexit();
	[] -> vedbufferlist;
	sysexit();
enddefine;

lconstant old_ved_name = ved_name;

define ved_name;
	;;; unlock file before renaming
	unless vedargument = nullstring then ved_unlockfile() endunless;
	old_ved_name();
enddefine;

lvars procedure olddiscappend = discappend;

define global discappend(file);
	lvars file;
	if isstring(file) and sys_file_exists(file <> '.VLCK') then
		vederror('APPENDING TO LOCKED FILE (' <> file <> '.VLCK exists)')
	endif;

	olddiscappend(file);
enddefine;

;;; Make sure that locking and unlocking always occur when starting
;;; or quitting a file

vedinitialise <> ved_lockfile -> vedinitialise;

vedvedquitfile <> ved_unlockfile -> vedvedquitfile;


endsection;

/*
;;; for testing

erase -> vedinitialise;
identfn -> vedvedquitfile;
ved_locked(vedpathname)
ved_lockfile() .rawcharin ->;
ved_unlockfile(), .rawcharin ->;

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 29 2006
		Changed discappend not to check locks on devices
		
--- Aaron Sloman, Jan 30 2000
	Changed to turn off autosaving during locking. Is that enough? Could
	autosaving already be in progress?
--- Aaron Sloman, may 1998
	Changed to allow different interpretation of "mine"
--- Aaron Sloman, Nov 26 1995
	Changed to make local define explicitly dlocal, for Poplog V15.0
--- Aaron Sloman, Sep  3 1992
	Altered ved_name so that it only unlocks the file if there's
		a new name
--- Aaron Sloman, Aug 17 1992
	Changed discappend to refuse to append to locked file.
	Changed wiggle times to 12 for fast machines
--- Aaron Sloman, Aug 13 1992
	Fixed problem with files already locked, under Xved
		Thanks to help from John Gibson
--- Aaron Sloman, Jun 17 1992
	Made the "DELETED" message include file name
	Made separate help file
 */
