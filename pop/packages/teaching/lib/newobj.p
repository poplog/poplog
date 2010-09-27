/*  --- Copyright University of Sussex 1989.  All rights reserved. ---------
 >  File:           C.all/lib/lib/newobj.p
 >  Purpose:        Demonstration object-oriented system using processes
 >  Author:         Aaron Sloman, 1985 (see revisions)
 >  Documentation:  HELP * NEWOBJ
 >  Related Files:  TEACH * ADVENT.NEWOBJ
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

/* LIB NEWOBJ    -     A PACKAGE FOR OBJECT ORIENTED PROGRAMMING

See HELP * NEWOBJ for details

Modified A. Sloman. June 1985 to include DEFAULTS field before START_ACTIONS

LIB OBJ was a package for object oriented programming, using POP-11
processes, implemented in May 1983. LIB NEWOBJ extends this to provide
multiple inheritance and some other extensions and minor bug-fixes.

*/

;;; Perhaps not all of these should be exported.

section class =>
;;;;;;/*
		with endwith >--> <--< |--> <--|
		CLASS ENDCLASS SUBCLASS_OF CLASS_FIELDS
		DEFAULTS START_ACTIONS MESSAGE_ACTIONS
		message, self, class_key, classtype_pr,
		classname,superclasses,subclasses,classfields,
		defaultactions, startactions,
		message_actions, class_procedure,
		class_props, consclasstype, isclasstype
		class_of_name   ;;; mapping from names to classes
		class_warning   ;;; procedure run when a class is redefined
		user_class_initial  ;;; run when a new class is created
		new_instance new
		default_response    ;;; default response procedure
		Classkey_of_instance
		allfields, all_supers
		check_duplicate_field   ;;; user definable
;;;;;;*/
;

vars class_procedure;
global vars self class_key Classkey_of_instance ;

vars name;  ;;; local to every object

;;; Message sending procedures
define global 9 message >--> obj;
	lvars obj;
	vars arg_num OLDinterrupt self;
	if obj.isword then valof(obj) -> obj endif;
	unless isprocess(obj) and isliveprocess(obj) then
		mishap(message,obj,2,'MESSAGE SENT TO NON(LIVE)-PROCESS')
	endunless;
	if obj == self then
		;;; already running
		if isword(message) then valof(message)
		elseif isprocedure(message) then chain(message)
		else mishap(name,message,2,'OBJECT SENDING MESSAGE TO ITSELF');
		endif
	else
		obj -> self;        ;;; make sure environment is set up
		interrupt -> OLDinterrupt;
		define interrupt;
			;;; prevent abnormal exit, which would kill the process
			;;; exit from this call, by resuming a process which will
			;;; re-run this process in such a way as to get it ready to
			;;; run normally next time
			consproc(0,OLDinterrupt) -> message;    ;;; will cause a resume
			OLDinterrupt -> interrupt;
			exitto(class_procedure(class_key));
		enddefine;

		if isinteger(message) then
			message -> arg_num; -> message
		else
			0 -> arg_num;
		endif;
		runproc(arg_num,self)   ;;; after running come back, unlike |-->
	endif
enddefine;


define global 9 self <--< message;
	lvars message, self;
	chain(message, self, nonop >-->);
enddefine;


define global 9 Message |--> other;
	lvars Message other;
	if other.isword then valof(other) -> other endif;
	unless other.isprocess then
		mishap(other,1,'TARGET FOR |--> and <--| MUST BE PROCESS')
	endunless;
	Message;    ;;; left on stack - will be transferred by resume
	other ->> self -> message;  ;;; if message is a process, it will be resumed
	exitto(class_procedure(class_key));
enddefine;

define global 9 other <--| Message;
	lvars Message, other;
	chain(Message, other, nonop |-->)
enddefine;

/*
Syntax to enable one to write

	WITH object DO actions ENDWITH;

where the object is a class instance, and the actions define a procedure
to be evaluated in the environment of the instance.

*/

global vars syntax endwith;

define global syntax with;
	erase(pop11_comp_expr_to("do"));
	sysPROCEDURE([], 0);
	erase(pop11_comp_stmnt_seq_to("endwith"));
	sysPUSHQ(sysENDPROCEDURE());
	sysCALL("<--<");
enddefine;


;;; A class has a key with various classfields
global vars procedure (classname,superclasses,subclasses,classfields,
					defaultactions, startactions, message_actions,
					class_procedure, class_props, consclasstype, isclasstype);

