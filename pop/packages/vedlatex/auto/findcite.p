/* --- Copyright University of Birmingham 2008. All rights reserved. ------
 > File:			$local/auto/findcite.p
 > Purpose:			Extract items in bib file referenced in latex file
 > Author:			Aaron Sloman, Feb 13 2004 (see revisions)
 > Documentation:	HELP FINDCITE
 > Related Files:    findcites shell script, to invoke this
 */

/*

WHAT THIS IS

Mark Ryan requested a utility that
  Takes a .tex and a .bib file, and produces the subset of the .bib file
  containing the entries which are referred to in the .tex file.
  (Useful so you don't have to send your huge bib file to coauthors)

His message reminded me that I've wanted this for some time, so I
 wrote it in pop11.

It can (temporarily) be tested thus

     ~axs/temp/findcites  bibtexfile.bib latexfile.tex > newfile.bib
or

     ~axs/temp/findcites bibtexfile.bib > newfile.bib
		(If no .tex file is given it prints the whole bib file, neatly).

 It prints the output, so you can redirect it to a file

 To try it do:

     ~axs/temp/findcites ~axs/pap/gen.bib ~axs/pap/emot.book02/sloman-chrisley-scheutz-emot.tex > newbx

 The shell script findcites compiles this file which defines two
 procedures (below)

 process_file(citewords, texfile) -> cited;
     Given a list of citation words e.g. [cite nocite citea citep citet]
     and a file name e.g. 'foo.tex' returns an alphabetically
     ordered list of the citation keys found, e.g.
     [simon67 minsky86 sloman71 ...]

 process_bib(cited, bibfile);
     Given a list of citation keys of the sort produced by process_file
     and a bibtex file, print out all the entries in bibfile that
     are referenced by the keys.
	 If cited is the word "'#CiteAll#'" then print all the entries in the
	 file. This may be used to tidy the file.

 Some formatting may be changed. To prevent any changes of indentation
	assign false to indent_spaces (default is 3).

 Long lines are broken at a space or tab after column 70 and indented by
	one tab.
	To prevent this assign a very large number to poplinewidth (default 70).


GLOBAL VARIABLES
Alter below, as required:

citewords
	defaults to [cite nocite citea citenp citep citet]

bibtypes
	A list of bibtex entry headers. See below

Both lists can be changed.

*/

/*

;;; TESTS

false -> pop_pr_quotes;
process_file(citewords,  '~/pap/emot.book02/SCS-final/sloman-chrisley-scheutz-emot.tex') =>
process_file(citewords,  '~axs/pap/emot.book02/SCS-short/scs-short.tex') =>
process_file(citewords,  '~axs/pap/cogsys04/sloman-chrisley-cogsys.tex') =>

vars cited;
process_file(citewords,  '~/temp/testfile.tex') -> cited;
process_file(citewords,  '~axs/pap/cogsys04/sloman-chrisley-cogsys.tex') -> cited;
length(cited) =>
cited =>

process_bib(cited, '~axs/pap/gen.bib');
process_bib(cited, '~axs/pap/emot.book02/fellous.bib');



vars keys = [albus81 anderson89 boden78 simon67 sloman71 sloman78 sloman81 sloman96sim witt54];

process_bib(keys , '~axs/pap/gen.bib');
true -> keep_latex_comments;
false -> keep_latex_comments;
process_bib("'#CiteAll#'", '~axs/pap/gen.bib');
process_bib("'#CiteAll#'", '~axs/temp/testbib.bib');

process_bib("'#CiteAll#'", '/home/staff/axs/temp/markbib.bib');

false -> check_duplicates;
true -> check_duplicates;
process_bib("'#CiteAll#'", '/home/staff/axs/temp/mdr.bib');

*/

;;; 20 Mbytes. Overkill?
5000000 ->	popmemlim;

;;; These will be indicators of bibtex citations
vars citewords = [cite nocite citea citep citet citeauthor citeyear];

;;; convert bibtex types to lower case to simplify matching
;;; add more if needed
vars bibtypes =
	maplist([
              Article
              Book
              Booklet
              Conference
              InBook
              InCollection
              InProceedings
              Manual
              MastersThesis
              Misc
              PhdThesis
              Proceedings
			  String
              TechReport
			  Thesis
              Unpublished
           ], uppertolower);

lconstant CiteAll = "'#CiteAll#'";

