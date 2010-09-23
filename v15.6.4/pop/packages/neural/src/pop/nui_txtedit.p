/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved ---------
 > File:           $popneural/src/pop/nui_txtedit.p
 > Purpose:        edit procedures
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:
 */

section $-popneural =>  nn_edit_net
                        nn_edit_egs
                        nn_edit_dt
;

pr(';;; Loading edit facilities\n');

uses nui_txtbrowser;
uses nui_txtpanels;

/* ----------------------------------------------------------------- *
    Frozval Accessors
 * ----------------------------------------------------------------- */

define frozval_pos(closure, argument);
lvars closure argument;
    frozval(argument, closure);
enddefine;

define updaterof frozval_pos(val, closure, argument);
lvars val closure argument;
    val -> frozval(argument, closure);
enddefine;


/* ----------------------------------------------------------------- *
    Edit Menu Defs
 * ----------------------------------------------------------------- */

;;; the functions in each menu take the selected net/example set/datatype
;;; and return the item to be edited

constant    bpnet_edit_menu = [ ['Edit Backprop Net'
                                 'learning rate (eta)'
                                 'learning momentum (alpha)']
                                ^bpeta ^bpalpha],

            clnet_edit_menu = [ ['Edit Complearn Net'
                                 'learning rate for winning units'
                                 'learning rate for losing units'
                                 'sensitivity equalisation for winning units'
                                 'sensitivity equalisation for losing units']
                                ^clgw ^clgl ^clrw ^clrl],

            egs_editegs_menu = [ ['Edit Example Set'
                               'Flags'
                               'Example template'
                               'Data source flag'
                               'Source info.'
                               'Example data'
                               'Data destination flag'
                               'Destination info.']
                             edit_egs_flags
                             edit_egs_template
                             edit_egs_source_type
                             edit_egs_source_info
                             edit_egs_examples
                             edit_egs_dest_type
                             edit_egs_dest_info],

            egs_editfile_menu = [ ['Edit Example Set'
                               'Flags'
                               'Example template'
                               'Source file info.'
                               'Example data'
                               'Destination file info.']
                             edit_egs_flags
                             edit_egs_template
                             edit_egs_source_filenames
                             edit_egs_example_file
                             edit_egs_dest_filenames],

            ;;; this menu is used for editing the default values
            ;;; and for the flags in a given examples set (in which
            ;;; case the initial value of EG_DEFAULTS is saved and
            ;;; restored after the example set flags have benn updated).

            egs_editflags_menu =
#_IF DEF NEURAL_CONTINUOUSDATA
                    [% ['Edit Example Set Flags' 50
                       'Discrete examples'
                       'Keep parsed examples'
                       'Generate output fields as target data'
                       'Use raw input data'
                       'Use raw output data'
                       'Use "examples arranged in lines" flag'
                       'Examples arranged in lines'],
                        conspair(ident eg_default_discrete, "boolean"),
                        conspair(ident eg_default_keep_egs, "boolean"),
                        conspair(ident eg_default_gen_output, "boolean"),
                        conspair(ident eg_default_rawdata_in, "boolean"),
                        conspair(ident eg_default_rawdata_out, "boolean"),
                        conspair(ident eg_default_use_in_lines, "boolean"),
                        conspair(ident eg_default_in_lines, "boolean"),
                    %]

#_ELSE      /* Discrete data only */

                    [% ['Edit Example Set Flags' 50
                       'Keep parsed examples'
                       'Generate output fields as target data'
                       'Use raw input data'
                       'Use raw output data'],
                        conspair(ident eg_default_keep_egs, "boolean"),
                        conspair(ident eg_default_gen_output, "boolean"),
                        conspair(ident eg_default_rawdata_in, "boolean"),
                        conspair(ident eg_default_rawdata_out, "boolean"),
                    %]
#_ENDIF
            ,

            rangedt_edit_menu = [ ['Edit Range Type'
                                   'lower bound'
                                   'upper bound']
                                   ^nn_dt_lowerbound
                                   ^nn_dt_upperbound],

            toggledt_edit_menu = [ ['Edit Toggle Type'
                                   'true value'
                                   'false value']
                                   ^nn_dt_toggle_true
                                   ^nn_dt_toggle_false],

            setdt_edit_menu = [ ['Edit Set Type'
                                   'output threshold'
                                   'set members']
                                   edit_setthreshold
                                   ^nn_dt_setmembers],

            generaldt_edit_menu = [ ['Edit General Type'
                                     'input values'
                                     'output values'
                                     'input converter'
                                     'output converter']
                                    ^dt_in_nargs
                                    ^dt_out_nargs
                                    ^nn_dt_inconv
                                    ^nn_dt_outconv];


