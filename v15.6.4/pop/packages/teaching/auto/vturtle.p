/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 > File:            C.all/lib/auto/vturtle.p
 > Purpose:         Loader for the VED version of the Pop-11 "turtle" package
 > Author:          John Williams, Jul 19 1993
 > Documentation:   HELP * VTURTLE, TEACH * VTURTLE
 > Related Files:   C.all/lib/turtle/ (directory), LIB * POPTURTLELIB
 */

#_TERMIN_IF DEF POPC_COMPILING

section;

uses popturtlelib;

pop11_compile(popturtlelib dir_>< 'vturtle.p');


endsection;
