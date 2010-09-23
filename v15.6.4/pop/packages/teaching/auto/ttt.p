/*  --- Copyright University of Sussex 2009.  All rights reserved. ---------
 >  File:           C.all/lib/auto/ttt.p
 >  Purpose:        typing tutor program
 >  Author:         Aaron Sloman 1979 (see revisions)
 >  Documentation:  TEACH * TTT
 >  Related Files:
 */
compile_mode :pop11 +strict;

/*
This is a program designed to help beginners get used to typing at a
teletype, without having to think about anything besides typing.
The program is invoked by typing TTT; to the POP11 system.
This will cause an explanatory message to be typed out, followed
a sequence of lines of typing to be imitated. Each line typed in by
the user is compared with the prompt line, and if there are any
discrepancies the user is given another chance.  This is repeated
until the number of attempts at that line has reached MAXERRS (default 3),
after which the line is abandoned and the next one offered.

To restart type TTT; again at the end.
To prevent the full explanatory message being printed out, assign FALSE
to NOISYTTT.  The program can be used on a different set of test lines.
E.g. Build a file called TYPING.P in which a list of strings is assigned
to TESTLINES.  Then, after compiling TTT, compile TYPING.P, then
typing TTT; will cause the next lot of testlines to be used.
If any element of TESTLINES is a list of two strings, then the first
is assumed to include an explanatory message, which is printed out,
and the second is the list to be copied.
*/

section;

weak constant procedure ppr;

define lconstant stringtolist(string);
	lvars item, repeater, n, string;
	0 -> n;
	incharitem(stringin(string)) -> repeater;
	[%until (repeater() -> item, item = termin) do
		item
	enduntil%]
enddefine;

global vars  2 ttt;   ;;; defined later.

lvars noisyttt;
;;; Assign FALSE to this before typing TTT; if you want to have
;;; the practice run without the introductory message.

lvars maxerrs;  3 ->maxerrs;
;;; This controls the maximum number of times the user is asked to
;;; try each example.

lvars procedure ttyin; ;;; defined later


define lconstant readstrip;
	lvars n c;
	0->n;
	until   (ttyin()->c, c==`\n`)
	do
		if c == termin then interrupt() endif;
		c, n+1->n
	enduntil;
	if  n==0
	then    'an empty line '
	else    consstring(n);
	endif
enddefine;


lconstant procedure subtestline;

define lconstant testline l;
lvars l;
	;;; given a string, just run subtestline.
	;;; otherwise it is a list of two strings. Print the first, and run
	;;; subtestline with the second
	if islist(l) then
		pr(newline); pr(front(l)); pr(newline);
		l(2) -> l
	endif;
	subtestline(l)
enddefine;


define lconstant _similar (s1,s2);
lvars s1,s2;
	;;; s1 is the test string, s2 is the string typed by user.
	;;; check if s2 is like s1 except for leading and trailing spaces
	define dlocal prmishap();
		clearstack();
		false; exitfrom(_similar)
	enddefine;

	stringtolist(s1)=stringtolist(s2)
enddefine;

lvars count;     ;;; local to subtestline

define lconstant _compare s1 s2;
lvars s1,s2;
	;;; a subroutine for subtestline
	if s1 = s2  or _similar(s1,s2) then
		pr('OK! ');
		true
	else
		if count >= maxerrs then
			pr('we\'ll give that one up, ');
			true
		else
			false
		endif
	endif
enddefine;

define lconstant subtestline l;
lvars l inchar;
dlocal count;

	pr('Try this:\n');
	;;; add a space to match ved's prompt character.
	if vedediting then pr(' ') endif;
	pr(l);
	pr(newline);
	readstrip() -> inchar;
	1 ->count;
	until _compare(l,inchar) or count > 3 do
		if  lmember_=(inchar,['bye' 'BYE' 'goodbye' 'good bye'])
		then    interrupt()
		endif;
		pr('Not quite, you typed: ');
		pr(inchar);
		pr('\ninstead of          : ');
		pr(l);
		pr('\nTry again\n');
		if vedediting then pr(' ') endif;
		pr(l);
		pr(newline);
		readstrip() ->inchar;
		count + 1 ->count;
	enduntil
enddefine;


define lconstant testall l;
lvars l;
  applist(l, testline);
