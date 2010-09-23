/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_search.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

/*
-- -- Search menu
*/

section;


define :menu search;
	'Search Ops'
	'Menu search'
	['Search*' ved_menu_search]
	['Replace*' ved_menu_subs]
	['SrchForwd*' [ENTER '/<string>' 'Search forward for string']]
	['SrchBack*' [ENTER '\\<string>' 'Search backward for string']]
	['SrchWrd*' [ENTER '"<word>"' 'Search forward for \nunembedded string']]
	['SrchBackWrd*' [ENTER '`<word>' 'Search back for \nunembedded string']]
	[ReSearch ved_re_search]
	[BackReSearch ved_re_backsearch]
	['Subs*' [ENTER 's/<string1>/<string2>/'
		['Interactively replace all occurrences of one'
		'string with another (Choose your own delimiter)'
		'in place of "\")' 'See HELP VEDSEARCH']]]
	['Subs_word*' [ENTER 's"<word1>"<word2>"'
		['Interactively replace non-embedded string(word)'
		 'See HELP VEDSEARCH']]]
	['GlobalSubs*' [ENTER 'gs/<word1>/<word2>/'
		['Global, non interactive substitution' 'of non-embeeded strings.'
		 'See HELP VEDSEARCH']]]
	['SubsInRange*'  [ENTER 'gsr/<string1>/<sstring2>'
		['Global substitution in a range.'
		 'Use \'"\' as delimiter for non-embedded strings']]]
	['SubsInLine*'  [ENTER 'gsl/<string1>/<string2>'
		['Global substitution in a line.'
		 'Use \'"\' as delimiter for non-embedded strings']]]
	['SubsInProc*'  [ENTER 'gsp/<string1>/<string2>'
		['Global substitution in a procedure'
		 'Use \'"\' as delimiter for non-embedded strings'
		 'See TEACH VEDSEARCH']]]
	['Browse...' [MENU dired]]
	['Editor...' [MENU editor]]
	[TEACH 'menu_doc teach vedsearch']
	['TEACH Search' 'menu_doc teach vedsearch']
	['REF Search' 'menu_doc ref vedsearch']
	['TEACH regexp' 'teach regexp']
	['MENUS...' [MENU toplevel]]
enddefine;

endsection;