/* ----------------------------------------------------------------- *
    Utility Functions For Edits
 * ----------------------------------------------------------------- */

;;; txtedit_menuloop takes te item being edited, a menu structure,
;;; a struct editor proc, a list/vector of labels passed to the
;;; struct editor, a list of default types (passed to get_item_default)
;;; and an association/property table which maps word values to
;;; procedures. The procedures must only take a single argument,
;;; the structure being edited.
;;;
define txtedit_menuloop(edit_item, edit_name, menu, struct_editor,
                        edit_list_labels, default_types, assoc_table);
lvars edit_item edit_name menu struct_editor edit_list_labels default_types
        title labels values val newval;
dlocal nn_help;
    destmenu_txt(menu) -> title -> labels -> values;
    menuhelpfiles(title) -> nn_help;
    if edit_name then
        sprintf(edit_name, title, '%p: %p') -> title;
    endif;
    show_menu_txt(title, labels, values, false, true) -> val;
    while val do
        if isprocedure(val) then
            ;;; it must be an accessor function to the structure being
            ;;; edited so obtain the current slot value
            apply(edit_item, val) -> newval;

            ;;; if the slot does not contain a procedure then assume it
            ;;; is a structure of some kind
            if isprocedure(newval) then
                ;;; get the new value
                get_item_default(default_types, 'New value', newval) -> newval;
            elseif islist(newval) or isvectorclass(newval) then
                struct_editor({%newval%}, edit_list_labels);
            else
                get_item_default(default_types, 'New value', newval) -> newval;
            endif;
            newval -> apply(edit_item, val);
        elseif isword(val) and assoc_table(val) then
            apply(edit_item, assoc_table(val));
        endif;
        use_basewindow(true);
        show_menu_txt(title, labels, values, false, true) -> val;
    endwhile;
enddefine;


/* ----------------------------------------------------------------- *
    Edit Functions
 * ----------------------------------------------------------------- */

define nn_edit_net(netname);
lvars netname network menu type;
    if (nn_neural_nets(netname) ->> network) then
        if (nn_net_type(network) ->> type) == "bpropnet" then
            txtedit_menuloop(network, netname, bpnet_edit_menu, false, false,
                            [], false);

        elseif type == "clearnnet" then
            txtedit_menuloop(network, netname, clnet_edit_menu, false, false,
                            [], false);
        endif;
    endif;
enddefine;


;;; edit_egs_flags is used to edit the default flags and also the
;;; flags in the supplied example set. If eg_rec is false then
;;; the routine assumes we are editing the default values.
;;; If eg_rec has been supplied, then its flags are assigned
;;; to EG_DEFAULTS and it is assumed that the caller has dlocal'd
;;; EG_DEFAULTS.
;;;
define edit_egs_flags(eg_rec);
lvars eg_rec title maxwidth labels values result;
dlocal nn_help;
    destpanel_txt(egs_editflags_menu) -> title -> maxwidth -> labels -> values;
    menuhelpfiles(title) -> nn_help;
    if eg_rec then
        ;;; have to refer to EG_DEFAULTS directly rather than the active
        ;;; var
        eg_flags(eg_rec) -> EG_DEFAULTS;
    endif;
    repeat forever
        clear_screen();
        banner(nn_banner);
        show_menu_txt(maxwidth, title, labels, values, true, true) -> result;
        if result then
            change_var(front(result));
        else
            quitloop();
        endif;
    endrepeat;
    if eg_rec then
        eg_default_flags -> eg_flags(eg_rec);
    endif;
enddefine;


;;; -------------------------------------------------------------------
;;;
;;; The next few routines are also used by the top-level to get
;;; the values for data source, destination and other information
;;; required to generate and apply the example set successsfully.
;;;
;;; -------------------------------------------------------------------

