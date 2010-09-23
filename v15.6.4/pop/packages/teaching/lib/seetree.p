/* --- Copyright University of Sussex 1993.  All rights reserved. ---------
 > File:           C.all/lib/lib/seetree.p
 > Purpose:        'Tree walking' interface to LIB * SHOWTREE
 > Author:         Roger Evans, Sep 1983 (see revisions)
 > Documentation:  HELP * SEETREE
 > Related Files:  LIB * SHOWTREE
 */
compile_mode :pop11 +strict;

uses showtree;

section;

vars
	seetree_command,
	seetree_message = false,

	;;; These are used by lib browseself_message
	seetree_root,
	seetree_snum,
	seetree_mlist,
	;

lvars slist, rtrow, rtcolumn;

define lconstant downnode(p);
lvars l p;
	showtree_node_daughters()(seetree_root) -> l;
	if islist(l) and not(null(l)) then
		[^slist ^seetree_snum] :: seetree_mlist -> seetree_mlist;
		l -> slist;
		if p == true then
			length(l)
		elseunless p then
			(length(l)+1) div 2
		else
			p
		endif -> seetree_snum;
	else
		vedscreenbell();
	endif;
enddefine;

define lconstant upnode();
	unless seetree_mlist == [] then
		dest(seetree_mlist) -> seetree_mlist -> seetree_snum;
		dl(seetree_snum) -> seetree_snum -> slist;
	else
		vedscreenbell();
	endunless;
enddefine;

define lconstant leftnode();
	unless seetree_snum == 1 then
		seetree_snum-1 -> seetree_snum;
	else
		vedscreenbell();
	endunless;
enddefine;

define lconstant rightnode();
	unless seetree_snum == length(slist) then
		seetree_snum+1 -> seetree_snum;
	else
		vedscreenbell();
	endunless;
enddefine;

;;; make sure box is on screen and wiggle cursor at it
define lconstant checkpoints(r, c1, c2);
	lvars r c1 c2;
	vedjumpto(r, c1); vedcheck();
	vedjumpto(r, c2); vedcheck();
enddefine;

define lconstant showbox(srow, frow, lcol, rcol);
	lvars srow frow lcol rcol;
	checkpoints(srow, lcol, rcol);
	checkpoints(frow, lcol, rcol);
	vedjumpto(srow, showtree_mid(lcol, rcol));
	vedwiggle(vedline, vedcolumn);
enddefine;

define lconstant do_seetree(tree);
	lvars tree;
	dlocal seetree_root seetree_mlist, slist, seetree_snum, rtrow, rtcolumn;
	showtree(tree);

	/* now provide our own character process loop */
	repeat;
		if isstring(seetree_message) then vedputmessage(seetree_message) endif;
		slist(seetree_snum) -> seetree_root;
		showbox(explode(showtree_node_location()(seetree_root)));
		seetree_command(vedgetproctable(vedinascii())) ();
	endrepeat;
enddefine;

newproperty( [ [% vedcharup,        upnode  %]
			   [% vedchardown,      downnode(%false%)  %]
			   [% vedchardownleft,  downnode(%1%)  %]
			   [% vedchardownright, downnode(%true%)  %]
			   [% vedcharleft,      leftnode  %]
			   [% vedcharright,     rightnode  %]
			   [% vedendfile,       exitfrom(%do_seetree%)  %]
			   [% vedrefresh,       vedrefresh  %]
			 ], 10, procedure; vedscreenbell() endprocedure, false)
	-> seetree_command;

define seetree(tree);
	lvars tree;
	dlocal seetree_mlist, slist, seetree_snum, vedstartwindow = vedscreenlength;
	[] -> seetree_mlist;
	[node1] -> slist;
	1 -> seetree_snum;
	vedobey(showtree_name, do_seetree(% tree %));
enddefine;

endsection;


/*  --- Revision History ---------------------------------------------------
--- John Gibson, Aug 31 1993
		Made default value of seetree_command prop be a procedure calling
		vedscreenbell (since latter is a variable).
--- John Gibson, Aug 24 1993
		Uses showtree instead of new_sh*owtree
--- John Gibson, Nov 12 1992
		Changed to use new_sh*owtree
--- John Gibson, Jul 23 1992
		Renamed rt, snum, mlist as top level vars seetree_root, seetree_snum
		and seetree_mlist
--- John Gibson, Jun 22 1992
		Got rid of local vedprocesstrap in do_seetree (unnecessary since
		vedobey now always runs its argument inside vedprocess).
		Also lconstant'ed, etc.
--- Mark Rubinstein, May 15 1986 - made public.
--- Mark Rubinstein, Dec  3 1985 - made all the status variables local to
	SEETREE and DO_SEETREE allowing for greater modularity if SEETREE is
	called recursively.
--- Mark Rubinstein, Nov 26 1985 - made SEETREE global.
--- Roger Evans, Jan 17 1985 - Slightly Modified for new version of SHOWTREE
 */
