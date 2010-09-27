/*  --- Copyright University of Sussex 1995.  All rights reserved. ---------
 >  File:           C.all/lib/lib/emycin.p
 >  Purpose:        Simple EMYCIN-like control of production system
 >  Author:         C. Mellish, 1983 (see revisions)
 >  Documentation:  TEACH * EXPERTS
 >  Related Files:  LIB * EPROSPECT
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

vars cutoff; 0.2 -> cutoff;
vars chatty; true -> chatty;

;;; This system is designed for simple diagnosis/identification tasks
;;; involving attributes of a single object. The control structure and
;;; numerical calculations are a simplification of what happens in EMYCIN.
;;; This system needs to be extended to cope with:
;;;
;;;     - multiple conclusions
;;;     - more complex premises than simple conjunctions
;;;     - a "context" mechanism

;;; This is called by:
;;;
;;;     emycin(goal,system);
;;;
;;; where GOAL is a word naming the attribute to be discovered and
;;; SYSTEM is a list of production rules. Each rule is of the form
;;;
;;;     [premise ... => n conclusion]
;;;
;;; where n is a number giving the degree of confidence in the rule.
;;; Premises and conclusions are two element lists, giving attribute
;;; and value. Example rule:
;;;
;;;       [ [legs 4] => 0.5 [species dog] ]
;;;
;;; If there are no rules with conclusions about a given attribute, it is
;;; assumed that the system can ask the user about that attribute.

;;; Representation of knowledge about attributes
;;; The database contains a fact about each attribute of the unknown object.
;;; This takes the form of a list starting with the attribute name and
;;; continuing with the various hypotheses about possible values. The
;;; hypotheses are lists with two elements - the value and the certainty
;;; factor.
;;; Example database fact:
;;;
;;;  [height [short 0.3] [tall -0.4]]
;;;
;;; Certainties are accessed and updated with the procedure CERTAINTY

define certainty(attr,val)->x;
   if present([^attr == [^val ?x] ==]) then
   else 0 -> x
   endif
enddefine;

define updaterof certainty(cert,attr,val);
   vars x, y;
   if present([^attr ??x [^val =] ??y]) then
	  remove(it);
	  add([^attr ^^x [^val ^cert] ^^y])
   elseif present([^attr ??x]) then
	  remove(it);
	  add([^attr ^^x [^val ^cert]])
   else
	  add([^attr [^val ^cert]])
   endif
enddefine;

;;; Integrating a conclusion about a possible value of an attribute
;;; New certainty is in the simplest case  c1 + c2 - (c1*c2) where
;;; c1 is the old certainty and c2 is the certainty of the conclusion

define conclude(attr,val,newcert);
   vars oldcert;
   certainty(attr,val) -> oldcert;
   if oldcert > 0 and newcert > 0 then
	  newcert + oldcert - (newcert*oldcert)
   elseif oldcert < 0 and newcert < 0 then
	  newcert + oldcert + (newcert*oldcert)
   else
	  (oldcert+newcert) / (1 - min(abs(newcert),abs(oldcert)))
   endif
   -> certainty(attr,val);
   if chatty then
	  [the certainty of ^attr being ^val is now ^(certainty(attr,val))]=>
   endif
enddefine;

;;; Asking the user about the value of an attribute
;;; The user is expected to provide a certainty between -1 and 1
;;; The list FOUND records which attributes have already been found out about,
;;; to avoid repetition.

vars found; [] -> found;

define listpr(list);
   applist(list,spr)
enddefine;

define ask(ancestors,attribute);
   vars val, cert, rule, ruledone;
   [what is the ^attribute].listpr;
   readline() --> [?val];
   if val == "why" then
	  false -> ruledone;
	  for rule in ancestors do
		 if ruledone then
			[' 'which will allow me to use the rule:].listpr
		 else
			[I am trying to use the rule:].listpr;
		 endif;
		 true -> ruledone;
		 nl(1);
		 sp(5); rule.pr; nl(1)
	  endfor;
	  nl(1);
	  ask(ancestors,attribute);
	  return
   endif;
   [how sure are you (a number between -1 and 1)?] =>
   readline() --> [?cert];
   conclude(attribute,val,cert)
enddefine;

;;; The main procedures

vars findvalueof, findgoal;

define emycin(goal,system);
   vars x;
   [] -> database;
   [] -> found;
   findvalueof([],goal,system);
   if present([^goal ??x]) then
   else [] -> x
   endif;
   nl(2);
   [the hypotheses are]=>
   syssort(x,procedure x y; x(2) > y(2) endprocedure) =>
enddefine;

;;; Find the value of an attribute (don't return it as a result, but
;;; CONCLUDE it). The first argument of FINDVALUEOF is the list of
;;; currently active rules (most deeply embedded rule first).
;;; This is used for WHY explanations.

define findvalueof(ancestors,attribute,system);
   vars rules, rule, premise, premises, n, tally, attr, val, value;
   vars foundrule; false -> foundrule;
   if chatty then
	  [finding out about ^attribute]=>
   endif;
   if member(attribute,found) then
	  return
   endif;
   for rule in system do
	  if rule matches [??premises => ?n [^attribute ?value]] then
		 if chatty then
			[trying rule ^rule]=>
		 endif;
		 true -> foundrule;
		 1 -> tally;
		 for premise in premises do
			premise --> [?attr ?val];
			findvalueof([^rule ^^ancestors],attr,system);
			if certainty(attr,val) < cutoff then
			   if chatty then
				  [abandoning this rule for ^attribute]=>
			   endif;
			   nextloop(2)
			endif;
			min(tally,certainty(attr,val)) -> tally;
		 endfor;
		 conclude(attribute,value,tally*n)
	  endif
   endfor;
   unless foundrule then
	  ask(ancestors,attribute)
   endunless;
   attribute::found -> found
enddefine;


/* --- Revision History ---------------------------------------------------
--- John Williams, Aug  4 1995
		Now sets compile_mode +oldvar.
--- John Williams, Jan 30 1990
		Renamed -npr- to -listpr- (cf FR 4303)
 */
