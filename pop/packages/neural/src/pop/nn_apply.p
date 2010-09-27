/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:           $popneural/src/pop/nn_apply.p
 > Purpose:        functions to apply example sets to networks
 >
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:  nn_dtconverters.p, nn_examplesets.p
 */

section $-popneural =>  nn_test_egs_item
                        nn_test_egs
                        nn_apply_data
                        nn_apply_example
                        nn_put_example_to_files
                        nn_apply_egs_item
                        nn_apply_egs
                        nn_result_diffs
                        nn_result_accuracy
                        nn_result_error
;

/* ----------------------------------------------------------------- *
    Basic Utility Procs For Extracting Results
 * ----------------------------------------------------------------- */

;;; open_output_file takes a filename and a template entry and returns
;;; the raw device and either a procedure (which is a character or
;;; item consumer) or a byte-structure used with syswrite. If the
;;; the call to sysopen returns false for some reason then the consumer
;;; arg is also false. Note the file is opened write-only.
;;;
define open_output_file(filename, org, apply_proc, gap, eol_mark)
									-> dev -> line_consumer;
lvars filename dev line_consumer apply_proc org;
lvars consumer gap eol_mark popnewline_p;

	define cons_txtline_consumer(list, consumer, gap, eol_mark);
	lvars list consumer eol_mark item index;
		if islist(list) then
		    for item in list do
			    consumer(item);
			    if gap then
				    consumer(gap);
			    endif;
		    endfor;
		elseif isvector(list) then
			fast_for index from 1 to length(list) do
				consumer(subscrv(1, list));
			    if gap then
				    consumer(gap);
			    endif;
			endfast_for;
		else
			;;; single item so send that
			consumer(list);
		    if gap then
			    consumer(gap);
		    endif;
		endif;
	    consumer(eol_mark);
	enddefine;

    if (syscreate(filename, 1, org) ->> dev) then
		if isprocedure(apply_proc) then
			cons_txtline_consumer(%apply_proc(dev), gap, eol_mark%)
		elseif isvectorclass(apply_proc) then
			raw_write(%dev%)
		else
			mishap(apply_proc, 1,
					'Invalid proc/structure for example consumer');
		endif
	else
		mishap(filename, 1, 'Unable to open output file');
	endif -> line_consumer;
enddefine;


;;; setup_outputfile_descriptors takes a template and the list of files
;;; and sets up the vector of file descriptors. These either contain
;;; a pair where the front is the repeater and the back is the raw
;;; device or a vector containing a list of filenames, the ORG
;;; argument for -sysopen-, the structure (for "line" and "file" types)
;;; or the repeater (for "char" or "item" files), the end-of-line marker
;;; and the value for -popnewline- (these last two are only used
;;; by "char" and "item" types).
;;;
define setup_outputfile_descriptors(type_list, files_list) -> file_descriptors;
lvars type_list files_list file_descriptors index n_filefields a_index
	ftype fname newpair org struct_or_proc gap eol_marker;

	;;; how many separate sets of files are there ?
	initv(length(files_list) ->> n_filefields) -> file_descriptors;

	;;; for each set of files:
	;;;		a) check the datatype specified and if appropriate set the
	;;; 	required flags,
	;;;
	;;;		b) if the file name contains a '*' then multiple files are
	;;;		required so convert the * to a '%p' for use with sprintf
	;;;
	;;; Note that if the datatype is not a filetype then there should only
	;;; be one filename in any case so get_file_attributes should return
	;;; values appropriate for an itemised file organised in lines.
	;;;
	fast_for index from 1 to n_filefields do
		type_list(index) -> ftype;
		if islist(ftype) then		;;;	have direction and fieldname info
			nn_datatypes(nn_template_type(ftype))
		else
			nn_datatypes(ftype)
		endif -> ftype;

		if ftype then
			get_outputfile_attributes(ftype) -> org -> struct_or_proc
								-> gap -> eol_marker;

			files_list(index) -> fname;

			if isstring(fname) and (locchar(`*`, 1, fname) ->> a_index) then
				;;; replace the * with %p
				substring(1, a_index - 1, fname) sys_>< '%p'
					sys_>< substring(a_index + 1, length(fname) - a_index, fname)
						-> fname;

				consvector(sprintf(%fname%), org, struct_or_proc,
							gap, eol_marker, 5);

			elseif islist(fname) then	;;; the user has supplied a list
										;;; of filenames directly so allow
										;;; the user to access each one

				consvector(subscrl(%fname%), org, struct_or_proc,
							gap, eol_marker, 5);

			elseif org == true then		;;; we have a file datatype so
										;;; return a vector
				consvector(fname, org, struct_or_proc, gap, eol_marker, 5);
			else
				;;; otherwise only have one filename so open it immediately
				conspair(false,false) -> newpair;
				open_output_file(fname, org, struct_or_proc, gap, eol_marker)
					-> back(newpair) -> front(newpair);
				newpair;
			endif -> subscrv(index, file_descriptors);
		else
			mishap(ftype, 1, 'Unknown datatype in file description');
		endif;
	endfast_for;
