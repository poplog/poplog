/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/rclib.p
 > Linked to:       $poplocal/local/lib/rclib.p
 > Purpose:			Make "rclib" libraries and document available
 > Author:          Aaron Sloman,  2 Jan 1997 (see revisions)
 > Documentation:	HELP * RCSTUFF (to be written)
 > Related Files:	LIB * RC_GRAPHIC * RC_LINEPIC, * RC_MOUSEPIC
 */

/*

Compile this file to make rclib available.
Then try TEACH * RC_LINEPIC

*/

global constant rclib;

section;

unless isundef(rclib) then [endsection;] -> proglist endunless;

uses objectclass
uses popxlib
uses rc_graphic


;;; Use pop-11 global variable if it exists. Default is THIS directory
global vars poprclibdir = sys_fname_path(popfilename);

;;; or use environment variable if it exists
lconstant RC_VAR = systranslate('rclib');

lconstant
	rclib_dir =
		if isstring(poprclibdir) then poprclibdir
		elseif isstring(RC_VAR) then RC_VAR
		else
			;;; Default is THIS directory
			sys_fname_path(popfilename);
			;;; '$poplocal/local/rclib/'
		endif;

lconstant rclib_auto =    rclib_dir dir_>< 'auto/';
lconstant rclib_lib =     rclib_dir dir_>< 'lib/';
;;; lconstant rclib_include = rclib_dir dir_>< 'include/';

;;; Load and show from rclib_ directory
extend_searchlist(rclib_auto, popautolist) -> popautolist;
extend_searchlist(rclib_lib, popuseslist) -> popuseslist;
;;; extend_searchlist(rclib_include, popincludelist) -> popincludelist;

;;; And extend ved's teach and help and ref lists
lconstant
	rclib_teach = [% rclib_dir dir_>< 'teach/' % teach],
	rclib_help = [% rclib_dir dir_>< 'help/' % help],
	rclib_ref = [% rclib_dir dir_>< 'ref/' % help],
	rclib_teachlist = [^rclib_teach],
	rclib_helplist = [^rclib_help],
	rclib_reflist = [^rclib_ref],
;
extend_searchlist([^rclib_help], vedhelplist) -> vedhelplist;
extend_searchlist(rclib_teachlist, vedteachlist) -> vedteachlist;
extend_searchlist(rclib_helplist, vedteachlist,true) -> vedteachlist;
extend_searchlist(rclib_reflist, vedreflist) -> vedreflist;
extend_searchlist(rclib_helplist, vedreflist, true) -> vedreflist;

extend_searchlist(rclib_dir, poppackagelist, true) -> poppackagelist;

max(popmemlim, 3000000) -> popmemlim;


global constant rclib = true;
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 10 2002
		Extended to accommodate new ref files
 */
