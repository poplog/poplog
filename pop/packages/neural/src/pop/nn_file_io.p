/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:           $popneural/src/pop/nn_file_io.p
 > Purpose:        neural net file I/O procedures
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:
 */

section $-popneural =>  nn_save_net
                        nn_load_net
                        nn_load_egs
                        nn_save_egs
                        nn_load_dt
                        nn_save_dt
                        nn_logscreen
                        nn_logfile
;

uses netfileutil;
include sysdefs;

/* ----------------------------------------------------------------- *
    File System Information
 * ----------------------------------------------------------------- */


#_IF DEF UNIX
lconstant isdirectory = sysisdirectory; ;;; use system definition

#_ELSE	/* VMS */
define lconstant isdirectory(path); /* -> boolean */
	lvars path;

	define dlocal prmishap(str, list);
		lvars str, list;
		exitfrom(false, isdirectory)
	enddefine;

	dlocal current_directory = path;
	true
enddefine;
#_ENDIF


define /* constant */ get_directories_list(directory) -> dirs;
lconstant dir_match_list =
#_IF DEF UNIX
	                       	['*' '.*']
#_ELSE
							['*.dir']
#_ENDIF
;
lvars directory dir_pattern suffix dirs = [], name
      repeater;

	unless directory then
		current_directory -> directory;
	endunless;

#_IF DEF UNIX
	;;; ensure a trailing '/'
	directory dir_>< '/' -> directory;
#_ENDIF


 	[% for dir_pattern in dir_match_list do
	    sys_file_match(directory, dir_pattern, false, true) -> repeater;
        if repeater() /== termin then
	        erase();
	        until (repeater() ->> name) == termin do
	            if name
#_IF DEF UNIX
				  and isdirectory(directory dir_>< name)
#_ENDIF
				then
		            name
	            endif;
		    enduntil;
        endif;
	endfor %] -> dirs;
enddefine;


define /* constant */ get_files_list(directory, fspec) -> files;
lvars directory suffix files = [], name
      repeater;

	unless directory then
		current_directory -> directory;
	endunless;

#_IF DEF UNIX
	;;; ensure a trailing '/'
	directory dir_>< '/' -> directory;
#_ENDIF

	sys_file_match(directory, fspec, false, true) -> repeater;

    if repeater() /== termin then
	    erase();
	    [% until (repeater() ->> name) == termin do
			    if name and not(sysisdirectory(directory dir_>< name)) then
				    name
			    endif;
		enduntil %] -> files;
    endif;
enddefine;


define /* constant */ saved_object_names(directory, fspec) -> fnames;
lvars fspec flist fname fnames;

	get_files_list(directory, fspec) -> flist;
	[% fast_for fname in flist do
		consword(sys_fname_nam(fname));
	endfast_for %] -> fnames;
	sys_grbg_list(flist);
enddefine;


/* ----------------------------------------------------------------- *
    Neural Net Load And Save
 * ----------------------------------------------------------------- */

define global constant nn_save_net(netname) /* -> result */;
    lvars netname sfile, file network;

    if isstring(netname) then
        netname -> sfile -> netname;
    else
        netname -> sfile;
    endif;

    nn_neural_nets(netname) -> network;

    if isstring(sfile) then
        sysfileok(sfile);
    elseif isword(sfile) then
        sysfileok(sfile >< '.net');
    endif -> file;
    apply(file, network, nn_net_save_fn(dataword(network)));
enddefine;


define global constant nn_load_net(netname) /* -> result */;
lvars netname nettype lfile file name dev;

    dlocal prmishap =
         procedure;
	        if isdevice(dev) and not(isclosed(dev)) then
    	        sysclose(dev);
        	endif;
			sysprmishap();
         endprocedure;

    if isstring(netname) then
        netname -> lfile -> netname;
    else
        netname -> lfile;
    endif;

    if isstring(lfile) then
        sysfileok(lfile);
    elseif isword(lfile) then
        sysfileok(lfile >< '.net');
    endif -> file;

    sysopen(file,0,true) -> dev;
    rdvarstring(dev) -> name;   ;;; name should be a string of
                                ;;; recordclass followed by '\n' e.g.
                                ;;; 'bpropnet\n'

    consword(erase(explode(name)), length(name) - 1)
        -> nettype;  ;;; turn it into a word

    apply(dev,nn_net_load_fn(nettype))
        ->> nn_neural_nets(netname);
   	netname -> nn_current_net;
