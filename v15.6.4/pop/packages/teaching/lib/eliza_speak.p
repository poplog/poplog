/* --- Copyright University of Birmingham 2009. All rights reserved. ------
 > File:			$usepop/pop/packages/teaching/auto/eliza_speak.p
 > Purpose:			Invoke eliza, using espeak to say things out loud
 > Author:			Aaron Sloman, Jul 18 2009 (see revisions)
 > Documentation:
 > Related Files:
 */



compile_mode :pop11 +strict;

;;; If you wish to see how the main eliza program is defined do
;;;	SHOWLIB * ELIZAPROG

section;

uses teaching

;;; Now make the eliza procedure available
uses elizaprog


define global vars procedure eliza_output(answer);
	ppr(answer);
	pr(newline);
	sysflush(poprawdevout);
	;;; make her voice female
	sysobey('espeak -v+f4 -s 120 "'>< flatten(answer) ><'"');
	;;;sysobey('flite " '>< flatten(answer) ><'" play');
enddefine;

;;; pr('\n\nGive the command\n\neliza();\n\n');


;;; for uses
global vars eliza_speak = eliza;
endsection;


/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 18 2009
		Separated out just the eliza procedure
 */
