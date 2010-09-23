/* --- Copyright University of Sussex 1995.  All rights reserved. ---------
 > File:            C.all/lib/lib/facets.p
 > Purpose:         Semantic rule interpretation similar to Wood's LUNAR system
 > Author:          Roger Evans, Jun 1982 (see revisions)
 > Documentation:   HELP * FACETS
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

section;
/* variable facets to make "uses" work properly */
	global vars facets;    undef -> facets;
endsection;

sysunprotect("self");   /* SEE REVISION HISTORY */

section $-facets =>
		facet isfacet clearfacet
		semrule endsemrule
		packet endpacket
		ftrace unftrace ftraceall unftraceall
		facet_rules resetfacets self
		defgram endgram deflex endlex
		try_next_rule category literal gives is usedfor
;

global vars
		 facet_rules resetfacets isfacet clearfacet self
9      ( gives is)
macro  ( ftrace unftrace ftraceall unftraceall
		 defgram deflex try_next_rule category literal)
syntax ( facet semrule endsemrule usedfor endgram endlex packet endpacket)
;

vars   interp ffetch theproc thefacet findvarsinpatt readpattern pattvars
	   dotrace maccomm makepatt test_cat test_word set_test_proc
	   varlist varctrs getpattern undef_facet_val
;

sysunprotect("popexecute");

/* system value of a facet before interpretation */
"undef_facet_val" -> undef_facet_val;


/* clear down facet rules */
define resetfacets();
	[] -> facet_rules;
enddefine;

resetfacets();


/* RULE APPLICATION - Run through list of rules applying each one.
   Rules return true if successful, false if not */
define interp(tree, thefacet);
	vars rule;
	for rule in facet_rules do
		if rule(tree,thefacet) then return endif;
	endfor;
	mishap('No interpretation rule given for tree',[^tree])
enddefine;


/* FACET LOOKUP PROCEDURE - look up value in property FPROP. If its
   undefined, try interpreting rules to give value. If its STILL
   undefined set it to undef (hence, unless undef_facet_val == undef,
   rule interpretation is tried only once) */
define ffetch(tree,fprop,fname) -> result;
	fprop(tree) -> result;
	if result == undef_facet_val then
		interp(tree,fname);
		fprop(tree) -> result;
		if result == undef_facet_val then
			undef ->> result -> fprop(tree);
		endif;
	endif;
enddefine;


/* DECLARATION OF FACETS - declare and initialise facet variables. The value
   of a facet procedure is a closure of ffetch with the name of the facet
   (a word) and a property for storing values. Its updater is just the
   unpdater of the property */
define syntax facet;
	vars i p;
	until nextitem() == ";" do
		readitem() -> i;
		unless i == "," then
			sysSYNTAX(i,0,false);
			newproperty([],10,undef_facet_val,true) -> p;
			ffetch(%p,i%) -> valof(i);
			updater(p) -> updater(valof(i));
			i ->> pdprops(updater(valof(i))) ->  pdprops(valof(i));
		endunless;
	enduntil;
enddefine;

/* FACET IDENTIFICATION */
define isfacet(thefacet);
	isprocedure(thefacet) and
	(   pdpart(thefacet) == ffetch or
		(  pdpart(thefacet) == systrace and isfacet(frozval(1,thefacet))));
enddefine;

/* CLEARING FACET VALUES - clear down a facet ie reset the property */
define clearfacet(thefacet);
	vars p;
	unless thefacet.isfacet then
		mishap('NON-FACET GIVEN TO CLEARFACET',[^thefacet]);
	endunless;
	newproperty([],10,undef_facet_val,true) -> p;
	p -> frozval(1,thefacet);
	updater(p) -> updater(thefacet);
	pdprops(thefacet) -> pdprops(updater(thefacet));
enddefine;

