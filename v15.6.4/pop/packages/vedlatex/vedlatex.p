;;; renamed as vedlatex.p
;;; 19 Jan 2005

section;

global constant vedlatex;

unless isundef(vedlatex) then [endsection;] -> proglist endunless;

;;; Default root dir for package is THIS directory
lconstant vedlatex_dir = sys_fname_path(popfilename);

;;; delete or add directories as appropriate
lconstant
	;;; program files
	vedlatex_auto =    vedlatex_dir dir_>< 'auto/',
	vedlatex_lib =     vedlatex_dir dir_>< 'lib/',
	;;; vedlatex_include = vedlatex_dir dir_>< 'include/',
	;;; vedlatex_data =    vedlatex_dir dir_>< 'data/'.

;;; And extend ved's teach and help and ref lists
	vedlatex_teach 	  = [% vedlatex_dir dir_>< 'teach/' % teach],
	vedlatex_help 	  = [% vedlatex_dir dir_>< 'help/' % help],
	;;; vedlatex_ref 	  = [% vedlatex_dir dir_>< 'ref/' % ref],
	vedlatex_teachlist = [^vedlatex_teach],
	vedlatex_helplist  = [^vedlatex_help],
	;;; vedlatex_reflist   = [^vedlatex_ref],
	;;; vedlatex_doclist   = [^vedlatex_doc],
	;


;;; Load and show from vedlatex_ directory
extend_searchlist(vedlatex_auto, popautolist) -> popautolist;
extend_searchlist(vedlatex_lib, popuseslist) -> popuseslist;
;;; extend_searchlist(vedlatex_include, popincludelist) -> popincludelist;


extend_searchlist([^vedlatex_help], vedhelplist) -> vedhelplist;
extend_searchlist(vedlatex_teachlist, vedteachlist) -> vedteachlist;
extend_searchlist(vedlatex_helplist, vedteachlist,true) -> vedteachlist;
;;; extend_searchlist(vedlatex_reflist, vedreflist) -> vedreflist;
extend_searchlist(vedlatex_helplist, vedreflist, true) -> vedreflist;

extend_searchlist(vedlatex_dir, poppackagelist, true) -> poppackagelist;

global constant vedlatex = vedlatex_dir;

endsection;
