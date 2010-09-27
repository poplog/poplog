/* --- Copyright University of Birmingham 2001. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_procheader.p
 > Purpose:			Start a procedure header, for students etc
 > Author:          Aaron Sloman, Oct 19 1996 (see revisions)
 > Documentation:	HELP * VED_PROCHEADER
 > Related Files:
 */

compile_mode :pop11 +strict;

section;


define lconstant is_syntax_word(word);
	lvars word, prop;
	if isword(word) then
		identprops(word) -> prop;
		isword(prop)
	and
		(prop == "syntax" or isstartstring('syntax', prop))
	else false
	endif;
enddefine;


define lconstant parse_args(string)->list;
	pdtolist(incharitem(stringin(string))) -> list;
	;;; solidify list, for the matcher
	copylist(list) -> list;
enddefine;

/*
parse_args('foo(x,y)->(b,c)')==>
** [foo ( x , y ) -> ( b , c )]
*/

define lconstant isproctype(def_type);
	not(def_type) or def_type == "method"
enddefine;


/*
PROCEDURE: next_field (string)
INPUTS   : string is a ???
OUTPUTS  : NONE
USED IN  : ???
CREATED  : 14 Dec 2001
PURPOSE  : ???

TESTS:

*/

define lconstant next_field(string);
	vedlinebelow(); ;;; vedinsertstring(' > ');
	vedinsertstring(string);
enddefine;

define lconstant insert_vars(list);
	lvars item;
	
	if list == [] then vedinsertstring('NONE');
	else
		lvars wascomma = false;
		vedinsertstring(hd(list));
		for item in tl(list) do
			if item == "," then
				vedinsertstring(item);
				true -> wascomma;
				vedcharright()
			else
				vedinsertstring(item);
				unless wascomma then
					vedinsertstring(', ')
				endunless;
			endif;
		endfor;
		if listlength(list) > 1 then
			next_field('  Where  :');
			for item in list do
				unless item == "," then
					next_field('\s\s\s\s');
					vedinsertstring(item); vedinsertstring(' is a ???')
				endunless
			endfor;
		else
			vedinsertstring(' is a ???')
		endif;
	endif;
enddefine;

define lconstant vars_field(inorout, def_type, in_updater, args);
	if isproctype(def_type) then
		unless args == [] and in_updater then
			next_field(inorout);
			insert_vars(args);
		endunless;
	else
		;;; insert nothing, e.g. for mixin, or class, or ruleset definition.
	endif
enddefine;

define lconstant END_ERROR();
	mishap('GOT TO END OF FILE IN ved_procheader. Missing ";"??', [])
enddefine;

define ved_procheader();
	lvars vedargs, item,
		name = false,
		def_type = false,
		in_updater = false,
		arglist = [],
		results = [];
	lconstant def_start = 'def'<>'ine'; ;;; disguised

	dlocal vedargument, ved_search_state;

	if vedargument = nullstring then
		lvars
			repeater, item;

		;;; get heading from current line if possible
		vedcharright();	;;; in case at beginning of procedure
        ved_check_search(def_start, [back noembed]);

		lvars line = vedline;

		vedwordright();

		;;; get text item repeater
		incharitem(vedrepeater) -> repeater;

		;;; go past define_form indicators, words like
		;;; global, vars, constant, etc.
		repeat
			repeater() -> item;
			if item == termin then
				END_ERROR();
			elseif item = ":" then
				repeater() ->> item -> def_type;
			elseif item == "updaterof" then
				true -> in_updater;
			else
			quitunless
				(isinteger(item)
				or
					is_syntax_word(item))
			endif
		endrepeat;
		;;; should now be at procedure name
		[%
			;;; The name
			item;
			repeat
				repeater() -> item;
				if item == termin then
					END_ERROR();
				elseif item == ":" and def_type == "method" then
					;;; ignore this and next item
					repeater() -> item;
					repeater() -> item;
				endif;
			quitif(item == ";");
				if item == "(" or item == ")" or item == "->" or item == ","
				or not(is_syntax_word(item))
				then item
				endif;
		   	endrepeat %] -> vedargs;
		;;; now create vedargument string, inserting spaces as needed
		consstring(#|
				lvars lastitem = false;
				for item in vedargs do
					explode(item);
					unless is_syntax_word(lastitem) or item == "(" then `\s`; endunless;
					if item == ")" or item == "->" then false
					else item
					endif -> lastitem;
				endfor|#) -> vedargument;
		vedjumpto(line, 1);
		vedlineabove();
	else
		;;; argument gives procedure specification.
		parse_args(vedargument) -> vedargs;
	endif;

	;;; get rid of trailing semi-colon
	if vedargs matches [== ;] then
		allbutlast(1, vedargs) -> vedargs
	endif;

	unless vedargs matches ! [?name ( ??arglist ) -> (??results)]
	or vedargs matches ! [?name ( ??arglist ) -> ??results]
	or vedargs matches ! [?name ( ??arglist ) ]
	or vedargs matches ! [?name]
	then
		'???' -> name;
	endunless;
	
	vedlinebelow();
	vedpositionpush();
	dlocal vedbreak = false;
	vedinsertstring('/*');
	if isproctype(def_type) then
		next_field(
			if def_type == "method" then 'METHOD' else 'PROCEDURE'endif);
	else
		next_field(lowertoupper(def_type >< nullstring));
	endif;
	max(vedcolumn, 10) -> vedcolumn;
	vedinsertstring(': ');
	if in_updater then vedinsertstring('-> '); endif;
	vedinsertstring(vedargument);
	vars_field('INPUTS   : ', def_type, in_updater, arglist);
	vars_field('OUTPUTS  : ', def_type, in_updater, results);
	if isproctype(def_type) then
		next_field('USED IN  : ???');
	endif;
	next_field('CREATED  : '); ved_day();
	next_field('PURPOSE  : ???');
	vedlinebelow();
	if isproctype(def_type) then
		next_field('TESTS:');
		vedlinebelow();
	endif;
	vedlinebelow(); vedinsertstring('*/');
	vedlinebelow();
	vedpositionpop();
enddefine;

;;; Associate ENTER procheader with ESC !
define :ved_runtime_action;
	vedsetkey('\^[!', veddo(%'procheader'%));
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Oct 19 2001
	Changed vedbacklocate instruction to ved_back_search with "noembed", to
	fix bug reported by Mark Roberts.
	Also stopped it looping forever when it reaches the end of file.
--- Aaron Sloman, Feb 21 1998
	Generalised to include mixin, class, instance, method, ruleset, etc.
	Indicates updaterof with "->"
--- Aaron Sloman, Oct 24 1996
	As suggested by Toby Smith, modified to insert heading automatically

	* VED_PROCHEADER Help file created
--- Aaron Sloman, Oct 22 1996
	Added "???" after "is a"
--- Aaron Sloman, Oct 21 1996
	Simplified format when there's fewer than two args or
	fewer than two results.

CONTENTS

 define lconstant is_syntax_word(word);
 define lconstant parse_args(string)->list;
 define lconstant isproctype(def_type);
 define lconstant next_field(string);
 define lconstant insert_vars(list);
 define lconstant vars_field(inorout, def_type, in_updater, args);
 define ved_procheader();
 define :ved_runtime_action;

 */
