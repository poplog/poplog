/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_vedblocks.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 29 1995
 > Documentation:
 > Related Files:
 */

/*
-- -- Menu to go with LIB VEDBLOCKS
See HELP VEDBLOCKS
*/

section;

uses vedblocks;

define :menu vedblocks;
	'Vedblocks'
	{cols 2}
	'Menu vedblocks: Text blocks'
	['PageUP' vedprevscreen]
	['Push' vedpushkey]
	['PageDown' vednextscreen]
	['CharUp' vedcharup]
    ['CharLeft' vedcharleft]
	['CharDown' vedchardown]
    ['CharRight' vedcharright]
	['WdLeft' vedwordleft]
	['WdRight' vedwordright]
	['DelBlock' ved_dtb]
	['StaticDel' ved_sdtb]	;;; static delete
	['MoveBlock' ved_mtb]
	['StaticMove' ved_smtb]
	['CopyBlock' ved_ttb]
	['StoreBlock' ved_stb]
	['YankBlock' ved_ytb]
	['StaticYank' ved_sytb]
	['YankOverlay' ved_yotb]		;;; overlay
	['InsertSpaces'  ved_itb] 	;;; insert spaces
	['StaticInsert' ved_sitb]
	['Mouse' vedxgotomouse]	;;; in case not loaded
	['HELP VedBlocks' 'menu_doc help vedblocks']
	['MENUS...' [MENU toplevel]]
enddefine ;

endsection;
