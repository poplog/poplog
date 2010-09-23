/*  --- Copyright University of Sussex 1995.  All rights reserved. ---------
 >  File:           C.all/lib/lib/rms.p
 >  Purpose:        Reason Maintenance System
 >  Author:         Chris Mellish and Bob Searle
 >  Documentation:  HELP * RMS
 >  Related Files:
 */

vars rmsfixcontra;

section rms

	rmsfixcontra        ;;; procedure for fixing contradictions
						;;; (default: RMSDEFFIXCONTRA)
	=>

	makenode            ;;; procedure for creating a RMS node
	justifynode         ;;; procedure for justifying a node
	rmscontradict       ;;; procedure for marking a node as a contradiction
	rmsdeffixcontra     ;;; default procedure for fixing a contradiction
	shownode            ;;; procedure for printing a node
	rmsnodeisin         ;;; tests whether a node is IN or not
;

;;;     initialization

vars rmscircles, rmscontraries, rmscheckcontra;

/*
	 these primitives manipulate the contents of nodes
		 see also: makenode, justifynode
	 nodes are structures with the following elements:
		 1 - node number (for printing)
		 2 - backlink to application structure
		 3 - current support depending on whether node is in
				 in - name of supporting justification
				 out - []
		 4 - list of justifications which could be used to support the node
		 5 - if <true> node is a contradiction
		 6 - list of nodes whose status (in/out) may depend on this node
		 7 - mark cell used in reason maintenance = 2 if node is suspected

*/
recordclass node nodeno backlink rmsnodesupport rmsnodejustif rmsnodeiscontra
 rmsnodedepend rmsnodemark;

procedure x; pr('<node'); pr(x.nodeno); pr('>') endprocedure
   -> class_print(key_of_dataword("node"));

define rmsnodesupp(anode);
   rmsnodesupport(anode)
enddefine;

define updaterof rmsnodesupp(just,anode);
	just -> rmsnodesupport(anode);
	rmscheckcontra(anode);
enddefine;

define rmsnodejust(anode);
   rmsnodejustif(anode)
enddefine;

define updaterof rmsnodejust(just,anode);
	[^just ^^(rmsnodejustif(anode))] -> rmsnodejustif(anode)
enddefine;

define rmsnodedep(anode);
   rmsnodedepend(anode)
enddefine;

define updaterof rmsnodedep(snode,node);
	unless member( snode, rmsnodedepend(node) ) then
		[ ^snode ^^(rmsnodedepend(node)) ] -> rmsnodedepend(node)
	endunless
enddefine;


define rmsnodeisin(anode);
	rmsnodesupp(anode) /== []
enddefine;

define rmscheckcontra(node);
	unless rmsnodeisin(node) then return endunless;
	if rmsnodeiscontra(node) then
		unless member(node,rmscontraries) then
			[^node ^^rmscontraries] -> rmscontraries;
		endunless
	endif
enddefine;



;;;     these primitives manipulate the contents of justifications
;;;      - a justification is a record with two fields (lists)
;;;      - the first sublist is the 'inlist', the second is the 'outlist'
;;;         for a justification to be valid (i.e. allow its referencing node
;;;         to be considered 'in'), all nodes on the 'inlist' must be in, and
;;;         all nodes on the 'outlist' must be out
;;;     see also rmsnodeisin, showjust

recordclass sljust slno inlist outlist;
vars slnum; 0 -> slnum;
procedure x; pr('<sl'); pr(x.slno); pr('>') endprocedure
   -> class_print(key_of_dataword("sljust"));


recordclass cpjust cpno conseq inhyps outhyps;
vars cpnum; 0 -> cpnum;
procedure x; pr('<cp'); pr(x.cpno); pr('>') endprocedure
   -> class_print(key_of_dataword("cpjust"));

