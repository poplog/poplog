/* --- Copyright University of Birmingham 2005. All rights reserved. ------
 > File:            $poplocal/local/lib/logic.p
 > Purpose:         See below
 > Author:          Aaron Sloman, Nov 25 1995 (see revisions)
 */

/*  --- Copyright University of Sussex 1987.  All rights reserved. ---------
 >  File:           C.all/lib/lib/logic.p
 >  Purpose:        Teaching propositional logic (truth-tables)
 >  Author:         Aaron Sloman, March 1978, April 1987 (see revisions)
 >  Documentation:  HELP * LOGIC  * LOGIC.HLP  * LOGIC.EXP
 >  Related Files:
 */

#_TERMIN_IF DEF POPC_COMPILING

;;; The top level operation is LOGIC, which sets up a special environment
;;; then uses DOLOGIC to read in commands, or new current formula.
;;; INTERRUPT and PRMISHAP are redefined locally
;;; This package is quite large because of the need for "natural"
;;; interaction: so lots of kinds of mistakes are anticipated and dealt with.

;;;				*******GLOBAL VARIABLES AND CONSTANTS******

;;; Files by H and HH commands
vars
	logic_help= '$usepop/pop/packages/teaching/help/logic.hlp',
	logic_explain='$usepop/pop/packages/teaching/help/logic.exp',
;

;;; Different formalisms are tolerated
;;; The lists which follow define the formalisms.

;;; lists of recognised propositional connectives
lconstant
	iffwds	=	[iff <->],
	thenwds	=	[implies ->],
	orwds	=	[or v],
	exorwds	=	[xor x],	;;; exclusive or
	andwds	=	[and & .],
	notwds	=	[not - ~ ],

;;; Now a "precedence" list. Order must be preserved, bi-conditionals
;;;	MUST come first.
	operatorseq=
		[%iffwds,thenwds,orwds,exorwds,andwds,"not","atom"%],

;;; and a list used to check for unwanted operators;
	operators=
	iffwds<>(thenwds<>(orwds<>(exorwds<>(andwds<>notwds)))),

;;; a 'frequency' list of binary operators used in newgen
;;; for randomly generated test formulas
	binaries = [v v v & & & -> -> <->],
;

;;; Variables used in automatically generated test formulas.
;;; Sometimes the list is temporarily changed in newgen - hence vars
;;; Change to lvars from V.13
vars
	variables = [[p q r s] [ a b c d e]],
	formulas_so_far,	;;; used to check repetition in newgen
;

vars
	current_formula		;;; The last formula read in or generated
	= [v [-p] q],		;;; a default initial formula.

	;;; variables, table, and final column for the current formula
	;;; assigned by setup
	current_variables,
	current_table,
	current_final_column,


	input=[],			;;; Used by various utilities

	mistakes=0,  		;;; used non-locally in patonback, and local to
						;;; teaching procedures which count errors
;

;;; globals
lvars premisses, nonnull, negdone, done1, justnegated;

constant 2 logic; 	;;; the main procedure, defined below

;;;				*******UTILITIES*******

(poppid + systime()) && 2:11111111 -> ranseed;

define lconstant macro chop x;
	;;; e.g. convert "chop list" into "list.back -> list"
	x, ".", "back", "->", x
enddefine;


define logic_interrupt;
	exitto(nonop logic)
enddefine;

;;; should be lconstant for V.13
constant procedure(
	isyes = member(%[[yes][y]]%),
	isno = member(%[[no] [n]]%),
	istrue = member(%[%true% 1 t]%),
	isfalse = member(%[%false% 0 f]%)
	)
	;

define istruthvalue(x);
	lvars x;
	istrue(x) or isfalse(x)
enddefine;

define allof(list,pred);
	;;; true if every element of list satisfies pred, false otherwise.
	lvars x,list,procedure pred;
	for x in list do
		unless pred(x) then return(false) endunless;
	endfor;
	return(true)
enddefine;

define hasfalse();
	member(false,current_final_column)
enddefine;

define hastrue();
	member(true, current_final_column)
enddefine;


define ppr(x);
	;;; Simple pretty printer. E.g. remove list brackets.
	if ispair(x) then applist(x,ppr)
	else pr(space); pr(x)
	endif;
enddefine;

define lpr(mess);
	;;; utility printing procedure
	;;; print out TRUE and FALSE as t and f
	if		mess == [] 		then ;;; do nothing
	elseif	istrue(mess)	then	ppr("t")
	elseif	isfalse(mess)	then	ppr("f")
	elseif	atom(mess)		then	ppr(mess)
	else	applist(mess, lpr)
	endif
