
'\n======TESTING old define :rule syntax======\n' =>

vars XXX_rules = [];

define :rule XXX1 in XXX_rules
	[DLOCAL [cucharout = foo]]
	[VARS xxx1]
	[LVARS xxx2]
	[?xxx1 is ?xxx2]
	;
	[VARS xxx3]
	[?xxx1 ?xxx2 ?xxx3]
enddefine;

XXX_rules ==>


'\n======TESTING define :ruleset======\n' =>

define :ruleset;
	[VARS [v1 = 3, v1=>] [[v2 v3] = 10//3, v2=> v3=>] ];

RULE rr1 weight 5
	[a1][b1]
	[VARS [v1 = 3, v1=>] [[v2 v3] = 10//3, v2=> v3=>] v4]
	[c1]
		==>
	[c2]
	[VARS [v1 = 3, v1=>] [[v2 v3] = 10//3, v2=> v3=>] v4]
	[d2]

	vars p,q;

RULE rr2
	[c][d]
		==>
	[e]
enddefine;

prb_rules ==>


define :ruleset fred;
	[VARS [v1 = 3, v1=>] [[v2 v3] = 10//3, v2=> v3=>] v4];
	use_section = true;

	rule fred1
		[a][b]
		==>
		[c][d]

	rule fred2 weight 3.4
		[c][d]
		==>
		[e]
enddefine;


fred ==>

fred(4).datalist =>

'\n======TESTING global vars ======\n' =>

false -> prb_force_lvars;
vars testvar1;
lvars testvar2;

define :ruleset testglobal1;

RULE R1
	[?testvar1 ?testvar2 ?testvar3]
	==>
	[?testvar1 ?testvar2 ?testvar3]
enddefine;

testglobal1 ==>

true -> prb_force_lvars;
vars testvar4;
lvars testvar5;

define :ruleset testglobal2;
	[VARS testvar4];

RULE R1
	[VARS [testvar6 = 99]]
	[?testvar4 ?testvar5 ?testvar6]
	==>
	[VARS testvar7]
	[?testvar4 ?testvar5 ?testvar6]
	[?testvar7]
enddefine;

testglobal2 ==>



'\n======TESTING define :rulefamily======\n' =>


define :ruleset fred1 ;

	rule fred11 [a][b] ==> [c]

	rule fred12 [x] [y] ==> [c] [d]
enddefine;

fred1 ==>

define :ruleset joe1;

	rule joe11 [a][b] ==> [c]

	rule fred22 [x] [y] ==> [c] [d]
enddefine;

joe1 ==>

;;; trace prb_consrulefamily;

define :rulefamily vars fred;

	[VARS x [[y z] = 24//7] w];
	debug = true;
	use_section = true;

	ruleset: fred1
	ruleset: joe1
enddefine;

define :rulefamily vars fred;

	[LVARS x [[y z] = 24//7] w];
	debug = true;
	use_section = true;

	ruleset: fred1
	ruleset: joe1
enddefine;


fred ==>

fred.datalist =>

fred.prb_family_prop =>
fred.prb_family_prop.datalist ==>
(fred.prb_family_prop)("joe1")==>
(fred.prb_family_prop)("fred1")==>

appproperty(fred.prb_family_prop,
	procedure(key, val);
		[[key ^key][val ^val]] ==>
	endprocedure);

fred.prb_family_matchvars =>



'\n======TESTING define :rulesystem======\n' =>

;;; TEST EXAMPLES

define :ruleset rs1 ;

	rule rs11 [a][b] ==> [c]

	rule rs12 [x] [y] ==> [c] [d]
enddefine;

rs1 ==>

define :ruleset rs2;

	rule rs21 [a][b] ==> [c]

	rule fred22 [x] [y] ==> [c] [d]
enddefine;

rs2 ==>

define :rulefamily vars rf1;

	[VARS x [[y z] = 24//7] w];
	debug = true;
	use_section = true;

	ruleset: rs1
	ruleset: rs2
enddefine;

define :rulefamily vars rf1;
	[LVARS x [[y z] = 24//7] w];
	debug = true;
	use_section = true;

	ruleset: rs1
	ruleset: rs2
enddefine;


rf1 ==>


define :ruleset rs3;
	[VARS x [[y z] = destpair(q)] w];

	rule rs31 [a][b] ==> [c]

	rule rs32 [x] [y] ==> [c] [d]
enddefine;

rs3 ==>

define :ruleset rs4;

	rule rs41 [a][b] ==> [c]

	rule rs42 [x] [y] ==> [c] [d]
	rule rs43 [x y] ==> [do rs4] [c d]
enddefine;

rs4=>


define :rulefamily rf2;
	[LVARS xx yy];

	ruleset: rs3
	ruleset: rs4
enddefine;

rf2 ==>

define :rulesystem testrs;
	[DLOCAL [prb_walk = true]];
	cycle_limit = 4;
;;;;	use_section = true;		;;; not permitted.
	[LVARS [myself = sim_myself] [[myx myy]=sim_coords(sim_myself)]];

	include: rf1
	include: rs3
	include: rf2 with_limit = 5
enddefine;

testrs ==>

'\n======TESTING lvar scoping ======\n' =>


cancel global1 global2 lvar1 lvar2 lvar3;

vars global1, global2;

lvars lvar1 = "v1";

lblock;

lvars lvar2 = "v2";

endlblock;

lblock

lvars lvar3 = "v3";

define :ruleset scope;
	[VARS global1];

rule scope1
	[vars ?global1 ?global2 ?lvar1 ?lvar2 ?lvar3 ?lvar4]
	==>
	[vars ?global1 ?global2 ?lvar1 ?lvar2 ?lvar3 ?lvar4]

enddefine;

scope ==>
endlblock;

'\n======TESTING embedded WHERE or POP11 ======\n' =>

lvars xloc = 5, yloc = 6;

define :ruleset embed;

RULE rr1
	[a1][b1]
		==>
	[c2]
	[[a][b][WHERE xloc > yloc][POP11 xloc + yloc =>]]
	[d2]

enddefine;

embed ==>
vars aaa = prb_actions(embed(1));
aaa ==>
vars p1 = aaa(2)(3)(2);		;;; the WHERE procedure
p1() =>
8 -> xloc;
p1() =>
vars p2 = aaa(2)(4)(2);		;;; the embedded POP11 procedure
p2();
3 -> yloc;
p2() ;
