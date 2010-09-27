/* --- Copyright University of Birmingham 2009. All rights reserved. ------
 > File:			$poplocal/local/ved_latex/auto/ved_latex.p
 > Linked to:		$poplocal/local/ved_latex/auto/ved_dobib.p
 > Linked to:		$poplocal/local/ved_latex/auto/ved_latex2.p
 > Purpose:			Convenient interaction with latex, xdvi dvips
 > Author:			Aaron Sloman, Apr 22 1992 (see revisions)
 > Documentation:	HELP * VED_LATEX
 > Related Files:
 */

section;

;;; User assignable globals
global vars
	ved_latex_clear,		;;; specify files to be deleted

	ved_latex_pr_command,	;;; print command to be used
							;;; output is piped through lpr

	ved_latex_command,		;;; default set below

	ved_latex209_command = 'latex ', ;;; note space at end
	ved_latex2e_command = 'latex ',
;

unless isstring(ved_latex_command) then
	ved_latex2e_command -> ved_latex_command;
endunless;

;;; default vaules
lconstant
	dvi = '.dvi',

	latex_clear = ['.aux' ^dvi '.log' '.bbl' '.blg' '.toc' '.out'],

	latex_pr_command = 'dvips -f -t a4 ',
;


;;; Set defaults for above

unless islist(ved_latex_clear) then
	latex_clear -> ved_latex_clear
endunless;

unless isstring(ved_latex_pr_command) then
	latex_pr_command -> ved_latex_pr_command
endunless;

section latex =>
	ved_latex latex_do_any latex_bold latex_italic latex_centre
	latex_block latex_quotes latex_section latex_comment
	ved_bibtex, ved_latex2, ved_dobib;

;;; Utilities

define lconstant check_exists(file);
	lvars file;
	unless sys_file_exists(file) then
		vederror(file <> ' DOES NOT EXIST. USE ENTER latex')
	endunless;
enddefine;

define lconstant get_includes() ->includes;

	;;; find out if this is a master file that includes
	;;; other files.

	lconstant
		includestring = '\\include{',
		includelen = datalength(includestring);

	[] -> includes;

	vedpositionpush();
	1 -> vedline;

	;;; find where source begins
    ved_check_search('\\\\begin{document}', []);

	repeat
		;;; search for include instructions and collect them
		vednextline();
		quitif(vedline > vvedbuffersize);
		lvars
			line = vedthisline(), loc1, loc2;
		if issubstring(includestring, line) ->> loc1 then
			;;; Veddebug(vedthisline());
			loc1+includelen -> loc1;
			locchar(`}`, loc1, line) -> loc2;
			unless loc2 then
				vedputmessage('WARNING (line ' >< vedline ><
					') "}" not found on same line as \\include{"');
				syssleep(200);
				nextloop(1);
			endunless;
			(substring(loc1, loc2 - loc1, line) sys_>< '.tex') :: includes -> includes;
		 endif;
	endrepeat;
	vedpositionpop();
enddefine;


