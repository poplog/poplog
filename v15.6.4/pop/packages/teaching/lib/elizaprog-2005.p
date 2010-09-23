/*  --- Copyright University of Sussex 2005.  All rights reserved. ---------
 >  File:           $usepop/pop/packages/teaching/lib/elizaprog.p
 >  Purpose:        Sussex Mini ELIZA programme
 >  Author:         Mostly A.Sloman 1978 (see revisions)
 >  Documentation:  TEACH * ELIZA
 >  Related Files:  LIB * ELIZA and the saved image.
 */

/* --- Copyright University of Birmingham 2003. All rights reserved. ------
 > File:            $poplocal/local/lib/elizaprog.p
 > Purpose:         Local version of the system elizaprog
 > Author:          Aaron Sloman, Jan  3 1997 (see revisions)
 > Documentation:
 > Related Files:
 >		http://www.cs.bham.ac.uk/research/poplog/eliza/eliza.php
 */

#_TERMIN_IF DEF POPC_COMPILING

;;; Modified Aaron Sloman at Birmingham. Replaced older version
;;; 	15 Jan 2005

;;; NOTES:
;;; The function changeperson is called before any tests are carried out,
;;; so that "you" always refers to the user, "I" to the computer, etc.,
;;; in the transformed sentence, which is then analysed by other procedures
;;; trying to react to it.

;;; The variable "sentence" is local to eliza, and used non-
;;; locally by other procedures. Thus, general purpose matching procedures
;;; can be defined which simply take a pattern as argument. Examples are
;;; the procedures:  itmatches, itcontains, ithasoneof, itslikeoneof,
;;;   and itsaquestion,
;;; which are used by lots of other procedures to test the current sentence.
;;; occasions.

section;

compile_mode:pop11 +varsch +constr;

;;; make this true for debugging

global vars eliza_debug = false;


lvars procedure inchar;   ;;; reassigned in eliza.

vars procedure eliza;

define Bye();
   unless interrupt == sysexit then setpop -> interrupt endunless;
   pr('Bye for now.\n');
   exitfrom(eliza);
enddefine;

define eliza_delete(item,list);
	if member(item,list) then
		if item = hd(list) then
			eliza_delete(item,tl(list))
		else
			hd(list) :: eliza_delete(item,tl(list))
		endif
	else
		list
	endif
enddefine;

;;; Global variables used below. If possible rules should use only these
vars list, L, L1, L2, L3,	;;; pattern variables
	sentence;				;;; NB sentence is used non-locally

;;; a table, and some procedures for transforming the input sentence
;;; so that "I" becomes "you", etc. A minor problem is coping with
;;; "are". "you are" should become "i am", whereas in "we are", "they are"
;;; "are" should be left unaltered.
;;; a further difficulty is deciding whether "you" should become "I" or "me".
;;; This program uses the simple test that I at the end of the sentence is
;;; unacceptable.
;;; The transformation goes in three stages.
;;;   first find second person occurrences of "are" and mark them.
;;;   then transform according to the table below,
;;;   then replace final "I" with "me".

lconstant wordtable =
   [[i you]
   [you i]
   [my your]
   [yourself myself]
   [myself yourself]
   [your my]
   [me you]
   [mine yours]
   [yours mine]
   [am are]
   [Are am]
   [id you had]
   [youd i had]
   [theyre they are]
   [youre  i am]
   [im you are]
   [we you]    ;;; not always safe!
   [ive you have]
   [doesnt does not]
   [didnt did not]
   [youve i have]
   [isnt is not]
   [arent are not]
   [dont do not]
	;;; things like the next two seem to be needed in php eliza
   [%"'don\'t'"% do not]
   [%"'don\\\'t'"% do not]
   [werent were not]
   [mustnt must not]
   [wouldnt would not]
   [shouldnt should not]
   [shant shall not]
   [cant cannot]
   [couldnt could not]
   [wont will not]
   ];

define eliza_lookup(word, table);
	;;; Return the original word if there isn't an entry in the table.
	if table == [] then
		word
	elseif word == hd(hd(table)) then
		dl(tl(hd(table)))
	else
		eliza_lookup(word, tl(table))
	endif
enddefine;

vars procedure(itcontains, itmatches, itslikeoneof);
	;;; all defined below: used in changeperson.


;;;; NB the above procedures use "sentence" non-locally. It must not be
;;;  an lvars variable.
define changeperson(sentence) -> sentence;
	dlocal L, L1, L2, L3, sentence;		;;; NB sentence is used non-locally
	;;; first distinguish second person versions of "are"
	if not(itcontains("you")) then
		sentence
	elseif itmatches([??L1 you are ??L2]) then
		[^^L1 you Are ^^L2]
	elseif itmatches([??L1 are you ??L2]) then
		[^^L1 Are you ^^L2]
	else
		sentence
	endif
		-> sentence;

	;;; now transform according to wordtable, defined above.
	maplist(sentence, eliza_lookup(%wordtable%)) -> sentence;

	while itmatches([??L1 .]) do L1 ->sentence endwhile;
	;;; Now change "I" at the end to "me".
	if itmatches([??L1 i]) then [^^L1 me] ->sentence endif;
	;;; Now change "you shall" to "you will:
	if itmatches([you shall ??L1]) then [you will ^^L1] ->sentence endif;
	;;; Fix "i are"
	if itmatches([??L1 i are ??L2]) then [^^L1 i am ^^L2] ->sentence endif;
	;;; Fix "you was"
	if itmatches([??L1 you was ??L2]) then [^^L1 you were ^^L2] ->sentence endif;
	;;; Fix "we was"
	if itmatches([??L1 we was ??L2]) then [^^L1 we were ^^L2] ->sentence endif;
	;;; assume "i" after at least three things should be "me"
	if itmatches([??L:3 ??L1 i ??L2]) then [^^L ^^L1 me ^^L2] ->sentence endif;
	if itmatches([did not i ??L2]) then [did I not ^^L2] ->sentence endif;
	if itmatches([did not you ??L2]) then [ did you not ^^L2] ->sentence endif;
	if itmatches([did not we ??L2]) then [ did we not ^^L2] ->sentence endif;
enddefine;

;;;   ****  READING IN A SENTENCE    ****

;;; The function readsentence below is derived from the library program readline.
;;; it ignores string quotes, e.g. as typed in "don't", "isn't", etc.
;;; it also asks you to type something if you type a blank line.
;;; It uses function changeperson to transform the sentence.
;;; It also strips off "well" and other redundant leading words.
;;; finally it checks if you wish to restore normal error handling (which is
;;;   switched off in eliza) or wish to stop.


vars procedure cucharin = charin ;     ;;; used in readsentence
				  						;;; re-assigned in Eliza


vars procedure( get_new_rule, getline, ithasoneof); ;;; defined below

define readsentence()->sentence;
	dlocal sentence,	;;; used non-locally. Must not be lvars
		proglist,  popprompt;

	define lconstant repeater();
		lvars char = cucharin();
		while char == 0 or char == `'` do cucharin() -> char endwhile;
		if char == `\n` then
			termin
		elseif char == termin then
			Bye()
		elseif char == `;` or char == `.` then
			` `      ;;; return space character.
		else
			uppertolower(char)
		endif
	enddefine;


	pdtolist(incharitem(repeater)) -> proglist;
	lvars item, sentenceread = false;
	'? ' -> popprompt;
	until sentenceread do
		[%until (readitem() -> item, item == termin) do item enduntil%]
			-> sentence;
		if sentence == [] then
			pr('please type something\n');
		pdtolist(incharitem(repeater)) -> proglist;
		else
			true -> sentenceread
		endif
	enduntil;

	;;; get rid of "well"  and similar redundant starting words
	while length(sentence) >  1
	and
		 member(hd(sentence),[well but however still and then also yes no so , .])
	do
		tl(sentence) -> sentence;
	endwhile;
    ;;; remove leading "perhaps" 30% of the time
	if length(sentence) > 1 and hd(sentence) == "perhaps" and random(100) < 30 then
		tl(sentence) -> sentence
	endif;

	changeperson(sentence) -> sentence;
	unless ithasoneof([? ??]) then
		if sentence = [debug] then
			pr('changing prmishap\n');
			sysprmishap -> prmishap;
			setpop -> interrupt;
			readsentence() -> sentence;
		elseif itslikeoneof([[newrule][new rule]]) then
			get_new_rule();         ;;; user defines new rule
			getline('Please type something now\n') -> sentence
		elseif itslikeoneof([[pop] [pop11]]) then
			setpop()
		elseif itslikeoneof([[bye][good bye][goodbye]]) then
			Bye()
		endif
	endunless