enddefine;


/* ----------------------------------------------------------------- *
    Example Set Load And Save
 * ----------------------------------------------------------------- */

lconstant egs_attr_vals =   [ [discrete ^(ident eg_default_discrete)]
                              [use_in_lines ^(ident eg_default_use_in_lines)]
                              [in_lines ^(ident eg_default_in_lines)]
                              [keep_egs ^(ident eg_default_keep_egs)]
                              [gen_output ^(ident eg_default_gen_output)]
                              [rawdata_in ^(ident eg_default_rawdata_in)]
                              [rawdata_out ^(ident eg_default_rawdata_out)]];

lconstant egs_attribute_accessors = writeable assoc(egs_attr_vals);
lconstant n_egs_attributes = length(egs_attr_vals);

;;; load_egs_flags loads the examle set flags from the example set file.
;;; If something goes wrong, procedure returns false, otherwise a
;;; value for the flags slot. The system works by dlocaling the
;;; default flags and then modifying it using the attributes
;;;
define load_egs_flags(get_val) -> flags;
dlocal EG_DEFAULTS;
lvars get_val attribute update_ident val n_flags;

	get_val() -> n_flags;
	repeat n_flags times
		get_val() -> attribute;
		if (egs_attribute_accessors(attribute) ->> update_ident) then
		    get_val() -> val;
		    if val == "yes" then
			    true
		    else
			    false
			endif -> idval(update_ident);
		else
			false -> flags;
			return();
		endif;
	endrepeat;
	EG_DEFAULTS -> flags;
enddefine;


;;; save_egs_flags saves the examle set flags from the example set file.
;;; File format for egs flags is:
;;;
;;; <n> [<attribute> yes|no]
;;;
define save_egs_flags(put_val, flags);
dlocal EG_DEFAULTS = flags;
lvars put_val flags;

    define lconstant save_flag(identifier, accessor);
	lvars identifier accessor;

		put_val(identifier);
		put_val(space);
		if idval(accessor) then
			put_val("yes")
		else
			put_val("no")
		endif;
		put_val(newline);
	enddefine;

	put_val("flags"); put_val(newline);
	put_val(n_egs_attributes); put_val(newline);
	appassoc(egs_attribute_accessors, save_flag);
enddefine;


;;; nn_load_egs takes an example set name and an optional filename
;;; string. It saves the contents of the example set (excluding the
;;; low-level data) to disk.
define global constant nn_load_egs(egsname) -> loaded;
dlocal popnewline = false;	;;; just in case
lvars egsname lfile egstemplate fielddata subdata flags = false,
	  data_source file dev egsrec getitem i j loaded = false, egsdata
	  data_dest dest_info;

