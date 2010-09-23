/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 > File:            $poplocal/local/lib/newmaster/utils.p
 > Purpose:         Global variables and utility procedures for NEWMASTER
 > Author:          Rob Duncan, Jan 18 1989 (see revisions)
 > Documentation:   HELP * NEWMASTER
 > Related Files:   LIB * NEWMASTER
 */

section $-newmaster;

constant

	;;; Newmaster identifier (shouldn't appear as a literal in the file)
	NEWMASTER			= '@' <> 'NEWMASTER' <> '@',

	;;; Newmaster files
	LOG					= 'install/LOG',
	VERSION				= 'install/VERSION',

	;;; Header and footer components
	LineMark			= '---\s',
	Copyright			= LineMark <> 'Copyright',
	DocMarkTop			= '\Gtl\G-\Gtr\s',
	DocMarkBot			= '\Gbl\G-\Gbr\s',
	;;; DocCopyright		= DocMarkBot <> 'Copyright',
	DocCopyright		= LineMark <> 'Copyright',
	;;; OldCopyright		= 'Copyright University of Sussex',
	OldCopyright		= 'Copyright University of Birmingham',
	AllRightsReserved	= 'All rights reserved.',
	OldHeader			= 'University of Birmingham POPLOG file',
	;;; OldHeader			= 'University of Sussex POPLOG file',
	RevisionHistory		= 'Revision History',
	SeeRevisions		= '(see revisions)',

	;;; Prompt strings
	FilePrompt			= 'File:',
	RevisionPrompt		= 'Revision:',
	PurposePrompt		= 'Purpose:',
	AuthorPrompt		= 'Author:',
	DocumentationPrompt	= 'Documentation:',
	RelatedPrompt		= 'Related Files:',

	;;; Version information
	PopVersionFile		= 'C.all/src/initial.p',
	PopVersionId		= 'pop_internal_version',

;

vars procedure
	option,		;;; forward
;


;;; -- Error Procedure ----------------------------------------------------

define newmaster_error(action, msg);
	lvars	action, msg, args = [];
	dlocal	pop_pr_quotes = false, pr = sys_syspr;
	if islist(msg) then
		;;; optional argument list
		((), action, msg) -> (action, msg, args);
	endif;
	if action then
		action :: (msg :: args) -> args;
		'Cannot %p: %s' -> msg;
	else
		copy(msg) -> msg;
		lowertoupper(msg(1)) -> msg(1);
	endif;
	vederror(sprintf(msg, args));
enddefine;


;;; -- String Utilities ---------------------------------------------------

;;; locspace, skipspace:
;;;     find the first (non-) space character in a string

define locspace(i, s) -> i;
	lvars i, s, c;
	for i from i to datalength(s) do
		returnif((subscrs(i, s) ->> c) == ` ` or c == `\t`);
	endfor;
enddefine;

define skipspace(i, s) -> i;
	lvars i, s, c;
	for i from i to datalength(s) do
		returnif((subscrs(i, s) ->> c) /== ` ` and c /== `\t`);
	endfor;
enddefine;

;;; rmspace:
;;;		remove spaces from a string

define rmspace(s);
	lvars s;
	consstring(#|
		appdata(s,
			procedure(c);
				lvars c;
				unless c == ` ` or c == `\t` then c endunless;
			endprocedure);
	|#);
enddefine;

;;; trailer:
;;;		add trailing dashes to a heading up to 72 characters

define lconstant trailer(n) -> n;
	lvars n;
	if n < 72 then
		`\s`, repeat 71 - n times `-` endrepeat;
		72 -> n;
	endif;
enddefine;


;;; -- Headers and Footers in Files ---------------------------------------

;;; the_year:
;;;		returns the year as a string

define the_year();
	lvars date = sysdaytime();
	substring(datalength(date) - 3, 4, date);
enddefine;

;;; the_date:
;;;		returns a short form of the date as a string

define the_date();
	lvars date = sysdaytime();
	substring(5, 7, date) <> substring(datalength(date) - 3, 4, date);
enddefine;

;;; the_user:
;;;		the user's full name

define the_user() -> name;
	lvars name, user = option("user") or popusername;
	unless sysgetusername(user) ->> name then
		newmaster_error(false, 'Unknown user: %p', [^user]);
	endunless;
enddefine;

;;; copyright_line:
;;;		returns the copyright string

define copyright_line();
	consstring(trailer(#|
    	explode(Copyright), `\s`;
	    explode(newmaster_copyright), `\s`;
		explode(the_year()), `.`, `\s`;
	    explode(AllRightsReserved);
	|#));
enddefine;

;;; old_header_line:
;;;		returns the old-style header line
;;;		(should be replaced with the copyright line)

define old_header_line();
#_<	consstring(trailer(#|
		explode(LineMark);
		explode(OldHeader);
	|#));
>_#;
enddefine;

;;; footer_line:
;;;		returns the revision history line

define footer_line();
#_<	consstring(trailer(#|
		explode(LineMark);
		explode(RevisionHistory);
	|#));
>_#;
enddefine;

;;; searchfor:
;;;		simplified interface to -vedtestsearch- with appropriate dlocals

define searchfor(s);
	lvars	s;
	dlocal	vvedanywhere, vvedoldsrchdisplay, vvedsrchstring, vvedsrchsize;
	vedtestsearch(s, false);
enddefine;

;;; searchfor_prompt:
;;;     searches for the next occurrence of a prompt in the file.
;;;		It must be present.

define searchfor_prompt(s);
	lvars s;
	unless searchfor(s) then
		newmaster_error(false, 'Missing \'%p\' field in source file header',
			[^s]);
	endunless;
enddefine;

;;; is_copyright_line:
;;;		tests whether a string could have been returned by -copyright_line-:
;;;		can't use just "=", because the -newmaster_copyright- and the year
;;;		may be different

define is_copyright_line(s);
	lvars i, s;
	;;; starts with Copyright or DocCopyright
	(issubstring(Copyright, s) or issubstring(DocCopyright, s) ->> i)
	;;; and ends with AllRightsReserved ...
	and (issubstring(AllRightsReserved, datalength(Copyright)+i, s) ->> i)
	;;; ... possibly followed by trailing dashes
	and not(skipchar(`-`, skipspace(i+datalength(AllRightsReserved), s), s));
enddefine;

;;; comment_style:
;;;		returns a "comment style" appropriate to the current file. This
;;;		is a vector of the form: {^intro ^opener ^closer}.

define comment_style(must);
	lvars must, entry, style = option("comment") or sysfiletype(vedcurrent);
	for entry in newmaster_comments do
		if entry(1) = style then
			if length(entry) == 2 then
				;;; end-of-line comment
				{% entry(2), entry(2), nullstring %};
			elseif length(entry) == 3 then
				;;; opener and closer only
				{% nullstring, entry(2), entry(3) %};
			else
				;;; full set
				{% entry(4), entry(2), entry(3) %};
			endif;
			return;
		endif;
	endfor;
	if must then
		newmaster_error(false, 'Unknown comment style: %p', [^style]);
	endif;
	false;
enddefine;

;;; is_doc_file:
;;;     looks for a document file footer in the current file and if found
;;;     returns the file name from it

define is_doc_file() -> filename;
	lvars   i, j, line, filename = false;
	dlocal  vedline, vedcolumn, vvedlinesize;
	vedendfile();
	;;; there must be at least two lines
	returnif(vedline <= 2);
	;;; the bottom line must be a copyright line
	vedcharup();
	returnunless(is_copyright_line(vedthisline()));
	;;; the line above should be: --- filename or --- filename
	;;; (possibly with dashes at the end if in old format)
	vedcharup();
	vedthisline() -> line;
	returnunless(isstartstring(LineMark, line)
					or isstartstring(DocMarkTop, line));
	;;; locate what should be the file name
	locspace(skipspace(datalength(LineMark), line) ->> i, line) -> j;
	returnif(i == j or skipchar(`-`, skipspace(j, line), line));
	;;; looks like a doc file:
	;;; get the filename, checking that trailing dashes haven't been appended
	substring(i, j-i, line) -> filename;
	if last(filename) == `-` then
		newmaster_error(false, 'Bad filename in document file footer');
	endif;
enddefine;

;;; is_src_file:
;;;     looks for a source file header in the current file and if found
;;;     returns the file name from it

define is_src_file() -> filename;
	lvars   i, j, line, prefix, comment, filename = false;
	dlocal  vedline, vedcolumn, vvedlinesize;
	;;; can't deduce anything if there's no comment style known
	returnunless(comment_style(false) ->> comment);
	;;; search for the first line of the file header:
	;;; should be a copyright line or an old header line
	;;; and should be preceded only by blank lines or comment lines
	vedtopfile();
	repeat
		returnif(vedline >= vvedbuffersize);
		vedthisline() -> line;
		returnif(vvedlinesize > 0 and not(isstartstring(comment(2), line)));
		quitif(is_copyright_line(line) or issubstring(old_header_line(),line));
		vedchardown();
	endrepeat;
	;;; next line must contain the file prompt
	vedchardown();
	vedthisline() -> line;
	returnunless(issubstring(FilePrompt, line) ->> i);
	;;; file prompt should be followed by the author prompt and have the
	;;; same prompt prefix
	rmspace(substring(1, i-1, line)) -> prefix;
	searchfor_prompt(AuthorPrompt);
	returnunless(rmspace(substring(1, vedcolumn-1, vedthisline())) = prefix);
	;;; extract the file name from after the file prompt
	locspace(skipspace(locspace(i, line), line) ->> i, line) -> j;
	if i == j then
		newmaster_error(false, 'Missing filename in source file header');
	elseif skipspace(j, line) <= datalength(line) then
		newmaster_error(false, 'Bad filename in source file header');
	endif;
	substring(i, j-i, line) -> filename;
	;;; give a warning if the prompt prefix is not the comment string
	if prefix /= rmspace(comment(1)) then
		vedputmessage('File header has non-standard comments');
	endif;
enddefine;

;;; changed_header:
;;;		records whether a file has had its header or footer changed
;;;		(property indexed by -vedpathname-)

define changed_header =
	newproperty([], 10, false, "tmparg");
enddefine;


;;; -- Master Version Records ---------------------------------------------

;;; A master version is a list of six components:
;;;		[^name
;;;			^host-machine
;;;			^type
;;;			^root-directory
;;;			^test-directory
;;;			^com-directory]

define lconstant version_sub(version, i);
	lvars version, i;
	version(i);
enddefine;

define version_name	= version_sub(% 1 %) enddefine;
define version_host	= version_sub(% 2 %) enddefine;
define version_type	= version_sub(% 3 %) enddefine;
define version_root	= version_sub(% 4 %) enddefine;
define version_test = version_sub(% 5 %) enddefine;
define version_com	= version_sub(% 6 %) enddefine;

define check_version_root(action, version) -> rootdir;
	lvars action, version, rootdir;
	sysfileok(version_root(version) dir_>< nullstring) -> rootdir;
	;;; check that the root directory is accessible
	unless sysisdirectory(rootdir) then
		newmaster_error(action, 'no access to master tree %p',
			[% version_root(version) %]);
	endunless;
enddefine;

define check_version_command(action, version) -> cmd;
	lvars action, version, name, cmd;
	action sys_>< 'master' -> name;
	sysfileok(version_com(version)) dir_>< name -> cmd;
	unless readable(cmd) then
		newmaster_error(action, 'no access to %p command', [^name]);
	endunless;
enddefine;

define check_version_log(action, version) -> logfile;
	lvars action, version, logfile;

    define lconstant iswriteable(file);
        lvars file;
        sysobey('(cat < /dev/null >> ' <> file <> ')>&/dev/null', `%`,
#_IF pop_internal_version >= 140500
			false);
#_ELSE
			);
#_ENDIF
        pop_status == 0;
    enddefine;

    sysfileok(version_root(version) dir_>< LOG) -> logfile;
    ;;; check that the LOG file exists and is writeable
    unless readable(logfile) then
        newmaster_error(action, 'no access to LOG file');
    elseunless iswriteable(logfile) then
        newmaster_error(action, 'cannot write to LOG file');
    endunless;
enddefine;

;;; pathname_search:
;;;		search a list of versions for one containing the given file

define pathname_search(name, versions);
	lvars root, version, name, versions;
	sysfileok(name) -> name;
	for version in versions do
		sysfileok(version_root(version) dir_>< nullstring) -> root;
		returnif(isstartstring(root, name))(version);
	endfor;
	false;
enddefine;

;;; vername_search:
;;;		search a list of versions for one with the given name.
;;;		It must exist.

define vername_search(name, versions);
	lvars version, name, versions;
	for version in versions do
		returnif(version_name(version) = name)(version);
	endfor;
	newmaster_error(false, 'No such master version: "%p"', [^name]);
enddefine;

;;; locate_file:
;;;		find the master version corresponding to a given file name.

define locate_file(action, name) -> (name, version);
	lvars action, name, version, i, root;
	if name = '.' then
		;;; get name from current file
		if option("name") and option("name") /= name then
			option("name") -> name;
		elseif not(is_src_file() ->> name) and not(is_doc_file() ->> name)
		then
			newmaster_error(action, 'no filename');
		endif;
	endif;
	sysfileok(name) -> name;
	if isstartstring('/', name) then
		;;; absolute path name:
		;;; find the corresponding master version
		pathname_search(name, newmaster_versions)
	else
		;;; relative to selected version
		vername_search(option("version") or 'default', newmaster_versions)
	endif -> version;
	if option("version")
	and (not(version) or version_name(version) /= option("version"))
	then
		;;; selected version doesn't match the one found
		newmaster_error(action, 'file not in master version "%p"',
			[% option("version") %]);
	endif;
	if version then
		;;; make name relative to the version root
		sysfileok(version_root(version) dir_>< nullstring) -> root;
		if isstartstring(root, name) then
			allbutfirst(datalength(root), name) -> name;
		endif;
	endif;
enddefine;

;;; file_version:
;;;		associates a master version with a file

define lconstant file_version_table =
	newproperty([], 10, false, false);
enddefine;

define file_version(name) -> version;
	lvars name, version;
	unless file_version_table(name) ->> version then
		unless pathname_search(name, newmaster_versions) ->> version then
			vername_search('default', newmaster_versions) -> version;
		endunless;
	endunless;
enddefine;

define updaterof file_version(version, name);
	lvars version, name;
	version -> file_version_table(name);
enddefine;


;;; -- File Locking -------------------------------------------------------

;;; lockfile:
;;;		lock a file before editing or deleting it

define lockfile(action, file) -> lock;
	lvars	action, file, lock, key, comment = 'newmaster';
	dlocal	pop_pr_quotes = false;
	if isword(file) then
		;;; optional key
		((), action, file) -> (action, file, key);
	else
		consword(popusername) -> key;
	endif;
	if action then
		sprintf('%P %P', [^comment ^action]) -> comment;
	endif;
    unless valof("trylockfile")(file, key, comment) ->> lock then
		newmaster_error(
			action,
			if key == "newmaster" then 'LOG %s' else '%s' endif,
	        [%	if valof("lockkey_of")(file) ->> key then
    				'file locked by %p', key
	        	else
		        	'file lock error'
	        	endif
			%]);
	endunless;
enddefine;

define unlockfile(file);
	lvars file, key;
	if isword(file) then
		;;; optional key
		((), file) -> (file, key);
	else
		consword(popusername) -> key;
	endif;
	valof("tryunlockfile")(file, key) -> ;
enddefine;

;;; locklog:
;;;		lock the log file before an installation or deletion

define locklog(action, logfile) -> lock;
	lvars action, logfile, lock;
	lockfile(action, logfile, "newmaster") -> lock;
	if isstring(lock) and isstartstring('newmaster', lock) then
        newmaster_error(action,
			if lock = 'newmaster mark' then
				'LOG file locked for marking'
			else
				'LOG file in use'
			endif);
	endif;
enddefine;

define unlocklog(logfile);
	lvars logfile;
	unlockfile(logfile, "newmaster");
enddefine;

;;; mark_log:
;;;		write a message on the LOG file (should be locked first)

define mark_log(mark, logfile);
	lvars	logfile, mark, date = sysdaytime();
	dlocal	pop_pr_quotes = false;
	sprintf('%P MARK \'%P\' %P %P\n', [^NEWMASTER ^mark ^popusername ^date])
		-> mark;
	sysopen(logfile, 1, false, `N`) -> logfile;
	sysseek(logfile, 0, 2);
	syswrite(logfile, mark, datalength(mark));
	sysclose(logfile);
enddefine;


;;; -- Poplog Version Number ----------------------------------------------

;;; set_version_number:
;;;		writes the internal version number of the given master version to
;;;		the VERSION file

define set_version_number(n, version);
	lvars	vfile, n, version;
	dlocal	pop_file_versions = 2;	;;; keep one backup
	sysfileok(version_root(version) dir_>< VERSION) -> vfile;
	syscreate(vfile, 1, "line") -> vfile;
	syswrite(vfile, n, datalength(n));
	syswrite(vfile, '\n', 1);
	sysclose(vfile);
	mark_log(PopVersionId <> '=' <> n, check_version_log("mark", version));
enddefine;

;;; get_version_number:
;;;		reads the internal version number of the given master version from
;;;		the VERSION file

define get_version_number(version) -> n;
	lconstant F_SIZE = 1, fvec = writeable initv(1), buff = writeable inits(7);
	lvars i, vfile, version, n = false;
	sysfileok(version_root(version) dir_>< VERSION) -> vfile;
	;;; VERSION file should contain just the 6-figure version number
	;;; plus newline
	if sys_file_stat(vfile, fvec)
	and fvec(F_SIZE) == 7
	and	(sysopen(vfile, 0, "line", `A`) ->> vfile)
	and sysread(vfile, buff, 7) == 7
	then
		for i to 6 do
			returnunless(isnumbercode(buff(i)));
		endfor;
		if buff(7) == `\n` then
			substring(1, 6, buff) -> n;
		endif;
	endif;
enddefine;

define check_version_number(action, version) -> n;
	lvars action, version, n;
	unless get_version_number(version) ->> n then
		newmaster_error(action, 'cannot read master version number');
	endunless;
enddefine;

;;; get_pop_internal_version:
;;;		reads the value of -pop_internal_version- from the current file

define get_pop_internal_version() -> n;
	lvars	i, j, lim, line, n = false;
	dlocal	vedline, vedcolumn, vvedlinesize;
	vedtopfile();
	if searchfor(PopVersionId) then
		vedthisline() -> line;
		skipspace(vedcolumn + datalength(PopVersionId), line) -> i;
		if issubstring_lim('=', i, i, false, line) then
			skipspace(i+1, line) ->> i -> j;
			locspace(i, line) -> lim;
			while j < lim and isnumbercode(line(j)) do
				j + 1 -> j;
			endwhile;
			;;; version number is 6 digits
			if j - i == 6 then
				substring(i, 6, line) -> n;
			endif;
		endif;
	endif;
enddefine;


;;; -- Miscellaneous ------------------------------------------------------

;;; confirm_action:
;;;		prompts for a Y/N answer

define confirm_action(msg);
	lvars msg, c;
	repeat
        vedscreenbell();
        vedputmessage(msg <> '? (y/n)');
        vedinascii() -> c;
        quitif(strmember(c, 'yYnN'));
    endrepeat;
    vedputmessage(nullstring);
	lowertoupper(c) == `Y`;
enddefine;


endsection;		/* $-newmaster */


/* --- Revision History ---------------------------------------------------
--- John Gibson, Feb  6 1993
		Changed is_doc_file to recognise new-style footer, etc.
--- Robert John Duncan, Sep  1 1992
		Added dlocal of pop_pr_quotes at appropriate points.
--- Robert John Duncan, Mar 16 1992
		Major reorganisation.
--- Robert John Duncan, Dec 10 1990
		Changed content and format of versions.
		Factored out common routines from -install- & -delete- functions.
		Added -option_delete- and -newmaster-error-.
--- Rob Duncan, Jun  6 1990
		Added -locate_file- which maps a pathname to a master version.
		Changed -master_version- to -file_version- and made it look at the
		current location of the file if there's no version explicitly
		recorded for it.
 */
