

section;

global constant bhamlib;

unless isundef(bhamlib) then [endsection;] -> proglist endunless;

;;; Default root dir for package is THIS directory
lconstant bhamlib_dir = sys_fname_path(popfilename);

;;; delete or add directories as appropriate
lconstant
	;;; program files
	bhamlib_auto =    bhamlib_dir dir_>< 'auto/',
	bhamlib_lib =     bhamlib_dir dir_>< 'lib/',
	;;; bhamlib_include = bhamlib_dir dir_>< 'include/',
	;;; bhamlib_data =    bhamlib_dir dir_>< 'data/'.

;;; And extend ved's teach and help and ref lists
	bhamlib_teach 	  = [% bhamlib_dir dir_>< 'teach/' % teach],
	bhamlib_help 	  = [% bhamlib_dir dir_>< 'help/' % help],
	bhamlib_ref 	  = [% bhamlib_dir dir_>< 'ref/' % ref],
;;;	bhamlib_doc 	  = [% bhamlib_dir dir_>< 'doc/' % doc],

	bhamlib_teachlist = [^bhamlib_teach],
	bhamlib_helplist  = [^bhamlib_help],
	bhamlib_reflist   = [^bhamlib_ref],
;;;	bhamlib_doclist   = [^bhamlib_doc],
	;


;;; Load and show from bhamlib_ directory
extend_searchlist(bhamlib_auto, popautolist) -> popautolist;
extend_searchlist(bhamlib_lib, popuseslist) -> popuseslist;
;;; extend_searchlist(bhamlib_include, popincludelist) -> popincludelist;


extend_searchlist([^bhamlib_help], vedhelplist) -> vedhelplist;
extend_searchlist(bhamlib_teachlist, vedteachlist) -> vedteachlist;
extend_searchlist(bhamlib_helplist, vedteachlist,true) -> vedteachlist;
;;; extend_searchlist(bhamlib_reflist, vedreflist) -> vedreflist;
extend_searchlist(bhamlib_helplist, vedreflist, true) -> vedreflist;
extend_searchlist(bhamlib_dir, poppackagelist, true) -> poppackagelist;

global constant bhamlib = bhamlib_dir;
endsection;
