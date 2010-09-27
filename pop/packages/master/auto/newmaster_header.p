/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/sussex/master/auto/newmaster_header.p
 > Purpose:         As below
 > Author:          Aaron Sloman, Jul 24 2002 (see revisions)
 > Documentation:	As below
 > Related Files:
 */

/* --- Copyright University of Sussex 1993.  All rights reserved. ---------
 > File:           $poplocal/local/auto/newmaster_header.p
 > Purpose:        Inserts headers and footers for VED_NEWMASTER
 > Author:         Robert Duncan and Simon Nichols, Jun  1 1987 (see revisions)
 > Documentation:  HELP * NEWMASTER
 > Related Files:  LIB * VED_NEWMASTER
 */

compile_mode:pop11 +strict;

uses ved_newmaster;

vedputmessage('Please wait');

section $-newmaster;

;;; revision_date:
;;;     returns the date as a string in the form: Month Day Year

define lconstant revision_date();
	lvars date = sysdaytime();
	substring(5, 7, date) <> allbutfirst(datalength(date)-4, date);
enddefine;

;;; find_prompt:
;;;     finds the first occurrence of -prompt- in the file.
;;;     It's an error for it not to be present.

define lconstant find_prompt(prompt);
	lvars   prompt;
	dlocal  vvedanywhere, vvedoldsrchdisplay, vvedsrchstring, vvedsrchsize;
	vedtopfile();
	unless vedtestsearch(prompt, false) then
		newmaster_error('missing "' <> prompt <> '" field in header');
	endunless;
enddefine;

;;; header_name:
;;;		deduce a name to go in the header (or footer) of a file
;;;		either from the "name" option
;;;		or from the pathname of the current ved buffer.

define lconstant header_name() -> name;
	lvars version, name, i;
	if option_name then
		locate_file(option_name) -> version -> name;
	else
		procedure;
			dlocal option_version = false;	;;; suppress version errors
			locate_file(vedpathname)
		endprocedure() -> version -> name;
		unless version then
		    locate_file(
			    if (issubstring('C.', 1, vedpathname) ->> i)
		        or (issubstring('S.', 1, vedpathname) ->> i)
		        then
			        allbutfirst(i-1, vedpathname)
			    else
				    '$poplocal/local/????/' dir_>< sys_fname_name(vedpathname)
			    endif) -> version -> name;
		endunless;
	endif;
	if version and version_type(version) /= 'master' then
		;;; header name should be absolute
		version_root(version) dir_>< name -> name;
	endif;
enddefine;

;;; make_src_header:
;;;     inserts a new, partially filled header into a program file.

define lconstant make_src_header();
	lconstant indent_column = 21;
	lvars name = header_name(), author = realname <> ', ' <> revision_date();

	define lconstant insert_prompt(arg);
		lvars arg;
		vedlinebelow();
		vedinsertstring(comment);
		vedcharright();
		vedinsertstring(destpair(arg) -> arg);
		unless arg == [] then
			vedjumpto(vedline, indent_column);
			vedinsertstring(front(arg));
		endunless;
	enddefine;

	vedtopfile();
	vedlineabove();
	vedinsertstring(start_comment);
	vedcharright();
	vedinsertstring(copyright_line);

	[%
		[^file_prompt ^name],
		[^purpose_prompt],
		[^author_prompt ^author],
		[^documentation_prompt],
		[^related_prompt]
	%],
	applist(insert_prompt);
	vedlinebelow();
	unless end_comment = nullstring then
		vedinsertstring(end_comment);
		vedlinebelow();
	endunless;
	vedtopfile(); vedcheck();     ;;; make sure top is visible.
	find_prompt(purpose_prompt);
	vedjumpto(vedline, indent_column);
enddefine;

;;; make_src_footer:
;;;     inserts a skeleton for revision notes into a program file.

define lconstant make_src_footer();
	vedendfile();
	vedlinebelow();
	vedinsertstring(start_comment <> ' ' <> footer_line);
	unless end_comment = nullstring then
		vedlinebelow();
		vedinsertstring(end_comment);
		vedcharup();
	endunless;
enddefine;

;;; make_doc_footer:
;;;     inserts the copyright notice and filename into a document file,
;;;     leaving the cursor on the first character of the filename.

define lconstant make_doc_footer();
	lvars path = header_name();

	define lconstant insert_string(string, attr);
		lvars string, attr;
		;;; disabled by A.Sloman for the sake of portability
		;;; dlocal vedcharinsert_attr = attr;
		vedinsertstring(string)
	enddefine;

	vedlineabove();
	;;;vedinsertstring(doc_mark_2); insert_string(copyright_note, `\[i]`);
	vedinsertstring(copyright_line);
	vedlineabove();
	;;;vedinsertstring(doc_mark_1); insert_string(path, `\[bi]`);
	vedinsertstring(linemark); vedinsertstring(path);
	vedjumpto(vedline, 5); vedcheck();
