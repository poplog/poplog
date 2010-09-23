/*  --- Copyright University of Sussex 1989.  All rights reserved. ---------
 >  File:           C.all/lib/lib/planet.p
 >  Purpose:        pop11 half of planet problem solver
 >  Author:         Roger Evans, November 1982 (see revisions)
 >  Documentation:  HELP *PLANET
 >  Related Files:  Prolog LIB *PLANET.PL
 */

#_TERMIN_IF DEF POPC_COMPILING

;;; planet - pop11/prolog planned execution package - R Evans

;;; an example of what a planet module should look like:

;;; module   in(room, thing);
;;;  given   input(thing),output(room),
;;;          adjacent(oldroom,room),in(oldroom, thing);
;;;   gain   in(room,thing);
;;;   lose   in(oldroom,thing);
;;;  using   room,thing,oldroom;
;;;
;;;       achieve finddoor(^oldroom,^room,?door);
;;;       move(thing,door);
;;;       open(door);
;;;       move(thing,room);
;;; endmodule;

uses prolog

sysunprotect("popexecute");

vars module,achieve;      ;;; stop macro expansion in prolog stuff if reloaded

:- prolog_language("top").   ;;; switch subsystem.
library(planet).
prolog_language("pop11").   ;;; back to pop

;;; lots of syntax stuff first

;;; getitems gets a sequence of items (defined by itemproc) separated by
;;; commas and terminated by closer - errors must be escaped using mishap
define getitems(itemproc,closer);
	[% while (itemproc(), pop11_try_nextreaditem(",")) do endwhile;
	   erase(pop11_need_nextitem(closer)); %]
enddefine;

;;; a quick word checker
define checkword(val);
	unless val.isword then
		mishap('Word needed',[^val]);
	endunless;
enddefine;

;;; get a word
define getword -> val;
	readitem() -> val;
	checkword(val);
enddefine;

;;; get a sequence of words
vars getwords; getitems(%getword,";"%) -> getwords;

;;; get the current prolog variable assigned to a word - assign one if not
;;; already given. pval is globally defined by module or achieve syntax word
;;; NOTE : this is used by module at compile time and achieve at runtime
vars pvals;
define getpval(argname) -> val;
	checkword(argname);
	unless dup(pvals(argname)) then
		erase();
		prolog_newvar();
	endunless ->> pvals(argname) -> val;
enddefine;



;;; a term is a prolog goal - a word followed possibly by an arg list.
;;; return the appropriate prolog predicate structure
vars getterms2;
define getterm(arg);
	lvars relname l;
	getword() -> relname;
	if relname == "fact" then
		erase(pop11_need_nextitem("("));
		getterm(false);
		erase(pop11_need_nextitem(")"));
		prolog_maketerm("fact",1);
	elseif arg and relname == """ then
		readitem();
		erase(pop11_need_nextitem("""));
	elseif pop11_try_nextreaditem("(") then
		getterms2() -> l;
		dl(l);
		prolog_maketerm(relname,listlength(l));
	elseif arg then
		getpval(relname)
	else
		relname
	endif;
enddefine;

;;; list of terms terminated by semicolon
vars getterms; getitems(%getterm(%false%), ";"%) -> getterms;
vars getterms2; getitems(%getterm(%true%),")"%) -> getterms2;


;;; the main module routine - must have a goal (a single term) and may have
;;; given,gain,lose clauses (all lists of terms). May then have a using
;;; clause(to pass parameters to pop) and them must have a (possibly empty)
;;; body.
vars syntax endmodule;

define syntax module;
	lvars pvals,locals;
	dlocal popexecute;
	;;; pvals holds the prolog variable assignments
	newproperty([],10,false,true) -> pvals;

	getterm(false),erase(pop11_need_nextitem(";"));                 ;;; goal
	if pop11_try_nextreaditem("given") then getterms() else [] endif, ;;; preconditions
	if pop11_try_nextreaditem("lose") then getterms() else [] endif,  ;;; losses
	if pop11_try_nextreaditem("gain") then getterms() else [] endif,  ;;; gains

	if pop11_try_nextreaditem("using") then
		getwords();
	else
		[]
	endif -> locals;            ;;; get the declared pop parameters



	false -> popexecute;
	;;; get a pop procedure
	sysPROCEDURE(false,length(locals));
	;;; declare and dereference params on entry
	applist(locals,sysVARS(%0%));
	applist(rev(locals), procedure(X);
							sysCALL("prolog_full_deref");
							sysPOP(X);
						 endprocedure);
	;;; get the body
	erase(pop11_comp_stmnt_seq_to("endmodule"));
	sysENDPROCEDURE();                                  ;;; the procedure

	maplist(locals,pvals);                               ;;; transfer vars

	;;; make all that into a prolog 'module' clause and assert it
	prolog_maketerm("module",6);
	unless prolog_invoke(prolog_maketerm("assert",1)) then
		mishap('module load failure',[]);
	endunless;
