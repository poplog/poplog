/*  --- Copyright University of Sussex 1995.  All rights reserved. ---------
 >  File:           C.all/lib/obsolete/prefix.p
 >  Purpose:        Prefix specified identifiers, superseded by SECTIONS.
 >  Author:         S.Hardy, 1982 (see revisions)
 >  Documentation:  HELP * PREFIX, REF * SECTIONS
 >  Related Files:
 */

compile_mode:pop11 +strict;

section;

global vars syntax endprefix = pop_undef;

define global vars syntax prefix;
	lvars	prefix_prefix, prefix_store, prefix_word, prefix_temp,
			prefix_proglist;
	readitem() <> "_" -> prefix_prefix;
	newassoc([]) -> prefix_store;
	until (readitem() -> prefix_word, prefix_word == ";") do
		unless prefix_word == "," then
			prefix_prefix <> prefix_word -> prefix_store(prefix_word)
		endunless
	enduntil;
	proglist -> prefix_proglist;
	pop11_compile(
		pdtolist(
			procedure;
				if null(prefix_proglist) then return(termin) endif;
				dest(prefix_proglist) -> prefix_proglist -> prefix_word;
				if prefix_word = "endprefix" then return(termin) endif;
				prefix_store(prefix_word) -> prefix_temp;
				if prefix_temp then
					 prefix_temp
				else
					 prefix_word
				endif
			endprocedure));
	prefix_proglist -> proglist;
enddefine;

endsection;


/* --- Revision History ---------------------------------------------------
--- John Williams, Apr 28 1995
		Moved to C.all/lib/obsolete	(cf. BR isl-er.230).
--- John Gibson, Oct 10 1992
		Cleaned up
 */