;;; get_X_filename prompts the user to obtain a filename which is
;;; either the example file or output file used by the example set
;;;
define get_X_filename(eg_rec, accessor1) -> filename -> ftype;
lconstant titles = {'Filenames'};
lvars eg_rec accessor1 filename ftype = false, filelist all_files
        offset template files_ref;

    accessor1(eg_rec) -> filelist;
    eg_template(eg_rec) -> template;

    if islist(filelist) then
        flatten(filelist) -> filelist;
    endif;

    if isstring(filelist) or
      (islist(filelist) and length(filelist) == 1 and
       (hd(filelist) ->> filelist)) then
        unless (template_filetype(1, template) ->> ftype) then
            DT_ITEM_FILE -> ftype;
        endunless;
        filelist -> filename;

    elseif islist(filelist) then
        ;;; have multiple files so select from them
        {%filelist%} -> files_ref;
        repeat forever
            nn_select_list(files_ref, titles) -> filename;
            if filename then
                index_in_list(filename, filelist) -> offset;
                ;;; assume it's a text file
                DT_ITEM_FILE -> ftype;
                /* template_filetype(offset, template) -> ftype; */
                return();
            else
                return();
            endif;
        endrepeat;
    else
        false ->> filename -> ftype;
        nui_message_txt('No files to select from');
    endif;
enddefine;

global vars procedure
    get_examplefile_name = get_X_filename(%eg_gendata%),
    get_outputfile_name = get_X_filename(%eg_applydata%),
;

define get_data_flag_txt() -> data_flag;
lvars data_flag;
    get_1_item('(file, procedure, exampleset or literal)',
                isdatasource, 'file, procedure, exampleset or literal')
                    -> data_flag;
    isdatasource(data_flag) -> data_flag;
enddefine;


define get_example_X_txt(template, data_flag, filetype_p, org_val)
                                            -> data_flag -> data_info;
lvars template filetype_p input_len org_val title labels values
      field data_flag data_info;

    if filetype_p then      ;;; data has to come from a file
        EG_FILE -> data_flag;
        boldpr(sprintf(length(template),
                'please enter %p filenames (without string quotes).\n'));
        get_strings('File name', length(template)) -> data_info;
    else
        unless data_flag then
            get_data_flag_txt() -> data_flag;
        endunless;

        if org_val then
            boldpr(sprintf(org_val, 'Current value: %p\n'));
        endif;

        if data_flag == EG_FILE then
            boldpr('Please enter filename (without string quotes).\n');
            get_string('File name ? ') -> data_info;

        elseif data_flag == EG_EGS then
            boldpr('Please enter example set name.\n');
            get_1_item('Example set name ? ', isword, 'example set name') -> data_info;

        elseif data_flag == EG_PROC then
            boldpr('Please enter procedure name.\n');
            compile(stringin(get_string('Procedure name ? '))) -> data_info;

        elseif data_flag == EG_LITERAL then
            false -> data_info;
            nui_message_txt('No source information needed for "literal" flag');
        else
            ;;; should never reach this error
            mishap(data_flag, 1, 'Illegal data source/target');
        endif;
    endif;
enddefine;


define get_data_source_txt(template, filetype_p, input_len)
    -> data_source -> data_generator;
lvars template filetype_p input_len data_source data_generator;

    boldpr('Data source: ');
    get_data_flag_txt() -> data_source;

    if data_source == EG_LITERAL then
        if y_or_n_txt('Enter examples now') then
            if input_len then
                npr('Enter examples (each should have ' sys_>< input_len
                    sys_>< ' entries) -');
            endif;
            get_lists(input_len, 'Example', true, false)
        else
            []
        endif -> data_generator;
    else
        get_example_X_txt(template, data_source, filetype_p, false)
                                        -> data_source -> data_generator;
    endif;
enddefine;


;;; get_data_dest_txt is used to get from the user any information
;;; required to send output from the network to the required destination
;;;
define get_data_dest_txt(template, filetype_p) -> data_dest -> dest_info;
lvars template filetype_p title labels values data_dest dest_info
      out_template;

    boldpr('Data destination: ');
    get_data_flag_txt() -> data_dest;
    if data_dest == EG_LITERAL then
        false -> dest_info;
    else
        extract_output_fields(template) -> out_template;
        get_example_X_txt(out_template, data_dest, filetype_p, false)
                                            -> data_dest -> dest_info;
        sys_grbg_list(out_template);
    endif;