dlocal prmishap =
    procedure();
        if isdevice(dev) and not(isclosed(dev)) then
            sysclose(dev);
        endif;
		sysprmishap();
    endprocedure;

	;;; reads and returns items as lists of lists
	define lconstant load_2d_list_data() -> newlist;
	lvars newlist;
        getitem() -> fielddata;
        initl(fielddata) -> newlist;
        fast_for i from 1 to fielddata do
            getitem() -> subdata;
            initl(subdata) -> newlist(i);
            fast_for j from 1 to subdata do
                getitem() -> newlist(i)(j);
            endfast_for;
        endfast_for;
	enddefine;

	;;; reads and returns items as a list
	define lconstant load_1d_list_data() -> newlist;
	lvars newlist;
        getitem() -> fielddata;
        initl(fielddata) -> newlist;
        fast_for i from 1 to fielddata do
            getitem() -> newlist(i);
        endfast_for;
	enddefine;

    if isstring(egsname) then
        egsname -> lfile -> egsname;
    else
        egsname -> lfile;
    endif;

    if isstring(lfile) then
		sysfileok(lfile)
    elseif isword(lfile) then
        sysfileok(lfile >< '.egs');
    endif -> file;

    if isword(egsname) then
        sysopen(file, 0, true) -> dev;
        unless dev then
            mishap('File does not exist', [^file]);
        endunless;
        incharitem(discin(dev)) -> getitem;
        unless getitem() == "exampleset" then
            sysclose(dev);
            mishap('Not an example set file', [^file]);
        endunless;

        getitem() -> fielddata;
        initl(fielddata) -> egstemplate;
        fast_for i from 1 to fielddata do
            [% getitem(); getitem(); getitem(); %] -> egstemplate(i);
        endfast_for;
        getitem() -> fielddata;

		;;; fielddata should tell us what (if any) data was saved with the
		;;; example set.
		if fielddata == "array" or fielddata == "list" then
			;;; old file format
            if fielddata == "array" then
                dev -> devarrvec(egsdata);
            else 	;;; must be a list of lists
			    load_2d_list_data() -> egsdata;
			endif;
			EG_LITERAL -> data_source;
			EG_LITERAL -> data_dest;
			false -> dest_info;
			eg_default_flags -> flags;
		else
			;;; New file format....
		    ;;; check if we have any data flags saved (optional
			;;; so need to read the next item from the file)
		    if fielddata == "flags" then
			    load_egs_flags(getitem) -> flags;
			    unless flags then
				    mishap('error reading flags', []);
			    endunless;

				getitem() -> fielddata;
		    endif;

			if fielddata /== "datasource" then
				mishap(fielddata, 1, 'unexepected item (expecting "datasource")');
			else
				getitem() -> fielddata;
			endif;

            if fielddata == "array" then
                dev -> devarrvec(egsdata);
			    EG_LITERAL -> data_source;
            elseif fielddata == "list" then
			    load_2d_list_data() -> egsdata;
			    EG_LITERAL -> data_source;
        	elseif fielddata == "file" then
				;;; should have a list of file specifiers
				load_1d_list_data() -> egsdata;
				EG_FILE -> data_source;
            elseif fielddata == "proc" then
			    ;;; procedure name
			    getitem() -> egsdata;
			    EG_PROC -> data_source;
            elseif fielddata == "egs" then
			    ;;; exampleset name
			    getitem() -> egsdata;
			    EG_EGS -> data_source;
			endif;

			getitem() -> fielddata;

			if fielddata /== "datadestination" then
				mishap(fielddata, 1,
						'unexepected item (expecting "datadestination")');
			else
				getitem() -> fielddata;
			endif;

            if fielddata == "array" then
                dev -> devarrvec(dest_info);
			    EG_LITERAL -> data_dest;
            elseif fielddata == "list" then
			    load_2d_list_data() -> dest_info;
			    EG_LITERAL -> data_dest;
        	elseif fielddata == "file" then
				;;; should have a list of file specifiers
				load_1d_list_data() -> dest_info;
				EG_FILE -> data_dest;
            elseif fielddata == "proc" then
			    ;;; procedure name
			    getitem() -> dest_info;
			    EG_PROC -> data_dest;
            elseif fielddata == "egs" then
			    ;;; example set name
			    getitem() -> dest_info;
			    EG_EGS -> data_dest;
			endif;

        endif;
        sysclose(dev);
        nn_make_egs(egsname, egstemplate, data_source, egsdata,
					data_dest, dest_info, flags);
        egsname -> nn_current_egs;
        (isexampleset(egsname) /== false) -> loaded;
    endif;
enddefine;


;;; The following routines are used to save the data source and target
;;; information. These are currently structures (arrays or lists),
;;;	files or procedures
;;;


define save_file_info(put_val, files);
dlocal pop_pr_quotes = false;
lvars put_val files i;
    put_val('file\n');
    put_val(length(files));
    put_val('\n');
	true -> pop_pr_quotes;
	fast_for i from 1 to length(files) do
		put_val(files(i));
		put_val(newline);
	endfast_for;
	false -> pop_pr_quotes;
enddefine;


define save_struct_info(put_val, dev, struct);
dlocal pop_pr_quotes = false;
lvars put_val dev struct i j;

    if isarray(struct) then
        put_val('array\n');
        devarrvec(dev, struct);
    else
        put_val('list\n');
		if struct and (struct /== []) then
            put_val(length(struct));
            put_val('\n');
            fast_for i from 1 to length(struct) do
                put_val(length(struct(i)));
                put_val(space);
		        true -> pop_pr_quotes;
                fast_for j from 1 to length(struct(i)) do
                    put_val(struct(i)(j));
                    put_val(space);
                endfast_for;
		        false -> pop_pr_quotes;
                put_val('\n');
            endfast_for;
		else
			put_val(0);
			put_val(newline);
		endif;
	endif;
