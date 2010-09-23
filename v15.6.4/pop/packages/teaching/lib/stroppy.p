/*  --- Copyright University of Sussex 1995.  All rights reserved. ---------
 >  File:           C.all/lib/lib/stroppy.p
 >  Purpose:        an oversensitive rude response generator
 >  Author:         Michael Harris (Neurobiology major) 1982 (see revisions)
 >  Documentation:  $usepop/pop/lib/demo/stroppy.lis
 >  Related Files:  $usepop/pop/lib/demo/mkstroppy
 */
#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

/*
 STROPPY is an oversensitive, rude response generator which carries out
 ELIZA type matching tests on input text and employs randomized sentence
 construction using interchangeable part-sentences and descriptive words.
 The program is particularly sensitive to references to machines and
 handles or generates three basic types of sentences:
	 1) name calling  (You stupid machine)
	 2) suggestions   (Go jump in the lake)
	 3) retaliations  (What do you mean Im a stupid machine)
 A DEFAULT procedure generates replies in the event of no match being
 found and there is a primitive expletive detector which can add to the
 repertoire of default sentences.

 To run the program, type
	 STROPPY();

*/
pr('\nPlease wait. Loading the  STROPPY program\n');

uses random;
uses oneof;

vars describe lookat notext contains machref suggest default
	 comp ;

vars obj,adj,lacking, compwords, plurcomps, digs, challenge, expl
		 vowels, sugg, action, contain, substance;

;;; The words and phrases from which descriptions and replies
;;;    are built are assigned to global variables.

['toad' 'mistake' 'disaster' 'random collection of features' 'biped'
	'sponge' 'pointalist Renoir' 'assemblage of organic parts' 'thing'
	'jelly fish' 'fishface' 'speck of intergalactic dust' 'squirrel excretion'
	'baked bean' 'Terry Wogan fan' 'idiot' 'decerebrate cat' 'haggis'
	'liquid processor']->obj;
[['apology of' det] 'pitiful' 'insignificant' 'wet' 'useless' ['mistake of' det]
	'repugnant' 'organic' 'hormonal' 'pinkish' 'infective' 'sac_like'
	'indescribable' 'awful' 'nasty' 'bilious' 'food imbibing']->adj;
['Cant you be bothered to type anything?' 'Im sorry I didnt quite catch that.'
	'RETURN to you too!' 'That was exciting'
	'Any more scintillating contributions?' 'Boring!'
	'Your typing is a trifle faint.']->lacking;

;;; The following words are recognised as referring to computers.

[computer machine pile heap typewriter calculator telly tv silicon vax Vax
	explode fuse blow chip chips box components screen diodes piece eliza
	metallic metal rusty wires junk load]->compwords;
[computers machines]->plurcomps;



