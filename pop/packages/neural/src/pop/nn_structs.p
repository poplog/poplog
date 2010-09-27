/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:           $popneural/src/pop/nn_structs.p
 > Purpose:        recordclass defs for neural networks, training sets,
 >                 datatypes etc.
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:
 */

section $-popneural =>  nn_datatypes
                        nn_neural_nets
                        nn_example_sets
                        nn_net_descriptors
                        eg_data_source
                        eg_data_destination
                        eg_gen_params
                        eg_gendata
                        eg_apply_params
                        eg_template
                        eg_in_template
                        eg_out_template
                        eg_in_names
                        eg_out_names
                        eg_in_vector
                        eg_out_vector
                        eg_in_units
                        eg_out_units
                        eg_in_examples
                        eg_in_data
                        eg_out_data
                        eg_out_examples
                        eg_targ_data
                        eg_targ_examples
                        eg_examples
                        eg_error
                        eg_name
                        nn_dt_format
                        nn_dt_inconv
                        nn_dt_outconv
                        nn_dt_type
                        ;;; compatability symbols
                        eg_genfn
                        eg_in_info
                        eg_out_info
;

global vars
	nn_datatypes = newproperty([], 32 , false, "perm"),
    nn_neural_nets = newproperty([], 32, false, "perm"),
    nn_example_sets = newproperty([], 32, false, "perm"),
    nn_net_descriptors = newproperty([], 6, false, "perm");

vars menuhelpfiles =
       assoc([['Main Panel' mainpanel]
              ['Help Menu' helpmenu]
              ['Teach & Test Panel' teachtestpanel]
              ['Networks Menu' networksmenu]
              ['Example Sets Menu' examplesetsmenu]
              ['Datatypes Menu' datatypesmenu]
              ['Training Options' trainingoptions]
              ['Log Options' logoptions]
              ['Edit Backprop Net' bpeditmenu]
              ['Edit Complearn Net' cleditmenu]
              ['Edit Example Set' egseditmenu]
              ['Edit Range Type' rangedteditmenu]
              ['Edit General Type' generaldteditmenu]]);

/*
	Example set data structure
*/
recordclass nn_egs
			eg_flags			;;; an integer containing flags about how the
								;;; example data are organised, the data
								;;; source etc. (see description of flags
								;;; in nn_examplesets.p)
			eg_stepsize			;;; an integer of the training step size if
								;;; using continuous data
			eg_data_source		;;; an integer specifying the source of
								;;; the example data
			eg_data_destination	;;; an integer specifying the destination of
								;;; the example data
            ;;; The interpretation of the -eg_gen_params- slot depends on the value
            ;;; in -eg_data_source-.
            ;;; It's either a data generator function (which must produce a list
            ;;; of lists), a string or list of strings (if data source is a file),
            ;;; or the literal data structure.
            eg_gen_params
            eg_gendata          ;;; a store of the data produced by the generator function
			;;; when data has been applied to a network then when data
			;;; is converted, where it is stored depends on the value of
			;;; the -eg_data_destination- flag.
			eg_apply_params
            eg_applydata        ;;; various items associated with the storage of output data
            eg_template         ;;; a template which specifies the format of the example data
            eg_in_template      ;;; a template of the data shown to the network
            eg_out_template     ;;; a template of the data from the network
            eg_in_names         ;;; a list of input field names
            eg_out_names        ;;; a list of output field names
            eg_in_vector        ;;; a dummy input vector (used as a temp. cache)
            eg_out_vector       ;;; a dummy output vector (used as a temp. cache)
            eg_in_units         ;;; the number of input nodes
            eg_out_units        ;;; the number of output nodes
            eg_in_examples      ;;; a store of the high level input data
            eg_in_data          ;;; an array of the converted input data
            eg_out_data         ;;; an array of the actual output data from the network
            eg_out_examples     ;;; a store of the high level actual output data from the network
            eg_targ_data        ;;; an array of the converted target data
            eg_targ_examples    ;;; a store of the high level target data
			eg_examples     	;;; number of examples in the example set
            eg_error            ;;; a vector of the errors for each example in the example set
            eg_name;            ;;; the name of the example set