define rmscptosl(cpjust) -> sljust;
	lvars anode;
	conssljust((slnum+1->>cpnum),[],[]) -> sljust;
	;;;cp-justifications are premis by default
	unless rmsnodeisin(conseq(cpjust)) then return endunless;
	for anode in inhyps(cpjust) do
		unless rmsnodeisin(anode) then return endunless;
	endfor;
	for anode in outhyps(cpjust) do
		if rmsnodeisin(anode) then return endif;
	endfor;
	;;; if we manage to get this far, the conditions are right for
	;;; establishing an sl-justification for this cp-justification
	mishap('cannot resolve cp justification',[^cpjust]);
enddefine;

define rmsjustinl(ajust);
	if ajust.issljust then
		inlist(ajust)                ;;;return sl-just in-list
	else
		inlist(rmscptosl(ajust))     ;;;extract in-list from cp-just
	endif;
enddefine;

define rmsjustoutl(ajust);
	if issljust(ajust) then
		outlist(ajust);                ;;;return sl-just out-list
	else
		outlist(rmscptosl(ajust))      ;;;extract out-list from cp-just
	endif;
enddefine;


;;;     utility primitives


define findassumptions(node) -> list;
	lvars anode, ajust;
	[] -> list;
	rmsnodesupp(node) -> ajust;
	unless rmsjustoutl(ajust) == [] then
		[^node ^^list] -> list;
	endunless;
	for anode in rmsjustinl(ajust) do
		[^^(findassumptions(anode)) ^^list] ->list;
	endfor;
enddefine;

define rmsdel(entry,list) -> newlist;
	if member(entry,list) then
		if entry = hd(list) then
			tl(list) -> newlist;
		else
			hd(list) :: rmsdel(entry,tl(list)) -> newlist;
		endif
	else
		list -> newlist;
	endif;
enddefine;

define setrmsdepend(node,just);
	lvars anode;
	for anode in rmsjustoutl(just) do
		node -> rmsnodedep(anode);
	endfor;
	for anode in rmsjustinl(just) do
		node -> rmsnodedep(anode);
	endfor
enddefine;

define marknodes(node);
	if rmsnodemark(node) = 2 then return endif;
	2 -> rmsnodemark(node);
	unless rmsnodedep(node) == [] then
		applist(rmsnodedep(node),marknodes)
	endunless
enddefine;

define checkjust(just) ->rmsstat;
	lvars anode, rmsstat;
	true -> rmsstat;
	for anode in rmsjustinl(just) do
		unless rmsnodeisin(anode) then false -> rmsstat endunless
	endfor;
	for anode in rmsjustoutl(just) do
		if rmsnodeisin(anode) then false -> rmsstat endif
	endfor
enddefine;

define checkjustmark(just) -> markval;
	lvars anode, markval;
	2 -> markval;
	for anode in [^^(rmsjustinl(just)) ^^(rmsjustoutl(just))] do
		if rmsnodemark(anode) = 2 then return endif
	endfor;
	if checkjust(just) then
		1 -> markval
	else
		0 -> markval
	endif;
enddefine;

define checknodemarksub(node) -> suppjust;
	lvars temp, foundmark, suppjust, ajust;
	false -> foundmark;
	[] -> suppjust;
	for ajust in rmsnodejust(node) do
		checkjustmark(ajust) -> temp;
		if temp = 1 then
			ajust -> suppjust;
			return
		elseif temp = 2 then
			true -> foundmark
		endif
	endfor;
	if foundmark then 'oops' -> suppjust endif
enddefine;

define checknodemark(node);
	lvars temp;
	unless rmsnodemark(node) = 2 then return endunless;
	checknodemarksub(node) -> temp;
	if temp = 'oops' then
		if member(node,rmscircles) then return endif;
		[^node ^^rmscircles] -> rmscircles;
	else
		0 -> rmsnodemark(node);
		temp -> rmsnodesupp(node);
	endif;
	applist(rmsnodedep(node),checknodemark);
enddefine;

