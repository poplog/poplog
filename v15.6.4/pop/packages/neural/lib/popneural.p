/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved ---------
 > File:           $popneural/lib/popneural.p
 > Purpose:        loads the rest of the POPLOG neural net system
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:
 */

section;

uses
    networkdefs,
    nn_training;

uses
    netdisplay,
    nui_main;

global vars popneural = true;

endsection;


/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 27/7/92
    Removed assignment to GFX to $popneural/bin/mkneural.p
-- Julian Clinton, 23/7/92
    Now only calls uses rather than explicitly loading files.
-- Julian Clinton, 17/7/92
    Moved UI-related files into here from netdisplay.p.
-- Julian Clinton, 01/06/92
    Made GFX flag global.
-- Julian Clinton, 29/5/92
    Removed loading of menudefs.p and txt_top_level.p (neither exist
    anymore)
*/
