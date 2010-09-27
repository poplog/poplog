/* --- Copyright University of Birmingham 2009. All rights reserved. ------
 > File:			$usepop/pop/lib/auto/speak_flite.p
 > Purpose:			
 > Author:			Aaron Sloman, Jul 16 2009
 > Documentation:
 > Related Files:
 */

/*

;;; tests
speak_flite('Will this come out ok?');
speak_flite([Will this come out ok?]);

*/

;;; Requires unix/linux program 'flite' to be installed.

define speak_flite(sentence);
	;;; sentence should be a string or word or list of strings or words.
	;;; It should  not include quotation marks.
	if islist(sentence) then
		flatten(sentence) -> sentence;
	endif;

	sentence ==>

	;;; get all printing dnow
	;;; sysflush(popdevout);
	sysflush(poprawdevout);
	;;; Make sure there is a space in the input to flite
	sysobey('flite "'>< sentence ><' " play');
	
enddefine;
