/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/isrc_window_object.p
 > Purpose:			Dummy definition, prior to use of rc_window_object
 > Author:          Aaron Sloman, Sep  4 1997
 > Documentation:
 > Related Files:
 */

section;
compile_mode :pop11 +strict;

uses objectclass;

;;; both of these are redefinied in lib rc_window_object

define vars procedure isrc_window_object(w);
	false
enddefine;

define :method rc_widget(w);
	w
enddefine;

sysunprotect("isrc_window_object");
sysunprotect("rc_widget");

endsection;
