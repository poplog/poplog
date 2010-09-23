/*  --- Copyright University of Sussex 1991.  All rights reserved. ---------
 >  File:           C.all/lib/lib/oldlisp.p
 >  Purpose:        a translator from LISP to POP-11
 >  Author:         Jon Cunningham - 1982 (see revisions)
 >  Documentation:  HELP * OLDLISP
 >  Related Files:  HELP * LISP
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

;;; THIS FILE CONTAINS A 'COMPILER' FROM LISP TO POP-11
;;; SOME LISP PROCEDURES ARE TRANSLATED DIRECTLY TO
;;; CALLS OF POP PROCEDURES OF THE SAME OR SIMILAR NAME

;;; This program is NOT SSUPPORTED

;;; Note: the translated program may not work correctly if built-in
;;; lisp functions are passed as arguments to be called within
;;; user-defined lisp functions.

popmemlim + 50000 -> popmemlim;
vars syntax lambda;

vars _temp;                 ;;; temporary variable used anywhere
vars condresult;

;;; SOME GLOBAL FLAGS CONTROLLING TRANSLATION

vars specialprops;                          ;;; property indicating how to translate a variable
vars lispprompt; '* ' -> lispprompt;        ;;; prompt used by lisp_read
vars lispliblist;                           ;;; used for auto-loading
	sysfileok('$usepop/pop/lsp/lib' dir_>< '') :: popautolist
			->> popautolist -> lispliblist;
	sysfileok('$usepop/pop/lsp/lib' dir_>< '') :: popuseslist -> popuseslist;
constant escape_word; consword(`\^[`,1) -> escape_word;
vars non_pop_words; false -> non_pop_words; ;;; when true different itemiser used
vars wordbreaks; ' \t\n@()[],?;' -> wordbreaks;   ;;; used when non_pop_words
vars stringquote; `\'` -> stringquote;
vars whites;    ' \t' -> whites;            ;;; `\n` added automatically if
											;;; popnewline false

;;; UTILITY PROCS

;;; No longer needed, nor available!
;;; compile('$usepop/pop/lsp/lib/prarrow.p');

define warning(string,args);
	pr('\nWARNING: ');
	pr(string);
	unless args == [] then
		pr('\ninvolving: ');
		ppr(args)
	endunless;
	nl(1)
enddefine;

define special(x);
vars adlist;
	define a_or_d(list);
	vars i;
		for i in list do
			unless i == `a` or i == `d` then
				return(false)
			endunless
		endfor;
		return(true)
	enddefine;

	if x.isword and [% explode(x) %] matches [`c` ??adlist:a_or_d `r`] then
		[% for x in adlist do
				if x == `a` then "hd" else "tl" endif
			endfor %]
	else
		specialprops(x)
	endif
enddefine;

uses popprint;

;;; ***************************************************
;;; * POP procedures corresponding to LISP procedures *
;;; ***************************************************

vars proplist; newproperty([],20,[],true) -> proplist;

vars translate;

define lisp_apply(fun,args);
vars temp;
	if (special(fun) ->> temp) then
		if temp.isprocedure then
			mishap('Unhandled special case in lisp apply',[^fun ^args])
		elseif temp == "fexpr" then
			return(apply(dl(args),valof(fun)))
		elseif temp.islist then
			rev(temp) -> fun
		else
			[^temp] -> fun
		endif
	elseif fun matches [lambda ==] then
		return(apply(dl(args),popval(translate(fun))))
	elseif fun.isword then
		[^fun] -> fun
	else
		mishap('Lisp apply expects a word or lambda expression as first arg',[^fun])
	endif;
	until fun == [] do
		destpair(fun) -> fun -> temp;
		if (identprops(temp) ->> _temp).isinteger and _temp > 0 then
			valof(temp) -> temp;
			popstackmark;
			dl(args);
			-> _temp;
			if _temp == popstackmark then
				[] -> args
			else
				until dup() == popstackmark do
					_temp;
					apply(temp) -> _temp
				enduntil;
				sysconslist(_temp) -> args
			endif
		else
			[% apply(dl(args),valof(temp)) %] -> args
		endif
	enduntil;
	if args == [] then
		[]
	elseif length(args) > 1 then
		warning('Many results from apply returned as a list',[]);
		args
	else
		front(args)
	endif
enddefine;

define lisp_assoc(word,list);
	until list == [] do
		if hd(hd(list)) == word then
			return(hd(list))
		else
			tl(list) -> list
		endif
	enduntil;
	return([])
enddefine;

define lisp_get(word,prop);
	if prop == "value" then
		valof(word)
	else
		lisp_assoc(prop,proplist(word)) -> prop;
		if prop == [] then
			[]
		else
			prop(2)
		endif
	endif
enddefine;

define lisp_put(word,val,prop) -> val;
vars temp;
	if prop == "value" then
		val -> valof(word)
	elseif (lisp_assoc(prop,proplist(word)) ->> temp) /== [] then
		val -> temp(2)
	else
		[% prop, val %] :: proplist(word) -> proplist(word)
	endif
enddefine;

define defprop(args);
	unless length(args) == 3 then
		mishap('Wrong number of args for DEFPROP',args)
	endunless;
	lisp_put(args(1),args(2),args(3))
enddefine;

define popname(word);
vars temp;
	if length(pdtolist(incharitem(stringin(word))) ->> temp) == 1 then
		return(front(temp))
	endif;
	lisp_get(word,"popname") -> _temp;
	if _temp == [] then
		gensym("#_") -> _temp;
		erase(lisp_put(_temp,word,"printname"));
		erase(lisp_put(word,_temp,"popname"))
	endif;
	return(_temp)
enddefine;

define lisp_implode(list);
vars ch n;
	0 -> n;
	for ch in list do
		if ch.isinteger then
			ch><'' -> ch
		endif;
		explode(ch);
		length(ch) + n -> n
	endfor;
	popname(consword(n))
enddefine;

define lisp_mapcar(fun, args);
		if args == [] then
			nil
		else
			lisp_apply(fun,[%hd(args)%]) :: lisp_mapcar(fun, tl(args))
		endif
enddefine;

define lisp_minus(n); -n enddefine;

define lisp_null(list);
	if list == [] then true else [] endif
enddefine;

define lisp_list(fun);
vars in_lisp_mode;
	false -> in_lisp_mode;
	[% fun() %]
enddefine;

vars lisp_t; true -> lisp_t;
define lisp_princ(s);
vars i;
	if s == [] then
		pr('nil')
	elseif s == true or s == "lisp_t" then
		pr('t')
	elseif s.islist then
		if front(s) == "quote" then
			pr('@');
			erase(lisp_princ(front(back(s))))
		else
			pr('(');
			for i from 1 to length(s) - 1 do
				erase(lisp_princ(s(i)));
				sp(1)
			endfor;
			unless s == [] then erase(lisp_princ(last(s))) endunless;
			pr(')')
		endif
	elseif s.isword then
		lisp_get(s,"printname") -> i;
		if i /== [] then
			pr(i)
		else
			pr(s)
		endif
	else
		pr(s)
	endif;
	return(true)
enddefine;

define lisp_print(s); nl(1); lisp_princ(s); sp(1) enddefine;

define lisp_explode(word);
vars cucharout;
	identfn -> cucharout;
	maplist([% erase(lisp_princ(word)) %],consword(% 1 %))
enddefine;

define digit(ch);
	if ch <= `0` or ch > `9` then
		false
	else
		ch - `0`
	endif
enddefine;

vars lisplastchar; false -> lisplastchar;
define lisp_nonpopreaditem(cucharin);
vars n c ch d whites;
	unless popnewline then
		whites >< '\n' -> whites
	endunless;
	if lisplastchar then
		if lisplastchar == termin then
			return(termin)
		endif;
		unless strmember(lisplastchar,whites) then
			consword(lisplastchar,1);
			false -> lisplastchar;
			return
		endunless;
		false -> lisplastchar
	endif;
	0 ->> n -> c;
	false -> d;
	repeat forever
		cucharin() -> ch;
		if ch == termin then
			return(ch)
		endif;
		quitunless(strmember(ch,whites))
	endrepeat;
	if strmember(ch,wordbreaks) then
		consword(ch,1);
		return
	endif;
	repeat forever
		if n then
			if digit(ch) then
				n*10 + digit(ch) -> n;
				if d then 1 + d -> d endif
			elseif ch == `.` then
				0 -> d
			elseif strmember(ch,wordbreaks) then
				ch -> lisplastchar;
				repeat c times erase() endrepeat;
				if d then
					return(n/(10 ** d))
				else
					return(n)
				endif
			else
				false -> n
			endif
		elseif strmember(ch,wordbreaks) then
			ch -> lisplastchar;
			consword(c) -> ch;
			return(popname(ch))
		endif;
		1 + c -> c;
		ch;
		cucharin() -> ch;
		if ch == termin then
			ch -> lisplastchar;
			if n then
				repeat c times erase() endrepeat;
				if d then
					return(n/(10 ** d))
				else
					return(n)
				endif
			else
				consword(c) -> ch;
				return(popname(ch))
			endif
		endif
	endrepeat
enddefine;

define lisp_incharitem(cucharin);
	if non_pop_words then
		lisp_nonpopreaditem(% cucharin %)
	else
		incharitem(cucharin)
	endif
enddefine;

define islisp_opener(item);
	switchon item ==
		case "(" then 3
		case "[" then 2
		case "{" then 1
		else false
	endswitchon
enddefine;

define islisp_closer(item);
	switchon item ==
		case "]" then 2
		case ")" then 3
		case escape_word then 0
		case "}" then 1
		else false
	endswitchon
enddefine;

vars lispinputlist; false -> lispinputlist;
vars procedure lisp_readfn; itemread -> lisp_readfn;

define lisp_reader() -> item;
	if lispinputlist then
		proglist,lispinputlist -> proglist -> lispinputlist;
		lisp_readfn() -> item;
		proglist,lispinputlist -> proglist -> lispinputlist;
	else
		lisp_readfn() -> item
	endif
enddefine;

vars nested; false -> nested;
define lisp_read() -> item;
vars depth temp popprompt _item;
	define checkitem(nested);
	vars _item;
	vars procedure lisp_readfn;
		if item == "@" then
			readitem -> lisp_readfn;
			[quote %lisp_read()%] -> item
		elseif item == "t" then
			"lisp_t" -> item
		elseif item == "nil" then
			[] -> item
		endif
	enddefine;
	lispprompt -> popprompt;
	lisp_reader() -> item;
	if item.islisp_closer then
		mishap('Unexpected closing bracket',[^item])
	endif;
	unless (item.islisp_opener ->> _temp) then
		checkitem(nested);
		return
	endunless;
	_temp, popstackmark;
	1 -> depth;
	repeat forever
		lisp_reader() -> item;
		if (item.islisp_opener ->> _temp) then
			_temp, popstackmark;
			1 + depth -> depth
		elseif (item.islisp_closer ->> _temp) then
			if nested then item -> _item endif;
			repeat forever
				sysconslist() -> item;
				-> temp;
				temp - _temp -> _temp;
				if _temp < 0 then
					warning('Missing opening bracket assumed',[]);
					temp - _temp -> _temp;
					temp, popstackmark, item;
					quitloop
				elseif depth == 1 then
					if nested and _temp > 0 then
						if lispinputlist then
							conspair(_item,lispinputlist) -> lispinputlist
						else
							conspair(_item,proglist) -> proglist
						endif
					endif;
					return
				else
					depth - 1 -> depth;
					item;
					if _temp == 0 then
						quitloop
					endif;
					temp - _temp -> _temp;
				endif
			endrepeat
		elseif item == termin then
			mishap('Unexpected end of input',[])
		else
			checkitem(true);
			item
		endif
	endrepeat
enddefine;

define subst(expr,new,old);
	if old = expr then
		new
	else
		maplist(expr, subst(% new, old %))
	endif
enddefine;

define lisp_subst(new,old,expr);
	subst(expr,new,old)
enddefine;

define lisp_terpri(); nl(1); true enddefine;

;;; ************************************
;;; * PROCEDURES TO DO THE TRANSLATION *
;;; ************************************

vars top_level; true -> top_level;

define argtrans(args);
	"(";
	unless args == [] then
		repeat forever
			 dl(translate(destpair(args) -> args));
			 quitif(args == []);
			 ","
		endrepeat
	endunless;
	")"
enddefine;

vars procedure popcondition;
define funtrans(fun,args) -> result;
	if (fun == "and" or fun == "or") then
		unless length(args) < 1 then
			[(% popcondition(destpair(args) -> args) %] -> result
		else
			[(] -> result
		endunless;
		until args == [] do
			result nc_<> [% fun, popcondition(destpair(args) -> args) %]
				-> result
		enduntil;
		result <> [)] -> result
	elseif (fun.isword and (identprops(fun) -> s,s.isinteger) and s > 0) then
		unless length(args) < 1 then
			"(" :: translate(destpair(args) -> args) -> result
		else
			[(] -> result
		endunless;
		until args == [] do
			result nc_<> (fun :: translate(destpair(args) -> args)) -> result
		enduntil;
		result <> [)] -> result
	else
		[% if fun.islist then
				dl(translate(fun))
			else
				fun
			endif;
			argtrans(args) %] -> result
	endif
enddefine;

define translate(s);
vars fun args;
	if s.atom then
		if (special(s) ->> fun) then
			if fun == "fexpr" then
				return([(^s)])
			elseif fun.isword then
				if fun == "and" or fun == "or" then
					warning('Oops - I can\'t translate AND or OR except as function calls',[^fun])
				endif;
				fun -> s        ;;; for operators
			else
				warning('Unhandled special case translation',[^s])
			endif
		endif;
		if s.isword then
			if (identprops(s) ->> fun).isinteger then
				if fun > 0 then
					warning('Translation of pop operator',[^s]);
					return([(nonop ^s)])
				endif
			elseunless fun == undef then
				warning('Unhandled strange identprops translation',[^s ^fun]);
				return([(^s)])
			endif
		endif;
		return([^s])
	endif;
	destpair(s) -> args -> fun;
	if dup(special(fun)) then -> fun;
		if fun.isprocedure then
			return(fun(args))
		elseif fun == "fexpr" then
			return([(% front(s)% ( ^args ))])
		elseif fun.islist then
			rev(fun) -> fun;
			goto l1
		endif
	else
		.erase
	endif;
	[^fun] -> fun;
l1: funtrans((destpair(fun) -> fun),args) -> args;
	for s in fun do
		if args matches [( == )] then
			[^s ^^args] -> args
		else
			[^s(^^args)]-> args
		endif
	endfor;
	return(args)
enddefine;

define makebody(body,lastcall,progging);
vars erasecall temp;
	"erase" -> erasecall;
	until body == [] do
		if (destpair(body) ->> body) == [] then
			lastcall -> erasecall
		endif -> temp;
		if temp.isword and progging then
			temp,":"
		else
			translate(temp) -> temp;
			if temp matches [goto =] or temp matches [return( == )] then
				dl(temp)
			elseif temp matches [lisp_print(?? _temp)] then
				dl(_temp);
				"=>";
				if erasecall == "identfn" then
					"true"
				elseif erasecall == "return" then
					dl([return(true)])
				endif
			else
				if erasecall == "identfn" then
					dl(temp)
				elseif erasecall == "erase" and temp matches [== ->> = )] then
					temp --> [??temp ->> ? _temp )];
					dl(temp);
					"->";
					_temp;
					")"
				else
					erasecall;
					if temp matches [( == )] then
						dl(temp)
					else
						"(";
						dl(temp);
						")"
					endif
				endif;
				unless body == [] then ";" endunless
			endif
		endif
	enduntil
enddefine;

define Add1(args); translate([plus ^^args 1]) enddefine;

define Minusp(args); translate([lessp ^^args 0]) enddefine;

define Plusp(args); translate([greaterp ^^args 0]) enddefine;

define Sub1(args); translate([difference ^^args 1]) enddefine;

define Zerop(args); translate([eq ^^args 0]) enddefine;

define Procedures(args,type);
vars body i ins fun;
	args --> [?args ??body];
	if type == "progdefine" then
			-> ins
	elseif type == "prog" then
		[] -> ins
	else
		args -> ins;
		[] -> args
	endif;
	[% if type == "define" or type == "progdefine" then
			 "define",
			 (destpair(ins) -> ins) ->> fun
		 else
			 "procedure"
		 endif;
		 if ins /== [] then
			 "(";
			 for i in ins do
				 i,","
			 endfor;
			 erase();
			 ")"
		 endif;
		 ";";
		 if args /== [] then
			 "vars";
			 for i in args do
				 i,","
			 endfor;
			 erase();
			 ";"
		 endif;
		 makebody(body,"return",type == "prog" or type == "progdefine");
		 if type == "define" or type == "progdefine" then
			 "enddefine";
			 ";",dl(["^fun"])
		 else
			 "endprocedure"
		 endif;
		 if type == "prog" then "(",")" endif %]
enddefine;

define popcondition(s);
vars args;
	translate(s) -> s;
	if s matches [lisp_true(??args)] then
		dl(args)
	elseif s matches [lisp_null(??args)] then
		"(",dl(args),")","==",[]
	else
		"(",dl(s),")","/==",[]
	endif
enddefine;

define Cond(args);
vars cond action ifword hadelse;
	false -> hadelse;
	"if" -> ifword;
	[%until args == [] do
			 unless front(args) matches [?cond ??action] then
				 mishap('Bad form for COND expression',args)
			 endunless;
			 back(args) -> args;
			 if cond == "lisp_t" then
				 "else";
				 [] -> args;
				 true -> hadelse
			 else
				 ifword, "elseif" -> ifword;
				 popcondition(
					if action == [] then
						[setq condresult ^cond]
					else
						cond
					endif);
				"then";
				if action == [] then
					"condresult"
				endif
			 endif;
			 makebody(action,"identfn",false)
		 enduntil;
		 unless hadelse then
			 "else",[]
		 endunless%
		endif]
enddefine;

define Define(args);
vars ins s;
	if front(args) == "fexpr" then
		back(args) -> args;
		unless (front(args) ->> s).islist and length(s) > 1 then
			mishap('Bad form for fexpr definition',[^s])
		endunless;
		"fexpr" -> specialprops(front(s))
	endif;
	if args matches [?ins [prog ??s]] then
		Procedures(ins,s,"progdefine")
	else
		Procedures(args,"define")
	endif
enddefine;

define Foreach(args);
vars cond action;
	unless args matches [?cond ??action] then
		mishap('Bad form for FOREACH',[^args])
	endunless;
	[%
	"foreach", dl(translate([quote ^cond])), "do";
	makebody(action,"erase",false);
	%endforeach; nil]
enddefine;

define Forevery(args);
vars cond action;
	unless args matches [?cond ??action] then
		mishap('Bad form for FOREVERY',[^args])
	endunless;
	[%
	"forevery", dl(translate([quote ^cond])), "do";
	makebody(action,"erase",false);
	%endforevery; nil]
enddefine;

define Goto(args);
	[goto %front(args)%]
enddefine;

define If(args);
vars cond action;
	unless args matches [?cond ??action] then
		mishap('Bad form for IF expression',[^args])
	endunless;
	Cond([^args])
enddefine;

vars Lambda; Procedures(% "procedure" %) -> Lambda;

define List(args);
	[% "[", "%", until args == [] do
			 dl(translate(destpair(args) -> args));
			 unless args == [] then "," endunless
		 enduntil, "%", "]" %]
enddefine;

define Logop(args,op);
vars temp;
	if length(args) < 2 then
		mishap('Missing arguments for n-ary operator',[^op ^args])
	else [lisp_true(%
		translate(destpair(args) -> args) -> temp;
		repeat forever
			dl(temp);
			op;
			translate(destpair(args) -> args) -> temp;
			dl(temp);
			quitif(args == []);
			"and";
		endrepeat;
		%)]
	endif
enddefine;

define MaxMin(args,fun);
	if length(args) < 1 then
		mishap('Missing arguments for MAX or MIN',[^fun])
	elseif length(args) == 1 then
		translate(front(args))
	else
		[^fun(] <> MaxMin(back(args),fun)
			<> ("," :: translate(front(args))) <> [)]
	endif
enddefine;

vars Max Min; MaxMin(%"max"%) -> Max; MaxMin(%"min"%) -> Min;

vars Prog; Procedures(% "prog" %) -> Prog;

define Quote(args);
	front(args) -> args;
	if args.isword then
		["^args"]
	elseif args.islist then
		[%"[",dl(args),"]"%]
	else
		[^args]
	endif
enddefine;

define Setq(args);
	[% "(";
		 while length(args) > 2 then
			 dl(translate(args(2))), "->", dl(translate(args(1))), ",";
			 back(back(args)) -> args
		 endwhile;
		 if length(args) /== 2 then mishap('Bad number of args for SETQ',args) endif;
		 dl(translate(args(2))), "->>", dl(translate(args(1))), ")" %]
enddefine;

define Set(args);
	[% "(";
		 while length(args) > 2 then
			 dl(translate(args(2))),
			 "->", "valof", "(",
			 dl(translate(args(1))),
			 ")", ",";
			 back(back(args)) -> args
		 endwhile;
		 if length(args) /== 2 then
			 mishap('Bad number of args for SET',args)
		 endif;
		 dl(translate(args(2)))% ->> valof(%dl(translate(args(1)))%))]
enddefine;

define Unless(args);
vars cond action;
	unless args matches [?cond ??action] then
		mishap('Bad form for UNLESS',[^args])
	endunless;
	Cond([[[not ^cond] ^^action]])
enddefine;

define Until(args);
vars cond action;
	unless args matches [?cond ??action] then
		mishap('Bad form for UNTIL',[^args])
	endunless;
	[%
	"until", popcondition([setq condresult ^cond]), "do";
	makebody(action,"erase",false);
	%enduntil, condresult]
enddefine;

define While(args);
vars cond action;
	unless args matches [?cond ??action] then
		mishap('Bad form for WHILE',[^args])
	endunless;
	[%
	"while", popcondition(cond), "do";
	makebody(action,"erase",false);
	%endwhile, nil]
enddefine;

newproperty([
	[add [lisp_list add]]
	[alladd [lisp_list alladd]]
	[allpresent [lisp_true allpresent]]
	[allremove [lisp_list allremove]]
	[add1 ^Add1]
	[and [lisp_true and]]
	[append <>]
	[apply lisp_apply]
	[assoc lisp_assoc]
	[atom [lisp_true atom]]
	[car hd]
	[cdr tl]
	[cond ^Cond]
	[cons ::]
	[define ^Define]
	[defprop fexpr]
	[difference -]
	[eq [lisp_true ==]]
	[equal [lisp_true =]]
	[eval [popval translate]]
	[explode lisp_explode]
	[flush [lisp_list flush]]
	[foreach ^Foreach]
	[forevery ^Forevery]
	[get lisp_get]
	[go ^Goto]
	[greaterp %Logop(%">"%)%]
	[if ^If]
	[implode lisp_implode]
	[lambda ^Lambda]
	[lessp %Logop(%"<"%)%]
	[list ^List]
	[lookup [lisp_true present]]
	[mapcar lisp_mapcar]
	[matches [lisp_true matches]]
	[max ^Max]
	[member [lisp_true member]]
	[min ^Min]
	[minus lisp_minus]
	[minusp ^Minusp]
	[not lisp_null]
	[null lisp_null]
	[numberp [lisp_true isnumber]]
	[or [lisp_true or]]
	[plus +]
	[plusp ^Plusp]
	[popready [lisp_list popready]]
	[popval [lisp_list popval]]
	[present [lisp_true present]]
	[princ lisp_princ]
	[print lisp_print]
	[prog ^Prog]
	[putprop lisp_put]
	[quote ^Quote]
	[quotient /]
	[read lisp_read]
	[remove [lisp_list remove]]
	[reverse rev]
	[set ^Set]
	[setq ^Setq]
	[sub1 ^Sub1]
	[subst lisp_subst]
	[terpri lisp_terpri]
	[times *]
	[unless ^Unless]
	[until ^Until]
	[while ^While]
	[zerop ^Zerop]
		],50,false,true) -> specialprops;

define lisptopop(x);
vars lispinputlist item in_lisp_mode;
	true -> in_lisp_mode;
	pdtolist(lisp_incharitem(discin(x><'.lsp'))) -> lispinputlist;
	startpopprint(x);
	repeat forever
		lisp_read() -> item;
		if item == termin then
			popprint([^termin]);
			clearstack();
			;;; this is where code to justify the file would go
			return(true)
		endif;
		translate(item) -> item;
		if front(item) == "define" then
			item(2) =>
		endif;
		popprint(item nc_<> [; ^newline]);
	endrepeat
enddefine;

;;; routines to switch between lisp and pop

vars in_lisp_mode; false -> in_lisp_mode;

define lisp_eval(lispinputlist);
vars item in_lisp_mode proglist;
	true -> in_lisp_mode;
	repeat forever
		lisp_read() -> item;
		if item == termin then
			return
		else
			erase(lisp_print(popval(translate(item))));
			nl(1)
		endif
	endrepeat
enddefine;

define lisp_compile(cucharin);
vars popautolist; lispliblist -> popautolist;
vars lisplastchar; false -> lisplastchar;
	if cucharin.isstring or cucharin.isword then
		discin(cucharin) -> cucharin
	endif;
	lisp_eval(pdtolist(lisp_incharitem(cucharin)));
	return("compiled")
enddefine;

define setlisp();
	nl(1);
	pr('Setlisp\n');
	lisp_compile(cucharin);
	pr('Leaving lisp\n');
enddefine;

define macro pop; identfn -> popsetpop; setpop() enddefine;

define macro lisp;
	procedure;
		charin -> cucharin;
		setlisp()
	endprocedure -> popsetpop;
	setpop()
enddefine;

;;; ALTERATION TO VEDVEDDEFAULTS TO ALLOW VED_LMR OF LISP FILES
;;; Should no longer be necessary
define vedveddefaults();
	if sys_fname_extn(vedcurrent) = '.lsp' then
		"lisp" -> subsystem;
		true -> vedcompileable
	endif
enddefine;



/* --- Revision History ---------------------------------------------------
--- Andreas Schoter, Sep  9 1991
	Changed occurrances of -popliblist- to -popautolist-
--- John Gibson, Aug 13 1989
		Replaced nc join with nc_<>
--- Aaron Sloman, May  1 1989
	Removed apparently spurious attempt to load prarrow.p
 */
