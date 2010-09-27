/*  --- Copyright University of Sussex 1995.  All rights reserved. ---------
 >  File:           C.all/lib/lib/gramdemo.p
 >  Purpose:        demonstration of parsing sentences (to do with a kitchen)
 >  Author:         A.Sloman 1983 (see revisions)
 >  Documentation:  $usepop/pop/lib/demo/kitchen.lis
 >  Related Files:  $usepop/pop/lib/demo/mkgram and saved image
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;


if popheader then pr(popheader); pr(newline); '' -> popheader endif;
uses showtree;

pr('please wait\n');
uses grammar;

define getline(pop_readline_prompt) -> result;
	;;; Like readline, but ignore apostrophes. Convert to lower case.
	vars popnewline inchar initem x proglist;
	true -> popnewline;
	define inchar() -> char;
		vars char;
		charin() -> char;
		while char == `'` or char == ``` do
			charin() -> char;
		endwhile;
		if isuppercode(char) then char + 32 -> char endif;
	enddefine;
	pdtolist(incharitem(inchar) )-> proglist;
	readline() -> result;
	if result /== [] and last(result) == "." then
		allbutlast(1, result) -> result
	endif;
enddefine;


define setmeaning(item,word);
	vars x;
	Wdprops(word) -> x;
	if x == undef or x == [] then item
	elseif isword(x) then [^item ^x]
	else [^item ^^x]
	endif
	-> Wdprops(word)
enddefine;


define testmember(word,list) -> cat;
	;;; if word is an initial segment of an element of the list,
	;;; return the element, otherwise false
	false-> cat;
	applist(list,
		procedure(x);
			if issubstring(word,1,x) == 1 then
				x; exitfrom(testmember)
			endif
		endprocedure)
enddefine;

define checktype(word, Lexicon);
	vars cat list x;
	if Wdprops(word) == [] then
		printf(word,
		 '\n\nWHAT TYPE OF WORD IS: %p ?\nPlease answer one of:\n\n');
		 [%for cat in Lexicon do
				hd(cat) -> x;
				unless issubstring('that',1,x)
				or (issubstring('verb',1,x) and strmember(`_`,x)) then
					 x
				endunless
			 endfor%] -> list;
		list ==>
		until
			(pr('\n\n(You can abbreviate to 3 letters). Press the RETURN button if you don\'t know.');
			getline('\n\r\n\rOtherwise type your answer and press return: ') -> x;

			if x == [] then
				pr('I assume you don\'t know. Will see what I can do.\n');
				return
			else
				hd(x) -> cat;
				testmember(cat,list) ->> cat
			endif)
		do
			pr('Please cat one of:\n\t ');
			list ==>
		enduntil;
		setmeaning(cat,word)
	endif;
enddefine;

define ends_ing(x);
	if length(x) < 3 then false
	else
		issubstring('ing', length(x)-2, x) == length(x) - 2
	endif
enddefine;

define checksentence(list,Lexicon);
	vars x y temp;
	list -> temp;
	while temp matches [== ?x:be_word ?y:ends_ing ??temp] do
		setmeaning("adjective",y);
		printf(y, '\Treating %p as an adjective\n');
	endwhile;
	applist (list,checktype(%Lexicon%));
	true        ;;; may be generalised
enddefine;


vars gram_a lex_a;;

[
;;; sentence formats
[SENTENCE
	[NOUN_PHRASE VERB_PHRASE]
	[NOUN_PHRASE verb NOUN_PHRASE that_word SENTENCE]
	[NOUN_PHRASE verb that_word SENTENCE]
	[SENTENCE  conjunction SENTENCE]
	]
;;; noun phrases
[NOUN_PHRASE
	[name]
	[pronoun]
	[SIMPLE_NOUN_PHRASE]
	[NOUN_PHRASE PREPOSITION_PHRASE]
	[NOUN_PHRASE conjunction NOUN_PHRASE]
	]
;;; simple noun phrase
[SIMPLE_NOUN_PHRASE
	[determiner noun]
	[determiner QUALIF_NOUN]
	[QUALIF_NOUN]
	]
;;; qualified noun
[QUALIF_NOUN
	[noun]
	[noun noun]
	[adjective QUALIF_NOUN]
	[possessive QUALIF_NOUN]
	]
;;; prepositional phrases
[PREPOSITION_PHRASE
	[preposition NOUN_PHRASE]
	]
;;; verb phrases
[VERB_PHRASE
	[had VERB_PHRASE]
	[be_word adjective]
	[be_word adjective NOUN_PHRASE]
	[be_word preposition NOUN_PHRASE]
	[verb_prep_np preposition NOUN_PHRASE]
	[verb_np_prep_np NOUN_PHRASE preposition NOUN_PHRASE]
	[verb_np_prep NOUN_PHRASE preposition]
	[verb_np NOUN_PHRASE]
	[verb_np_np NOUN_PHRASE NOUN_PHRASE]
	[intransitiveverb]
	[verb NOUN PHRASE]
	[verb OBJ_PHRASE]
	[verb to verb_inf]
	[verb NOUN_PHRASE to verb_inf ]
	[verb NOUN_PHRASE to verb]
	[verb NOUN_PHRASE to verb_inf OBJ_PHRASE]
	[verb NOUN_PHRASE to verb OBJ_PHRASE]
	[verb to verb_inf OBJ_PHRASE]
	]
[OBJ_PHRASE
	[adjective]
	[adjective NOUN_PHRASE]         ;;;adjectives include participles
	[preposition NOUN_PHRASE]
	[NOUN_PHRASE preposition]
	[NOUN_PHRASE preposition NOUN_PHRASE]
	[NOUN_PHRASE]
	[NOUN_PHRASE NOUN_PHRASE]
	[preposition]
	]
] -> gram_a;

[
	[name Joe Mary joe mary ]
	[pronoun she he you it i I they them we her me him]
	[determiner the a an each every some ]
	[noun kitchen cup saucer spoon fork knife bowl sink milk sugar gas flour
		egg eggs herbs tea coffee salt cheese cake biscuit cookies powder
		pepper butter soup food squash orange juice lemon
		water potatoes apples peas carrots rice mess floor fire light chip
		chips chef waiter shelf cupboard taps cooker fridge hob tap
		pot pan mine yours hers his its joes marys]
	[adjective smelly old green sweet sour bitter white red new sticky
		wet raw rancid fresh hot cold warm mine hers his yours]
	[possessive joes marys his her its their my your]
	[be_word were was got became wasnt is isnt]
	[that_word that how where when]
	[preposition on in out under over at by with from to of onto into]
	[conjunction and while when]
	[verb_prep_np looked poked climbed stood fell wept switched turned
		weighed]
	[verb_np_prep turned switched picked]
	[verb_np_prep_np threw stuck gave joined took stirred mixed poured
		shook sprinkled fetched lifted removed stole put smeared baked
		cooked]
	[verb_np_np baked made cooked cut buttered poured]
	[verb_np stirred baked cooked mixed liked hated poured caught lit shut
		opened roasted boiled dropped drank ate drank cut washed cleaned
		weighed made had]
	[intransitiveverb cooked poured stirred ate wept]
	[verb weighed struck boiled washed poured turned stood had told asked
		switched threw]    ;;; for multiple uses of these verbs
	[verb_inf be bake pour stir make cut open cook drink eat shut give
		pick light mix shake fetch turn put drop strike turn cook
		wash dry clean weigh]
	[adverb slowly carefully ]
] -> lex_a;


setup(gram_a,lex_a);

define lconstant type(file);
lvars file inchar ;
	discin(sysfileok(file, false)) -> file;
	until (file() ->> inchar) == termin do
		if inchar == `\n` then
			rawcharout(`\r`)
		endif;
		rawcharout(inchar);
	enduntil;
	rawoutflush();
enddefine;

define test();
	vars x proglist finished first Last vedautowrite;
	pdtolist(incharitem(charin)) -> proglist;
	false ->> vedautowrite ->> finished -> x;
	until finished do
		unless x then
			type('$usepop/pop/lib/demo/kitchen.lis');
			getline('Guess what went on in the kitchen?\r\n? ') -> x;
		endunless;
		;;; remove full stops
		if hd(x) = "setpop" then
			;;; for debugging
			setpop -> interrupt; sysprmishap -> prmishap; true -> popsyscall;
			setpop()
		elseif x = [bye] or x == termin then
			true -> finished
		else
			while x matches [??first . ??Last] do
				[^^first ^^Last] -> x
			endwhile;
			if checksentence(x,lex_a) and
				(SENTENCE(x) ->> x)
			then
				pr('Analysed it. Now for a diagram\n');
				showtree_mess(x);
			else
				'Not analysable according to this grammar' =>
			endif;
			getline('Want to try another? (y/n) (end with RETURN)\r\n')-> x;
			if length(x) == 1 then
				hd(x) -> x;
				if member (x, [bye no nope n]) then true -> finished
				else false -> x;
				endif;
			endif;
		endif;
	enduntil;
enddefine;

if systrmdev(popdevin) then test() endif;


/* --- Revision History ---------------------------------------------------
--- John Gibson, Jul 31 1995
		Added +oldvar at top
--- John Gibson, Aug 24 1993
		Uses showtree instead of new_sh*owtree
 */
