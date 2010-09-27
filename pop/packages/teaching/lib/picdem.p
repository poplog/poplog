/* --- Copyright University of Sussex 1989. All rights reserved. ----------
 > File:            C.all/lib/lib/picdem.p
 > Purpose:			Demonstrates Some Problems of matching image descriptions
 > Author:          Aaron Sloman, Jul  8 1989 (see revisions)
 > Documentation:	TEACH * PICDEM
 > Related Files:	LIB * FINDLINES, * FINDJUNCS  TEACH * SEEPICTURE
 >					LIB * TURTLE, LIB * SCHEMA, TEACH * SCHEMATA
 */

#_TERMIN_IF DEF POPC_COMPILING

section;
;;; Loading library files if necessary
uses turtle;
uses findlines;
uses findjuncs;

loadlib("display");		;;; For printing pictures without numbers

if identprops("scheck") = undef then loadlib("schema") endif;


/* GLOBAL VARIABLES */

;;; A property for mapping descriptions (models) onto pictures from which
;;; they were derived
vars picofmodel = newproperty([], 20, false, true);

;;; A list of all the concepts learnt
vars allconcepts = [];

;;; Variable to control amount of trace printing
global vars chatty = true;

;;; A list of ordered junction types produced by findjuncs. They are
;;; ordered by decreasing complexity, to help with matching.
;;; The junction description for each figure will be stored with
;;; junction types in this order. However, if there are two or more
;;; junctions of a certain type (e.g. "ell") then their order will be
;;; arbitrary.
vars typelist; [jn8 jn7 jn6 jn5 jn4 kay crs arw tee ell end] -> typelist;

define highertype(type1,type2,order) -> result;
	;;; Does type1 come before type2 in the list "order"
	lvars type,type1,type1,order, result;
	if type1 == type2 then true -> result
	else
		fast_for type in order do
			if type == type1 then
				true -> result; return()
			elseif type == type2 then
				false -> result; return()
			endif
		endfor;
		mishap(type1, type2, 2, 'wrong types in junctiontype')
	endif
enddefine;


define newpoint(num) -> wd;
	;;; Generate a new point name, e.g."pt1", "pt2", "pt3"...
	;;; using -num- as the suffix
	;;; declare it as an identifier
	lvars wd;
	consword('pt' sys_>< num) -> wd;
	ident_declare(wd, 0, false);
enddefine;


define typeof(junc);
	;;; The first element of a junction description is its type.
	;;; Define a procedure for this, to allow a change of representation.
	lvars junc;
	junc(1)
enddefine;

define pointof(junc) -> pt;
	;;; The point defining the location of a junction is the second
	;;; element of its description. If the second element is unknown
	;;; use the third.
	lvars junc,pt;
	unless islist(junc) and listlength(junc) >= 3 then
		mishap(junc, 1, 'IMPROPER OBJECT USED AS JUNCTION DESCRIPTOR');
	endunless;
	junc(2) -> pt;
	if	pt=="?" then junc(3) -> pt endif
enddefine;

define junc_precedes(j1,j2) -> boolean;
	;;; For ordering junctions give priority to those whose junction-points
	;;; have already been used, i.e. replaced by variable names,
	;;; otherwise use the type of junction, guided by typelist.
	lvars p1 = pointof(j1), p2 = pointof(j2), j1, j2, boolean;

	if isword(p1) then
		not(isword(p2)) or p1(3) <= p2(3) -> boolean ;;; pt2 comes before pt5
	elseif isword(p2) then
		false -> boolean
	else
		highertype(typeof(j1), typeof(j2),typelist) -> boolean
	endif
enddefine;

define sortdata();
	;;; put junctions in decreasing order of complexity.
	syssort(database, junc_precedes) -> database;
enddefine;

define insertvar(name,num,list);
	lvars name,num,list;
	;;;e.g. insertvar("p3",4,[tee ? p1 [1 7] ? p2])
	;;; should alter the fourth element of the list so that it is
	;;;	[tee ? p1 ? p3 ? p2]
	;;; Used for updating database entries in -generalize-
	until num == 1 do
		back(list) -> list;
		num-1 -> num
	enduntil;
	conspair(name, back(list)) -> back(list);
	"?" -> front(list)
enddefine;

define getjuncs();
	;;; return a list of the junction entries, minus the word "junc"
	[%foreach [junc ==] do back(it) endforeach%]
enddefine;


