

section;

global constant vedutils;

unless isundef(vedutils) then [endsection;] -> proglist endunless;

;;; Default root dir for package is THIS directory
lconstant vedutils_dir = sys_fname_path(popfilename);

;;; delete or add directories as appropriate
lconstant
	;;; program files
	vedutils_auto =    vedutils_dir dir_>< 'auto/',
	vedutils_lib =     vedutils_dir dir_>< 'lib/',
	;;; vedutils_include = vedutils_dir dir_>< 'include/',
	;;; vedutils_data =    vedutils_dir dir_>< 'data/',

;;; And extend ved's teach and help and ref lists
	vedutils_teach 	  = [% vedutils_dir dir_>< 'teach/' % teach],
	vedutils_help 	  = [% vedutils_dir dir_>< 'help/' % help],
	vedutils_ref 	  = [% vedutils_dir dir_>< 'ref/' % ref],
;;;	vedutils_doc 	  = [% vedutils_dir dir_>< 'doc/' % doc],

	vedutils_teachlist = [^vedutils_teach],
	vedutils_helplist  = [^vedutils_help],
	vedutils_reflist   = [^vedutils_ref],
;;;	vedutils_doclist   = [^vedutils_doc],
	;


;;; Load and show from vedutils_ directory
extend_searchlist(vedutils_auto, popautolist) -> popautolist;
extend_searchlist(vedutils_lib, popuseslist) -> popuseslist;
;;; extend_searchlist(vedutils_include, popincludelist) -> popincludelist;


extend_searchlist([^vedutils_help], vedhelplist) -> vedhelplist;
extend_searchlist(vedutils_teachlist, vedteachlist) -> vedteachlist;
extend_searchlist(vedutils_helplist, vedteachlist,true) -> vedteachlist;
;;; extend_searchlist(vedutils_reflist, vedreflist) -> vedreflist;
extend_searchlist(vedutils_helplist, vedreflist, true) -> vedreflist;

extend_searchlist(vedutils_dir, poppackagelist, true) -> poppackagelist;

global constant vedutils = vedutils_dir;
endsection;