enddefine;


define unparse_discrete_files(accessor, eg_rec) -> files -> results;
lvars eg_rec n_outputs = false, outp_array accessor curr_desc fname
		files_list filelist index type_list type_template outinfo
		file_descriptors findex dev consumer files
		return_results_p results = false;

	;;; strip_list removes the extra depth of list which is added
	;;; to the converted items to allow them to be written to
	;;; file. This is necessary when the data is held in the
	;;; eg_out_examples slot and compared with eg_targ_examples
	;;; (which won't have the extra nesting).
	;;;
	define lconstant strip_list(old_list) -> new_list;
	lvars old_list new_list item;

		[% fast_for item in old_list do
			dl(item);
			sys_grbg_list(item);
		endfast_for; %] -> new_list;

		;;; reclaim the defunct list
		sys_grbg_list(old_list);
	enddefine;

	eg_out_template(eg_rec) -> type_list;
	eg_examples(eg_rec) -> n_outputs;
	eg_apply_params(eg_rec) -> files_list;
	eg_keep_egs(eg_rec) -> return_results_p;

	if isstring(files_list) then
		[^files_list] -> files_list;
	endif;

	accessor(eg_rec) -> outp_array;

	if return_results_p then
		[] -> results;
	endif;

	setup_outputfile_descriptors(type_list, files_list) -> file_descriptors;

	[% fast_for findex from 1 to length(file_descriptors) do
		if ispair(subscrv(findex, file_descriptors)) then
			;;; a simple file name so access it directly
			[^(files_list(findex))]
		else
			;;; leave a list which can be added to
			initl(n_outputs)
		endif;
	endfast_for %] -> files;

	;;; this will set up a type_list whch does not contain any filetypes
	;;; at the top-level
	if is_file_dt(nn_template_type(type_list(1))) then
		nn_remove_filetypes(type_list) -> type_template;
	else
		;;; if the first datatype isn't a filetype then none of
		;;; them should be
		type_list -> type_template;
	endif;

    fast_for index from 1 to n_outputs do

		;;; for output to a file, the raw data has to be unparsed so that
		;;; each group of items sent to each file are in a list on their own
		;;; which can then be passed to the file consumer. This is the
		;;; only time when core_unparse_output has to listify the results.
		;;;
        core_unparse_output(outp_array(%index%), type_template, true) -> outinfo;

		fast_for findex from 1 to length(file_descriptors) do
			subscrv(findex, file_descriptors) -> curr_desc;
			if ispair(curr_desc) and
			  isprocedure(front(curr_desc)) then	;;; open file so put a line
				apply(outinfo(findex), front(curr_desc))

			elseif isvector(curr_desc) then
				;;; we need to write a whole file at a time
				curr_desc(1) -> fname;
				if isprocedure(fname) then
					;;; either an sprintf or subscrl closure
					apply(index, fname) -> fname;
				endif;
				fname -> subscrl(index, subscrl(findex, files));
				open_output_file(fname,
								  curr_desc(2),
								  curr_desc(3),
								  curr_desc(4),
								  curr_desc(5)) -> dev -> consumer;
				consumer(outinfo(findex));
				sysclose(dev);
			endif;
		endfast_for;

		if return_results_p then
			strip_list(outinfo) :: results -> results;
		else
			sys_grbg_list(outinfo);
		endif;
    endfast_for;

	;;; now go through closing the files
	close_file_devices(file_descriptors);

	if return_results_p then
		ncrev(results) -> results;
	endif;
enddefine;


define unparse_discrete_singlefiles(files_list, template, result);
lvars files_list template result curr_desc fname
		file_descriptors findex dev consumer files;

	if isstring(files_list) then
		[^files_list] -> files_list;
	endif;

	setup_outputfile_descriptors(template, files_list) -> file_descriptors;

	[% fast_for findex from 1 to length(file_descriptors) do
		if ispair(subscrv(findex, file_descriptors)) then
			;;; a simple file name so access it directly
			[^(files_list(findex))]
		endif;
	endfast_for %] -> files;

	fast_for findex from 1 to length(file_descriptors) do
		subscrv(findex, file_descriptors) -> curr_desc;

		if ispair(curr_desc) and
		  isprocedure(front(curr_desc)) then	;;; open file so put a line
			apply(result(findex), front(curr_desc))

		elseif isvector(curr_desc) then
			;;; We need to write a whole file at a time.
			;;; Single file output so always write wildcards as "Out".
			sprintf("Out", curr_desc(1)) -> fname;
			fname -> subscrl(1, subscrl(findex, files));
			open_output_file(fname,
							  curr_desc(2),
							  curr_desc(3),
							  curr_desc(4),
							  curr_desc(5)) -> dev -> consumer;
			consumer(result(findex));
			sysclose(dev);
		endif;
	endfast_for;

	;;; now close the files
	close_file_devices(file_descriptors);
enddefine;


;;; unparse_discrete_lists takes an eg_record accessor procedure
;;; (which should be eg_out_data or eg_targ_data) and an example
;;; set and returns a list of lists of the discrete outputs
;;;
define unparse_discrete_lists(accessor, eg_rec, listify_p) -> lists;
lvars eg_rec listify_p outp_array accessor index lists template n_outputs;

	eg_out_template(eg_rec) -> template;
	eg_examples(eg_rec) -> n_outputs;
	accessor(eg_rec) -> outp_array;

    [% fast_for index from 1 to n_outputs do
        core_unparse_output(outp_array(%index%), template, listify_p);
    endfast_for %] -> lists;
enddefine;


#_IF DEF NEURAL_CONTINUOUSDATA
;;; unparse_continuous_lists takes an eg_record accessor procedure
;;; (which should be eg_out_data or eg_targ_data) and an example
;;; set and returns a list of vectors of the parsed output sequences.
;;;
define unparse_continuous_lists(accessor, eg_rec) -> lists;
lvars eg_rec outp_array accessor index descriptors type_list type lists
		n_units n_types n_raw_vals n_seq_parts array_ptr current_sequence
		desc_entry converter n_raw_vals n_items seq_index;

	check_1d_array(accessor, eg_rec);
	accessor(eg_rec) -> outp_array;
	eg_out_template(eg_rec) -> type_list;
	length(type_list) -> n_types;

	if eg_has_filetypes(eg_rec) then
		;;; remove filetypes for the time being
		nn_remove_filetypes(type_list) -> type_list;
	endif;

	;;; Need to work out how many units are needed to represent the
	;;; sequences. Dividing the length of the arrayvector by this
	;;; number gives the number of sequence "parts" to be parsed.
	nn_units_needed(type_list) -> n_units;
	length(arrayvector(outp_array)) -> n_raw_vals;
	n_raw_vals/n_units -> n_seq_parts;

	unless isinteger(n_seq_parts) then
		mishap(n_seq_parts, 1,
				'Output series is not a multiple of the no. of output units');
	endunless;

	;;; create a cache for storing the number of items needed
	initv(n_types) -> descriptors;
	for index from 1 to n_types do
		consvector(1, nn_items_needed(type_list(index)),
					nn_units_needed(type_list(index)),
					nn_dt_inconv(nn_datatypes(type_list(index))),
					4) -> subscrv(index, descriptors);
	endfor;

	;;; Now setup the list of vectors which will be filled with high-level
	;;; data. We get the size of each vector by multiplying the number
	;;; of items returned by each "part" of a sequence by the number
	;;; of sequence parts.
	[% for index from 1 to n_types do
		subscrl(index, type_list) -> type;
		if is_line_file_dt(type) or is_full_file_dt(type) then
			;;; values are returned as a byte-structure
		else
			initv(subscrv(2, subscrv(index, descriptors)) * n_seq_parts);
		endif;
	endfor %] -> lists;


	1 -> array_ptr;
	repeat n_seq_parts times
	    fast_for index from 1 to n_types do
			lists(index) -> current_sequence;
			fast_subscrv(index, descriptors) -> desc_entry;
			explode(desc_entry) -> converter -> n_raw_vals -> n_items -> seq_index;

			;;; Leave the raw values on the stack
			repeat n_raw_vals times
				outp_array(array_ptr);
				array_ptr fi_+ 1 -> array_ptr;
			endrepeat;

			;;; ...call the converter...
		    apply(converter);

			;;; grab the high-level data items
			repeat n_items times
				-> current_sequence(seq_index);
				seq_index fi_+ 1 -> seq_index;
			endrepeat;
			seq_index -> fast_subscrv(1, desc_entry);
	    endfast_for;
	endrepeat;
enddefine;


;;; unparse_continuous_files takes an accessor (eg_out_data or
;;; eg_targ_data) and an example set. It returns a list of filenames
;;; to which the output sequences were sent and the list of vectors
;;; of the output data.
;;;
define unparse_continuous_files(accessor, eg_rec) -> file_list -> examples;
lvars accessor eg_rec file_list examples type_list file_descriptors
		sequence seq_index curr_desc temp_list index outfile;

	unparse_continuous_lists(accessor, eg_rec) -> examples;
	eg_apply_params(eg_rec) -> file_list;

	if isstring(file_list) then
		[^file_list] ->> eg_apply_params(eg_rec) -> file_list;
	elseunless islist(file_list) then
		mishap(file_list, 1, 'List of filenames needed');
	endif;

	eg_out_template(eg_rec) -> type_list;
	setup_outputfile_descriptors(type_list, file_list) -> file_descriptors;

	;;; The loops used to iterate through the vectors assume that
	;;; the lengths of the output vectors are all the same.
	if eg_use_in_lines(eg_rec) and not(eg_in_lines(eg_rec)) then
		;;; output data in columns.
		if length(file_list) == 1 then
			;;; send all data to one file
			front(subscrv(1, file_descriptors)) -> outfile;
		    for seq_index from 1 to length(hd(examples)) do
			    [% for sequence in examples do
				    subscrv(seq_index, sequence);
			    endfor %] -> temp_list;
				outfile(temp_list);
				sys_grbg_list(temp_list);
		    endfor;
			sysclose(back(subscrv(1, file_descriptors)));
		else
			if length(file_list) /== length(examples) then
				mishap(length(file_list), length(examples), 2,
					'Number of output file_list should match number of sequences');
			endif;

			;;; for each item in a sequence
		    for seq_index from 1 to length(hd(examples)) do
				;;; for each file/sequence
			    fast_for index from 1 to length(file_list) do
				    subscrv(index, file_descriptors) -> curr_desc;
				    subscrl(index, examples) -> sequence;
					apply(subscrv(seq_index, sequence), front(curr_desc));
				endfast_for;
			endfor;

			;;; close the devices
		    fast_for index from 1 to length(file_descriptors) do
				sysclose(back(subscrv(index, file_descriptors)));
			endfast_for;
		endif;
	else
		;;; output data in rows
		if length(file_list) == 1 then
			;;; send all data to one file
			front(subscrv(1, file_descriptors)) -> outfile;
			for sequence in examples do
				outfile(sequence);
		    endfor;
			sysclose(back(subscrv(1, file_descriptors)));

		else
			if length(file_list) /== length(examples) then
				mishap(length(file_list), length(examples), 2,
					'Number of output file_list should match number of sequences');
			endif;

			;;; for each item in a sequence
		    fast_for seq_index from 1 to length(examples) do
				;;; send each sequence to its own file
				apply(examples(seq_index),
						front(subscrv(seq_index, file_descriptors)));
			endfast_for;

			;;; close the devices
		    fast_for index from 1 to length(file_descriptors) do
				sysclose(back(subscrv(index, file_descriptors)));
			endfast_for;
		endif;
	endif;

	unless eg_keep_egs(eg_rec) then
		false -> examples;
	endunless;
enddefine;
#_ENDIF


/* ----------------------------------------------------------------- *
    Utility Procs For Applying And Saving Results
 * ----------------------------------------------------------------- */

;;; In each of the following four procedures, accessor is expected
;;; to be one of eg_targ_data or eg_out_data
;;;

#_IF DEF NEURAL_CONTINUOUSDATA

define unparse_egs_to_file(accessor, eg_rec);
lvars accessor eg_rec;
	if eg_discrete(eg_rec) then
		unparse_discrete_files(accessor, eg_rec) -> eg_applydata(eg_rec)
			-> eg_out_examples(eg_rec);
	else
		unparse_continuous_files(accessor, eg_rec) -> eg_applydata(eg_rec)
			-> eg_out_examples(eg_rec);
	endif;
enddefine;

#_ELSE		/* Discrete data only */

define unparse_egs_to_file(accessor, eg_rec);
lvars accessor eg_rec;
	unparse_discrete_files(accessor, eg_rec) -> eg_applydata(eg_rec)
		-> eg_out_examples(eg_rec);
enddefine;
#_ENDIF


#_IF DEF NEURAL_CONTINUOUSDATA
define unparse_egs_to_proc(accessor, eg_rec);
lvars accessor eg_rec lists;
	if eg_discrete(eg_rec) then
		unparse_discrete_lists(accessor, eg_rec, false) -> lists;
	else
		unparse_continuous_lists(accessor, eg_rec) -> lists;
	endif;
	if eg_keep_egs(eg_rec) then
		lists -> eg_out_examples(eg_rec);
	endif;
	apply(lists, eg_apply_params(eg_rec));
enddefine;

#_ELSE		/* Discrete data only */

define unparse_egs_to_proc(accessor, eg_rec);
lvars accessor eg_rec lists;
	unparse_discrete_lists(accessor, eg_rec, false) -> lists;
	if eg_keep_egs(eg_rec) then
		lists -> eg_out_examples(eg_rec);
	endif;
	apply(lists, eg_apply_params(eg_rec));
enddefine;
#_ENDIF


#_IF DEF NEURAL_CONTINUOUSDATA
define unparse_egs_to_struct(accessor, eg_rec);
lvars eg_rec;
	if eg_discrete(eg_rec) then
		unparse_discrete_lists(accessor, eg_rec, false) -> eg_out_examples(eg_rec);
	else
		unparse_continuous_lists(accessor, eg_rec) -> eg_out_examples(eg_rec);
	endif;
enddefine;

#_ELSE		/* Discrete data only */

define unparse_egs_to_struct(accessor, eg_rec);
lvars eg_rec;
	unparse_discrete_lists(accessor, eg_rec, false) -> eg_out_examples(eg_rec);
enddefine;
#_ENDIF

define unparse_egs_to_egs(accessor, eg_rec);
lvars eg_rec targ_egs;
	nn_example_sets(eg_apply_params(eg_rec)) -> targ_egs;
	if targ_egs then
		accessor(eg_rec) -> eg_in_data(targ_egs);
	else
		mishap(targ_egs, 1, err(NOSU_EG));
	endif;
enddefine;


/* ----------------------------------------------------------------- *
    Main Functions
 * ----------------------------------------------------------------- */

define global nn_test_egs_item(item, egsname,
                               netname, show_targ) -> result;
lvars item i show_targ egsname netname pos
      data, invec, inunits outunits, arrayfn machine eg_rec outvec;

    if isneuralnet(netname) then
        nn_neural_nets(netname) -> machine;
    else
        mishap(netname, 1, 'Invalid network');
    endif;

    if isexampleset(egsname) then
        nn_example_sets(egsname) -> eg_rec;
    else
        mishap(egsname, 1, 'Invalid example set');
    endif;

	unless isinteger(item) then
		mishap(item, 1, 'Integer needed for index');
	endunless;

    nn_net_array_fn(dataword(machine)) -> arrayfn;
    apply(machine, nn_net_inputs_fn(dataword(machine))) -> inunits;
    apply(machine, nn_net_outputs_fn(dataword(machine))) -> outunits;

    eg_in_vector(eg_rec) -> invec;
	eg_out_vector(eg_rec) -> outvec;

	check_array_size(invec, inunits, false, arrayfn)
										->> eg_in_vector(eg_rec) -> invec;
	check_array_size(outvec, outunits, false, arrayfn)
										->> eg_out_vector(eg_rec) -> outvec;

    eg_in_data(eg_rec) -> data;

	unless data then
		mishap(eg_name(eg_rec), 1, 'No input data available in example set');
	endunless;

    copy_struct(data(%item%), invec, 1, eg_in_units(eg_rec));

    apply(invec, machine, outvec, nn_net_apply_item_fn(dataword(machine)));
    nn_unparse_example(outvec, eg_out_template(eg_rec)) -> result;
    [^result] -> eg_out_examples(eg_rec);
    if show_targ then
        eg_targ_data(eg_rec) -> data;
        copy_struct(data(%item%), outvec, 1, outunits);
        [%result, explode(nn_unparse_example(outvec,
                                             eg_out_template(eg_rec))) %]
            -> result;
        tl(result) -> eg_targ_examples(eg_rec);
    endif;
enddefine;


;;; nn_apply_datum takes an input vector, an output vector and a network
;;; structure. The result of the apply is left in the output vector.
;;;
define global nn_apply_datum(invec, outvec, network);
lvars responsefn = nn_net_apply_item_fn(dataword(network)),
	  	network invec outvec;

	Check_vectorclass(invec, false);
	Check_vectorclass(outvec, false);
    responsefn(invec, network, outvec);
enddefine;


;;; nn_apply_example takes an example, an input converter template,
;;; an output converter template and a network structure and returns
;;; the result of propagating the example through the net
;;;
define global nn_apply_example(example, intemplate, outtemplate,
                        invec, outvec, network) -> result;
lvars example intemplate outtemplate
		responsefn = nn_net_apply_item_fn(dataword(network)),
	  	network result = false, invec outvec;

	Check_vectorclass(invec, false);
	Check_vectorclass(outvec, false);
    nn_parse_example(example, intemplate, invec);
    responsefn(invec, network, outvec);
    nn_unparse_example(outvec, outtemplate) -> result;
enddefine;


;;; nn_put_example_to_files takes list of filenames, a template and
;;; and example and send the data to the
;;;
define global nn_put_example_to_files(example, files_list, template);
lvars template files_list example;

	Check_list(files_list, false);

	unparse_discrete_singlefiles(files_list, template, example);
enddefine;


define global nn_apply_egs_item(item, egsname, netname) -> result;
lvars item i egsname netname pos
      data invec outvec inunits outunits arrayfn machine eg_rec outvec;

    if isneuralnet(netname) then
        nn_neural_nets(netname) -> machine;
    else
        mishap(netname, 1, 'Invalid network');
    endif;

    if isexampleset(egsname) then
        nn_example_sets(egsname) -> eg_rec;
    else
        mishap(egsname, 1, 'Invalid example set');
    endif;

	unless isinteger(item) then
		mishap(item, 1, 'Integer needed for index');
	endunless;

    eg_in_data(eg_rec) -> data;
	unless data then
		mishap(eg_name(eg_rec), 1, 'No input data available in example set');
	endunless;

    nn_net_array_fn(dataword(machine)) -> arrayfn;
    apply(machine, nn_net_inputs_fn(dataword(machine))) -> inunits;
    apply(machine, nn_net_outputs_fn(dataword(machine))) -> outunits;

    eg_in_vector(eg_rec) -> invec;
	eg_out_vector(eg_rec) -> outvec;

	check_array_size(invec, inunits, false, arrayfn)
										->> eg_in_vector(eg_rec) -> invec;
	check_array_size(outvec, outunits, false, arrayfn)
										->> eg_out_vector(eg_rec) -> outvec;

    copy_struct(data(%item%), invec, 1, eg_in_units(eg_rec));
    apply(invec, machine, outvec, nn_net_apply_item_fn(dataword(machine)));
    nn_unparse_example(outvec, eg_out_template(eg_rec)) -> result;
enddefine;


;;; nn_apply_egs applies all the inputs of the example set
;;; to the net.
;;;
define global nn_apply_egs(egsname, netname);
lvars item i result, egsname netname inunits outunits arrayfn
      result_list = [], targ_list = [], data continuous_p = false,
	  invec outvec machine inarray outarray eg_rec;

    if isneuralnet(netname) then
        nn_neural_nets(netname) -> machine;
    else
        mishap(netname, 1, 'Invalid network');
    endif;

    if isexampleset(egsname) then
        nn_example_sets(egsname) -> eg_rec;
    else
        mishap(egsname, 1, 'Invalid example set');
    endif;

    nn_net_array_fn(dataword(machine)) -> arrayfn;
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

	eg_in_data(eg_rec) -> data;
	unless data then
		mishap(eg_name(eg_rec), 1, 'No input data available in example set');
	endunless;
	check_array_size(eg_out_data(eg_rec), outunits,
						eg_examples(eg_rec), arrayfn) -> outarray;

#_IF DEF NEURAL_CONTINUOUSDATA
	;;; if we have continuous data then currently we need to convert
	;;; it to 2D !
	if continuous_p then
		check_2d_array(eg_out_data, arrayfn, eg_rec, outunits);
	endif;


	;;; if the data is continuous then eg_in_units contains the stepsize
	;;; (usually the same as the number of input sequences). This has to be
	;;; left on the stack before calling the apply procedure.
	if continuous_p then
		inunits;
	endif;
#_ENDIF

    ;;; get the appropriate function and do the training
    apply(data, machine, outarray, nn_net_apply_set_fn(dataword(machine)));

	;;; once the training has been completed, convert the results
	;;; back to real data
    outarray -> eg_out_data(eg_rec);
	unless eg_rawdata_out(eg_rec) then
		if egs_to_file(eg_rec) then
			unparse_egs_to_file(eg_out_data, eg_rec)
		elseif egs_to_file(eg_rec) then
			unparse_egs_to_proc(eg_out_data, eg_rec)
		elseif egs_to_literal(eg_rec) then
			unparse_egs_to_struct(eg_out_data, eg_rec)
		elseif egs_to_egs(eg_rec) then
			unparse_egs_to_egs(eg_out_data, eg_rec);
		endif;
	    unless eg_keep_egs(eg_rec) then
	        ;;; free any high-level items which may have been left over
	        ;;; from unparsing the data
			false -> eg_out_examples(eg_rec);
	    endunless;
	endunless;
enddefine;


;;; nn_test_egs applies all the inputs of the example set
;;; to the net and then returns the results as a list of lists.
;;; If show_targ is true then the hd of the list is the list of
;;; actual results and the tl is the list of desired results
;;;
define global nn_test_egs(egsname, netname, show_targ) -> result_list;
lvars item i result, show_targ, egsname netname outunits
      result_list = [], targ_list = [], eg_rec;

	;;; get the example set record
	nn_example_sets(egsname) -> eg_rec;

	;;; check the name was valid
	unless eg_rec then
		mishap(egsname, 1, err(NOSU_EG));
	endunless;

	;;; call nn_apply_egs
	nn_apply_egs(egsname, netname);

	if eg_rawdata_out(eg_rec) or not(eg_out_examples(eg_rec)) then
        if show_targ then
            [^(eg_out_data(eg_rec)) ^(eg_targ_data(eg_rec))]
		else
            eg_out_data(eg_rec)
        endif -> result_list;
	else
        if show_targ then
			if eg_targ_examples(eg_rec) then
            	[%eg_out_examples(eg_rec), eg_targ_examples(eg_rec)%]
			else
				;;; not a very pleasant way but need to ensure that an
				;;; appropriate list structure is returned
            	[%eg_out_examples(eg_rec),
					initl(length(eg_out_examples(eg_rec)))%]
			endif
		else
            eg_out_examples(eg_rec)
        endif -> result_list;
	endif;
enddefine;


;;; nn_result_diffs takes a example set and a network and returns
;;; a list of indices in the example set of the results which
;;; are different. If the lists are of different length then
;;; the empty list is returned.
define global nn_result_diffs(actual, target) -> diffs;
lvars target actual diffs = [], index;
	if (islist(actual) or isvector(actual))
	  and (islist(target) or isvector(target)) then
        if length(actual) == length(target) then
            for index from 1 to length(actual) do
                if target(index) /= actual(index) then
                    index :: diffs -> diffs;
                endif;
            endfor;
            ncrev(diffs) -> diffs;
        else
      		[] -> diffs;
        endif;
	elseif isarray(actual) and isarray(target) then
		;;; do nothing for arrays (yet)
      	[] -> diffs;
	else
      	[] -> diffs;
	endif;
enddefine;


;;; nn_result_accuracy takes a example set and a network and returns
;;; how accurately a network responds to a given example set. If the output
;;; of the network is not defined (e.g. for a competitive learning network)
;;; then the accuracy is returned as 100.0.
;;;
define global nn_result_accuracy(egs, net) -> acc;
lvars egs net target actual targ act agree = 0;
    nn_test_egs(egs, net, true) -> actual;
    actual(1), actual(2) -> target -> actual;
    length(actual) - length(nn_result_diffs(actual, target)) -> agree;
    number_coerce(agree / length(actual), 1.0s0) -> acc;
enddefine;


;;; nn_result_error takes an example set and returns
;;; how accurately a network responded to the given example set. If the output
;;; of the network is not defined (e.g. for a competitive learning network)
;;; then the error is returned as 0.0
define global nn_result_error(egs) -> egerr;
lvars item targs vec actual targs egerr = 0.0, eglen, eg, subtotal egs
	  a_bounds t_bounds;

    if isword(egs) then
        nn_example_sets(egs) -> egs;
    endif;
    eg_out_data(egs) -> actual;
    eg_targ_data(egs) -> targs;
    if isarray(targs) and
	  (boundslist(actual) ->> a_bounds) = (boundslist(targs) ->> t_bounds) then

		if length(a_bounds) == 4 then
			;;; discrete data
            initv(a_bounds(4)) -> vec;    			;;; number of examples
            a_bounds(2) -> eglen;         			;;; number of output units
            fast_for eg from 1 to length(vec) do    ;;; for each example output
                0.0 -> subtotal;
                fast_for item from 1 to eglen do
                    (targs(item, eg) - actual(item, eg)) ** 2
                        + subtotal -> subtotal;
                endfast_for;
                subtotal / 2.0 -> fast_subscrv(eg, vec);
                fast_subscrv(eg, vec) + egerr -> egerr;
            endfast_for;
            vec -> eg_error(egs);
		else
            initv(a_bounds(2)) -> vec;    ;;; number of examples
            fast_for item from 1 to length(vec) do
                ((targs(item) - actual(item)) ** 2) / 2.0
										-> fast_subscrv(item, vec);
            	fast_subscrv(item, vec) + egerr -> egerr;
            endfast_for;
            vec -> eg_error(egs);
		endif;
    endif;
enddefine;

endsection;		/* $-popneural */

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 21/9/93
	Removed dlocal of -eg_keep_egs- flag to true in nn_test_egs.
	Behaviour of nn_test_egs if results are not converted (if -eg_keep_egs-
		is false) is the same as if raw data is being used.
	Added checking in nn_result_diffs so that only lists and vectors are
		handled.
-- Julian Clinton, 7/9/93
	Fixed bug in nn_test_egs which causes a mishap 'ILLEGAL ITEM FOR
		datalength' when eg_keep_egs flag is false.
-- Julian Clinton, 29/1/93
	Made unparse_discrete_files strip out the extra layer of listing
		padding before returning each example.
-- Julian Clinton, 21/8/92
	Renamed -eg_applyfn- to -eg_apply_params-.
-- Julian Clinton, 14/8/92
	Moved nn_delete_net out of this file into nn_newnets.p
-- Julian Clinton, 12/8/92
	#_IF'd out the support for continuous data.
-- Julian Clinton, 2/7/92
	-nn_apply_egs- no longer returns a result.
-- Julian Clinton, 23/6/92
	Removed redundant checks for words before tests of -isneuralnet- and
		-isexampleset-.
-- Julian Clinton, 22/6/92
	Moved -nn_apply_example- in here from nn_examplesets.p
-- Julian Clinton, 19/6/92
    nn_delete_net now assigns false to nn_current_net if the deleted
	network is current.
-- Julian Clinton, 10/6/92
	Renamed eg_out_info and eg_targ_info to eg_out_examples and
	eg_targ_examples.
    Modified mishaps.
-- Julian Clinton, 8/5/92
    Sectioned.
*/