recordclass classtype
		classname superclasses subclasses classfields
		defaultactions startactions
		message_actions class_procedure class_props ;

define procedure class_sub_print(class_key);
	lvars temp,class_key;
	define procedure class_sub_print(class_key);
		lvars class_key;
		;;; recursive calls should just print the name
		pr(classname(class_key));
	enddefine;
	superclasses(class_key) -> temp;
	printf(length(subclasses(class_key)), temp, classname(class_key),
				'<classtype %p, super %p, %p subclasses>')
enddefine;

define global procedure classtype_pr(class_key);
	;;; to print out a class type record, print name and information
	;;; about super and sub-classes
	lvars class_key;
	class_sub_print(class_key);
enddefine;

;;; Make this the printer for class type records
classtype_pr -> class_print(datakey(consclasstype(0,0,0,0,0,0,0,0,0)));


;;; Define mapping from class name to class key

global vars procedure class_of_name;

newproperty([],100,false,true) -> class_of_name;

define global procedure class_warning(Name);
	lvars Name;
	printf(Name,'\n;;; WARNING: CLASS %p BEING REDEFINED\n')
enddefine;


;;; Mechanisms for constructing classes and instances


define global new_instance(classname_or_class, new_instance_initialiser)
								->self;
	;;; create a new instance corresponding to the class
	;;; after the classinitialiser has run, this new_instance_initialiser will run
	lvars classname_or_class, new_instance_initialiser;
	vars Classkey_of_instance message;
	if isword(classname_or_class) then
		class_of_name(classname_or_class)
	else
		classname_or_class
	endif -> Classkey_of_instance;
	unless isclasstype(Classkey_of_instance) then
		mishap(classname_or_class,0,'CLASS OR CLASS NAME REQUIRED')
	endunless;
	consproc(0,class_procedure(Classkey_of_instance)) -> self;
	false -> message;
	runproc(new_instance_initialiser,1,self);
enddefine;

define set_field_value(list) -> list;
	lvars wd,list;
	destpair(list) -> list -> wd;
	destpair(list) -> list -> valof(wd)
enddefine;

define new(new_instance_info);
	;;; the argument may be of the form e.g.
	;;;     [person name john age 33 sex male]
	lvars class_of_New_instance;
	destpair(new_instance_info) -> new_instance_info ->class_of_New_instance;
	new_instance(class_of_New_instance,
				procedure;
					until null(new_instance_info) do
						set_field_value(new_instance_info) -> new_instance_info;
					enduntil;
				endprocedure);
enddefine;


define global 9 default_response;
	if isword(message) then valof(message)
	elseif isprocedure(message) then message();
	elseunless islist(message) or isprocess(message) then
		mishap(message,1,'BAD MESSAGE')
	endif;
enddefine;

;;; A user definable procedure to be run whenever a new class
;;; record is created.
global vars procedure user_class_initial;
	erase -> user_class_initial;        ;;; user assignable

define startclass(Name,supers,fieldlist,defaults,initial,mess_actions,class_proc);
	lvars item, Name,supers,fieldlist,defaults,initial,mess_actions,class_proc,
		new_classkey;

	if class_of_name(Name) then
		class_warning(Name)
	endif;
	if supers /== false and not(ispair(supers)) then
		mishap(supers,1,'NON-LIST OF SUPERCLASSES')
	endif;

	consclasstype(Name,supers,[],fieldlist,defaults,initial,
					mess_actions,class_proc,
					newproperty([],10,undef,true)) -> new_classkey;
	new_classkey ->  class_of_name(Name);
	if supers then
		for item in supers do
			new_classkey::subclasses(item) -> subclasses(item)
		endfor;
	endif;
	user_class_initial(new_classkey);
enddefine;

define checkread(closer) -> item;
	lvars closer, item;
	readitem() -> item;
	if identprops(item) == "syntax" then
		unless item == closer
		or (ispair(closer) and lmember(item,closer))
		then
		mishap(item,' EXPECTING ', closer, 3,'MISPLACED SYNTAX WORD: ')
		endunless;
	endif;
enddefine;

define check_readlist(closer) -> list;
	lvars closer item list;
	[% while nextitem() /= closer do checkread(closer) endwhile %] -> list;
enddefine;

vars syntax (ENDCLASS, SUBCLASS_OF, CLASS_FIELDS, START_ACTIONS,
		MESSAGE_ACTIONS);

