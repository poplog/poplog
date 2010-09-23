/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/menus/menu_news.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 21 1995 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
-- -- Menu for' ved_gn (get news) and postnews
Only works at Birmingham now.
*/

section;

uses ved_gn;

define :menu news;
	'News reader'
	{cols 2}
	'Menu news'
	'Reading and sending news'
	['GetNewsGroups' [POP11 ved_gn(); veddo('ved ' <> vednewsrc)]]
	['GetIt' [POP11 dlocal vedediting = true, vedargument = nullstring; ved_gn()]]
	['PageUp' vedprevscreen]
	['PageDown' vednextscreen]
	['SameSubject' 'gns']
	['SameAuthor' 'gna']
	['Catchup' 'gn .']
	['Howmany?' 'gn ?']
	['Show all' 'gn new']
	['Get 100' 'gn 100']
	['Followup' 'followup']
	['Reply' 'followup reply']
	['Send' 'send']
	['NewArticle' 'postnews new']
	['PostThis' 'postnews']
	['QuitThis' 'q']
;;;	['SaveThis' 'save']	;;; needs dialogue to get an argument
	['SaveNewsrc' 'w']
	['CloseLink' 'gn close']
	['HelpNews' 'menu_doc help ved_gn']
	['HelpPost' 'menu_doc help ved_postnews']
	['HelpSetup' 'help ved_gn_setup']
	;;; this may not be optimal!
	['DoSetup*' [ENTER 'gn_setup  news.announce cs comp.ai sci.cog bham. comp.lang comp'
		'Specify the order in which you want news groups. See HELP VED_GN_SETUP']]
	['MENUS...' [MENU toplevel]
]
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 16 1999
	Minor change to make ved_gn fetch articles.
 */
