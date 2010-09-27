/*  --- Copyright University of Sussex 1996.  All rights reserved. ---------
 >  File:           C.all/lib/obsolete/hangman.p
 >  Purpose:        Hangman spelling game. Works only on Visual 200 terminal.
 >  Author:         Aaron Sloman, 1980 (see revisions)
 >  Documentation:
 >  Related Files:  LIB *V200GRAPH  LIB *ACTIVE $usepop/pop/lib/demo/mkhang
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

pr('Please wait. Loading Programs\n');
uses popturtlelib

vars Vpoint;
unless isprocedure(Vpoint) then
	apply(procedure;
	vars cucharout; erase -> cucharout;;    ;;; supppress warning message
	popval([lib active;])
	endprocedure);
endunless;

false -> picture;                ;;; save space during compilation

pr(' Half way there\n');
pr(' To interrupt, hold down CTRL key, and press \'Y\' once\n');

vars Xman,Yman,Xword,Yword,Xletters,Yletters,words,Xscore,Yscore,me,you;
18 -> Xword; 5 -> Yword;
18 -> Xletters; 10 -> Yletters;
18 -> Xscore; 14 -> Yscore;

poppid + systime(); -> ranseed;

define insert(inn,letters);
		if letters == [] then [^inn]
		elseif inn(1) < hd(letters)(1)
		then    inn :: letters
		else    hd(letters)::insert(inn,tl(letters))
		endif
enddefine;

define plantstring(x,y,string);
		charout(0); ;;; flush charout
		jumpto(x,y); 0 -> heading;
		length(string) ->x;
		1 -> y;
		while y <= x do
				consword(string(y),1) -> picture(xposition,yposition);
				jump(1);
				y + 1 -> y
		endwhile
enddefine;

define Base();
		"=" -> paint;
		jumpto(1,1); 0 -> heading;
		draw(11);
enddefine;

define Upright();
		jumpto(5,1);drawto(5,15);
enddefine;

define Arm();
		jumpto(5,15); 0 -> heading; draw(5); turn(-90);
		"|" -> paint;
		draw(2);
		xposition -> Xman; yposition -> Yman;
enddefine;

define Head();
		"*" -> paint;
		jumpto(Xman,Yman);
		-45 -> heading;
		repeat 4 times tdraw(2);turn(-90) endrepeat;
		-90 -> heading; jump(3); xposition -> Xman; yposition -> Yman;
enddefine;

define startdown(ang);
		jumpto(Xman,Yman);
		ang -> heading;
enddefine;

define Neck();
		startdown(-90);
		draw(1);
		xposition -> Xman; yposition ->Yman;
enddefine;

define limb(ang);
		startdown(ang); draw(6)
enddefine;

define Llimb();
		limb(-135);
enddefine;

define Rlimb();
		limb(-45);
enddefine;

define Trunk();
		startdown(-90);
		draw(3);
		xposition -> Xman; yposition -> Yman;
enddefine;

vars hangman;
[%Base,Upright,Arm,Head,Neck,Llimb,Rlimb,Trunk,Llimb,Rlimb%] -> hangman;

define prepare(word);
	vars paint;
	plantstring(Xletters,Yletters+1,'Guesses:');
	plantstring(Xword,Yword+1,'The word:');
	jumpto(Xword,Yword);
	0 -> heading;
	"_" -> paint;
	draw(length(word) - 1);
	Scroll();
	rawoutflush();
	pr('The word has ' >< length(word) >< ' letters.\
	When you guess a correct letter, its position will be shown\
	Otherwise the picture of a man on gallows will be extended.\
	Try to guess all the letters before the man is finished.\
	To redraw display press the ESC key (left of keyboard)\n');
enddefine;


define isletter(x);
	 islowercode(x)
enddefine;


define getchar(mess)->char;
	vars x;
	0 -> char;
	0 -> x;
	until isletter(char) do
		x + 1 -> x;
		Scroll();
		rawoutflush();
		pr(mess>< '? '); pr(space); charout(0);  ;;; flush output buffer
		rawcharin()-> char;
		;;; give up if more than 30 non-letters are typed.
		if x > 30 or char = termin then interrupt() endif;
		if char == `\^V` ;;; ctrl V
		or char == `\^[`  ;;; ESC
		then    rawcharout(`^`);rawcharout(`V`); display()
		endif;
		if isuppercode(char)
		then uppertolower(char) -> char
		endif;
		rawcharout(char)
	enduntil;
enddefine;

define answeryes(mess);
	 Scroll();
	 getchar(mess >< '(y/n)') /== `n`
enddefine;



define checkout(letters,inn) -> x;
	0 -> x;
	jumpto(Xword,Yword);
	until letters == [] do
		if inn == hd(letters)
		then inn -> picture(xposition,yposition); 1 + x-> x
		endif;
		jump(1); tl(letters) -> letters
	enduntil
enddefine;

define getguesses(letters)->won;
	vars tried hangman inn x count;
	[] -> tried; false -> won; 0 -> count;
	until hangman == [] or won
	do
		getchar('Type a letter') -> inn;
		consword(inn,1) -> inn;
		if   match([== ^inn ==],tried)
		then    pr('\nyou\'ve tried that before. Try another\n')
		else
			insert(inn,tried) -> tried;
			jumpto(Xletters,Yletters); 0 -> heading;
			applist(tried, procedure x;
					x-> picture(xposition,yposition);
					jump(1); endprocedure);
			checkout(letters,inn) -> x;
			if x > 0 then
				x + count -> count;
				count == length(letters) -> won
			else apply(dest(hangman) -> hangman);
			endif;
		endif
	enduntil
enddefine;

define play();
	vars words playagain me you word won wonstring cucharout;
	Vout -> cucharout;
	shuffle(words) -> words;
	define prmishap;
		vars cucharout;
		charout -> cucharout;
		Scroll();
		rawoutflush();
		sysprmishap();
		pr('\n\nTYPE CTRL-C to CONTINUE'); charin();
	enddefine;

	;;; prevent charout messing up format.
	false -> poplinewidth;
	false -> poplinemax;

	define interrupt;
		pr('\nBye\n');
		exitfrom(play);
	enddefine;

	0 ->>me->you;
	true-> playagain;
	'Me: 0  You: 0' -> wonstring;
	pr('Please answer questions by typing only "y" or "n"\n');
	if answeryes('Would you like to have only short words')
	then    maplist(words,procedure x; if length(x) < 5 then x endif endprocedure)
			->words
	endif;
	until words == [] or
		(not(playagain) and not(answeryes('Play some more')))
	do
		newpicture(Xletters+25,15);
		jumpto(Xletters-1,1);
		"#" -> paint;
		repeat 2 times
			draw(25);turn(90);
			draw(14); turn(90);
		endrepeat;

		plantstring(Xscore,Yscore,wonstring);
		false -> playagain;
		hd(words) -> word;
		prepare(word);
		getguesses(unpackitem(word)) -> won;
		pr('\n' ><
			if won then 1+you -> you; 'Well done'
			else 1+me -> me; 'Bad luck' endif);

		'Me: ' >< me >< '   You: ' >< you -> wonstring;
		plantstring(Xscore,Yscore,wonstring);
		if not(won)
				and answeryes('Try that word again')
		then    true -> playagain;
		elseif won or answeryes('Want to see the word')
		then    pr('\nIt was "' >< word >< '"\n');
			tl(words) -> words;
		else    tl(words) -> words
		endif;
	enduntil;
	pr(wonstring >< '\n\nBye\n');
enddefine;



[
'accidental' 'absent' 'although' 'alligator' 'angry' 'antelope'
'apple' 'applicability' 'at'
'baby' 'bad' 'banana' 'bard' 'because' 'bed' 'bird' 'blue' 'bridge' 'busy' 'by'
'cat' 'catch' 'chair' 'chattering' 'chip' 'come' 'cope' 'computer'
'confident' 'cordial' 'crash'
'cup' 'cyst'
'dancing' 'deer' 'dairy' 'dawn' 'day' 'dazzle' 'define' 'diarrhoeia'
'dig' 'do' 'doctor' 'dog' 'door' 'down' 'drizzle'
'ecstatic' 'edge' 'electricity' 'elephant' 'elk' 'embarrassed' 'embezzler'
'enthusiastic' 'estimated' 'every' 'example' 'excellent'
'expectation' 'expiditious'
'fed' 'feel' 'fidget' 'fill' 'finger' 'fish' 'flamboyant'
'flute' 'flay' 'fly' 'fool' 'fragment' 'fray' 'fruit' 'fuel'
'fungus' 'funny' 'furnishings'
'gay' 'gladly' 'go' 'gone' 'good' 'grandiose' 'grumpy' 'gun' 'guru'
'guarantee' 'guava'
'hairy' 'hand' 'happier' 'headache' 'help' 'here' 'hop' 'hope' 'hopping'
'hosier' 'hatch' 'hurtle' 'hymns'
'idiot' 'ice' 'if' 'impropriety' 'inn' 'incomparable' 'inflation' 'ink'
'insolent' 'itchy'
'jangle' 'jaw' 'jealousy' 'joker' 'jump' 'judge' 'juicy' 'justify'
'kangaroo' 'keenly' 'keep' 'kidney' 'king' 'kitchen' 'knapsack'
'knowledge' 'knuckle'
'languid' 'led' 'lavish' 'ladylike' 'leverage' 'light' 'like'
'liquid' 'loathsome' 'lobster' 'lord' 'lucid' 'lucky'
'machine' 'mad' 'magnificent' 'marauding' 'marriage' 'meat' 'medicine'
'meet' 'milk' 'misinterpret' 'misled' 'music' 'my'
'nail' 'navel' 'never' 'nicest' 'nose'
'one' 'onerous' 'optical' 'orange' 'out' 'outlaw' 'over' 'owl' 'oxygen'
'oyster'
'pea' 'peal' 'peat' 'pending' 'pet' 'petal' 'plan' 'plant' 'polish'
'pony' 'portray' 'prairie' 'prejudice' 'pretty' 'prisoner' 'probe'
'professional' 'programme' 'pry'
'quaint' 'quality' 'quaver' 'queen' 'quiet' 'quintuplet' 'quiver' 'quote'
'rabbit' 'radiated' 'raucous' 'reed' 'relieve'
'respiration' 'riddle' 'rift' 'rocking' 'rosary' 'rude' 'ruler' 'run'
'sadly' 'sardine' 'set' 'shake' 'shrunken' 'simpleton' 'six' 'skip'
'skullduggery' 'sky' 'snippet' 'snowy' 'socks'
'soil' 'stank' 'stop' 'stupidly' 'switch'
'tangle' 'take' 'teacher' 'terminate' 'toe' 'top' 'tortoise' 'trap' 'tree'
'triangle' 'try'
'umbrella' 'uncle' 'unenthusiastic' 'uniform' 'unique' 'up'
'upstairs' 'usually'
'vacuum' 'vague' 'valley' 'vast' 'vermin' 'veils' 'ventriloquist' 'very'
'veterinary' 'vicious' 'viewer' 'void' 'volley'
'warranted' 'water' 'way' 'weapon' 'weary' 'went' 'whale' 'whatever'
'where' 'while'
'whispery' 'whole' 'wink' 'wooden' 'worldly'
'yacht' 'yank' 'yearn' 'yellow' 'yet' 'yolk' 'yonder' 'yoyo' 'young'
'zeal' 'zebra' 'zero' 'zip' 'zoo' 'zoom' 'zombie'
] -> words;

if systrmdev(popdevin) then
	play();
endif;

/*  --- Revision History ---------------------------------------------------
--- John Williams, Jan  3 1996
		Moved from C.all/lib/lib to C.all/lib/obsolete
--- Robert John Duncan, Oct 11 1994
		Added popturtlelib
--- Aaron Sloman, Aug 18 1986 time for new words
--- Mark Rubinstein, Oct 28 1985 - removed some POP-2isms
--- John Williams, Jul 30 1985:  changed UNPACKWORD to UNPACKITEM
 */
