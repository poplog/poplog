/* --- Copyright University of Birmingham 2003. All rights reserved. ------
 > File:            $poplocal/local/lib/summarise.p
 > Purpose:			Summarise/parody a text file
 > Author: 			Riccardo Poli and Aaron Sloman October 1996 (see revisions)
 > Documentation:	HELP SUMMARISE
 > Related Files:	LIB GRAMMAR, TEACH GRAMMAR
 */

/*
  AUTHOR: R. Poli and A. Sloman
  DATE:   October 1996
  DESCRIPTION: This program creates a crazy summary of a text file

The basic idea, and the core algorithm are due to Riccardo Poli.

;;; test it

summarise_file('$usepop/pop/teach/respond', 300);
 */

section;
;;; compile_mode :pop11 +strict;

;;; Maximum number of words to be read from input files.
;;; Can be changed if necessary
global vars max_input_words = 20000;

define lconstant learn_frequencies(input_file, max_words) -> ( frequency, dictionary, w1, w2);
	;;; read in up to max_words words from the input_file given and return
	;;;	a frequency table, a dictionary, and the first two words read in.

	;;; The input file can be a character repeater, a file name (a string) or
	;;; '-', meaning use the standard input.

    lvars
		procedure frequency = newproperty([], 257, false, true),
 	  	procedure dictionary = newproperty([], 257, false, true),
		;;; character repeater for the input file
	  	procedure rdchar =
    		if input_file = '-' then
				charin
    		elseif isprocedure(input_file) then
				input_file
			else
 				discin(input_file)
    		endif;

    define lconstant rdvalidchar();
		;;; treat most non-alphanumeric characters as spaces
		lvars char = rdchar();
		if char == termin then
	    	termin
		elseif char < 32 or strmember(char, '-=><[]{}?%!@#$%^&*_+|~;"/\\') then
	    	` `
		elseif strmember(char, '()') then
	    	rdvalidchar();
			else
	    	;;; uppertolower(char)
	    	char
			endif
    enddefine;

    lvars
		;;; create text item repeater for the input stream
		procedure rditem = incharitem(rdvalidchar),
	  	curr_word, prev_word1, prev_word2, sum, counter = 1, x;

	;;;; Treat various characters as alphabetic characters
    for x in [% `'`, `,`, `.`, `"`, `\``, `:`, `0`, `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9` %] do
    	1 -> item_chartype(x,rditem);
    endfor;

    rditem() ->> w1 -> prev_word1;
    rditem() ->> w2 -> prev_word2;
    repeat
	    counter + 1 -> counter;
	    rditem() -> curr_word;

	    if not(frequency(prev_word1)) then
			newproperty([], 53, false, true) -> frequency(prev_word1);
			newproperty([], 53, 0, true) -> dictionary(prev_word1);
	    endif;
	    if not(frequency(prev_word1)(prev_word2)) then
			newproperty([], 53, 0, true) -> frequency(prev_word1)(prev_word2);
	    endif;

	;;; Next line moved from higher up by A.Sloman to avoid termination bug
	quitif( curr_word = termin or counter fi_> max_words  );

	    dictionary(prev_word1)(prev_word2) + 1 -> dictionary(prev_word1)(prev_word2);
	    frequency(prev_word1)(prev_word2)(curr_word) + 1 ->
	    		frequency(prev_word1)(prev_word2)(curr_word);
		if prev_word1 == "." and random(100) > 90 then
			prev_word1, prev_word2 -> (w1, w2)
		endif;
	    prev_word2 -> prev_word1;
	    curr_word -> prev_word2;
	endrepeat;
enddefine;
	

define lconstant generate_word(prev_word1,prev_word2,frequency,dictionary) -> curr_word;
	;;; Generate the next word on the basis of the last two read in.

    lvars sum = 0, val,
	  	freq_table = frequency(prev_word1);
unless freq_table then
	mishap('freq_table false for ' >< prev_word1, []);