/* RULE DEFINITION - new syntax words semrule and endsemrule for bracketing
   semantic rules. semrule compiles a rule into a procedure and adds it to
   the list of facet rules. Ie given a rule:

		semrule foo [...]
			<code>
		endsemrule;

   it does (approximately!):

		define P1(self,thefacet,theproc) with_props foo;
			unless self matches [...] then return(false) endunless;
			theproc();
			return(true);
		enddefine;

		define P2() with_props foo;
			<code>
		enddefine;

		[^^facet_rules ^(P1(%P2%))] -> facet_rules;
*/
define syntax semrule;
	vars popexecute; false -> popexecute;
	vars myname pattern, thevars, i, args p1 p2 retlab oklab;
	[theproc thefacet self] -> args;
	sysNEW_LABEL() -> retlab;
	sysNEW_LABEL() -> oklab;
	;;; build a procedure to test pattern and call rule if necessary
	readitem() -> myname;       ;;; get name
	readpattern() -> thevars;   ;;; get var names from pattern
	sysPROCEDURE(myname,3);
		sysNEW_LVAR() -> pattern;
		applist(args, sysVARS(%0%));
		applist(args, sysPOP);
		applist(thevars, sysVARS(%0%));
		pop11_comp_expr();                 ;;; compile the pattern
		sysPOP(pattern);
		if pop11_try_nextitem("usedfor") then
			/* optional facet restriction clause */
			/* facet name as argument */
			sysPUSH("thefacet");
			readitem() -> i;
			if i == "[" then
				/* compile a list and call member */
				valof("[")();
				sysCALL("member");
			else
				/* not a list - must be boolean proc - call it */
				sysCALL(i);
			endif;
			sysIFNOT(retlab);
		endif;
		sysPUSH("self");
		sysPUSH(pattern);
		sysCALL("matches");
		sysIFSO(oklab);
	sysLABEL(retlab);           /* rule not applicable */
		sysPUSH("false");
		sysGOTO("return");
	sysLABEL(oklab);            /* rule ok - call body */
		sysCALL("theproc");
		sysPUSH("true");
	sysLABEL("return");
	sysENDPROCEDURE() -> p1;

	/* compile rule body itself */
	sysPROCEDURE(myname,0);
		erase(pop11_comp_stmnt_seq_to("endsemrule"));
	sysLABEL("return");
	sysENDPROCEDURE() -> p2;

	/* now add to end of facet_rules */
	sysPUSH("popstackmark");
	sysPUSH("facet_rules");
	sysCALL("dl");
	sysPUSHQ(p1(%p2%));
	sysCALL("sysconslist");
	sysPOP("facet_rules");

enddefine;

/* read pattern (non-destructively - local proglist) and make a list of
   the variables in it - to be declared as local to rule */
define readpattern() -> pattvars;
	vars proglist list;
	listread() -> list;
	[] -> pattvars;
	findvarsinpatt(list);
enddefine;


define findvarsinpatt(pattern);
	vars e;
	define readword(t);
		if pattern == [] then
			if t then exitfrom(findvarsinpatt)
			else mishap('Unexpected end of pattern',[^myname]);
			endif;
		else dest(pattern) -> pattern;
		endif;
	enddefine;

	unless pattern.islist then return endunless;
	repeat forever
		if (readword(true)->>e) == "%" then
			until readword(false) == "%" do enduntil;
		elseif e == "?" or e == "??" then
			readword(false) -> e;
			unless lmember(e,pattvars) then e::pattvars -> pattvars endunless;
		elseif e.islist then
			findvarsinpatt(e);
		endif;
	endrepeat
enddefine;


/* TRACING SEMANTIC RULES

	Facets can be traced normally, but semantic rules have special tracing
macros FTRACE and UNFTRACE. FTRACE foo; causes the BODY procedure of rule
foo (ie the frozen argument in the rule procedure itself - see SEMRULE) to
be traced using DOTRACE. DOTRACE calls SYSTRACE, but not on the body itself
(which has no arguments or results). Instead the body is first wrapped up
in a procedure which does take arguments (the tree and the facet name) and
returns a result (the value of the facet, or NO VALUE ASSIGNED if none
was given). All this is purely cosmetic!
*/
define dotrace(p,n);
	vars temp v;

	procedure(l,f);
		p();
		frozval(1,valof(f))(l) -> v;
		if v == undef_facet_val then
			'NO VALUE ASSIGNED'
		else v
		endif;
	endprocedure -> temp;

	n -> pdprops(temp);
	systrace(self,thefacet,temp);
	erase(); /* get rid of the result */
enddefine;

