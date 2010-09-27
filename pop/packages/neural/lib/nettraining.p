/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved ---------
 > File:           $popneural/lib/nettraining.p
 > Purpose:        loads the network training routines
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:
 */

section;

extend_searchlist('$popneural/src/pop/', popuseslist) -> popuseslist;
uses networkdefs;
uses nn_training;

global vars nettraining = true;

endsection;

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 27/04/93
    Fixed PNF0036 (extend_searchlist result not assigned).
*/
