/* --- Copyright University of Birmingham 2009. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/ved_rcdemo.p
 > Purpose:         Accessing demonstration programs in the
					RCLIB demo library
 > Author:          Aaron Sloman, Mar 30 1997 (see revisions)
 > Documentation:
 > Related Files:
 */

section;
uses rclib;

define ved_rcdemo();
	unless isendstring('.p', vedargument) then
		vedargument sys_>< '.p' -> vedargument
	endunless;

;;;	veddo('pved $poplocal/local/rclib/demo/' dir_>< vedargument)
	veddo('pved ' >< poprclibdir dir_>< 'demo' dir_>< vedargument)
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul  4 2009
		Changed to use poprclibdir
 */