enddefine;


define vars logic_error(message);
	;;; general purpose error routine, locally redefinable
	clearstack();
	lpr(message);
	interrupt();
enddefine;


;;;		*******PROCEDURES FOR READING IN A LINE OF INPUT*******

;;; two variables used by getline
vars
	getlinedepth=0,			;;; counts depth of recursion
	notnull=true; 			;;; if true, don't allow null input

define getline(mess) -> ll;
;;; used to print a message and read in a line from terminal
;;; If notnull is true, then getline will not accept an empty line,
;;; but goes on asking for a line to be typed in.

	dlocal getlinedepth = getlinedepth + 1;

	define dlocal prmishap;
		sysprmishap -> prmishap;
		clearstack();
		[]; ppr('please try again\n'); exitto(getline);
	enddefine;

	if getlinedepth > 2 then ppr('\n Type H for help\n'); interrupt() endif;
	lpr(mess);
	unless vedediting then pr(space) endunless;

	lvars bye = sysexit;
	readline() -> ll;
	if ll = [bye] or ll == termin then
		ppr('\nBYE\n\n');
		bye();;
	elseif ll = [stop] then interrupt()		;;; return to logic.
	elseif ll = [debug] then
		sysprmishap -> prmishap;
		valof("popready") ->> logic_interrupt -> interrupt;
		setpop -> bye;
	elseif notnull and atom(ll) then
		getline('\nPlease type something: ') ->ll
	endif
enddefine;


define getyes(message);
	;;; Prompt with message followed by '?' then read in a line of text,
	;;; and assign it to global variable input. Check whether it contains
	;;; the word "yes" or "y", allowing empty response as equivalent to yes

	dlocal notnull = false;
	getline(message><'?   ') -> input;
	if input == [] then [y] -> input endif;
	isyes(input)
enddefine;


;;;				*******PRINTING ROUTINES*******

;;; Now procedures for printing formulas represented as trees or atoms.
;;; the structure is one of
;;;		<atom>
;;;		[ - <formula> ]
;;;		[ <binary operator>		<formula>	<formula> ]

vars procedure fpr;		;;; top-level formula printing procedure.

define procedure bracketpr(form);
	;;; Used by fpr for printing nested formulas

	if atom(form) then lpr(form)
	elseif front(form)=="-" then fpr(form)
	else  ppr("("); fpr(form); pr(")")
	endif
enddefine;

define fpr(form);

	if atom(form) then lpr(form)
	elseif form(1)=="-" then
		ppr("-"); bracketpr(form(2))
	else
		bracketpr(form(2)),		;;; first argument
		ppr(form(1)),			;;; operator
		bracketpr(form(3))		;;; second argument
	endif
enddefine;


define answer(x,reply);
	ppr(if x then 'it is ' else 'it isn\'t ' endif);
	lpr(reply)
enddefine;



;;;			*******PARSING ROUTINES*******


;;; Procedures for analysing a list of input text items and producing a
;;; parse tree. Uses global variable input.
;;; E.g. if input = [ if not p or q then r iff s and t] then tree is
;;;			[ <-> [ -> [ v [ - p] q ] r ] [& s t] ]
;;; note scope conventions
;;; The procedure RPRINT prints out such a tree, in infix notation,
;;; with parentheses showing scope

;;; The next procedures are concerned with parsing, on the assumption that
;;; a line of text has been read in and assigned to input (used globally)
;;; The top level procedure is parse, which calls rparse, which in turn
;;; calls itself recursively using less and less of the list operatorseq

define try(wds);
	;;; used to check a hypothesis about the next word in input.
	;;; wds may be either a single word, or a list of words.

	if atom(input) then false
	elseif isword(wds) then
		if		wds == front(input) then chop input; true
		else	false
		endif
	elseif  member(front(input),wds) then
		chop input;
		true;
		if atom(input) then logic_error('incomplete formula') endif
	else  false
	endif;
enddefine;

define avoid(wds);
	;;; if front(input) = wds or member of wds, then error.

	if	atom(input) then		;;;ok do nothing
	elseif	front(input) == wds
	or		not(atom(wds)) and member(front(input), wds)
	then
		ppr('Something missing before');
		logic_error(input)
	endif
enddefine;

define checkclose();
	avoid("then");
	avoid(")")
enddefine;

define demand(wd);
	unless	try(wd) then
		ppr('Missing'); ppr(wd);
		logic_error(if atom(input) then [] else 'before' :: input endif)
	endunless