enddefine;

;;; calling planet - use the syntax word achieve followed by a goal term.
;;; a slight difference here - pop needs to make an input/output distinction
;;; output arguments are words (var names which must have been declared)
;;; preceded by "?". They are initialised to <ref undef> and are fully
;;; dereferenced on output - but may still be <ref undef> if they were not
;;; instantiated.

;;; getparam has to compile code to load the param value onto the stack as
;;; one element of the 'arg' list for sysachieve - if the arg is an output it
;;; compiles a call to getpval. It also returns the name of the output var.
define getparam();
	lvars word;
	if pop11_try_nextreaditem("?") then
		getword() -> word;
		sysdeclare(word);
		sysPUSHQ(word);
		sysCALL("getpval");  ;;; getpval(word)
		sysPUSHS(word);      ;;; ->>
		sysPOP(word);        ;;; word
		return(word);
	else
		pop11_comp_expr();
	endif;
enddefine;

;;; getparams plants code to make up list of all arg values. It also returns
;;; a list of the name s of the output variables
vars getparams; getitems(%getparam,")"%) -> getparams;


;;; planetexec actually executes the procedures planned. It flattens the
;;; list it is given (this saves prolog having to do appends all the time in
;;; making the list) and eventually applies the procedures - the format is
;;; [proc|args] where the args have been bound by prolog. NOTE : the procs
;;; given in a module dereference automatically
define planetexec(L);
	if L == [] then return
	elseif islist(L) then
		applist(rev(L),planetexec);
	elseif isprologterm(L) and prolog_predword(L) == "proc" then
		prolog_arg(1,L)(dl(prolog_arg(2,L)));
	else
		mishap('planetexec failed',[^L]);
	endif;
enddefine;


;;; actually does the achieve. The lists of args and output names are waiting
;;; on the stack - we need a pval for getval to use.
define sysachieve();
	lvars plist,args,outputs;
	sysconslist() -> outputs;
	sysconslist() -> args;
	;;; change to prolog predicate unless its an atom
	unless length(args) == 1 then
		prolog_maketerm(dl(args),listlength(args)-1) -> args
	else
		hd(args) -> args;
	endunless;
	prolog_newvar() -> plist;

	;;; call the prolog half to plan the goal - return list of procs plist
	unless prolog_invoke(prolog_maketerm(args,plist,[],"achieve",3)) then
		mishap('achieve failure',[]);
	endunless;

	;;; dereference and execute procs
	prolog_full_deref(plist) -> plist;
	planetexec(plist);
	;;; dereference output vars and finish
	applist(outputs, procedure(X);
						prolog_full_deref(valof(X)) -> valof(X);
					 endprocedure);
enddefine;


;;; achieve uses getparams to compile code to apps param values to sysachieve
;;; a call of
;;;         achieve in(?room1,theman());
;;; comes out as though it had been
;;;         popstackmark;
;;;         prolog_newvar() ->> valof("room1");
;;;         theman();
;;;         popstackmark;
;;;         sysachieve("in");
define syntax achieve;
	lvars outlist goal;
	dlocal popexecute;
	false -> popexecute;
	sysPROCEDURE(false,0);
	sysVARS("pvals",0);
	sysPUSHQ([]); sysPUSHQ(10); sysPUSHQ(false); sysPUSHQ(true);
	sysCALL("newproperty");
	sysPOP("pvals");
	[] -> outlist;
	getword() -> goal;
	sysPUSHQ(popstackmark);
	if pop11_try_nextreaditem("(") then
		getparams() -> outlist;
	endif;
	sysPUSHQ(goal);             ;;; predname is last arg.
	sysPUSHQ(popstackmark);
	applist(outlist,sysPUSHQ);
	sysCALL("sysachieve");
	sysPUSHQ(sysENDPROCEDURE());
	sysCALLS(undef);
enddefine;

define macro clearplanet;
	prolog_newvar();
	prolog_newvar();
	prolog_newvar();
	prolog_newvar();
	prolog_newvar();
	prolog_newvar();
	prolog_maketerm("module",6);
	prolog_invoke(prolog_maketerm("retractall",1));
	erase();
enddefine;

clearplanet      ;;; clear down modules if any.

/*  --- Revision History ---------------------------------------------------
--- John Gibson, Aug 13 1989
		Replaced old sys- compiler procedures with pop11_ ones.
--- Mark Rubinstein, Sep  5 1985 - changed subsystem change due to bug? in
	prolog consult mode?
--- Mark Rubinstein, Sep  4 1985 - inserted missing " around call to change
	subsystem.
--- Mark Rubinstein, Aug  9 1985 - changed location of prolog part PLANET.PL
--- Roger Evans, Aug  1 1985 modified to use prolog_maketerm etc.
 */
