/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:           	$popneural/src/pop/nn_examplesets.p
 > Purpose:        	utilities for creating sets of example data
 >                 	suitable for a network
 > Author:         	Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:  	nn_dtconverters.p
*/

section $-popneural =>  nn_template_io
                        nn_template_type
                        nn_template_name
                        nn_remove_filetypes
                        nn_parse_example
                        nn_unparse_example
                        nn_get_example_from_files
                        nn_make_egs
                        nn_generate_egs
                        nn_generate_egs_input
                        nn_copy_egs
                        nn_delete_egs
                        eg_rawdata_in
                        eg_rawdata_out
                        eg_keep_egs
                        eg_gen_output
                        EG_FILE
                        EG_PROC
                        EG_LITERAL
                        EG_EGS
                        EG_RAWDATA_IN
                        EG_RAWDATA_OUT
                        EG_KEEP_EXAMPLES
                        EG_GEN_OUTPUT
                        eg_default_flags
                        eg_default_rawdata_in
                        eg_default_rawdata_out
                        eg_default_keep_egs
                        eg_default_gen_output
;

uses nn_structs;
uses nn_utils;
uses nn_dtconverters;
uses nn_file_utils;

/* ----------------------------------------------------------------- *
     Template Accessors
 * ----------------------------------------------------------------- */

define global nn_template_io(template);
lvars template;
    template(1);
enddefine;

define updaterof global nn_template_io(val, template);
lvars val template;
    val -> template(1);
enddefine;

define global nn_template_type(template);
lvars template;
    template(2);
enddefine;

define updaterof global nn_template_type(val, template);
lvars val template;
    val -> template(2);
enddefine;

define global nn_template_name(template);
lvars template;
    if length(template) == 3 then
        template(3);
    else
        "unnamed";
    endif;
enddefine;

define updaterof global nn_template_name(val, template);
lvars val template;
    if length(template) == 3 then
        val -> template(3);
    else
        template <> [^val] -> template;
    endif;
enddefine;

define count_template_direction(template, directions) -> n_items;
lvars template values n_items = 0, rest_list item;

	template -> rest_list;
	while rest_list /== [] do
		dest(rest_list) -> rest_list -> item;
		if lmember(nn_template_io(item), directions) then
			n_items fi_+ 1 -> n_items;
		endif;
	endwhile;
enddefine;

global vars procedure
	count_template_inputs = count_template_direction(%[in both]%),
	count_template_outputs = count_template_direction(%[out both]%),
;


/* ----------------------------------------------------------------- *
     Flag Definitions, Predicates And Accessors
 * ----------------------------------------------------------------- */

;;; example set data sources or destinations
global constant
	EG_FILE 			= 2,	;;; 1 or more files
	EG_PROC 			= 8,	;;; a procedure
	EG_LITERAL 			= 9,	;;; supplied as a structure (e.g. a list)
	EG_EGS     			= 10,	;;; another example set
;

define egs_from_X(eg_rec, X) -> boole;
lvars eg_rec X boole;
	unless isinteger(eg_rec) then
		eg_data_source(eg_rec)
	else
		eg_rec
	endunless == X -> boole;
enddefine;

define updaterof egs_from_X(boole, eg_rec, X);
lvars eg_rec X boole;
	if boole then		;;; assigning false changes nothing
		X -> eg_data_source(eg_rec);
	endif;
enddefine;


define egs_to_X(eg_rec, X) -> boole;
lvars eg_rec X boole;
	unless isinteger(eg_rec) then
		eg_data_destination(eg_rec)
	else
		eg_rec
	endunless == X -> boole;
enddefine;

define updaterof egs_to_X(boole, eg_rec, X);
lvars eg_rec X boole;
	if boole then		;;; assigning false changes nothing
		X -> eg_data_destination(eg_rec);
	endif;
enddefine;


;;; These procedures can either take the slot value or an example set record
;;; although updating requires an example set record.
global vars procedure
	egs_from_file = egs_from_X(%EG_FILE%),
	egs_from_proc = egs_from_X(%EG_PROC%),
	egs_from_literal = egs_from_X(%EG_LITERAL%),
	egs_from_egs = egs_from_X(%EG_EGS%),
	egs_to_file = egs_to_X(%EG_FILE%),
	egs_to_proc = egs_to_X(%EG_PROC%),
	egs_to_literal = egs_to_X(%EG_LITERAL%),
	egs_to_egs = egs_to_X(%EG_EGS%),
;

;;; eg_has_filetypes checks the the datatype of the head of the
;;; example set template and if it is a filetype, it returns the
;;; name of the file type, otherwise it returns false.
;;;
define global eg_has_filetypes(eg_rec) -> boole;
lvars eg_rec boole template ftype;
	eg_template(eg_rec) -> template;
	if islist(template) and length(template) fi_> 0 and
	  is_file_dt(nn_template_type(hd(template)) ->> ftype) then
		ftype
	else
		false
	endif -> boole;
enddefine;


;;; template_filetype takes an index (integer) and a template and
;;; returns the filetype of the entry indicated by the index or false
;;; if it is not a filetype.
;;;
define template_filetype(index, template) -> ftype;
lvars index template ftype;
	;;; is_file_dt should return the actual type of the template
	is_file_dt(nn_template_type(template(index))) -> ftype;
enddefine;


;;; example set flags
global constant
	EG_RAWDATA_IN		= 2:00000001,	;;; do not convert input data,
	EG_RAWDATA_OUT		= 2:00000010,	;;; do not convert output data,
	EG_USE_INLINES		= 2:00000100,	;;; if this flag is set then use the
										;;; EG_INLINES flag to determine the
										;;; orientation of data, otherwise
										;;; use EG_DISCRETE
	EG_INLINES 			= 2:00001000,	;;; 1 example per line,
	EG_DISCRETE			= 2:00010000,	;;; data is discrete,
	;;; if data source is not LITERAL then this flag defines whether to
	;;; discard the high-level data in the example set once it has been
	;;; converted
	EG_KEEP_EXAMPLES	= 2:00100000,

	;;; EG_GEN_OUTPUT is an internal flag which specifies whether or
	;;; not output items should be expected within the example data
	;;; or simply ignored
	EG_GEN_OUTPUT    	= 2:01000000,
;

global vars
	;;; dummy arg when creating an example set
	EG_DEFAULTS		= EG_DISCRETE || EG_KEEP_EXAMPLES || EG_INLINES
						&&~~ EG_RAWDATA_IN &&~~ EG_RAWDATA_OUT
						&&~~ EG_USE_INLINES || EG_GEN_OUTPUT
;

define eg_flag_set(eg_rec, flag) -> boole;
lvars flag val eg_rec boole;
	(unless isinteger(eg_rec) then
		eg_flags(eg_rec)
	else
		eg_rec
	endunless && flag) /== 0 -> boole;
enddefine;

define updaterof eg_flag_set(boole, eg_rec, flag);
lvars flag val eg_rec boole;
	if boole then
		eg_rec.eg_flags || flag -> eg_rec.eg_flags;
	else
		eg_rec.eg_flags &&~~ flag -> eg_rec.eg_flags;
	endif;
enddefine;

global vars procedure
	eg_discrete = eg_flag_set(%EG_DISCRETE%),
	eg_use_in_lines = eg_flag_set(%EG_USE_INLINES%),
	eg_in_lines = eg_flag_set(%EG_INLINES%),
	eg_rawdata_in = eg_flag_set(%EG_RAWDATA_IN%),
	eg_rawdata_out = eg_flag_set(%EG_RAWDATA_OUT%),
	eg_keep_egs = eg_flag_set(%EG_KEEP_EXAMPLES%),
	eg_gen_output = eg_flag_set(%EG_GEN_OUTPUT%),
;

;;; The next few routines are used to modify the default behaviour
;;; when creating the example set

define active eg_default_flags;
	EG_DEFAULTS
enddefine;

define updaterof active eg_default_flags(val);
lvars val;
	mishap(0, 'Cannot update example set default flags directly');
enddefine;

define updaterof eg_default_flag_set(boole, flag);
lvars flag boole;
	if boole then
		EG_DEFAULTS || flag -> EG_DEFAULTS;
	else
		EG_DEFAULTS &&~~ flag -> EG_DEFAULTS;
	endif;
enddefine;


define eg_default_flag_set(flag) -> boole;
lvars flag boole;
	(EG_DEFAULTS && flag) /== 0 -> boole;
enddefine;

define updaterof eg_default_flag_set(boole, flag);
lvars flag boole;
	if boole then
		EG_DEFAULTS || flag -> EG_DEFAULTS;
	else
		EG_DEFAULTS &&~~ flag -> EG_DEFAULTS;
	endif;
enddefine;

global vars active (
	eg_default_discrete = eg_default_flag_set(%EG_DISCRETE%),
	eg_default_use_in_lines = eg_default_flag_set(%EG_USE_INLINES%),
	eg_default_in_lines = eg_default_flag_set(%EG_INLINES%),
	eg_default_rawdata_in = eg_default_flag_set(%EG_RAWDATA_IN%),
	eg_default_rawdata_out = eg_default_flag_set(%EG_RAWDATA_OUT%),
	eg_default_keep_egs = eg_default_flag_set(%EG_KEEP_EXAMPLES%),
	eg_default_gen_output = eg_default_flag_set(%EG_GEN_OUTPUT%),
);


/* ----------------------------------------------------------------- *
	Field Accessors
 * ----------------------------------------------------------------- */

define global isXfield(item, char) -> boole;
lconstant char_to_direction = assoc([[`i` in] [`o` out]
									 [`b` both] [`n` none]]);
lvars item char boole;

	if isstring(item) then consword(item) -> item; endif;
	uppertolower(item) -> item;
	if length(item) > 0 and subscrw(1, item) == char then
		char_to_direction(char)
	else
		false
	endif -> boole;
enddefine;

global vars procedure
	isinputfield = isXfield(%`i`%),
	isoutputfield = isXfield(%`o`%),
	isbothfield = isXfield(%`b`%),
	isnonefield = isXfield(%`n`%),
;

define global isvalidfield(item) -> boole;
lvars item boole;

	if isstring(item) then consword(item) -> item; endif;
	isinputfield(item) or isoutputfield(item) or isbothfield(item)
		or isnonefield(item) -> boole;
enddefine;


;;; generic way of checking user input. This routine will
;;; return the data value associated with the text input.
;;;
define is_X_data(item, char) -> boole;
lconstant char_to_data = assoc([[`p` ^EG_PROC] [`e` ^EG_EGS]
								[`f` ^EG_FILE] [`l` ^EG_LITERAL]]);