enddefine;

define save_proc_info(put_val, proc, name);
lvars put_val proc i name;
    put_val('proc\n');
	if isword(proc) then
		put_val(proc);
	elseif isprocedure(proc) then
		if isword(pdprops(proc)) then
			put_val(pdprops(proc));
		endif;
	else
		sysprmessage(0,
			sprintf(name, proc,
					'Cannot save %p in example set %p'),
			'Warning :', 1);
		put_val("identfn");
	endif;
	put_val(newline);
enddefine;

define save_egs_info(put_val, egsname);
lvars put_val egsname;
    put_val('egs\n');
	put_val(egsname);
	put_val(newline);
enddefine;

;;; nn_save_egs takes an egsname and an optional filename. The format
;;; is:
;;;		exampleset
;;;		<template-length>
;;;		<direction> <datatype> <fieldname>
;;;		<direction> <datatype> <fieldname>
;;;		...
;;;		flags <n-flags> <flag1> [yes|no] <flag2> [yes|no]
;;;		datasource [file|proc|array|list]
;;;
define global constant nn_save_egs(egsname) -> saved;
lvars egsname sfile egsfield data_source data_dest file dev egsrec putitem i j
      saved = false;
dlocal pop_pr_quotes = false;
dlocal prmishap =
    procedure();
        if isdevice(dev) and not(isclosed(dev)) then
            sysclose(dev);
        endif;
		sysprmishap();
    endprocedure;

    if isstring(egsname) then
        egsname -> sfile -> egsname;
    else
        egsname -> sfile;
    endif;

    if isstring(sfile) then
        sysfileok(sfile);
    elseif isword(sfile) then
        sysfileok(sfile >< '.egs');
    endif -> file;

    if isword(egsname)
      and (nn_example_sets(egsname) ->> egsrec) then
        syscreate(file, 1, true) -> dev;
        outcharitem(discout(dev)) -> putitem;
        putitem('exampleset\n');
        eg_template(egsrec) -> egsfield;

		;;; first comes the template
        putitem(length(egsfield));
        putitem('\n');
        fast_for i from 1 to length(egsfield) do
			true -> pop_pr_quotes;
            putitem(egsfield(i)(1));
            putitem(space);
            putitem(egsfield(i)(2));
            putitem(space);
            unless length(egsfield(i)) < 3 then
                putitem(egsfield(i)(3));
            else
                putitem(consword('field_' sys_>< i));
            endunless;
			false -> pop_pr_quotes;
            putitem('\n');
        endfast_for;

		;;; now save the example set flags
		save_egs_flags(putitem, eg_flags(egsrec));

		;;; save the data source info
		eg_data_source(egsrec) -> data_source;
		putitem('datasource\n');
		if data_source == EG_LITERAL then
			;;; save the data structure
            eg_gendata(egsrec) -> egsfield;
			save_struct_info(putitem, dev, egsfield);

		elseif data_source == EG_FILE then
			;;; save the list of files (remembering to set
			;;; pop_pr_quotes to true)
			eg_gen_params(egsrec) -> egsfield;		;;; get the files list
			save_file_info(putitem, egsfield);

		elseif data_source == EG_PROC then
			eg_gen_params(egsrec) -> egsfield;	;;; get the procedure
			save_proc_info(putitem, egsfield, eg_name(egsrec));

		elseif data_source == EG_EGS then
			eg_gen_params(egsrec) -> egsfield;	;;; get the example set name
			save_egs_info(putitem, egsfield);

        endif;

		;;; now the data destination info
		eg_data_destination(egsrec) -> data_dest;
		putitem('datadestination\n');

		if data_dest == EG_LITERAL then
			;;; save the data structure
            eg_apply_params(egsrec) -> egsfield;
			save_struct_info(putitem, dev, egsfield);

		elseif data_dest == EG_FILE then
			;;; save the list of files (remembering to set
			;;; pop_pr_quotes to true)
			eg_apply_params(egsrec) -> egsfield;		;;; get the files list
			save_file_info(putitem, egsfield);

		elseif data_dest == EG_PROC then
			eg_apply_params(egsrec) -> egsfield;	;;; get the procedure
			save_proc_info(putitem, egsfield, eg_name(egsrec));

		elseif data_dest == EG_EGS then
			eg_apply_params(egsrec) -> egsfield;	;;; get the example set name
			save_egs_info(putitem, egsfield);

        endif;

        putitem(termin);
        (sysfilesize(file) /== 0) -> saved;
    endif;