define require(item, repeater, next);
  	;;; check that item is the next thing produced by the repeater
	;;; apart from newlines. If it is not item produce an error.

	;;; Leave newlines on the stack. They will be put in a list	
	;;; by the caller.
	while next == newline then next; repeater() -> next endwhile;
	;;; [next ^next] ==>

	;;; first non-newline should be item (e.g. "{" )
	unless next == item then
		mishap('Expecting ' >< item >< ' found: ' >< next, [])
	endunless;

enddefine;


/*
PROCEDURE: process_file (citewords, texfile) -> cited
INPUTS   : citewords, texfile
  Where  :
    citewords is a list of words, like "cite", "nocite", "citea"
    texfile is a is a string, the name of the latex file to be scanned
OUTPUTS  : cited is a list of the words referring to cited items.
USED IN  : Getting first argument for process_bib(cited, bibfile)
CREATED  : 4 Feb 2004
PURPOSE  : Find what has been cited in a latex file.

TESTS:
	above

*/


define process_file(citewords, texfile) -> cited;
	;;; return citations in textfile of types specified in
	;;; the list citewords

	lvars
		cited = [],
		next,
		procedure filein = discin(sysfileok(texfile));

	define lconstant nextcharin() -> char;
		;;; modify the character repeater filein
		;;; Ignore all text from '%' to end of line.

		lvars char = filein();
		if char == `%` then
			;;; ignore latex comments
			repeat
				filein() -> char;
			returnif(char == `\n`)
			endrepeat
		endif;
	enddefine;

	;;; Create a text item repeater from nextcharin
	lvars
		procedure getnextitem = incharitem(nextcharin);

	procedure();
		;;; We need a new procedure body to set the scope of dlocal --
		;;; as it requires getnextitem to have been defined.

		;;; Make the itemiser treat many sign characters as alphabetic
		dlocal
			%item_chartype(`#`, getnextitem)% = 1,
			%item_chartype(`!`, getnextitem)% = 1,
			%item_chartype(`$`, getnextitem)% = 1,
			%item_chartype(`^`, getnextitem)% = 1,
			%item_chartype(`~`, getnextitem)% = 1,
			%item_chartype(`#`, getnextitem)% = 1,
			%item_chartype(`&`, getnextitem)% = 1,
			%item_chartype(`*`, getnextitem)% = 1,
			%item_chartype(`_`, getnextitem)% = 1,
			%item_chartype(`+`, getnextitem)% = 1,
			%item_chartype(`-`, getnextitem)% = 1,
			%item_chartype(`=`, getnextitem)% = 1,
			%item_chartype(`:`, getnextitem)% = 1,
			%item_chartype(`;`, getnextitem)% = 1,
			%item_chartype(`.`, getnextitem)% = 1,
			%item_chartype(`@`, getnextitem)% = 1,
			%item_chartype(`?`, getnextitem)% = 1,
			%item_chartype(`|`, getnextitem)% = 1,
			%item_chartype(`/`, getnextitem)% = 1,
			%item_chartype(`\``, getnextitem)% = 1,
			%item_chartype(`'`, getnextitem)% = 1,
			;


		define getcited(cited) -> cited;
			;;; get the list of cite arguments, when a citation has been
			;;; found
			
			lvars next = getnextitem();

			;;; [getcited: next ^next] =>

			;;; allow up to two prefixes in square brackets
			if next == "[" then
				;;; read to closing square bracket
				until next == "]" do getnextitem() -> next enduntil;
				getnextitem() -> next;
			endif;

			if next == "[" then
				;;; read to closing square bracket
				until next == "]" do getnextitem() -> next enduntil;
				getnextitem() -> next;
			endif;


			unless next == "{" then
				[% require("{", getnextitem, next); %] ->;
			endunless;

			;;; now get citation keys, up to "}" ignoring commas and
			;;; previously recorded keys
			repeat
				lvars next = getnextitem();
			quitif(next == "}");
				if next == termin then
					mishap('End of file, expecting "}"', []);
				endif;

				unless fast_lmember(next, cited) or next == "," then
					;;; found one, so add it to the list
					conspair(next, cited) -> cited;
				endunless;
				
			endrepeat;
			
		enddefine;


		;;; now repeatedly scan to next citation and record keys
		lvars lastitem = false;

		repeat
			getnextitem() -> next;
		
		quitif(next == termin);

			;;;beware of '\def' or '\newcommand' etc.
			if lmember(next, [def newcommand renewcommand providecommand ]) then
				procedure();
					;;; read to end of line (not safe!)
					dlocal popnewline = true;
					repeat
						getnextitem() -> next;
						;;; [getting:next ^next] =>
						quitif(next==newline);
					endrepeat;
				endprocedure();
				nextloop
			endif;

			;;; see if it has found one of \cite \nocite etc.
			;;; if lastitem == "\" and lmember(next, citewords) then
			;;;;[processfile:next ^next] =>
			if lmember(next, citewords) then
				getcited(cited) -> cited;
			endif;

			next -> lastitem;

		endrepeat;

		syssort(cited, alphabefore) -> cited;

	endprocedure();