lvars item char boole;

	if isstring(item) then
		consword(item) -> item;
	endif;
	uppertolower(item) -> item;
	(length(item) > 0) and (subscrw(1,item) == char) and
		char_to_data(char) -> boole;
enddefine;

global vars procedure
	is_file_data = is_X_data(%`f`%),
	is_egs_data = is_X_data(%`e`%),
	is_proc_data = is_X_data(%`p`%),
	is_literal_data = is_X_data(%`l`%),
;

define global isdatasource(item) -> boole;
lvars item boole s_type;

	if isstring(item) or isword(item) then
		if isstring(item) then consword(item) -> item; endif;
		is_file_data(item) or is_egs_data(item) or is_proc_data(item) or is_literal_data(item)
	else
		if (is_file_data(item) ->> s_type) or
			(is_egs_data(item) ->> s_type) or
			(is_proc_data(item) ->> s_type) or
			(is_literal_data(item) ->> s_type) then
			s_type
		else
			false
		endif
	endif -> boole;
enddefine;

;;; have a separate data destination procedure in case this changes
global vars isdatadestination = isdatasource;

define word_of_data_source(item) -> word;
lvars item word;

    if item == EG_FILE then
		"file"
	elseif item == EG_PROC then
		"procedure"
	elseif item == EG_LITERAL then
		"literal"
	elseif item == EG_EGS then
		"exampleset"
	else
		false
	endif -> word;
enddefine;


/* ----------------------------------------------------------------- *
    Example Set Template Parsers
 * ----------------------------------------------------------------- */

;;; extract_input_fields is used to extract the fields in the example set
;;; template that are either input or both fields.
;;;
define extract_input_fields(template) -> in_template;
lvars template entry direction in_template;

    [% fast_for entry in template do
        if isinputfield(nn_template_io(entry) ->> direction) or
          isbothfield(direction) then
            entry;
        endif;
    endfast_for %] -> in_template;
enddefine;


;;; extract_output_fields is used to extract the fields in the example set
;;; template that are either output or both fields.
;;;
define extract_output_fields(template) -> out_template;
lvars template entry direction out_template;

    [% fast_for entry in template do
        if isoutputfield(nn_template_io(entry) ->> direction) or
          isbothfield(direction) then
            entry;
        endif;
    endfast_for %] -> out_template;
enddefine;


;;; parse a template for the input and output types and return them
define parse_template(template) -> input -> output -> innames -> outnames;
lvars entry in_or_out type input = [], output = [],
      innames = [], outnames = [];

    for entry in template do
        if islist(entry) then
            nn_template_io(entry) -> in_or_out;
            nn_template_type(entry) -> type;
            unless nn_datatypes(type) then
                mishap(type, 1, 'Unknown data type');
            endunless;
            if isinputfield(in_or_out) then
                type :: input -> input;
                nn_template_name(entry) :: innames -> innames;
            elseif isoutputfield(in_or_out) then
                type :: output -> output;
                nn_template_name(entry) :: outnames -> outnames;
            elseif isbothfield(in_or_out) then
                type :: input -> input;
                type :: output -> output;
                nn_template_name(entry) :: innames -> innames;
                nn_template_name(entry) :: outnames -> outnames;
            elseunless isnonefield(in_or_out) then
                mishap(in_or_out, 1,
					'Illegal direction - "in", "out", "both" or "none" expected');
            endif;
        endif;
    endfor;

    if null(input) then
        false, false
    else
        ncrev(innames), ncrev(input)
    endif -> input -> innames;

    if null(output) then
        false, false
    else
        ncrev(outnames), ncrev(output)
    endif -> output -> outnames;
enddefine;


;;; set_egs_units_needed takes an example set and calculates
;;; the number of input and output units required. If the data
;;; is being supplied raw then the user must have supplied this
;;; information directly in the template. If the data is not raw
;;; then a standard template must have been supplied so use the
;;; datatype sepcification instead.
define set_egs_units_needed(eg_rec);
lvars eg_rec;

	if eg_rawdata_in(eg_rec) then
		false -> eg_in_units(eg_rec);
	else
		;;; note that for continuous data, the number of input units
		;;; for the neural network must be a multiple of this number
		;;;
        nn_units_needed(eg_in_template(eg_rec)) -> eg_in_units(eg_rec);
	endif;

	if eg_rawdata_out(eg_rec) then
		false -> eg_out_units(eg_rec);
	else
		;;; note that for continuous data, the number of output units
		;;; for the neural network must be a multiple of this number
		;;;
        nn_units_needed(eg_out_template(eg_rec)) -> eg_out_units(eg_rec);
	endif;
enddefine;


/* ----------------------------------------------------------------- *
     Array Converters/Checkers
 * ----------------------------------------------------------------- */

;;; check_array_size is passed an array, a width and height (height
;;; may be false for a 1-D array) and an array creator function.
;;; checks that the array is of the correct dimensions and if not,
;;; creates a new array using the array creator function.
;;;
define global check_array_size(array, ar_width, ar_height, arrayfn)
							-> new_array;
lvars array ar_width ar_height new_array = false, arrayfn blist;

	if isarray(array) then
		boundslist(array) -> blist;

	    if length(blist) == 2 then
	        if (subscrl(2, blist) == ar_width) then
		        array
	        else
    	        arrayfn([1 ^ar_width], 0.0s0)
	        endif
	    else
			;;; assume a 2d array
	        unless (subscrl(2, blist) == ar_width) and
	          (subscrl(4, blist) == ar_height) then
    	        arrayfn([1 ^ar_width 1 ^ar_height], 0.0s0)
	        else
		        array
	        endunless
	    endif
	else
		if ar_height then
    		arrayfn([1 ^ar_width 1 ^ar_height], 0.0s0)
		else
    		arrayfn([1 ^ar_width], 0.0s0)
		endif
	endif -> new_array;
enddefine;


#_IF DEF NEURAL_CONTINUOUSDATA
;;; setup_raw_data_arrays is used to create the data arrays using
;;; the supplied array function. For discrete data, the arrays
;;; are 2-D dimensional while for continuous they are 1-D. This
;;; routine attempts to re-use any existing arrays inside the
;;; example set record to cut down on garbage creation.
;;;
define setup_raw_data_arrays(eg_rec, arrayfn, n_examples)
									-> inp_array -> targ_array;
lvars eg_rec arrayfn n_examples inp_array = false, targ_array = false,
	  n_units;

	if eg_discrete(eg_rec) then

		eg_in_units(eg_rec) -> n_units;
		check_array_size(eg_in_data(eg_rec), n_units, n_examples, arrayfn)
							-> inp_array;

        if isunknown(eg_out_units(eg_rec) ->> n_units) then
            false
        else
			check_array_size(eg_targ_data(eg_rec), n_units, n_examples,
								arrayfn)
        endif -> targ_array;
	else
		;;; continuous data so the arrays are 1-D and reflect the
		;;; number of input and output examples
		check_array_size(eg_in_data(eg_rec), n_examples, false, arrayfn)
							-> inp_array;
		check_array_size(eg_targ_data(eg_rec), n_examples, false, arrayfn)
							-> targ_array;
	endif;
enddefine;

#_ELSE		/* Discrete data only */

define setup_raw_data_arrays(eg_rec, arrayfn, n_examples)
									-> inp_array -> targ_array;
lvars eg_rec arrayfn n_examples inp_array = false, targ_array = false,
	  n_units;

	eg_in_units(eg_rec) -> n_units;
	check_array_size(eg_in_data(eg_rec), n_units, n_examples, arrayfn)
						-> inp_array;

    if isunknown(eg_out_units(eg_rec) ->> n_units)
	  ;;; check we are meant to generate targ arrays
      or not(eg_gen_output(eg_rec)) then
        false
    else
		check_array_size(eg_targ_data(eg_rec), n_units, n_examples,
							arrayfn)
    endif -> targ_array;
enddefine;
#_ENDIF


#_IF DEF NEURAL_CONTINUOUSDATA
;;; convert_to_2d takes a one dimensional array and the width of the
;;; new array (which should be the number of units required) and
;;; returns a new 2d array compatible with the structure required
;;; by the neural net training algorithms.
;;;
define convert_to_2d(array, arrayfn, units_needed, n_units) -> new_array;
lvars array arrayfn units_needed n_units arrvec len new_array
		n_seqs seqs_per_example n_examples stepsize i j seq_offset;

	arrayvector(array) -> arrvec;
	length(arrvec) -> len;
	n_units/units_needed -> seqs_per_example;
	len div units_needed -> n_seqs;

	unless isinteger(seqs_per_example) then
		mishap(seqs_per_example, 1,
				'Ratio of network units/units needed should be an integer');
	endunless;

	unless n_units >= units_needed then
		mishap(0, sprintf(n_units, units_needed,
				'Too few units (%p required, %p supplied)'));
	endunless;

	0 -> seq_offset;
	n_seqs fi_- seqs_per_example fi_+ 1 -> n_examples;

	arrayfn([1 ^n_units 1 ^n_examples], 0.0s0) -> new_array;

	fast_for i from 1 to n_examples do
		fast_for j from 1 to n_units do
			array(seq_offset fi_+ j) -> new_array(j,i);
		endfast_for;
		seq_offset fi_+ units_needed -> seq_offset;
	endfast_for;
enddefine;


;;; convert_to_1d takes a two dimensional array used for training and
;;; returns a new 1d array of sequential data.
;;;
define convert_to_1d(array, arrayfn, units_needed) -> new_array;
lvars array arrayfn blist units_needed n_units arrvec len new_array
		n_seqs seqs_per_example n_examples stepsize i j seq_offset;

	boundslist(array) -> blist;
	unless length(blist) == 4 then
		mishap(array, 1, '2-D array needed');
	endunless;

	blist(4) - blist(3) + 1 -> n_examples;
	blist(2) - blist(1) + 1 -> n_units;

	n_units/units_needed -> seqs_per_example;

	unless isinteger(seqs_per_example) then
		mishap(seqs_per_example, 1,
				'Ratio of network units/units needed should be an integer');
	endunless;

	unless n_units >= units_needed then
		mishap(0, sprintf(n_units, units_needed,
				'Too few units (%p required, %p supplied)'));
	endunless;

	n_examples fi_- 1 + seqs_per_example -> n_seqs;
	units_needed * n_seqs -> len;

	arrayfn([1 ^len], 0.0s0) -> new_array;

	0 -> seq_offset;
	fast_for i from 1 to n_examples do
		fast_for j from 1 to n_units do
			array(j,i) -> new_array(seq_offset fi_+ j);
		endfast_for;
		seq_offset fi_+ units_needed -> seq_offset;
	endfast_for;