vars firstlot;	;;; used in the pattern matcher

define generalize()-> model;
	lvars pt, num, newpt, model, pointnum = 1;
	dlocal firstlot;	;;; used in the pattern matcher
	dlocal database = [];

	findlines(); findjuncs();

	if chatty then
		pr('\nHere\'s the database:\n'); database ==>
	endif;

	;;; get rid of line information
	;;; and remove the word "junc" from the beginning of each item.
	getjuncs() -> database;
	if chatty then
		pr('\nHere\'s a simplified version of the database:\n');
		database ==>
	endif;

	;;; now put junctions in order of decreasing complexity
	sortdata();

	if chatty then
		pr('\nHere\'s the database re-ordered (most complex junctions first):\n');
		database ==>
	endif;

	;;; replace points by variables
	while present([??firstlot [= =] ==]) do
		listlength(firstlot) + 1 -> num;
		it(num) -> pt;
		pointnum -> picture(dl(pt));
		newpoint(pointnum) -> newpt;
		pointnum + 1 -> pointnum;
		if chatty then
			ppr(['  ( Replacing point [' ^pt ']\twith ?' ^newpt)]);
		endif;
		insertvar(newpt, num, it);
		foreach [??firstlot ^pt ==] do
			insertvar(newpt,(length(firstlot) + 1), it)
		endforeach;

		;;; If a ray from a previously marked point has now been marked,
		;;; then bring the junction at the end of that ray forward:
		unless num == 2 then sortdata() endunless;
		if chatty then
			pr('\nHere\'s the modified, reordered, database:\n'); database ==>
		endif;
	endwhile;

	database -> model;
enddefine;

define assign(name);
	;;; name is a word. the picture will be analysed.
	lvars name;
	;;; declare the name as an ordinary variable
	ident_declare(name, 0, false);
	;;; make the generalization of the current picture its valof.
	generalize() -> valof(name);
	pr(newline);
	;;; Show the picture
	display();
	pr('\nThe generalised model for '><name>< ' is\n');
	valof(name) ==>
enddefine;


define learn (list);
	;;; List contains a concept name followed by drawing instructions,
	;;;  e.g. learn([tri triangle(5)]);
	;;; If there are no drawing instructions, the current -picture- is used.
	lvars list,name, n, wd, found=false;
	destpair(list) -> list -> name;
	printf(name,'\nLearning %p\n');
	unless	list == []
	then
		unless lmember("newpicture",list) then turtle(); endunless;
		popval(list);
	endunless;
	assign(name);
	picture -> picofmodel(valof(name));
	unless allconcepts == [] then
		printf(name, '\nComparing %p with previously known concepts');
		for wd in allconcepts do
			printf(wd,'\nIs it like %p ?');
				if valof(wd) = valof(name) then
					true -> found;
					printf(wd,name,'\nYES %p is like %p\n');
				else printf(' -- No.');
				endif;
		endfor
	endunless;
	unless member(name,allconcepts) then
			[^^allconcepts ^name] -> allconcepts
	endunless;
	unless found then
		printf(name,'\nNo previous concept is like %p.\n')
	endunless;
enddefine;

define picof(model);
	lvars model;
	dlocal picture;
	picofmodel(model) -> picture;
	display();	;;; uses -picture- non-locally
enddefine;

define recognize(name,picname);
	lvars name, picname, schema=valof(name);
	printf(picname,'Examining picture for %p:\n');
	picofmodel(valof(picname)) -> picture;
	display();
	findlines();
	findjuncs();
	getjuncs() -> database;
	printf(picname,'\nHere is the description for %p:\n');
	database==>
	printf(name,'\nMatching it with the schema %p\n');
	schema ==>
	scheck(schema);
	if	same==[] then
		printf(name,picname, '%p has nothing in common with schema %p\n');
		return();
	endif;
	printf(name,picname,'\n%p has the following features in common with %p\n');
	same ==>
	unless extra == [] then
		printf(name,picname,
				'\nHere is stuff in %p not recognized by schema %p:\n');
		extra ==>
	endunless;
	unless missing==[] then
		printf(name,'\nHere are missing bits predicted by the schema %p:\n');
		missing ==>
	endunless;
	if extra == [] and missing == [] then
		printf(name,picname,'\n%p and %p are very similar concepts.\n');
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul  9 1989
	Tidied up, and re-did TEACH PICDEM accordingly
 */
