/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:           $popneural/src/pop/nn_training.p
 > Purpose:        utilities for converting example data to a form
 >                 suitable for the network
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:  nn_dtconverters.p
*/

section $-popneural => nn_learn_egs_item nn_learn_egs;
;

uses netgenerics;


/* ----------------------------------------------------------------- *
    Main Functions
 * ----------------------------------------------------------------- */

;;; nn_learn_egs_item takes an index of the data item to be trained on
;;; (an integer), an example set name and network name (as words) and
;;; the number of iterations (integer). If nn_events is
;;; an empty list or nn_event_timer is 0, training is done in one
;;; call of the training routine. If there are some procedures to
;;; to be executed and nn_event_timer is > 0, training is performed
;;; in chunks. After every nn_event_timer iterations, all procedures
;;; in the list nn_events are applied. Not that at the start of each
;;; training run, nn_iterations is set to 0.
;;;
;;; Note that the values of nn_current_net, nn_current_egs and
;;; nn_training_cycles are dlocal'd so that any user procedures
;;; run applying nn_events procs can find out what network and
;;; example set are being used.
;;;
define global nn_learn_egs_item(item, egsname, netname, iterations);
lvars item iterations i egsname netname arrayfn session incr intemp outtemp
      inunits outunits invec outvec machine eg_rec indata targdata;

dlocal nn_current_net, nn_current_egs,
    nn_training_cycles = iterations;

    if isword(netname) and isneuralnet(netname) then
        nn_neural_nets(netname) -> machine;
    else
        mishap(netname, 1, 'invalid network');
    endif;

    if isword(egsname) and isexampleset(egsname) then
        nn_example_sets(egsname) -> eg_rec;
    else
        mishap(egsname, 1, 'invalid example set');
    endif;

    ;;; now we know they're valid, update nn_current_net/egs
    netname -> nn_current_net;
    egsname -> nn_current_egs;

    unless isinteger(item) then
        index_in_list(item, eg_gendata(eg_rec)) -> item;
        unless item then
            mishap('No such example in example set', [^item]);
        endunless;
    endunless;

    eg_in_data(eg_rec) -> indata;
    unless indata then
        mishap(indata, 1, 'No input data (not generated ?)');
    endunless;

    eg_targ_data(eg_rec) -> targdata;

    nn_net_array_fn(dataword(machine)) -> arrayfn;
    apply(machine, nn_net_inputs_fn(dataword(machine))) -> inunits;
    apply(machine, nn_net_outputs_fn(dataword(machine))) -> outunits;

    eg_in_vector(eg_rec) -> invec;
    eg_out_vector(eg_rec) -> outvec;

    check_array_size(invec, inunits, false, arrayfn)
                                        ->> eg_in_vector(eg_rec) -> invec;
    check_array_size(outvec, outunits, false, arrayfn)
                                        ->> eg_out_vector(eg_rec) -> outvec;

    arrayfn([%1, inunits, 1, 1%], 0.0s0) -> intemp;
    arrayfn([%1, outunits, 1, 1%], 0.0s0) -> outtemp;


#_IF DEF NEURAL_CONTINUOUSDATA
    if eg_discrete(eg_rec) then
        copy_struct(indata(%item%), intemp(%1%), 1, inunits);
        copy_struct(targdata(%item%), outtemp(%1%), 1, outunits);
    else
        ;;; for continuous data, input is continuous
        copy_struct(indata(%item * inunits%), intemp(%1%), 1, inunits);
        check_2d_array(eg_targ_data, arrayfn, eg_rec, outunits);
        copy_struct(targdata(%item%), outtemp(%1%), 1, outunits);
    endif;

#_ELSE      /* Discrete data only */

    copy_struct(indata(%item%), intemp(%1%), 1, inunits);
    copy_struct(targdata(%item%), outtemp(%1%), 1, outunits);
#_ENDIF

    0 -> nn_iterations;

    ;;; if the event timer or events list has a default value
    ;;; then do the training in one chunk
    if (nn_event_timer == 0) or (nn_events == []) then
        apply(intemp, outtemp, iterations, true,
              machine, eg_out_vector(eg_rec),
              nn_net_learn_set_fn(dataword(machine)));

        iterations -> nn_iterations;
    else
    ;;; else the user has set up nn_events and nn_event_timer
    ;;; so need to do training in stages

        maplist(nn_events, apply) ->;
        max(nn_training_cycles div nn_event_timer, 1) -> incr;
        nn_training_cycles div incr -> iterations;

        for session from 1 to incr do

            apply(intemp, outtemp, iterations, true,
                  machine, eg_out_vector(eg_rec),
                  nn_net_learn_set_fn(dataword(machine)));

            iterations + nn_iterations -> nn_iterations;

            maplist(nn_events, apply) ->;
        endfor;
    endif;
enddefine;


