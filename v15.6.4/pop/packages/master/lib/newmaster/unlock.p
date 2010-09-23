/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            $poplocal/local/lib/newmaster/unlock.p
 > Purpose:         Unlock a master file
 > Author:          Robert John Duncan, Mar  2 1992
 > Documentation:   HELP * NEWMASTER
 > Related Files:   LIB * NEWMASTER
 */


section $-newmaster;

define lconstant do_unlock();
	lvars name, version, user, key;
	option("unlock") -> name;
	if name = 'LOG' then
		;;; special case for the newmaster LOG file
		'install/LOG' -> name;
		"newmaster" -> user;
	else
		option("user") or consword(popusername) -> user;
	endif;
	locate_file("unlock", name) -> (name, version);
	if version then
		version_root(version) dir_>< name -> name;
	endif;
	valof("tryunlockfile") -> ;	;;; force autoloading
	valof("lockkey_of")(name) -> key;
	if not(key) then
		vedputmessage('File not locked');
	elseif key /== user then
		newmaster_error("unlock", 'file locked by %p', [^key]);
	elseif tryunlockfile(name, user) then
		vedputmessage('File unlocked');
	else
		newmaster_error("unlock", 'unspecified error');
	endif;
enddefine;
;;;
do_unlock -> command("unlock");

endsection;		/* $-newmaster */
