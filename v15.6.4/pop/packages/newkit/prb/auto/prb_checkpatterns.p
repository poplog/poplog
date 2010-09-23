/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/newkit/prb/auto/prb_checkpatterns.p
 > Purpose:			Check patterns used with poprulebase
 > Author:          Aaron Sloman, Nov 15 2001
					Based on a suggestion by Catriona Kennedy
 > Documentation:	HELP PRB_CHECKPATTERNS
 > Related Files:	LIB poprulebase
 */


section;

uses ARGS;
uses newkit
uses poprulebase

;;; words to be ignored by default
global vars prb_ignore_words =
	[NOT OR AND NOT_EXISTS IMPLIES FILTER INDATA VAL
	 DLOCAL INSTRUCTIONS FINAL WINDOW STARTWINDOW ENTITIES $$ ?? ? -> ->>
	 sim_myself prb_allrules prb_sortrules];

define lconstant isokword(item, oklist) -> boole;
	;;; used to tell whether a word is recognized, and should therefore
	;;; not go into the output file
	if isword(item) then
		lvars okitem;
		fast_for okitem in oklist do
			if item == okitem
			or (isprocedure(okitem) and okitem(item)) then
				true -> boole;
				return;
			endif;
		endfor;
		false ->  boole;
	else
		true -> boole
	endif;
enddefine;


/*

tests

isokword(99, [a b c d ^is_syntax_word e])=>
** <true>
isokword('the cat', [a b c d ^is_syntax_word e])=>
** <true>
isokword("cat", [a b c d ^is_syntax_word e])=>
** <false>
isokword("d", [a b c d ^is_syntax_word e])=>
** <true>
isokword("if", [a b c d ^is_syntax_word e])=>
** <true>
isokword("cat", [])=>

*/


define lconstant gobble_list(procedure getnext);
	;;; read a list to closing list bracket
	;;; used to read the remainder of a pop11 expression
	;;; starting [POP11 or [WHERE

	lvars next,
		list_depth = 1;

	repeat
		getnext() -> next;
		if next == termin then
			mishap('UNEXPECTED END OF FILE WHEN CHECKING PATTERNS', []);
		elseif next == "[" then
			;;; entering another list expression
			list_depth + 1 -> list_depth ;
		elseif next == "]" then
			;;; finishing a list expression
			list_depth - 1 -> list_depth ;
			returnif(list_depth == 0)
		endif;
	endrepeat;
enddefine;

define prb_checkpatterns(infile, oklist, outfile);
	;;; allow optional extra boolean argument no_line_numbers
	lvars
		no_line_numbers = false,
		procedure foundword;

	;;; check for optional fourth argument
	ARGS infile, oklist, outfile, &OPTIONAL no_line_numbers:isboolean;


	unless islist(oklist) then
		mishap('LIST OF WORDS NEDED', [^oklist])
	endunless;

	if no_line_numbers then
		;;; property to record words
		newproperty([], 100, false, "perm") -> foundword;
	endif;

	lvars
		next,
		lastitem = false,
		linenum = 1,
		procedure getnextchar = discin(infile),
		outfile = discout(outfile),
		list_depth = 0;

	define lconstant next_char() -> char;
		getnextchar() -> char;
		if char == `\n` then
			linenum + 1 -> linenum
		endif;
	enddefine;

	lvars procedure getnext = incharitem(next_char);

	;;; allow newlines to be recognized
	dlocal
		popnewline = true,
		cucharout = outfile;

	repeat
		getnext() -> next;
		;;; pr(newline); pr(linenum), pr(': ');pr(next);
		if next == termin then
			;;; flush the output buffer and stop
			pr(newline);
			pr(termin);
			return();
		elseif next == "[" then
			;;; entering another list expression
			list_depth + 1 -> list_depth ;
		elseif next == "]" then
			;;; finishing a list expression
			list_depth - 1 -> list_depth ;
		elseif list_depth /== 0 then
			if lastitem == "[" then
				;;; at heginning of list
				if next == "POP11" or next == "WHERE" then
					;;; read to end of list
					gobble_list(getnext);
					list_depth - 1 -> list_depth ;
					"]" -> lastitem;
					nextloop(1);
				endif
			endif;
			
			if isnumber(next) or not(isinheap(next)) then
				;;; ignore words in system
			elseif prb_action_type(next) then
				;;; ignore
			elseif prb_condition_type(next) then
				;;; ignore
			elseif fast_lmember(next, prb_ignore_words) then
				;;; ignore
			elseif no_line_numbers and foundword(next) then
				;;; ignore
				;;; for debugging
				;;; printf(next, '\nFOUND : %P ')
				
			elseunless isokword(next, oklist) then
				if no_line_numbers then
					true -> foundword(next);
					npr(next);
				else
					printf(next, linenum, '\n%P : %P')
				endif;
			endif
		endif;
		next -> lastitem;
 	endrepeat;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
-- Aaron Sloman, 21 Feb 2002
	Provided help file, and put in a check for oklist: must be a list.

*/