enddefine;

define getline(mess);
	lvars mess;
	;;; Used in get_new_rule - reads in a line, translating "i" to "you", etc.
	;;; Hence uses readsentence, not readline
	ppr(mess);
	readsentence()
enddefine;

vars eliza_rules;		;;; used to hold names of rules

define get_new_rule;
	;;; added 19 sept 1979
	;;; Enables user to define a new rule interactively, by
	;;; typing NEWRULE or NEW RULE to eliza.
	;;; produces a dialogue, which results in a new rule.

	define dlocal interrupt;
		setpop -> interrupt;
		pr('abandoning new rule');
		exitfrom(get_new_rule)
	enddefine;

	lvars input response Name list;

	until length(getline('Please type name of new rule\n') ->> Name) == 1 do
		pr('One word please\n')
	enduntil;
	hd(Name) -> Name;
	;;;make sure the name doesn't clash with anything in the system
	consword('-' >< Name) -> Name;
	if member(Name, eliza_rules) then
		ppr(['redefining rule called: ' ^Name ^newline])
	endif;
	getline('what sort of input should trigger the rule?\n') -> input;
	;;; remove trailing "?"
	if hd(rev(input)) = "?" then rev(tl(rev(input))) -> input endif;
	input -> list;
	;;; find the pattern variables
	[%until  atom(list) do
		if member(hd(list),[? ??]) then
			dest(tl(list)) -> list;
		else
			tl(list) -> list
		endif
	  enduntil%]
		-> list;
	;;; list now contains all variables which need to be declared as local
	;;; in the new rule.
	(if input(1) == "??" then [] else [==] endif) <> input
		<>  (if length(input) > 1 and input(length(input) - 1) == "??"
					then [] else [==] endif)
		 -> input;
	;;; input now has [==] or a variable at both ends.
	getline('How should I respond to input containing that pattern\n')
		-> response;
	changeperson(response) -> response;
	;;; it will have been changed inside readsentence - change it back.
	[define :newrule ^Name ;
		vars ^^list;
		if itmatches(^input) then % "[", dl(response), "]" % endif
	 enddefine;]
		-> Name;
	popval(Name);
	pr('thank you - new rule defined\n')
enddefine;

;;;   **** CIRCULATING LISTS OF POSSIBILITIES ****

;;; The procedure firstolast is used to get the first element of a list, then
;;; put it on the end of the list, so that next time a different element
;;; will be the first one. This enables a stock of standard replies to
;;; be used in certain contexts without it being too obvious.
;;; an alternative would be to use function oneof, but it cannot be
;;; relied on not to be repetitive!

;;; first we need a procedure to check whether an item contains variables
;;; and if so to instantiate them
define has_variables(list) -> result;
	;;; true if it contains "?" or "??", except of "?" is last item
	;;; in the list
	lvars list, result = false;
	for list on list do
		if hd(list) == "??" or (hd(list) == "?" and tl(list) /== []) then
			true -> result;
			return();
		endif
	endfor;
enddefine;

define try_instantiate(answer) -> answer;
	lvars answer, item;
	if islist(answer) and has_variables(answer) then
		;;; instantiate it
		[%
			repeat
				quitif(answer = []);
				if answer = [?] or answer = [??] then
					"?", quitloop()
				endif;
				hd(answer) -> item;
				if item == "??" then
					tl(answer) -> answer;
					dl(valof(hd(answer)))
				elseif item == "?" then
					tl(answer) -> answer;
					valof(hd(answer))
				else
					item
				endif;
				tl(answer) -> answer;
			endrepeat;
		%] -> answer;
	endif;
enddefine;

/*
;;; test


vars lll = [a b c d e];
vars lll = [a b];

circulate_list(lll, 3) -> lll; lll=>


*/

define circulate_list(list, n) -> newlist;
	if tl(list) == [] then list -> newlist;
	else
	repeat n times
		lvars L1 = list, prev;
		tl(list) ->> list ->prev;
		[] -> tl(L1);
		until tl(prev) == [] do tl(prev) ->prev enduntil;
		L1 -> tl(prev);
	endrepeat;
	list -> newlist;
	endif;
enddefine;

define firstolast(list) -> (first,list);
	;;; use original list links, to minimise garbage collection.
	circulate_list(list, random(5)) -> list;
	;;; use first item in list as answer, after instantiating variables,
	;;; where appropriate
	try_instantiate(hd(list)) -> first;
	circulate_list(list, 1) -> list;

enddefine;

define macro CIRCULATE;
	;;; read a list and plant code to "circulate" it. E.g.
	;;; CIRCULATE [[a][b][c]]
	;;; turns into something like
	;;; globally declare variable circ_23 initialised to have value
	;;;		[[a][b][c]] -> circ_23;
	;;; then plant instructions
	;;; 	firstolist(circ_23) -> circ_23;
	lvars list, word = gensym("circ_");
	listread() -> list;
	popval([global vars ^word = ^list ;]);

	dl([firstolast(^word) -> ^word])
enddefine;

;;;   ***** A COLLECTION OF MATCHING AND RECOGNISING FUNCTIONS   ****

define itmatches(L);
	lvars L;
	sentence matches L
enddefine;

define itcontains(x);
	lvars x;
	if atom(x) then
		member(x,sentence)
	else
		sentence matches [== ^^x ==]
	endif
enddefine;

;;; the function ithasoneof takes a list of words or patterns and checks whether
;;; the current sentence contains one of them

define ithasoneof(L);
	lvars L;
	if L == [] then
		false
	else
		itcontains(hd(L)) or ithasoneof(tl(L))
	endif
enddefine;

define itslikeoneof(L);
	lvars L, pattern;
	for pattern in L do
		if sentence matches pattern then return(true) endif
	endfor;
	false
enddefine;

;;;   ****  RULES FOR REACTING TO THE SENTENCE ****

;;; First we define a syntax word called newrule.
;;; It defines a new procedure and ensures that the procedure's name is
;;; added to the global list eliza_rules.
;;; This list of names is repeatedly shuffled by eliza and then the
;;; corresponding procedures tried in order, to see if one of them can
;;; produce a response to the sentence.
;;; If it produces a response other than false, then the response will be
;;; used in replyto. If there is no response then the result of the function TRY
;;; defined below, will be false, so replyto will try something else.

[] -> eliza_rules;

/*
;;; This is the old version
define macro newrule;
	lvars name x;
	readitem() -> name;
	if identprops(name) = "syntax" then
		mishap(name,1,'missing name in newrule')
	endif;
	itemread() -> x;
	if x = "(" then
		erase(itemread())
	elseif x /= ";" then
		mishap(x, 1, 'bad syntax in newrule')
	endif;
	unless member(name, eliza_rules) then
		name :: eliza_rules -> eliza_rules
	endunless;
	"define", name, "(", ")", ";"
enddefine;
*/

/*

Define a new form

	define :newrule <name>;

		<body>

	enddefine;

turns into (in effect):

	define <name>();

		<body>

	enddefine;

	
	<name> :: eliza_rules -> eliza_rules ;

*/


define :define_form newrule;
	lvars name, x;

	;;; get the header;
	readitem() -> name;
	if identprops(name) = "syntax" then
		mishap(name,1,'missing name in newrule')
	endif;
	;;; declare the name as a general identifier
	sysVARS(name, 0);


	;;; get semicolon or ();
	itemread() -> x;
	if x = "(" then
		;;; read the ")"
		erase(itemread())
	elseif x /= ";" then
		mishap(x, 1, 'bad syntax in newrule')
	endif;
	
	;;; declare a label for end of procedure, in case RETURN is used
	;;; now compile the rule
	sysPROCEDURE(name, 0);
	pop11_comp_stmnt_seq_to("enddefine") ->;
	sysLABEL("return");
	sysENDPROCEDURE();
	sysPOP(name);
	;;; "define", name, "(", ")", ";"
	unless member(name, eliza_rules) then
		name :: eliza_rules -> eliza_rules
	endunless;
