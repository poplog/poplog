/*  --- Copyright University of Sussex 1986.  All rights reserved. ---------
 >  File:           C.all/lib/lib/rmsapps.p
 >  Purpose:        Appendix B       RMS APPLICATIONS SUPPORT LAYER
 >  Author:         Chris Mellish and Bob Searle
 >  Documentation:  HELP * RMS
 >  Related Files:  LIB * RMS
 */

#_TERMIN_IF DEF POPC_COMPILING


vars nodes;         ;;; list of all RMS nodes
[] -> nodes;

define showinnodes();
	lvars node;
	for node in nodes do
		if rmsnodeisin(node) then
			shownode(node)
		endif
	endfor;
enddefine;

define showoutnodes();
	lvars node;
	for node in nodes do
		unless rmsnodeisin(node) then
			shownode(node)
		endunless
	endfor;
enddefine;

define shownodes();
	applist(nodes,shownode)
enddefine;

define declare(x) -> node;
	makenode(x) -> node;
	node::nodes -> nodes
enddefine;

define assert(x,j1,j2) -> node;
	declare(x) -> node;
	justifynode(node,j1,j2);
enddefine;

define premise(x);
	assert(x,[],[]);
enddefine;
