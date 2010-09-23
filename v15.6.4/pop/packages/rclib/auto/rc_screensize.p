/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_screensize.p
 > Purpose:			Return width and height of current screen
 > Author:          Aaron Sloman, Feb 26 2000
 > Documentation:
 > Related Files:
 */

/*

;;; test it
rc_screensize()=>

*/

section;

uses xlib
uses XlibMacros

define rc_screensize() ->(width, height);
	unless XptDefaultDisplay then XptDefaultSetup(); endunless;

	XDisplayWidth(XptDefaultDisplay,0) -> width;
	XDisplayHeight(XptDefaultDisplay,0) -> height;

enddefine;

endsection;