enddefine;

vars procedure rparse;	;;; defined below

define parse();
	;;; top level parser. Uses global variable input

	define dlocal logic_error(mess);
		lvars mess;
		clearstack();
		lpr(mess);
		[];		;;; result for parse
		exitfrom(parse)
	enddefine;

	rparse(operatorseq);
	if		input/==[]
	then	checkclose();
		logic_error('surplus input: '::input)
	endif
enddefine;

define procedure rparse(precedence) -> ss;
	lvars thisop nextops;
	destpair(precedence) -> (thisop, nextops);
	checkclose();
	if		atom(input) then logic_error('missing input')
	elseif	thisop == "not" then
		front(input) ->ss;
		if		ss == "--"
		then	[ - - ]
		elseif	ss=="---"
		then	[ - - - ]
		elseif	ss == "----"
		then	[ - - - - ]
		else	[%ss%]
		endif <> chop input;
		if		try(notwds)
		then	[ - % rparse(precedence)%]
		else	rparse(nextops)
		endif -> ss
	elseif  thisop == "atom"
	then
		;;; expect "(", "if", or some atom which is not in the list operators.
		avoid(operators);
		if try("if") then
			;;; now handle conditionals of the form IF P THEN Q.
			;;; P may be an arbitrary formula. Q may be anything but a biconditional
			rparse(operatorseq) ->ss;
			demand("then");
			[-> %ss, rparse(back(operatorseq))%] ->ss
			;;; use the back to prevent bi-conditionals after "then"
		elseif  try("(")
		then
			rparse(operatorseq) ->ss;
			demand(")");
		elseif	istruthvalue(front(input))
		then	logic_error('don\'t use t and f as variables')
		else	front(input) ->ss;		;;; found an atom, return it
			chop input
		endif
	else
		;;; thisop specifies a type of binary operator, e.g. andwds.
		;;; try to parse suitable arguments before and after an
		;;; occurrence of it.
		rparse(nextops) ->ss;
		if thisop == orwds or thisop == exorwds or thisop == andwds then
			;;; allow them to associate to the left:
			while try(thisop) do
				[%thisop(2),ss,rparse(nextops)%] ->ss
			endwhile;
		elseif try(thisop) then [%thisop(2),ss,rparse(nextops)%] ->ss
		endif
	endif
enddefine;


;;;			*******FUNCTIONS FOR GENERATING FORMULAS*******

;;; The procedure newgen creates the formula and assigns it to current_formula.
;;; The complexity of the formula is controlled by the variables which follow.
;;; Some are altered as the program is used.
;;; (Could use lvars and dlocal)
vars
	vfreq=3,
	negfreq=3,
	complexmax=1,
	complexity=1
;

define morecomplex();
	;;; make tasks more complex.
	unless complexmax > 8 then 0.25 + complexmax ->complexmax endunless;
	max(2, complexmax) -> complexmax;
enddefine;

define lesscomplex();
	;;; make tasks less complex
	unless complexmax < 2 then complexmax - 0.25 -> complexmax endunless
enddefine;


		;;; repetitions control freqency of selection.

define atomsin(formula);
	if formula == [] then 0
	elseif formula == "-" then 0.3
	elseif atom(formula) then 1
	else atomsin(front(formula)) + atomsin(back(formula))
	endif;
enddefine;

define varsof(form) -> list;
	;;; form is a formula. Return a list of all its variables.

	define subvars(form);
		lvars form;
		if atom(form) then
			unless member(form,list) then form::list ->list
			endunless
		elseif	front(form) == "-" then subvars(form(2))
		else	subvars(form(2)), subvars(form(3))
		endif
	enddefine;

	[] -> list;
	subvars(form);
	sort(list) ->list;		;;; get the variables in alphabetic order
enddefine;


vars procedure newgen;	;;; defined below

define genform();
	;;; used by newgen to generate a random formula.
	;;; as depth increases, increase chance of producing a negation,
	;;; or a variable

	dlocal vfreq, negfreq, complexity, justnegated;	;;; all used non-locally

	random(3)*vfreq -> vfreq;

	random(4)*negfreq -> negfreq;

	if   complexity >= 1
	then complexity - 1 ->complexity;
		complexity - 0.25 -> complexity;
		;;; reduce maximum depth at random.
		if		random(round(3 * complexmax)) < vfreq
		and		caller(1) /== newgen
		then	oneof(variables);
		elseif	not(justnegated)
		and		random(round(4*complexmax)) < negfreq
		then	true -> justnegated;
			[%"-", genform() %]
		else
			false -> justnegated;
			[% oneof(binaries), genform(), genform()%]
		endif
	else oneof(variables)
	endif
