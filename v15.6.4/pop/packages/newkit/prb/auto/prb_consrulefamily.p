/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_consrulefamily.p
 > Purpose:         Create a rulefamily record
 > Author:          Aaron Sloman, Apr 21 1996
 > Documentation:	LIB * define_rulefamily
 > Related Files:
 */

/*

	prb_consrulefamily
		This one actually creates rulefamilies, and can be used
		directly if required.

For full details see HELP * RULESYSTEMS

-- prb_consrulefamily (create a rulefamily)

prb_consrulefamily(name, rulesets, next, lim, sect, debug, vec) -> family;

INPUTS:
1.	A word -- name of a rule family
2.	A list of rulesets (each of form defined below)
3.	A ruleset (list of rules) or name of ruleset(word) to be run first
4.	The number of times to cycle with this rulefamily in prb_run (or false)
5.	False or a section in which to run the rules
6.	A boolean to determine whether rulesets should be recompileable
		(they are represented by identifier and accessed via idval
		if debug is true)
7.  False or a two element vector containing a list of words to add to
	popmatchvars and a procedure to be run to initialise the matcher
	variables.
RESULT: a rulefamily record.

Format for list of rulesets (2nd argument):
	The elements in the list of rulesets may either be words or lists
	of rules or two-element vectors.
 		A word is taken to be a name of a ruleset (accessible via valof)
 		A vector of two elements should contain a word and the corresponding
			ruleset, usually a list of rules.
		A list of rules should start with a word with which the rules
			are to be associated.
			
*/

compile_mode :pop11 +strict;

uses poprulebase
uses rulefamily
section;

define prb_consrulefamily(
		name, rulesets, next, lim, sect, debug, vec, dlvec) -> family;

	lvars prop = newproperty([], length(rulesets), false, "tmparg");

	if sect then
		current_section -> sect
	endif;

	;;; Create the rule-family
	consprb_rulefamily(name, prop, next, [], lim, sect, vec, dlvec) -> family;

	;;; Now put the rulesets in the property
	lvars ruleset;
	for ruleset in rulesets do
		if isword(ruleset) then
			;;; if debug, store the identifier, whose value should
			;;; be the ruleset list. Then the agent will work with new
			;;; rules after the ruleset has been changed.
			if debug then identof(ruleset) else valof(ruleset) endif
				-> prop(ruleset)
		elseif islist(ruleset) then
			;;; It should be of the form [^key ^^ruleset]
			;;; use the front as the key for the property.
			back(ruleset) -> prop(front(ruleset))
		else
			mishap('RULESET in family ' >< name >< ' has wrong format ',
				[^ruleset])
		endif
	endfor
enddefine;

endsection;