enddefine;


;;; check_1d_array ensures that if the slot indicated by accessor
;;; is a 2D array then it will be converted to a 1D array. This
;;; procedure should only be called for converting output or target
;;; arrays in example sets using continuous data.
;;;
define check_1d_array(accessor, eg_rec);
lvars accessor eg_rec array arrayfn;

	accessor(eg_rec) -> array;
	if array and length(boundslist(array)) /== 2 then
			convert_to_1d(array, newanyarray(%datakey(arrayvector(array))%),
					eg_out_units(eg_rec)) -> accessor(eg_rec);
	endif;
enddefine;


;;; check_2d_array ensures that if the slot indicated by accessor
;;; is a 1D array then it will be converted to a 1D array. This
;;; procedure should only be called for converting output or target
;;; arrays in example sets using continuous data.
;;;
define check_2d_array(accessor, arrayfn, eg_rec, n_units);
lvars accessor eg_rec array arrayfn n_units n_egs;

	accessor(eg_rec) -> array;
	if array then
		if length(boundslist(array)) /== 4 then
			convert_to_2d(array, arrayfn,
					eg_out_units(eg_rec), n_units) -> accessor(eg_rec);
		endif;
	else
		;;; nothing there so just create one
		check_array_size(array, n_units, eg_examples(eg_rec), arrayfn)
			-> accessor(eg_rec);
	endif;
	boundslist(accessor(eg_rec))(4) -> eg_examples(eg_rec);
enddefine;

#_ENDIF


/* ----------------------------------------------------------------- *
    Main Functions
 * ----------------------------------------------------------------- */

;;; core_parse_example takes an example, a template and the input
;;; and target vector for this example and parses the data according to
;;; template. The invec and targvec are altered accordingly with data
;;; supplied by the conversion functions held in nn_datatypes. If
;;; the return_examples_p flag is true then the high-level data
;;; used for input and output are returned, otherwise the procedure
;;; returns two false values.
;;;
;;; It is possible to supply a list of datatypes only. In this case
;;; the direction is assumed to be input and it is also assumed that
;;; only the input vector has been supplied (or rather, because the
;;; data is assumed to be input, the target vector will not be
;;; accessed during parsing).
;;;
define global core_parse_example(example, template,
				invec, targvec, return_examples_p) -> in_eg -> targ_eg;
lvars example template invec targvec return_examples_p item type
      direction type_entry stack_len ex_index = 1, in_index = 1,
      targ_index = 1, in_eg = false, targ_eg = false;

    ;;; generate_raw_data takes a simple datatype and a direction
    ;;; All the other data required for conversion are assumed to
    ;;; have been left on the stack.
    ;;;
    define lconstant generate_raw_data(dtype, direction);
    lvars num dtype direction n_results num;

		get_dt_record(dtype) -> dtype;

        unless is_simple_dt(dtype) then
            mishap(dtype, 1, 'Simple datatype required');
        endunless;

        ;;; how many results are we expecting
        nn_units_needed(dtype) -> n_results;

        apply(nn_dt_inconv(dtype));    ;;; leave results on the stack

        ;;; Transfer the results into the input or target vector.
        ;;; Because the order has been reversed, we need to insert
        ;;; the values into the vector/array in reverse order. Note
        ;;; that because in_index and targ_index point to the next free
        ;;; slot in the vector, counting has to go from n_results - 1 to 0.
        ;;;
        if isinputfield(direction) then
            fast_for num from 0 to (n_results fi_- 1) do
                -> invec(in_index fi_+ num);
            endfast_for;
            n_results fi_+ in_index -> in_index;

        elseif isoutputfield(direction) then
			if targvec then
            	fast_for num from 0 to (n_results fi_- 1) do
                	-> targvec(targ_index fi_+ num);
            	endfast_for;
			else
				erasenum(n_results);
			endif;
            n_results fi_+ targ_index -> targ_index;

        elseif isbothfield(direction) then
            fast_for num from 0 to (n_results fi_- 1) do
				;;; need to check that targvec has been passed
				if targvec then
                	->> targvec(targ_index fi_+ num);
				endif;
                -> invec(in_index fi_+ num);
            endfast_for;
            n_results fi_+ targ_index -> targ_index;
            n_results fi_+ in_index -> in_index;

        elseif isnonefield(direction) then
            erasenum(n_results);    ;;; might have items left on stack

        else
            mishap(direction, 1,
		        'Illegal direction - "in", "out", "both" or "none" expected');
        endif;
    enddefine;


    ;;; try_item takes a single item (which may be false). If
    ;;; item is non-false then the current item in the
    ;;; example list is checked against item (which may also be a list
    ;;; of valid items). If the current item is the same as item or
    ;;; a member of the list of items then the index is incremented
    ;;; and the item is returned, otherwise false is returned.
	;;;
    define try_item(item) -> curr_item;
    lvars item curr_item;
        example(ex_index) -> curr_item;
        if item then
            if curr_item = item or
              (islist(item) and member(curr_item, item)) then
                ex_index fi_+ 1 -> ex_index;
            else
                false -> curr_item;
            endif;
        endif;
    enddefine;


    ;;; need_item takes a single item (which may be false). If
    ;;; item is non-false then the current item in the
    ;;; example list is checked against item (which may also be a list
    ;;; of valid items). If the current item is the same as item or
    ;;; a member of the list of items then the index is incremented
    ;;; and the item is returned otherwise an error is signalled.
    ;;;
    define need_item(item) -> curr_item;
    lvars item curr_item;
        example(ex_index) -> curr_item;
        if item then
            if curr_item = item or
              (islist(item) and member(curr_item, item)) then
                ex_index fi_+ 1 -> ex_index;
            else
                mishap(0, sprintf(item, example(ex_index),
                        'Parsing example - found %p, expecting %p'));
            endif;
        endif;
    enddefine;


    ;;; store_example_field takes a direction and a list of the
    ;;; converted data and attaches the list to one or both
    ;;; of the input or target example lists. This procedure
    ;;; is only called if the return_examples_p flag is true.
    ;;; It copies the top-level items in the list so that the
    ;;; original list can be garbaged when the procedure returns.
    ;;;
    define store_example_field(direction, data_list);
    lvars list_item direction data_list;

        for list_item in data_list do
            if isinputfield(direction) then
                list_item :: in_eg -> in_eg;
            elseif isoutputfield(direction) then
                list_item :: targ_eg -> targ_eg;
            elseif isbothfield(direction) then
                list_item :: in_eg -> in_eg;
                list_item :: targ_eg -> targ_eg;
            endif;
        endfor;
    enddefine;


    ;;; convert_to_raw_data takes the current type entry and
    ;;; parses the data into the required format for the converter
    ;;; functions.
    ;;;
    define lconstant convert_to_raw_data(type_entry, direction);
    lvars type_entry direction n_items n_types = 0, starter ender separator
          dt_names dt_name set_members seq seq_item temp_list;

        if is_simple_dt(type_entry) then
            nn_items_needed(type_entry) -> n_items;
            [% repeat n_items times
                example(ex_index);
                ex_index fi_+ 1 -> ex_index;
            endrepeat %] -> temp_list;
            if return_examples_p then
                store_example_field(direction, temp_list);
            endif;
			;;; dump the items on the stack (order doesn't matter for
			;;; simple datatypes)
            dl(temp_list);
            sys_grbg_list(temp_list);
            generate_raw_data(type_entry, direction);

        elseif is_choice_field_dt(type_entry) then
            nn_items_needed(type_entry) -> n_items;
            nn_dt_field_choiceset(type_entry) -> dt_name;
            nn_dt_setmembers(dt_name) -> set_members;
            nn_dt_field_ender(type_entry) -> ender;
            nn_dt_field_separator(type_entry) -> separator;

            ;;; check that any starter item is valid
            erase(need_item(nn_dt_field_starter(type_entry)));

            ;;; if we have an ender then this must be the terminating
            ;;; condition
            if ender then
                [%  until try_item(ender) do
                        need_item(set_members);
                        erase(try_item(separator));     ;;; ignore separators
                    enduntil %];

            ;;; otherwise the terminating condition is not having a
            ;;; separator. Note that in this case it is an error to
            ;;; have no set items present.
            else
                unless separator then
                    mishap(0, 'Choice field has no ender or separator');
                endunless;
                [%  repeat forever
                        need_item(set_members);
                        unless try_item(separator) then
                            quitloop();
                        endunless;
                    endrepeat %];
            endif -> temp_list;

            if return_examples_p then
                ;;; because this really IS a list then to store it we
                ;;; have to embed it in another list.
                store_example_field(direction, temp_list :: []);
            endif;

			;;; leave set list on the stack
            generate_raw_data(temp_list, dt_name, direction);
			unless return_examples_p then
                sys_grbg_list(temp_list);
			endunless;

        elseif is_seq_field_dt(type_entry) then
            ;;; sequences are slightly more tricky since they can
            ;;; contain non-simple datatypes. This means processing has
            ;;; to be done in a loop
			;;;
            nn_dt_field_sequence(type_entry) -> seq;
            until seq == [] do
                dest(seq) -> seq -> seq_item;
                if seq_item == "\" then     ;;; datatype next
                    dest(seq) -> seq -> seq_item;
                    ;;; call recursively
                    convert_to_raw_data(seq_item, direction);
                else
                    if seq_item == "\\" then    ;;; an escaped "\"
                        "\" -> seq_item;
                    endif;
                    erase(need_item(seq_item));
                endif;
            enduntil;

        elseif is_file_dt(type_entry) then
		    ;;; If we've been passed a file datatype then extract
			;;; the "real" datatypes associated with it.
			;;;
		    if is_char_file_dt(type_entry) or is_item_file_dt(type_entry) then
			    nn_dt_file_datatypes(type_entry) -> dt_names;
			    if isword(dt_names) then
				    convert_to_raw_data(dt_names, direction);
			    else
				    for dt_name in dt_names do
					    convert_to_raw_data(dt_name, direction);
				    endfor;
			    endif;

		    elseif is_line_file_dt(type_entry) or is_full_file_dt(type_entry) then
			    ;;; use the general datatype
			    nn_dt_file_recipient(type_entry) -> dt_name;

			    convert_to_raw_data(dt_name, direction);

		    endif;
        else
            mishap(type_entry, 1, 'Unknown datatype');
        endif;
    enddefine;

    ;;; if we are returning the examples then set up some hooks for
    ;;; the convert_to_raw_data procedure to hang the semi-converted
    ;;; data to.
    if return_examples_p then
        [] ->> in_eg -> targ_eg;
    endif;

    ;;; go through the example set template and convert the data
    ;;;
    for item in template do
        if islist(item) then                ;;; apply the conversion
                                            ;;; function to the data
            nn_template_type(item) -> type;
            nn_template_io(item) -> direction;
            nn_datatypes(type) -> type_entry;
		else
			;;; if we're simply passed a list of datatypes then assume
			;;; we have been supplied with the input vector
			item -> type;
			"in" -> direction;
			nn_datatypes(type) -> type_entry;
		endif;

        stacklength() -> stack_len;
        convert_to_raw_data(type_entry, direction);
        if stacklength() /== stack_len then
            mishap(item, 1,
                    'User stack has changed during field conversion');
        endif;
    endfor;

    if return_examples_p then
        ncrev(in_eg) -> in_eg;
        ncrev(targ_eg) -> targ_eg;
    endif;