enddefine;

define newgen();
	;;; generates formulas at random, with gradually increasing complexity,
	;;; controlled by complexmax. Can be reset to 1 to reduce complexity.
	;;; See the command RS in operation DOLOGIC, below
	;;; the depth is directly controlled by the variable complexity.
	dlocal variables, complexity;
	if		complexmax > 3
	then	2 + random(round(complexmax/2))
	else	complexmax
	endif	-> complexity;
	complexity == 1 -> justnegated;
	rev(oneof(variables)) -> variables;
	;;; make sure there are not too many variables if complexmax <= 3
	until	complexmax > 3 or length(variables) < 3
	do		chop variables
	enduntil;
	repeat
		genform() ->current_formula;
	nextif(member(current_formula,formulas_so_far));
	quitif(complexmax < 3 or
		(length(varsof(current_formula)) > 1
			and atomsin(current_formula) >= 4))
	endrepeat;
	current_formula::formulas_so_far -> formulas_so_far;
	morecomplex();
enddefine;

define patonback();
	ppr(
		if mistakes == 0 then
			'good: no mistakes'; morecomplex()
		elseif mistakes == 1 then
			'not bad, only 1 mistake'
		else
			mistakes><' mistakes this time';
			if mistakes > 2 then lesscomplex() endif
		endif);
	logic_interrupt()
enddefine;



;;;		*******PROCEDURES FOR EVALUATING LOGICAL FORMULAS*******
vars procedure eval;	;;; defined below

define procedure evalvar(vals, vrbls, var);
	;;; evaluate a variable using a binding environment defined by
	;;; a list of variables and a list of values

	if		istruthvalue(var) then var
	else	until front(vrbls)==var do
			chop vrbls; chop vals;
		enduntil;
		istrue(front(vals))
	endif
enddefine;

define procedure eval(vals, vrbls, form);
	;;; Evaluate a structure in an environment defined by vrbls and vals.
	;;; Form is either a variable (an atom) or a list whose first element
	;;; is one of the operators (e.g. "-", "<->", "->", "&" or "v", "x")
	;;; Remaining elements of form are structures (variables or lists)

	lvars op, arg1, arg2;
	if atom(form) then evalvar(vals, vrbls, form)
	else
		destpair(form) ->(op, form);
		if op == "-" then not( eval(vals, vrbls, form(1)) )
		elseif (dl(form) ->(arg1, arg2);
				eval(vals, vrbls, arg1) ->arg1;
				eval(vals, vrbls, arg2) ->arg2;
				op == "<->")
		then	arg2 == arg1
		elseif	op == "->"
		then	not(arg1) or arg2
		elseif	op == "v"
		then	arg1 or arg2
		elseif	op == "x"
		then	arg1 /== arg2		;;; exclusive or
		elseif  op == "&"
		then	arg1 and arg2
		endif
	endif
enddefine;


;;;		*******PROCEDURES FOR DIAGNOSTIC PRINTING*******

;;; Now some procedures for partially evaluating a formula. I.e. only
;;; evaluate one subformula, replacing it by a truth-value, and return
;;; the modified formula. Used for printing out steps in evaluation.

define replacevars(vals, vrbls, form);
	;;; relace all atoms in the formula with the appropriate truth-values.

	dlvars vals vrbls form;
	if		atom(form)
	then	evalvar(vals, vrbls, form)
	else
		front(form) ::
		maplist(back(form),
			procedure(form); replacevars(vals, vrbls, form) endprocedure)
	endif
enddefine;

define eval1(form, done1, negdone)-> (form, done1, negdone);
	;;; the formula has had all its atoms replaced by truth-values.
	;;; evaluate one sub-expression, and replace it with its truth-value.
	lvars L;
	unless  done1 or atom(form)
	then
		if not(allof(back(form),istruthvalue)) then
			for L on back(form) do
			quitif(done1);
				eval1(front(L), done1, negdone) ->(front(L), done1, negdone);
			endfor
		else
			(form(1) == "-" and atom(form(2))) -> negdone;
			;;; negdone is used to control indentation.
			eval([], [], form) -> form;
			true -> done1;
		endif
	endunless
enddefine;

