/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/lib/generate_category.p
 > Purpose:			Extend LIB GRAMMAR by generalising generate
 > Author:          Aaron Sloman, Jun 16 1999
 > Documentation:	TEACH GRAMMAR, TEACH STORYGRAMMAR
 > Related Files:
 */

compile_mode :pop11+strict;

section;

uses grammar

define vars generate_category(category, grammar, lexicon);
	;;; given a grammar and a lexicon, generate an example of the
	;;; category, at random. The procedure subgen defined in
	;;; lib grammar uses the global variables Grammar and Lexicon
	;;; and the recursion depth indicator, Level.

	dlocal
		Grammar=grammar,
		Lexicon=lexicon,
		Level = 0;

	subgen(category)
enddefine;

endsection;