enddefine;


;;; core_unparse_output takes an output vector (or array closures, whatever)
;;; a template (which may be a proper template with field names
;;; and directions etc. or a list of datatypes) and a flag which defines
;;; whether each datatype should be returned in its own sublist or
;;; all results returned in a single list. If it's a list of datatypes
;;; then it is assumed that datatypes are output.
;;;
define global core_unparse_output(outvec, template, listify_p) -> example;
lvars example template listify_p outvec return_examples_p item type
      direction type_entry stack_len ex_index = 1,
      out_index = 1, out_eg = false;

    ;;; extract_simple_data takes a simple datatype and a direction
    ;;; All the other data required for conversion are assumed to
    ;;; have been left on the stack.
    ;;;
    define lconstant extract_simple_data(dtype, direction);
    lvars num dtype direction n_units;

		get_dt_record(dtype) -> dtype;
        unless is_simple_dt(dtype) then
            mishap(dtype, 1, 'Simple datatype required');
        endunless;

        ;;; how many data values are we expecting
        nn_units_needed(dtype) -> n_units;

        ;;; Put the results from the output vector onto the stack.
        ;;;
        if isoutputfield(direction) or isbothfield(direction) then
            fast_for num from 0 to (n_units fi_- 1) do
                outvec(out_index fi_+ num);
            endfast_for;
            n_units fi_+ out_index -> out_index;
        	apply(nn_dt_outconv(dtype));    ;;; leave results on the stack

        elseif isinputfield(direction) or isnonefield(direction) then
            ;;; do nothing

        else
            mishap(direction, 1,
		        'Illegal direction - "in", "out", "both" or "none" expected');
        endif;
    enddefine;


	;;; convert_from_raw_data takes a datatye record or name and a
	;;; direction and calls itself until the datatype is either a
	;;; simple type or a "line" or "file" type. At this point, it calls
	;;; extract_simple_data which leaves its results on the stack.
	;;;
	define lconstant convert_from_raw_data(dt_rec, direction);
	lvars dt_rec direction dt_name dt_names temp_list
		  rest_list item starter ender separator seq seq_item;

		if isoutputfield(direction) or isbothfield(direction) then
            if is_simple_dt(dt_rec) then
			    extract_simple_data(dt_rec, direction);

            elseif is_choice_field_dt(dt_rec) then
                nn_dt_field_choiceset(dt_rec) -> dt_name;
			    ;;; sets always return 1 item
			    extract_simple_data(dt_name, direction) -> temp_list;

                nn_dt_field_starter(dt_rec) -> starter;
                nn_dt_field_ender(dt_rec) -> ender;
                nn_dt_field_separator(dt_rec) -> separator;

			    unless islist(temp_list) then
				    temp_list :: [] -> temp_list;
			    endunless;

			    temp_list -> rest_list;

			    ;;; now leave the appropriate starter, ender and
			    ;;; example set items on the stack
			    if starter then starter; endif;
			    repeat length(rest_list) - 1 times
				    dest(rest_list) -> rest_list -> item;
				    item;
				    if separator then separator; endif;
			    endrepeat;

				unless null(rest_list) then
			    	hd(rest_list);
				endunless;

			    if ender then ender; endif;

            elseif is_seq_field_dt(dt_rec) then
                ;;; sequences are slightly more tricky since they can
                ;;; contain non-simple datatypes. This means processing has
                ;;; to be done in a loop
				;;;
                nn_dt_field_sequence(dt_rec) -> seq;
                until seq == [] do
                    dest(seq) -> seq -> seq_item;
                    if seq_item == "\" then     ;;; datatype next
                        dest(seq) -> seq -> seq_item;
                        ;;; call recursively
                        convert_from_raw_data(seq_item, direction);
                    else
                        if seq_item == "\\" then    ;;; an escaped "\"
                            "\" -> seq_item;

						elseif islist(seq_item) then
							;;; we have a list of alternatives which are
							;;; valid items at this point. In this case
							;;; take the first item in the list.
							;;;
							hd(seq_item) -> seq_item;
                        endif;

						;;; leave the result on the stack
                        seq_item;
                    endif;
                enduntil;

            elseif is_file_dt(dt_rec) then

			    ;;; If we've been passed a file datatype then extract
				;;; the "real" datatypes associated with it and use
				;;; those instead since at this stage we won't know
				;;; which devices to send the results to.
				;;;
			    if is_char_file_dt(dt_rec) or is_item_file_dt(dt_rec) then
				    nn_dt_file_datatypes(dt_rec) -> dt_names;
				    if isword(dt_names) then
					    convert_from_raw_data(dt_names, direction);
				    else
					    for dt_name in dt_names do
						    convert_from_raw_data(dt_name, direction);
					    endfor;
				    endif;

			    elseif is_line_file_dt(dt_rec) or is_full_file_dt(dt_rec) then
				    ;;; use the general datatype
				    nn_dt_file_recipient(dt_rec) -> dt_name;

				    ;;; the recipient datatype should be a "general" type
					;;; and the result should be a byte-structure so we can
				    ;;; call extract_simple_data directly
				    extract_simple_data(dt_name, direction);

			    endif;
		    else
                mishap(dt_rec, 1, 'Unknown datatype');
            endif;
		endif;
	enddefine;


    ;;; go through the example set template and convert the data
    ;;;
	[% for item in template do
        if islist(item) then                ;;; apply the conversion
                                            ;;; function to the data
            nn_template_type(item) -> type;
            nn_template_io(item) -> direction;
            nn_datatypes(type) -> type_entry;
		else
			;;; if we have been passed a list of types then assume
			;;; we have been supplied with the output vector
			item -> type;
			"out" -> direction;
			nn_datatypes(type) -> type_entry;
		endif;

		unless isinputfield(direction) or isnonefield(direction) then
			if listify_p then
				;;; for output to be sent to a number of files, return
				;;; the data as lists of lists
        		[% convert_from_raw_data(type_entry, direction); %];
			else
        		convert_from_raw_data(type_entry, direction);
			endif;
		endunless;
    endfor %] -> example;
enddefine;


;;; nn_parse_example takes a template and a "high-level" data list
;;; and converts the input to a vector suitable for presentation
;;; to a neural network
define global nn_parse_example(example, template, vector);
lvars template example type type_entry index = 1;

	Check_vectorclass(vector, false);

	;;; ensure no results are returned. Because all items are "defined"
	;;; as input, don't need to supply a target vector
	;;;
	erasenum(core_parse_example(example, template, vector, false, false), 2);
enddefine;


;;; nn_unparse_example takes a template and a vector from the output
;;; nodes of a network and converts it into a list of "high-level" data
define global nn_unparse_example(vector, template) -> example;
lvars vector template listify_p = false, example;

	if isboolean(template) then
		;;; define whether each datatype should be returned
		;;; in its own list
		vector, template -> listify_p -> template -> vector;
	endif;

	Check_vectorclass(vector, false);
	core_unparse_output(vector, template, listify_p) -> example;
enddefine;


;;; nn_make_egs creates an example set with the given name, template
;;; and data generator. Name must be a word, template must be a list
;;; and the data generator must be a list of lists, a vector of vectors or
;;; an array.
;;;
;;; nn_make_egs("complete",
;;; 			[[in boolean in1] [out boolean out1]],
;;; 			EG_FILE, 'test*.dat',
;;; 			EG_FILE, 'output*.dat',
;;; 			eg_default_flags);
;;;
;;; nn_make_egs("complete",
;;; 			[[in boolean in1] [out boolean out1]],
;;; 			EG_FILE, 'test*.dat',
;;; 			EG_LITERAL, false,
;;; 			eg_default_flags);
;;;
;;; nn_make_egs("complete",
;;; 			[[in boolean in1] [out boolean out1]],
;;; 			EG_FILE, 'test*.dat',
;;; 			EG_PROC, myproc,
;;; 			eg_default_flags);
;;;
define global nn_make_egs(name, template, data_source);
lvars eg_rec = consnn_egs(EG_DEFAULTS, 1, false, false, false, false, false,
			false, false, false, [], [], false, false, false, false, [], [],
			false, false, false, false, false, 0, {}, false);
lvars name template data_source data_destination = false,
	  flags = false, data_generator = false, dest_data = false, examples,
	  in_nodes, out_nodes, index, type;

	if isinteger(data_source) then
		;;; passed some flags so re-order args
		data_source -> flags;
		template -> dest_data;
		name -> data_destination;
		-> data_generator; -> data_source; -> template; -> name;
	endif;

	name -> eg_name(eg_rec);
	eg_rec -> nn_example_sets(name);
	template -> eg_template(eg_rec);

	unless isword(name) then
		mishap(name, 1, 'Example set name must be a word');
	endunless;

	;;; First check the data_source (if passed) and make sure the data_generator
	;;; is consistent with it. If no data_source was passed then use the
	;;; simple way of creating a generator function.
	;;;
	if flags then		;;; process data inputs and args

#_IF DEF NEURAL_CONTINUOUSDATA

#_ELSE		/* Discrete data only */

		;;; make sure discrete and in_lines flags are set and use_in_lines is
		;;; unset
		flags || EG_DISCRETE || EG_INLINES &&~~ EG_USE_INLINES -> flags;
