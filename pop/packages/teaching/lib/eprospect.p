/*  --- Copyright University of Sussex 1995.  All rights reserved. ---------
 >  File:           C.all/lib/lib/eprospect.p
 >  Purpose:        EPROSPECTOR-like expert system framework
 >  Author:         Chris Mellish, Jan 1985 (see revisions)
 >  Documentation:
 >  Related Files:
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

;;; Set this variable TRUE to get extra chatty information
vars chatty; false -> chatty;

;;; Representation of probabilities
;;; Prior probabilities represent how probable a given fact is at the
;;; start. The system calculates probabilities for the particular case
;;; by starting with the prior probabilities
;;; PRIORPROB is given a value by PROCESS

vars priorprob;

define prob(fact) -> x;
	if present([^fact ?x]) then
	else priorprob(fact)->x
	endif
enddefine;

define updaterof prob(newp,fact);
	if present([^fact =]) then
		newp -> it(2)
	else
		add([^fact ^newp])
	endif;
enddefine;

;;; Asking a question

vars asked, conclude;

define ask(fact,system);
	vars p;
	vars i;
	unless member(fact,asked) then
		[to what extent do you believe ^fact (number between -5 and 5)?]=>
		readline() --> [?i];
		fact::asked -> asked;
		i / 5 -> i;
		priorprob(fact) -> p;
		if i >= 0 then p + i * ( 1 - p ) else (1 + i) * p endif -> p;
		conclude(fact, p, system)
	endunless
enddefine;

;;; Conclude a new probability value for some fact, and
;;; propagate the consequences to other facts
;;; The numbers are hairy, and only approximate what PROSPECTOR uses.
;;; I have relatively little confidence in them.

vars minlist, rm, askabout;

define conclude(fact,new_prob,system);
	vars rule, p1, p2, posweight, negweight, concl;
	vars z, odds, old_premise_prob, new_premise_prob, old_prob;
	if chatty then
		[^fact now has probability ^new_prob]=>
	endif;
	prob(fact) -> old_prob;
	for rule in system do
		if rule matches [??p1 ^fact ??p2 => ?posweight ?negweight ?concl] then
			prob(concl)/(1-prob(concl)) -> odds;
			minlist(1,[% for z in [^^p1 ^fact ^^p2] do prob(z) endfor %])
				-> old_premise_prob;
			new_prob -> prob(fact);
			minlist(1,[% for z in [^^p1 ^fact ^^p2] do prob(z) endfor %])
				-> new_premise_prob;
			old_prob -> prob(fact);
			if new_premise_prob /= old_premise_prob then
				odds * abs(new_premise_prob - old_premise_prob)/(1 - old_premise_prob) *
				(if new_premise_prob > old_premise_prob then posweight else negweight endif) -> odds;
				conclude(concl,odds/(1+odds),system)
			endif
		endif
	endfor;
	new_prob -> prob(fact)
enddefine;

;;; The main procedure to call. Give it a system (list of rules) and
;;; a list of prior probabilities. Note that database is set to []
;;; at the start.

vars priormemb;

define eprospect(system,priors);
	vars goals, questions, hypotheses, p, r, premises, concl;
	vars priorprob, asked;
	priormemb(%priors%) -> priorprob;
	[] ->> goals ->> questions -> hypotheses;
	[] ->> database ->> asked;
	;;; First of all, classify all facts into goals, questions and hypotheses.
	;;; Goals are facts with no conclusions, and questions are facts with no
	;;; supports. Hypotheses are all others.
	for r in system do
		r --> [??premises => = = ?concl];
		if member(concl,goals) then
		elseif member(concl,hypotheses) then
		elseif member(concl,questions) then
			rm(concl,questions) -> questions;
			concl::hypotheses -> hypotheses
		else
			concl::goals -> goals
		endif;
		for p in premises do
			if member(p,goals) then
				rm(p,goals) -> goals;
				p::hypotheses -> hypotheses
			elseif member(p,hypotheses) then
			elseif member(p,questions) then
			else
				p::questions -> questions
			endif
		endfor
	endfor;
	;;; Now investigate each goal in turn
	for p in goals do
		askabout(p,system,questions)
	endfor;
	[Hypotheses are:]=>
	syssort(
		[% for p in goals do [^p ^(prob(p))] endfor %],
		procedure x y; x(2) > y(2) endprocedure) =>
enddefine;


define askabout(fact,system,questions);
	vars r, premises, p;
	if chatty then
		[now trying to find out about ^fact]=>
	endif;
	if member(fact,questions) then
		ask(fact,system)
	else
		for r in system do
			if r matches [??premises => = = ^fact] then
				for p in premises do
					askabout(p,system,questions)
				endfor
			endif
		endfor
	endif
enddefine;

;;; Miscellaneous utilities

define priormemb(x,l);
	vars y;
	if l matches [== [^x ?y] ==] then
		y
	else 0.5
	endif
enddefine;

define rm(x,list);
	vars a, b;
	if list matches [??a ^x ??b] then
		[^^a ^^b]
	else
		mishap('cant remove from list',[^x ^list])
	endif
enddefine;

define minlist(n,l);
	if l == [] then n
	elseif hd(l) < n then minlist(hd(l),tl(l))
	else minlist(n,tl(l))
	endif
enddefine;


/* --- Revision History ---------------------------------------------------
--- John Williams, Aug  4 1995
		Now sets compile_mode +oldvar.
 */
