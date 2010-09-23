/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/menus/menu_teach.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 21 1995 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
-- -- "Teach" menu
*/

section;
uses menu_xterm.p


define :menu teach;
	'Teach menu'
	'Menu teach'
	'TEACH files\n and demos'
	;;; ['WindowSize' ved_setwindow]
	['PageUp' vedprevscreen]
	['PageDown' vednextscreen]
	['GoSection' 'g']
	['StartTeach' 'teach quickved']
	['Windowmanager' 'teach ctwm']
	['TeachVed' 'teach ved']
	['TeachMoreVed' 'teach moreved']
	['TeachMark' 'teach mark']
	['TeachVedPop' 'teach vedpop']
	['TeachLoadMark' 'teach lmr']
	['TeachRiver' 'teach river']
	['TEACH Email' 'teach email']
    ['ElizaDemo*' [POP11 menu_xterm(false,'eliza')]]
	['TeachRespond' 'teach respond']
	['TeachDefine' 'teach define']
	['TeachMatches' 'teach matches']
	['TeachDatabase' 'teach database']
	['TeachSets' 'teach sets']
	['PopCore'	'teach popcore']
	;;; ['Tower'	'teach tower']
	;;; ['Searching'	'teach searching']
    ;;; ['LogicTutor*' [POP11 menu_xterm(false,'pop11 +prolog +logic')]]
	;;; next one assumes that a saved image has been set up for LIB LOGIC1
    ['PopLogic*' [POP11 menu_xterm(false,'pop11 +poplogic')]]
	['EditFile*' [ENTER 'ved ?' 'Editing a new file']]
	['Enter' [POP11 vedenter();vedrefreshstatus()]]
	['MENUS...' [MENU toplevel]]
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Oct  1 1999
	Slightly reorganised.
 */