#_ENDIF

		if egs_from_file(data_source) then
			;;; data_generator should be a filename or a list of filenames
			unless isstring(data_generator) or islist(data_generator) then
				mishap(data_generator, 1, 'Filename string(s) needed');
			endunless;
			if isstring(data_generator) then
				[^data_generator]
			else
				data_generator
			endif -> eg_gen_params(eg_rec);

		elseif egs_from_proc(data_source) then
			;;; data_generator should be a procedure
			unless isprocedure(data_generator) then
				mishap(data_generator, 1, 'Procedure needed');
			endunless;
			data_generator -> eg_gen_params(eg_rec);

		elseif egs_from_egs(data_source) then
			;;; data_generator should be an example set name
			unless isword(data_generator) then
				mishap(data_generator, 1, 'Example set name needed');
			endunless;
			data_generator -> eg_gen_params(eg_rec);

		elseif egs_from_literal(data_source) then
			;;; data_generator should be a list, vectorclass or array
			if data_generator and
			  not(islist(data_generator) or isvectorclass(data_generator)
			  or isarray(data_generator)) then
				mishap(data_generator, 1, 'List, vector or array needed');
			endif;
			data_generator -> eg_gen_params(eg_rec);

		else
			mishap(data_source, 1, 'Unknown data source flag');
		endif;

		;;; Now check the data destination information. This is
		;;; required to tell the output converter function where
		;;; to store the converted data.
		;;;
		if egs_to_file(data_destination) then
			;;; dest_data should be a filename or a list of filenames
			unless isstring(dest_data) or islist(dest_data) then
				mishap(dest_data, 1, 'Filename string(s) needed');
			endunless;
			if isstring(dest_data) then
				[^dest_data]
			else
				dest_data
			endif -> eg_apply_params(eg_rec);

		elseif egs_to_proc(data_destination) then
			;;; dest_data should be a procedure
			unless isprocedure(dest_data) then
				mishap(dest_data, 1, 'Procedure needed');
			endunless;
			dest_data -> eg_apply_params(eg_rec);

		elseif egs_to_egs(data_destination) then
			;;; dest_data should be a word
			unless isword(dest_data) then
				mishap(dest_data, 1, 'Example set name needed');
			endunless;
			dest_data -> eg_apply_params(eg_rec);

		elseif egs_to_literal(data_destination) then
			;;; dest_data can be ignored
			dest_data -> eg_apply_params(eg_rec);

		else
			mishap(data_destination, 1, 'Unknown data destination flag');
		endif;

		flags -> eg_flags(eg_rec);
		data_source -> eg_data_source(eg_rec);
		data_destination -> eg_data_destination(eg_rec);

	else	;;; the simple (original) arguments
		EG_PROC -> eg_data_source(eg_rec);
		EG_LITERAL -> eg_data_destination(eg_rec);
		EG_DEFAULTS -> eg_flags(eg_rec);

	    ;;; check what the datasource is and set the eg_gen_params and
	    ;;; eg_data_source slots appropriately
        if isprocedure(data_source) then
            data_source -> eg_gen_params(eg_rec);
        elseif islist(data_source)
               or isarray(data_source)
               or isvector(data_source) then
            identfn(%data_source%) -> eg_gen_params(eg_rec);
            data_source -> eg_gendata(eg_rec);
        else
            mishap(data_source, 1,
					'Data source must be a list or a procedure')
        endif;
	endif;

	if islist(template) then

		;;; standard template
        unless islist(template) then
	        mishap(template, 1, 'Example template must be a list');
        endunless;

        unless length(template) > 0 then
	        mishap(template, 1, 'Example template must have at least 1 field');
        endunless;

        ;;; parse the template into input and output components
        parse_template(template) -> eg_in_template(eg_rec)
                                 -> eg_out_template(eg_rec)
                                 -> eg_in_names(eg_rec)
                                 -> eg_out_names(eg_rec);
	endif;

	if not(eg_in_template(eg_rec)) then
		true -> eg_rawdata_in(eg_rec);
	endif;

	if not(eg_out_template(eg_rec)) then
		true -> eg_rawdata_out(eg_rec);
	endif;

	if eg_rawdata_in(eg_rec) then
		false ->> eg_in_template(eg_rec) -> eg_in_names(eg_rec);
	endif;

	if eg_rawdata_out(eg_rec) then
		false ->> eg_out_template(eg_rec) -> eg_out_names(eg_rec);
	endif;

	set_egs_units_needed(eg_rec);
    eg_rec -> nn_example_sets(name);
    name -> nn_current_egs;
enddefine;


/* ----------------------------------------------------------------- *
    Generate Functions
 * ----------------------------------------------------------------- */

