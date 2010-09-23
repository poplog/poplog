/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved ---------
 > File:           $popneural/lib/netdisplay.p
 > Purpose:        loads the graphical interface
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:
 */

section;

exload_batch;
uses netgenerics;

load $popneural/src/pop/nn_accessors.p
load $popneural/src/pop/nn_utils.p
#_IF DEF GFXNEURAL
load $popneural/src/pop/nn_gfxdefs.p
load $popneural/src/pop/nn_gfxdialogs.p
load $popneural/src/pop/nn_gfxdraw.p
load $popneural/src/pop/nn_gfxevents.p
load $popneural/src/pop/nn_netdisplay.p
#_ENDIF

endexload_batch;

global vars netdisplay = true;

endsection;


/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 27/7/92
    Changed GFX to GFXNEURAL.
-- Julian Clinton, 17/7/92
    Modified for new filenames and moved UI-related files to popneural.p
-- Julian Clinton, 04/06/92
    Removed explicit load of pwmlabelitem.
-- Julian Clinton, 01/06/92
    Made GFXNEURAL flag global.
*/
