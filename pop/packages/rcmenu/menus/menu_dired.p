/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/menus/menu_dired.p
 > Purpose:			VED's dired facilities via menu buttons
 > Author:          Aaron Sloman, Aug 10 1999
 > Documentation:
 > Related Files:
 */

/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_dired.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 21 1995
 */

/*
-- -- Menu concerned with dired options
*/

section;

uses rcmenulib

uses ved_menu_doc;

define :menu dired;
   	'Dired Ops'
	'Menu dired'
	'File and\ndirectory\nbrowser\n(ved_dired)'
	['HELP Dired' 'menu_doc help dired']
	['ListFiles*'
		[ENTER 'dired *'
			['Use the "dired" command with a directory name'
			'or a pattern, or give the command with a file or'
			'directory name at right of current line in VED buffer'
			'Format: dired <flags> <pattern>, e.g.:'
			'dired  -lt  *.p']]]
	['PrevLine' vedcharup]
	['NextLine' vedchardown]
	['GetFile' 'dired']
	['ExpandDir' 'dired']
	['UnExpandDir' 'do;ml;dired -dcd']	;;; Move down a line first
	['ListDirs' 'dired -d']
	['LatestFirst' 'dired -lt']
	['ListLong' 'dired -l']
	['Quit&List' 'qdired']
	['MoveFile*' [ENTER 'dired -mv <target>'
		['Move or rename the file to right'
		'of current line to <target> see "man mv"'
		'(also HELP DIRED)']]]
	['RenameFile*' [ENTER 'dired -mvd <newname>'
		['Rename the file to right' 'of current line to <newname>'
		'(i.e. rename in same directory)'
		'See "man mv" and HELP DIRED']]]
	['CopyFile*' [ENTER 'dired -cp <newname>'
		['Copy the file to right of current line to <newname>'
		 '(<newname> can be either file path name or directory'
		'see "man cp" (and HELP DIRED)']]]
	['CopySameDir*' [ENTER 'dired -cpd <newfile>'
		['Copy the file to right of current line to <newfile>'
		'in the same directory See "man cp"(and HELP DIRED)']]]
	['DeleteTheFile' 'dired -rm']
	['PeekAtFile' 'dired -peek']
;;;	[Readonly 'dired -r']
;;;	[Writeable 'dired -w']
	['MENUS...' [MENU toplevel]]
enddefine;

endsection;
