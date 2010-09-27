/*  --- Copyright University of Sussex 1986.  All rights reserved. ---------
 >  File:           C.all/lib/lib/labels.p
 >  Purpose:        For use with lib tetra and lib waltz.
 >  Author:         Aaron Sloman, Jan 1981 (see revisions)
 >  Documentation:  TEACH * WALTZ
 >  Related Files:  LIB * TETRA, *WALTZ.
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

;;; The function interpall, given a list of junctions, like that in lib tetra
;;; returns for each junction a list of possible interpretations, in the
;;; form of a set of line labels. The set of possible labels is defined
;;; by the patterns in the list rules, which is used non-locally by these
;;; functions

;;; ****    utility programs    ****

popconstruct;
true -> popconstruct;

vars chatty; true -> chatty;        ;;; used in report

define report(list);
	if chatty then list ==> endif;
enddefine;


;;; *** The list of giving possible labellings for each vertex type ***

vars rules;

	;;; for each type of junction specify possible interpretations
	;;; An interpretation is a set of labels for lines i.e. two points
	;;; Students will add information about ell arrow and fork junctions
[[[ell 1 2 3]
		[ ell1 [occ 2 1] [occ 1 3]]
		[ ell2 [occ 3 1] [occ 1 2]]
		;;; students may add additional information
 ]
 [[tee 1 2 3 4]
		[ tee1 [occ 1 2] [occ 4 1] [cnvx 1 3]]
		[ tee2 [occ 1 2] [occ 4 1] [cncv 1 3]]
		[ tee3 [occ 1 2] [occ 4 1] [occ 1 3]]
		[ tee4 [occ 1 2] [occ 4 1] [occ 3 1]]
 ]
 [[arw 1 2 3 4]
	[arw1 [occ 2 1] [cnvx 1 3] [occ 1 4]]
		;;; to be completed by students
 ]
 [[frk 1 2 3 4] ]   ;;; to be completed by students
] -> rules;



;;; ****    programs to build interpretations using rules ****

vars labelline buildinterp getinterps;      ;;; functions below

vars chatty;
true -> chatty;

define interpall(junctions);
	;;; given a list of junctions, make a list of possible interpretations
	;;; for each junction
	maplist(junctions,getinterps)
enddefine;

define getinterps (junc) -> interps;
	;;; given a junction, get a list of possible interpretations for it
	;;; use the global variable rules
	vars type points pointtypes possibilities;
	junc --> [junc ?type ??points];

	rules --> [ == [[^type ??pointtypes] ??possibilities] == ];

	unless length(points) = length(pointtypes)
	then    mishap(
				'wrong number of points in junc or interp',
				[^junc,[^type ??pointtypes]])
	endunless;

	[] -> interps;
	report([interpreting ^type ^^points]);

	until   possibilities = []
	do
		buildinterp(hd(possibilities),points) :: interps -> interps;
		tl(possibilities) -> possibilities;
	enduntil;

	report([found ^(length(interps)) interpretations for ^(hd(points))]);

	;;; stick the junction point at the front of the list of interps
	hd(points) :: interps -> interps
enddefine;

define buildinterp(pattern,points)->interp;
	;;; given a pattern, e.g. [ell1 [occ 2 1] [occ 1 3]]
	;;; and a list of points (of the appropriate number)
	;;; build an instance of the pattern using the points
	vars type list;
	hd(pattern) -> type; tl(pattern) -> list;
	[% type,
	  until list = []
	  do    labelline(hd(list), points);
		tl(list) -> list
	  enduntil%] ->interp;
	report([^interp legal for ^(hd(points))]);
enddefine;

define labelline(linepattern, points);
	;;; linepattern is something like [cnvx 1 3], points a list of points.
	;;; return a list containing the label and the corresponding points.
	;;; e.g. if points is [ p1 p2 p3] the result might be
	;;; [cnvx p1 p3]
	vars label point1 point2;
	linepattern --> [?label ?point1 ?point2];
	[%label, points(point1), points(point2)%]
enddefine;
-> popconstruct;