define lconstant concat_strings(vector);
	;;; Make a string of the characters in items in vector
	;;; for readability and reduced garbage
	lvars item, vector, index;
	consstring(
		#|
			for index from 1 to datalength(vector) do
				explode(fast_subscrv(index, vector))
			endfor
		|#)
enddefine;


define procedure do_range(string1, string2);
	;;; insert the strings on new lines before and after the marked
	;;; range

	lvars string1, string2;
	check_string(string1);
	check_string(string2);
	vedpositionpush();
	vedmarkfind();
	vedlineabove();
	vedinsertstring(string1);
	vedendrange();
	vedlinebelow();
	vedinsertstring(string2);
	vedpositionpop();
enddefine;


define procedure do_line(string1, string2);
	;;; insert the strings on new lines before and after this line

	lvars string1, string2, col = vedcolumn;
	check_string(string1);
	check_string(string2);

	dlocal vedbreak = false;
	1 -> vedcolumn;
	vedinsertstring(string1);
	vedtextright();
	vedinsertstring(string2);
	col + datalength(string1) -> vedcolumn;
enddefine;


define procedure do_word(string1, string2);
	;;; insert the strings on new lines before and after this word
	lvars string1, string2, col = vedcolumn;
	lconstant whitespace = '\s\t';

	check_string(string1);
	check_string(string2);

	dlocal vedbreak = false;

	until vedcolumn == 1 or strmember(vedcurrentchar(), whitespace) do
		vedcharleft()
	enduntil;
	if strmember(vedcurrentchar(), whitespace) then
		vedcharright()
	endif;
	vedinsertstring(string1);
	until vedcolumn > vvedlinesize
	or strmember(vedcurrentchar(), whitespace) do
		vedcharright()
	enduntil;

	vedinsertstring(string2);
	col + datalength(string1) -> vedcolumn;
enddefine;


define global latex_do_any(string1, string2);
	;;; do whichever of the above is needed, depending on vedargument
	;;; default to do_line. (This could be wrong)

	lconstant whitespace = '\s\t';

	lvars oldcol = vedcolumn;

	if vedargument = 'mr' or vedargument = 'range' then
		$-latex$-do_range(string1, string2)
	elseif vedargument = 'word' or vedargument = 'w' then
		$-latex$-do_word(string1, string2)
	elseif vedargument = 'line' or vedargument = 'f' then
		$-latex$-do_line(string1, string2)
	else
		;;; should this be the default?
		$-latex$-do_line(string1, string2)
	endif
enddefine;


define global ved_bibtex;
	;;; By Richard Dallaway
	lvars
		dir = sys_fname_path(vedpathname),
		rootfile = dir dir_>< sys_fname_nam(vedpathname),
		auxfile = rootfile sys_>< '.aux';

	check_exists(auxfile);

	veddo(concat_strings(
		{'sh cd ' ^dir '; bibtex -min-crossrefs=1 ' ^rootfile ' < /dev/null '}));
enddefine;

/*

ENTER latex block <type> [ <scope> ]

Produces \begin{<type>} and \end{type} before and after the current line or
marked ranged, depending on <scope>, which defaults to "line".

*/

define global latex_block();
	lvars arg, loc;
	vedpositionpush();
	if strmember(`\s`, vedargument) ->> loc then
		substring(1, loc - 1, vedargument) -> arg;
		allbutfirst(loc, vedargument) -> vedargument
	else
		vedargument -> arg;
		nullstring -> vedargument
	endif;

	if vedargument = 'range' or vedargument = 'mr' then
		latex_do_any('\\begin{' <> arg <> '}', '\\end{' <> arg <> '}');
	else
		latex_do_any('\\begin{' <> arg <> '}\n', '\n\\end{' <> arg <> '}');
	endif;
		vedpositionpop();
enddefine;

define global latex_bold =
	latex_do_any(% '{\\bf ', ' }'%)
enddefine;

define global latex_italic =
	latex_do_any(% '{\\em ', ' }'%)
enddefine;

define global latex_centre();
	veddo('latex block center ' <> vedargument)
enddefine;

;;;; define global ved_xdvi();
;;;; Now in LIB VED_XDVI

define lconstant dviclear(rootfile);
	;;; invoked by ENTER latex clear
	lvars rootfile, string;
	allbutfirst(5, vedargument) -> vedargument;
	if isstartstring(space, vedargument) then
		allbutfirst(1, vedargument) -> vedargument
	endif;

	if vedargument = 'd' or vedargument = 'default' then
		;;; reset default flags
		latex_clear -> ved_latex_clear
	elseunless vedargument = nullstring then
		sysparse_string(vedargument) -> ved_latex_clear
	endif;
	vedputmessage('DELETING ' >< ved_latex_clear);
	sysobey(
		concat_strings({'rm -f '
				% for string in ved_latex_clear do
					rootfile, string, space endfor
				%}));
enddefine;

/*
;;; tests for getprinter
;;; Use print arrow to print separator
=> applist([%getprinter('-Plp2', 1)%], npr);

=> applist([%getprinter('-Plp2 -p 10', 1)%], npr);

=> applist([%getprinter('-m -Plp2 -p 10', 4)%], npr);


*/

define constant getprinter(vedarg, loc) -> (newvedarg, printer);
	;;; vedarg is vedargument, loc is occurrence of '-P',
	;;; return two strings: printer name and new vedargument.
	lvars newloc = loc+2, endloc = 0, len = datalength(vedarg);
	lconstant err = 'Missing printer after -P';

	unless len > loc+1 then vederror(err) endunless;
	if loc > 1 then
		;;; -P should be preceded by space?
		loc - 1 -> loc;
		unless vedarg(loc) == `\s` then
			vederror('Missing space before -P')
		endunless;
	endif;
		
	locchar(`\s`, newloc, vedarg) -> endloc;

	if endloc then
		substring(newloc, endloc - newloc, vedarg) -> printer;
		if loc == 1 then
			allbutfirst(endloc, vedarg)
		else
			substring(1,loc-1, vedarg) <> allbutfirst(endloc-1, vedarg)
		endif
			-> newvedarg
	else
		substring(newloc, len - newloc+1, vedarg) -> printer;
		substring(1,loc-1, vedarg) -> newvedarg
	endif;
	
enddefine;

define lconstant dviprint(rootfile, dir);
	;;; invoked by ENTER latex print ...
	lvars rootfile, dir,
		loc,
		args,
		printflags = nullstring,
		print_to_file = false,
		printer = false,
		dvifile = rootfile <> dvi;

	dlocal %systranslate('PRINTER')%;

	check_exists(dvifile);

	if isendstring(' ps', vedargument) then
		allbutlast(3, vedargument) -> vedargument;
		;;; print to postscript file
		true -> print_to_file;
	elseif issubstring('-P', vedargument) ->> loc then
		getprinter(vedargument, loc) -> (vedargument, printer);
		printer -> systranslate('PRINTER');
	endif;

	if vedargument = 'print d' or vedargument = 'print default' then
		;;; reset default
		latex_pr_command ->> vedargument -> ved_latex_pr_command

		;;; now get rid of 'print '
	elseif isstartstring('print dvips ', vedargument) then

	elseif vedargument	/= 'print' then
		;;; Must be 'print <args>'. Get rid of 'print '
		allbutfirst(6, vedargument) -> vedargument;

		;;; add print flags
		if subscrs(1, vedargument) == `-` then
			;;; user has provided flags for dvips
			vedargument <> vedspacestring -> printflags
		else
			vederror('UNKNOWN ARGS FOR LATEX PRINT' >< vedargument)
		endif
	endif;

	vedputmessage('Running dvi print command. Please wait');

	veddo(
		concat_strings(
			{'sh cd ' ^dir '; '
				^ved_latex_pr_command ^vedspacestring ^printflags ^dvifile
				^(if print_to_file then
				' > ', rootfile, '.ps'
				else ' | lpr '
				endif)
			}));
	vedputmessage('Done');
enddefine;

define global latex_quotes();
	;;; Convert quotes to their proper form
	dlocal vedediting = false;
	veddo('gs/ "/ ``/');
	veddo('gs/@a"/``/');
	veddo('gs/("/(``/');
	veddo('gs/ \'/ `/');
	veddo('gs/(\'/(`/');
	veddo('gs/@a\'/`/');
	veddo('gs/" /\'\' /');
	veddo('gs/"@z/\'\'/');
	veddo('gs/")/\'\')/');
	veddo('gs/"}/\'\'}/');
	veddo('gs/"./\'\'./');
	veddo('gs/",/\'\',/');

	true -> vedediting;
	vedrefresh();
enddefine;


define global latex_section();
	;;; Turn current line into section heading
	lvars col = vedcolumn;
	dlocal vedbreak = false;
	1 -> vedcolumn;
	vedinsertstring('\\section{');
	vedtextright();
	vedinsertstring('}');
	col + 9 ->	vedcolumn
enddefine;

define global latex_comment();
	;;; comment line or range
	if vedargument = 'range' or vedargument = 'mr' then
		veddo('gsr/@a/% /');
	else
		veddo('gsl/@a/% /')
	endif;
enddefine;

define first_char(string) -> char;
	;;; return first non-sapce char in string, or false
	lvars i;
	fast_for i from 1 to datalength(string) do
		subscrs(i, string) -> char;
		returnunless(strmember(char, '\s\t'));
	endfor;
	false -> char;
enddefine;

define set_latex_command() -> command;
	;;; find first line starting with '\'
	vedpositionpush();
	vedjumpto(1,1);
	;;; check first non-space character in each line till '\\' found
	repeat
		lvars
			line = subscrv(vedline, vedbuffer),
			char = first_char(line);

		if char == `\\` then
			;;; if first command is documentclass change to
			;;; latex2e

			if issubstring('\documentclass', line) then
				ved_latex2e_command
			elseif issubstring('\documentstyle', line) then
				ved_latex209_command
			else ved_latex_command
			endif -> command;
			vedpositionpop();
			return();
		endif;
		vednextline();
		if (vedline > vvedbuffersize) then
			vedpositionpop();
			vederror('NOT A LATEX FILE?')
		endif;
	endrepeat;
enddefine;

;;; The main procedure
define ved_latex;
	;;; "ENTER latex xdvi", "ENTER latex clear", "ENTER latex print"
	;;; or "ENTER latex". Various extras in HELP * VED_LATEX
	dlocal
		ved_search_state,
		pop_pr_quotes = false;

	lvars
		dir = sys_fname_path(vedpathname),
		rootfile = dir dir_>< sys_fname_nam(vedpathname);

	if isstartstring('clear', vedargument) then
		dviclear(rootfile);

	elseif isstartstring('xdvi', vedargument) then
		if isstartstring('xdvi ', vedargument) then
			allbutfirst(5, vedargument)
		else nullstring
		endif -> vedargument;

		;;; use valof to postpone autoloading
		valof("ved_xdvi")();

	elseif isstartstring('bibtex', vedargument) then
		ved_bibtex();	;;; bibtex takes no optional arguments

	elseif isstartstring('printdefaults ', vedargument) then
		allbutfirst(14, vedargument) -> ved_latex_pr_command
	elseif isstartstring('print', vedargument) then
		dviprint(rootfile, dir);

	elseunless vedargument = nullstring then

		lblock;
			lvars
				loc = strmember (`\s`, vedargument),
				newcommand;
			if loc then
				;;; strip command name from front of vedargument
				substring(1, loc - 1, vedargument) -> newcommand;
				allbutfirst(loc, vedargument) -> vedargument;
			else
				vedargument -> newcommand;
				nullstring -> vedargument;
			endif;
			;;; Note that vedargument has now had keyword removed
			apply(valof(consword('latex_' sys_>< newcommand)));
		endlblock
	else
		;;; bare latex command
		lvars includes = get_includes();

		if includes == [] then
			if vedchanged then ved_w1() endif;
		else
			;;; included files may have been edited, write everything.
			ved_w();	
		endif;

		dlocal ved_latex_command = set_latex_command();
		lblock
			lvars file, oldpath = vedpathname, oldfile = ved_current_file;
			sys_fname_name(vedpathname) -> file;

			veddo(
				concat_strings({'sh cd ' ^dir '; ' ^ved_latex_command ^file
						' <	 /dev/null'}) );
			;;; go to end of file for error messages?
			unless vedcurrentfile == oldfile then
				if ved_try_search('! LaTeX error', [nocase])
				or ved_try_search('! Extra', [nocase])
				or ved_try_search('! Misplaced', [nocase])
				or ved_try_search('@a! ', [nocase])
				or ved_try_search('latexerr', [])
				or ved_try_search('! Emergency stop', [])
				then
					vedpositionpush();
					if ved_try_search('@al.',[]) then
						;;; go to location of error in source file

						lvars
							errfile = ved_current_file,
							includedfile = false,
							errline,
							;

						;;; find line number in error message
						vedmoveitem()->; vedmoveitem()->;
						vedmoveitem() -> errline;
						if includes == [] then
							;;; now go to problem file
							vedswapfiles();
							;;; back in source file.
							;;; Save previous editing location
							vedpositionpush();
							;;; no included file, so error must be in source file
							vedjumpto(errline, 1);
							;;; go back to error message in latex output file
							vedswapfiles();
							vedpositionpop();
							vederror('Latex error. Check error message and your latex file.');
						else
							;;; see if one of the included files has
							;;; been used
							lvars inclfile;
							vedpositionpush();
							vedendfile();
							;;; search back for record of included file
							for inclfile in includes do
								;;; Veddebug([searching back for ^inclfile]);
								if ved_try_search(inclfile, [back]) then
									;;; found the file with the error
									vedpositionpop();
									vedendfile();
									lvars
										errstring =
											'LATEX ERROR MAY BE IN\n\t'
												>< dir dir_>< inclfile,
										linestring =
											'AT OR BEFORE LINE ' >< errline;

									vedlinebelow();
									vedinsertstring('@@@@@@@@@\n');
									vedinsertstring(linestring);
									vedlinebelow();
									vedinsertstring(errstring);
									vedinsertstring('\nOR IN FILE THAT INCLUDED IT\n\t');
									vedinsertstring(oldpath);
									vedinsertstring('\n@@@@@@@@@');
									vedjumpto(vedline+1, 1);
									vederror('LATEX ERROR: SEE EDIT BUFFER');
								endif;
							endfor;
							vedpositionpop();
							vedswapfiles();
							;;; back in source file.
							;;; Save previous editing location
							vedpositionpush();
							vedjumpto(errline, 1);
							;;; go back to error message in latex output file
							vedswapfiles();
							vederror('CANNOT FIND WHICH FILE IT WAS')
						endif;
					endif;
				else
					vedendfile()
				endif
			endunless;
		endlblock;
	endif
enddefine;

define ved_latex2;
	;;; run latex twice, for fixing cross references.
	lvars oldfile = ved_current_file;
	veddo('latex');
	oldfile -> ved_current_file;
	veddo('latex');
enddefine;

define ved_dobib;
	;;; run latex then bibtex, then run latex twice.
	lvars oldfile = ved_current_file;
	ved_w();
	veddo('latex');
	oldfile -> ved_current_file;
	veddo('bibtex');
	oldfile -> ved_current_file;
	veddo('latex2');
enddefine;

endsection;	 /*latex*/
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jun 24 2009
		Altered latex_clear list to include '.out'
--- Aaron Sloman, Aug 11 2004
		Altered latex_quotes to transform "('" to "(`"
--- Aaron Sloman, Apr 28 2001
	Made it deal more sensibly with a master latex file that uses \include
--- Aaron Sloman, Apr 28 2001
	Enhanced the parsing of ENTER latex print, to allow a printer
	to to be specified, using new procedure getprinter
	Made ved_latex2e_command the default
--- Aaron Sloman, Aug 10 2000
	Changed "\r" to "\n" in the centre command
--- Aaron Sloman, Jan  5 2000
		Allowed argument string to include -P<printer>
--- Aaron Sloman, Jun 27 1999
	Replaced latex209 with latex
--- Aaron Sloman, Apr  9 1999
	dlocalised ved_search_state
--- Aaron Sloman, Dec 12 1998
	Make ved_latex jump to line in source file mentioned in latex error
--- Aaron Sloman, Nov 26 1998
	Made VED go to error message in output file where appropriate
--- Aaron Sloman, Jul 15 1998
	Made bibtex automatically include cross-references
--- Aaron Sloman, Dec 13 1997
	Made to adjust automatically for latex2e
--- Aaron Sloman, Dec 25 1996
	Minor changes, including making ved_latex go to end of output file.
	Put ved_xdvi in separate file.
--- Aaron Sloman, Jan 11 1996
		Fix problems with ved_xdvi, including making it change to the
		file's directory so as to work with psfig etc.
--- Aaron Sloman, May 20 1995
	Allowed users to assign an alternative command to
		ved_xdvi_command
--- Aaron Sloman, May 15 1995
	Added '.toc' to latex_clear
--- Aaron Sloman, April 17 1995
	Changed dviprint to include dir argument so that it can do
	cd dir, to ensure that any .eps files are picked up.

--- Aaron Sloman, April 17 1995
	Added ENTER latex2, and ENTER dobib
	  ENTER latex2
		This runs latex twice in the current .tex file, producing
		two separate output files. It is useful for fixing tables
		of contents, new citations based on bibtex, etc.

	  ENTER dobib
		This runs ved_latex, then ved_bibtex then ved_latex2.
		It produces four separate output files. Do this when you
		have introduced a new citation, or when you have altered
		your .bib file and need to run bibtex.


--- Aaron Sloman, March 23 1995
	Allowed "ps" to be combined with other commands, e.g.
		ENTER latex print -t landscape ps
--- Aaron Sloman, Aug 16 1994
	Changed to use latex209 instead of latex, and introduced
	ved_latex_command as a default users can change.
--- Aaron Sloman, Aug  7 1994
	Made to print dvips output into a ved file rather than to screen.
--- Aaron Sloman, Jan 8th 1994
	fixed latex_quotes to deal with ". and ",
--- Aaron Sloman, Nov 22 1992
	Made to jump to end of output file, so that errors can be found
	easily.
--- Aaron Sloman, Oct 10 1992
	Altered to allow ENTER latex print -<flags>

--- Aaron Sloman, Jun 18 1992
	Made dviclear do "rm -f"

	Added ENTER dvi2tty
		  ENTER printdefaults
		  ENTER print ps
--- Aaron Sloman, Jun 18 1992
	Changes due to Richard Dallaway
		Added ved_bibtex, and ENTER latex bibtex
		Modified latex_clear to include .bbl and .blg
		Modified HELP VED_LATEX accordingly
--- Aaron Sloman, May 10 1992
	added latex_comment
	Added latex_block, latex_quotes, latex_section
	Added LIB latex_heading to the library.

--- Aaron Sloman, Apr 28 1992
	Modified to make it easy to extend using autoloadable latex_<name>
	procedures.
	Sectionised
	Added utilities $-latex$-do_range, $-latex$-do_word, $-latex$-do_line

 */