define constant sysCALLQ_?(proc);
	lvars proc;
	if proc then sysCALLQ(proc) endif
enddefine;

define constant sysSETLOCALS(list);
	;;; make sure all the words in list are declared, and make them
	;;; local to current procedure
	;;; If an element is a list do the same recursively
	lvars item, list;
	for item in list do
		if islist(item) then sysSETLOCALS(item)         ;;; ??? needed?
		else sysSYNTAX(item,0,false); sysLOCAL(item)
		endif
	endfor;
enddefine;


define constant run_other_process();
	;;; the value of message is a process to be run.
	;;; there may or may not be something on the stack to be sent as
	;;; a message
	lvars other_process;
	message -> other_process;
	if stacklength() == 0 then
		false
	endif -> message;
;;;message =>
;;;"name" >--> other_process =>
	resume(stacklength(), other_process)
enddefine;

define global procedure union(list1,list2,flag) -> list;
	lvars item list list1 list2 flag;
	if flag then
		;;; don't copy list1. Assume non-redundant
		ncrev(list1) -> list
	else
		[] -> list;
		for item in list1 do
			unless lmember(item,list) then conspair(item,list) -> list endunless;
		endfor;
	endif;
	for item in list2 do
		unless lmember(item,list) then conspair(item,list) -> list endunless
	endfor;
	ncrev(list) -> list;
enddefine;

;;; Utilities for getting at all super-classes of a class.
define global procedure all_supers(class) -> list;
	;;; class is an object, a class record, a class name, or a list of classes
	lvars class list sup supers;
	if isprocess(class) then "class_key" >--> class
	elseif isword(class) then class_of_name(class)
	else class
	endif -> class;     ;;; now a class record or list
	[] -> list;
	if islist(class) then
		for sup in class do union(list,all_supers(sup),true) -> list endfor
	else
		superclasses(class) -> supers;
		if supers then
			for sup in supers do
				union(list,all_supers(sup),true) -> list;
			endfor;
			list nc_<> [^class]
		else
			[^class]
		endif -> list;
	endif;
enddefine;

;;; utilities for getting at field names corresponding to a class or object
define global procedure allfields (classes) -> list;
	;;; return all the field names corresponding to the classes in the list
	lvars list classes class ;
	[] -> list;
	if classes then
		for class in classes do
			union(list,classfields(class),true) -> list;
		endfor;
	endif
enddefine;


define global procedure check_duplicate_field(list1,list2,Name);
	;;; user definable. check for reused field name.
	lvars item, list1,list2, Name;
	for item in list1 do
		if lmember(item,list2) then
		printf(Name,item,'\n;;; Field name %p duplicated in CLASS %p')
		endif;
	endfor;
enddefine;


constant CLASS;
define global syntax CLASS ;
	lvars item allsups Name fieldlist supers defaults
		 init_actions mess_actions temp start run resuming class_proc;
	;;; read in class Name
	itemread() -> Name;
	erase(pop11_need_nextitem("SUBCLASS_OF"));

	;;; then names of super classes
	check_readlist("CLASS_FIELDS") -> supers;

	if supers==[] or supers = [undef] then false
	else
		[% for item in supers do
			class_of_name(item) ->> item;
;;;;;[super ^item] =>
			unless item then mishap(item,1,'NON CLASS NAME GIVEN:') endunless;
		  endfor
		%]
	endif -> supers;

	if supers then all_supers(supers) else false endif-> allsups;