;;; parse_discrete_lists takes a static datastructure (a list of lists,
;;; a vector of vectors or an array, an example set and an arrayfn. It
;;; sets up the raw data arrays before parsing the static data structure.
;;; If the example set has the "keep examples" flag set then two lists of
;;; lists containing the basic data (unconverted but without any of
;;; the separators or extra bits and pieces) is returned (one list for
;;; input data, the other with target data).
;;;
define parse_discrete_lists(all_examples, eg_rec, arrayfn)
							-> inp_examples -> targ_examples
							-> inp_array -> targ_array -> n_examples;
lvars eg_rec arrayfn inp_examples = false, targ_examples = false,
		inp_array targ_array targ_closure = false,
		n_examples all_examples index template ininfo, targinfo,
		return_examples_p;

	;;; officially the return result should be a list of lists
	;;; although we will permit a vector of vectors or a 2-D array
	if islist(all_examples) or isvectorclass(all_examples) then
		length(all_examples)
	elseif isarray(all_examples) then
		boundslist(all_examples)(4)
	endif -> n_examples;

	setup_raw_data_arrays(eg_rec, arrayfn, n_examples)
			-> inp_array -> targ_array;

	eg_keep_egs(eg_rec) -> return_examples_p;
	eg_template(eg_rec) -> template;

	;;; if we only need to parse input examples then ensure that
	;;; any output datatypes have been removed from the template
	;;;
	unless eg_gen_output(eg_rec) then
		extract_input_fields(template) -> template;
	endunless;

	if return_examples_p then
		[] ->> inp_examples -> targ_examples;
	endif;

    ;;; given the template and examples,
    ;;; convert the high-level examples into raw net data
    ;;; and put the info into the input arrays
    if islist(all_examples) or isvector(all_examples) then
        fast_for index from 1 to n_examples do
			if targ_array then
				targ_array(%index%) -> targ_closure;
			endif;
            core_parse_example(
					all_examples(index), template,
                    inp_array(%index%), targ_closure,
					return_examples_p) -> ininfo -> targinfo;

			if return_examples_p then
				ininfo :: inp_examples -> inp_examples;
				if targinfo then
					targinfo :: targ_examples -> targ_examples;
				endif;
			endif;
        endfast_for;

    elseif isarray(all_examples) then
        fast_for index from 1 to n_examples do
			if targ_array then
				targ_array(%index%) -> targ_closure;
			endif;
            core_parse_example(all_examples(%index%), template,
                    inp_array(%index%), targ_closure,
					return_examples_p) -> ininfo -> targinfo;

			if return_examples_p then
				ininfo :: inp_examples -> inp_examples;
				if targinfo then
					targinfo :: targ_examples -> targ_examples;
				endif;
			endif;
        endfast_for;
    else
        mishap(dataword(all_examples), 1,
		       'Illegal structure returned by generator function');
    endif;

	if return_examples_p then
		ncrev(inp_examples) -> inp_examples;
		ncrev(targ_examples) -> targ_examples;
	endif;
enddefine;



#_IF DEF NEURAL_CONTINUOUSDATA
;;; core_parse_seq takes a list of sequences and a list of
;;; types and returns an array of raw data suitable for the neural net
define core_parse_seq(seqs, types, arrayfn) -> data_array -> n_seqs;
lvars seqs types arrayfn data_array n_types descriptors index array_size
		array_ptr a_ptr desc_entry seq_index n_seqs n_items n_results
		current_sequence converter;

	;;; To speed things up, create a cache for the index, number
	;;; of items needed and number of results returned for each
	;;; data sequence type. For each datatype, the cache is
	;;; a vector of 4 items: the index, items needed, results returned
	;;;	and the converter function. Note that the datatype has to be a
	;;; simple type.
	;;;
	initv(length(types) ->> n_types) -> descriptors;
	for index from 1 to n_types do
		consvector(1, nn_items_needed(types(index)),
					nn_units_needed(types(index)),
					nn_dt_inconv(nn_datatypes(types(index))),
					4) -> subscrv(index, descriptors);
	endfor;

	;;; Setup the raw sequence array. The length of this is calculated
	;;; using the first sequence. The calculation is:
	;;;
	;;;		(items supplied/items needed) * values returned
	;;;
	;;; where (items supplied/items needed) also gives the number of
	;;; iterations through each sequence that has to be made to parse
	;;; the whole sequence
	;;;
	length(hd(seqs))/ descriptors(1)(2) -> n_seqs;

	n_seqs * descriptors(1)(3) -> array_size;

	arrayfn([1 ^array_size], 0.0s0) -> data_array;

	1 -> array_ptr;

	repeat n_seqs times
	    fast_for index from 1 to n_types do
			seqs(index) -> current_sequence;
			fast_subscrv(index, descriptors) -> desc_entry;
			explode(desc_entry) -> converter -> n_results -> n_items -> seq_index;

			;;; Leave the required number of items on the stack....
			repeat n_items times
				current_sequence(seq_index);
				seq_index fi_+ 1 -> seq_index;
			endrepeat;

			;;; ...save the index in the descriptors...
			seq_index -> fast_subscrv(1, desc_entry);

			;;; ...call the converter...
		    apply(converter);

			;;; ...and save the return values
			fast_for a_ptr from 0 to (n_results - 1) do
				-> data_array(array_ptr fi_+ a_ptr);
			endfast_for;
			array_ptr fi_+ n_results -> array_ptr;
	    endfast_for;
	endrepeat;
enddefine;


;;; parse_continuous_lists takes all the examples and returns
;;; appropriate structures for input and target examples and
;;; input and target array functions. It is assumed that each
;;; row of the structure contains the complete sequence for
;;; a given row or column.
;;;
define parse_continuous_lists(all_examples, eg_rec, template, in_types,
		out_types, arrayfn) -> inp_examples -> targ_examples
							-> inp_array -> targ_array -> n_examples;
lvars eg_rec arrayfn inp_array = false, targ_array = false,
		all_examples index template in_types out_types
		inp_examples = [], targ_examples = [],
		type item direction template_entry e_index index;

	1 -> e_index;

	;;; first split the examples into input and output examples
	;;;
	for template_entry in template do
		nn_template_type(template_entry) -> type;
		nn_template_io(template_entry) -> direction;
		if isinputfield(direction) then
			all_examples(e_index) :: inp_examples -> inp_examples;
			e_index fi_+ 1 -> e_index;

		elseif isoutputfield(direction) then
			all_examples(e_index) :: targ_examples -> targ_examples;
			e_index fi_+ 1 -> e_index;

		elseif isbothfield(direction) then
			all_examples(e_index) :: inp_examples -> inp_examples;
			all_examples(e_index) :: targ_examples -> targ_examples;
			e_index fi_+ 1 -> e_index;

		endif;
	endfor;

	ncrev(inp_examples) -> inp_examples;
	ncrev(targ_examples) -> targ_examples;

	;;; what we should have here is a list of input sequences and
	;;; a list of output sequences which should be the same size
	;;; as the number of input and output sequnces defined for the
	;;; example set. Check that this is the case....
	;;;
	unless in_types and length(inp_examples) == length(in_types) then
		mishap(0, sprintf(length(inp_examples), length(in_types),
				'Incorrect no. of input sequences: expecting %p, found %p'));
	endunless;

	unless out_types and length(targ_examples) == length(out_types) then
		mishap(0, sprintf(length(targ_examples), length(out_types),
				'Incorrect no. of output sequences: expecting %p, found %p'));
	endunless;

	;;; Now parse the examples into the appropriate input/output array.
	if in_types then
		core_parse_seq(inp_examples, in_types, arrayfn)
				-> inp_array -> n_examples;
	endif;
	if out_types then
		core_parse_seq(targ_examples, out_types, arrayfn)
				-> targ_array -> n_examples;
	endif;
enddefine;
#_ENDIF


;;; nn_remove_filetypes takes a standard example set template
;;; (which should contain nothing except file datatypes) and returns
;;; a list of the datatypes used by that filetype. This is then passed
;;; as the argument to the example list parser. Use lists here so that
;;; we can garbage collect them when we've finished with them. Note that
;;; if a simple list of filetypes is passed in then a simple list of
;;; non-filetypes is returned, otherwise (for a normal template type)
;;; a list of lists containing both the direction and the datatype
;;; is returned.
;;;
define global nn_remove_filetypes(template) -> type_template;
lvars template entry subtypes subentry type_template;

	[% for entry in template do
		;;; check the entry's datatype format
		if islist(entry) then
			;;; we need to extract the type items and direction
		    if (nn_datatypes(nn_template_type(entry)) ->> subtypes) then

		        if isword(nn_dt_format(subtypes) ->> subtypes) then
			        [% nn_template_io(entry), subtypes %]
		        else		;;; should be a list of datatypes
			        for subentry in subtypes do
				        [% nn_template_io(entry), subentry %]
			        endfor;
		        endif;
		    else
			    mishap(nn_template_type(entry), 1,
					    'Unknown datatype in filetype declaration');
		    endif;
		else
			;;; assume a list of datatypes
		    if (nn_datatypes(entry) ->> subtypes) then

		        if isword(nn_dt_format(subtypes) ->> subtypes) then
			        subtypes;
		        else		;;; should be a list of datatypes
			        for subentry in subtypes do
				       	subentry;
			        endfor;
		        endif;
		    else
			    mishap(entry, 1, 'Unknown datatype in filetype declaration');
		    endif;
		endif;
	  endfor;
	%] -> type_template;
enddefine;


;;; get_examplefile_attributes takes a datatype record and
;;; returns appropriate
;;;
define get_examplefile_attributes(ftype)
				-> org -> struct_or_proc -> eol_marker -> popnewline_p;
;;; in_itemiser def is taken from -nn_declare_file_format-
lconstant in_itemiser = discin <> incharitem;
lvars ftype struct_or_proc org eol_marker popnewline_p;

	get_dt_record(ftype) -> ftype;
	if is_char_file_dt(ftype) then
		false, nn_dt_inconv(ftype), `\n`, false,
	elseif is_item_file_dt(ftype) then
		false, nn_dt_inconv(ftype), newline, true,
	elseif is_line_file_dt(ftype) then
		"line", nn_dt_inconv(ftype), `\n`, false,
	elseif is_full_file_dt(ftype) then
		true, nn_dt_inconv(ftype), false, false
	else
		;;; otherwise assume that we have a single file of items
		false, in_itemiser, newline, true
	endif -> popnewline_p -> eol_marker -> struct_or_proc -> org;
enddefine;


define get_outputfile_attributes(ftype)
				-> org -> struct_or_proc -> gap -> eol_marker;
;;; out_itemiser def is taken from -nn_declare_file_format-
lconstant out_itemiser = discout <> outcharitem;
lvars ftype struct_or_proc gap org eol_marker;

	get_dt_record(ftype) -> ftype;
	if is_char_file_dt(ftype) then
		false, nn_dt_outconv(ftype), false, `\n`,
	elseif is_item_file_dt(ftype) then
		false, nn_dt_outconv(ftype), space, newline,
	elseif is_line_file_dt(ftype) then
		"line", nn_dt_outconv(ftype), false, `\n`,
	elseif is_full_file_dt(ftype) then
		true, nn_dt_outconv(ftype), false, false,
	else
		;;; otherwise assume that we have a single file of items
		false, out_itemiser, space, newline
	endif -> eol_marker -> gap -> struct_or_proc -> org;
enddefine;

define raw_read(dev, struct, len) -> struct;
lvars dev struct len;
	erase(sysread(dev, struct, len));
enddefine;

define raw_write(struct, dev);
lvars dev struct len = length(struct);
	syswrite(dev, struct, len);
	sysflush(dev);
enddefine;


;;; open_example_file takes a filename, a flag which defines whether the
;;; repeater should return the whole file or not, the argument for file
;;; organisation to -sysopen-, the end of line marker and a flag which
;;; is used to set/unset popnewline. It returns
;;; the raw device and a procedure (which is a character or
;;; item repeater or a procedure to read n bytes from the file). If the
;;; the call to sysopen returns false for some reason then the repeater
;;; arg is also false. Note the file is opened read-only.
;;;
define open_example_file(filename, file_p, org, apply_proc, eol_mark, popnewline_p)
									-> dev -> file_repeater;
lvars filename file_p dev file_repeater apply_proc org;
lvars repeater eol_mark popnewline_p;

	define cons_txtline_repeater(repeater, eol_mark, popnewline_p);
	dlocal popnewline = popnewline_p;
	lvars repeater eol_mark popnewline_p item;

		;;; simply leave the items on the stack since this should always
		;;; be called from within decorated list/vector brackets
		while (repeater() ->> item) /== termin and item /= eol_mark do
			item;
		endwhile;
	enddefine;

	define cons_txtfile_repeater(repeater, eol_mark, popnewline_p);
	dlocal popnewline = popnewline_p;
	lvars repeater eol_mark popnewline_p item;

		;;; simply leave the items on the stack since this should always
		;;; be called from within decorated list/vector brackets
		while (repeater() ->> item) /== termin do
			unless eol_mark and item = eol_mark then
				item;
			endunless;
		endwhile;
	enddefine;

    if (sysopen(filename, 0, org, `A`) ->> dev) then
		if isprocedure(apply_proc) then
			if file_p then
				;;; either return something which will read a file at a time
				cons_txtfile_repeater(%apply_proc(dev), eol_mark, popnewline_p%)
			else
				;;; or something which will read a line at a time
				cons_txtline_repeater(%apply_proc(dev), eol_mark, popnewline_p%)
			endif;
		elseif isvectorclass(apply_proc) then
			raw_read(%dev, apply_proc, length(apply_proc)%)
		else
			mishap(apply_proc, 1, 'invalid proc/structure for example reader');
		endif
	else
		mishap(filename, 1, 'Unable to open example file');
	endif -> file_repeater;
enddefine;


;;; setup_examplefile_descriptors takes a template and the list of files
;;; and sets up the vector of file descriptors. These either contain
;;; a pair where the front is the repeater and the back is the raw
;;; device or a vector containing a list of filenames, the ORG
;;; argument for -sysopen-, the structure (for "line" and "file" types)
;;; or the repeater (for "char" or "item" files), the end-of-line marker
;;; and the value for -popnewline- (these last two are only used
;;; by "char" and "item" types).
;;;
define setup_examplefile_descriptors(template, files_list) -> file_descriptors;
lvars template files_list file_descriptors index n_filefields
	ftype newpair org struct_or_proc eol_marker popnewline_p;

	;;; how many separate sets of files are there ?
	initv(length(files_list) ->> n_filefields) -> file_descriptors;

	;;; for each set of files:
	;;;		a) check the datatype specified and if appropriate set the
	;;; 	required flags,
	;;;
	;;;		b) if the number of files in the current field is 1 then open
	;;;		the file.
	;;;
	;;;		If filenames are in a list then store the information
	;;; 	found in (a) in structure associated with the file list.
	;;;		Otherwise open the file to be read a line at a time.
	;;;
	fast_for index from 1 to n_filefields do
		template(index) -> ftype;
		if islist(ftype) then		;;;	have direction and fieldname info
			nn_datatypes(nn_template_type(ftype))
		else
			nn_datatypes(ftype)
		endif -> ftype;

		if ftype then
			get_examplefile_attributes(ftype) -> org -> struct_or_proc
								-> eol_marker -> popnewline_p;

			if isstring(files_list(index)) and org /== true then

				;;; if we only have one filename and the data type isn't a
				;;; filetype then open it immediately as a line repeater
				;;;
				conspair(false,false) -> newpair;
				open_example_file(files_list(index), false,
							org, struct_or_proc, eol_marker, popnewline_p)
					-> back(newpair) -> front(newpair);
				newpair;

			else
				consvector(files_list(index), org, struct_or_proc,
							eol_marker, popnewline_p, 5);
			endif -> subscrv(index, file_descriptors);
		else
			mishap(ftype, 1, 'Unknown datatype in file description');
		endif;
	endfast_for;
enddefine;

;;; close_file_devices ensures that any file devices left open after
;;; the parsing of line-oriented files are closed
;;;
define close_file_devices(file_descriptors);
lvars file_descriptors findex curr_desc;

    fast_for findex from 1 to length(file_descriptors) do
	    subscrv(findex, file_descriptors) -> curr_desc;
	    if ispair(curr_desc) and isdevice(back(curr_desc)) then
		    sysclose(back(curr_desc));
		endif;
    endfast_for;
enddefine;


;;; parse_discrete_files takes a list of lists, an example set and
;;; an arrayfn. It first checks to see how long each sub-list in the
;;; files-list is. If any of them have more than 1 item then that is the
;;; number of examples being trained (since it implies that each example
;;; is in a separate files). If all of them are of length 1 then the
;;; first file in the list is opened and has the number of lines in it
;;; counted (this gives the number of examples).
;;;
;;; If the example set has the "keep examples" flag set then two lists of
;;; lists containing the basic data (unconverted but without any of
;;; the separators or extra bits and pieces) is returned (one list for
;;; input data, the other with target data).
;;;
define parse_discrete_files(files_list, eg_rec, arrayfn)
							-> inp_examples -> targ_examples
							-> inp_array -> targ_array -> n_examples;