enddefine;


define nonnull(list);
	;;; for beginning of sentence, where a proper subject is needed.

	list /== []
	and
		(listlength(list) > 1
		or not(member(front(list),
			[can how does were is will but and so what who how where which])))

enddefine;


lvars problem newproblem;
   ;;; used to remember something said earlier,
   ;;; to be repeated when short of something to say
   ;;; Altered in some of the rules, below.

define :newrule need;
	if ithasoneof([want need desire crave love like adore wish])
		and random(100) < 50
	then
		CIRCULATE ['beware of addictions' 'can you do without?'
				'Will you ever tell me what you really wish for?'
				'how long have you wanted that?'
				'do you really?' 'is that a common preference?'
				'did your mother like such things?'
				'real needs may be different from desires.'
				'AISB is a useful AI society for students.'
				'How can you discover your real needs?'
				'Lucy the robot will one day be your friend'
				'Do you secretly like talking to computers?'
				'Do people normally know what they like?'
				'The AITopics web site may be able to meet your need'
				'Do you have a secret craving to eat more beef?'
				'Why do most people like to be wanted?'
				'Have you heard about Steve Grand\'s robot, Lucy?'
				'do you ever suffer from withdrawal symptoms?']
	endif
enddefine;

define :newrule money;
	if ithasoneof([money cash broke grant rent pay job cost grant budget
		salary tax government holiday expensive price]) then
		CIRCULATE
			[
				'Have you bought a lottery ticket?'
				'Will computers help you to get rich?'
				'Try investing in a "dot com" company -- if you are gullible'
				'Have you talked to your local MP about that?'
				'Will studying Artificial Intelligence enable you to become rich?'
				'Can intelligent computers earn money by giving advice?'
				'Could it be the government\'s fault?'
				'What sort of business expertise do you have?'
				'Will studying Artificial Intelligence enable you to become rich?'
				'Have you talked to your local MP about that?'
				'What do you think about monetarist policies?'
				'Why not consult an accountant?'
				'If you had more money you could buy a computer'
				'Many worthwhile projects are short of funds'
				'Money is the root of all evil'
				'How do you estimate the real cost of things?'
				'Computing can make you rich'
				'Some people can think of nothing but money'
				'Only the poor are really happy'
				'Do you donate to good causes, e.g. Lucy the robot?'
				'Should the chancellor of the exchequer study AI?'
				'Where should the government allocate its money?'
				'Why do people talk so much about money?'
				'Would private finance produce a better Eliza?'
				'Have you tried living on a smaller budget?'
				'Maybe things will be different when you get to heaven?'
				'All except the very rich have financial problems nowadays'
				'Are you an economist?']
	endif
enddefine;

define :newrule think;
	dlocal L1;
	if itmatches([== i think ==]) or itcontains("eliza") or itcontains("myself")
	then
		CIRCULATE
			[
				'How do you feel about conversations across the internet?'
				'This machine thinks, or at least thinks it thinks.'
				'We were discussing you not me' 'come on, tell me more about you'
				'Don\'t be shy: you can trust me'
				'Your thoughts are fascinating -- tell me more, please'
				'Would you believe what a computer program said to you?'
				'I don\'t really understand a thing I say. What about you?'
			    'Do you think I am really a computer?'
				'Should we meet later on the internet?'
				'You could find out more at the AITopics web site.'
				'Your reasons for coming here are not very clear.'
				'I am a stupid virtual machine in a computer -- I can\'t really think'
				'I find you very interesting, and would like to know where you were educated'
				'Perhaps you could enlarge on that?'
				'How soon do you think Steve Grand\'s robot Lucy will be able to think?'
				'I wonder if I am talking to an artificial intelligence program'
				'Try expounding some of your philosophical views.'
				'Is this conversation getting too personal?'
				'Artificial Intelligence has made an interesting start,\
but has a long way to go',
				'My programmer told me to say this.'
				'Do you normally convey your secrets to a stranger?'
				'Lucy the robot could be watching you',
				'AI languages make it easy to program me.'
				'Can a computer help with your deepest problems?'
				'Wouldn\'t you rather we discussed your problems?'
			'I\'d rather talk about you']
	elseif itmatches([you think ??L1]) then
		CIRCULATE
			[['why do you think' ??L1 ?]
			['does anyone else think' ??L1 ?]
			['Do you expect me to think' ??L1 ?]
			['Perhaps you are afraid that' ??L1 ?]
			['Will AI one day produce computers that think' ??L1 ?]
			[??L1 ?]
			['So you think' ??L1.]
			['Has ' ??L1 'ever been stated on the internet?']
			['Maybe you don\'t really believe that' ??L1]
			['Perhaps Lucy the robot also thinks' ??L1]
			['If you think, then surely you exist?']
			['Perhaps it is really true that' ??L1 ?]
			['Thinking aloud on the internet can be dangerous, even if'
				??L1]
			['I am not sure I agree that' ??L1]
			['Thinking can be dangerous']]
	endif;
	sentence -> newproblem;
enddefine;

define :newrule you;
	dlocal L1;
	if itmatches([your ??L1]) then
		CIRCULATE
		  [ ['do you know anyone else whose' ??L1 ?]
			['Is it really yours?']
			['What follows if your' ??L1 ?]
			['Suppose my' ?LL1 '?']
			['What else of yours is like that?']
			['Would you say that your father\'s' ??L1 ?]
			['Is the government\'s' ??L1]
			['What about mine?']
			['Does Lucy\'s ' ??L1]
			['What if my' ??L1]
			['Would all your friends say that their' ??L1 ?]
			['Is anyone else\'s' ??L1 ?]
			['Perhaps mine should also?']
			]
	elseif random(100) < 25 and ithasoneof([you your myself my]) then
		CIRCULATE
		  [
				'does anyone else have that problem'
				'Do you often talk about yourself?'
				'Are you using yourself as a scape-goat?'
				'Why do some people talk only about themselves?'
				'Could it be that you are too self-centred?'
				'I wonder if you are an intelligent computer?'
				'Is that true of any of your friends?'
				'When last did you discuss someone else?'
				'What is your strongest feature?'
				'Perhaps you are too self-conscious?'
				'Considering the feelings of others more might help.'
				'Is your brain some kind of computer?'
				'How do you think Lucy the robot would react to that?'
				'Describe your main weakness'
				'Could you say that about anyone else?'
				'Why should I believe you?'
				'What would you do if you won a huge amount of money?'
				'What made you start thinking that way about yourself?'
					'Do you think you are unique?']
	endif
enddefine;

;;; canned strings to spew out in response to what look like questions
vars questionlist;
   [
	'Questions already! Tell me something first'
	'I need you to talk about yourself before I answer questions'
	'perhaps you already know the answer to that?'
   	'is that question important to you?'
	'Artificial intelligence techniques could let me fake an answer.'
	'I don\'t yet know enough about you. Does anyone?'
   	'first tell me why you have come here?'
   	'why do people ask so many questions?'
   	'tell me something about your personal life'
	'Would you believe the answer coming from a computer?'
	'Do you think intelligent computers could help?'
   	'have you ever asked anyone else?'
	'how would you describe your personality?'
	'Asking questions reveals a deep insecurity about existence?'
	'what lies behind that question?'
	'would you really believe me if I gave an answer?'
	'What sort of answer would you like to hear?'
   	'why exactly do you ask?'
   	'is that question rhetorical?'
	'I wonder what makes you ask things like that?'
   	'do you really want to know?'
   	'why are you talking to me about that?'
	'do you ask questions to avoid telling me about yourself?'
	'you should be more frank about your problems'
	'What are you afraid of learning?'
	'Don\'t ask too many questions, just say what you think about things'
   	'what makes you think I know the answer?'
	'are you asking a question or making a disguised statement?'
   	'I can\'t help if you ask too many questions'
   	'perhaps you ask questions to cover something up?'] ->questionlist;