;;;;; [supers ^supers allsups ^allsups] =>

	erase(pop11_need_nextitem("CLASS_FIELDS"));

	;;; read in field names and declare them globally as variables
	[%until (checkread("DEFAULTS") ->> item) == "DEFAULTS" do
		unless item == "," then
			item;
			;;; make sure it is declared as a variable
			sysSYNTAX(item,0,false);
		endunless;
	enduntil%] -> fieldlist;

	;;; Compile default actions, to be performed before initialisation
	;;; is done.
	if (nextitem()->> item) == "START_ACTIONS" then
		erase(readitem());
		false
	else
		;;; now compile initialisation procedure
		sysPROCEDURE('defaults_'><Name,0);
			erase(pop11_comp_stmnt_seq_to("START_ACTIONS"));
		sysENDPROCEDURE()
	endif
	 -> defaults;

	;;; Compile an instance initialisation procedure, if necessary
	if (nextitem()->> item) == "MESSAGE_ACTIONS" then
		erase(readitem());
		false
	else
		;;; now compile initialisation procedure
		sysPROCEDURE('initialise_'><Name,0);
			erase(pop11_comp_stmnt_seq_to("MESSAGE_ACTIONS"));
		sysENDPROCEDURE()
	endif
	 -> init_actions;

	;;; compile procedure to deal with messages, if necessary
	if nextitem() == "ENDCLASS" then
		false;
		erase(readitem())
	else
		;;; compile procedure to deal with messages
		sysPROCEDURE('messages_'><Name,0);
			erase(pop11_comp_stmnt_seq_to("ENDCLASS"));
		sysENDPROCEDURE()
	endif -> mess_actions;

	;;; Now create the main procedure for the class;

	sysPROCEDURE(Name,0);
		;;; make all the field names, plus the default names, local
		sysVARS("class_key",0);
		;;; declare field names inherited from superclasses
		allfields(allsups) -> item;
		check_duplicate_field(fieldlist,item,Name); ;;; may print warning

		sysSETLOCALS(union(fieldlist, item, false));

		;;; give each instance default value for: class_key
		sysPUSH("Classkey_of_instance");    ;;; will have a value at initialisation time
		sysPOP("class_key");
		;;; call super class defaults
		if supers then
			for item in allsups do
				;;;;; [initialiser ^item] =>
				;;; run the default actions for the super class
				sysCALLQ_?(defaultactions(item));
			endfor
		endif;
		sysCALLQ_?(defaults);   ;;; run class defaults
		sysCALLQ(apply);        ;;; call instance initialiser - on stack
		;;; call super class initialisers
		if supers then
			for item in allsups do
				;;;;; [initialiser ^item] =>
				;;; run the initialisers for the super class
				sysCALLQ_?(startactions(item));
			endfor
		endif;
		sysCALLQ_?(init_actions);   ;;; run class initialiser

		;;; initialisation ends here

		;;; start a loop - forever read in message and process then suspend
		;;; except that if the value of the message is a process, then
		;;; resume that process. use whatever is on the stack.
		sysNEW_LABEL() -> start;
		sysNEW_LABEL() -> run;
		sysNEW_LABEL() -> resuming;
		sysLABEL(start);
		sysPUSH("message");
		sysCALLQ(isprocess);
		sysIFSO(resuming);
		sysCALLQ(stacklength);
		sysCALLQ(suspend);
		sysGOTO(run);
		sysLABEL(resuming);
		;;; resume process in value of message. The message to be sent it
		;;; may be on the top of the stack.
		sysCALLQ(run_other_process);

		sysLABEL(run);

		;;; note since process is run in context of >-->, "message"
		;;; and "self" will always have values.
		;;; see if super_classes have anything to say about the action
		;;; then the procedure for this class
		if supers then
			for item in allsups do
				;;; run the message actions for the super class
				;;;;;[mess actions ^(message_actions(item))] =>
				sysCALLQ_?(message_actions(item));
			endfor
		endif;
		sysCALLQ_?(mess_actions);
		;;; default action
		sysCALLQ(nonop default_response);
		sysGOTO(start);
	sysENDPROCEDURE()
		-> class_proc;

	startclass(Name,supers,fieldlist,defaults,init_actions,mess_actions,class_proc);
enddefine;

unless member("CLASS", vedopeners) then
	[^^vedopeners with CLASS] -> vedopeners;
	[^^vedclosers endwith  ENDCLASS] -> vedclosers;
	[^^vedbackers SUBCLASS_OF SUBCLASS_OF, CLASS_FIELDS, START_ACTIONS,
		MESSAGE_ACTIONS] -> vedbackers;
endunless;

section_cancel(current_section);
endsection;

section;

global vars name;

define global default_printer;
	pr('<' >< classname(class_key) >< space >< name >< '>')
enddefine;


CLASS thing
SUBCLASS_OF undef
CLASS_FIELDS
	name
	class_printer
DEFAULTS
	default_printer -> class_printer
START_ACTIONS
MESSAGE_ACTIONS
ENDCLASS;

endsection;



/*  --- Revision History ---------------------------------------------------
--- John Gibson, Aug 13 1989
		Replaced old sys- compiler procedures with pop11_ ones.
--- Aaron Sloman, Jul 30 1985 fixed bug in |-->
	It used not to assign to 'self' properly.
 */
