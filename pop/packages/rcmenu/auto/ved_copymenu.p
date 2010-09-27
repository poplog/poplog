/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/ved_copymenu.p
 > Purpose:         Copy menu definition file to local directory
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

/*
ENTER copymenu
If this is invoked in a file defining a menu, this command will cause
the file to be copied to your own local menu directory, as defined
by menu_user_dir (see HELP * VED_MENU/menu_user_dir). You can then
edit it, and use ENTER l1 to compile it.

ENTER copymenu <menuname>
As above, except that it will first get the required menu using
the 'showmenu' command, and then make a copy.
*/

section;

define ved_copymenu();
	lvars name, newdir, newname;

	;;; first get the menu file
	if vedargument = nullstring then
		;;; This is a poor test for whether it's a menu file....
		unless issubstring('menu', vedpathname) then
			vederror('NOT EDITING A MENU FILE?')
		endunless;
	else
		;;; get named menu
		veddo('showmenu ' <> vedargument)
	endif;

	;;; Locate the directory for user-owned menus
	if isstring(menu_user_dir) then
		menu_user_dir
	elseif menu_user_dir matches [= ==] then
		recursive_front(menu_user_dir)
	else
		'~/vedmenus'
	endif.sysfileok -> newdir;

	;;; create the directory if it doesn't exist
	unless sysisdirectory(newdir) then
		vedputmessage(
			'MAKING DIRECTORY ' <> newdir <> '. INTERRUPT IF NECESSARY');
		;;; Allow 3 seconds for user to interrupt
		syssleep(300);
		sysobey('mkdir ' <> newdir)
	endunless;

	;;; Assume already editing a menu file by this point
	;;; use ENTER name command to change location and ownership

	sys_fname_name(vedpathname)-> name;
	veddo('name ' <> newdir dir_>< name);
	ved_w1();
	vedputmessage('THIS FILE IS NOW OWNED BY YOU:- ' <> name)

enddefine;

endsection;
