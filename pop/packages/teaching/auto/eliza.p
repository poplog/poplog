/* --- Copyright University of Birmingham 2008. All rights reserved. ------
   --- University of Sussex POPLOG file -----------------------------------
 >  File:         	$usepop/pop/packages/teaching/auto/eliza.p
 >  Purpose:        A procedure to compile and run  eliza.
 >  Author:         Aaron Sloman and various others
 >  Documentation:  TEACH * ELIZA
 >  Related Files:  LIB * ELIZAPROG (the program itself)
 */
compile_mode :pop11 +strict;

;;; If you wish to see how the main eliza program is defined do
;;;	SHOWLIB * ELIZAPROG

section;

uses teaching

;;; Now make the eliza procedure available
uses elizaprog

endsection;

/*
;;; Revision notes

-- 4 Feb 2008
	No longer attempts to run eliza saved image
*/
