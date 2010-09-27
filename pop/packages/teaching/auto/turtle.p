/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 > File:            C.all/lib/auto/turtle.p
 > Purpose:         Loader for the Pop-11 "turtle" graphics package
 > Author:          John Williams, Jul 19 1993 (see revisions)
 > Documentation:   HELP * TURTLE, TEACH * TURTLE
 > Related Files:   C.all/lib/turtle/ (directory), LIB * POPTURTLELIB
 */

#_TERMIN_IF DEF POPC_COMPILING

section;

uses popturtlelib;

pop11_compile(popturtlelib dir_>< 'turtle.p');


endsection;
