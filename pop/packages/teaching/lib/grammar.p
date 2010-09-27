/*  --- Copyright University of Sussex 1995.  All rights reserved. ---------
 >  File:           C.all/lib/lib/grammar.p
 >  Purpose:        Natural Language parser library.
 >	Author:			Aaron Sloman, 2 Dec 1979 (see revisions)
 >  Documentation:  HELP * GRAMMAR
 >  Related Files:
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;


vars Instance;
if Instance.isprocedure then [] -> proglist endif;
;;; Aaron Sloman        2 Dec 1979

;;;The function setup takes a grammar and a lexicon and produces a
;;; parser, or, more precisely, a set of parsing functions,
;;; each of which takes a list of text and produce a parse tree or false.
;;; They are all closures of the function Parse.
;;; Parse is reasonably efficient, but unfortunately only the first acceptable
;;; parse tree is produced. Thus ambiguity cannot be handled.
;;; Parse checks for infinite recursion, so both left and right recursion
;;; are allowed.
;;; However, for efficiency, no "null" non-terminals are allowed:
;;; they can be handled by an extra entry in the grammar, instead.
;;; This allows the program easily
;;; to set lower bounds on the length of an acceptable text string,
;;; and aids efficiency.

;;; The format of the grammar and the lexicon are illustrated in the
;;; samples given below.
;;; Note that the same word can occur in several lexical categories.

;;; A grammar is a list of rules, each of which is a list containing
;;; a non-terminal and a list of formats.
;;; Each entry in each format is either the name of a rule, or the
;;; name of a lexical category, or a lexical item, e.g. a preposition.
;;; For instance, one of the formats for the rule
;;; named "vp" (verb phrase) might be
;;;     [pv that vp]
;;; where "pv" is the name of a lexical category - "propositional verbs"
;;; "that" is a vocabulary item (since it is neither a rule name nor a
;;; name of a lexical category)
;;; and "vp" is a rule name.
;;; The setup program works out which is what.

;;; The lexicon is a list of lists, each of which starts with the
;;; name of a lexical category, and is followed by words of that category,
;;; e.g.    [pv thought believed hoped]

;;; After the function setup has been given the grammar and the lexicon
;;; a set of functions will be made available, one for each lexical
;;; category and one for each rule type. If a function of the former
;;; type is given a word as argument it returns either false, or a
;;; list suitable for building into a parse tree, e.g.:
;;; pv("thought")   returns [pv thought]

;;;The second type of function returns a parse tree
;;; : s([john liked the girl]) =>
;;; **[[s [np [qn [noun john]]] [vp ............]]]
;;; etc.


;;; Two sample grammars are given - grammar1 and grammar2, the latter being
;;; more complex. They are to be found in [pop.lib]grammar1, and
;;; [pop.lib]grammar2.p
;;; These grammars are based on ideas of Steve Hardy and Gerald Gazdar.
;;; extended by Aaron Sloman
;;; The lexicon is to be found in [pop.lib]lexicon.p



vars donouns;
false -> donouns;   ;;; if made true, then unknown words will be
			;;; treated as nouns

define Instance(Rule);
	;;; Instantiate a rule produced by transform, below.
	;;; Used for output from Parse
	;;; given something like [??x1:ng ??x2:vg] produce [^x1 ^x2]
	lvars Wd;
	[%until Rule==[] then
		destpair(Rule) ->Rule->Wd;
		if  Wd=="??" or Wd=="?"
		then    valof(destpair(Rule)->Rule);
			if  not(atom(Rule))
			and front(Rule)=":"
			then    back(back(Rule))-> Rule
			endif
		else Wd
		endif
	enduntil%]
enddefine;

vars Calls;
[] -> Calls;
				;;; used in Parse to detect infinte recursion.

define Parse(_L, Wd, List);
	;;; _L is a list of text to be Parsed,
	;;; Wd is the name of a non-terminal grammatical category
	;;; List is a list of Patterns for instances of the category
	;;; The variables x1 x2 -- x9 are for use in rules, created by setup.
	vars Pattern x1 x2 x3 x4 x5 x6 x7 x8 x9 Calls Size Temp;


	if  _L == []
	then    return(false)   ;;; don't allow empty productions
	endif;

	length(_L) -> Size;  ;;; Length of given text string.

	Calls -> Temp;
	until Temp == [] do
		if front(front(Temp)) == Wd then
			if back(front(Temp)) == Size then
				;;; infinite recursion, potentially, so stop
				return(false)
			else quitloop
			endif;
		else back(Temp) -> Temp
		endif
	enduntil;

	conspair(conspair(Wd, Size),Calls) -> Calls;
		;;; record type of rule, and length of text string - to be checked
		;;; in recursive calls of Parse.

	;;; try matching the text against the List of rule formats
	until List==[]
	then    destpair(List) -> List -> Pattern;
			;;; set lower bound on acceptable text length
		if  front(Pattern) <= Size
		and (back(Pattern) -> Pattern; _L matches Pattern)
		then    return(Wd::Instance(Pattern))
			;;; return Parse tree
		endif
	enduntil;
	false
enddefine;


vars Wdprops;

newproperty([], 101, [], true) -> Wdprops;


define setup(Grammar,Lexicon);
	;;;For each word in the Lexicon associate its syntactic categories with it
	;;;using MEANING
	;;; Similarly for each rule type in the Grammar
	;;;Check that nothing has been used as both lexical category and non-terminal
	vars Wd,Lexicon;
	for Wd in Grammar do
		front(Wd) -> Wd;   ;;; the grammatical category
		if Lexicon matches [== [^Wd ==] ==]
;;;;        until Lexicon==[] then
;;;;            if  front(destpair(Lexicon) -> Lexicon)==Wd
			then    mishap(0, Wd >< ' is in both lexicon and grammar')
			endif
;;;;        enduntil
	endfor;
	;;; now clear the Wdpropss:
	vars List;
	for List in Lexicon do
		vars wd;
		for wd in back(List) do [] -> Wdprops(wd) endfor;
		"terminal" ->Wdprops(front(List));
	endfor;

	;;; now put relevant information about each lexical entry in its Wdprops
	for List in Lexicon do
		vars Wd;
		destpair(List) -> List -> Wd;
			vars x,y;
			for x in List do
				Wdprops(x) -> y;
				if  y == []
				then    Wd
				elseif  isword(y)
				then    [%Wd, y%]
				else    Wd::y
				endif -> Wdprops(x)
			endfor;
	endfor;

	;;; prepare the Wdpropss of all the rule names
	for List in Grammar do
			"rule" -> Wdprops(front(List))
	endfor;

	;;; a List of variable names for use in transformed rules
	vars Vlist;
	[ x1 x2 x3 x4 x5 x6 x7 x8 x9] -> Vlist;
	vars x1 x2 x3 x4 x5 x6 x7 x8 x9;

	define trydest(List);
		;;; used in transform to check that there are enough pattern variables available.
		if List==[]
		then    mishap(Rule,1,'rule too long')
		else    destpair(List)
		endif
	enddefine;

	define transform(Rule);
		;;; given a Rule something like [ng prep ng]
		;;; produce a Pattern  [3 ??x1:ng ?x2:prep ??x3:ng]
		;;;I.e. a list containing the number of rule elements, followed
		;;; by transformed rule elements.
		;;; The number is used as lower bound for acceptable string
		;;; produce "?" for terminal categories
		;;; produce "??" for non-terminal Rule names
		vars Vlist,Wd,type;
		length(Rule) ::
		[%for Wd in Rule do
			Wdprops(Wd) -> type;
			if  type == "rule"
			then    "??", trydest(Vlist) -> Vlist, ":", Wd;
			elseif  type=="terminal"
			then    "?", trydest(Vlist) -> Vlist, ":", Wd;
			else    Wd
			endif
		endfor%]
	enddefine;


	;;; define a function corresponding to each rule name
	vars List,Wd;
	for List in Grammar do
		destpair(List)->List -> Wd;
		;;; Wd is now the rule name, List the list of formats.
		;;; Declare the variable, and assign a closure of Parse to it.
		unless isword(Wd) then
			mishap('NON-WORD GIVEN AS NON-TERMINAL IN GRAMMAR',[^Wd,^List])
		endunless;
		popval([vars %Wd%;]);
		Parse(%Wd, maplist(List,transform)%)
				-> valof(Wd);
		Wd -> pdprops(valof(Wd));
	endfor;

	define check(Wd, Type);
		;;;given a Wd and a terminal category check if the word is of that type
		;;; If so, return a suitable chunk of parse tree.
		vars List;
		Wdprops(Wd) -> List;
		if  Type == List
		or  (not(atom(List)) and member(Type,List))
		or  (donouns and Type == "noun" and atom(List))
		then    [%Type, Wd%]
		else
				false
		endif
	enddefine;

	for List in Lexicon do
		front(List) -> Wd;
		popval([vars ^Wd;]);
		check(%Wd%) -> valof(Wd);
		Wd -> pdprops(valof(Wd))
	endfor;
enddefine;

define macro ---;
	;;; altered to work with load marked range. A.S. June 1987
	dlocal popnewline = true;
	lvars item;
	[% until (readitem()->> item) == newline or item == termin do item
		enduntil%] -> item;
	dl([if s( ^item ) .dup then ==> else => endif; ])
enddefine;


;;; Now some functions for generating sentences at random given a grammar and a lexicon.
;;; generate(grammar,lexicon) will produce a list of words from the lexicon
;;; forming a sentence according to the grammar, which is assumed to use "s" as
;;; the non-terminal name for sentences. Recursion is controlled by maxlevel

vars Level maxlevel subgen;
10 -> maxlevel;

define getterminal(Wd);
	;;; return a lexical item of type Wd, or false if there isn't one
	vars list;
	Lexicon -> list;
	;;; Lexicon is local to generate
	until list==[] then
		if  Wd == front(front(list))
		then    return(oneof(back(front(list))))
		else    back(list) -> list
		endif
	enduntil;
	;;;if we get here, Wd isn't a lexical category
	false
enddefine;

define genlist(types)->result;
	;;;types is a list of non-terminals or terminals
	vars list;
	[] -> result;
	until types==[] do
		if  (subgen(destpair(types)->types)->> list)
		then    result<>list -> result
		else    false -> result; return
		endif
	enduntil
enddefine;

define trygenrules(rules)->result;
	;;; rules is a list of possible right-hand-sides
	;;; repeatedly try expanding one till a non-false result is
	;;; obtained, i.e. recursion level doesn't get exceeded.
	vars rule;
	until rules == [] do
		oneof(rules) -> rule;
		if  (genlist(rule)->>result)
		then    return
		else    delete(rule,rules) -> rules
		endif
	enduntil;
	false->result;
enddefine;

define subgen(type)->result;
	;;; type is either the name of a grammatical category
	;;; or a terminal symbol or a list of possible right hand
	;;; sides of a rule.
	;;; This function is called by generate which has Grammar and
	;;; Lexicon as local variables. subgen does all the work.
	;;; If depth of recursion exceeds maxlevel, then return false

	vars list rules Level;
	Level + 1 -> Level;
	if  Level > maxlevel
	then    false -> result
	elseif  ispair(type)
	then    trygenrules(back(type))->result
	elseif  (getterminal(type)->>result)
	then    [%result%] -> result
	else
		;;; look to see if it is a non-terminal
		Grammar -> list;
		until list=[] do
			destpair(list) -> list -> rules;
			if  front(rules)==type
			then    subgen(rules) -> result; return
			endif;
		enduntil;

		;;; if we get this far type is a terminal
		[%type%] -> result
	endif
enddefine;

define generate(Grammar,Lexicon);
	;;; given a grammar and a lexicon, generate a sentence at random
	vars Level;
	0 -> Level; ;;;controls depth of recursion
	subgen("s")
enddefine;


/* --- Revision History ---------------------------------------------------
--- John Gibson, Jul 31 1995
		Added +oldvar at top
--- Aaron Sloman, Jun  9 1987
	Altere macro --- to come with load marked range.
 */