;;; nn_learn_egs takes an example set name and network name (as words),
;;; the number of iterations (integer) and a boolean which specifies
;;; whether to show the examples in random order. If nn_events is
;;; an empty list or nn_event_timer is 0, training is done in one
;;; call of the training routine. If there are some procedures to
;;; to be executed and nn_event_timer is > 0, training is performed
;;; in chunks. After every nn_event_timer iterations, all procedures
;;; in the list nn_events are applied. Not that at the start of each
;;; training run, nn_iterations is set to 0.
;;;
;;; Note that the values of nn_current_net, nn_current_egs and
;;; nn_training_cycles are dlocal'd so that any user procedures
;;; run applying nn_events procs can find out what network and
;;; example set are being used.
;;;
define global nn_learn_egs(egsname, netname, iterations, cycle);
lvars iterations egsname netname inunits outunits cycle arrayfn incr session
      machine invec outvec eg_rec targdata continuous_p = false;

dlocal nn_current_net, nn_current_egs,
    nn_training_cycles = iterations;

    if isword(netname) and isneuralnet(netname) then
        nn_neural_nets(netname) -> machine;
    else
        mishap('invalid network', [^netname]);
    endif;

    if isword(egsname) and isexampleset(egsname) then
        nn_example_sets(egsname) -> eg_rec;
    else
        mishap('invalid example set', [^egsname]);
    endif;

    ;;; now we know they're valid, update nn_current_net/egs
    netname -> nn_current_net;
    egsname -> nn_current_egs;

    apply(machine, nn_net_inputs_fn(dataword(machine))) -> inunits;
    apply(machine, nn_net_outputs_fn(dataword(machine))) -> outunits;


#_IF DEF NEURAL_CONTINUOUSDATA
    ;;; if the data is continuous then eg_in_units contains the stepsize
    ;;; (usually the same as the number of input sequences). This has to be
    ;;; left on the stack before calling the apply procedure.
    not(eg_discrete(eg_rec)) -> continuous_p;
    if continuous_p then
        eg_in_units(eg_rec) -> inunits;
    endif;
#_ENDIF


    nn_net_array_fn(dataword(machine)) -> arrayfn;
    eg_in_vector(eg_rec) -> invec;
    eg_out_vector(eg_rec) -> outvec;

    check_array_size(invec, inunits, false, arrayfn)
                                        ->> eg_in_vector(eg_rec) -> invec;
    check_array_size(outvec, outunits, false, arrayfn)
                                        ->> eg_out_vector(eg_rec) -> outvec;

#_IF DEF NEURAL_CONTINUOUSDATA
    ;;; if we have continuous data then currently we need to convert
    ;;; it to 2D !
    if continuous_p then
        check_2d_array(eg_targ_data, arrayfn, eg_rec, outunits);
    endif;
#_ENDIF


    eg_targ_data(eg_rec) -> targdata;
    check_array_size(targdata, outunits, eg_examples(eg_rec), arrayfn)
                        ->> eg_targ_data(eg_rec) -> targdata;

    ;;; unless we have some data then give an error
    unless eg_in_data(eg_rec) then
        mishap(0, 'No input data (not generated ?)');
    else
        0 -> nn_iterations;

        ;;; if the event timer or events list has a default value
        ;;; then do the training in one chunk
        if (nn_event_timer == 0) or (nn_events == []) then

#_IF DEF NEURAL_CONTINUOUSDATA
            if continuous_p then
                inunits;
            endif;
#_ENDIF

            apply(eg_in_data(eg_rec), targdata,
                iterations, cycle, machine, outvec,
                nn_net_learn_set_fn(dataword(machine)));
            iterations -> nn_iterations;
        else
        ;;; else the user has set up nn_events and nn_event_timer
        ;;; so need to do training in stages

            maplist(nn_events, apply) ->;
            max(nn_training_cycles div nn_event_timer, 1) -> incr;
            nn_training_cycles div incr -> iterations;

            for session from 1 to incr do

#_IF DEF NEURAL_CONTINUOUSDATA
                if continuous_p then
                    inunits;
                endif;
#_ENDIF

                apply(eg_in_data(eg_rec), targdata,
                    iterations, cycle, machine, outvec,
                    nn_net_learn_set_fn(dataword(machine)));

                iterations + nn_iterations -> nn_iterations;

                maplist(nn_events, apply) ->;
            endfor;
        endif;
    endunless;
enddefine;


define print_results(results, names);
lvars results names result name;
lconstant pr_string = 'Value for field %p is %p\n';

    for result name in results, names do
        printf(result, name, pr_string);
    endfor;
enddefine;

global vars nn_training = true;

endsection;     /* $-popneural */

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 17/8/92
    Improved checking for presence of training data.
-- Julian Clinton, 12/8/92
    #_IF'd out the support for continuous data.
-- Julian Clinton, 14/7/92
    Moved from $popneural/lib to $popneural/src/pop.
-- Julian Clinton, 10/6/92
    Modified nn_learn_egs and nn_learn_egs_item so that they now run
    events in nn_events after nn_event_timer iterations (previously
    this functionality had only been available via the user interface).
-- Julian Clinton, 11/5/92
    Sectioned.
*/
