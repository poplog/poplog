/*	--- Copyright University of Sussex 2008.  All rights reserved. ---------
 >	File:			C.all/lib/lib/schema.p
 >	Purpose:		planning demonstration program?
 >	Author:			Steven Hardy, June 1982 (see revisions)
 >	Documentation:	TEACH *SCHEMATA
 >	Related Files:
 */

#_TERMIN_IF DEF POPC_COMPILING

section;

uses database;
global vars same, missing, extra;

define scheck_select(N, S, R);
;;; returns as results all subsets of S with N elements missing
;;; and R added.
	lvars N S R;
	if N == 0 then
		;;; No more to remove - only one option
		S <> R
	elseunless S == [] then
		;;; First try removing first element
		scheck_select(N - 1, tl(S), R);
		;;; Then try removing some other element
		scheck_select(N, tl(S), hd(S) :: R);
	endif
enddefine;


define scheck(S);
;;; compare schema S against the current database
	lvars X, P, SS, S, N;
	dlocal database;
	if isprocedure(S) then
		S -> P -> S
	else
		procedure; true endprocedure -> P
	endif;
	for N from 0 to length(S) do
		;;; consider successively shorter subsets of S
		for SS in [%scheck_select(N, S, [])%] do
			;;; For all ways of matching this subset against DATABASE (if any)
			forevery SS do
				;;; If filter procedure happy, then quit
				if P() then quitloop(3) endif
			endforevery
		endfor
	endfor;
	;;; Compute SAME, MISSING and EXTRA
	them -> same;
	for X in same do if present(X) then remove(X) endif endfor;
	database -> extra;
	pattern_instance(S) -> database;
	for X in same do if present(X) then remove(X) endif endfor;
	database -> missing;
enddefine;


vars tracing; unless isboolean(tracing) then true -> tracing endunless;

define schoose(OPTIONS) -> RESULT;
;;; given a list of schema names, choose the best schema to fit the current
;;; database
	lvars THIS, SCORE, OPTIONS, RESULT;
	-1 -> SCORE;
	for THIS in OPTIONS do
		scheck(valof(THIS));
		if tracing then
			[%THIS, 'same =', length(same),
					'missing =', length(missing),
					'extra =', length(extra)%] =>
		endif;
		if length(same) / (length(same) + length(missing)) > SCORE then
			THIS -> RESULT;
			length(same) / (length(same) + length(missing)) -> SCORE;
		endif;
	endfor;
	scheck(valof(RESULT));
	if tracing then
		[best is ^RESULT] =>
		unless missing == [] then
			[this suggests] =>
			for THIS in missing do THIS => endfor
		endunless;
	endif;
enddefine;


endsection;


/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul  8 2008
		Changed "instance" to "pattern_instance"
--- John Williams, Jul 25 1994
		dlocal instead of vars in procedure scheck (cf. BR isl-fr.4553)
--- Andrew Law, Jul 22 1987 added correct documentation reference
 */
