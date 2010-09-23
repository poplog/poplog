/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/getpointvec.p
 > Purpose:			Make available a "free list" mechanism for vectors
 >					Copied from $usepop/pop/x/pop/lib/Xpw/XpwPixmap.p
 > Author:          Aaron Sloman, Aug  4 2000 (see revisions)
 > Documentation:	Should go into HELP RCLIB
 > Related Files:	LIB rc_draw_points.p rc_draw_filled_polygon.p
 */


section;

compile_mode :pop11 +strict;

;;; Don't save vectors bigger than this for re-use?
;;; (Prevent memory leak)
global vars max_reusable_vector;

unless isinteger(max_reusable_vector) then 30 -> max_reusable_vector endunless;

;;; A property mapping integers N to lists of available vectors
;;; of length N
lconstant procedure vectab = newproperty([], max_reusable_vector, [], "tmpclr");

;;; Given a list, vector or shortvector, and an integer -n-: returns a
;;; vector and the number of groups of -n- integers in the vector
;;; attempts to free-list these vectors

define getpointvec(vec, n, closed) ->(nitems, vec);
	lvars
		len = length(vec),
		;
	unless isinteger(len / n ->> nitems) then
		mishap(vec, n, 2, 'Length of points list is not a correct multiple');
	endunless;

	lvars newlen = if closed then len fi_+ n else len endif;

	returnif(isvector(vec) and not(closed));

	;;; re-use or create a new vec
	explode(vec);
	if closed then
		;;; need to repeat the first n coordinates.
		lvars index;
		fast_repeat n times 0 endrepeat;
	endif;

	;;; always need a new vector
	if newlen > max_reusable_vector or (vectab(newlen) ->> vec) == [] then
		;;; No stored vector of this length, so create one
		consvector(newlen) -> vec;
	else
		;;; re-use an existing one
		sys_grbg_destpair(vec) -> (vec, vectab(newlen));
		fill(vec) -> vec;
	endif;
enddefine;

define freepointvec(vec);
	;;; restore vec to the free set if it is not too long.
	lvars vec, len = datalength(vec);
	
	if len fi_<= max_reusable_vector then
		;;; store the vector for re-use.
		;;; First get new pair, in case creating it causes a garbage
		;;; collection which could clear vectab

		lvars pair = conspair(vec,0);

		;;; now use it to store the vector at the front of the
		;;; list of vectors of this length
		vectab(len) -> fast_back(pair);
		pair -> vectab(len);
	endif;
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov 19 2000
	Altered to deal with possibility of GC being triggered while storing
	vector for reuse.
--- Aaron Sloman, Nov 16 2000
	newproperty argument changed to "tmpclr", so that the property
	is cleared on every garbage collection.
--- Aaron Sloman, Nov 16 2000
	Removed references to short vectors
--- Aaron Sloman, Aug 24 2000
	getpointvec changed so as to use the given vector if closed is false
	and it's a shortvec.
 */
