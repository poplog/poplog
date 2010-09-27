/* --- Copyright University of Birmingham 1993. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_browse.p
 > Purpose:         Get an index to online files, or access a file
 > Author:          Aaron Sloman, Feb 26 1993
 > Documentation:	HELP * VED_BROWSE
 > Related Files:	See cross references in HELP VED_BROWSE
 */


section;

;;; Global constants used below
;;; Standard directories for PML documentation and libraries
lconstant dir_lists =
	[
;;; ML
		[mlhelp [ '$poplocal/local/pml/help/' '$usepop/pop/pml/help/' ]]
		[mlteach [ '$poplocal/local/pml/teach/' '$usepop/pop/pml/teach/']]
		[mllib ['$poplocal/local/pml/lib/' '$usepop/pop/pml/lib/']]
		[mlsrc [ '$usepop/pop/pml/src/' ]]
;;; LISP		
		[lisphelp
			['$poplocal/local/lisp/help/' '$usepop/pop/lisp/help/' ]]
		[lispref ['$usepop/pop/lisp/ref/' ]]
		[lispsrc [ '$usepop/pop/lisp/src/' ]]
		[lispteach ['$poplocal/local/lisp/teach/']]
		[lisplib
			['$poplocal/local/lisp/modules/' '$usepop/pop/lisp/modules/']]
;;; PROLOG		
		[prologhelp
			['$poplocal/local/plog/help/' '$usepop/pop/plog/help/' ]]
		[prologteach
			['$poplocal/local/plog/teach/' '$usepop/pop/plog/teach/' ]]
		[prologlib
			[ '$poplocal/local/plog/lib/'
				'$poplocal/local/plog/auto/'
				'$usepop/pop/plog/lib/'
				'$usepop/pop/plog/auto/' ]]
		[prologsrc
			['$usepop/pop/plog/src/']]
;;; POP11
		[pop11teach vedteachlist]
		[pop11help vedhelplist]
		[pop11ref vedreflist]
		[pop11doc veddoclist]
		[pop11src vedsrclist]
		[pop11teach vedteachlist]
		[pop11auto popautolist]
		[pop11lib popuseslist]
		[pop11include popincludelist]
	]
	;

;;; Define a property mapping combination of language and category onto
;;; search list, or its name.

global constant browse_search_lists =
	newproperty(dir_lists, length(dir_lists), [], "perm");

;;; Some useful strings
lconstant
	browse_index_message =
		'BROWSE INDEX: put cursor on desired file name then press REDO',

	name_terminators = '\s\t';

;;; Menu strings, and corresonding vectors of names of languages or
;;; file categories

global vars
	browse_subsystem_menu =
		'0:current 1:pop11 2:prolog 3:lisp 4:ml',

	browse_subsystems =
		{current pop11 prolog lisp ml},

	browse_type_menu =
		'1:help 2:teach 3:ref 4:doc 5:lib 6:auto 7:src 8:include :',

	browse_types =
		{'help' 'teach' 'ref' 'doc' 'lib' 'auto' 'src' 'include'},
;


;;; get default command for running "ls" on library directories
#_IF sys_file_exists('/usr/5bin/ls')
	;;; Probably SunOS !

	global vars browse_ls_command = '/usr/5bin/ls -xL';

#_ELSEIF issubstring('hp', hd(sys_machine_type))
    ;;; Running HP-UX
	
	global vars browse_ls_command = '/bin/ls -xL';

#_ELSE
    ;;; Default for Unix systems

	global vars browse_ls_command = '/bin/ls -CL';

#_ENDIF


define lconstant getoption(menu_string, vector) -> char;
	;;; displayse menu options and returns the selection, based on
	;;; character typed by user.

	lvars char, menu_string, vector, len = datalength(vector);

	;;; show menu and wait for response
    repeat
		vedsetstatus(menu_string, false, true);
		vedwiggle(0,vedscreenwidth);
		vedscr_read_input() -> char;
		if isnumbercode(char) and (char - `0`) <= len then
			quitloop
		else
			vedscreenbell()
		endif
	endrepeat;
enddefine;


define lconstant thisname() -> name;
	;;; return file name under or to right of VED cursor
	;;; also move VED cursor to right of the name
	lvars char, name, startcol,
		col = vedcolumn,
		line = vedthisline();

	min(col, vvedlinesize) -> col;	;;; in case to right of text
	;;; find beginning of name by moving left to space or tab
	until col == 1
	or strmember(fast_subscrs(col, line), name_terminators)
	do
		col - 1 -> col;
	enduntil;

	;;; now get name to right of cursor
	;;; Move right past spaces and tabs to start of name
	until col > vvedlinesize
	or not(strmember(subscrs(col, line), name_terminators))
	do
		col + 1 -> col;
	enduntil;

	;;; record beginning of name
	col -> startcol;

	;;; find next space or tab character, ending file name
	until col > vvedlinesize
	or strmember(subscrs(col, line), name_terminators)
	do
		col + 1 -> col;
	enduntil;

	;;; now extract the name
	substring(startcol, col - startcol, line) -> name;
	;;; move cursor to end of name
	col -> vedcolumn;
