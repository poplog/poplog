/*  --- Copyright University of Sussex 1986.  All rights reserved. ---------
 *  File:           C.all/lib/lib/blocks/blocks.p
 *  Purpose:        part of the blocksworld demonstration
 *  Author:         Roger Evans 1983 ?(see revisions)
 *  Documentation:  TEACH * BLOCKS (only roughly relevant)
 *  Related Files:  LIB * HAND , files in $usepop/pop/lib/lib/blocks/
 *					also $usepop/pop/lib/demo/mkblocks (or VMS version)
 *					LIB * FACETS
 */

vars grammar,lexicon;
uses grammar;
uses facets;
resetfacets();

vars locof;
facet locof act refof pred res;

defgram
	[ vp [vloc loc]
			semrule partapply(act(vloc1),locof(loc1)) -> res(self); endsemrule
		 [locnp]
			semrule partapply(go_proc,locof(locnp1)) -> res(self); endsemrule
		 [vtr np]
			semrule partapply(act(vtr1),[%refof(np1)%]) -> res(self); endsemrule
		 [vtr]
			semrule partapply(act(vtr1),[default]) -> res(self); endsemrule
		 [vtrloc np loc]
			semrule partapply(act(vtrloc1),[%refof(np1),loc1%]) -> res(self);endsemrule
		 [vtrloc np]
			semrule [%'I don\'t know where you mean'%] ===>; endsemrule
		 [vtrloc loc]
			semrule partapply(act(vtrloc1),[default ^loc1]) -> res(self); endsemrule
		 [vlet np L_go]
			semrule partapply(act(vlet1),[%refof(np1)%]) -> res(self); endsemrule
		 [vpick np L_up]
			semrule partapply(act(vpick1),[%refof(np1)%]) -> res(self); endsemrule
		 [vput np L_down]
			semrule partapply(act(vput1),[%refof(np1)%]) -> res(self); endsemrule
		 [L_Help]
			semrule Help -> res(self); endsemrule
		 [L_bye]
			semrule Exit_proc -> res(self); endsemrule
	]

	[ loc [locnp]
			semrule locof(locnp1) -> locof(self); endsemrule
		  [L_to np]
			semrule to_proc(refof(np1)) -> locof(self); endsemrule
	]

	[ np [L_it]
			semrule .getlastblock -> refof(self); endsemrule
		 [det cn]
			semrule res(det1)(pred(cn1)) -> refof(self); endsemrule
	]

	[ cn [adj cn]
			semrule pred(adj1)::pred(cn1) -> pred(self); endsemrule
		 [bnoun]
			semrule [[?box isblock]] -> pred(self); endsemrule
		 [snoun]
			semrule [^(pred(snoun1))] -> pred(self); endsemrule
	]
endgram -> grammar;

deflex
	[vloc go     semrule go_proc -> act(self); endsemrule ]
	[vtr  open   semrule open_proc -> act(self); endsemrule
		  close  semrule close_proc -> act(self); endsemrule
		  get    semrule get_proc -> act(self); endsemrule
		  drop   semrule drop_proc -> act(self); endsemrule
		  let semrule drop_proc -> act(self); endsemrule
		  pick   semrule pick_proc -> act(self); endsemrule
		  put    semrule put_proc -> act(self); endsemrule ]
	[vtrloc move semrule move_proc -> act(self); endsemrule
			take semrule move_proc -> act(self); endsemrule ]
	[ vlet let   semrule drop_proc -> act(self);endsemrule ]
	[ vpick pick semrule pick_proc -> act(self); endsemrule ]
	[ vput put   semrule put_proc -> act(self); endsemrule ]
	[ locnp up   semrule [%Raise(%13%),false,false%] -> locof(self); endsemrule
			down semrule [%Down,false,false%] -> locof(self); endsemrule
			left semrule [%false,Across(%-num%),false%] -> locof(self); endsemrule
			right semrule [%false,Across(%num%),false%] -> locof(self); endsemrule ]
	[ det a   semrule a_proc -> res(self); endsemrule
		  an  semrule a_proc -> res(self); endsemrule
		  the semrule the_proc -> res(self); endsemrule ]
	[ adj big     semrule [big ?box] -> pred(self); endsemrule
		  large   semrule [big ?box] -> pred(self); endsemrule
		  little  semrule [little ?box] -> pred(self); endsemrule
		  small   semrule [little ?box] -> pred(self); endsemrule
		  red     semrule [hue ?box red] -> pred(self); endsemrule
		  blue    semrule [hue ?box blue] -> pred(self); endsemrule
		  green   semrule [hue ?box green] -> pred(self); endsemrule
		  yellow  semrule [hue ?box yellow] -> pred(self); endsemrule ]
	[bnoun block box brick thing one]
	[snoun table  semrule [?box istable] -> pred(self); endsemrule
		   hand   semrule [?box ishand] -> pred(self); endsemrule ]
	[L_go go] [L_Help help] [L_to to] [L_it it]
	[L_up up] [L_down down] [L_bye bye goodbye]
endlex -> lexicon;

setup(grammar,lexicon);

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov  9 1988 fixed previous fix to header information
--- Aaron Sloman, Sep  8 1987 fixed header information
 */