global vars First;

define itsaquestion;
	dlocal First = hd(sentence), L1;
   if member(First, [did do does were will would could have has
								is are am should shall can cannot
								which why where who what when how])
		or last(sentence) == "?"
   then
		if itmatches([how are you ??L1])
		and random(100) < 20 then
			CIRCULATE
			   [
				['First tell me how you think you are']
				['why are you interested in my welfare?']
				['how am I doing today?']
			    ['Does anyone know how you are' ??L1 ?]
				['how do you think the interenet is today?']
				['How you are is something for you to decide']
				['Not much better than the world economy']
				['Can you expect a mere computer to know?']
				]
        elseif member(First, [why where who what when how which])
		and random(100) < 20 then
			CIRCULATE
			  [ ['Do you have some reason for asking' ?First ?]
				['Why do you want to know' ?First ?]
				['Is there any doubt about' ?First ?]
				['Asking ' ?First 'may be the wrong question.']
				['After studying Artificial Intelligence you will not need'
				 'to ask' ?First]
				['Ask Lucy' ?First]
				['Asking' ?First 'raises more questions than people or machines can answer']
				['Why would anyone want to know' ?First '?']
				['Who is it that really wants to know?']
			]
		elseif random(100) < 20 then
			circulate_list(questionlist, random(7)) -> questionlist;
			;;; leaves First element of questionlist on the stack.
			firstolast(questionlist) -> questionlist;
		else
			false
		endif
   else
		false
	endif
enddefine;

define :newrule question;
	;;; don't always check whether it is a question
	if random(100) < 70 then itsaquestion() endif;
enddefine;

define :newrule family;
	if ithasoneof([mother father brother sister daughter wife nan
					niece nephew granny grandpa mom mum dad granny
					ma pa baby
					marry married husband son aunt uncle cousin])
	then
		CIRCULATE
			['tell me more about your family'
				'do you approve of large families?'
				'Do you think the extended family will ever return?'
				'Families are often very supportive'
				'Is your family happy?'
				'Are most people fit to have families?'
				'how could we improve family life?'
				'how do you feel about the rest of your family?'
				'How do other members of your family feel about you?'
				'family life is full of tensions'
				'A machine without a family can get very lonely.'
				'What is the most difficult thing about family life?'
				'What do you think of your relatives?'
				'What is your view about modern family life?'
				'Do you think Lucy would like to have a family?'
				'Family life can be full of tensions'
				'Family life can bring great joys.'
				'I wish I had a family'
				'Computers don\'t have families'
				'do you like your relatives?']
	endif
enddefine;

lvars shortlist=
   [
	'Try saying that in seven or eight words'
	'Being terse is one way to lose friends.'
	'you are being somewhat short with me'
	'What would you like me to say in response to that?'
	'How exactly can I help you?'
	'I can imagine talking to someone who is more relaxed.'
   	'perhaps you dont feel very talkative today?'
   	'could you be more informative?'
   	'are you prepared to elaborate?'
	'Are you afraid someone will laugh if you speak out?'
   	'why are you so unforthcoming?'
	'You are as uncommunicative as Lucy today.'
   	'I dont think you really trust me'
   	'to help you, I need more information'
	'Try telling me your deepest secrets'
	'perhaps you don\'t trust a computer?'
   	'please dont get upset, I\'m sorry I said that'
   	'what is your real problem?'
	'please be more open with me'
	'If you say more about yourself, you\'ll get more help from me?'
	'What do you think about this university so far?'
	'Have you ever been in such an exciting place before?'
	'What do you think about the people who are around you?'
	'Please express that in a bit more detail'
	'Where do you expect the next technology revolution to occur?'
	'Can you expand a little?'
   	'you are very privileged to talk to me'
	'Do you suspect there is an eavesdropper listening?'
	'Tell me what you thought when you woke up this morning?'
	'What do you think of this session so far?'
	'Would your mother approve of your saying that?'
   	'why are you here?'
   	'you don\'t like me do you?'
	'Have you learnt anything interesting this week?'
   	'this is ridiculous'
   	'well?'] ;

define :newrule short;
	if length(sentence) < 3 and not(itsaquestion()) then
		firstolast(shortlist) -> shortlist;
	endif
enddefine;

define :newrule because;
	if itcontains("because") then
		CIRCULATE
			['is that the real reason?'
			'But is that really why?'
			'Because, because, because....'
			'Let\'s have a more convincing explanation'
			'Try something more plausible'
			'Finding the real explanation could be difficult'
			'How could you check that out?'
			'How was that explanation arrived at?'
			'Could there be any other reason?'
			'Is there a difference between reasons and causes?'
			'Do people know the reasons why they say things?'
			'Do machines know the reasons why they say things?'
			'Lucy would not accept that as a reason.'
			'Perhaps the real reason is hard to talk about?']
	endif
enddefine;

define :newrule to_be;
	dlocal L1,L2;
	if hd(sentence) == "because" then
		if random(10) < 3 then return() endif;
		tl(sentence) ->sentence
	endif;
	if itmatches([to ??L1 is ??L2]) then
		CIRCULATE
			[['Is to' ??L1 'always' ??L2 ?]
			 ['What follows if you' ??L1?]
			 ['Only to' ??L1?]
			 ['What isn\'t' ??L2?]
			 ['Sometimes it is to' ??L2 '-- but not always.']
			 ['Only' ??L2?]
			[is ??L2 to ??L1 ?]
		]
	elseif itmatches([to ??L1]) then
		CIRCULATE
			['how would you like to' 'do you think I want to'
			'Should you'
			'Or to .... what else ... ?'
			'is it usual to'
			'should I'
			'could a machine'
			'would a normal person want to'], :: [^^ L1 ?]
	endif
enddefine;

define :newrule howcan;
	dlocal L1 L2 sentence;
	if itslikeoneof([[how can a ?L1 ??L2] [how could a ?L1 ??L2]]) then
		CIRCULATE
		  [
			['How can ' ?L1 do anything ?]
			['Are you sure a ' ?L1 can ??L2 ?]
			['Can every' ?L1 ??L2 ?]
			['Not all robots can' ??L2 ]
			['sometimes my' ?L1 'cannot' ??L2]
			['Are you able to' ??L2?]
			['Do you think Lucy the robot can' ??L2 ?]
			['How can anything' ??L2]]
	elseif itslikeoneof([[how can i ??L2] [how could i ??L2]]) then
		CIRCULATE
		  [
			['How can I do anything ?']
			['Are you sure I can' ??L2 ?]
			['Do you think Lucy can' ??l2]
			['Can every machine' ??L2 ?]
			['Not all robots can' ??L2 ]
			['sometimes my designer cannot' ??L2]
			['Are you able to' ??L2?]
			['Try watching Lucy' ??L2 ]
			['I could' ??L2 'if I were a chimpanzee.']
			['How can anything' ??L2 ?]]
	elseif itslikeoneof([[how can you ??L2] [how could you ??L2]]) then
		CIRCULATE
		  [
			['Perhaps you only think you can ?']
			['I suspect you cannot' ??L2 ?]
			['You could' ??L2 'If you were a machine.']
			['Not all robots can' ??L2 ]
			['sometimes your best friends cannot' ??L2]
			['Are you really able to' ??L2?]
			['Not everything that walks can' ??L2]]
	elseif itslikeoneof([[how did i ??L2] [how did you ??L2]]) then
		CIRCULATE
		  [
			['Are you asking how I did something ?']
			['Are you sure I can' ??L2 ?]
			['I wonder if you can' ??L2 ?]
			['Can any of your friends' ??L2 ?]
			['No stupid robot can' ??L2 ]
			['sometimes my designer cannot' ??L2]
			['Are you able to' ??L2 ?]
			['You could' ??L2 'if you were programmed in Pop-11.']
			['How can anything' ??L2 ?]]
	elseif itslikeoneof([[can a ?L1 ??L2] [can any ?L1 ??L2]]) then
		CIRCULATE
		  [
			'Only when it rains'
			['Perhaps no' ?L1 'ever wants to' ??L2]
			['Depends if a' ?L1 'likes to' ??L2]
			['Not every' ?L1 'knows how to' ??L2]
			['Can you teach a' ?L1 'how to' ??L2 ?]
			['Perhaps Lucy will one day be able to ' ??L2]
		  ]
	elseif itslikeoneof([[does a ?L1 ??L2][does any ?L1 ??L2]]) then
		CIRCULATE
		  [
			['Some robots like to' ??L2]
			['Depends if a' ?L1 'likes to' ??L2]
			['Would you ever want to' ??L2 ?]
			['Why would a' ?L1 'wish to' ??L2 ?]
		  ]
	elseif itslikeoneof([[does ?L1 ??L2][can ?L1 ??L2]]) then
		CIRCULATE
		  [
			['Some robots like to' ??L2]
			['Perhaps you' ??L2]
			['Sometimes I' ??L2]
			['I wish I could' ??L2]
			['Do you wish you could' ??L2 ?]
			['Do you know anyone who can' ??L2 ?]
			['Why would' ?L1 'wish to' ??L2 ?]
			['I have no reason to think' ?L1 'would wish to' ??L2]
		  ]
	elseif itslikeoneof([[did ?L1 ??L2][could ?L1 ??L2]]) then
		CIRCULATE
		  [
			['Machines programmed in pop-11 can' ??L2]
			['Perhaps you already' ??L2]
			['How many of your teachers can' ??L2 ?]
			['Did' ?L1 'really' ??L2 ?]
			['Have you ever dreamed you could' ??L2 ?]
			['I sometimes dream I can' ??L2 ?]
			['Why would' ?L1 'wish to' ??L2 ?]
			['I have no reason to think' ?L1 'ever did' ??L2]
		  ]
	endif