enddefine;


define lconstant prune_dirs(doc_type, doc_dirs) -> doc_dirs;
	;;; return doc_dirs, minus those that don't include doc_type
	lvars dir, doc_type, doc_dirs, dirs;

	flatten_searchlist(recursive_valof(doc_dirs)) -> doc_dirs;

	unless member(doc_type, ['lib', 'auto']) then
		;;; remove dirs of different type, e.g. remove ref dirs
		;;; from help list
		[%
			for dir in doc_dirs do
				if issubstring(doc_type, dir) then dir endif
				endfor
		%] -> doc_dirs
	endunless;

	;;; now remove redundancies
	[%
		for dirs on doc_dirs do
			front(dirs) -> dir;
			unless member(dir, back(dirs)) then dir endunless
			endfor
	%] -> doc_dirs
enddefine;

define lconstant browse_get_file();
	;;; get file name that cursor is on or to left of in browse index file
	lvars filename,  language_and_type;

	vedbuffer(2) -> language_and_type;

	thisname() -> filename;

	;;; Now build up the help, teach, showlib or whatever command
	veddo(language_and_type sys_>< space sys_>< filename)
enddefine;

define lconstant browse_make_index();
	lvars
		char, dir, command, doc_type, subsystem_name,
		searchlist, doc_dirs,
		oldfile = vedcurrentfile;

	getoption(browse_subsystem_menu, browse_subsystems) -> char;

	subscrv(char - `0` + 1, browse_subsystems) -> subsystem_name;

	;;; deal with option 0
	if subsystem_name = "current" then subsystem -> subsystem_name endif;
	;;; in case current subsystem is prolog "top" level.
	if subsystem_name = "top" then "prolog" -> subsystem_name endif;

	;;; find documentation type
	getoption(browse_type_menu, browse_types) -> char;

	subscrv(char - `0`, browse_types) -> doc_type;

	;;; create the key for accessing the table - a compound word
    ;;; and use it to access the property
	browse_search_lists(consword(subsystem_name sys_>< doc_type)) -> doc_dirs;

	;;; flatten the list, get rid of duplicates, and remove extras
	prune_dirs(doc_type, doc_dirs) -> doc_dirs;

	if doc_dirs == [] then
		vederror('NO SEARCH LIST FOR ' >< subsystem_name >< space >< doc_type)
	endif;

	;;; build up a string to form the argument for veddo, of the form
	;;; sh <ls command> dir1 dir2 dir3 ... | expand -8
	;;; where expand is used to remove tabs.

    consstring
		(#| explode('sh '),		;;; for ENTER sh, to invoke vedgenshell
			explode(browse_ls_command),
			`\s`,
			for dir in doc_dirs do
				if sys_file_exists(dir) then explode(dir), `\s` endif
			endfor,
			explode(' | expand -8')
		|#) -> command;

	veddo(command);

	;;; That should have created lists of relevant files, in a
	;;; new VED buffer. Check.
	if oldfile == vedcurrentfile then vederror('NO FILES FOUND') endif;

	;;; suppress screen output till call of vedrefresh, below

	dlocal vedediting = false;
	vedtopfile();
	vedlineabove();
	0 -> vedlineoffset;

	;;; Insert instructions at top of file. (Also used to identify this
	;;; 	later as a browse index file)
	vedinsertstring(browse_index_message);

	;;; now record the language and documentation type
	vedlinebelow();
	vedinsertstring(
		if subsystem_name = "ml" then 'pml' else subsystem_name endif
		sys_>< space sys_><
	 	if member(doc_type, ['lib' 'auto']) then 'showlib' else doc_type
		endif);
	vedlinebelow();
	vedinsertstring('NB:- Do not alter previous two lines -:NB');

	;;; Now remove the line produced by vedgenshell, starting "sh"
	vednextline();
	if isstartstring('sh ', vedthisline()) then
		nullstring -> vedthisline()
	else
		vedlineabove();
	endif;

	if length(doc_dirs) > 1 then
		;;; Now prepare an index to directories, using ved_indexify
		veddo('gs;@a/;-- /;');
		veddo('indexify');
	else
		vedlinebelow();
		vedinsertstring(hd(doc_dirs))
	endif;
	vedtopfile(); vedtextright();
	vedputcommand('browse');
	chain(vedrefresh);
enddefine;

;;; Now the top level procedure

define global ved_browse();
	if vvedbuffersize > 2 and vedbuffer(1) = browse_index_message then
		;;; inside a "browse" index file. Get the name and find the file.
		browse_get_file();
	else
		;;; create a new index
		browse_make_index()
	endif
enddefine;
	
endsection;
