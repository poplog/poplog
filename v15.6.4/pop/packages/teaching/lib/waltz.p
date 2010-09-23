/*  --- Copyright University of Sussex 1986.  All rights reserved. ---------
 >  File:           C.all/lib/lib/waltz.p
 >  Purpose:        line labelling and Waltz filtering
 >  Author:         Aaron Sloman, Jan 1981
 >  Documentation:  TEACH * WALTZ
 >  Related Files:  LIB * LABELS, *TETRA
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

;;; The function interpall in lib labels produces a line-labelling in the
;;; form of a list of junctions with possible interpretations. For details
;;; of format see lib labels.
;;; The function filter is given the result of interpall, and
;;; returns a filtered version. It repeatedly tries to prune possible
;;; interpretations from junctions by checking consistency, until nothing is
;;; left to be filtered out.

;;; ****    some utility programs   ****
popconstruct;
true -> popconstruct;
vars chatty; true -> chatty;

define report(list);
	if chatty then list ==> endif;
enddefine;


define sometrue(X,List,Pred)->result;
	;;; apply Pred to X and one element of List at a time, to see if at
	;;; least one result is TRUE. If so return TRUE, otherwise FALSE.
	until List==[] do
		if  Pred(X,hd(List))
		then    true -> result; return
		else    tl(List) -> List
		endif
	enduntil;
	false -> result
enddefine;

define otherpoint(point,line);
	;;; line is something like [label point1 point2]
	if  point=line(2)
	then    line(3)
	else    line(2)
	endif
enddefine;



;;; ****    procedures for doing the Waltz filtering    ****

vars consistent prune somebadlabel nointerp labelfitsinterp;

define filter(interps) -> interps;
	;;; interps is a list of points associated with possible
	;;; interpretations. Filter out impossible interpretations.
	;;; the format of interps is the list produced by interpall.
	vars list vertex new nochange;
	false -> nochange;
	until nochange do
		true -> nochange;   ;;; remains true if nothing is pruned
		;;; repeatedly chug down list of vertex interpretations,
		;;; trying to prune interpretations for each vertex
		interps -> list;
		until   list = [] do
			hd(list) -> vertex;
			report([pruning ^vertex]);
			if  (prune(vertex,interps) ->> new)
			then    false -> nochange;
				report([pruned to ^new]);
				delete(vertex,interps) -> interps;
				new :: interps -> interps;
			else    report([^(hd(vertex)) unchanged]);
			endif;
			tl(list) -> list;
		enduntil;
	enduntil;
enddefine;

define prune(vertex,interps) -> result;
	;;; vertex has a list of possible interpretations. Remove all those
	;;; not consistent with other vertices in interps.
	;;; return false if no pruning possible
	vars point labels list newinterp;
	false -> result;
	hd(vertex) -> point; tl(vertex) -> list;
	[] -> newinterp;
	until   list = []
	do  hd(list) -> labels;     ;;; hd(labels) is type
		;;; e.g. tee3 or ell2
		if somebadlabel(point, tl(labels), interps)
		then    true -> result  ;;; i.e. pruning done
		else    labels :: newinterp -> newinterp;
			;;; i.e. reuse one interpretation
		endif;
		tl(list) -> list
	enduntil;
	if result then point :: newinterp -> result endif
enddefine;

define somebadlabel(point,labels,interps);
	;;; at least one of the labels associated with point lacks a
	;;; consistent interpretation at the opposite vertex
	sometrue(point,
		labels,
		procedure(point,label);
			nointerp(label, otherpoint(point,label), interps)
		endprocedure)
enddefine;

define nointerp(linelabel,neighbour, interps);
	;;;false if at least one interpretation of the neighbour
	;;; is consistent with the linelabel
	vars list ;
	interps --> [ == [^neighbour ??list] == ];
	not(sometrue(linelabel, list, labelfitsinterp))
enddefine;

define labelfitsinterp(linelabel,interp);
	;;; given a label, check that at least one element of interp is
	;;; consistent with it
	sometrue(linelabel, tl(interp), consistent)
enddefine;

define consistent(line1,line2);
	;;; given two lines defined by a label and two points, make sure
	;;; they are consistent. If the label is "occ" the points must be
	;;; in the same order. Otherwise they may be reversed
	vars label;
	if  line1 = line2
	then    true
	else    hd(line1) -> label;
		label /= "occ"
	and hd(line2) = label
	and rev(tl(line2)) = tl(line1)
	endif
enddefine;
-> popconstruct;