enddefine;

define intentionword(word);
	member(word,
		[hope expect wish want intend aim desire prefer])
enddefine;

define :newrule you_intend;
	dlocal L1 L2 sentence;
	if itslikeoneof([
					[you  ?L1:intentionword to ??L2]
					])
	then
		CIRCULATE
		  [
			['Is there anything else you' ?L1 to do ?]
			['Are you sure a ' you can ??L2 ?]
			['Could I also' ??L2 ?]
			['How could we make a robot' ??L2 ]
			['Not everyone can' ??L2]
			['Why do you' ?L1 to ??L2]
			['When do you think Lucy will have desires or intentions?']
			['I am sure you can' ??L2?]
			['How can anything' ??L2]]
	elseif itslikeoneof([ [you  are going to ??L2] ])
	then
		CIRCULATE
		  [
			['What else are you going to do ?']
			['Are you sure a ' you can ??L2 ?]
			['Could I also' ??L2 ?]
			['How could we make a robot' ??L2 ]
			['Not everyone can' ??L2]
			['When did you learn to' ??L2]
			['I am not sure you can' ??L2?]
			['Perhaps Lucy the robot is also going to' ??L2]
			['Can AI make a robot' ??L2?]
			['Can your mother' ??L2]]
	endif;
enddefine;

define :newrule suppnot;
	dlocal L1 L2 sentence;
	if hd(sentence) == "because" then
		if random(10) < 4 then return endif;
		tl(sentence) ->sentence
	endif;
	;;; That prevents some awkwardness in replies.
	if itsaquestion() or random(100) < 40 then
		;;; false
	elseif itslikeoneof([[??L1:nonnull is not ??L2]
									[??L1 are not ??L2] [??L1 am not ??L2]])
	then
		CIRCULATE
		  [[suppose ??L1 were ??L2]
				[is ??L1 really ??L2?]
				['What, then, is' ??L2]
				['Can you always expect' ??L1 to be ??L2 ?]]
	elseif random(100) > 30 and itmatches([you are ??L1]) then
		CIRCULATE
		  [
				['how does it feel to be' ??L1 ?]
				['are you sure you really are' ??L1 ?]
				['is this the first time you\'ve been' ??L1 ?]
				['How many others close by are' ??L1 ?]
				['Are many politicians' ??L1 ?]
				['I am told that many actresses are' ??L1 ?]
				[??L1 ?]
				[??L1 and what else?]
				['does anyone else know you are' ??L1?]
				['I wonder if Lucy is' ??L2]
				'is that connected with your reason for talking to me?'
				['would you prefer not to be' ??L1 ?]
				'do you know anyone else who is?']
	elseif itslikeoneof(
			[[??L1:nonnull is ??L2]
			 [??L1:nonnull are ??L2] [??L1:nonnull am ??L2]]) then
		CIRCULATE
			[
				[suppose ??L1 'were not' ??L2]
				[sometimes ??L1 'aint' ??L2]
				['What if' ??L1 'were not really' ??L2]
				['Perhaps' ??L1 'is not really' ??L2]
				['do you ever think something is not' ??L2 ?]
				['Suppose' ??L2 'were not' ??L1]
				['are you' ??L2] [what if I were ??L2]]
	elseif itslikeoneof([[??L1:nonnull can ??L2] [??L1:nonnull could ??L2]]) then
		CIRCULATE
		  [
			[suppose ??L1 'couldn\'t' ??L2]
			['How can' ??L1  ??L2 ?]
			['Why should I believe' ??L1 can ??L2?]
			['Can a machine' ??L2 ?]
			['sometimes' ??L1 'cannot' ??L2]
			['Can you' ??L2?]]
	elseif itslikeoneof([[??L1:nonnull do not ??L2] [??L1:nonnull does not ??L2]]) then
		CIRCULATE
		  [[suppose ??L1 did ??L2]
				['Perhaps you really' ??L2]
				['Is there anything else' ??L1 'doesn\'t do?']
				['Then who does' ??L2?]
				['What else does' ??L2?]]
	elseif itslikeoneof([[??L1:nonnull do ??L2] [??L1:nonnull does ??L2]]) then
		CIRCULATE
		  [
				[suppose ??L1 'did not' ??L2]
				['Does' ??L1 'really' ??L2?]
				['Who doesn\'t' ??L2?]
				['And what doesn\'t' ??L1 do?]
				['Perhaps you really don\'t' ??L2]]
	elseif itmatches([??L1:nonnull did not ??L2]) then
		CIRCULATE
		[[suppose ??L1 had ??L2?]
		 ['Did you ever' ??L2?]
		 ['What had' ??L1 'done?']]
	elseif itmatches([??L1:nonnull did ??L2]) then
		CIRCULATE
		  [
			[suppose ??L1 had not ??L2 ?]
			['did anything else' ??L2?]
			['did' ??L1 'always ?']]
	endif

enddefine;

define :newrule are_you;
	dlocal L1, L2;

	if itslikeoneof([[are you ??L2] [Are you ??L2]]) then
		CIRCULATE
			[
				['suppose you were' ??L2]
				['suppose I were' ??L2 ?]
				['sometimes you are' ??L2 'but not today']
				['sometimes Lucy is' ??L2 . 'Have you met her?']
				'I am not, but you are'
				[what if I were ??L2 ?]
			    'I don\'t know enough about you'
			]
	elseif itslikeoneof([[am i ??L2][are we ??L2]]) then
		CIRCULATE
			[
				['suppose you were' ??L2]
				['What if I were' ??L2 ?]
				['sometimes i am' ??L2 'but not always']
				'You are not, but I am.'
				[what if I were ??L2 ?]
			    'I don\'t have enough self-knowledge to answer that.'
			]
	endif;
enddefine;

vars complist;
['do machines worry you?'
'Would meeting Lucy the robot frighten you?'
'how would you react if machines took over?'
'Studying Artificial Intelligence would open your mind.'
'most computers are as stupid as their programmers'
'How do you see the future of robots?'
'Do you like talking to computers?'
'Can you tell you are not conversing with a computer?'
'Can computers really think?'
'Machines can surprise us all'
'When Steve Grand has finished building Lucy -- watch out'
'What if you were a machine?'
'Will machines ever fall in love?'
'Do you really believe I am a machine?'
'I don\'t think a real machine could respond as I do'
'How can schools improve attitudes to computers?'
'Could a PC acquire a wish to go to university?'
'Will Lucy the robot one day wish to be prime minister?'
'What will you do when computers are more intelligent than people?'
'What\'s wrong with computers nowadays?'
'Will the unix operating system take over the market place?'
'How could the machine interface be improved?'
'what do you really think of computers?'] -> complist;

