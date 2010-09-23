/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:           $popneural/lib/networkdefs.p
 > Purpose:        network type declarations
 >
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:  netgenerics.p
 */

section;

include sysdefs;

#_IF DEF HP9000_700     ;;; shouldn't append underscores to symbol names
                        ;;; so pretend it's a COFF machine
global vars COFF = true;
uses external;
uses c_dec;
false -> COFF;

#_ELSE

uses external;
uses c_dec;

#_ENDIF

exload_batch;

uses netgenerics;

;;; competitive learning networks
lib complearn;
nn_declare_net('competitive learning', "clearnnet", make_clnet,
                explode, isclearnnet, cl_save, cl_load,
                clninunits, clnoutunits, array_of_double,
                cl_response, cl_response_set,
                cl_learn, cl_learn_set,
                [inputs
                 net_format
                 learning_rate_winning_units
                 learning_rate_losing_units
                 sensitivity_eq_winning_units
                 sensitivity_eq_losing_units]);


;;; back propagation networks
lib backprop;
nn_declare_net('back-propagation', "bpropnet", make_bpnet, explode,
                isbpropnet, bp_save, bp_load,
                bpninunits, bpnoutunits, array_of_double,
                bp_response, bp_response_set,
                bp_learn, bp_learn_set,
                [inputs
                 net_format
                 weight_var
                 eta
                 alpha]);
endexload_batch;

global vars networkdefs = true;

endsection;

/*  --- Revision History --------------------------------------------------
--- Julian Clinton, 30/8/95
    Added exload_batch/endexload_batch.
--- Julian Clinton, 17/8/93
    Added fix for incorrect C_DEC appending of underscores to symbol names.
--- Julian Clinton, Aug  5 1993
    Changed backprop and complearn to use array_of_double (C array)
    rather than array_of_real (Fortran array).
*/
