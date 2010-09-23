/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/menus/menu_editor.p
 > Purpose:			Provide VED options as menu buttons
 > Author:          Aaron Sloman, Aug 10 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_editor.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

section;

#_IF DEF MOTIF
;;; uses puilib
#_ENDIF

uses rclib
uses rcmenulib

uses rc_control_panel
uses rc_browse_files
uses rc_getfile


uses menu_choosefile1;
uses menu_choosefile2;

#_IF DEF MOTIF
define rc_edittool(name, directory, filter, ref_widget);
	lvars name, directory, filter, ref_widget;
	lvars filename =
		pop_ui_choose_file(false,
				'Ved Open File', 'Open', directory, filter, name, true);

	if filename then
		;;; make relative to current directory, if possible
		lvars path = sysfileok(filename);
		if isstartstring(current_directory, path) then
			allbutfirst(length(current_directory), path) -> filename;
		endif;
#_IF DEF VMS
		;;; under VMS, we need remove the version number, otherwise
		;;; trying to write the file gives an error
		sys_fname(filename, 1, 5) -> filename;
#_ENDIF
		external_defer_apply(vededit(% filename %))
	endif;
enddefine;


define menu_run_edittool();
	rc_edittool(false, '.' ,'*', false)
enddefine;

#_ENDIF

define :menu editor;
	'VED Ops'
	{cols 2}
	 'Menu editor: Ved actions'
	['Refresh' menu_refresh]
	['EditFile*' [ENTER 'ved ' ['Editing a new file.' 'Insert the name on right.']]]
    ;;; ['FastChoose*' menu_choosefile1]
    ['BrowseFiles*' menu_choosefile2]
	['BrowseProcs*' ved_procbrowser]
#_IF DEF MOTIF
	;;; ['MotifBrowse' [POP11 pop_ui_edittool(false,'.',false, false)]]
	['MotifBrowse' menu_run_edittool]
#_ENDIF
	['Autosave*'
		[ENTER 'autosave 5'
		['Get VED to save all files,' 'e.g. every 5 minutes'
		'See HELP VED_AUTOSAVE']]]
	['PurgeFiles*'
		[ENTER 'purgefiles *-'
         ['To delete all files matching a pattern, give the command'
			'below with a pattern. Edit the pattern if necessary'
			'After pressing Do, you will get a request for confirmation'
			'of the form:  "OK?(n=NO,RETURN=yes,s=show)"'
			'Type s to show the files before deciding whether to delete.']]]
	['ScanFiles*' ved_menu_grep]
	['HelpScan' 'help ved_grep']
	['VedProps...' [MENU vedprops]]
	['Mark...' [MENU mark]]
	['Search...' [MENU search]]
	['Move...' [MENU move]]
	['Delete...' [MENU delete]]
	['Blocks...' [MENU vedblocks]]
	['Printing...' [MENU print]]
	['Control...' [MENU control]]
	['CaseChange...' [MENU case]]
	['SaveAll' ved_w]
	['Save1' ved_w1]
	['Quit1' ved_q]
	['RotateBuffs' menu_rotate_files]
	['SwapBuffer' [POP11 menu_apply(vedswapfiles)]]
	['SelectBuffer' [POP11 rc_vedfileselect("middle", "top", '9x15')]]
	['GoIndex...' [MENU index]]
	['Compiling...' [MENU compiling]]
	['Printing...' [MENU print]]
	['Control...' [MENU control]]
	['Dired...' [MENU dired]]
	['KEYMAPS...' [MENU keys]]
	['Ved Browser...' [MENU dired]]
	['Indexing...' [MENU index]]
	['XVED...'	[MENU xved]]
	['HelpVED' 'help ved']
	['HelpCommands' 'ref vedcomms']
	['MENUS...' [MENU toplevel]]

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar  9 2000
	Removed command to compile puilib
	Introduced rc_edittool and used it to replace pop_ui_edittool
	
--- Aaron Sloman, Sep 27 1999
	Added ved_procbrowser
--- Aaron Sloman, Aug 11 1999
	Converted to use rclib mechanisms
 */
