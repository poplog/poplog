/* --- Copyright University of Birmingham 2005. All rights reserved. ------
 > File:			$usepop/pop/packages/vedmail/vedmail.p
 > Purpose:			Provide Mail sending, receiving, manipulating facilities in Ved
 > Author:			Aaron Sloman, Jan 12 2005
 > Documentation:	HELP ved_send, ved_reply, ved_mdir
 > Related Files:
 */

section;

global constant vedmail;
unless isundef(vedmail) then [endsection;] -> proglist endunless;

;;; Default root dir for package is THIS directory
lconstant
	vedmail_dir = sys_fname_path(popfilename);

;;; delete or add directories as appropriate
lconstant
	;;; program files
	vedmail_auto =    vedmail_dir dir_>< 'auto/',
	vedmail_lib =     vedmail_dir dir_>< 'lib/',
;;;	vedmail_include = vedmail_dir dir_>< 'include/',
;;;	vedmail_data =    vedmail_dir dir_>< 'data/'.

;;; And extend ved's teach and help and ref lists
	vedmail_teach 	  = [% vedmail_dir dir_>< 'teach/' % teach],
	vedmail_help 	  = [% vedmail_dir dir_>< 'help/' % help],
;;;	vedmail_ref 	  = [% vedmail_dir dir_>< 'ref/' % ref],
	vedmail_teachlist = [^vedmail_teach],
	vedmail_helplist  = [^vedmail_help],
;;;	vedmail_reflist   = [^vedmail_ref],
;;;	vedmail_doclist   = [^vedmail_doc],
	;


;;; Load and show from vedmail_ directory
extend_searchlist(vedmail_auto, popautolist) -> popautolist;
extend_searchlist(vedmail_lib, popuseslist) -> popuseslist;
;;; extend_searchlist(vedmail_include, popincludelist) -> popincludelist;


extend_searchlist([^vedmail_help], vedhelplist) -> vedhelplist;
extend_searchlist(vedmail_teachlist, vedteachlist) -> vedteachlist;
extend_searchlist(vedmail_helplist, vedteachlist,true) -> vedteachlist;
;;; extend_searchlist(vedmail_reflist, vedreflist) -> vedreflist;
;;; extend_searchlist(vedmail_helplist, vedreflist, true) -> vedreflist;

extend_searchlist(vedmail_dir, poppackagelist, true) -> poppackagelist;

global constant vedmail = vedmail_dir;
endsection;