enddefine;


/* ----------------------------------------------------------------- *
    Datatypes Load And Save
 * ----------------------------------------------------------------- */

define load_simple_dt(get_val, dev, name, type);
lvars get_val dev name type smembers = [],
	  num lowval highval trueval falseval items units inc outc;

    if type == "set" then
        get_val() -> num;
		[% repeat num times
            get_val();
        endrepeat; %] -> smembers;
		get_val() -> num;
		unless isnumber(num) then
			false -> num;
		endunless;
        sysclose(dev);
        nn_declare_set(name, smembers, num);

    elseif type == "range" then
        get_val() -> lowval;
        get_val() -> highval;
        sysclose(dev);
        nn_declare_range(name, lowval, highval);

    elseif type == "toggle" then
		get_val() ->;		;;; ignore these for the time being...
        get_val() -> trueval;
		get_val() ->;       ;;; ...as these are for future expansion
        get_val() -> falseval;
        sysclose(dev);
        nn_declare_toggle(name, trueval, falseval);

    elseif type == "general" then
    	get_val() -> items;
    	get_val() -> units;
    	get_val() -> inc;
    	get_val() -> outc;
        sysclose(dev);
        nn_declare_general(name, [^items ^units], inc, outc);
        if inc == "undef" or outc == "undef" then
            warning('datatype declared with undefined converter functions',
                    [^name]);
        endif;
	endif;
enddefine;


define load_field_dt(get_val, dev, name, type);
lvars get_val dev name setname type n_items items attr val
	  starter = false, ender = false, separator = false,
	  units inc outc;

    if is_seq_field_dt(type) then
		;;; get number of items
		get_val() -> n_items;

		;;; and read them
		[% repeat n_items times
			get_val();
		endrepeat %] -> items;
		sysclose(dev);
		nn_declare_field_format(name, items);

    elseif is_choice_field_dt(type) then
		;;; choice for which set
		get_val() -> setname;

		;;; how many pairs of starter/ender/separator...
		get_val() -> n_items;

		;;; ...and load them from disk
		repeat n_items times
			get_val() -> attr;
			get_val() -> 	if attr == "Start" then
                         		starter
							elseif attr == "End" then
								ender
							elseif attr == "Sep" then
								separator
							endif;
		endrepeat;
		sysclose(dev);
		nn_declare_field_format(name, setname, starter, ender, separator);

	endif;
enddefine;


define load_file_dt(get_val, dev, name, type);
lvars get_val dev name type n_items values rname;

	if is_char_file_dt(type) or is_item_file_dt(type) then
		;;; how many datatypes
		get_val() -> n_items;

		;;; list of datatypes
		[% repeat n_items times
			get_val();
		endrepeat %] -> values;
		sysclose(dev);
		nn_declare_file_format(name, values, type);

	elseif is_line_file_dt(type) or is_full_file_dt(type) then
		;;; datatype name
		get_val() -> rname;

		;;; size of byte-structure
		get_val() -> n_items;

		sysclose(dev);
		nn_declare_file_format(name, rname, n_items, type);
	else
		sysclose(dev);
	endif;
enddefine;


define global constant nn_load_dt(dtname) -> loaded;
lvars dtname dtentry dtype lfile file dev getitem loaded = false;

