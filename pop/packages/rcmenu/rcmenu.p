/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/rcmenu.p
 > linked to        $poplocal/local/rcmenu/rcmenulib.p
 > Purpose:			set up search lists for rclib based menus
 > Author:          Aaron Sloman, 18 Aug 1999 (see revisions)
 > Documentation:	HELP RCLIB, HELP * VED_MENU
 > Related Files:	LIB * VED_MENU
 */

section;

uses rclib

global constant rcmenulib;
global constant rcmenu;

;;; prevent recompilation
;;; temporarily disabled
unless isundef(rcmenu) then [endsection;] -> proglist endunless;

;;; User definable initial directory for menus. Default '~/vedmenus'
;;; Users can provide their own search list.
global vars menu_user_dir;

;;; The default search list for user menus
if isundef(menu_user_dir) then
	['~/vedmenus'] -> menu_user_dir
endif;

;;; Use pop-11 global variable if it exists. Default is THIS directory
global vars menulibdir = sys_fname_path(popfilename);

;;; Use pop-11 global variable if it exists
global vars popmenudir;

global constant
    menu_root =
		if isstring(popmenudir) then popmenudir
		elseif systranslate( '$popmenu' ) then
	            '$popmenu/'
		else
				menulibdir
		endif;

lconstant menu_auto =    menu_root dir_>< 'auto/';
lconstant menu_lib =     menu_root dir_>< 'lib/';
;;; lconstant menu_include = menu_root dir_>< 'include/';

;;; Load and show from menu_ directory
extend_searchlist(menu_auto, popautolist) -> popautolist;

;;; These don't yet exist
;;; extend_searchlist(menu_lib, popuseslist) -> popuseslist;
;;; extend_searchlist(menu_include, popincludelist) -> popincludelist;

;;; And extend ved's teach and help and ref lists
lconstant
	menu_teach = [% menu_root dir_>< 'teach/' % teach],
	menu_help = [% menu_root dir_>< 'help/' % help],
;;;;	menu_ref = [% menu_root dir_>< 'ref/' % help],
	menu_teachlist = [^menu_teach ],	;;;; ^menu_ref],
	menu_helplist = [^menu_help ],		;;;; ^menu_ref],
;;;;	menu_reflist = [^menu_ref ^menu_help ^menu_teach],
;

;;; Now extend search lists help, etc.

;;; Help list first
extend_searchlist(ident menu_helplist, vedhelplist) -> vedhelplist;
;;; Put the teach directory at the end??
;;; extend_searchlist(ident menu_teachlist, vedhelplist, true) -> vedhelplist;

;;; Extend the teach search list
extend_searchlist(ident menu_teachlist, vedteachlist) -> vedteachlist;

;;; Now put the help directory at the end??
;;; extend_searchlist(ident menu_helplist, vedteachlist, true) -> vedteachlist;

;;;; No REF files yet
;;;; extend_searchlist(ident menu_reflist, vedreflist) -> vedreflist;

extend_searchlist(menu_root, poppackagelist, true) -> poppackagelist;

;;; User extendable search list for autoloadable menus
global vars menu_dirs ;

;;; A directory for autoloadable menus
;;; to go on menu_dirs
lconstant menumenus = menu_root dir_>< 'menus';

if islist(menu_dirs) then
	unless member(menumenus, menu_dirs) then
		[^ menumenus ^^menu_dirs ] -> menu_dirs
	endunless;
else
	[^(ident menu_user_dir) ^menumenus] -> menu_dirs
endif;


global constant rcmenu = menu_root;
;;; alternative mode of invocation
global constant rcmenulib = true;
global constant menulib = true;		;;; prevent compilation of old version

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 25 1999
	Changed to make LIB rcmenu the primary file and LIB rcmenulib
	the link. Will later edit other files to do "uses rcmenu"
	instead of "uses rcmenulib"
 */
