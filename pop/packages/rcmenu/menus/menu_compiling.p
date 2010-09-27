/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/menus/menu_compiling.p
 > Purpose:         Drive compilation facilities via menu
 > Author:          Aaron Sloman, Jan 21 1995 (see revisions)
					See also LIB RC_PROCBROWSER
-- Compiling stuff
 */

section;

uses rclib

uses rcmenulib
uses menu_vedinput

#_IF vedusewindows == "x"
uses menu_xved_utils
#_ENDIF


define :menu compiling;
    'Compiling'
	{cols 2}
	'Menu compiling'
    'Mark, justify, compile'
	['BrowseProcs*' ved_procbrowser]
	['BrowseFiles*' menu_choosefile2]
	['PageUp' vedprevscreen]
	['PageDown' vednextscreen]
    ['MarkStart' vedmarklo]
    ['MarkEnd' vedmarkhi]
    ['ClearMark' ved_crm]
    ['TidyProcedure' ved_jcp]
    ['CompileFile' [POP11 menu_vedinput(ved_l1)]]
    ['CompileRange' [POP11 menu_vedinput(ved_lmr)]]
    ['CompileProc' [POP11 menu_vedinput(ved_lcp)]]
    ['CompileLine' [POP11 menu_vedinput(vedloadline)]]
#_IF vedusewindows == "x"
	['CompSelection' [POP11 menu_vedinput(menu_clipboard_compile)]]
	['PasteSelection' menu_clipboard_paste]
	['CopySelection' menu_clipboard_transcribe]
	['CutSelection' [POPNOW menu_clipboard_cut()]]
	['MoveSelection' [POPNOW menu_clipboard_move()]]
	['ClearSelection' menu_clipboard_clear]
	['XVedFonts...' [MENU xvedfonts]]
#_ENDIF
    ['ImmediateMode' ved_im]
#_IF DEF MOTIF
	['MotifBrowser*'
    	;;; Button to invoke the Poplog file browser to select a file to compile.
	    [POP11 pop_ui_compiletool(false,'~',false, false)]]
#_ENDIF
    ['Editor...' [MENU editor]]
    ['Control...' [MENU control]]
	['List Procs' 'headers']
	['Go Proc' 'gp']
    ['Mark...' [MENU mark]]
    ['HELP Mark' 'menu_doc help mark']
    ['HELP Lmr' 'menu_doc help lmr']
	['HelpFor' '??']    ;;; get help for item to right of cursor
    ['MENUS...' [MENU toplevel]]
enddefine ;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 15 1999
	Made to invoke ved_procbrowser, which chooses the browser on the
	basis of file_extension.
--- Aaron Sloman, Aug 28 1999
	Moved rc_procbrowser to a separate library
--- Aaron Sloman, Jan 20 1998
	Added List Procs and Go Proc buttons.
--- Aaron Sloman, Oct 24 1997
	Added stuff for Xved
 */