dlocal prmishap =
    procedure();
        if isdevice(dev) and not(isclosed(dev)) then
            sysclose(dev);
        endif;
		sysprmishap();
    endprocedure;

    if isstring(dtname) then
        dtname -> lfile -> dtname;
    else
        dtname -> lfile;
    endif;

    if isstring(lfile) then
        sysfileok(lfile);
    elseif isword(lfile) then
        sysfileok(lfile >< '.dt');
    endif -> file;

    sysopen(file, 0, true) -> dev;
    unless dev then
        mishap('File does not exist', [^file]);
    endunless;
    incharitem(discin(dev)) -> getitem;
    getitem() -> dtype;

	if is_simple_dt(dtype) then
		load_simple_dt(getitem, dev, dtname, dtype);

	elseif is_field_dt(dtype) then
		load_field_dt(getitem, dev, dtname, dtype);

	elseif is_file_dt(dtype) then
		load_file_dt(getitem, dev, dtname, dtype);

    else
        sysclose(dev);
        mishap('Unknown datatype', [^dtype]);
    endif;
    (isdatatype(dtname) /== false) -> loaded;
    dtname -> nn_current_dt;
enddefine;


;;;
;;; Datatypes always start with the type of the datatype. What comes next
;;; depends on the datatype:
;;;
;;; set: <set-length> set-item1 set-item2 ....   threshold (if non-false)
;;; range: lowerbound upperbound
;;; toggle: <n-true-vals> true_val1 ... <n-false-vals> false_val1 ...
;;; seq: <sequence-length> seq-item1 seq-item2 ...
;;; choice: set-name <n-pairs> [starter <item>|ender <item>|separator <item>]
;;; pattern: <n_items> <n_units> in_procname out_procname
;;; general: <n_items> <n_units> in_procname out_procname
;;; char and item: <n_items> datatype1 datatype2 ...
;;; line and file: <recipient-datatype> <size-of-byte-struct>
;;;
;;; Note that the actual disk file will have linefeeds to make it a little
;;; more readable. This shouldn't affect anything (so long as popnewline
;;; is false).
;;;

define save_general_dt(put_val, dt_rec, type);
lvars put_val dt_rec type proc proclist;
	put_val(nn_items_needed(dt_rec));
	put_val('\n');
	put_val(nn_units_needed(dt_rec));
	put_val('\n');
	for proc in [^(nn_dt_inconv(dt_rec)) ^(nn_dt_outconv(dt_rec))] do
	    if isprocedure(proc) then
    	    if pdprops(proc) then
        	    put_val(pdprops(proc));
        	    put_val('\n');
    	    else
        	    put_val('undef\n');
    	    endif;
	    else
    	    put_val(proc);
    	    put_val('\n');
	    endif;
	endfor;
enddefine;


define save_field_dt(put_val, dt_rec, type);
dlocal pop_pr_quotes;
lvars dt_rec put_val type len i list item;
	put_val(type);
	put_val(newline);
    if is_seq_field_dt(type) then
		nn_dt_inconv(dt_rec) -> list;
		put_val(length(list));
		put_val(newline);
		true -> pop_pr_quotes;
		for item in list do
			put_val(item);
			put_val(newline);
		endfor;
    elseif is_choice_field_dt(type) then
		;;; choice for which set
		put_val(nn_dt_field_choiceset(dt_rec));
		put_val(newline);

		;;; get any starter, ender or separator items
		[% 	if (nn_dt_field_starter(dt_rec) ->> item) then
				"Start", item;
		 	endif;
			if (nn_dt_field_ender(dt_rec) ->> item) then
				"End", item;
		 	endif;
			if (nn_dt_field_separator(dt_rec) ->> item) then
				"Sep", item;
		 	endif %] -> list;
		length(list) -> len;

		;;; how many pairs...
		put_val(len div 2);
		put_val(newline);
		;;; ...and save them to disk
		for i from 1 by 2 to len - 1 do
		    put_val(list(i)); put_val(space);
		    put_val(list(i + 1)); put_val(newline);
		endfor;
	endif;
enddefine;


define save_file_dt(put_val, dt_rec, type);
lvars dt_rec put_val type recipient dts item len;
	put_val(type);
	put_val(newline);
	if is_char_file_dt(type) or is_item_file_dt(type) then
		nn_dt_file_datatypes(dt_rec) -> dts;
		length(dts) -> len;
		;;; how many datatypes
		put_val(len); put_val(newline);
		;;; list of datatypes
		repeat len times
			dest(dts) -> dts -> item;
			put_val(item); put_val(newline);
		endrepeat;
	elseif is_line_file_dt(type) or is_full_file_dt(type) then
		;;; datatype name
		put_val(nn_dt_file_recipient(dt_rec)); put_val(newline);
		;;; size of byte-structure
		put_val(length(nn_dt_file_in_bytestruct(dt_rec))); put_val(newline);
	endif;
