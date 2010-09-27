/* --- copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/lockfile/lockfile.p
 > Linked to:       $poplocal/local/lib/lockfile.p
 > Purpose:			Make "lockfile" libraries and document available
 > Author:          Aaron Sloman,  24 Jul 2002
 > Documentation:	HELP lockf lockfiles ved_lockfile
 > Related Files:	
 */

/*

Compile this file to make lockfile available.

*/

global constant lockfile;

section;

unless isundef(lockfile) then [endsection;] -> proglist endunless;

;;; Use pop-11 global variable if it exists. Default is THIS directory
global vars poplockfiledir = sys_fname_path(popfilename);

lconstant
	lockfile_dir =
		if isstring(poplockfiledir) then poplockfiledir
		else
			;;; Default is THIS directory
			sys_fname_path(popfilename);
			;;; '$poplocal/local/lockfile/'
		endif;

lconstant lockfile_auto =    lockfile_dir dir_>< 'auto/';
lconstant lockfile_lib =     lockfile_dir dir_>< 'lib/';
;;; lconstant lockfile_include = lockfile_dir dir_>< 'include/';

;;; Load and show from lockfile_ directory
extend_searchlist(lockfile_auto, popautolist) -> popautolist;
extend_searchlist(lockfile_lib, popuseslist) -> popuseslist;
;;; extend_searchlist(lockfile_include, popincludelist) -> popincludelist;

;;; And extend ved's teach and help and ref lists
lconstant
	lockfile_teach = [% lockfile_dir dir_>< 'teach/' % teach],
	lockfile_help = [% lockfile_dir dir_>< 'help/' % help],
;;;	lockfile_ref = [% lockfile_dir dir_>< 'ref/' % help],
	lockfile_teachlist = [^lockfile_teach],
	lockfile_helplist = [^lockfile_help],
;;;	lockfile_reflist = [^lockfile_ref],
;
extend_searchlist([^lockfile_help], vedhelplist) -> vedhelplist;
extend_searchlist(lockfile_teachlist, vedteachlist) -> vedteachlist;
extend_searchlist(lockfile_helplist, vedteachlist,true) -> vedteachlist;
;;; extend_searchlist(lockfile_reflist, vedreflist) -> vedreflist;
;;;extend_searchlist(lockfile_helplist, vedreflist, true) -> vedreflist;

extend_searchlist(lockfile_dir, poppackagelist, true) -> poppackagelist;

global constant lockfile = lockfile_dir;
endsection;
