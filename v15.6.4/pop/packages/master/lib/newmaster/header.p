/* --- Copyright University of Sussex 2002.  All rights reserved. ---------
 > File:           $poplocal/local/lib/newmaster/header.p
 > Purpose:        Inserts headers and footers for NEWMASTER
 > Author:         Robert Duncan and Simon Nichols, Jun  1 1987 (see revisions)
 > Documentation:  HELP * NEWMASTER
 > Related Files:  LIB * NEWMASTER
 */


section $-newmaster;

;;; indent_to:
;;;		tab to a given column

define lconstant indent_to(col);
	lvars col;
	until vedcolumn > col do
		vedcharinsert(`\t`);
	enduntil;
enddefine;

;;; file_name:
;;;		deduce a name to go in the header (or footer) of a file
;;;		either from the "name" option or from the pathname of the current
;;;		ved buffer.

define lconstant file_name() -> name;
	lvars version, name, i;
	if option("name") then
		locate_file(false, option("name")) -> (name, version);
	else
		procedure;
			dlocal % option("version") % = false; ;;; suppress version errors
			locate_file(false, vedpathname)
		endprocedure() -> (name, version);
		unless version then
		    locate_file(
				false,
			    if (issubstring('C.', 1, vedpathname) ->> i)
		        or (issubstring('S.', 1, vedpathname) ->> i)
		        then
			        allbutfirst(i-1, vedpathname)
			    else
				    '?????/' dir_>< sys_fname_name(vedpathname)
			    endif) -> (name, version);
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
	lconstant
		INDENT = 20;
	lvars
		author	= the_user() <> ', ' <> the_date(),
		comment	= comment_style(true),
		name	= file_name(),
	;

	define lconstant insert_prompt(arg);
		lvars arg;
		vedlinebelow();
		vedinsertstring(comment(1));
		vedcharright();
		vedinsertstring(destpair(arg) -> arg);
		unless arg == [] then
			indent_to(INDENT);
			vedinsertstring(front(arg));
		endunless;
	enddefine;

	vedtopfile();
	vedlineabove();
	vedinsertstring(comment(2));
	vedcharright();
	vedinsertstring(copyright_line());

	applist([%
		[^FilePrompt ^name],
		[^PurposePrompt],
		[^AuthorPrompt ^author],
		[^DocumentationPrompt],
		[^RelatedPrompt]
	%], insert_prompt);
	vedlinebelow();
	unless comment(3) = nullstring then
		vedinsertstring(comment(3));
		vedlinebelow();
	endunless;
	vedtopfile(); vedcheck();     ;;; make sure top is visible.
	searchfor_prompt(PurposePrompt);
	vedtextright(); indent_to(INDENT);
enddefine;

;;; make_src_footer:
;;;     inserts a skeleton for revision notes into a program file.

define lconstant make_src_footer();
	lvars comment = comment_style(true);
	vedendfile();
	vedlinebelow();
	vedinsertstring(comment(2) <> ' ' <> footer_line());
	unless comment(3) = nullstring then
		vedlinebelow();
		vedinsertstring(comment(3));
		vedcharup();
	endunless;
enddefine;

;;; make_doc_footer:
;;;     inserts the copyright notice and filename into a document file,
;;;     leaving the cursor on the first character of the filename.