enddefine;


define edit_egs_source_type(eg_rec);
lvars eg_rec;
    boldpr(sprintf(word_of_data_source(eg_data_source(eg_rec)),
            'Current data source is "%p" -\n'));
    get_data_flag_txt() -> eg_data_source(eg_rec);
enddefine;

define edit_egs_dest_type(eg_rec);
lvars eg_rec;
    boldpr(sprintf(word_of_data_source(eg_data_destination(eg_rec)),
            'Current data destination is "%p" -\n'));
    get_data_flag_txt() -> eg_data_destination(eg_rec);
enddefine;


;;; edit_egs_source_filenames allows the user to change the filenames given
;;; to the example set which can be expanded
define edit_egs_source_filenames(eg_rec);
lvars eg_rec v_ref;
    nn_edit_list(({%eg_rec.eg_gen_params%} ->> v_ref), {'Filename'});
    v_ref(1) -> eg_gen_params(eg_rec);
enddefine;

;;; edit_egs_dest_filenames allows the user to change the filenames given
;;; to the example set which can be expanded
define edit_egs_dest_filenames(eg_rec);
lvars eg_rec v_ref;
    nn_edit_list(({%eg_rec.eg_apply_params%} ->> v_ref), {'Filename'});
    v_ref(1) -> eg_apply_params(eg_rec);
enddefine;

;;; forward reference
global vars procedure nn_edit_egs;

define edit_egs_example_file(eg_rec);
lvars eg_rec filename source filelist ftype;

    if egs_from_file(eg_rec) and not(eg_rawdata_in(eg_rec)) then
        get_examplefile_name(eg_rec) -> filename -> ftype;
        if filename then
            ;;; now we have the filename, try to work out how to display it
            if is_item_file_dt(ftype) or is_char_file_dt(ftype) then
                vededitor(vedveddefaults, filename);
#_IF DEF XNEURAL
                ;;; if using X then we have to exit at this point otherwise
                ;;; the busy cursor stays on
                if popunderx then
                    exitfrom(nn_edit_egs);
                endif;
#_ENDIF

#_IF DEF PWMNEURAL
                ;;; if using PWM also exit because the PWM does not
                ;;; always react will to VED being fired up
                if popunderpwm then
                    exitfrom(nn_edit_egs);
                endif;
#_ENDIF
            else
                nui_message_txt('Cannot edit this file using VED');
            endif;
        endif;
    else
        nui_message_txt('Cannot access example file');
    endif;
enddefine;


define edit_egs_examples(eg_rec);
lvars eg_rec examples v_ref;
    if egs_from_file(eg_rec) then
        edit_egs_example_file(eg_rec);
    elseif egs_from_literal(eg_rec) then
        eg_rec.eg_gendata -> examples;
        if examples then
            nn_edit_struct(({%eg_rec.eg_gendata%} ->> v_ref), {'Examples'});
            v_ref(1) -> eg_gendata(eg_rec);
        else
            nui_message_txt('No examples available');
        endif;
    else
        nui_message_txt('Cannot edit examples from procedure or example set');
    endif;
enddefine;


define edit_egs_template(eg_rec);
lvars eg_rec v_ref;
    nn_edit_struct(({%eg_rec.eg_template%} ->> v_ref), {'Field info'});
    v_ref(1) -> eg_template(eg_rec);
enddefine;


define edit_egs_source_info(eg_rec);
lvars eg_rec template data_source data_flag data_info;
    eg_data_source(eg_rec) -> data_source;
    eg_template(eg_rec) -> template;
    get_example_X_txt(template, data_source, false, eg_gen_params(eg_rec))
                                        -> data_flag -> data_info;
    data_info -> eg_gen_params(eg_rec);
enddefine;


define edit_egs_dest_info(eg_rec);
lvars eg_rec template data_dest data_flag data_info;
    eg_data_destination(eg_rec) -> data_dest;
    eg_template(eg_rec) -> template;
    get_example_X_txt(template, data_dest, false, eg_apply_params(eg_rec))
                                        -> data_flag -> data_info;
    data_info -> eg_apply_params(eg_rec)
enddefine;


