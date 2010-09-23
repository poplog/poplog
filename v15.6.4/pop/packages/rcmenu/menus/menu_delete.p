/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_delete.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 29 1995
 */

/*
-- -- Delete menu
*/

section;
uses menulib
uses menu_check_deletefile;

define global vars vedcharrightdelete();
	vedcharright();veddotdelete();
enddefine;

define global vars vedjoinline();
	;;; join current line with previous line, ignoring vedbreak and vedstatic
	dlocal vedbreak = false, vedstatic = false;
	1 -> vedcolumn;
	vedchardelete()
enddefine;


define: menu delete;
	'Delete'
	{cols 2}
	'Menu delete: Line,\nPart Line, Word, Cut'
	['DelLine' vedlinedelete]
	['YankLine' ved_yankl]
	['DelLineLeft' vedclearhead]
	['DelLineRight' vedcleartail]
	['DelWordLeft' vedwordleftdelete]
	['DelWordRight' vedwordrightdelete]
	['YankPartLine' ved_yankw]
	['DelCharHere' veddotdelete]
	['DelCharLeft' vedchardelete]
	['DelCharRight' vedcharrightdelete]
	['JoinLine' vedjoinline]
	['DelRange'	ved_d]
	['YankRange' ved_y]
	['PushLocation' vedpushkey]
	['Cut' ved_cut]
	['YankCut' ved_splice]
	['ClearBuffer' ved_clear]
	['DelMail' ved_ccm]
	['DelThisFile*' menu_check_deletefile]
	['PurgeFiles*'
		[ENTER 'purgefiles *-'
         ['To delete all files matching a pattern, give the command'
			'below with a pattern. Edit the pattern if necessary'
			'After pressing Do, you will get a request for confirmation'
			'of the form:  "OK?(n=NO,RETURN=yes,s=show)"'
			'Type s to show the files before deciding whether to delete.']]]
	['Blocks...' [MENU vedblocks]]
	['Marking...' [MENU mark]]
;;;	['Undo...' [MENU undo]]
	['Move...' [MENU move]]
	['Editor (VED)...' [MENU editor]]
	['HELP Keys' 'menu_doc help vedkeys Deleting']
	['HELP Comms' 'menu_doc ref vedcomms Deletion']
	['HELP Cut' 'menu_doc ref ved_cut']
	['HELP Undo' 'help undo']
	['MENUS...' [MENU toplevel]]
enddefine;

endsection;