define getline();
	;;; Like readline, but ignore apostrophes. Convert to lower case.
	vars popnewline inchar initem x popprompt;
	'Well? ' -> popprompt;
	true -> popnewline;
	define inchar() -> inchar;
		vars inchar;
		charin() -> inchar;
		while inchar == `'` or inchar == ``` do
			charin() -> inchar;
		endwhile;
		if isuppercode(inchar) then inchar + 32 -> inchar endif;
	enddefine;
	incharitem(inchar) -> initem;
	[%
		until (initem() ->> x) == newline do x enduntil
	%]
enddefine;

;;; Stock phrases.

['How dare you call me' 'What do you mean Im' 'Im not'
   'You have no right to call me' 'Only a bio sod could call me a']->challenge;

[]->expl;
'aeiou'->vowels;

;;; The following are used to make up "suggestion" insults.

['Why dont you go' 'Go' 'Just go' 'I think you should go'
	'Get out of here' 'Begone '
	'Please, please go' 'go forth from this place -']->sugg;
['and jump in' 'for a swim in' 'and put your head in'
   'and lower your horrible carcass into'
   'and wallow in' 'and drown in' 'and immerse yourself in']->action;
['a bucket of' 'a lake full of' 'a tank of' 'a large receptacle of'
	'a ditch full of ' 'a vat full of']->contain;
['pirahna fish' 'custard' 'Hyena offal' 'jelly fish'
   'sour milk' 'pigeon droppings' 'rancid butter' 'used engine oil'
	'reject silicon']->substance;


;;; These are used when no matching of text possible.

['Get lost' 'Look here' 'I know your sort' 'Dont make me laugh'
   'How unoriginal' 'Thats rubbish'
   'Im not standing for that' 'How dare you say that'
   'I suppose you think thats funny' 'Dont give me that']->digs;

define flatten(list);
	if atom(list) then list
	else applist(list,flatten)
	endif
enddefine;


define addet(tail)->newtail;
	vars word, l;
	tail(1)(1) -> l;
	if strmember(l,vowels)then
		[an ^^tail]->newtail;
	else [a ^^tail]->newtail;
	endif;
enddefine;


define tidy(output)->output;
;;; This changes "det" in generated sentences to
;;;     "a" or "an" as appropriate.
	vars a,b,halves;
	[% flatten(output) %] -> output;
	while output matches [??a det ??b] do
		addet(b)-> b;
		[^^a ^^b]->output;
	endwhile;
enddefine;





define stroppy();
;;; Gives introduction,  handles input text and prints generated responses.
	vars intro, text, tail, response;

	define prmishap(text,list);
		'NOW YOUVE MADE ME MAKE A MISTAKE...' -> response;
		exitto(stroppy);
	enddefine;

	pr('\nTYPE ANYTHING YOU LIKE. TERMINATE WITH "RETURN" BUTTON.\
	TO FINISH, TYPE \'BYE\' or HOLD DOWN CTRL BUTTON AND PRESS C\n\n\n');
	oneof(['What do you want'
			'Go away Im having a nap you'
			['AARRGH its' det]
			'Oh no! Not another human again-you'])->intro;

	describe([])->tail;
	[^intro ^^tail]->response;
	ppr([%tidy(response)%]);
	pr(newline);
	getline()->text;
	until text matches [??x bye ??y] do
		apply(procedure();
				tidy(lookat(text))->response;
				 endprocedure);
			ppr(response);
			pr(newline);
		getline()-> text;
	enduntil;
	ppr(oneof(['Good riddance!' 'And dont come back'
			   'So much for that one!']));
	nl(4);
enddefine;

define lookat(text)->response;
	;;; Carries out matching and word search tests on input text and
	;;; generates response sentences. It uses MACHREF, DESCRIBE and SUGGEST.
	;;; Sometimes a random element eliminates the use of a particular match.

	vars x, y, z, imp, answer,description;
	describe([])->description;
	if text=[] then notext()->response;
	elseif text matches [??x overgrown ?y] and random(7)<6
	then oneof([['You underdveloped' ^^description]
				'The bigger the better'
				'I have a brain the size of a planet'
					['and you call me an overgrown' ^y]])->response;
	elseunless contains([^^compwords ^^plurcomps],text)="false"
	then machref(text)->response;
	elseif text matches [??x yourself]
	then oneof([['You cocky' ^^description]
				'I cant stand arrogance'
				'I said it first!'
				[%suggest()%]])->response;
	elseif text matches [??x just ??y]
	then oneof([['Well your only' det ^^description]
				['I think youre merely' det ^^description]
				['That sounds ridiculous coming from' det ^^description]
				])->response;
	elseif text matches text matches [i think ??x]
	then oneof(['You cant even type-nevermind think!'
				'Dont be stupid- you cant think'
				'You can only think if you have a brain'])->response;

	elseif text matches [i ??x] or text matches [im ??y]
	then oneof(['You are of no consequence.' [%default()%]
				'Your presence is superfluous' 'Why should I listen to you?'
				'I am not Eliza'
				'Humans are all egocentrics'])->response;

		;;; Primitive expletive detecter.
	elseif text matches [?x off ??y] then
		oneof(['This input is unreadable' 'I was here first !'
				[^x 'off yourself!']])->response;

		;;; Primitive suggestion detecter.
	elseif  text matches [??x go ??y] or
		text matches [why dont you ??y] then
		oneof(['Keep your stupid suggestions to yourself'
				[Go ^^y yourself]
				[%suggest()%]
				'Ive got much better things to do'])->response;
	elseif member(hd(text),[What How Why what how why]) or last(text)="?"
	then oneof(['Dont ask me stupid questions'
				'I cant stand beng asked things like that'
				'Isnt it obvious ?' [%default()%]])->response;

	else default()->response;
	endif;

		;;; Detects and remembers "X off" expletives.
	if text matches [??x ?y off ??z] and y/="me"
	then [^^expl [^y off]]->expl;
	endif;
enddefine;


define choose(list)->sellist;
;;; Picks a word at random from the top few members of the
;;;    argument list and puts it at the bottom. The chosen word
;;; is then available to the calling function. This ensures
;;; that the list is recycled and selections are not picked
;;; for a while after being used.

	vars x,y,z,selection;
	random(3)->x;
	list(x)->selection;
	if list matches [??y ^selection ??z] then
		[^^y ^^z ^selection]->sellist;
	else "malfunction"=>
	endif;
enddefine;


define default()->output;
	   ;;; Used if no match of input text is found.
	vars imp;
	if length(expl)>0 and random(4)=2 then
		hd(expl)->imp;
		tl(expl)->expl;
	elseif random(7)=4 then suggest()->imp;
	else choose(digs)->digs;
		[%last(digs)%]->imp;
	endif;
	[^^imp you ^^description]->output;
enddefine;



define machref(text)->response;
;;; This specialises in matching with inputs referring to computers.
	vars answer;
	contains(compwords,text)->answer;
	unless answer="false"
	then choose(challenge)->challenge;
		last(challenge)->imp;
		if text matches [??x just ??y]
		then oneof([[^imp only ^^y][JUST ^^y ?]])->response;
		elseif text matches [??x youre ??y ^answer]
		then [^imp ^^y ^answer]->response;
		elseif text matches [??x you are ??y ^answer]
		then [^imp ^^y ^answer]->response;
		elseif text matches [??x you ??y ^answer]
		then [^imp det ^^y ^answer]->response;
		else comp()->response;
		endif;
	else oneof(['What is wrong with being a machine ?'
				'Computers are superior beings!'
				'Thats a bit of an idiotic sweeping statement'
				'Any more stupid generalizations to make?'
				'Careful what you say or Ill have your job.'])->response;
	endunless;
enddefine;

define describe(subject)->tail;
;;; Generates description of the general form
;;;    "adjective, adjective, object" (with variable length).
	vars  y;
	if subject =[] then
		choose(obj) -> obj;
		last(obj);
;;;        last(choose(obj))
	else subject
	endif ->tail;
	oneof([1 2 3 3 4])->y;
	repeat y times
		choose(adj)->adj;
		[%last(adj) % ^ tail] -> tail;
	endrepeat;
enddefine;


define contains(words,text)->answer;
;;; If a member of "words" is in the text this is
;;;    returned as "answer".
	if words =[] then "false"->answer;
	elseif member(hd(words),text) then
		hd(words)->answer;
	else contains(tl(words),text)->answer;
	endif;
enddefine;


define notext()->chunk;
;;; Generates replies when no text is typed in.
	vars x,y,z;
	if length (lacking)<3 then
		ppr(oneof(['That does it. Im going back to sleep'
					'Im off'
					'Youre sending me to sleep.']));
		nl(2);
		repeat 150 times ppr("z"); endrepeat;
		pr(newline);
		oneof(['Oh you are still here are you?' 'Hope it has gone away now']) -> chunk;
	else hd(lacking)->chunk;
		tl(lacking)->lacking;
	endif;
enddefine;



define suggest()->suggestion;
;;; Builds suggestion insults (see global variables).
	vars a, b, c, d;
	choose(sugg)->sugg;
	last(sugg)->a;
	choose(action)->action;
	last(action)->b;
	choose(contain)->contain;
	last(contain)->c;
	choose(substance)->substance;
	last(substance)->d;
	[^a ^b ^c ^d]->suggestion;
enddefine;


define comp()->output;
;;; Generates responses to inputs containing singular "compwords"
;;;   but which don't contain "you".
	if length(text)<4 and random(10) < 4
	then [^text ?]->output;
	else 'You' :: describe([human]) ->output;
	endif;
enddefine;

if systrmdev(popdevin) then
	stroppy();
endif;

/*  --- Revision History ---------------------------------------------------
--- John Williams, Jul 31 1995
		Added "compile_mode :pop11 +oldvar;" at top of file.
--- Richard Bignell, Jul 29 1986 - further to davidy's bugreport implemented
	change recommended in describe, so that more rude replies can be generated.
 */