define nn_edit_egs(egsname);
dlocal EG_DEFAULTS;     ;;; need to do this to prevent permanent change
                        ;;; if the user edits the example set flags
lconstant egs_edit_procs = assoc([
                        [edit_egs_flags         ^edit_egs_flags]
                        [edit_egs_template      ^edit_egs_template]
                        [edit_egs_source_type   ^edit_egs_source_type]
                        [edit_egs_examples      ^edit_egs_examples]
                        [edit_egs_example_file  ^edit_egs_example_file]
                        [edit_egs_source_info   ^edit_egs_source_info]
                        [edit_egs_dest_type     ^edit_egs_dest_type]
                        [edit_egs_dest_info     ^edit_egs_dest_info]
                        [edit_egs_source_filenames   ^edit_egs_source_filenames]
                        [edit_egs_dest_filenames     ^edit_egs_dest_filenames]]);

lvars egsname egs_edit_menu type title labels values eg_rec;
    if (nn_example_sets(egsname) ->> eg_rec) then
        if eg_has_filetypes(eg_rec) then
            ;;; all datatypes must be a file type
            egs_editfile_menu
        else
            egs_editegs_menu
        endif -> egs_edit_menu;
        txtedit_menuloop(eg_rec, eg_name(eg_rec), egs_edit_menu, false, false,
                        [word], egs_edit_procs);
        if y_or_n_txt('Call generator function') then
            call_genfn(eg_name(eg_rec));
            txt_pause();
        endif;
    endif;
enddefine;


define edit_setthreshold(dt);
lvars dt curr_val new_val;
    nn_dt_setthreshold(dt) -> curr_val;
    get_item_default([word decimal ddecimal integer],
        'Threshold - real or false', curr_val) -> new_val;

    if isnumber(new_val) then
        new_val
    elseif new_val == "false" or new_val == false then
        false
    else
        curr_val
    endif -> nn_dt_setthreshold(dt);
enddefine;


define nn_edit_dt(dtname);
lconstant dt_edit_procs =
                newassoc([[edit_setthreshold ^edit_setthreshold]]);
lvars dtname type lower upper select title labels values oldval newthresh
    dt newval val;

    unless is_simple_dt(dtname) then
        nui_message_txt('Can only edit simple datatypes');
    else
        if (nn_datatypes(dtname) ->> dt) then
            if (nn_dt_type(dt) ->> type) == "set" then
                txtedit_menuloop(dt, dtname, setdt_edit_menu, nn_edit_list,
                        {'Set Item'}, [integer ddecimal decimal], dt_edit_procs)
            elseif type == "range" then
                txtedit_menuloop(dt, dtname, rangedt_edit_menu, false, false,
                        [integer ddecimal decimal], false);
            elseif type == "toggle" then
                txtedit_menuloop(dt, dtname, toggledt_edit_menu, false, false,
                        [word string integer], false);
            elseif type == "general" then
                txtedit_menuloop(dt, dtname, generaldt_edit_menu, false, false,
                        [word], false);
            endif;
        endif;
    endunless;
enddefine;

endsection;     /* $-popneural */

global vars nui_txtedit = true;         ;;; for "uses"

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 26/8/95
    Added missing lvars declaration in nn_edit_net, edit_egs_source_info
    and edit_egs_dest_info. Also corrected erroneous template argument
    in edit_egs_(source/dest)_info.
-- Julian Clinton, 28/8/92
    Modified input of literal data.
-- Julian Clinton, 21/8/92
    Renamed -eg_genfn- to -eg_gen_params- and -eg_applyfn- to
        -eg_apply_params-.
-- Julian Clinton, 13/8/92
    Made X version exit from nn_edit_egs if vededitor called to
        prevent busy cursor remaining on.
-- Julian Clinton, 12/8/92
    #_IF'd out the support for continuous data.
-- Julian Clinton, 17/7/92
    Renamed from txtedit.p to nui_txtedit.p.
-- Julian Clinton, 27/6/92
    Revised editing facilities to produce less garbage.
-- Julian Clinton, 26/6/92
    Added support for toggle types.
-- Julian Clinton, 22/6/92
    Added support for editing set threshold.
-- Julian Clinton, 1/6/92
    Modified edit_egs display string.
-- Julian Clinton, 8/5/92
    Sectioned.
*/