enddefine;


;;; Global variables needed for scanning the bibtex file analysing it
;;; and printing out relevant sections.

global vars

	;;; If true, duplicate entries with the same citation key are pruned.
	;;; only the first occurrence is used. A list of duplicates is printed
	;;; at the end of the file
	check_duplicates = true,

	;;; Make this false to get comments starting with '%' removed
	keep_latex_comments = true,

	;;; never force a word to be broken
	poplinemax = 99999999,

	;;; insert newline and tab after this:
	poplinewidth = 70,

	;;; Make this false to prevent automatic indentation
	indent_spaces = 3,
	;;; indent_spaces = false,

	;;; Assume no line in bibtex file has more than 512 characters.
	;;; This could be a bug.

	string_max = 512,

	;;; use this as a read buffer
	buffer = inits(string_max),


	;;; remaining variables localised in process_bib
	
	line_num,

	;;; this will hold the current line of text, a string
	current_buffer,

	current_buffsize,

	;;; index into the current_buffer
	index = 0,

	;;; list of lines read in, in reverse order
	;;;textlines = [],

	;;; list of line numbers for entry beginnings, in reverse order
	startlines = []
	;


define check_termin(char);
	if char == termin then
		mishap('Unexpected end of file, line: ' >< line_num, [])
	endif;
enddefine;

define read_to_closer(getnextitem);
	;;; '{' has been read, so read up to '}'
	;;; using brackets as a counter

	lvars brackets = 1;	;;; opener already read

	lvars lastchar = false;

	repeat
		lvars char = nextchar(getnextitem);
		check_termin(char);
		cucharout(char);
		if char == `@` then
			pr(current_buffer);
			mishap('@ found before }', []);
		endif;
		if char == `{` and lastchar /== `\\` then brackets + 1 -> brackets endif;
		if char == `}` and lastchar /== `\\` then brackets - 1 -> brackets endif;
		char -> lastchar;
		if indent_spaces and char == `\n` then
			;;; handle indentation;
			;;; read to first non-space character
			repeat
				lvars char = nextchar(getnextitem);
				;;;check_termin(char);
				if char==termin then
					['TERMIN FOUND' brackets ^brackets]=>
					return;
				endif;
			quitunless(strmember(char,'\s\n\t'));
			endrepeat;
			if brackets == 1 and char == `}` then
				cucharout(char);
				return()
			else
				;;; indent line
				repeat indent_spaces times cucharout(`\s`) endrepeat;
				cucharout(char);
				if char == `{` and lastchar /== `\\` then brackets + 1 -> brackets endif;
				if char == `}` and lastchar /== `\\` then brackets - 1 -> brackets endif;
				char -> lastchar;
			endif;
		endif;
	quitif(brackets == 0);
		char -> lastchar;
	endrepeat;
enddefine;


define print_bibentry(bibtype, bibkey, getnextitem) -> char;;
	;;; found a matching entry, so print it, using item repeater getnextitem
	;;; for bib file,

	;;; print start of entry with context
	pr(newline);
	pr("@"); pr(bibtype);
	pr("{");pr(bibkey);
	pr(",");

	read_to_closer(getnextitem);

	;;; end entry and one blank line
	pr(newline);


enddefine;


define print_citestrings(getnextitem) -> char;
	;;; invoked below if bibtypelcase = "string" then

	pr('@string{');
	;;; read to first `{`
	until (nextchar(getnextitem) ->> char) == `{`
	do
		check_termin(char);
	enduntil;
	read_to_closer(getnextitem);

	;;; end entry and one blank linke
	pr(newline);
	pr(newline);
	
enddefine;


/*
PROCEDURE: print_citations (cited, getnextitem)
INPUTS   : cited, getnextitem
  Where  :
    cited is EITHER the word "#CiteAll#" or a list of citation keys
		possibly created by process_file
    getnextitem is an item repeater created in process_bib from the
		bibtex file.
OUTPUTS  : NONE
USED IN  : process_bib
CREATED  : 13 Feb 2004
PURPOSE  : Prints out the bibtex entries

TESTS:

*/