enddefine;


define global constant nn_save_dt(dtname) -> saved;
	lvars dtname dt_record i smembers dtype sfile proc
      	file dev putitem
      	saved = false, key, dword, dester;
	dlocal pop_pr_quotes = false;
	dlocal prmishap =
    	procedure();
    		if isdevice(dev) and not(isclosed(dev)) then
        		sysclose(dev);
    		endif;
			sysprmishap();
		endprocedure;

	if isstring(dtname) then
    	dtname -> sfile -> dtname;
	else
    	dtname -> sfile;
	endif;

	if isstring(sfile) then
    	sysfileok(sfile);
	elseif isword(sfile) then
    	sysfileok(sfile >< '.dt');
	endif -> file;

	if isword(dtname) and (nn_datatypes(dtname) ->> dt_record) then
    	nn_dt_type(dt_record) -> dtype;
    	syscreate(file, 1, true) -> dev;
    	unless dev then
        	mishap('Cannot create file', [^file]);
    	endunless;
    	outcharitem(discout(dev)) -> putitem;
    	if dtype == "set" then
        	putitem('set\n');
        	nn_dt_setmembers(dt_record) -> smembers;
        	putitem(length(smembers));
        	putitem('\n');
        	for i from 1 to length(smembers) do
				true -> pop_pr_quotes;		;;; preserve string quotes
            	putitem(smembers(i));
				false -> pop_pr_quotes;
            	putitem('\n');
        	endfor;
			if isnumber(nn_dt_setthreshold(dt_record)) then
				putitem(nn_dt_setthreshold(dt_record));
           		putitem('\n');
			endif;
    	elseif dtype = "range" then
        	putitem('range\n');
        	putitem(nn_dt_lowerbound(dt_record));
        	putitem('\n');
        	putitem(nn_dt_upperbound(dt_record));
        	putitem('\n');
    	elseif dtype = "toggle" then
        	putitem('toggle\n');
			putitem(1);				;;; this is for future expansion
			putitem(space);
        	putitem(nn_dt_toggle_true(dt_record));
        	putitem('\n');
			putitem(1);				;;; and so is this
			putitem(space);
        	putitem(nn_dt_toggle_false(dt_record));
        	putitem('\n');
    	elseif dtype = "general" then
        	putitem('general\n');
			save_general_dt(putitem, dt_record, dtype);
		elseif is_field_dt(dtype) then
			save_field_dt(putitem, dt_record, dtype);
		elseif is_file_dt(dtype) then
			save_file_dt(putitem, dt_record, dtype);
    	else
        	putitem(termin);
        	mishap('Unknown datatype', [^dtype]);
    	endif;
    	putitem(termin);
	endif;
	(sysfilesize(file) > 0) -> saved;
enddefine;


/* ----------------------------------------------------------------- *
    Logging Information
 * ----------------------------------------------------------------- */

define global nn_logscreen();
dlocal pop_pr_places = 4;
lvars acc;
    if logecho then
        npr(';;; Date            : ' sys_>< sysdaytime());
        npr(';;; Network         : ' sys_>< nn_current_net sys_><
            ', Example Set : ' sys_>< nn_current_egs);
        npr(';;; Training cycles : ' sys_>< nn_iterations);
    endif;
    if logaccuracy then
        nn_result_accuracy(nn_current_egs, nn_current_net) -> acc;
        acc * 100.0 -> acc;
        npr(';;; Accuracy        : ' sys_>< acc sys_>< '%');
    endif;
    if logerror then
        nn_result_error(nn_current_egs) -> acc;
        npr(';;; Error           : ' sys_>< acc);
    endif;
    nl(1);
enddefine;