define printeval(vals, vrbls, form);
	;;; repeatedly replace a part of form with a truth-value got by
	;;; evaluating it, and print out the result, until the whole
	;;; thing has been evaluated.

	dlocal done1, negdone;
	lvars indent_spaces;
	1 -> indent_spaces;		;;; controls indentation
	nl(1); fpr(form); nl(1);
	replacevars(vals, vrbls, form) ->form;
	until atom(form) do
		fpr(form);
		false ->> done1 -> negdone;
		eval1(form, done1, negdone) -> (form, done1, negdone);
		if atom(form) then
			ppr('\t  and that is  ');
			lpr(form); nl(1); return();
		endif;
		nl(1); sp(indent_spaces);
		indent_spaces + if negdone then 1 else 2 endif -> indent_spaces;
	enduntil;
enddefine;


;;;		*******PROCEDURES FOR ANALYSING CURRENT FORMULA AFTER PARSING*******



;;; Given a number N, the procedure truthtable returns a list of lists,
;;; each being a list of N truth-values.  So if N = 1 the result is
;;; [[<true>][<false>]] whereas if N is 2, the result is
;;; [[<true> <true>][<true> <false>][<false> <true>][<false> <false>]]

define truthtable(n);
	lvars ll;

	define add(vv, ll);
		;;; given a list of combinations of truth-vvues, and a new truth-vvue
		;;; make a new list. E.g. given [ [T] [F] ] and "F", make the list
		;;; [ [F T] [F F] ]
		maplist(ll, procedure(ll); vv::ll endprocedure)
	enddefine;

	if n == 0 then [[]]
	else
		truthtable(n-1) -> ll;
		add(true,ll) <> add(false,ll)
	endif
enddefine;


define finalcolumn(table, vrbls, form);
	;;; form is a formula, vrbls its variables, table the list of
	;;; possible truth-combinations.
	;;; return a list of truth-values for form, for each combination.

	maplist(table, eval(%vrbls, form%))
enddefine;

define setup();
	;;; assume current_formula has been read in
	;;; prepare the environment for logical games, assuming a current formula.
	varsof(current_formula) -> current_variables;
	truthtable(length(current_variables)) -> current_table;
	finalcolumn(current_table,current_variables,current_formula) -> current_final_column;
enddefine;

define prtablefor(current_formula);
	dlocal
		current_formula, current_variables,
		current_table current_final_column;
	setup();
	ppr(current_variables); ppr('\t   '); fpr(current_formula);
	nl(1);
	until atom(current_table) do
		lpr(destpair(current_table) -> current_table);
		ppr('\t     ');
		lpr(destpair(current_final_column) ->current_final_column);
		nl(1)
	enduntil
enddefine;



;;;		*******PROCEDURES FOR READING IN TRUTH-VALUES*******


define gettruthvalues(message, numlist) -> ll;
	;;; message is a message to be printed.
	;;; numlist specifies possible numbers of truthvalues required.
	;;; read in a row of truth-values, or possibly just one.
	;;; complain if something other than a truth-value is typed.

	lvars item, list;
	dlocal pop_readline_prompt='';
	repeat
		getline(message) -> ll;
		for item in ll do
			unless  istruthvalue(item) then
				ppr(item sys_>< ' is not a truth-value, try again\n ');
				nextloop(2)
			endunless;
		endfor;
	quitif(member(length(ll), numlist));
		ppr('wrong number of truth-values, try again\n ');
	endrepeat;
	maplist(ll, istrue) -> ll
enddefine;


;;;		*******PROCEDURES FOR LOGICAL EXERCISES*******

define helptable();
	;;; print out incomplete truth-table for current formula, a row at a time.
	;;; get user to type final column. Check that values are correct.

	dlocal mistakes, interrupt;
	lvars
		reply,
		table = current_table,
		final_column = current_final_column;

	patonback  -> interrupt;
	0 -> mistakes;
	ppr(['Type in the final column\n' ^current_variables '\t    ']);
	fpr(current_formula); nl(1);
	until   atom(final_column)
	do
		gettruthvalues(front(table)<>['\t    '], [1]) -> reply;
		unless front(reply) == front(final_column) then
			mistakes + 1 -> mistakes;
			ppr('no, because:');
			printeval(front(table), current_variables, current_formula);
			unless atom(back(final_column)) then ppr('try next row\n') endunless
		endunless;
		chop table, chop final_column
	enduntil;
	patonback()
enddefine;

;;; **** Some commands for answering questions about the current formula ****