/* trace named semantic rules */
define macro ftrace;
	vars i p pp;
	until (readitem() ->> i) = ";" do
		unless i == "," then
			for p in facet_rules do
				frozval(1,p) -> pp;
				if pdprops(pp) == i then
					dotrace(%pp,i%) -> frozval(1,p);
					quitloop;
				endif;
			endfor;
		endunless;
	enduntil;
enddefine;

/* trace all semantic rules */
define macro ftraceall;
	vars p pp;
	for p in facet_rules do
		frozval(1,p) -> pp;
		unless pdpart(pp) == dotrace then
			dotrace(%pp,pdprops(pp)%) -> frozval(1,p);
		endunless;
	endfor;
enddefine;

/* untrace named smenatic rules */
define macro unftrace;
	vars i p pp;
	until (readitem() ->> i) = ";" do
		unless i == "," then
			for p in facet_rules do
				frozval(1,p) -> pp;
				if  pdpart(pp) == dotrace
				and (frozval(1,pp) -> pp; pdprops(pp) == i) then
					pp -> frozval(1,p);
					quitloop;
				endif;
			endfor;
		endunless;
	enduntil;
enddefine;

/* untrace all semantic rules */
define macro unftraceall;
	vars p pp;
	for p in facet_rules do
		frozval(1,p) -> pp;
		if pdpart(pp) == dotrace then
			frozval(1,pp) -> frozval(1,p);
		endif;
	endfor;
enddefine;


/* USING FACETS IN LIB GRAMMAR - the macros defgram and deflex are
   basically the same, the few differences (due to different formats in
   lib GRAMMAR) are signalled by the switch SW. The type string is used for
   automatic semantic rule naming
*/
define macro defgram; maccomm("endgram",'g_'); enddefine;
define macro deflex; maccomm("endlex",'l_'); enddefine;

/* maccom builds the grammar/lexicon lists for GRAMMAR but also
   looks for semantic rules */
vars clever_test_cat;
define maccomm(sw,type);
	vars rule, head, i, varlist ctrs test_cat;
	newproperty([],5,1,true) -> ctrs;
	/* patch to make terminals ok in grammar - see clever_test_cat below */
	clever_test_cat -> test_cat;
	[%
	until pop11_try_nextreaditem(sw) do
		erase(pop11_need_nextitem("["));
		readitem() -> head;
		[% head;
		until pop11_try_nextreaditem("]") do
			if hd(proglist) == sw then
				mishap('mcb: MISSING CLOSING BRACKET: ' sys_>< sw
						<> ' EXPECTING ]', nil);
			endif;
			if sw == "endgram" then
				popval(exprread()) -> rule;
			else
				readitem() -> rule;
			endif;
			rule;

			if pop11_try_nextreaditem("semrule") then
				/* found semantic rule - build pattern based on syntactic rule
				   make up a name, put both on front of proglist and call
				   semrule procedure */
				getpattern(head,rule) -> varlist -> pattern;
				applist(varlist,set_test_proc(%sw,false%));
				[   ^(consword(type >< head >< ctrs(head)))
					^pattern;
					^^proglist] -> proglist;
				ctrs(head) + 1 -> ctrs(head);
				nonsyntax semrule();
			endif;
		enduntil;
		%];
	enduntil;
	%]
enddefine;

/* convert rule into pattern */
define getpattern(head,rule) -> varlist -> pattern;
	vars varlist varctrs;
	[] -> varlist;
	if rule.islist then
		newproperty([],5,1,true) -> varctrs;
		[^head ^^(makepatt(rule))];
	else
		[^head ^rule]
	endif -> pattern;
enddefine;

/* insert queries and restriction procedures into pattern - return list
   of variables so that maccomm can build restricton procs (set_test_proc)
*/
define makepatt(rule);
	vars x;
	if rule.islist then
		maplist(rule,makepatt);
	elseif rule.isword then
			"?", consword(rule >< varctrs(rule)), ":", "is"<>rule;
			varctrs(rule) + 1 -> varctrs(rule);
			unless lmember(rule,varlist) then
				rule :: varlist -> varlist;
			endunless;
	else
		rule
	endif;
enddefine;

/* RESTRICTION PROCEDURE BUILDING */
define test_cat(tree,cat);
	tree.islist and tree.hd == cat
