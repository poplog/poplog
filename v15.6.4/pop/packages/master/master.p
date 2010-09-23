/* --- copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/master/master.p
 > Linked to:       $poplocal/local/lib/master.p
 > Purpose:			Make "master" libraries and document available
 > Author:          Aaron Sloman,  24 Jul 2002
 > Documentation:	HELP getmaster newmaster rmmaster ved_master
 > Related Files:	
 */

/*

Compile this file to make master available.

*/

global constant master;

section;

unless isundef(master) then [endsection;] -> proglist endunless;

uses lockfile;

lconstant
	master_dir =
			;;; Default is THIS directory
			sys_fname_path(popfilename);

lconstant master_auto =    master_dir dir_>< 'auto/';
lconstant master_lib =     master_dir dir_>< 'lib/';
;;; lconstant master_include = master_dir dir_>< 'include/';

;;; Load and show from master_ directory
extend_searchlist(master_auto, popautolist) -> popautolist;
extend_searchlist(master_lib, popuseslist) -> popuseslist;
;;; extend_searchlist(master_include, popincludelist) -> popincludelist;

;;; And extend ved's teach and help and ref lists
lconstant
	master_teach = [% master_dir dir_>< 'teach/' % teach],
	master_help = [% master_dir dir_>< 'help/' % help],
;;;	master_ref = [% master_dir dir_>< 'ref/' % help],
	master_teachlist = [^master_teach],
	master_helplist = [^master_help],
;;;	master_reflist = [^master_ref],
;
extend_searchlist([^master_help], vedhelplist) -> vedhelplist;
extend_searchlist(master_teachlist, vedteachlist) -> vedteachlist;
extend_searchlist(master_helplist, vedteachlist,true) -> vedteachlist;
;;; extend_searchlist(master_reflist, vedreflist) -> vedreflist;
;;;extend_searchlist(master_helplist, vedreflist, true) -> vedreflist;

extend_searchlist(master_dir, poppackagelist, true) -> poppackagelist;

global constant master = master_dir;
endsection;