define evalcurrform();
	;;; give practice at evalution. user supplies values.

	dlocal interrupt = patonback, mistakes = 0;

	lvars row, requestrow, x, ll;

	length(current_variables) -> x;
	ppr('Type "stop" when fed up\n The formula is:\t');
	fpr(current_formula);
	ppr('\n Give values for variables and for formula');
	repeat
		nl(1); ppr(current_variables);
		gettruthvalues('\n', [%x, x + 1 %]) -> row;
		length(row) -> ll;
		if ll == x + 1 then
			destpair(rev(row)) ->(ll, row);
			rev(row) -> row
		else
			front(gettruthvalues('the final column?\t', [1])) -> ll
		endif;

		if eval(row,current_variables,current_formula) == ll then
			ppr('that\'s right')
		else
			mistakes + 1 -> mistakes;
			ppr('No, because:');
			printeval(row, current_variables, current_formula);
			'try again'.ppr
		endif
	endrepeat
enddefine;




define checkequiv(form);
	;;; used in getguess and testeq below, [] if not well formed.
	;;; form is the result of parsing recent input.

	lvars formvars;
	if atom(form) then
		ppr('. Ill formed - bad luck\n');
		return(false)
	endif;
	varsof(form) -> formvars;
	if form = current_formula then
		ppr('\n that\'s exactly right \n'); morecomplex();
		true
	elseif current_variables /= formvars then
		ppr('your formula should contain just the variables: ');
		ppr(current_variables); lesscomplex();
		mistakes + 1 -> mistakes;
		false;
	elseif finalcolumn(current_table, formvars, form)
				= current_final_column then
		ppr('Good that is equivalent to the formula, namely:\n');
		fpr(current_formula); true
	else
		mistakes + 1 -> mistakes;
		if getyes('Sorry, not equivalent\n Want the truth-table for your formula')
		then prtablefor(form)
		elseif allof(input,istruthvalue) then
			return(false);
		elseif length(input) > 1 then
			chain(parse(),checkequiv)
		endif;
		false
	endif;
enddefine;

define testeq();
	;;; generate a formula and ask for an equivalent one to be typed in
	;;; to be assigned to input

	dlocal complexmax, mistakes,
		nonnull = false,
		variables = [[a b][p q]],  ;;; restrict formulas to two variables
		interrupt = patonback;

	lvars tabledone;
	ppr('Try typing in a formula equivalent to the one given');
	repeat
		;;; create a new formula
		repeat
			if complexmax > 3 then [[a b c][p q r]]
			else [[a b][p q]]
			endif -> variables;
			newgen();
		quitif(length(varsof(current_formula)) > 1);
			lesscomplex();	;;; newgen increases complexity - undo
		endrepeat;
		setup();
		ppr('\n This is the formula:\n'); fpr(current_formula);
		false -> tabledone;
		repeat
			;;; allow for student to type in formula instead of answering
			if		not(tabledone)
			and 	getyes('\n Want to see the formula\'s table')
			then	prtablefor(current_formula); true -> tabledone
			elseif	isno(input)
			then	[] ->input
			endif;
			while length(input) < 2 do
				getline('equivalent formula?') ->input;
				if isno(input) then return endif
			endwhile;
			if checkequiv(parse()) then
				if not(tabledone) and getyes('Want its truthtable') then
					prtablefor(current_formula)
				endif;
				if getyes('\nWant to try a different one') then
					nextloop(2)
				else patonback();	;;; returns
				endif
			else [] -> input
			endif
		endrepeat
	endrepeat
enddefine;


;;; ***** GUESSING GAME *******

define guessform;
	dlocal input, interrupt = patonback, mistakes = 0;

	lvars len, formula, rows_so_far, val, row, count = 0;

	ppr('Starting the formula guessing game.');
	define getrow();
		dlocal pop_readline_prompt = '';
		ppr(newline);
		getline('')
	enddefine;

	repeat
		newgen();
		setup();
		length(current_variables) -> len;
	nextunless(len > 1);
		ppr('\n A formula has been generated by the computer.');
		ppr('\n You may either guess the formula or type in a set of values');
		ppr('\n   for the variables, in which case the value for the formula');
		ppr('\n   will be printed out.');
		[] -> rows_so_far;
		repeat
			count + 1 -> count;
			if count < 5 then
				ppr('\n Guess the formula or type a row of truth values for the variables:\n ');
			else ppr('\n ');
			endif;
			ppr(current_variables); ppr("?");
			for row in rows_so_far do pr('\n ');; lpr(row) endfor;
			getrow() -> input;
			repeat
				if allof(input,istruthvalue) then
					if length(input) /== len then
						ppr('\nExactly ' sys_>< len sys_>< ' variables needed, please.');
						nextloop(2)
					endif;
					maplist(input,istrue) -> input;
					eval(input,current_variables,current_formula) -> val;
					ppr('The corresponding value for the formula is: ');
					fpr(val);
					[^^input ^val] -> val;
					if member(val, rows_so_far) then
						ppr('\n That repeats a previous row');
					else [^^rows_so_far ^val] -> rows_so_far;
					endif;
					nextloop(2)
				else
					parse() -> formula;
					if length(formula) > 1 then
						[] -> input;
						if checkequiv(formula) then
							if getyes('\nWant to try a different one') then
								nextloop(3)
							else patonback();	;;; returns
							endif
						elseif allof(input,istruthvalue) then nextloop()
						elseif getyes('\nTry again') then
							nextloop(2)
						elseif allof(input,istruthvalue) then
							nextloop()
						else patonback();
						endif;
					else nextloop(2)
					endif
				endif
			endrepeat
		endrepeat
	endrepeat
