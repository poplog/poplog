/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:           $popneural/lib/nn_newnets.p
 > Purpose:        to allow new network types to be declared
 >
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:  $popneural/lib/networkdefs.p
 */

include sysdefs;


section $-popneural =>  nn_declare_net
                        nn_net_title
                        nn_net_dataword
                        nn_net_cons_fn
                        nn_net_dest_fn
                        nn_net_recognise_fn
                        nn_net_save_fn
                        nn_net_load_fn
                        nn_net_inputs_fn
                        nn_net_outputs_fn
                        nn_net_array_fn
                        nn_net_apply_item_fn
                        nn_net_apply_set_fn
                        nn_net_learn_item_fn
                        nn_net_learn_set_fn
                        nn_net_varlist
                        nn_make_net
                        nn_copy_net
                        nn_delete_net
                        nn_kill_windows
;

uses external;
uses c_dec;
uses nn_utils;


/* ----------------------------------------------------------------- *
     New Net Type Declaration Functions
 * ----------------------------------------------------------------- */

;;; nn_declare_net declares a new network type. It is used as a means to
;;; expand the currrent net types in a way which will reduce the changes
;;; to the system as new network types are added
define global nn_declare_net(
                              title,
                              dword,
                              conser,
                              dester,
                              recogniser,
                              saver,
                              loader,
                              n_ins,
                              n_outs,
                              arraymaker,
                              apply_item,
                              apply_set,
                              learn_item,
                              learn_set,
                              var_list);

lvars title dword conser dester recogniser saver loader n_ins n_outs
      arraymaker apply_item, apply_set learn_item learn_set var_list rec;

    consnn_net_data(title, dword, conser, dester, recogniser,
                    saver, loader, n_ins, n_outs, arraymaker,
                    apply_item, apply_set, learn_item, learn_set,
                    var_list) -> rec;
    rec -> nn_net_descriptors(dword);
    (title :: hd(nn_net_type_menu)) :: (dword :: tl(nn_net_type_menu))
        -> nn_net_type_menu;
enddefine;


/* ----------------------------------------------------------------- *
    Generic Net Type Accessors
 * ----------------------------------------------------------------- */


define global constant nn_net_title(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_title(val) -> val;
    endif;
enddefine;

define updaterof global constant nn_net_title(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_title(nn_net_descriptors(net_dword));
    endif;
enddefine;

define global constant nn_net_dataword(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_dataword(val) -> val;
    endif;
enddefine;

define updaterof global constant nn_net_dataword(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_dataword(nn_net_descriptors(net_dword));
    endif;
enddefine;

define global constant nn_net_cons_fn(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_cons_fn(val) -> val;
    endif;
enddefine;

define updaterof global constant nn_net_cons_fn(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_cons_fn(nn_net_descriptors(net_dword));
    endif;
enddefine;

define global constant nn_net_dest_fn(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_dest_fn(val) -> val;
    endif;
enddefine;

define updaterof global constant nn_net_dest_fn(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_dest_fn(nn_net_descriptors(net_dword));
    endif;
enddefine;

define global constant nn_net_recognise_fn(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_recognise_fn(val) -> val;
    endif;
enddefine;

define updaterof global constant nn_net_recognise_fn(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_recognise_fn(nn_net_descriptors(net_dword));
    endif;
enddefine;

define global constant nn_net_save_fn(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_save_fn(val) -> val;
    endif;
enddefine;

define updaterof global constant nn_net_save_fn(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_save_fn(nn_net_descriptors(net_dword));
    endif;
enddefine;

define global constant nn_net_load_fn(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_load_fn(val) -> val;
    endif;
enddefine;

define updaterof global constant nn_net_load_fn(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_load_fn(nn_net_descriptors(net_dword));
    endif;
enddefine;

define global constant nn_net_inputs_fn(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_inputs_fn(val) -> val;
    endif;
enddefine;

define updaterof global constant nn_net_inputs_fn(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_inputs_fn(nn_net_descriptors(net_dword));
    endif;
enddefine;

define global constant nn_net_outputs_fn(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_outputs_fn(val) -> val;
    endif;
enddefine;

define updaterof global constant nn_net_outputs_fn(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_outputs_fn(nn_net_descriptors(net_dword));
    endif;
enddefine;

define global constant nn_net_array_fn(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_array_fn(val) -> val;
    else
        array_of_double -> val;           ;;; ensure sensible function
    endif;
enddefine;

define updaterof global constant nn_net_array_fn(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_array_fn(nn_net_descriptors(net_dword));
    endif;
enddefine;

define global constant nn_net_apply_item_fn(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_apply_item_fn(val) -> val;
    endif;
enddefine;

define updaterof global constant nn_net_apply_item_fn(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_apply_item_fn(nn_net_descriptors(net_dword));
    endif;
enddefine;

define global constant nn_net_apply_set_fn(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_apply_set_fn(val) -> val;
    endif;
enddefine;

define updaterof global constant nn_net_apply_set_fn(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_apply_set_fn(nn_net_descriptors(net_dword));
    endif;
enddefine;

define global constant nn_net_learn_item_fn(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_learn_item_fn(val) -> val;
    endif;
enddefine;

define updaterof global constant nn_net_learn_item_fn(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_learn_item_fn(nn_net_descriptors(net_dword));
    endif;
enddefine;

define global constant nn_net_learn_set_fn(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_learn_set_fn(val) -> val;
    endif;
enddefine;

define updaterof global constant nn_net_learn_set_fn(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_learn_set_fn(nn_net_descriptors(net_dword));
    endif;
enddefine;

define global constant nn_net_varlist(net_dword) -> val;
lvars net_dword val;
    if (isnettype(net_dword) ->> val) then
        net_varlist(val) -> val;
    endif;
enddefine;

define updaterof global constant nn_net_varlist(val, net_dword);
lvars net_dword val;
    if isnettype(net_dword) then
        val -> net_varlist(nn_net_descriptors(net_dword));
    endif;
enddefine;


/* ----------------------------------------------------------------- *
    Generic Net Creators/Destroyers
 * ----------------------------------------------------------------- */

define global constant nn_make_net(dword);
lvars dword net_type = nn_net_descriptors(dword);
    if net_type then
        apply(net_cons_fn(net_type));
    endif;
enddefine;


;;; nn_copy_net takes a network and copies it
define global constant nn_copy_net(net) -> netcopy;
lvars net item index netcopy key;
    if isword(net) then
        nn_neural_nets(net) -> net;
    endif;
    if net then
        newcopydata(net) -> netcopy;
    else
        false -> netcopy;
    endif;
enddefine;

;;; don't give declaring variable message
global vars procedure nn_kill_windows = erase;

define global nn_delete_net(name);
lvars name;
    false -> nn_neural_nets(name);

#_IF DEF PWMNEURAL
    if popunderpwm then
        nn_kill_windows(name);
    endif;
#_ENDIF

#_IF DEF XNEURAL
    if popunderx then
        nn_kill_windows(name);
    endif;
#_ENDIF

    if name == nn_current_net then
        false -> nn_current_net;
    endif;
enddefine;

endsection;     /* $-popneural */

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 5/8/93
    Changed back to use external and c_dec.
-- Julian Clinton, 6/7/93
    Changed to use newexternal/newc_dec and removed loading of fortran_dec.
-- Julian Clinton, 14/8/92
    Moved nn_delete_net in here from nn_apply.p.
-- Julian Clinton, 8/5/92
    Sectioned.
*/