enddefine;

;;; make_sh_footer:
;;;     inserts the copyright notice and filename into a shell file,
;;;     leaving the cursor on the first character of the filename.

define lconstant make_sh_header();
	lvars path = header_name();
	vedinsertstring('### ');
	vedinsertstring(copyright_line);
	vedlinebelow();
	vedinsertstring('### ');
	vedinsertstring(path);
	vedjumpto(vedline, 5); vedcheck();
enddefine;


;;; update_copyright:
;;;		checks that the copyright notice on the file is up to date

define lconstant update_copyright();
	lvars	yr, n, line;
	dlocal	vedline, vedcolumn, vvedlinesize, vedstatic,
			vvedanywhere, vvedoldsrchdisplay, vvedsrchstring, vvedsrchsize;
	;;; locate the copyright line
	returnunless(vedtestsearch(copyright, false));
	;;; extract the year field and quit if it's already up to date
	repeat datalength(copyright) times vedcharright() endrepeat;
	vedthisline() -> line;
	skipspace(vedcolumn, line) -> n;
	returnunless(datalength(line) >= n + 3);
	substring(n, 4, line) -> yr;
	returnif(yr = year);
	;;; check that we've really found a date before replacing it
	strnumber(yr) -> n;
	returnunless(n and 1960 < n and n <= 2060);
	;;; replace the field with the current year
	vedlocate(yr);
	true -> vedstatic;
	vedinsertstring(year);
enddefine;

;;; newmaster_header:
;;;     inserts a header or footer into a file as appropriate.

define constant newmaster_header();
	dlocal	vedleftmargin = 0, vedbreak = false,
			vvedanywhere, vvedoldsrchdisplay, vvedsrchstring, vvedsrchsize;
	if is_doc_file() then
		update_copyright();
		vedputmessage(vednullstring);
	elseif is_sh_file() then
		vedtopfile();
		unless vvedbuffersize == 1 then
			vedchardown();
			if issubstring(copyright, 1, vedthisline()) then
				vedlinedelete();
			else
				vedlineabove();
			endif;
		endunless;
		make_sh_header();
		vedputmessage(vednullstring);
	elseif option_doc then
		vedendfile();
		unless vedline == 1 then
			vedcharup();
			if issubstring(copyright, 1, vedthisline()) then
				vedlinedelete();
			else
				vedchardown(); vedlinebelow();
			endif;
		endunless;
		make_doc_footer();
		vedputmessage(vednullstring);
	elseif is_src_file() then
		vedtopfile();
		if vedtestsearch(old_header_line, false) then
			vedcleartail();
			vedinsertstring(copyright_line);
		else
			update_copyright();
		endif;
		find_prompt(file_prompt);
		if issubstring('$usepop/master/', 1, vedthisline()) then
			;;; Old-style filename; remove '$usepop/master/' prefix
			vedlocate('$usepop/master/');
			repeat 15 times veddotdelete() endrepeat;
		endif;
		find_prompt(author_prompt);
		unless issubstring(see_revisions, 1, vedthisline()) then
			;;; 'Author' field exists, but without 'see revisions'
			vedtextright(); vedcharright();
			vedinsertstring(see_revisions);
		endunless;
		unless vedtestsearch(footer_line, false) then
			make_src_footer();
		endunless;
		vedlinebelow();
		if end_comment = nullstring then
			;;; Insert end-of-line type comment
			vedinsertstring(comment <> ' ')
		endif;
		vedinsertstring(linemark <> realname <> ', ' <> revision_date() <> ' ');
	else
		unless comment then
			newmaster_error('unknown comment style: ' <> option_comment);
		endunless;
		make_src_header();
		vedputmessage(vednullstring);
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 24 2002
		Re-installed old style doc_footers, for portability
--- John Gibson, Feb  6 1993
		Changed make_doc_footer to make new-style footer
--- Robert John Duncan, Dec 10 1990
		Changed to use -newmaster_error-
--- Rob Duncan, Jun  6 1990
		Changed to use the new -locate_file- mechanism.
--- Rob Duncan, Feb 20 1989
		Added check for known comment style before calling -make_src_header-
--- John Williams, Dec  2 1988
		Added 'local' and 'transport' options
--- Rob Duncan, Sep 12 1988
	Rewrote to use -is_src_file- and -is_doc_file- from "ved_newmaster.p"
 */