define print_citations(cited, getnextitem) -> char;
	lvars char;
	;;; cited is the list of cited entries
	;;; getnextitem is the text item repeater for the bibtex file
	;;; created in the caller process_bib, below

	;;; make itemisers return newline
	dlocal popnewline = true;

	lvars duplicates = [];

	procedure();
		;;; dlocal expressions have to be evaluated after getnextitem gets
		;;; its value
		;;; Make the itemiser treat many sign characters and numerals as alphabetic

		dlocal
			%item_chartype(`'`, getnextitem)% = 1,
		;

		lvars

			checked_keys = [],


			lastitem = newline;

		repeat

			repeat
				lvars next = getnextitem();
				returnif(next == termin)(termin -> char);
				quitif(next == "@");
				if keep_latex_comments and next == "%" and cited == "'#CiteAll#'" then
					;;; don't discard comments between items
					pr('%');
					repeat
						;;; print characters to end of line
						lvars c = nextchar(getnextitem);
						cucharout(c);
						quitif(c == `\n`);
					endrepeat;
					newline -> lastitem;
				else
					next -> lastitem;
				endif;
			endrepeat;
			
			if next == "@"
				and (lastitem == newline or lastitem == "}")
			then
				
				lvars
					bibtype = getnextitem(),
					bibtypelcase = uppertolower(bibtype);

				returnif(bibtype == termin)(termin -> char);

				if bibtypelcase = "string" then
					;;; includes newline at end.
					print_citestrings(getnextitem) -> char;
					returnif(char == termin);
					newline -> lastitem;

				elseif fast_lmember(bibtypelcase, bibtypes) then
						;;; [bibtype ^bibtype ] =>

					;;; line_num :: startlines -> startlines;
					
					lvars key;
					;;; get citation key
					until (nextchar(getnextitem) ->> char) == `{`
					do
						returnif(char == termin);
					enduntil;
					;;; citation key should follow. It may be on next line.
                    ;;; Collect all non-white space characters up to but
					;;; excluding ','

					consword(
						#| repeat
								nextchar(getnextitem) -> char;
								quitif(char == `,`);
								check_termin(char);
								unless strmember(char, '\s\t\n') then char endunless
						   endrepeat
						|#) -> key;


					lvars
						first_occurrence = false,
						lcase_key = uppertolower(key);

					

					if check_duplicates
					and fast_lmember(key, checked_keys)
					then
						key :: duplicates -> duplicates;
					else
						true -> first_occurrence;
						key :: checked_keys -> checked_keys;
					endif;

					if	first_occurrence
					and (cited == CiteAll or fast_lmember(lcase_key, cited))
					then

						;;; found a required bibtex entry
						;;; so print it out
						print_bibentry(bibtype, key, getnextitem) -> char;

						;;; Veddebug([^bibtype ^char ]);

						if char == termin then pr(newline); return
						elseif char == `}` then
							cucharout(char);
							pr(newline);
						elseif char == `@` then
							index - 1 -> index
						endif;
						nextloop();
                	else
						key :: checked_keys -> checked_keys;

						;;; discard entry;

						lvars next;
						;;; read to end of line
						;;; next cannot be a newline
						repeat
							getnextitem() -> next;
						returnif(next == termin)(termin -> char);
						quitif(next == newline);
							next -> lastitem;
						endrepeat;

					endif;
				endif

			else
				;;; read on
				next -> lastitem;
			endif;

		endrepeat;
	endprocedure();	

	if duplicates /== [] then
		;;; Print out list of duplicates removed:
		999 -> poplinewidth;
		pr('\n\n%DUPLICATES REMOVED:\n% ');
		applist(rev(duplicates), spr)
	endif;

enddefine;


/*
PROCEDURE: process_bib (cited, bibfile)
INPUTS   : cited, bibfile
  Where  :
    cited is EITHER the word "#CiteAll#" or a list of citation keys
		possibly created by process_file
    bibfile is a bibtex file
OUTPUTS  : NONE (everything is printed)
USED IN  : Shell scripts and user programs
CREATED  : 5 Feb 2004
PURPOSE  : Given a list of citation keys and a bibtex file, extract
		a smaller file containing only the entries cited.
		If instead of a list the first argument is the word "#CiteAll#"
		(created by "'#CiteAll#'") then extract ALL the bibtex entries.
		This can be used to 'pretty print' a bibtex file.

TESTS:
	above
*/

define process_bib(cited, bibfile);

	dlocal
		line_num = 0,

		current_buffsize,
		current_buffer,

		;;; index into it
		index = 0,

		;;; next two disabled for now. Could be useful later.
		;;; a list, in reverse order, of all lines read in
		;;;textlines = [],

		;;; list of line numbers for entry beginnings, in reverse order
		;;; startlines = [];
	;

	if islist(cited) then
		maplist(cited, uppertolower) -> cited;
	endif;

	;;; [NEW ^cited] ==>

	lvars
		filedev = sysopen(bibfile, 0, "line"),
		procedure filein = discin(sysfileok(bibfile));

	define next_char() -> char;
		;;; character repeater from bibtex file
		;;; also manages a list of lines read in

		if index == 0 then
			;;; have to start a new line from the file
			line_num + 1 -> line_num;

			sysread(filedev, buffer, string_max) -> current_buffsize;
			if current_buffsize == 0 then
				;;; end of file
				termin -> char;
				return
			else
				;;; save the current line
				substring(1, current_buffsize, buffer) -> current_buffer;

				;;;	current_buffer :: textlines -> textlines;
			endif;
		endif;

    	index + 1 -> index;
		if index > current_buffsize then
			;;; End of line. So read next line to get next char
			0 -> index;
			next_char() -> char;
		else
			fast_subscrs(index, current_buffer) -> char;
		endif;

		if not(keep_latex_comments) and char == `%` then
			;;; ignore rest of line
			0 -> index;
			`\s` -> char;
		endif;

	enddefine;


	;;; create an item-repeater
	lvars
		char,
		procedure getnextitem = incharitem(next_char);

	procedure();
		;;; We need a new procedure body to set the scope of dlocal --
		;;; as it requires getnextitem to have been defined.

 		;;; Make the itemiser treat many sign characters as alphabetic
	dlocal
   			%item_chartype(`#`, getnextitem)% = 1,
   			%item_chartype(`!`, getnextitem)% = 1,
   			%item_chartype(`$`, getnextitem)% = 1,
   			%item_chartype(`^`, getnextitem)% = 1,
   			%item_chartype(`~`, getnextitem)% = 1,
   			%item_chartype(`#`, getnextitem)% = 1,
   			%item_chartype(`&`, getnextitem)% = 1,
    		%item_chartype(`*`, getnextitem)% = 1,
   			%item_chartype(`_`, getnextitem)% = 1,
   			%item_chartype(`+`, getnextitem)% = 1,
   			%item_chartype(`-`, getnextitem)% = 1,
  			%item_chartype(`=`, getnextitem)% = 1,
 			%item_chartype(`:`, getnextitem)% = 1,
 			%item_chartype(`;`, getnextitem)% = 1,
 			%item_chartype(`.`, getnextitem)% = 1,
;;; 			%item_chartype(`@`, getnextitem)% = 1,
 			%item_chartype(`?`, getnextitem)% = 1,
 			%item_chartype(`|`, getnextitem)% = 1,
 			%item_chartype(`/`, getnextitem)% = 1,
 			%item_chartype(`\``, getnextitem)% = 1,
 			%item_chartype(`'`, getnextitem)% = 1,
 			;

		;;; use it to find and print out the citations
		print_citations(cited,  getnextitem) -> char;

		;;; char should be termin

		;;; convenient for some editors:
		pr(newline);
	endprocedure();
	
enddefine;

/*

 CONTENTS 		

 define require(item, repeater, next);
 define process_file(citewords, texfile) -> cited;
 define check_termin(char);
 define read_to_closer(getnextitem);
 define print_bibentry(bibtype, bibkey, getnextitem) -> char;;
 define print_citestrings(getnextitem) -> char;
 define print_citations(cited, getnextitem) -> char;
 define process_bib(cited, bibfile);

*/

;;; for uses
global vars findcite = true;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, May  5 2008
		Added \citeyear \citeauthor
--- Aaron Sloman, Mar 31 2008
		Removed spurious repeater in process_bib (filein)
		Fixed item repeater in process_bib not to be upset by
		file names with illeal pop11 number format
--- Aaron Sloman, Feb 27 2008
		Introduced patch to cope with occurrences of \def \newcommand
		\renewcommand \providecommand whose arguments include one of
		of the 'cite' key words.
		The patch just reads to the end of the line for now. Not safe!
--- Aaron Sloman, Jan  8 2008
		Added key citenp for APA style.

--- Aaron Sloman, Jul 25 2004
		Added new keys citep, citet, required for elsevier class
		Also allowed two square-bracketed inserts between keyword
		and citation key, e.g. cite[e.g.,][ch 4]{jones98}

--- Aaron Sloman, Feb 15 2004
	Added 'Thesis' to list of types
	Added check_duplicates to prune duplicates. Default true
	Added keep_latex_comments, default true

--- Aaron Sloman, Feb 14 2004
	Changed to rely a lot less on pop11 itemiser. Introduced option
	for indentation control.
	
 */
