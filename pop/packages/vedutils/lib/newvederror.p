/* --- Copyright University of Birmingham 2009. All rights reserved. ------
 > File:            $usepop/pop/packages/vedutils/lib/newvederror.p
 > Purpose:			Change compilation errors to use output file instead of status line
 > Author:          Aaron Sloman, Nov 13 2001 (see revisions)
 > Documentation:	See REF vederror, HELP mishap
 > Related Files:
 */


;;; abort compilation of oldvederror is already defined.
#_TERMIN_IF DEF oldvederror

section;

;;; Save old version of vederror
global constant oldvederror = vederror;

pr('\nNB: newvederror.p is no longer needed and should not be compiled\n');

define vars vederror(string);

	;;; ved_l1 is a closure of an inaccessible system procedure.
	;;; we can get at the procedure like this
	lconstant l1_compiler = pdpart(ved_l1);

	if iscaller(ved_lmr) or iscaller(l1_compiler) then
		;;; compiling from marked range, so put mishap message in output file.

		if vedlmr_print_in_file then
			;;; redirect output to that file
			vedlmr_print_in_file -> ved_chario_file
		endif;

		printf('\n;;; MISHAP %p\n;;; (At or before line %p column %p)\n',
				[^string ^vedline ^vedcolumn]);
		if iscaller(l1_compiler) then
				vedinput(vedjumpto(%vedline, vedcolumn%));
		endif;
		vedscreenbell();
		vedscr_flush_output();
	else
		oldvederror(string)
	endif;
enddefine;



global vars newvederror = vederror;

endsection;
 /* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug  5 2009
		This file is no longer needed. Will be withdrawn.
--- Aaron Sloman, Nov 18 2001
	Changed to inform
--- Aaron Sloman, Nov 16 2001
	Fixed to deal with ved_l1
*/
