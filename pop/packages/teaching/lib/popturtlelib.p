/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 > File:            C.all/lib/lib/popturtlelib.p
 > Purpose:         Add Pop-11 "turtle" library directory to popautolist
 > Author:          John Williams, Jul 14 1993 (see revisions)
 > Documentation:   REF * LIBRARY
 > Related Files:   C.all/lib/turtle (directory), LIB * TURTLE, LIB * VTURTLE
 */

#_TERMIN_IF DEF POPC_COMPILING

section;

global vars popturtlelib = '$usepop/pop/lib/turtle/' dir_>< '';

extend_searchlist(popturtlelib, popautolist, true) -> popautolist;


endsection;
