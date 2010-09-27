/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            $poplocal/local/auto/newmaster_utils.p
 > Purpose:         Global variables and utility procedures for NEWMASTER
 > Author:          Rob Duncan, Jan 18 1989 (see revisions)
 > Related Files:   LIB * VED_NEWMASTER
 */

compile_mode:pop11 +strict;

section $-newmaster;

;;; title:
;;;		surrounds a string with dashes sufficient to make up a 72-column
;;;		title string

define lconstant title(s);
	lvars s;
	`-`, `-`, `-`, ` `,
	explode(s),
	` `, fast_repeat 67 - datalength(s) times `-` endrepeat;
	consstring(72);
enddefine;

constant

	newmaster_section = current_section,

	;;; Newmaster identifier
	NEWMASTER = '@' <> 'NEWMASTER' <> '@',

	;;; Current year
	year = substring(datalength(sysdaytime()) - 3, 4, sysdaytime()),

	;;; Header and footer lines
	copyright		= 'Copyright University of Birmingham',
	;;; copyright		= 'The University of Birmingham',
	rights			= 'All rights reserved.',
	;;;rights			= '',
	copyright_line	= title(copyright <> ' ' <> year <> '. ' <> rights),
	;;; old_header_line	= title('University of Sussex POPLOG file'),
	old_header_line	= title('University of Birmingham POPLOG file'),
	footer_line		= title('Revision History'),
	see_revisions	= '(see revisions)',
	linemark		= '--- ',

	;;; Prompt strings

	file_prompt				= 'File:',
	purpose_prompt			= 'Purpose:',
	author_prompt			= 'Author:',
	documentation_prompt	= 'Documentation:',
	related_prompt			= 'Related Files:',
;

vars

	;;; Command line options
	option_comment,
	option_doc,
	option_local,
	option_lock,
	option_name,
	option_version,
	option_user,

;;; This lot not really needed
option_delete = false,
option_force = false,
option_get = false,
option_install = false,
option_recover = false,
option_recover_n = 1,
option_transport = false,

	realname,
	comment,
	start_comment,
	end_comment,
;

lvars _current_action = false;

define active current_action;
	_current_action;
enddefine;

define updaterof active current_action(action);
	lvars action;
	if action and _current_action and action /= _current_action then
		vederror('Incompatible actions: '
			<> _current_action <> ' & ' <> action);
	else
		action -> _current_action;
	endif;
enddefine;

define newmaster_error(msg);
	lvars msg;
	unless isstring(msg) then
		msg sys_>< nullstring -> msg;
	endunless;
	if msg = nullstring then
		'Newmaster error' -> msg;
	elseif isstring(current_action) then
        'Cannot ' <> current_action <> ': ' <> msg -> msg;
    else
		copy(msg) -> msg;
        lowertoupper(msg(1)) -> msg(1);
    endif;
	vederror(msg);
enddefine;

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

define check_version_root(version) -> rootdir;
	lvars version, rootdir;
	sysfileok(version_root(version) dir_>< nullstring) -> rootdir;
	;;; check that the root directory is accessible
	unless sysisdirectory(rootdir) then
		newmaster_error('no access to master tree ' <> version_root(version));
	endunless;
enddefine;

define check_version_command(version, name) -> cmd;
	lvars version, name, cmd;
	sysfileok(version_com(version)) dir_>< name -> cmd;
	unless readable(cmd) then
		newmaster_error('no access to ' <> lowertoupper(name) <> ' command');
	endunless;
enddefine;

define check_version_log(version) -> logfile;
	lvars version, logfile;

    define lconstant iswriteable(file);
        lvars file;
        sysobey('(cat < /dev/null >> ' <> file <> ')>&/dev/null', `%`);
        pop_status == 0;
    enddefine;

    sysfileok(version_root(version) dir_>< 'install/LOG') -> logfile;
    ;;; check that the LOG file exists and is writeable
    unless readable(logfile) then
        newmaster_error('no access to LOG file');
    elseunless iswriteable(logfile) then
        newmaster_error('cannot write to LOG file');
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
	vederror('no such master version: "' <> name <> '"');
enddefine;

;;; lockfile:
;;;		lock a file before editing or deleting it

define lockfile(file) -> lock;
	lvars file, lock, key, comment;
	consword(popusername) -> key;
	if current_action then
		'newmaster ' sys_>< current_action
	else
		'newmaster'
	endif -> comment;
    unless valof("trylockfile")(file, key, comment) ->> lock then
		newmaster_error(
	        if valof("lockkey_of")(file) ->> key then
    			'file locked by ' sys_>< key
	        else
		        'file lock error'
	        endif);
	endunless;
enddefine;

define unlockfile(file);
	lvars file;
	valof("tryunlockfile")(file, consword(popusername)) -> ;
enddefine;

;;; locklog:
;;;		lock the log file before an installation or deletion

define locklog(logfile) -> lock;
	lvars logfile, lock;
    valof("trylockfile")(logfile, "newmaster", 'newmaster LOG') -> lock;
	if isstring(lock) and isstartstring('newmaster', lock) then
        newmaster_error('LOG file in use');
	elseif lock /== true then
		newmaster_error('cannot lock the LOG file');
	endif;
enddefine;

define unlocklog(logfile);
	lvars logfile;
	valof("tryunlockfile")(logfile, "newmaster") -> ;
enddefine;

;;; locspace, skipspace:
;;;     find the first (non-) space character in a string

