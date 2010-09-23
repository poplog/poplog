/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/ved_edmenu.p
 > Purpose:         Edit a menu file
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

/*

	ENTER edmenu foo

Enables you to edit the file menu_foo.p which is somewhere in
the current search list for menu files. If such a file is not found,
it assumes you wish to start one in the directory ~/vedmenus
(or the head of menu_user_dir)

If that does not already exist, an error will result.


*/


section;

uses ved_menu;

global vars vedmenuname = undef;

define ved_edmenu();
	;;; lib ENTER showlib, but shows a menu instead, and makes it writeable
	;;; e.g. ENTER edmenu file
	lvars found, new = false, name = vedargument;

	if vedargument = nullstring then
		vederror('edmenu WHAT?')
	else
		;;; add standard prefix and suffix
		dlocal vedargument
			= menu_startstring sys_>< vedargument sys_>< '.p';
	endif;

	vedgetlibfilename(
		menu_dirs <> popautolist,
		"vedlibname",
		vedargument) -> found;

    unless found then
		hd(menu_user_dir) dir_>< vedargument -> found;
		true -> new;
	endunless;

	;;; now get the file
	vededitor(
		procedure(); "menu" -> vedfileprops; vedveddefaults() endprocedure,
		found);

	if new then
		applist(
			[';;; LIB menu_' ^name '.p\n;;; ' ^(sysdaytime())
			 '\n;;; ' ^(sysgetusername(popusername))
			'\n\ndefine :menu ' ^name ';\n\nenddefine;'],
			vedinsertstring);
		vedcharup();
		1 -> vedcolumn;
	endif;
enddefine;

endsection;
