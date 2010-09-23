/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/check_deletefile.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

section;

uses pop_ui;

define global vars procedure menu_check_deletefile;
	;;; check whether file is to be deleted then proceed

	vedscreenbell();

	lvars ans =
		pop_ui_confirm(
			'REALLY REMOVE THIS FILE FROM THE DISK?',
			[yes no],
			2,
			false,
			menu_current_menu);

	if ans == 1 then
		dlocal
			vedargument = nullstring,
			pop_file_versions = false, vedversions = false;
        if sysdelete(vedpathname) then
            vedputmessage('DELETED');
        endif;
        false -> vedwriteable;
        ved_q();
	else
		vedputmessage('REPRIEVED')
	endif
enddefine;


endsection;