lvars eg_rec arrayfn inp_examples = false, targ_examples = false,
		inp_array targ_array targ_closure = false, n_examples = false,
		files_list filelist index template type_template ininfo, targinfo,
		file_descriptors findex curr_example curr_desc
		dev repeater return_examples_p;

	;;; If a number of separate files have been produced for a given
	;;; wildcard then that must be the number of examples
	for filelist in files_list do
		if islist(filelist) then
			length(filelist) -> n_examples;
			quitloop();
		endif;
	endfor;

	;;; unless we've already found the number of examples then open the
	;;; first file and count the number of lines in it.
	unless n_examples then
		nn_file_line_count(hd(files_list), false, "line") -> n_examples;
	endunless;

	setup_raw_data_arrays(eg_rec, arrayfn, n_examples)
			-> inp_array -> targ_array;

	eg_keep_egs(eg_rec) -> return_examples_p;
	eg_template(eg_rec) -> template;

	;;; if we only need to parse input examples then ensure that
	;;; any output datatypes have been removed from the template
	;;;
	unless eg_gen_output(eg_rec) then
		extract_input_fields(template) -> template;
	endunless;

	if return_examples_p then
		[] ->> inp_examples -> targ_examples;
	endif;

	setup_examplefile_descriptors(template, files_list) -> file_descriptors;

	;;; this will set up a template whch does not contain any filetypes
	;;; at the top-level
	if is_file_dt(nn_template_type(template(1))) then
		nn_remove_filetypes(template) -> type_template;
	else
		;;; if the first datatype isn't a filetype then none of
		;;; them should be
		template -> type_template;
	endif;

    fast_for index from 1 to n_examples do
		[% fast_for findex from 1 to length(file_descriptors) do
			subscrv(findex, file_descriptors) -> curr_desc;
			if ispair(curr_desc) and
			  isprocedure(front(curr_desc)) then	;;; open file so get a line
				apply(front(curr_desc))

			elseif isvector(curr_desc) then
				;;; open the file to be read in one go
				open_example_file(curr_desc(1)(index), true,
								  curr_desc(2),
								  curr_desc(3),
								  curr_desc(4),
								  curr_desc(5)) -> dev -> repeater;
				repeater();
				sysclose(dev);
			endif;
		endfast_for %] -> curr_example;

		if targ_array then
			targ_array(%index%) -> targ_closure;
		endif;

        core_parse_example(curr_example, type_template,
                inp_array(%index%), targ_closure,
				return_examples_p) -> ininfo -> targinfo;

		if return_examples_p then
			ininfo :: inp_examples -> inp_examples;
			if targinfo then
				targinfo :: targ_examples -> targ_examples;
			endif;
		else
			sys_grbg_list(ininfo);
			if islist(targinfo) then
				sys_grbg_list(targinfo);
			endif;
		endif;
    endfast_for;

	close_file_devices(file_descriptors);

	if return_examples_p then
		ncrev(inp_examples) -> inp_examples;
		if islist(targ_examples) then
			ncrev(targ_examples) -> targ_examples;
		endif;
	endif;
enddefine;


;;; parse_discrete_singlefiles takes a list of filenames and a template
;;; and returns a list of the items extracted from the files.
;;;
define parse_discrete_singlefiles(files_list, template, listify_p) -> example;
lvars findex example files_list template file_descriptors listify_p
	curr_desc dev repeater;

	setup_examplefile_descriptors(template, files_list) -> file_descriptors;

	[% fast_for findex from 1 to length(file_descriptors) do
		subscrv(findex, file_descriptors) -> curr_desc;
		if ispair(curr_desc) and
		  isprocedure(front(curr_desc)) then	;;; open file so get a line
			if listify_p then
				[% apply(front(curr_desc)) %];
			else
				apply(front(curr_desc));
			endif;

		elseif isvector(curr_desc) then
			;;; open the file to be read in one go
			open_example_file(curr_desc(1)(1), true,
							  curr_desc(2),
							  curr_desc(3),
							  curr_desc(4),
							  curr_desc(5)) -> dev -> repeater;
			if listify_p then
				[% repeater(); %];
			else
				repeater();
			endif;
			sysclose(dev);
		endif;
	endfast_for %] -> example;

	close_file_devices(file_descriptors);
enddefine;


;;; read_file_columns takes a filename (string), a file datatype,
;;; an integer which is the number of columns in the file and
;;; leaves vectors of the examples read on the stack.
;;;
define read_file_columns(filename, ftype, n_cols);
lvars filename ftype examples n_cols column_count index item vec
		entries org struct_or_proc eol_mark popnewline_p dev line_repeater
		n_lines temp_list line_count;

	;;; now make a list of properties to hold the data
	[% repeat n_cols times
		newproperty([], 100, false, "perm");
	endrepeat %] -> examples;

	;;; now make a vector of integers which hold the number of items
	;;; read for that column
	{% repeat n_cols times
		0
	endrepeat %} -> column_count;

	get_examplefile_attributes(ftype)
		-> org -> struct_or_proc -> eol_mark -> popnewline_p;

	open_example_file(filename, false, org, struct_or_proc, eol_mark,
					popnewline_p) -> dev -> line_repeater;

	1 -> line_count;

	;;; this will simply continue looping until
	repeat forever
		[% line_repeater() %] -> temp_list;
		if temp_list == [] then quitloop(); endif;
		fast_for index from 1 to length(temp_list) do
			;;; update the vector slot
			temp_list(index) -> examples(index)(line_count);
			subscrv(index, column_count) fi_+ 1 ->
										subscrv(index, column_count);
		endfast_for;
		sys_grbg_list(temp_list);
		line_count fi_+ 1 -> line_count;
	endrepeat;
	sys_grbg_list(temp_list);
	examples -> temp_list;
	sysclose(dev);

	;;; now we've finished reading the file so create vectors and
	;;; transfer the data from the property tables to the vectors
	fast_for index from 1 to n_cols do
		initv(subscrv(index, column_count)) -> vec;
		examples(index) -> entries;
		fast_for item from 1 to subscrv(index, column_count) do
			entries(item) -> subscrv(item, vec);
		endfast_for;
		vec;
	endfast_for;
	sys_grbg_list(temp_list);
enddefine;


;;; read_file_rows takes a filename (string), a file datatype,
;;; an integer which is the number of rows in the file. It
;;; leaves vectors of the examples read on the stack.
;;;
define read_file_rows(filename, ftype, n_rows);
lvars filename ftype examples n_rows
		org struct_or_proc eol_mark popnewline_p dev line_repeater;

	get_examplefile_attributes(ftype)
		-> org -> struct_or_proc -> eol_mark -> popnewline_p;

	open_example_file(filename, false, org, struct_or_proc, eol_mark,
					popnewline_p) -> dev -> line_repeater;

	repeat n_rows times
		{% line_repeater() %}
	endrepeat;
	sysclose(dev);
enddefine;


#_IF DEF NEURAL_CONTINUOUSDATA
define read_continuous_file_examples(template, filelist, eg_rec) -> all_examples;
lvars template filelist eg_rec all_examples filename template_entry;

    ;;; check how the data are organised
    if (eg_use_in_lines(eg_rec) and not(eg_in_lines(eg_rec))) then
		if eg_has_filetypes(eg_rec) then
			[% for filename template_entry in filelist, template do
				;;; there is a restriction sequence filetypes can only
				;;; refer to simple types
				read_file_columns(filename,
									nn_template_type(template_entry), 1);
			endfor %] -> all_examples;
		else
			;;; should only have 1 filename
			hd(filelist) -> filename;
			[% read_file_columns(filename, false,
				length(template)) %] -> all_examples;
		endif;
    else
		if eg_has_filetypes(eg_rec) then
			[% for filename template_entry in filelist, template do
				;;; there is a restriction sequence filetypes can only
				;;; refer to simple types
				read_file_rows(filename,
								nn_template_type(template_entry), 1);
			endfor %] -> all_examples;
		else
			;;; should only have 1 filename
			hd(filelist) -> filename;
			[% read_file_rows(filename, false,
				length(template)) %] -> all_examples;
		endif;
    endif;
enddefine;


;;; parse_continuous_files
;;; If the example set has the "keep examples" flag set then two lists of
;;; lists containing the basic data (unconverted but without any of
;;; the separators or extra bits and pieces) is returned (one list for
;;; input data, the other with target data).
;;;
define parse_continuous_files(files_list, eg_rec, arrayfn)
							-> inp_examples -> targ_examples
							-> inp_array -> targ_array -> n_examples;
lvars eg_rec arrayfn inp_examples = false, targ_examples = false,
		inp_array targ_array n_examples = false, all_examples
		files_list filelist index template type_template return_examples_p;

	eg_keep_egs(eg_rec) -> return_examples_p;
	eg_template(eg_rec) -> template;

	if return_examples_p then
		[] ->> inp_examples -> targ_examples;
	endif;


	read_continuous_file_examples(template, eg_gen_params(eg_rec), eg_rec)
			-> all_examples;

	;;; this will set up a template which does not contain any filetypes
	;;; at the top-level
	if is_file_dt(nn_template_type(template(1))) then
		nn_remove_filetypes(template) -> type_template;
	else
		;;; if the first datatype isn't a filetype then none of
		;;; them should be
		template -> type_template;
	endif;

	;;; now we can simply pass all the results to be parsed by
	;;;	parse_continuous_lists
	;;;
	parse_continuous_lists(all_examples, eg_rec, type_template,
		eg_in_template(eg_rec), eg_out_template(eg_rec), arrayfn)
				-> inp_examples -> targ_examples
				-> inp_array -> targ_array -> n_examples;

	unless return_examples_p then
		false ->> inp_examples -> targ_examples;
	endunless;
enddefine;
#_ENDIF


;;; The following functions:
;;;
;;; 	parse_egs_from_struct
;;; 	parse_egs_from_proc
;;; 	parse_egs_from_file
;;;
;;; are called from nn_generate_egs. They are called with the example set
;;; and array creation function and extract data from the appropriate
;;; data source (a literal structure, a procedure or a file), parse the
;;; data and return the high-level (unconverted) data for input and
;;; target examples (latter may be false if there are no target examples),
;;; the data arrays for input and targets (again, target array may be false)
;;; and the number of examples produced. The raw data arrays are created
;;; using the array creation function.
;;;
;;; All of these functions assume that the examples need to be converted
;;; before being added to the raw training arrays since the raw data
;;; case (when eg_flags has the EG_RAWDATA_IN flag set) is handled directly
;;; inside nn_generate_egs.
;;;
define parse_egs_from_struct(eg_rec, arrayfn) -> inp_examples -> targ_examples
            -> inp_array -> targ_array -> n_examples;
