/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            $poplocal/local/lib/newmaster/get.p
 > Purpose:         Retrieves a file from the master tree for NEWMASTER
 > Author:          Rob Duncan, Jan 18 1989 (see revisions)
 > Related Files:   LIB * NEWMASTER
 */


section $-newmaster;

define lconstant do_get();
	lvars version, name, key, user;
	locate_file("get", option("get")) -> (name, version);
	if version then
		version_root(version) dir_>< name -> name;
	endif;
	;;; try reading the file
	unless readable(name) then
		newmaster_error(false, 'Cannot get master file%p', [%sysiomessage()%]);
	endunless;
	;;; looks OK -- pved the file and record its version
	if option("quit") then
		vedqget(vedhelpdefaults, name, vededitor);
	else
		vededitor(vedhelpdefaults, name);
	endif;
	version -> file_version(vedpathname);
	;;; check for locks
	valof("trylockfile") -> ;	;;; force autoloading
	valof("lockkey_of")(name) -> key;
	consword(popusername) -> user;
	if key == user then
		vedputmessage('You have this file locked');
	elseif option("lock") then
		if key then
			newmaster_error("lock", 'file locked by %p', [^key]);
		elseif valof("trylockfile")(name, user, 'newmaster get') then
			vedputmessage('File is now locked');
		else
			newmaster_error("lock", 'unspecified error');
		endif;
	elseif key then
		vedputmessage('This file locked by ' sys_>< key);
	endif;
enddefine;
;;;
do_get -> command("get");

endsection;		/* $-newmaster */


/* --- Revision History ---------------------------------------------------
--- Robert John Duncan, Mar 16 1992
		Major reorganisation.
--- Robert John Duncan, Sep  7 1990
		Now gives more information about locks.
--- Rob Duncan, Jun  6 1990
		Changed to use new -locate_file- mechanism.
 */