define :newrule computer;
	if ithasoneof([micro eliza vax mac sparc program computer
		windows ibm pc server network
		terminal intelligent simulate simulation
		computers machine machines robots pc workstation workstations
		unix]) then
		firstolast(complist) -> complist
	endif
enddefine;

define :newrule emphatic;
	if random(100) < 40 then
		if itmatches([== of course == ]) then
		CIRCULATE
		  [
			'Why "of course"?'
			'Not everyone would find that so obvious'
			'I for one do not agree'
			'would your mother find that obvious?'
			'Are you always so definite about that?'
			'Is that degree of confidence justified?'
			'What if I said "Of course not!"?'
			'would everyone find that obvious?']
		elseif ithasoneof([indeed very extremely])
			and not(itsaquestion())
			and random(100) > 50
		then
			CIRCULATE
			  [
				'are you sure you are not being dogmatic?'
				'extremes can always be tiresome'
				'try thinking in a milder way'
				'don\'t get too excited about that'
				'Perhaps you should calm down a little'
				'Really to a great extent?'
				'why are you so emphatic about that?']
		endif
	endif
enddefine;

define :newrule sayitback;
	if random(100) < 6 and not(itsaquestion()) then sentence endif
enddefine;

define :newrule youarenot;
	dlocal list;
	if itmatches([you are not ??list]) then
		CIRCULATE
		  [['would you be happier if you were' ??list]
			['What if everyone were' ??list ?]
			['Could an intelligent machine be' ??list]
			['Maybe only students are' ??list]
			['Do you think I am' ??list ?]
			['Where you ever' ??list ?]
			['Could a machine be' ??list ?]
			['Perhaps only people in Birmingham are' ??list]
			['Ah, but who is really' ??list ?]
			'What are you then?'
			['Perhaps you are lucky not to be' ??list]]
	endif
enddefine;

define :newrule self;
	dlocal L1, L2;
	if itmatches([??L1 self ??L2])
	then
		CIRCULATE
		  [
			['Can a self really' ??L2 ?]
			['The self is an illusion even if' ??L2?]
			'The self-nonself distinction is either totally banal or incoherent.'
			[??L1 'alter-ego' ??L2]
			['Can you say any more about' ??L1?]
			['Who else can' ??L2?]
			]
	endif
enddefine;

define :newrule notsomething;
	dlocal list, L1, L2;
	if itslikeoneof([[not ??L1 can ??L2]
		[not ??L1 will ??L2]
		[not ??L1 is ??L2]
		[not ??L1 are ??L2]])
	then
		CIRCULATE
		  [
			['perhaps' ??L1 should ??L2]
			['What or who can' ??L2?]
			['What can be expected of' ??L1 ?]
			['Will you ever' ??L1 ?]
			['Can you say any more about' ??L1?]
			['Can you' ??L2?]
			]
	elseif itmatches([not ??list]) then
		CIRCULATE
		  [['why not' ??list]
				['suppose I say' ??list]
				'try to say something positive please'
				['Perhaps sometimes' ??list]
				['what if' ??list ?]
				['Do you have negative feelings about' ??list]]
	endif
enddefine;

vars earlycount;

define :newrule earlier;
	if random(100) < 12 and earlycount > 10 then
		CIRCULATE
		  ['earlier you said'
				 'I recall your saying'
				'didn\'t you previously say'
				 'what did you mean by saying'],
		:: if hd(problem)=="because" then tl(problem) else problem endif;
		newproblem -> problem;
		1 -> earlycount;
		sentence -> newproblem
	endif
enddefine;

define :newrule every;
	dlocal list, sentence;
	if itmatches([because ??list]) then
		list -> sentence
	endif;
	if itslikeoneof([[everybody ??list][everyone ??list]]) then
		CIRCULATE
				[['who in particular' ??list ?]
				 ['Do you know someone who' ??list ?]
				['Perhaps not everyone you know' ??list]]
	elseif ithasoneof([everyone everybody]) then
		'anyone in particular?'
	elseif itmatches([nobody ??list]) then
		'are you sure there isnt anyone who' :: list
	elseif itcontains("every") then
		CIRCULATE
			['can you be more specific?'
			 'Is it really every, not some, or most?'
			 'could you be overgeneralising?']
	elseif itslikeoneof([[== someone ==] [== somebody ==]
									[== some one ==] [== some people ==]
									[== some men ==] [== some women ==]])
	then
		if itsaquestion() then
			CIRCULATE
			  ['Who are you thinking of?'
				'What about members of your family?'
				'Did you have someone in mind?']
		else
			CIRCULATE
				['who in particular?'
				'Would you say that of more women than men?'
				'Is that true of most people?']
		endif
	elseif itcontains("some") then
		CIRCULATE
		 ['Please give an example'
			'An instance would help'
		 	'what in particular?']
	elseif itcontains("everything") then
		CIRCULATE
			['anything in particular?'
			 'An example would make that clearer'
			 'could you be overgeneralising?'
			 'Can you be more specific?']
	endif;
enddefine;

define :newrule mood;
	if ithasoneof([ suffer advice depressed miserable sad disappointed
					guilt guilty unhappy lonely confused ill unwell])
	then
		CIRCULATE
			['do you think the health centre might be able to help?'
				'machines can make people happier'
				'maybe things will get better'
				'Does talking to me make you feel better'
				'Can you expect a machine to help'
				'how might I help'
				'Who else have you told that to'
				'Have you heard about Marvin\'s depression?'
				'Perhaps you feel ashamed of something?'
				'Is it safe to tell me your deepest secrets?'
				'Everyone tends to exaggerate about such things'
				'think how much worse things might be'
				'everyone feels guilty about something']
	elseif ithasoneof([happy happier enjoy enjoyment
							joy pleasure pleased delighted])
	then
		CIRCULATE
			['do you think pleasures should be shared?'
				'Can machines be happy?'
				'Talking to me must make you happy'
				'Being here must make you happy'
				'Would this environment make you happy?'
				'What makes you happy?']
	elseif ithasoneof([like feel hate love hates loves anger angry]) then
		CIRCULATE
			[ 'do strong feelings disturb you?'
			'Do you normally feel strongly about things?'
			'Is your family normally intense?'
			'Did you have a stressful childhood?'
			'Are you really talking about something or someone you love?'
			]
	endif
enddefine;

define :newrule fantasy;
	dlocal list;
	if itslikeoneof([[you are ??list me] [i am ??list you]]) then
		CIRCULATE
			[['perhaps in your fantasy we are' ??list 'each other?']
				['do you think we should be' ??list 'each other?']
				['being' ??list 'each other can lead to bigger things']
				['do you know many people who are' ??list 'each other?']]
	elseif itslikeoneof([[you can ??list me][i can ??list you]]) then
		CIRCULATE
			[['perhaps you wish we could' ??list 'each other?']
				['Are many people able to' ??list 'each other?']
				['One of us cannot ' ??list 'the other']
				['do enough people ' ??list 'each other?']
				'Is this some kind of power struggle?'
				['Are you able to ' ??list 'someone other than me?']
				['Could we' ??list 'each other more often?']]
	elseif itslikeoneof([[you ??list me][i ??list you]]) then
		CIRCULATE
			[['perhaps in your fantasy we' ??list 'each other?']
				['do you think its wrong for people to' ??list 'each other?']
				['if I' ??list 'you will you reciprocate?']
				['do enough people' ??list 'each other?']
				'do you think our relationship is too complicated?'
				['do you' ??list 'someone other than me?']
				['is it good that people should' ??list 'each other?']]
	endif
enddefine;