/*
A datatype consists of:

    1.  a) list of two integers:
		    arguments to converter function
		    items returned by converter functions (same as
		    the number of units needed to represent datatypes)
		b) a word specifying another datatype
		c) a list of words of datatypes

    2.	procedure for converting high level data to
	    real values passed to network

    3.	procedure for converting network values to high level
	    data

    4. 	a generic type e.g. "general", "set", "range", "toggle" etc.

    5.  a non-exported slot which contains any extra information
        required by nn_save_dt. Currently this is only used by
        "general" data types if the user has passed a word a string
        giving the library or filename where the converter is defined.

*/

recordclass nn_dt_record
            nn_dt_format
            nn_dt_inconv
            nn_dt_outconv
            nn_dt_type
            nn_dt_savedata;


/* ----------------------------------------------------------------- *
    Net Functions Accessors
 * ----------------------------------------------------------------- */

/* nn_net_data is the recordclass used to hold information about the
    different types of network in the system.
*/

recordclass nn_net_data
            net_title           ;;; a string    - a string of the net type
            net_dataword        ;;; a word      - the dataword of the recordclass
            net_cons_fn         ;;; a procedure - constructor function
            net_dest_fn         ;;; a procedure - destructor function
            net_recognise_fn    ;;; a procedure - recogniser
            net_save_fn         ;;; a procedure - save network to disk
            net_load_fn         ;;; a procedure - load network from disk
            net_inputs_fn       ;;; a procedure - number of inputs function
            net_outputs_fn      ;;; a procedure - number of outputs function
            net_array_fn        ;;; a procedure - array constructor
            net_apply_item_fn   ;;; a procedure - apply example (non-learning) function
            net_apply_set_fn    ;;; a procedure - apply example set (non-learning) function
            net_learn_item_fn   ;;; a procedure - learn example function
            net_learn_set_fn    ;;; a procedure - learn example set function
            net_varlist;        ;;; a list      - arguments to constructor function

/* ----------------------------------------------------------------- *
    Structure Utilities
 * ----------------------------------------------------------------- */

;;; copy_struct takes two sequences and copies from the first to the second
define copy_struct(struct1, struct2, start_at, end_at);
lvars struct1 struct2 start_at end_at index;
    fast_for index from start_at to end_at do
        struct1(index) -> struct2(index);
    endfast_for;
enddefine;


;;; index_in_list takes an item and a list and returns the index of the
;;; first occurrence of that item in the list or false if the item
;;; does not appear
define index_in_list(item, list) -> result;
lvars item list listindex result = false;
    fast_for listindex from 1 to length(list) do
        if item = list(listindex) then
            listindex -> result;
            quitloop();
        endif;
    endfast_for;
enddefine;


;;; for compatability with Neural 1.0
syssynonym("eg_genfn", "eg_gen_params");
syssynonym("eg_in_info", "eg_in_examples");
syssynonym("eg_out_info", "eg_out_examples");

global vars nn_structs = true;

endsection;		/* $-popneural */

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 27/8/95
        Replaced vars declaration with lvars in copy_struct.
-- Julian Clinton, 21/8/92
	Renamed -eg_genfn- to -eg_gen_params- and -eg_applyfn- to
		-eg_apply_params-.
-- Julian Clinton, 2/7/92
	Added eg_data_destination, eg_applyfn and eg_applydata slots to nn_egs.
-- Julian Clinton, 28/6/92
	Added nn_dt_savedata to nn_dt_record.
-- Julian Clinton, 24/6/92
	Added eg_examples slot to nn_egs recordclass.
-- Julian Clinton, 22/6/92
	Added eg_flags, eg_data_source and eg_stepsize slots to nn_egs
		recordclass.
-- Julian Clinton, 19/6/92
	Modified menuhelpfiles assoc list keys to be consistent with new titles.
-- Julian Clinton, 10/6/92
	Renamed eg_in_info, eg_out_info and eg_targ_info to eg_in_examples,
	eg_out_examples and eg_targ_examples.
-- Julian Clinton, 8/5/92
    Sectioned.
-- Julian Clinton, 25th Sept 1990:
  	Removed "null" and "ignore" datatypes
	Moved maxseq function to nn_dtconverters.p
*/