lvars eg_rec arrayfn inp_examples targ_examples inp_array targ_array
		n_examples all_examples;

	eg_gen_params(eg_rec) -> all_examples;

	if eg_keep_egs(eg_rec) then
		all_examples -> eg_gendata(eg_rec);
	endif;

#_IF DEF NEURAL_CONTINUOUSDATA
	if eg_discrete(eg_rec) then
		parse_discrete_lists(all_examples, eg_rec, arrayfn)
							-> inp_examples -> targ_examples
							-> inp_array -> targ_array -> n_examples;
	else
		parse_continuous_lists(all_examples, eg_rec,
					eg_template(eg_rec), eg_in_template(eg_rec),
					eg_out_template(eg_rec), arrayfn)
							-> inp_examples -> targ_examples
							-> inp_array -> targ_array -> n_examples;
	endif;
#_ELSE		/* Discrete data only */
	parse_discrete_lists(all_examples, eg_rec, arrayfn)
						-> inp_examples -> targ_examples
						-> inp_array -> targ_array -> n_examples;
#_ENDIF
enddefine;


define parse_egs_from_proc(eg_rec, arrayfn) -> inp_examples -> targ_examples
            -> inp_array -> targ_array -> n_examples;
lvars eg_rec arrayfn inp_examples targ_examples
	  inp_array targ_array n_examples all_examples;

	apply(eg_gen_params(eg_rec)) -> all_examples;

	if eg_keep_egs(eg_rec) then
		all_examples -> eg_gendata(eg_rec);
	endif;

#_IF DEF NEURAL_CONTINUOUSDATA
	if eg_discrete(eg_rec) then
		parse_discrete_lists(all_examples, eg_rec, arrayfn)
							-> inp_examples -> targ_examples
							-> inp_array -> targ_array -> n_examples;
	else
		parse_continuous_lists(all_examples, eg_rec,
					eg_template(eg_rec), eg_in_template(eg_rec),
					eg_out_template(eg_rec), arrayfn)
							-> inp_examples -> targ_examples
							-> inp_array -> targ_array -> n_examples;
	endif;
#_ELSE		/* Discrete data only */

	parse_discrete_lists(all_examples, eg_rec, arrayfn)
						-> inp_examples -> targ_examples
						-> inp_array -> targ_array -> n_examples;
#_ENDIF
enddefine;


define parse_egs_from_file(eg_rec, arrayfn) -> inp_files -> targ_files
            -> inp_array -> targ_array -> n_examples;
lvars eg_rec arrayfn inp_files targ_files inp_array targ_array n_examples
	  spec file_specs files_list;

	if isstring(eg_gen_params(eg_rec) ->> file_specs) then
		[^file_specs] ->> file_specs -> eg_gen_params(eg_rec);
	endif;

	;;; for filetypes, the eg_gen_params slot contains a list of filenames
	;;; as data sources or a single string. The result of exanding these
	;;; is a list of filenames which can be added to the eg_gendata slot.
	[% for spec in file_specs do
		get_filenames(spec);
	endfor %] ->> files_list -> eg_gendata(eg_rec);

#_IF DEF NEURAL_CONTINUOUSDATA
	if eg_discrete(eg_rec) then
		parse_discrete_files(files_list, eg_rec, arrayfn)
							-> inp_files -> targ_files
							-> inp_array -> targ_array -> n_examples;
	else
		parse_continuous_files(files_list, eg_rec, arrayfn)
							-> inp_files -> targ_files
							-> inp_array -> targ_array -> n_examples;
	endif;
#_ELSE		/* Discrete data only */
	parse_discrete_files(files_list, eg_rec, arrayfn)
						-> inp_files -> targ_files
						-> inp_array -> targ_array -> n_examples;
#_ENDIF
enddefine;


;;; Given an example set which has a template and a generator function,
;;; nn_generate_egs creates the examples and data structures and convert
;;; the examples into a form appropriate for the current neural net.
;;;
define global nn_generate_egs(eg_rec);
lvars innodes outnodes ininfo = [],
      arrayfn = nn_net_array_fn(dataword(nn_neural_nets(nn_current_net))),
	  eg_rec examples = false, len template inp_array outp_array
	  inp_files outp_files index data_source flags source_name source_egs;

	;;; check if array creator function has been passed - if so,
	;;; grab the example set name/record still on the stack
    if isprocedure(eg_rec) then
        eg_rec -> arrayfn -> eg_rec;
    endif;

	;;; allow the user to pass in a named exampleset as well as an
	;;; example set record
    if isword(eg_rec) then
        nn_example_sets(eg_rec) -> eg_rec;
    endif;

	;;; update unit count in case this has been changed
	set_egs_units_needed(eg_rec);

    eg_template(eg_rec) -> template;
	eg_data_source(eg_rec) -> data_source;

	;;; get hold of the data from the defined source
	if egs_from_proc(data_source) then		;;; procedures should be applied
		if eg_rawdata_in(eg_rec) then
			;;; raw data should be ready for the neural network to
			;;; train on
    		apply(eg_gen_params(eg_rec)) -> eg_in_data(eg_rec) -> eg_targ_data(eg_rec);
		    false ->> eg_in_examples(eg_rec) ->> eg_out_examples(eg_rec)
			    ->> eg_targ_examples(eg_rec) -> eg_gendata(eg_rec);
		else
			parse_egs_from_proc(eg_rec, arrayfn)
				-> eg_in_examples(eg_rec) -> eg_targ_examples(eg_rec)
				-> eg_in_data(eg_rec) -> eg_targ_data(eg_rec)
				-> eg_examples(eg_rec);
		endif;

	elseif egs_from_literal(data_source) then
		parse_egs_from_struct(eg_rec, arrayfn)
			-> eg_in_examples(eg_rec) -> eg_targ_examples(eg_rec)
			-> eg_in_data(eg_rec) -> eg_targ_data(eg_rec)
			-> eg_examples(eg_rec);

	elseif egs_from_egs(data_source) then
		;;; get the source example set name
		eg_gen_params(eg_rec) -> source_name;
		if (nn_example_sets(source_name) ->> source_egs) then
			;;; transfer the output data from the source egs to this one
			eg_out_data(source_egs) -> eg_in_data(eg_rec);
			eg_examples(source_egs) -> eg_examples(eg_rec);
		else
			mishap(source_name, 1, err(NOSU_EG));
		endif;

	elseif egs_from_file(data_source) then
		parse_egs_from_file(eg_rec, arrayfn)
			-> eg_in_examples(eg_rec) -> eg_targ_examples(eg_rec)
			-> eg_in_data(eg_rec) -> eg_targ_data(eg_rec)
			-> eg_examples(eg_rec);
	else
		mishap(data_source, 1, 'Unknown data source');
	endif;

	if eg_rawdata_in(eg_rec) then
		return();
	endif;

	unless eg_keep_egs(eg_rec) then
	    ;;; free any high-level items which may have been included in
	    ;;; the example set
	    false ->> eg_in_examples(eg_rec) -> eg_targ_examples(eg_rec);
	endunless;
enddefine;


;;; nn_generate_egs_input is used to generate example sets which
;;; do not have any target data defined for them.
;;;
define global nn_generate_egs_input(eg_rec);
lvars eg_rec arrayfn = false;

	define lconstant call_gen();
	dlocal %eg_gen_output(eg_rec)% = false;

		if arrayfn then
			nn_generate_egs(eg_rec, arrayfn);
		else
			nn_generate_egs(eg_rec);
		endif;
	enddefine;

	;;; check if array creator function has been passed - if so,
	;;; grab the example set name/record still on the stack
    if isprocedure(eg_rec) then
        eg_rec -> arrayfn -> eg_rec;
    endif;

	;;; allow the user to pass in a named exampleset as well as an
	;;; example set record
    if isword(eg_rec) then
        nn_example_sets(eg_rec) -> eg_rec;
    endif;

	call_gen();
enddefine;


;;; nn_copy_egs takes an example set and copies it
define global constant nn_copy_egs(egs) -> egscopy;
lvars egs index egscopy;
    if isword(egs) then
        nn_example_sets(egs) -> egs;
    endif;
    if egs then
        newcopydata(egs) -> egscopy;
    else
        false -> egscopy;
    endif;
enddefine;


;;; delete an example set and return the item
define global nn_delete_egs(name);
lvars name;
    false -> nn_example_sets(name);
	if name == nn_current_egs then
		false -> nn_current_egs;
	endif;
enddefine;


;;; nn_get_example_from_files takes list of filenames, a template and a
;;; listify flag and returns a list of "high-level" data items
;;; extracted from the files. If the listify flag is true then items
;;; read from each file are returned as a sublist. If false then
;;; the the returned items are all in a single list.
;;;
define global nn_get_example_from_files(files_list, template, listify_p) -> example;
lvars template files_list listify_p example;

	parse_discrete_singlefiles(files_list, template, listify_p) -> example;
enddefine;

global vars nn_examplesets = true;		;;; for "uses"

endsection;		/* $-popneural */

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 14/10/93
	Removed extra call to generator function in nn_generate_egs
		(see PNF0044).
-- Julian Clinton, 9/11/92
	Removed unnecessary checking from nn_make_egs which was preventing
		example sets for CL nets being created.
-- Julian Clinton, 26/8/92
	Added ability to generate only input examples.
-- Julian Clinton, 21/8/92
	Renamed -eg_genfn- to -eg_gen_params- and -eg_applyfn- to
		-eg_apply_params-.
-- Julian Clinton, 18/8/92
	Various minor bug fixes.
-- Julian Clinton, 12/8/92
	#_IF'd out the support for continuous data.
-- Julian Clinton, 27/6/92
	Added some new flags and flag access procedures.
-- Julian Clinton, 26/6/92
	Re-wrote the generator and parser functions to support data formats
		and optional storage of the converted data.
-- Julian Clinton, 23/6/92
	Added example set flags.
-- Julian Clinton, 22/6/92
	Removed export of -nn_parse_training_example-.
	Moved -nn_apply_example- from here to nn_apply.p
	Modified construction of example set.
-- Julian Clinton, 19/6/92
    nn_delete_egs now assigns false to nn_current_egs if the deleted
	exampleset is current.
-- Julian Clinton, 10/6/92
	Renamed eg_in_info to eg_in_examples.
-- Julian Clinton, 8/5/92
    Sectioned.
*/
