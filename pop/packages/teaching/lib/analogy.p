/*  --- Copyright University of Sussex 1995.  All rights reserved. ---------
 >  File:           C.all/lib/lib/analogy.p
 >  Purpose:        illustrate the way EVAN's analogy program might work
 >  Author:         Jon Cunningham (see revisions)
 >  Documentation:  HELP * ANALOGY, TEACH *EVANS
 >  Related Files:  LIB * EVPICS
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

;;; this program illustrates the way EVAN'S ANALOGY program might work
;;; in addition, it shows how the same principles can be used for verbal
;;; comprehension analogy problems by providing a little dictionary

;;; initialise

turtle();
vars it matchgraph;
popconstruct;
true -> popconstruct;

;;; useful procedures

vars 9 ismemberof;
member -> nonop ismemberof;

define checkadd(item);
	unless present(item) then add(item) endunless
enddefine;

;;; procedures to findshapes in a turtle picture
define undraw(database);
	vars paint hence thence;
	space -> paint;
	foreach [line = ?hence ?thence] do
		jumpto(dl(hence));
		drawto(dl(thence))
	endforeach;
	jumpto(1,1)
enddefine;

define findtriangle();
	vars p1 p2 p3 lox loy hix hiy;
	while allpresent([[line hrz ?p1 ?p3]
				[line rht ?p1 ?p2][line lft ?p3 ?p2]]) do
		allremove(them);
		undraw(them);
		p1 --> [?lox ?loy];
		p2 --> [= ?hiy];
		p3 --> [?hix =];
		add([shape triangle [^lox ^loy ^hix ^hiy]])
	endwhile
enddefine;

define findsquare(square);
	vars p1 p2 p3 p4 lox loy hix hiy;
	while allpresent([[line hrz ?p1 ?p4][line vrt ?p1 ?p2]
				[line hrz ?p2 ?p3][line vrt ?p4 ?p3]]) do
		allremove(them);
		undraw(them);
		p1 --> [?lox ?loy];
		p3 --> [?hix ?hiy];
		add([shape ^square [^lox ^loy ^hix ^hiy]])
	endwhile
enddefine;

define findshapes();
	vars breaklines minlinelength;
	[] -> database;
	false -> breaklines;
	findlines();
	findtriangle();
	findsquare("square");
	2 -> minlinelength;
	findlines();
	findsquare("dot");
	foreach [line ==] do remove(it) endforeach
enddefine;

;;; procedures to make a graph description of a picture
define reltn(name1,name2,rel,type);
	add([^type ^name1 ^rel ^name2])
enddefine;

vars inside above rightof aboveright belowright biggerthan;
reltn(%"inside","spatial"%) -> inside;
reltn(%"above","spatial"%) -> above;
reltn(%"rightof","spatial"%) -> rightof;
reltn(%"aboveright","spatial"%) -> aboveright;
reltn(%"belowright","spatial"%) -> belowright;
reltn(%"biggerthan","size"%) -> biggerthan;

define area(area,type)->area;
	if type = "triangle" then area/2 -> area endif
enddefine;

define compare(name1,name2,size1,type1,size2,type2);
	vars xl1 xh1 yl1 yh1;
	vars xl2 xh2 yl2 yh2;
	vars xdif ydif;

	size1 --> [?xl1 ?yl1 ?xh1 ?yh1];
	size2 --> [?xl2 ?yl2 ?xh2 ?yh2];

	area((xh1-xl1)*(yh1-yl1),type1) -> size1;
	area((xh2-xl2)*(yh2-yl2),type2) -> size2;

	if 2*size1 > 3*size2 then
		biggerthan(name1,name2)
	elseif 2*size2 > 3*size1 then
		biggerthan(name2,name1)
	endif;

	[%xl1+xh1-xl2-xh2,yl1+yh1-yl2-yh2%] --> [?xdif ?ydif];

	if xl1 > xl2 and xh1 < xh2 and yl1 > yl2 and yh1 < yh2 then
		inside(name1,name2)
	elseif xl2 > xl1 and xh2 < xh1 and yl2 > yl1 and yh2 < yh1 then
		inside(name2,name1)
	else
		;;; find which quadrant shape2 is in relative to shape1
		xdif+ydif,ydif-xdif -> ydif -> xdif;    ;;; rotate axes
		if xdif>0 and ydif> 0 then
			above(name1,name2)
		elseif xdif < 0 and ydif < 0 then
			above(name2,name1)
		elseif xdif > 0 and ydif < 0 then
			rightof(name1,name2)
		elseif xdif < 0 and ydif > 0 then
			rightof(name2,name1)
		elseif xdif < 0 then
			aboveright(name2,name1)
		elseif xdif > 0 then
			aboveright(name1,name2)
		elseif ydif < 0 then
			belowright(name1,name2)
		elseif ydif > 0 then
			belowright(name2,name1)
		endif
	endif
enddefine;

define makegraph();
	vars name1 name2 size1 size2 type1 type2;
	foreach [shape ?type1 ?size1] do
		remove(it);
		gensym("shape") -> name1;
		add([shape ^type1 ^name1 ^size1]);
		add([^name1 isa ^type1])
	endforeach;
	foreach [shape ?type1 ?name1 ?size1] do
		remove(it);
		foreach [shape ?type2 ?name2 ?size2] do
			compare(name1,name2,size1,type1,size2,type2)
		endforeach
	endforeach;
	rev(database) -> database
enddefine;

;;; procedures to do the analogy problem by predicting the answer
vars pcopy;

define predict(a,b,c)->d;
	vars swapped g1un g2un database;
	matchgraph(a,b<>c) -> database -> g2un -> g1un, erase();
	pcopy(g2un) -> d
enddefine;

define pacopy(h);
	vars i j k;
	if h == [] then []
	else fast_front(h)->i;
		while present([?j ^i]) and present([^j ?k]) and not(i = k) do
			k -> i
		endwhile;
		if present([^i ?i]) then endif;
		i :: pacopy(fast_back(h))
	endif
enddefine;

define phcopy(h)->n;
	vars type n1 rel n2 rel2;
	if h matches [?type ?n1 ?rel ?n2] and present([^rel reversedto ?rel2]) then
		pacopy([^type ^n2 ^rel2 ^n1]) -> n
	else pacopy(h)->n
	endif
enddefine;

define pcopy(a);
	if a == [] then []
	else phcopy(fast_front(a)) :: pcopy(fast_back(a))
	endif
enddefine;

;;; dictionary definitions. Looking up a
;;; word will return a little database representing its meaning

vars dictionary;

	[
		[man [male sex person]
				[adult age person]]
		[woman
				[female sex person]
				[adult age person]]
		[boy
				[male sex person]
				[young age person]]
		[girl
				[female sex person]
				[young age person]]
		[child
				[young age person]]
		[person  [person isa person]]

		[stallion [male sex horse]
				[adult age horse]]
		[mare
				[female sex horse]
				[adult age horse]]
		[colt
				[male sex horse]
				[young age horse]]
		[filly
				[female sex horse]
				[young age horse]]
		[foal
				[young age horse]]
		[horse  [horse isa horse]]
	] -> dictionary;

define dict_lookup(word) -> net;
;;; look up a word in "dictionary", or invent a definition
	vars database;
	dictionary -> database;
	unless present([^word ??net]) then
		[[^word isa ^word]] -> net
	endunless
enddefine;

;;; procedures to carry out terminal dialogue and call the matching routines
define prlist(l);
	applist(l,spr);
enddefine;

define ask(question)->ans;
	repeat forever
		nl(1);
		prlist(question);
		readline() -> ans;
		if ans matches [?ans] then return endif;
		'answer must be a single word'.pr
	endrepeat;
enddefine;

vars yeslist nolist;
[y yes okay ok t true] -> yeslist;
[n no f false negative] -> nolist;

define askyesno(question)->bool;
	vars ans;
	ask(question) -> ans;
	if ans ismemberof yeslist then true -> bool
	elseif ans ismemberof nolist then false -> bool
	else askyesno([does ^ans mean yes or no]) -> bool;
		if bool then ans :: yeslist -> yeslist
		else ans :: nolist -> nolist
		endif
	endif;
enddefine;

define processpic(name);
	vars database pic picval;
	nl(2);
	ask([what is the name of picture ^name]) -> pic;
	if identprops(pic) == undef then
		dict_lookup(pic) -> database;
		pr('\nHere is the dictionary definition of '><pic><'\n')
	else
		valof(pic) -> picval;
		if picval.isprocedure then
			picval();
			display();
			findlines();
			findshapes();
			pr('the low level description of the picture is\n');
			prlist(database);
			if askyesno([save picture description in ^pic]) then
				database -> valof(pic)
			endif
		else
			picval -> database
		endif;

		makegraph();
		'\nHere is the symbolic description of the picture\n'.pr
	endif;
	database==>
	return(database)
enddefine;

define addunused(arcs,pic);
	vars arc;
	while arcs matches [?arc ??arcs] do add([^pic unused ^arc]) endwhile
enddefine;

define addforcings(force);
	vars node1 node2;
	while force matches [[?node1 ??rel ?node2] ??force] do
		if rel == [] then [matchedto] -> rel endif;
		if swapped then add([^node2 ^^rel ^node1])
		else add([^node1 ^^rel ^node2])
		endif
	endwhile
enddefine;

vars score;
define compgraph(g1,g2);
	vars g1unused g2unused swapped;
	matchgraph(g1,g2) -> force -> g2unused -> g1unused -> score;
	[] -> database;
	if swapped then g1unused,g2unused->g1unused->g2unused endif;
	addunused(g1unused,n1);
	addunused(g2unused,n2);
	addforcings(force)
enddefine;

define comppic(pic1,pic2,n1,n2)->database score;
	vars score;
	nl(1);
	prlist([comparing ^^n1 and ^^n2]);
	nl(1);
	compgraph(pic1,pic2);
	prlist([this is the description of the differences between ^^n1 and
			^^n2]);
	nl(1);
	database==>
enddefine;

define evans();
	vars database bestmatch difab;
	vars pic_a pic_b pic_c pic_d1 pic_d2 pic_d3;
	vars g1unused g2unused force;
	vars diffab diffcd1 diffcd2 diffcd3;
	vars score1 score2 score3;

	prlist([the name of a picture is either a procedure to draw the picture
			or a variable containing a database description (in the right
			format) of the picture]);
	processpic("A") -> pic_a;
	processpic("B") -> pic_b;
	nl(1);
	erase(comppic(pic_a,pic_b,[A],[B])) -> diffab;
	nl(2);
	processpic("C") -> pic_c;

	if askyesno([would you like me to predict the answer]) then
		prlist([i predict that the answer matches]);
		nl(1);
		predict(pic_a,pic_b,pic_c)==>
	endif;

	'\nNow need to see each of the alternatives for D\n'.pr;
	processpic("D1") -> pic_d1;
	processpic("D2") -> pic_d2;
	processpic("D3") -> pic_d3;
	erase(comppic(pic_c,pic_d1,[C],[D1])) -> diffcd1;
	erase(comppic(pic_c,pic_d2,[C],[D2])) -> diffcd2;
	erase(comppic(pic_c,pic_d3,[C],[D3])) -> diffcd3;
	prlist([Now the moment of truth]);
	until askyesno([are you ready]) do prlist([i am ready]) enduntil;

	erase(comppic(diffab,diffcd1,[the differences between A and B],
			[the differences between C and D1]) -> score1);
	erase(comppic(diffab,diffcd2,[the differences between A and B],
			[the differences between C and D2]) -> score2);
	erase(comppic(diffab,diffcd3,[the differences between A and B],
			[the differences between C and D3]) -> score3);
	nl(2);
	prlist([the difference
			of the differences score ^score1 ^score2 ^score3 respectively]);
	prlist([so the answer is]);
	sp(1);
	if score1 < score2 then
		if score1 < score3 then diffcd1 -> diffcd3; "D1".pr else "D3".pr endif
	elseif score2 < score3 then diffcd2 -> diffcd3; "D2".pr else "D3".pr
	endif;
	nl(2)
enddefine;

vars swapped;
vars finished expand combine;

define findnodes(graph)->database;
	vars arc database n1 n2;
	[] -> database;
	for arc in graph do
		if arc matches [= ?n1 = ?n2] then checkadd(n1); checkadd(n2) endif;
		if arc matches [?n1 = =] then checkadd(n1) endif
	endfor
enddefine;

define nodematches(nodes1,nodes2) -> database;
	vars m n1 n2 swapped;
	[] -> database;
	if length(nodes1) > length(nodes2) then
		true -> swapped;
		nodes1, nodes2 -> nodes1 -> nodes2
	else false -> swapped
	endif;
	add([node []]);
	for n1 in nodes1 do
		if n1 ismemberof nodes2 then nextloop endif;
		foreach [node ?m] do
			remove(it);
			for n2 in nodes2 do
				if n2 ismemberof nodes1 then nextloop endif;
				if swapped then
					unless [^n2 =] ismemberof m then
						add([node [[^n2 ^n1] ^^m]])
					endunless
				else
					unless [= ^n2] ismemberof m then
						add([node [[^n1 ^n2] ^^m]])
					endunless
				endif
			endfor
		endforeach
	endfor
enddefine;

define matchgraph(graph1,graph2);
	vars partials parts best rest newpartials;
	vars database nodes;

	if length(graph1) > length(graph2) then
		true->swapped;
		graph1,graph2 -> graph1 -> graph2
	else
		false -> swapped
	endif;

	nodematches(findnodes(graph1),findnodes(graph2)) -> database;

	foreach [node ?nodes] do
		remove(it);
		add({%3*(length(graph2)-length(graph1))+2*length(nodes),
				 graph1,graph2,[],[],nodes%})
	endforeach;
	database -> partials;
	[] -> database;

	until finished() do
		combine(expand(fast_destpair(partials)->partials))
	enduntil;
	fast_subscrv(1,parts),
	fast_subscrv(4,parts),
	rev(fast_subscrv(5,parts))<>fast_subscrv(3,parts),
	fast_subscrv(6,parts)
enddefine;

define finished();
	fast_front(partials) -> parts;
	return(fast_subscrv(2,parts) == [])
enddefine;

vars forcematch unforcedmatch;

define expand(best)->database;
	vars type type2;
	vars score, graph1, graph2, ugra1, forcings;
	vars ugra2, newforcings arc;
	vars n11 n21 n12 n22 rel rel2 arc2;
	explode(best) -> forcings -> ugra2 -> ugra1 -> graph2 -> graph1 -> score;
	fast_destpair(graph1) -> graph1 -> arc;
	rev(ugra2) nc_<> graph2 -> graph2;
	add({%score+5,graph1,graph2,arc::ugra1,[],forcings%});
	[] -> ugra2;
	until graph2 == [] do
		fast_destpair(graph2) -> graph2 -> arc2;
		if length(arc) == length(arc2) then
			if length(arc) == 4 then
				arc --> [?type ?n11 ?rel ?n12];
				arc2 --> [?type2 ?n21 ?rel2 ?n22];
				if unforcedmatch([^n11 ^n12],[^n21 ^n22]) then
					forcematch([^type ^rel],[^type2 ^rel2],[])
				elseif unforcedmatch([^n11 ^n12],[^n22 ^n21]) then
					forcematch([^type],[^type2],[[^rel reversedto ^rel2]])
				endif
			elseif length(arc) == 3 then
				if unforcedmatch([%fast_front(arc)%],[%fast_front(arc2)%]) then
					forcematch(fast_back(arc),fast_back(arc2),[])
				endif
			else
				forcematch(arc,arc2,[])
			endif;
		endif;
		arc2 :: ugra2 -> ugra2

	enduntil
enddefine;

define unforcedmatch(arc1,arc2);
vars a1 a2;
	while arc1 matches [?a1 ??arc1] and arc2 matches [?a2 ??arc2] do
		unless a1 = a2 or member([^a1 ^a2],forcings) then
			return(false)
		endunless
	endwhile;
	return(true)
enddefine;

define forcematch(arc1,arc2,force);
	vars forcings,a1,a2,l;
	length(forcings) -> l;
	force <> forcings -> forcings;
	while arc1 matches [?a1 ??arc1] and arc2 matches [?a2 ??arc2] do
		unless a1 = a2 or member([^a1 ^a2],forcings) then
			[^a1 ^a2]::forcings -> forcings
		endunless
	endwhile;
	add({%score+2*(length(forcings)-l),
			 graph1,graph2,ugra1,ugra2,forcings%})
enddefine;

define insert(partial);
	vars sc;
	vars p q;
	fast_subscrv(1,partial) -> sc;
	[] -> q;
	partials -> p;
	while not(p == []) and fast_subscrv(1,fast_front(p)) < sc do
		fast_back(p ->> q) -> p
	endwhile;
	if q = [] then partial :: partials -> partials
	else partial :: p -> fast_back(q)
	endif
enddefine;

define combine(new);
	vars partial;
	for partial in new do insert(partial) endfor
enddefine;

-> popconstruct;


/* --- Revision History ---------------------------------------------------
--- John Williams, Aug  3 1995
		Now sets compile_mode +oldvar;
 */