define global nn_logfile();
lvars i, outdev, acc, egsrec, netfile = gensym(nn_current_net) sys_>< '.net';
dlocal pop_pr_places = 2,
       prmishap =
         procedure;
             outdev(termin);
             sysprmishap();
         endprocedure;

    outcharitem(discappend(logfilename)) -> outdev;
    outdev(';;; ------------------------------------------------\n');
    outdev(';;; Poplog-Neural logfile ' sys_>< logfilename sys_>< ' opened.\n');
    outdev(';;; Date    : ' sys_>< sysdaytime());
    outdev('\n;;; Network : ' sys_>< nn_current_net);
    outdev(', Example Set : ' sys_>< nn_current_egs);
    if isneuralnet(nn_current_net) and isexampleset(nn_current_egs) then
        outdev('\n;;; ------------------------------------------------\n');
        outdev(';;; Number of training cycles : ' sys_>< nn_iterations);
        if logaccuracy then
            nn_result_accuracy(nn_current_egs, nn_current_net) -> acc;
            acc * 100.0 -> acc;
            outdev('\n;;; Response Accuracy         : ' sys_>< acc sys_>< '%');
        endif;
        if logerror then
            nn_result_error(nn_current_egs) -> acc;
            outdev('\n;;; Response Error            : ' sys_>< acc);
        endif;
        nn_example_sets(nn_current_egs) -> egsrec;
        if logtestset then
            unless isunknown(eg_out_units(egsrec)) then
                outdev('\n;;; Input, Output And Target Data:');
                outdev('\n;;; (Note: "-" means output was correct, "X" means output was incorrect)');
                for i from 1 to eg_examples(egsrec) do
                    outdev('\n;;; Example ' sys_>< i);
                    outdev('\n;;;       input  : ');
                    outdev(eg_in_examples(egsrec)(i));
                    if eg_targ_examples(egsrec)(i) =
                        eg_out_examples(egsrec)(i) then
                        outdev('\n;;;   -   output : ');
                    else
                        outdev('\n;;;   X   output : ');
                    endif;
                    outdev(eg_out_examples(egsrec)(i));
                    outdev('\n;;;       target : ');
                    outdev(eg_targ_examples(egsrec)(i));
                endfor;
                outdev('\n;;;');
            else
                outdev('\n;;; Input And Output Data');
                for i from 1 to eg_examples(egsrec) do
                    outdev('\n;;; Example ' sys_>< i);
                    outdev('\n;;;         input: ');
                    outdev(eg_in_examples(egsrec)(i));
                    outdev('\n;;;       output : ');
                    outdev(eg_out_examples(egsrec)(i));
                endfor;
                outdev('\n;;;');
            endunless;
        endif;
        if logsavenet then
            outdev('\n;;; Network saved in ' sys_>< netfile);
        endif;
        outdev('\n;;; ------------------------------------------------\n');
    else
        outdev('\n;;; nn_current_egs or nn_current_net has an illegal value\n');
    endif;
    outdev(';;; Logfile closed.');
    outdev('\n;;; ------------------------------------------------\n\n');
    outdev(termin);
    if logsavenet then
        nn_save_net(nn_current_net, netfile)->;
    endif;
enddefine;

endsection;		/* $-popneural */

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 27/10/93
	Fixed PNF0046 which causes set members to be declared in reverse order.
-- Julian Clinton, 28/8/92
	Added gen_output flag to be save/load egs facilities.
-- Julian Clinton, 21/8/92
	Renamed -eg_genfn- to -eg_gen_params- and -eg_applyfn- to
		-eg_apply_params-.
-- Julian Clinton, 12/8/92
	Removed provisional support for continuous data.
-- Julian Clinton, 30/6/92
	Added file I/O support for new example set facilities.
	Tidied up error handling.
-- Julian Clinton, 26/6/92
	Added support for toggle type.
-- Julian Clinton, 23/6/92
	-nn_save_egs- and -nn_save_dt- now preserve string quotes in sets,
		field names and example data.
-- Julian Clinton, 22/6/92
	Modifed -nn_save_dt- and -nn_load_dt- to check if a threshold has been
		included.
-- Julian Clinton, 10/6/92
	Renamed eg_in_info, eg_out_info and eg_targ_info to eg_in_examples,
		eg_out_examples and eg_targ_examples.
-- Julian Clinton, 8/5/92
    Sectioned.
-- Julian Clinton, 14th Sept. 1990:
    PNE0029 Added variable "logerror" and split checking of error
    	and accuracy
-- Julian Clinton, PNF0023, 30 Aug 1990:
    Changed nn_logfile to convert generated filename to a string
*/