enddefine;

define test_word(tree,word);
	tree == word;
enddefine;

/*  A CLEVER VERSION OF TEST-CAT FOR USE WITH LIB GRAMMAR

	This procedure is locally assigned to test_cat inside DEFGRAM (above).
	It assumes it has been built by set_test_proc to check a non-terminal
	symbol, and checks (by looking for the presence of a procedure in the
	valof its second argument) whether in fact it should be lexical.
	It redefines itself appropriately!!     RE 24/5/85
*/
define clever_test_cat(tree,cat);
	vars iscat;
	"is"<>cat -> iscat;
	if identprops(cat) /== undef and isprocedure(valof(cat)) then
		test_cat
	else
		test_word
	endif(%cat%) -> valof(iscat);
	iscat -> pdprops(valof(iscat));
	valof(iscat)(tree);
enddefine;

define set_test_proc(cat,sw,flag);
	vars iscat;
	"is"<>cat -> iscat;
	sysSYNTAX(iscat,0,false);
	/* flag says whether redefinition is ok - if true then dont */
	if flag and isprocedure(valof(iscat)) then return endif;
	if sw == "endgram" then test_cat else test_word endif(%cat%)
		-> valof(iscat);
	iscat -> pdprops(valof(iscat));
enddefine;


/* HELPFUL USER MACROS */

/* try_next_rule - force rule failure */
vars macro try_next_rule;
[;false;exitto($-facets$-interp);] -> nonmac try_next_rule;

/* declare categories - ie set up restriction procs for them */
define macro category;
	vars i sw;
	until (readitem()->i; i==";") do
		unless i == "," then
			set_test_proc(i,"endgram",false);
		endunless
	enduntil
enddefine;

/* declare literals (ie lexical categories) - different restriction proc */
define macro literal;
	vars i sw;
	until (readitem()->i; i==";") do
		unless i == "," then
			set_test_proc(i,"endlex",false);
		endunless
	enduntil
enddefine;


/* shorthands for assigning  values to SELF */
define 9 CAT gives FACET;
	FACET(CAT) -> FACET(self);
enddefine;

define 9 FACET is VAL;
	VAL -> FACET(self);
enddefine;


/* PACKET SYNTAX - packet/endpacket brackets provide a context which
   localises facet_rules to allow packets of rules (like Wood's facets).
   Packets have names - the local facet_rules for the packet is stored
   in the variable which is the packet name.
   eg:      packet foo;
				<body>
			endpacket;
   is the same as
			procedure();
				vars facet_rules;
				foo -> facet_rules;
				<body>
				facet_rules -> foo;
			endprocedure();
*/
define syntax packet;
	vars i;
	readitem() -> i;
	sysSYNTAX(i,0,false);
	unless valof(i).islist then [] -> valof(i) endunless;
	sysPROCEDURE(false,0);
		sysLOCAL("facet_rules");
		sysPUSH(i);
		sysPOP("facet_rules");
		erase(pop11_comp_stmnt_seq_to("endpacket"));
		sysPUSH("facet_rules");
		sysPOP(i);
	sysCALLQ(sysENDPROCEDURE());
enddefine;


endsection;


/*  --- Revision History ---------------------------------------------------
--- John Gibson, Jul 31 1995
		Added +oldvar at top
--- Simon Nichols, Nov  8 1990
		Changed mishap codes to lower case.
--- John Gibson, Aug 13 1989
		Replaced old sys- compiler procedures with pop11_ ones.
--- Richard Bignell, Jul 16 1986 - Added sysunprotect("self") so that if the
	facets package is used in conjunction with flavours package it will
	compile; this is necessary since flavours sysprotects "self". Any
	problems please report to richb.
--- Mark Rubinstein, May 16 1986 - altered -maccomm- so that it doesn't get
	into an infinite loop if a final ] is missing.
--- Mark Rubinstein, Feb 12 1986 - altered to use exprread instead of
	readexpression
--- Roger Evans, Jun  3 1985 - minor 'declaring variable' bug fixed.
--- Roger Evans, May 25 1985 - Modified to allow terminal symbols in grammar
	rules when using LIB GRAMMAR.
 */
