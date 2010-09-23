/*  --- Copyright University of Sussex 1991.  All rights reserved. ---------
 >  File:           C.all/lib/ved/ved_vcalc.p
 >  Purpose:        A 'spreadsheet' like package.
 >  Author:         Aaron Sloman, Sept 1983 (see revisions)
 >  Documentation:  HELP * VCALC
 >  Related Files:
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

section;

;;; USER UTILITIES
define lconstant procedure switchval(word);
	;;; used for ved_showing and ved_chatty
	lvars word;
	not(valof(word)) -> valof(word);
	vedputmessage( if valof(word) then 'ON' else 'OFF' endif)
enddefine;

vars showing=false; 	;;; controls whether vedcheck is called

vars chatty=false; 		;;; controls messages

;;; Two procedures to switch values.
vars procedure(
	ved_showing=switchval(%"showing"%),
	ved_chatty=switchval(%"chatty"%));

;;; SYSTEM GLOBALS
true -> popconstruct;			;;; compile patterns as constant

vars calc_updating;                  ;;; controls whether effects of changes
true -> calc_updating;               ;;; are propagated immediately

;;; global properties
vars procedure (vcalcval, isinvar, isoutvar);

vars equations=[], varsdone=[], constraints=[];


;;; UTILITIES

define lconstant vedatspace;
	strmember(vedcurrentchar(), '\s\t|')
enddefine;

define lconstant gobacktochar(char);
	lvars char;
	until vedcurrentchar() == char do
		vedcharleft()
	enduntil
enddefine;

define lconstant setchanged(changed);
	;;; don't let every action update vedchanged. Just add 1 to saved value
	unless changed then 0 -> changed endunless;
	unless vedchanged == changed then changed + 1 -> vedchanged endunless;
enddefine;

define lconstant put_chatty_message(message);
	vedputmessage(message);
	if chatty then charin_timeout(300) -> endif;
enddefine;

;;; SPECIAL ITEM-REPEATER doesn't combine ":" or "::" with anything else

lvars procedure calcmoveitem_rep=incharitem(vedrepeater);

lconstant calcmoveitem_ref=frozval(1, calcmoveitem_rep);

lconstant vcalc_item=item_newtype();

;;; set `:` to have new type
vcalc_item -> item_chartype(`:`,calcmoveitem_rep);

define lvars procedure calcmoveitem();
	;;; return next item in VED buffer, and move past it. Use `:` as special
	lvars item;
	vedrepeater -> fast_cont(calcmoveitem_ref);
	calcmoveitem_rep();
	;;; backspace as necessary
	fast_cont(calcmoveitem_ref) -> item;
	while ispair(item) do
		vedcharleft();
		fast_back(item) -> item
	endwhile;
enddefine;

define lconstant readcalcitem(repeater) -> item;
	;;; repeater is an item repeater: readitem or calcmoveitem
	;;; read in an item. If its "!" then assume it and next item
	;;; form a comment. Ignore "|" for tabulation.
	;;; minimal syntax checking
	lvars repeater,item;
	repeater() -> item;
	if item == "!" then
		erase(repeater());
		repeater() -> item;
	elseif item == "|" then readcalcitem(repeater) -> item
	elseif member(item, [EQS TABLE constraint ]) then
		clearstack();
		vederror('MISSING SEMI-COLON SOMEWHERE -- FOUND ' >< item)
	endif
enddefine;


define ok_item(repeater) -> item;
	;;; read an item. complain if end of file or end of range
	lvars repeater,item;
	readcalcitem(repeater) -> item;
	if item==termin then vederror('SOMETHING MISSING')
	endif;
enddefine;


define lvars procedure checkset(settype,othertype,item);
	;;; Check variable declarations; initialise vcalc variable
	;;; Sets the item as being an invar or an outvar, after checking
	lvars item, procedure(settype,othertype);
	if othertype(item) then
		clearstack();
		vederror('DECLARING ' >< item >< ' AS INPUT AND OUTPUT ITEM')
	else
		true -> settype(item);
		;;; things are being changed, so unset value
			false -> vcalcval(item)
	endif;
enddefine;

lconstant procedure update_equations;        ;;; defined later

define getval(repeater) -> item;
	;;; repeater is readitem, or calcmoveitem
	;;; Read in an expression of form <var>:<value> and set value.
	;;; or expression of form <var>::<value> and set it to be output variable.
	lvars item,val,repeater;
	readcalcitem(repeater) -> item;
	if item == termin or item == newline then return endif;
	unless isword(item) then
		vederror('WORD NEEDED -- FOUND: ' >< item)
	endunless;
	if item == ":" or item == "::" then
			vederror('MISSING VARIABLE BEFORE OR AFTER' >< item)
	elseif (ok_item(repeater) ->> val) == ":" then
		checkset(isinvar,isoutvar,item);
		ok_item(repeater) -> vcalcval(item);
		update_equations(item)		;;; usually calc_updating is false
	elseif val == "::" then
		checkset(isoutvar,isinvar,item);
		ok_item(repeater) ->;
	else vederror('NO COLON AFTER VARIABLE: ' >< item >< ' -- FOUND: ' >< val)
	endif;
enddefine;

define lvars evalcalc(list) -> result;
	;;; evaluate a list of POP-11 text, replacing invars and outvars
	;;; with their values. Abort if undefined
	lvars len,item,list,result;
	stacklength() -> len;
	[%fast_for item in list do
		 if isinvar(item) or isoutvar(item) then
			 if vcalcval(item) ->> item then
				 if isword(item) then
					 ;;; make sure it is quoted
					 """, item, """
				 else item
				 endif
			 else
				 erasenum(stacklength() - len);
				 ;;; no value yet so can't run equation
				 false -> result; return();
			 endif
		 else item
		 endif;
	 endfor%] -> result;
enddefine;

define lvars procedure processequation(list);
	lvars temp len list outvar=front(list), rest=back(back(list));
	;;; transform equation
	if chatty then  put_chatty_message(list >< nullstring); endif;
	unless member(outvar, varsdone) then
		evalcalc(rest) -> temp;	;;; executable version of equation body
		if temp then
			define dlocal prmishap(x,y);
				erasenum(stacklength() - len);
				exitfrom(processequation)
			enddefine;
			stacklength() -> len;
			popval(temp) -> temp;
			;;; if the value has changed, then re-do relevant equations
			unless temp = vcalcval(outvar) then
				temp -> vcalcval(outvar);
				update_equations(outvar)
			endunless;
		endif
	endunless
enddefine;

define procedure calcerror(name);
	lvars name;
	;;; user definable error procedure when constraints are violated
	vedlocate(name);
	vederror('CONSTRAINT VIOLATED: ' >< name);
enddefine;


define lvars procedure processconstraint(word);
	lvars temp list;
	vars len word;
	;;; transform constraint
	if isword(word) then valof(word) else word endif -> list;
	unless islist(list) then vederror('CONSTRAINT NOT DEFINED: ' >< word)
	endunless;
	put_chatty_message(
		if chatty then list else word endif sys_>< nullstring);
	evalcalc(list) -> temp;	;;; executable version of constraint
	if temp then
		define dlocal prmishap(x,y);
		lvars x,y;
			erasenum(stacklength() - len);
			put_chatty_message('Constraint not evaluable: ' >< word);
			exitfrom(processconstraint)
		enddefine;
		stacklength() -> len;
		;;; try evaluating constraint
		unless popval(temp) then calcerror(word)
		endunless
	endif
enddefine;

define lvars procedure do_equations;
	put_chatty_message('Processing equations');
	applist(equations,processequation)
enddefine;


define lvars procedure do_constraints;
	put_chatty_message('Processing constraints');
	applist(constraints,processconstraint);
	vedputmessage('OK');
enddefine;


define lconstant formatinsert(string);
	lvars string;
	vars vedstatic=true;
	define lconstant testcharinsert(c);
		lvars c;
		unless vedatspace() then
			false -> vedstatic;
		endunless;
		vedcharinsert(c);
	enddefine;
	appdata(string,testcharinsert);
	unless vedatspace() then
		false -> vedstatic;
		vedcharinsert(` `); vedcharinsert(` `);
	endunless;
enddefine;

define lvars procedure vedupdate(item);
	;;; Update value of an output variable.
	;;; Find where item is recorded and update it.
	lvars char, item, val,oldc=vedchanged,line=vedline,col=vedcolumn,
	col1=false,line1=false;
	vars vedautowrite=false, vedstatic=true;
	unless isoutvar(item) then
		vederror('ATTEMPT TO UPDATE NON OUTPUT VARIABLE: ' sys_>< item)
	endunless;
	unless vcalcval(item) ->> val then
		vederror('UPDATING VARIABLE WITH NO VALUE: ' sys_>< item)
	endunless;

	vedpositionpush(); vedendfile();
	repeat
		vedlocate(item);	;;; found occurrence. Check if OK
		if line1 then
			if vedcolumn==col1 and vedline==line1 then
				;;; second time round
				goto error;
			endif
		else vedline-> line1; vedcolumn -> col1; ;;; record first occurrence
		endif;
		;;; check that '::' follows item
		vedmoveitem()->;
		if vedcurrentchar() == `:` then
			vedcharright();
			if vedcurrentchar() == `:` then
				vedcharright();
				;;; clear previous entry if any
				until vedatspace() do
					veddotdelete(); vedcharright();
				enduntil;
				gobacktochar(`:`);
				vedcharright();
				formatinsert(val sys_>< nullstring);
				if showing then vedcheck() endif;
				vedscr_flush_output();
				vedpositionpop();
				setchanged(oldc);
				return();
			endif;
		endif
	endrepeat;
error:
	vederror('NO ENTRY FOUND FOR OUTPUT VARIABLE: ' sys_>< item);
enddefine;

vars procedure ved_vcheck;

define lvars procedure equation_uses(word,list);
	lvars word list;
	vars wd arg;
	while list matches [?wd ?arg ==] do
		if fast_lmember(wd, [sumof prodof average numof]) then
			if isinteger(arg) then arg >< nullstring -> arg endif;
			if issubstring(arg,1,word)
			then true; return
			else fast_back(fast_back(list)) -> list
			endif
		else fast_back(list) -> list
		endif;
	endwhile;
	false
enddefine;

define lconstant procedure update_equations(word);
	;;; update all equations using the word
	lvars word eqn item rest;
	if calc_updating then
		unless fast_lmember(word,varsdone) then
			if isoutvar(word) then vedupdate(word) endif;
			word :: varsdone -> varsdone;
			fast_for eqn in equations do
				fast_front(eqn) -> item; fast_back(fast_back(eqn)) -> rest;
				if fast_lmember(word, rest) or equation_uses(word,rest) then
					processequation(eqn)
				endif;
			endfor;
		endunless
	endif
enddefine;


define procedure test_compile(code, error_message);
	vars prwarning pop_syntax_only=true;
	;;; now see if it will compile without error
	erase -> prwarning;
	define dlocal prmishap(string,list);
		lvars string,list;
		pr(newline);
		error_message >< code =>
		spr(string);
		unless list == [] then applist(list,spr) endunless;
		;;; unless list == [] then list => endunless;
	enddefine;
	popval(code);
enddefine;

define lconstant getequation(repeater) -> equation;
	;;; read in equation of form: <var> = <expression>;
	lvars item, repeater, equation;
	[%until (readcalcitem(repeater) ->> item) == ";" or item == termin then
			 item
		 enduntil%] -> equation;
	unless length(equation) fi_> 2 and equation(2) == "=" then
		vederror('"=" MUST BE SECOND ITEM OF EQUATION ' >< equation)
	endunless;
	checkset(isoutvar,isinvar,front(equation));
	test_compile(equation, 'ERROR IN EQUATION: ');
enddefine;


;;; MACROS FOR USE WITH VED_RUN, etc

define readcalcvars(istype,nottype);
	;;; used in macros defining input and output variables
	lvars item,istype,nottype;
	until (readcalcitem(readitem) ->> item) == ";" or item == termin do
		unless item == "," do
			checkset(istype,nottype,item);
		endunless;
	enduntil;
enddefine;

define macro invars;
;;; invars declares input variables
	readcalcvars(isinvar,isoutvar)
enddefine;


define macro outvars;
;;; outvars declares output variables
	readcalcvars(isoutvar,isinvar)
enddefine;


define lconstant app_vals(string,total, 2 op) -> total;
	;;; used by sumof and prodof. Add or multiply all vcalcval of invars
	;;; and outvars of words which contain the string
	define lconstant sub_val(item,val);
		lvars item,val;
		if issubstring(string,1,item) then
			vcalcval(item) -> val;
			if val then total op val -> total
			else false ; exitfrom(app_vals);
			endif
		endif
	enddefine;
	appproperty(isinvar, sub_val);
	appproperty(isoutvar, sub_val);
enddefine;


lvars procedure (sum_vals, mult_vals);

app_vals(%0, nonop + %) -> sum_vals;
app_vals(%1, nonop * %) -> mult_vals;

define lconstant num_vals(string) -> total;
	define lconstant sub_vals(item,val);
		lvars item,val;
		if issubstring(string,1,item) then
			total fi_+ 1 -> total
		endif
	enddefine;
	0 -> total;
	appproperty(isinvar, sub_vals);
	appproperty(isoutvar, sub_vals);
enddefine;

define av_vals(string);
	sum_vals(string)/num_vals(string)
enddefine;


define mk_macro(word,proc);
	dl([^proc (^(word><nullstring)) ])
enddefine;

define macro sumof word;
	mk_macro(word, sum_vals)
enddefine;


define macro prodof word;
	mk_macro(word, mult_vals)
enddefine;

define macro average word;
	mk_macro(word, av_vals)
enddefine;


define macro numof word;
	mk_macro(word, num_vals)
enddefine;


define macro EQS;
	;;; read in a collection of equations, terminated by a final semicolon
	lvars eqns=[];
	vars varsdone=[];
	put_chatty_message('Reading equations');
	until null (proglist) or hd(proglist) = ";" do
		getequation(readitem) :: eqns -> eqns
	enduntil;
	rev(eqns) -> equations;		;;; keep order
	if calc_updating then ved_vcheck() endif;
enddefine;


define macro TABLE;
	lvars oldupdate=calc_updating;
	vars varsdone=[], calc_updating;
	put_chatty_message('Reading table of values');
	false -> calc_updating;
	vcalc_item -> item_chartype(`:`,itemread);
	until null(proglist) or front(proglist) == ";" do
		getval(readitem) -> ;  ;;; result not used
	enduntil;
	if oldupdate then ved_vcheck() endif;
enddefine;


define 9 word <-- val;
	;;; Used in macro constraint. Checks a new constraint;
	;;; val is a list containing a constraint
	lvars val word;
	vars prwarning=erase;
	val -> valof(word);
	test_compile(val, 'ERROR in Constraint: ' >< word);
	processconstraint(word);
enddefine;

define macro constraint name;
	lvars name;
	setfrontlist(name,constraints) -> constraints;
	"vars", name, ";", """, name, """, "<--",
enddefine;

define vars procedure ved_vcheck;
	vars calc_updating=true;
	lvars changed=vedchanged;
	vedpositionpush();
	unless vedcurrentchar() == `:` then vedlocate('::'); vedcheck(); endunless;
	do_equations();
	do_constraints();
	setchanged(changed);
	vedpositionpop();
enddefine;


define ved_vstart;
	;;; initialise everything
	newproperty([],100,false,true) -> vcalcval;
	"vcalcval" -> pdprops (vcalcval);

	newproperty([],100,false,true) -> isinvar;
	"isinvar" -> pdprops(isinvar);

	newproperty([],100,false,true) -> isoutvar;
	"isoutvar" -> pdprops(isoutvar);
	[] ->> equations -> constraints;
enddefine;

;;; initialise everything
ved_vstart();

define ved_vcalc;
	;;; Initialise and print a reminder about format
	ved_vstart();
	unless vedargument == nullstring then
		ved_ved();
		vedendfile();
		vedinsertstring('invars ;\n\noutvars ;\n\nEQS\n\n;\n\nTABLE\n\n;');
		vedinsertstring('\n\n;;; constraint <name>  [ <expression> ];');
	endunless;
enddefine;

define ved_run;
	;;; read through whole file and process everything.
	vars varsdone=[], calc_updating=false, vedautowrite=false;
	lvars changed=vedchanged;
	ved_vstart();
	ved_l1();
	ved_vcheck();
	setchanged(changed);
enddefine;


;;; PROCEDURES FOR INTERACTIVE CHANGES

define ved_edl();
	;;; read in and process one line of table of input values
	lvars item;
	vars varsdone=[], popnewline=true,calc_updating=false;
	vedpositionpush();
	vedscreenleft();
	repeat
		getval(calcmoveitem)-> item;
	quitif( item == termin or item == newline);
	endrepeat;
	vedpositionpop();
	ved_vcheck();
enddefine;


define ved_edeq();
	;;; read new version of equation starting on current line
	lvars item;
	vars lefts varsdone=[];
	vedpositionpush();
	vedscreenleft();
	getequation(incharitem(vedrepeater)) -> item;
	vedpositionpop();
	unless item == [] then
		;;; replace previous version of the equation if there was one
		if equations matches [??lefts [^(front(item)) ==] ==] then
			item -> equations(listlength(lefts) fi_+ 1);
		else
			conspair(item, equations) -> equations;
		endif;
	endunless;
	false -> vcalcval(front(item));
	processequation(item);
	do_constraints();
enddefine;


define ved_edv;
	;;; redo one variable - to left of cursor
	vars varsdone=[];
	;;; go left to colon
	gobacktochar(`:`);
	;;; go left to beginning of variable
	vedwordleft();
	while vedcurrentchar() == `_` and vedcolumn > 1
	and	not(strmember(vedthisline()(vedcolumn-1),'\s\t'))
	do
		vedwordleft()
	endwhile;
	erase(getval(calcmoveitem));
	ved_vcheck();
enddefine;


define ved_showvals;
	;;; make sure output values appear on the screen
	appproperty(isoutvar,
					procedure(x,y);
						lvars x,y;
						if vcalcval(x) then vedupdate(x); endif;
					endprocedure);
enddefine;


define lconstant do_vrow(default);
	;;; produce a row with strings appended to strings
	lvars col;
	vars string left col_width cols;
	vars vedbreak=false,vedautowrite=false;
	sysparse_string(vedargument) --> [?string ?left ?col_width ??cols];
	vedlinebelow();
	unless fast_member(left, ['left' 'right' '<' '>']) then
		mishap('EXPECTING left or right, found: ' >< left, [])
	endunless;
	unless isinteger(col_width) then
		mishap('EXPECTING integer, found: ' >< col_width)
	endunless;
	;;; turn left into a boolean saying whether to add on left or right
	(left = 'left' or left = '<') -> left;
	fast_for col in cols do
		vedinsertstring(
			if left then string sys_>< col else col sys_>< string endif
			sys_>< default);
		until vedcolumn mod col_width == 1 do vedcharright() enduntil;
	endfor;
	vedscreenleft();
enddefine;

define ved_row;
	do_vrow(':0');
enddefine;

define ved_outrow;
	do_vrow('::.');
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- John Gibson, Jun  3 1991
		Uses vedscr_flush_output
--- Aaron Sloman, Jun  1 1987 improved an error message
--- Aaron Sloman, Aug  4 1986 replaced vedwordright with vedmoveitem
	in vedupdate, and made ved_vcheck restore its position, to ensure
	ved_run works.
--- Aaron Sloman, Jul 27 1986
	Made more efficient, generalised, and the help file re-written.
	Now handles negative numbers, etc.
*/