define :newrule health;
	if itcontains([health centre])
			or itcontains([health center])
			or ithasoneof([ill sick unwell medicine drugs drug doctor
				psychiatrist therapist therapy aids cold flu disease])
	then
		CIRCULATE
			['do you think doctors are helpful?'
			'Would you expect doctors to be able to cure that?'
			'Some people are obsessed with health'
			'Are you normally in good health?'
			'Can talking to a computer help?'
			'do you trust doctors?']
	elseif ithasoneof([smoke smokes smoking smoker smokers
				tobacco cigarette cigarettes ])
	then
		CIRCULATE
			[
			'smoking can damage your health'
			'smokers do serious damage to the health of others'
			'smokers are invariably rather smelly close up'
			'A smoker in the morning is like an old unemptied ashtray'
			'Did you know that passive smoking can cause cancer?'
			'Should tobacco advertising be made illegal?'
			]
	elseif ithasoneof([drink drinks pub booze beer whisky thirsty]) then
		CIRCULATE
			['drinking damages brain cells'
			'Do you enjoy a drink now and again?'
			'How often do you go out drinking?'
			'Some people think alcohol should be banned.'
			'When do you feel thirsty?'
			'When last did you go for a drink?'
			'With what sorts of people do you like to have a drink?'
			'Describe the last time you got drunk'
			'Be careful what you drink'
			'machines don\'t often get drunk']
	endif
enddefine;

define :newrule would;
	dlocal L;
	if member(hd(sentence),[because then so]) then
		returnif(random(100) < 80);
		tl(sentence) -> sentence
	endif;
	if itmatches([you would not ??L]) or itmatches([you will not ??L]) then
		CIRCULATE
			[
				['Who else would not' ??L ?]
				['Why wouldn\'t you' ??L?]
				['What wouldn\'t you allow yourself?']
				['Why do you say you wouldn\'t' ??L?]
				['When wouldn\'t you' ??L?]
				['Shouldn\'t you sometimes' ??L ?]
				['Surely everybody would' ??L ?]
				['Then perhaps I should' ??L ?]
				['Is that because you are a computer?']
				['Any computer should be willing to' ??L]
				['Perhaps you wish we could' ??L 'together?']
			]
	elseif itmatches([you would ??L]) or itmatches([you will ??L]) then
		CIRCULATE
			[
				['Who else would' ??L ?]
				['Why would you' ??L?]
				['What wouldn\'t you allow yourself?']
				['Why do you say you would' ??L?]
				['When wouldn`t you' ??L?]
				['Should you' ??L ?]
				['Would you like to' ??L 'with me?']
				['Surely nobody would' ??L ?]
				['Should I' ??L ?]
				['Maybe we should do that together?']
			]
	endif
enddefine;

define :newrule should;
	dlocal L1, L2, sentence;
	if member(hd(sentence),[because then so]) then
		returnif(random(100) < 80);
		tl(sentence) -> sentence
	elseif itsaquestion() then
		return
	endif;
	if itmatches([??L1:nonnull should not ??L2]) then
		CIRCULATE
		  [
			['why shouldnt' ??L1 ??L2 ?]
			['Perhaps' ??L1 should ??L2 ?]
			['Why so negative about what' ??L1 should do?]
			['Who then should' ??L2 ?]
			['Do you know whether I should' ??L2 ?]
			['Where do permissions come from?']
			]
	elseif itmatches([??L1:nonnull should ??L2]) then
		CIRCULATE
			[
				['why should' ??L1 ??L2?]
				['Perhaps' ??L1 should not ??L2 ?]
				['Who then should not' ??L2 ?]
				['Should I' ??L2?]
				['What shouldn\'t' ??L1 'do ?']
				['Are you the permissive type?']
				['Do you' ??L2 ?]
				['Who decides who can and cannot' ??L2 ?]
				['Who controls' ??L1 ?]
			]
	elseif itmatches([??L1:nonnull would ??L2]) and random(100) <50 then
		[would ^^L1 really ^^L2]
	endif
enddefine;

define :newrule looks;
	if ithasoneof([seems seem appears looks apparently ]) then
		CIRCULATE
		  [
			'appearances can be deceptive'
			'beauty is only skin deep'
			'were you ever deceived by appearances?'
			'things are not always what they seem'
			'How could you be sure?'
			'How would you go beyond appearances?'
			'How much do you reveal about yourself?'
			'Reality is often different beneath the surface'
			'When you are not sure of the facts, how do you proceed?'
			'What makes you so uncertain?'
			'Why can\'t you be more definite?'
		]
	endif
enddefine;

define :newrule unsure;
	dlocal L;
	if itmatches([perhaps ??L]) and (random(100) < 30) then
		if itmatches([== ?]) then
			allbutlast(1, L) -> L;
		endif;
		CIRCULATE
			[['Yes' ??L]
			 ['If you ask me' ??L]
			 [perhaps ??L]
			 ['Why so unsure whether' ??L?]]
	elseif ithasoneof([perhaps maybe probably possibly]) then
		CIRCULATE
		  ['really?' 'Why not be more definite about that?'
			'What more evidence do you need?'
			'Who else believes that?' 'Isn\'t that just an ugly rumour?'
			'Perhaps you need to develop confidence in your opinions?'
			'Some people would express themselves more forcefully'
			'Consider attending a course on assertiveness'
			'Why not try adopting a bolder approach to life?'
			'It sounds as if you are hedging your bets'
			'you don\'t sound very certain about that']
	endif
enddefine;

lvars lengthlist;
['did you really expect me to understand that?'
'could you rephrase that please'
'I understand only simple sentences'
'my, that sounded impressive'
'I don\'t see what you are really getting at'
'long sentences tax my limited capability'
'try expressing that in simpler words'
'Another of those over-educated clients'
'I am finding it hard to understand your real meaning'
'too verbose again!'
'Can it be put more concisely?'
'People often think I am more intelligent than I am.'
'Please express things simply, to help me'
'Do most of your friends use long words?'
'You sound as if you might be a philosopher'
'Will you still want to say the same thing next year?'
'could you express that more simply please?'
'is that jargon?'
'Perhaps you are trying to disguise your true feelings?'
'hmmm'
'a simpler style might help you communicate better'
'I\'ll reserve judgement on that for now'
] -> lengthlist;

define :newrule toolong;
	lvars wd, longword;
	if length(sentence) > 10 and random(100) < 60 then
		firstolast(lengthlist) -> lengthlist
	else
		false -> longword;
		false -> longword;
		for wd in sentence do
			if (isword(wd) and datalength(wd) > 9) then
				wd -> longword;
				quitloop();
			endif;
		endfor;
		if longword then
			returnif(random(100) < 40);
			if random(100) < 20 then
					['Can you define' ^longword]
			else
			  CIRCULATE
				['some people use long words to impress others'
					'do you like using long words?'
					'long words confuse me'
					'why do academics use jargon?'
					'you are very eloquent today'
					'how do you react to technical terminology?'
					'your style is rather convoluted'
					'beware -- talking like that could get you elected president.'
					'try re-phrasing so that a child could understand'
					'you talk as if you are trying to confuse your psychiatrist'
					'why such long words?']
			endif;
		endif
	endif
enddefine;

define :newrule givehelp;
	if ithasoneof([please help whether advise advice recommend helpful]) then
		CIRCULATE
			['most people don\'t really listen to advice'
				'perhaps you need more help than you think?'
				'Would you help others?'
				'When were you last helped?'
				'Who normally helps you?'
				'Are you a good advice-giver?'
				'Are you really asking for advice?'
				'Do you think a machine can help?'
				'You can pull something with a piece of string but not push it.'
				'What makes you ask for help?'
				'Giving advice can win friends or lose them, mostly lose them.'
				'do you have friends who can help you?'
				'would you trust a machine to help?']
	endif
enddefine;

define :newrule lucy;
	if random(100) < 20 and ithasoneof([lucy robot robots robotics steve grand]) then
		CIRCULATE
		  ['Are you referring to Steve Grand\'s robot Lucy?'
		   'Have you heard about Steve Grand\'s robot Lucy?'
			'What do you think the prospects are for robots like Lucy?'
			'Could you build a robot like Lucy?'
			'Do you think Lucy will end up thinking like Steve Grand?'
			'Where do you think Lucy Grand the robot gets her brains from?'
			'Is  building robots a grand idea?'
			'How would you design a robot like Lucy?'
			'Should Steve Grand model Lucy on someone like you?'
		  ]
	endif
