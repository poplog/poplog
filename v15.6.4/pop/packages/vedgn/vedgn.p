/* --- Copyright University of Birmingham 2005. All rights reserved. ------
 > File:            $usepop/pop/packages/ved_gn/ved_gn.p
 > Linked to:       $usepop/pop/packages/lib/ved_gn.p
 > Purpose:			Make "ved_gn" libraries and document available
 > Author:          Aaron Sloman,  8 Jan 2005 (see revisions)
 > Documentation:	HELP * VED_GN, VED_POSTNEWS
 > Related Files:	LIB * unix_sockets
 */

/*

Compile this file to make ved_gn available.
Then try HELP ved_gn

*/


section;

global constant vedgn;

unless isundef(vedgn) then [endsection;] -> proglist endunless;

lconstant
	vedgn_dir =
			;;; Default is THIS directory
			sys_fname_path(popfilename);

lconstant vedgn_auto =    vedgn_dir dir_>< 'auto/';
;;; lconstant vedgn_lib =     vedgn_dir dir_>< 'lib/';
;;; lconstant vedgn_include = vedgn_dir dir_>< 'include/';

;;; Load and show from vedgn_ directory
extend_searchlist(vedgn_auto, popautolist) -> popautolist;
;;; extend_searchlist(vedgn_lib, popuseslist) -> popuseslist;
;;; extend_searchlist(vedgn_include, popincludelist) -> popincludelist;

;;; And extend ved's teach and help and ref lists
lconstant
	;;; vedgn_teach = [% vedgn_dir dir_>< 'teach/' % teach],
	vedgn_help = [% vedgn_dir dir_>< 'help/' % help],
	;;; vedgn_ref = [% vedgn_dir dir_>< 'ref/' % help],
	vedgn_teachlist = [^vedgn_help],
	vedgn_helplist = [^vedgn_help],
;;;	vedgn_reflist = [^vedgn_help],
;

extend_searchlist([^vedgn_help], vedhelplist) -> vedhelplist;
;;; extend_searchlist(vedgn_teachlist, vedteachlist) -> vedteachlist;
extend_searchlist(vedgn_helplist, vedteachlist,true) -> vedteachlist;
;;; extend_searchlist(vedgn_reflist, vedreflist) -> vedreflist;
;;; extend_searchlist(vedgn_helplist, vedreflist, true) -> vedreflist;

extend_searchlist(vedgn_dir, poppackagelist, true) -> poppackagelist;

;;; pop11_compile(vedgn_auto dir_>< 'ved_gn.p');

global constant vedgn = vedgn_dir;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 16 2005
		Changed name of library to vedgn
 */