enddefine;

;;; **** MAKING INFERENCES  *****

define setupinference() -> (premisses, conclusion, current_formula);

	dlocal premisses, variables, current_formula, notnull;

	lvars ll, ok, printing, numofpremisses, antecedent;

	repeat
		front(getline('How many premisses')) -> numofpremisses;

	quitif(isinteger(numofpremisses) and numofpremisses >= 1);
		ppr('a number please\n')
	endrepeat;
	if complexmax < 4 then [[p q][p q]] else [[p q r] [p q]] endif -> variables;
	false -> notnull;
	false -> ok;
	until ok
	do
		;;; make sure at least one premiss has more than one variable.
		[] -> premisses;
		repeat numofpremisses times
			newgen();
			current_formula :: premisses -> premisses;
			length(varsof(current_formula)) > 1 -> ok;
		endrepeat;
		if ok then
			;;; now check that the premisses are not inconsistent
			;;; by forming their conjunction
			destpair(premisses) -> (antecedent, ll);
			until atom(ll) do
				[ & %antecedent, front(ll)%] ->antecedent;  chop ll
			enduntil;
			antecedent -> current_formula;
			setup();
			hasfalse() and hastrue() -> ok
		endif
	enduntil;
	getyes('do you want their individual truth-tables') ->printing;
	ppr('here are the premisses:');
	premisses -> ll;
	until atom(ll) do
		destpair(ll) -> (current_formula, ll);
		if printing then
			nl(1);
			prtablefor(current_formula);
			ppr('-------------------')
		else
			ppr('\n>> '); fpr(current_formula); nl(1);
		endif
	enduntil;
	;;; make sure conclusion includes at least one variable from premisses!
	[%current_variables,current_variables%] -> variables;
	newgen();
	current_formula -> conclusion;
	ppr(' And the conclusion is:\n');
	if printing then nl(1); prtablefor(current_formula)
	else ppr('\n   '); fpr(current_formula)
	endif;
	[%"->",antecedent,conclusion%] ->current_formula;
	setup();
enddefine;

define inferences();
	;;; gives user practice at testing the validity of inferences.

	dlocal complexmax, current_formula,
		formulas_so_far = [],
		interrupt = patonback,
		mistakes = 0;

	lvars premisses, conclusion, ll, valid, isvalid, premiss,
		last_complexmax, count, failed;

	1 ->> complexmax -> last_complexmax;
	repeat
		if complexmax > last_complexmax then
			0.5 + last_complexmax ->> complexmax -> last_complexmax
		endif;
		setupinference() -> (premisses, conclusion, current_formula);
		not(hasfalse()) -> isvalid;
		getyes('\nDo you think the inference is valid') -> valid;
		0 -> count;
		repeat
			false -> failed;
			count + 1 -> count;
			if valid and isvalid then
			else
				if valid and count < 2 then ppr('It is invalid\n') endif;
				ppr('Give values of variables making premisses true and conclusion false\n');
				ppr(current_variables);
				gettruthvalues('\n', [%length(current_variables)%]) ->ll;
				if eval(ll,current_variables,current_formula) then
					mistakes + 1 -> mistakes;
					true -> failed;
					ppr('That set doesn\'t invalidate the inference, because');
					ppr('\n>>This is how the premisses come out:');
					for premiss in premisses do
						printeval(ll, current_variables, premiss);
					endfor;
					ppr('\n>>And the conclusion:');
					printeval(ll, current_variables, conclusion);
				endif;
			endif;
			if isvalid == valid and not(failed) then
				ppr('Good. '); morecomplex()
			else lesscomplex(); mistakes + 1-> mistakes;
			endif;
			if isvalid then ppr('It is valid.  ')
			else
				ppr('It is invalid.  ');
				if valid and count < 2 then
					ppr('can you see why?\n '); nextloop();
				elseif failed then
					if getyes('Do you want another attempt to invalidate it?') then
						nextloop()
					endif
				endif
			endif;
			if getyes('Do you want the complete truth-table') then
				prtablefor(current_formula)
			endif;
		;;;quitif(valid or (valid == isvalid) or count > 1);
		quitloop();
		endrepeat;
	quitunless(getyes('want to try another'))
	endrepeat;
	patonback();