define rmschase(node);
	lvars savecircles;
	marknodes(node);
	[] -> rmscircles;
	checknodemark(node);
	[] -> savecircles;
	while not( length(rmscircles) = length(savecircles) ) do
		rmscircles -> savecircles;
		[] -> rmscircles;
		applist(savecircles,checknodemark);
	endwhile;
	unless rmscircles == [] then
		mishap('circularity encountered',[ ^rmscircles ]);
	endunless;
enddefine;

define incheck(node,just);
	if checkjust(just) then
		unless rmsnodedep(node) == [] then
			rmschase(node);
		else
			just -> rmsnodesupp(node);
		endunless
	endif
enddefine;


;;;     user entries into rms

vars nodenum;       ;;; Holds number of last node created
0 -> nodenum;

define makenode(fact);
	consnode((nodenum+1->>nodenum),fact,[],[],false,[],0)
enddefine;

define justifynode(node,ins,outs);
	lvars anode, ajust;
	for anode in [^node ^^ins ^^outs] do
		unless anode.isnode then
			mishap('unknown node to justify',
				[^anode '::' justifynode(^node,^ins,^outs)])
		endunless;
	endfor;
	[] -> rmscontraries;
	conssljust((slnum+1->>slnum),ins,outs) -> ajust;
	ajust -> rmsnodejust(node);
	setrmsdepend(node,ajust);
	unless rmsnodeisin(node) then incheck(node,ajust) endunless;
	unless rmscontraries == [] then
		applist(rmscontraries,rmsfixcontra);
	endunless;
enddefine;

define rmscontradict(node);
	true -> rmsnodeiscontra(node);
enddefine;


define rmsdeffixcontra(node);
	lvars anode, bnode, nodel, cpnode, just;
	findassumptions(node) -> nodel;      ;;;get the culprits
	if nodel == [] then
		mishap('contradiction unresolved - no assumptions, node=',[^node]);
	endif;
	makenode("rmsfixcontra") -> cpnode;     ;;; create NOGOOD node
	justifynode(cpnode,[],[]);              ;;; force in as premise
	;;; I don't understand this bit
	nodel -> inlist(rmsnodesupp(cpnode));
	conscpjust((cpnum+1->>cpnum),node,nodel,[]) -> rmsnodesupp(cpnode);
	;;; make CP justification  for it
	;;; now that we have constructed a cp-justification,
	;;;     use it to justify each of the nodes on the assumptions' out-lists
	for anode in nodel do
		for bnode in rmsjustoutl(rmsnodesupp(anode)) do
			justifynode(bnode,[^cpnode ^^(rmsdel(anode,nodel))],
				[^^(rmsdel(bnode,rmsjustoutl(rmsnodesupp(anode))))]);
		endfor;
	endfor;
enddefine;

unless "rmsfixcontra".identprops == 0 and rmsfixcontra.isundef.not then
   rmsdeffixcontra -> rmsfixcontra
endunless;

;;;     display functions

define showjust(just);
	if just.issljust and just.inlist == [] and just.outlist == [] then
		pr('\t*premis*\n')
	else
		pr('\t');
		pr(just.inlist); pr('\t'); pr(just.outlist);
		pr(newline);
	endif
enddefine;

define shownodedep(nodel);
	if rmsnodedep(nodel) == [] then
		pr('*independent*\n')
	else
		pr('can affect: ');
		pr(rmsnodedep(nodel));
		pr(newline);
	endif
enddefine;

define shownode(anode);
	pr(anode);
	pr('\t');
	pr(anode.backlink);
	pr(newline);
	if rmsnodeisin(anode) then
		pr('\tIN\t');
		pr(rmsnodesupp(anode));
		showjust(rmsnodesupp(anode));
	else
		pr('\tOUT\n');
	endif;
	if rmsnodeiscontra(anode) then pr('\t\t***contradiction***\n') endif;
	pr(newline)
enddefine;

endsection;
