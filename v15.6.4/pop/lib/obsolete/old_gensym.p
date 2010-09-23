/*  --- Copyright University of Sussex 1993.  All rights reserved. ---------
 >  File:           C.all/lib/obsolete/old_gensym.p
 >  Purpose:        Old library
 >  Author:         Aaron Sloman, 1983 (see revisions)
 >  Documentation:  HELP * GENSYM
 */

#_TERMIN_IF DEF POPC_COMPILING

section;

uses gensym;	;;; use the new version

sysunprotect("gensym");

global vars procedure gensym;

procedure(w, property) with_props gensym;
	lvars w y property;
	check_word(w);
	property(w) -> y;
	y + 1 -> property(w);
	consword(w sys_>< y);
endprocedure(% gensym_property %) -> gensym;

procedure(y, w, property) with_props gensym;
	lvars y w property;
	check_word(w);
	unless isinteger(y) do
		mishap(y, w, 2, 'INTEGER NEEDED TO UPDATE GENSYM VALUE OF WORD')
	endunless;
	y -> property(w)
endprocedure(% gensym_property %) -> updater(gensym);

global constant old_gensym = true;

endsection;

/*  --- Revision History ---------------------------------------------------
--- John Gibson, Sep 22 1993
		Made it use variable gensym_property for the property and
		moved to lib/obsolete/old_gensym.p
 */