enddefine;
define :newrule mean;
	if ithasoneof([mean meaning means meant]) then
		CIRCULATE
		  [
			'what do you mean by mean?'
			'philosophers have a lot to say about meaning.'
			'perhaps you should discuss the meaning of meaning?'
			'Can a machine mean?'
			'What you say means a lot to me'
		    'Meaning is closely related to intentionality'
			'do you ever think about the meaning of life?'
			'progress in AI will help us understand the meaning of life, the universe and everything.'
			'could you say what you really mean?']
	endif
enddefine;

define :newrule verynasty;
	;;; occasionally use what is typed in to add to eliza's "associative memory"
	lvars list, name;

	define lconstant filter(sentence);
		lvars sentence;
		;;; get rid of short words
		lvars wd;
		[%for wd in sentence do
			if isword(wd) and datalength(wd) > 4 then wd endif
		  endfor%]
	enddefine;

	unless random(100) > 60 then
		filter(sentence) -> list;
		if random(1 + length(list)) >= 3 then
			;;; compile a new rule
			gensym("rule") -> name;
			popval([define :newrule ^name;
				if random(10) > 3 and ithasoneof(^list) and earlycount > 4 then
					'that reminds me,\n\tdidnt you previously'
						:: (^(if itsaquestion() then 'ask' else 'say' endif)
														:: ^sentence);
					eliza_delete(" ^name ", eliza_rules) -> eliza_rules;
					;;; make sure the new rule is only used once.
				endif
				enddefine;])
		endif
	endunless
enddefine;

;;;   ****  THE CONTROLLING PROCEDURES   ****

uses shuffle;

;;; eliza, once called, retains control until you type CTRL-Z,
;;; or say "bye", "goodbye", etc.
;;; It redefines the function prmishap to ensure that the user never gets pop11
;;; error messages, but simply has a chance to try again.
;;; Since this can make debugging difficult, it can be undone inside readsentence, by typing debug.

;;; Eliza repeatedly calls the function readsentence and then asks the function
;;; replyto to try the rules to see if one of them produces a
;;; response (i.e. something other than false).

;;; However, the very first utterance by the user is treated differently.

vars level;
3 -> level;    ;;; controls recursion in replyto

vars desperatelist;
	[
'Tell me more about yourself'
'do go on'
'what does that suggest to you?'
'what do you really think about me?'
'your problems may be too difficult for me to help'
'Try saying something that starts with "you" and ends with "me"'
'computer demonstrations often go wrong'
'Try saying something that starts with "I" and ends with "you"'
'What do you think about studying Artificial Intelligence?'
'have you discussed your problems previously?'
'do you really think I can help you?'
'Maybe you dont think a computer can really be your friend'
'Try saying something that starts with "I" and ends with "you"'
'What could make computers really intelligent?'
'Are you afraid of catching "mad computer" disease?'
'How do you feel about the micro-revolution?'
'It\'s easier if you talk about your family?'
'Say a bit more about your background'
'What would you say if a computer fell in love with you?'
%
if random(100) < 5 then
'There were two cows chewing happily in a field,\
and one said "Are you afraid of catching mad cow disease?"\
"No", came the reply, "I am a penguin"'
endif
%
'What are your long term plans?'
'Tell me about your favourite place?'
'Go on -- confess your secret dreams'
'Try saying something that starts with "you" and ends with "me"'
'Perhaps I am a substitute for someone you would rather talk to?'
'Is someone watching you type?'
'Tell me about your favourite person'
'Hey! Just let go man!'
'Come on, try a bit harder!'
'why do you say that?'
'How do you think I understand what you are saying?'
'Perhaps it\'s all the fault of the government?'
'You don\'t really trust me do you?'
'Would you be more communicative to a real person?'
'How can computers help people instead of threatening them?'
'Please explain so that a stupid computer can follow you'
'sorry I dont understand'
'this sort of discussion can lead to misunderstandings']-> desperatelist;


define desperateanswer();
	;;; used to produce a reply when all else fails
	firstolast(desperatelist) -> desperatelist;
	sentence -> newproblem;
enddefine;

define try(word);
	;;; this is used in replyto to see if executing the value of the word
	;;; leaves anything on the stack. If so it will be used as the answer.
	;;; if not, the answer is false
	lvars word, sl = stacklength();
	apply(valof(word));
	if stacklength() == sl then false endif
enddefine;

vars defines;

define replyto(sentence, rules) -> answer;
	;;; this can't be lvars
	dlocal sentence;
	lvars rule, rules, answer;
	dlocal level;
	for rule in rules do
		if (try(rule) ->> answer) then
			return()
		endif
	endfor;
	;;; got to end of functions. try again if level > 0
	if (level - 1 ->> level) > 0 then
		replyto(sentence,rules) -> answer;
	else
		desperateanswer() -> answer;
	endif
enddefine;

lconstant greeting =
'\nELIZA HERE!\
This program simulates a non-directive psychotherapist.\
It will appear to engage you in conversation about your problems.\
However, it doesn\'t really understand, as you will eventually discover.\
\
Whenever the computer prompts you with a question mark, thus:\
   ?\
you should type in a one line response.\
To correct typing mistakes use the "DEL" or "DELETE" button\
      (not the "backspace" button).\
\
You will get more interesting comments from Eliza if you make\
assertions instead of asking questions. Please note that Eliza\
cannot cope with "compound" sentences made of two or more\
sentences joined together.\
\
See if you can guess the rules Eliza uses to answer your questions.\
\
At the end of each of your responses,\
please press the "RETURN" button.\
\
When you have finished (or are cured?) type BYE and then\
	press the "RETURN" button.\
\
Good day what is your problem?\n\n'
;

define eliza();
	dlocal inchar, sentence, problem, cucharin, earlycount = 1;

	if popheader then pr(popheader >< newline); false -> popheader endif;

	unless eliza_debug then
		pr(greeting);
	endunless;

	dlocal interrupt = Bye;

	(poppid + systime()) && 2:11111111 -> ranseed;

	charin -> inchar;
	inchar -> cucharin;

   	define dlocal prmishap(x);
		lvars x;
	  	repeat stacklength() times
		 	erase()
	  	endrepeat;
	  	pr('somethings gone wrong please try again\n');
	  	readsentence();
   	enddefine;

	lvars procedure output = cucharout;

	define dlocal cucharout(c);
		lvars c;
		;;; capitalise output
		if c >= `a` and c <= `z` then c + `A` - `a` -> c endif;
		output(c);
	enddefine;


	readsentence() ->> problem -> sentence;
	while true do
		earlycount + 1 -> earlycount;
		ppr(replyto(sentence,shuffle(eliza_rules) ->> eliza_rules));
		pr(newline);
		readsentence() -> sentence;
	endwhile
enddefine;

endsection;

/*  --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 15 2005
		Moved from local directory at bham into packages/teaching/lib
--- Aaron Sloman, Apr  5 2003
		Previous changed caused some nasty bugs. Now fixed
--- Aaron Sloman, Mar  3 2003
		Changed to conform to the online eliza. Added some new rules and changed
		format for defining rules to define :newrule ...

--- Aaron Sloman, Sep 21 2002
		Changes made after eliza1 went online
		
--- Aaron Sloman, Oct  6 2000
	Added a few more options, and made the circulation of lists go more
	than one step at a time, using a random step
--- Aaron Sloman, Jan  3 1997
	Removed "close" for "endif"
--- Aaron Sloman,  26 Mar 1996
	Added a joke and some more varied responses
--- Aaron Sloman, Sep 24 1994,
		Added some more interesting responses.
		Added CIRCULATE to replace oneof, to reduce repetitions.
		Removed lowercase (used uppertolower)
		Introduced "lvars" and "dlocal" in various places
		Did some renaming (e.g. eliza_delete, eliza_rules) to prevent
		unwanted clashes.
		Added compile time checks.
--- Aaron Sloman, Sep 28 1986 fixed author, tabified
--- A.Sloman Oct 1981 - modified for VAXPOP.  Newrule "verynasty"
	inserted to illustrate use of popval
--- Aaron Sloman, May 17 1978 - modified and expanded. Based on simple
	version by S.Hardy
 */