endunless;

	lvars
	  	procedure row = frequency(prev_word1)(prev_word2);


	lvars
	  	number_of_occurrences = dictionary(prev_word1)(prev_word2),
	  	threshold;

    if number_of_occurrences == 0 then
 		false -> curr_word;
    else
		random(number_of_occurrences) -> threshold;
    	for curr_word, val in_property row do
	    	sum fi_+ val -> sum;
	    quitif( sum >= threshold );
    	endfor;	
    endif;	
enddefine;


define lconstant last_char(x);
	if isword(x) then
		subscrw(datalength(x), x)
	else
		mishap( x, 1, 'NON-EMPTY WORD NEEDED');
	endif
enddefine;



define summarise_file(file, max_word_count);
    false -> ranseed;

	;;; uncomment for testing
	;;; 1-> ranseed;

    lvars freq, dict, prev1, prev2,
      	count, word_count = 0,
		;

	;;; increase heap size if necessary
    max(popmemlim, 4000000) -> popmemlim;

	;;; read in the file and store the frequencies
    learn_frequencies(file, max_input_words) -> (freq, dict, prev1, prev2);

    datalength(prev1) fi_+ datalength(prev2) fi_+ 1 -> count;

    nl(1);
	npr(if isstring(file) then 'SUMMARY of ' >< file else 'SUMMARY 'endif);
    nl(1);
    spr(prev1);
    spr(prev2);
    repeat
    	(generate_word(prev1,prev2,freq,dict),prev2) -> (prev2,prev1);
    	if prev2 then
    		if count fi_+ datalength(prev2) fi_+ 1 fi_> 60 then
 	    	    0 -> count;
	    	    nl(1);
    		endif;
    		count fi_+ datalength(prev2) fi_+ 1 -> count;
    		spr(prev2);
    	else
			quitloop;
    	endif;
    	if last_char(prev2) == `.` and random(10) fi_< 3 then
			nl(2);
 			0 -> count;
    	endif;
    	word_count fi_+ 1 -> word_count;
    quitif( word_count fi_> max_word_count and last_char(prev2) == `.` );
	endrepeat;
	nl(1);
	npr('GOOD BYE!');
enddefine;

define ved_summarise();
	lvars
		oldcucharout = vedcharinsert,
        oldfile = vedcurrentfile,
		args = strnumber(vedargument);


	define dlocal cucharout(char);
		if vedcurrentfile == oldfile then
			vedpositionpop();
			vededit('SUMMARY', vedhelpdefaults, true);
			vedendfile();
			vedcharinsert -> cucharout;
			vedcharinsert(char);
		endif;
	enddefine;

	;;; if no argument, summarise in 1000 words.
	unless args then 1000 -> args endunless;

	;;; Go to top of file, for vedrepeater, but first remember location
	vedpositionpush();
	vedjumpto(1, 1);
	summarise_file(vedrepeater, args);
	edit(oldfile);
enddefine;


define  $-Pop$-Main();
    lvars
		file = poparglist(1),
      	max_word_count = strnumber(poparglist(2)) ;
		summarise_file(file, max_word_count);
enddefine;


;;; This is for invocation from the shell in the form
;;; pop11 summarise <file> <maxwords>
if length(poparglist) == 2
	and strnumber(poparglist(2))
	and sys_file_exists(poparglist(1))
then
	;;; assume this is being invoked from the command line

	$-Pop$-Main();

endif;

;;; for uses
global vars summarise = true;

endsection;

/*

CONTENTS (access procedures by using ENTER gg)

 define lconstant learn_frequencies(input_file, max_words) -> ( frequency, dictionary, w1, w2);
 define lconstant generate_word(prev_word1,prev_word2,frequency,dictionary) -> curr_word;
 define lconstant last_char(x);
 define summarise_file(file, max_word_count);
 define ved_summarise();
 define  $-Pop$-Main();

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 31 2003
	Altered so that it does not always start with the opening two
	words of the tex.
--- Aaron Sloman, Jun 12 1999
	Fixed bug due to last words read in not having proper entries
 */
