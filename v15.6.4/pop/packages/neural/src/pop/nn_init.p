/* --- Copyright University of Sussex 1988. All rights reserved. ----------
 > File:            $popneural/src/pop/nn_init.p
 > Purpose:         set up LIB, HELP and REF paths
 > Author:          David Young, Dec  7 1988
 > Documentation:
 > Related Files:   backprop.f, backprop.f, backprop.o, backcomp
 */

section;

extend_searchlist('$popneural/lib', popautolist) -> popautolist;
extend_searchlist('$popneural/src/pop/', popautolist) -> popautolist;

#_IF DEF VMS
unless member(['popneural:[help]' help], vedhelplist) then
    ['popneural:[help]' help] ::
     (['popneural:[ref]' ref] ::
      (['popneural:[teach]' teach] :: vedhelplist)) -> vedhelplist
endunless;

unless member(['popneural:[ref]' ref], vedreflist) then
    ['popneural:[ref]' ref] ::
     (['popneural:[help]' help] ::
      (['popneural:[teach]' teach] :: vedreflist)) -> vedreflist
endunless;

unless member(['popneural:[teach]' teach], vedteachlist) then
    ['popneural:[teach]' teach] ::
     (['popneural:[help]' help] ::
      (['popneural:[ref]' ref] :: vedteachlist)) -> vedteachlist
endunless;

#_ELSE

unless member(['$popneural/help' help], vedhelplist) then
    ['$popneural/help' help] ::
     (['$popneural/ref' ref] ::
      (['$popneural/teach' teach] :: vedhelplist)) -> vedhelplist
endunless;

unless member(['$popneural/ref' ref], vedreflist) then
    ['$popneural/ref' ref] ::
     (['$popneural/help' help] ::
      (['$popneural/teach' teach] :: vedreflist)) -> vedreflist
endunless;

unless member(['$popneural/teach' teach], vedteachlist) then
    ['$popneural/teach' teach] ::
     (['$popneural/help' help] ::
      (['$popneural/ref' ref] :: vedteachlist)) -> vedteachlist
endunless;

#_ENDIF

endsection;

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 29/7/92
    Removed poppwmlib and popsunlib additions.
-- Julian Clinton, 27/7/92
    Renamed GFX to GFXNEURAL.
-- Julian Clinton, 22/6/92
    Changed popliblist to popautolist.
    Renamed file from init.p to nn_init.p
-- Julian Clinton, 8/5/92
    Sectioned.
*/
