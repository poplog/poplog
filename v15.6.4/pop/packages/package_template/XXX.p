

section;

global constant XXX;

unless isundef(XXX) then [endsection;] -> proglist endunless;

;;; Default root dir for package is THIS directory
lconstant XXX_dir = sys_fname_path(popfilename);

;;; delete or add directories as appropriate
lconstant
	;;; program files
	XXX_auto =    XXX_dir dir_>< 'auto/',
	XXX_lib =     XXX_dir dir_>< 'lib/',
	XXX_include = XXX_dir dir_>< 'include/',
	XXX_data =    XXX_dir dir_>< 'data/'.

;;; And extend ved's teach and help and ref lists
	XXX_teach 	  = [% XXX_dir dir_>< 'teach/' % teach],
	XXX_help 	  = [% XXX_dir dir_>< 'help/' % help],
	XXX_ref 	  = [% XXX_dir dir_>< 'ref/' % ref],
	XXX_doc 	  = [% XXX_dir dir_>< 'doc/' % doc],

	XXX_teachlist = [^XXX_teach],
	XXX_helplist  = [^XXX_help],
	XXX_reflist   = [^XXX_ref],
	XXX_doclist   = [^XXX_doc],
	;


;;; Load and show from XXX_ directory
extend_searchlist(XXX_auto, popautolist) -> popautolist;
extend_searchlist(XXX_lib, popuseslist) -> popuseslist;
extend_searchlist(XXX_include, popincludelist) -> popincludelist;


extend_searchlist([^XXX_help], vedhelplist) -> vedhelplist;
extend_searchlist(XXX_teachlist, vedteachlist) -> vedteachlist;
extend_searchlist(XXX_helplist, vedteachlist,true) -> vedteachlist;
;;; extend_searchlist(XXX_reflist, vedreflist) -> vedreflist;
extend_searchlist(XXX_helplist, vedreflist, true) -> vedreflist;

extend_searchlist(XXX_dir, poppackagelist, true) -> poppackagelist;

global constant XXX = true;
endsection;