enddefine;

lvars testlines;

[
'hello'
'pop'
 ['Numbers are on the top row. Don\'t confuse the number 0 and the letter O'
	'007']
'2001'
'pop11'
['The next example contains all the letters of the alphabet'
	'the quick brown fox jumped over the lazy dog']
 ['Some symbols require you to hold down the SHIFT KEY while you\npress the key with the symbol required'
	'+']
'*'
'='
['The next symbol is to be found next to the \'0\' on the top row.'
	'-']
';'
':'
['POP11 can be used for arithmetic. (It won\'t actually do it now, as this is\
	a typing lesson). Type in the following and press RETURN:'
	'3 + 5']
['Here is how you say 10 times 66 in POP11'
	'10 * 66']
['The following means 55 plus 44 take away 33 ' '55 + 44 - 33']
['The next symbol is the POP11 print arrow. Don\'t forget the shift key' '=>']
['Here is how you tell POP11 to print 99 plus 66 plus 5' '99 + 66 + 5 =>']
['Here is how you tell POP11 to print the sum of x and y'
	'x + y =>']
['Some POP11 instructions end with a semi-colon'
'lib river;']
['Some instructions use the parentheses ().\n You\'ll need to hold down the SHIFT key'
	'eliza();']
['The word-quote symbol \'"\' also needs the shift key'
	'"fox"']
'putin("fox");'
'getin();'
'add([man at boat]);'
['The pop11 matcher uses the question mark, and up-arrow symbols "?" and "^"'
	'list matches [fred is a ?x]']
'[?y is a ^x]'
'list matches [man at ??x]'
'lookup([man at ?place]);'
['This is how you ask POP11 to make a list of numbers.\n  Note the SQUARE brackets'
'[1 2 3 4]']
['This time it is a list with just one number'
'[1234]']
['If you want to stop this lesson,\
	Please type BYE and press the RETURN button'
'help turtle;']
'draw(5);'
'turn(90);'
'turn(-90);'
'jumpto(5,5);'
'display();'
['The next symbol is called the "assignment arrow".\
	Don\'t use the DEL key for "-"'
	'->']
'assign 3 to x'
'3 -> x;'
'assign "+" to paint'
'"+" -> paint;'
'repeat'
'repeat 4 times'
'draw(5); turn(90);'
'endrepeat;'
'repeat 4 times draw(5); turn(90); endrepeat;'
'define'
'define where;'
'define square (side);'
'enddefine;'
'square(3);'
'x - 5 -> x;'
'add 4 to side'
'side + 4 -> side;'
'draw(side);'
'jumpby(3,4);'
'"a" -> paint;'
'define element (item,list);'
'a procedure of two arguments'
'pr(space);'
'pr(newline);'
'pr(l);'
'<>'
'concatenate list la and list lb'
'la <> lb =>'
'[cat] <> [dog] =>'
'[the quick brown fox jumped over the lazy dog]'
] ->testlines;



define global vars 2  ttt;
	dlocal popprompt ttyin;
	'' -> popprompt;

	charin -> ttyin;


	define dlocal interrupt();
		clearstack();
		ppr('\n\nBYE\n');
		exitfrom(nonop ttt)
	enddefine;

 if noisyttt then
  '\nThis is the POP11 system typing lesson.\
  You will be offered lines of text to copy. Some of them\
  are English and will make sense to you, whereas others use POP11\
  symbols, and may seem like gibberish for the present.\
  Here is how the lesson will go.\n'.pr;
  '\nThe computer will type out lines of text. You type in an exact copy.\
  At the end of each line press the button marked "RETURN" \
  If you notice a typing error yourself, you can delete the last\
  character you typed by pressing the button marked "DEL".\
\
  If you want to delete the whole line and start it again, then\
	 hold down the button marked "CTRL", and type U\
\
  If you make mistakes, you\'ll have two chances to try again.\
  If you get fed up and want to stop, type BYE and press the RETURN button.\n\n'.pr;
 endif;
  testall(testlines);
	  interrupt()
enddefine;

endsection;

if pop_runtime then ttt endif;


/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul  6 2009
	Altered printout if used in ved so that an extra space is used to make
	output match what the user will type.
--- A Sloman, Sep 1986 tidied and tabified
*/
