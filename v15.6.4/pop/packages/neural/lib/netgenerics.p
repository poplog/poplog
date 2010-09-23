/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:           $popneural/lib/netgenerics.p
 > Purpose:        constructs to allow new net types to be added easily
 >
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:  networkdefs.p
 */

section;

extend_searchlist('$popneural/src/pop/', popuseslist) -> popuseslist;
load $popneural/src/pop/nn_structs.p
load $popneural/src/pop/nn_macros.p
load $popneural/src/pop/nn_defs.p
load $popneural/src/pop/nn_activevars.p
load $popneural/src/pop/nn_newnets.p
load $popneural/src/pop/nn_dtconverters.p
load $popneural/src/pop/nn_examplesets.p
load $popneural/src/pop/nn_apply.p
load $popneural/src/pop/nn_file_io.p

global vars netgenerics = true;

endsection;

/*  --- Revision History --------------------------------------------------
*/
