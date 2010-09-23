/* --- Copyright University of Birmingham 2009. All rights reserved. ------
 > File:			$usepop/pop/lib/auto/speak_espeak.p
 > Purpose:			Allow Pop-11 to invoke espeak (speech generator) library
 > Author:			Aaron Sloman, Jul 17 2009 (see revisions)
 > Documentation:   HELP SPEAK_ESPEAK
 > Related Files:   $usepop/pop/lib/auto/speak_flite.p
 */


;;; Requires unix/linux program 'espeak' to be installed.

/*
;;;TEST

speak_espeak('glad to know you and yours are still feeling very well today');

*/

section;

global vars espeak_speed;

if isundef(espeak_speed) then
    120 -> espeak_speed
endif;


define speak_espeak(sentence);
	;;; sentence should be a string or word or list of strings or words.
	if islist(sentence) then
		flatten(sentence) -> sentence;
	endif;

	 sentence ==>
	;;; get all printing finished now
	sysflush(poprawdevout);

	;;; use slightly reduced speed, 120 not default 170
    if isinteger(espeak_speed) then

	    sysobey('espeak -s '>< espeak_speed >< ' "'>< sentence ><'"');
    else
	    sysobey('espeak -s 120 "'>< sentence ><'"');
    endif
	
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 18 2009
		Tidied up and removed unnecessary printing
 */