define constant locspace(i, s) -> i;
	lvars i, s, c;
	for i from i to datalength(s) do
		returnif((subscrs(i, s) ->> c) == ` ` or c == `\t`);
	endfor;
enddefine;

define constant skipspace(i, s) -> i;
	lvars i, s, c;
	for i from i to datalength(s) do
		returnif((subscrs(i, s) ->> c) /== ` ` and c /== `\t`);
	endfor;
enddefine;

;;; is_doc_file:
;;;     looks for a document file footer in the current file and if found
;;;     returns the file name from it

define constant is_doc_file() -> filename;
	lvars   i, j, line, filename = false;
	dlocal  vedline, vedcolumn, vvedlinesize;
	vedendfile();
	;;; there must be at least two lines
	unless vedline > 2 then return endunless;
	;;; the bottom line should begin: --- Copyright ...
	vedcharup();
	vedthisline() -> line;
	unless issubstring_lim(linemark, 1, 1, false, line)
	and issubstring_lim(copyright, skipspace(4, line) ->> i, i, false, line)
	then
		return
	endunless;
	;;; the line above should be: --- filename
	;;; (possibly with dashes at the end if in old format)
	vedcharup();
	vedthisline() -> line;
	unless issubstring_lim(linemark, 1, 1, false, line) then return endunless;
	;;; locate what should be the file name
	skipspace(4, line) -> i;
	locspace(i, line) -> j;
	if i == j or skipchar(`-`, skipspace(j, line), line) then return endif;
	;;; looks like a doc file:
	;;; get the filename, checking that trailing dashes haven't been appended
	substring(i, j-i, line) -> filename;
	if last(filename) == `-` then
		vederror('Bad filename in document file footer');
	endif;
enddefine;

;;; is_src_file:
;;;     looks for a source file header in the current file and if found
;;;     returns the file name from it

define constant is_src_file() -> filename;
	lvars   i, j, line, prefix, filename = false;
	dlocal  vedline, vedcolumn, vvedlinesize,
			vvedanywhere, vvedoldsrchdisplay, vvedsrchstring, vvedsrchsize;

	define lconstant rmspaces(s);
		lvars s;
		cons_with consstring {%
			appdata(s, procedure(c); lvars c;
				unless c == ` ` or c == `\t` then c endunless
			endprocedure)
		%};
	enddefine;

	;;; can't deduce anything if there's no comment style known
	unless comment then return endunless;
	;;; search for the first line of the file header:
	;;; should be a copyright line or an old header line
	;;; and should be preceded only by blank lines or comment lines
	vedtopfile();
	repeat
		if vedline >= vvedbuffersize then return endif;
		vedthisline() -> line;
		if vvedlinesize > 0
		and not(issubstring_lim(start_comment, 1, 1, false, line))
		then
			return;
		endif;
		if issubstring(copyright, 1, line)
		or issubstring(old_header_line, 1, line)
		then
			quitloop;
		endif;
		vedchardown();
	endrepeat;
	;;; next line must contain the file prompt
	vedchardown();
	vedthisline() -> line;
	unless issubstring(file_prompt, 1, line) ->> i then return endunless;
	;;; file prompt should be followed by the author prompt and have the
	;;; same prompt prefix
	rmspaces(substring(1, i-1, line)) -> prefix;
	unless vedtestsearch(author_prompt, false)
	and rmspaces(substring(1, vedcolumn-1, vedthisline())) = prefix
	then
		vederror('Missing \'Author:\' field in source file header');
	endunless;
	;;; extract the file name from after the file prompt
	skipspace(locspace(i, line), line) -> i;
	locspace(i, line) -> j;
	if i == j then
		vederror('Missing filename in source file header');
	elseif skipspace(j, line) <= datalength(line) then
		vederror('Bad filename in source file header');
	endif;
	substring(i, j-i, line) -> filename;
	;;; give a warning if the prompt prefix is not the comment string
	if prefix /= rmspaces(comment) then
		vedputmessage('File header has non-standard comments');
	endif;
enddefine;

define constant is_sh_file() -> boole;
	;;; Return true if first line starts with `#`
	lvars boole, line1 = subscrv(1,vedbuffer);
	datalength(line1) > 0 and subscrs(1, line1) == `#` -> boole
enddefine;
	

;;; locate_file:
;;;		find a master version corresponding to the given file name.

define locate_file(name) -> version -> name;
	lvars name, version, i, root;
	sysfileok(name) -> name;
	if isstartstring('/', name) then
		;;; absolute path name:
		;;; find the corresponding master version
		pathname_search(name, newmaster_versions)
	else
		;;; relative to selected version
		vername_search(option_version or 'default', newmaster_versions)
	endif -> version;
	if option_version
	and (not(version) or version_name(version) /= option_version)
	then
		;;; selected version doesn't match the one found
		vederror('file not in version "' <> option_version <> '"');
	endif;
	if version then
		;;; make name relative to the version root
		sysfileok(version_root(version) dir_>< nullstring) -> root;
		if isstartstring(root, name) then
			allbutfirst(datalength(root), name) -> name;
		endif;
	endif;
enddefine;

;;; changed_header:
;;;		(property indexed by -vedpathname-)
;;;		records whether a file has had its header or footer changed

constant procedure changed_header = newproperty([], 10, false, false);

;;; file_version:
;;;		associates a master version with a file

lconstant procedure file_version_table = newproperty([], 10, false, false);

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

endsection;		/* $-newmaster */

;;; newmaster_utils:
;;;		for USES

section;

global constant newmaster_utils = true;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Feb  6 1992
		Changed to use Birmingham instead of Sussex
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