enddefine;

;;;		*******TOP LEVEL PROCEDURES*******


define dologic();
	;;; this procedure, called repeatedly from logic, handles the
	;;; commands or formulas typed in by the user
	lvars ll, oldform = current_formula;
	getline('\n Type command or formula') ->input;
	if length(input) == 1 then
		front(input) -> ll;
		if		ll = "h"
		then	pop11_compile(logic_help)
		elseif  ll = "?" then
			ppr('COMMANDS \: \n');
			ppr([? h hh p tb ht ev nf rs ta in co eq g val stop bye])
		elseif	ll = "hh" or ll = "??"
		then	pop11_compile(logic_explain);
		elseif	ll = "rs"
		then	1 -> complexmax
		elseif	ll = "nf"
		then
			while	(newgen(); length(current_formula)==2 and atom(current_formula(2))) do
				lesscomplex();
			endwhile;
			ppr(' ** new formula ready');
		elseif	ll = "p"
		then	fpr(current_formula); nl(1)
		elseif	ll = "ht"
		then	helptable()
		elseif	ll = "eq"
		then	testeq()
		elseif	ll = "tb"
		then	prtablefor(current_formula)
		elseif	ll="ta"
		then	answer(not(hasfalse()), 'a tautology')
		elseif	ll = "in"
		then	answer(not(hastrue()), 'inconsistent')
		elseif	ll = "co"
		then	answer((hastrue() and hasfalse()), 'contingent')
		elseif	ll = "ev"
		then	evalcurrform()
		elseif	ll = "g"
		then	guessform()
		elseif	ll = "val"
		then	inferences()
		elseif	ll = "debug"
		then	sysprmishap -> prmishap;	;;; for debugging
			valof("popready") -> interrupt;
		else	ppr('Unknown command. Type H or ? or HH for help\n')
		endif
	else
		parse() -> current_formula;
		unless atom(current_formula) then pr('** OK') endunless
	endif;

	if		atom(current_formula) then oldform -> current_formula endif;
	unless	current_formula == oldform
	then	setup()
	endunless
enddefine;

define 2 logic;
	dlocal
		pop_readline_prompt = ': ',
		prmishap, proglist,
		formulas_so_far = [];

	lvars ll, oldc = cucharout, nosp = false;

	define dlocal cucharout(x);
		;;; suppress spaces after "(" and "-"
		unless  nosp and x == `\s` then oldc(x); endunless;
		x == `(` or x == `-` -> nosp
	enddefine;

	define dlocal interrupt();
		dlocal prmishap;
		define dlocal interrupt();
			setpop -> interrupt;
			'There has been a system error. Please ask for help'=>
			valof("popready")();
		enddefine;
		clearstack();
		ppr('\n** restarting, ');
		false;
		logic_interrupt();
	enddefine;
	logic_error(%'something has gone wrong\n'%) -> prmishap;
	ppr('\nWelcome to the logic tutor\n');
	if		getyes('is this your first go with the logic program')
	then	pop11_compile(logic_explain)
	endif;
	ppr('type\tH for list of commands\n\tHH for sample formulas');

	repeat
		pdtolist(incharitem(charin)) -> proglist;
		dologic();
		clearstack();
	endrepeat;
enddefine;


setup();

/*  --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan  9 2005
		Relocated to $usepop/pop/packges/teaching/...

--- Aaron Sloman, Aug 27 1999
	Had to fix bugs dues to misuse of dlocal and output variables, etc.
	Inferences hadd stopped working.

--- A. Sloman Apr 17 1987
	Put into one file. Tidied, lvarsed, etc. Removed "dload"
	Enabled <RETURN> as equivalent to "Y" or "YES" etc.
	Restored the "G" option (guessform) and added "?" to get a brief
	summary of commands
 */