define lconstant make_doc_footer();
	lvars name = file_name();

	define lconstant insert_string(string, attr);
		lvars string, attr;
		;;; dlocal vedcharinsert_attr = attr;
		vedinsertstring(string)
	enddefine;

	vedlineabove();
	vedcharinsert(`\n`);
	;;; vedinsertstring(DocMarkBot);
	vedinsertstring(LineMark);
	insert_string(consstring(#|
    	explode('Copyright'), `\s`;
	    explode(newmaster_copyright), `\s`;
		explode(the_year()), `.`, `\s`;
	    explode(AllRightsReserved);
	|#), `\[i]`);
	vedlineabove();
	;;; vedinsertstring(DocMarkTop);
	vedinsertstring(LineMark);
	insert_string(name, `\[bi]`);
	vedjumpto(vedline, datalength(LineMark)); vedcheck();
enddefine;

;;; update_copyright:
;;;		checks that the copyright notice on the file is up to date

define lconstant update_copyright();
	lvars	i, ds, yr, line;
	dlocal	vedline, vedcolumn, vvedlinesize, vedstatic;
	;;; locate the copyright line
	repeat
		vedthisline() -> line;
		if is_copyright_line(line) then
			quitloop;
		elseif issubstring(old_header_line(), line) ->> i then
			;;; replace old header line with new
			vedjumpto(vedline, i);
			vedcleartail();
			vedinsertstring(copyright_line());
			return;
		elseif vedline >= vvedbuffersize then
			return;
		else
			vednextline();
		endif;
	endrepeat;
	;;; extract the year field and quit if it's already up to date
	returnunless((issubstring(AllRightsReserved, line) ->> i)
		and (locchar_back(`.`, i, line) ->> i)
		and i > 4);
	subdstring(i - 4, 4, line) -> ds;
	returnif(ds = the_year());
	;;; check that we've really found a date before replacing it
	strnumber(ds) -> yr;
	returnunless(yr and 1970 <= yr and yr < 2070);
	;;; replace the field with the current year (updating the substring
	;;; preserves any character display attributes)
	vedjumpto(vedline, i - 4);
	the_year() -> substring(1, 4, ds);
	true -> vedstatic;
	vedinsertstring(ds);
enddefine;

;;; newmaster_header:
;;;     inserts a header or footer into a file as appropriate.

define lconstant do_header();
	lvars	comment;
	dlocal	vedleftmargin = 0, vedbreak = false;
	if is_doc_file() then
		update_copyright();
		vedputmessage(vednullstring);
	elseif option("doc") then
		vedendfile();
		unless vedline == 1 then
			vedcharup();
			if issubstring(OldCopyright, vedthisline()) then
				vedlinedelete();
			else
				vedchardown(); vedlinebelow();
			endif;
		endunless;
		make_doc_footer();
		vedputmessage(vednullstring);
	elseif is_src_file() then
		vedtopfile();
		update_copyright();
		searchfor_prompt(FilePrompt);
		if issubstring('$usepop/master/', 1, vedthisline()) then
			;;; Old-style filename; remove '$usepop/master/' prefix
			vedlocate('$usepop/master/');
			repeat 15 times veddotdelete() endrepeat;
		endif;
		searchfor_prompt(AuthorPrompt);
		unless issubstring(SeeRevisions, vedthisline()) then
			;;; 'Author' field exists, but without 'see revisions'
			vedtextright(); vedcharright();
			vedinsertstring(SeeRevisions);
		endunless;
		unless searchfor(footer_line()) then
			make_src_footer();
		endunless;
		vedlinebelow();
		comment_style(true) -> comment;
		if comment(3) = nullstring then
			;;; Insert end-of-line type comment
			vedinsertstring(comment(1) <> ' ')
		endif;
		vedinsertstring(LineMark <> the_user() <> ', ' <> the_date() <> ' ');
		if comment(3) /= nullstring then
			vedlinebelow();
			indent_to(8);
		endif;
	else
		make_src_header();
		vedputmessage(vednullstring);
	endif;
	true -> changed_header(vedpathname);
enddefine;
;;;
do_header -> command("header");

endsection;		/* $-newmaster */


/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 24 2002
		Altered to work for Birmingham
--- Robert Duncan, Apr 16 1993
		Changed update_copyright to preserve any character display
		attributes in the existing copyright line.
--- John Gibson, Feb  6 1993
		Changed make_doc_footer to insert new-style footer
--- Robert John Duncan, Mar 16 1992
		Major reorganisation.
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
