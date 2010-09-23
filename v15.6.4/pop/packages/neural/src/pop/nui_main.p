/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:            $popneural/src/pop/nui_main.p
 > Purpose:         main Neural UI. Defines menus, startup and shutdown
 >                  procs and most action procs.
 > Author:          Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:
 */

section $-popneural =>  nn_init nn_exit neural
;

pr(';;; Loading Poplog-Neural UI\n');

exload_batch;

uses nui_printing;
uses nui_panels;
uses nui_txtbrowser;
uses nui_txtedit;

/* ----------------------------------------------------------------- *
     Lexical Variables Used By The UI
 * ----------------------------------------------------------------- */

lvars
    current_net_dir     = false,        ;;; current network load/save dir
    current_egs_dir     = false,        ;;; current example set load/save dir
    current_dt_dir      = false,        ;;; current datatype load/save dir
;


/* ----------------------------------------------------------------- *
     Generic Command Functions
 * ----------------------------------------------------------------- */

;;; set_options takes a panel name (which displays a set of variable/value
;;; pairs) and allows the user to set the values. Under GUI, this simply
;;; displays the window containing the values, while under the text UI,
;;; it keeps looping and changing the values accordingly
;;;
define set_options(panel_name);
dlocal nn_exitfromproc = set_options;
dlocal interrupt = nn_interrupt;
lvars panel_name panel = ui_options_table(panel_name),
      labels values maxwidth title wid_var wid, result = false;

#_IF DEF GFXNEURAL
    if GUI then
        show_options_gfx(panel_name);
        return();
    endif;
#_ENDIF
    destpanel_txt(panel) -> title -> maxwidth -> labels -> values;
    show_options_txt(title, maxwidth, labels, values);
enddefine;


;;; sub_menu always returns a value.

define sub_menu(menu_name) -> val;
lvars menu_name menu = ui_options_table(menu_name),
      labels = hd(menu),
      values = tl(menu), val = false;

    show_menu_txt(hd(labels), tl(labels), values, false, true) -> val;
enddefine;


;;; prevent declaring variable message with forward reference
vars procedure select_exec;

define show_panel(panel_name);
dlocal nn_exitfromproc = show_panel;
dlocal interrupt = nn_interrupt;
lvars panel_name panel = ui_options_table(panel_name),
      labels values title maxwidth wid_var, wid, result = false;

#_IF DEF GFXNEURAL
    if GUI then
        show_panel_gfx(panel_name);
        return();
    endif;
#_ENDIF
    destpanel_txt(panel) -> title -> maxwidth -> labels -> values;
    use_basewindow(true);
    repeat forever
        show_panel_txt(title, labels, values, false, true) -> result;
        if result then
            if isprocedure(result) then
                apply(result)
            elseif islist(result) then
                if is_panel_ref(result) then
                    show_panel(subscrl(2, result))
                elseif is_menu_ref(result) then
                    select_exec(subscrl(2, result));
                elseif is_options_ref(result) then
                    set_options(subscrl(2, result));
                endif;
            endif;
        else
            quitloop()
        endif;
        use_basewindow(true);
    endrepeat;
enddefine;


define select_exec(menu_name);
dlocal nn_exitfromproc = select_exec;
dlocal interrupt = nn_interrupt;
lvars menu_name val = true;

    while val do
        clear_screen();
        banner(nn_banner);
        sub_menu(menu_name) -> val;
        if isword(val) then
            apply(ui_options_table(val));
        elseif isprocedure(val) then
            apply(val);
        elseif islist(val) then
            if is_menu_ref(val) then
                select_exec(subscrl(2, val));
            elseif is_panel_ref(val) then
                show_panel(subscrl(2, val))
            elseif is_options_ref(val) then
                set_options(subscrl(2, val));
            endif;
        endif;
    endwhile;
enddefine;


;;; display_control_panel is the main entry point to the program. In GUI
;;; mode, it simply displays the main control panel and then exits. Under
;;; the text UI, it provides the top level "infinite" loop
;;; which continues to display the main menu. It can also be used
;;; for any kind control panel which displays menus or has activate
;;; buttons etc.
;;;
define display_control_panel(panel_name);
dlocal interrupt = nn_interrupt;
dlocal nn_exitfromproc = display_control_panel;
lvars panel_name panel = ui_options_table(panel_name),
      labels values title maxwidth wid_var wid result = false;

    destpanel_txt(panel) -> title -> maxwidth -> labels -> values;

#_IF DEF GFXNEURAL
    if GUI then
        show_mainpanel_gfx(panel_name);
        return();
    endif;
#_ENDIF
    use_basewindow(true);
    repeat forever
        show_mainpanel_txt(title, labels, values) -> result;
        if result then
            if isprocedure(result) then
                apply(result)
            elseif islist(result) then
                if is_menu_ref(result) then
                    select_exec(subscrl(2, result));
                elseif is_panel_ref(result) then
                    show_panel(subscrl(2, result))
                elseif is_options_ref(result) then
                    set_options(subscrl(2, result));
                endif;
            endif;
        else
            quitloop()
        endif;
        use_basewindow(true);
    endrepeat;
enddefine;


/* ----------------------------------------------------------------- *
    Datatype Command Functions
 * ----------------------------------------------------------------- */

;;; gen_dt_name takes a word and generates names until it find one that
;;; is not already a datatype.
define gen_dt_name(stub) -> name;
lvars stub name;
    until not(isdatatype(gensym(stub) ->> name)) do
    enduntil;
    get_item_default([], 'Datatype name', name) -> name;
enddefine;

define get_simple_dt_info(type);
lvars type name arg1 arg2 arg3;

    use_basewindow(true);

#_IF DEF GFXNEURAL
    unless GUI then
        nl(1);
        heading('Create Simple Type');
    endunless;
#_ENDIF

    if type == "set" then
        gen_dt_name("set_") -> name;
        npr('Enter each set member, pressing RETURN after each one.');
        get_lists(1, 'Set member ', false, false) -> arg1;
        get_item_default([decimal ddecimal integer],
            'Threshold - real or false', "false") -> arg2;
        if arg2 == "false" then
            false -> arg2;
        endif;
        pr('Creating set datatype...');
        nn_declare_set(name, arg1, arg2);

    elseif type == "range" then
        gen_dt_name("range_") -> name;
        get_item_default([], 'Lower bound', 0) -> arg1;
        get_item_default([], 'Upper bound', 100) -> arg2;
        pr('Creating range datatype...');
        nn_declare_range(name, arg1, arg2);

    elseif type == "toggle" then
        gen_dt_name("toggle_") -> name;
        [integer decimal ddecimal string] -> arg3;
        get_item_default(arg3, 'True value', "true") -> arg1;
        get_item_default(arg3, 'False value', "false") -> arg2;
        pr('Creating toggle datatype...');
        nn_declare_toggle(name, arg1, arg2);

    elseif type == "general" then
        gen_dt_name("general_") -> name;
        get_item_default([], 'Data format', [1 1]) -> arg1;
        get_1_item('Input converter', isword, 'procedure name') -> arg2;
        get_1_item('Output converter', isword, 'procedure name') -> arg3;
        pr('Creating datatype...');
        nn_declare_general(name, arg1, arg2, arg3);

    endif;
    name -> nn_current_dt;
    npr('done');
    txt_pause();
enddefine;


define get_field_dt_info(type);
lconstant isvalid_seq_item = procedure(x); lvars x;
                                isword(x) or (isinteger(x) and x < 127);
                             endprocedure;

lvars type name arg1 arg2 arg3 arg4;

    use_basewindow(true);

#_IF DEF GFXNEURAL
    unless GUI then
        nl(1);
        heading('Create Field Type');
    endunless;
#_ENDIF

    if is_seq_field_dt(type) then
        gen_dt_name("sequence_") -> name;
        print_list('Datatypes:', prop_list(nn_datatypes));
        pr('Please enter sequence. Use "\\" to prefix datatypes.\n');
        contrequestline('Sequence') -> arg1;
        pr('Creating sequence datatype...');
        nn_declare_field_format(name, arg1);

    elseif is_choice_field_dt(type) then
        gen_dt_name("choice_") -> name;
        until isdatatype(arg1) do
            get_1_item('Name of set datatype', isword, 'set name') -> arg1;
            if ishelp_request(arg1) then
                  print_list('Datatypes:', prop_list(nn_datatypes));
            endif;
        enduntil;
        get_1_item('Start item', isvalid_seq_item, "word") -> arg2;
        get_1_item('End item', isvalid_seq_item, "word") -> arg3;
        get_1_item('Separator', isvalid_seq_item, "word") -> arg4;
        pr('Creating choice datatype...');
        nn_declare_field_format(name, arg1, arg2, arg3, arg4);

    endif;
    name -> nn_current_dt;
    npr('done');
    txt_pause();
enddefine;

define get_file_dt_info(type);
lvars type name arg1 arg2 arg3;

    use_basewindow(true);

#_IF DEF GFXNEURAL
    unless GUI then
        nl(1);
        heading('Create File Type');
    endunless;
#_ENDIF

    if is_char_file_dt(type) then
        gen_dt_name("charfile_") -> name;
        print_list('Datatypes:', prop_list(nn_datatypes));
        contrequestline('Datatypes in file') -> arg1;
        pr('Creating character file datatype...');
        nn_declare_file_format(name, arg1, type);

    elseif is_item_file_dt(type) then
        gen_dt_name("itemfile_") -> name;
        contrequestline('Datatypes in file') -> arg1;
        pr('Creating item file datatype...');
        nn_declare_file_format(name, arg1, type);

    elseif is_line_file_dt(type) then
        gen_dt_name("linefile_") -> name;
        until isdatatype(arg1) do
            get_1_item('Name of recipient datatype', isword, 'datatype name')
                        -> arg1;
            if ishelp_request(arg1) then
                  print_list('Datatypes:', prop_list(nn_datatypes));
            endif;
        enduntil;
        get_1_item('Size of byte structure', isinteger, 'integer') -> arg2;
        pr('Creating line file datatype...');
        nn_declare_file_format(name, arg1, arg2, type);

    elseif is_full_file_dt(type) then
        gen_dt_name("fullfile_") -> name;
        until isdatatype(arg1) do
            get_1_item('Name of recipient datatype', isword, 'datatype name')
                        -> arg1;
            if ishelp_request(arg1) then
                  print_list('Datatypes:', prop_list(nn_datatypes));
            endif;
        enduntil;
        get_1_item('Size of byte structure', isinteger, 'integer') -> arg2;
        pr('Creating file datatype...');
        nn_declare_file_format(name, arg1, arg2, type);

    endif;
    name -> nn_current_dt;
    npr('done');
    txt_pause();
enddefine;


define create_dt();
dlocal nn_exitfromproc = create_dt;
dlocal interrupt = nn_interrupt;
lvars type;

    use_basewindow(true);

#_IF DEF GFXNEURAL
    unless GUI then
        nl(1);
        heading('Create Datatype');
    endunless;
#_ENDIF

    sub_menu("select_dt_menu") -> type;
    if is_simple_dt(type) then
        get_simple_dt_info(type);
    elseif is_field_dt(type) then
        get_field_dt_info(type);
    elseif is_file_dt(type) then
        get_file_dt_info(type);
    endif;
enddefine;


define list_all_dts();
lvars item dt_list = prop_list(nn_datatypes), list;
    use_basewindow(false);
    if dt_list == [] then
        nui_message('No datatypes have been defined');
    else
#_IF DEF GFXNEURAL
        if GUI then
            nui_message(build_titled_string('Datatypes:', dt_list));
        else
            print_list('Datatypes:', dt_list);
            txt_pause();
        endif;
#_ELSE
        print_list('Datatypes:', dt_list);
        txt_pause();
#_ENDIF
    endif;
    sys_grbg_list(dt_list);
enddefine;

define select_which_dt(prompt, select_label) -> res;
lvars prompt select_label res = false, menu list;

    if isempty(nn_datatypes) then
        nui_message('No datatypes have been defined.');
        return();
    endif;

#_IF DEF GFXNEURAL
    if GUI then
        nn_singlechoice_gfx(prop_list(nn_datatypes), prompt,
            'Datatypes', select_label) -> res;
        return();
    endif;
#_ENDIF

    use_basewindow(false);
    print_list('Datatypes:', prop_list(nn_datatypes));
    get_item_default([], 'Which datatype', nn_current_dt) -> res;
enddefine;

define set_current_dt();
lvars res;
    select_which_dt('Set Current Datatype', 'Select') -> res;
    if res then
        res -> nn_current_dt;
    endif;
enddefine;

define display_dt();
lvars dt;
    use_basewindow(true);
    select_which_dt('Display Datatype', 'Display') -> dt;
    if nn_datatypes(dt) then
        nn_pr_dt(dt);
        txt_pause();
    endif;
enddefine;


define edit_dt();
dlocal nn_exitfromproc = edit_dt;
dlocal interrupt = nn_interrupt;
lvars dt;
    unless isempty(nn_datatypes) then
        use_basewindow(true);
        nl(1);
        heading('Edit Datatype');
        select_which_dt('Edit Datatype', 'Edit') -> dt;
        if isdatatype(dt) then
            nn_edit_dt(dt);
        endif;
    else
        nui_message('No datatypes have been defined.');
    endunless;
enddefine;


define delete_dt();
dlocal nn_exitfromproc = delete_dt;
dlocal interrupt = nn_interrupt;
lvars dt menu;
    if isempty(nn_datatypes) then
        nui_message('No datatypes have been defined.');
    else
        use_basewindow(true);
        nl(1);
        heading('Delete Datatype');
        select_which_dt('Delete Datatype', 'Delete') -> dt;
        if isdatatype(dt) and
          nui_confirm(sprintf(dt, 'Really delete %p ?'),
                        ['Delete' 'Cancel'], 2) == 1 then
             nn_delete_dt(dt);
        endif;
    endif;
enddefine;


define load_dt();
dlocal nn_exitfromproc = load_dt;
dlocal interrupt = nn_interrupt;
lvars dtfiles dtdir dtname dtnames update_proc loadnames;

    saved_object_names(%'*.dt'%) -> update_proc;
    update_proc(current_dt_dir) -> dtnames;
    nui_select_loaditems(current_dt_dir, update_proc, dtnames, 'Load Datatypes',
                    'Datatypes') -> dtdir -> dtnames;

    returnunless(dtdir);
    dtdir -> current_dt_dir;

    if islist(dtnames) and dtnames /== [] then
        nui_do_loaditems(dtnames, dtdir, '.dt', nn_load_dt) -> loadnames;
        if null(loadnames) then
            nui_message('No datatypes loaded');
        else
            nui_message(build_titled_string('Loaded datatypes:', loadnames));
        endif;
    else
        nui_message('No datatypes loaded');
    endif;
enddefine;


define save_dt();
dlocal nn_exitfromproc = save_dt;
dlocal interrupt = nn_interrupt;
lvars dtname dtdir dtnames savenames;

    unless isempty(nn_datatypes) then
        nui_select_saveitems(current_dt_dir, prop_list(nn_datatypes), 'Save Datatypes',
                    'Datatypes') -> dtdir -> dtnames;
        returnunless(dtdir);
        dtdir -> current_dt_dir;
        nui_do_saveitems(dtnames, dtdir, '.dt', nn_save_dt) -> savenames;
        if null(savenames) then
            nui_message('No datatypes saved');
        else
            nui_message(build_titled_string('Saved datatypes:', savenames));
        endif;
    else
        nui_message('No datatypes have been defined.');
    endunless;
enddefine;


/* ----------------------------------------------------------------- *
     Network Command Functions
 * ----------------------------------------------------------------- */

define get_number_of_units(prompt, n_default) -> n_units;
lvars prompt n_default n_units;
    while (not(isinteger(n_units)) or (isinteger(n_units) and n_units < 1)) do
        get_item_default([list pair word integer], prompt, n_default) -> n_units;
        unless isinteger(n_units) then
            if islist(n_units) then
                if are_types(isdatatype,n_units) then
                    nn_units_needed(n_units) -> n_units;
                else
                    inputerr('invalid datatype(s)');
                    nextloop();
                endif;
            elseif isdatatype(n_units) then
                nn_units_needed(nn_datatypes(n_units)) -> n_units;
            endif;
            unless isinteger(n_units) and n_units > 0 then
                inputerr('integer > 0 needed');
            endunless;
        endunless;
    endwhile;
enddefine;


;;; cont_data_units is used to check user input for the no. of input
;;; and output units. It is intended to create closures of this
;;; checking against
define lconstant cont_data_units(n_inputs, units_needed);
lvars n_inputs units_needed;
    (n_inputs mod units_needed) == 0;
enddefine;


define global nn_create_bpnet();
lvars name type ins = 0, outs = 0, layers = -1,
      layer format arg1 arg2 arg3 arg4 eg_rec testproc;

    use_basewindow(true);
    nl(1);
    heading('Back-propagation Network');
    until not(isneuralnet(gensym("bpnet_") ->> name)) do
    enduntil;
    get_item_default([], 'Network name', name) -> name;
    if not(isempty(nn_example_sets)) and
      y_or_n_txt('Do you want to use an existing example set with this net')
        then
        get_item_default([], 'Example set name', nn_current_egs)
            -> nn_current_egs;
        eg_in_units(nn_example_sets(nn_current_egs) ->> eg_rec) -> ins;

#_IF DEF NEURAL_CONTINUOUSDATA
        if eg_discrete(eg_rec) then
            if isunknown(ins) then
                npr('Undefined number of input units in example set');
                get_number_of_units('Number of input units or datatype list', 16)
                    -> ins;
            else
                printf(ins, 'Network requires %p input units');
            endif;
        else
            if isunknown(ins) then
                get_number_of_units('Number of input units or datatype list', 16)
                    -> ins;
            else
                cont_data_units(%ins%) -> testproc;
                get_1_item(sprintf(ins,
                                'Enter no. of input units (multiple of %p)'),
                            testproc, 'integer') -> ins;
            endif;
        endif;

#_ELSE      /* Discrete data only */

        if isunknown(ins) then
            npr('Undefined number of input units in example set');
            get_number_of_units('Number of input units or datatype list', 16)
                -> ins;
        else
            printf(ins, 'Network requires %p input units');
        endif;

#_ENDIF

        eg_out_units(eg_rec) -> outs;

#_IF DEF NEURAL_CONTINUOUSDATA
        if eg_discrete(eg_rec) then
            if isunknown(outs) then
                nl(1);
                npr('Undefined number of output units in example set');
                get_number_of_units('Number of output units or datatype list', 16)
                    -> outs;
            else
                printf(outs, ' and %p output units\n');
            endif;
        else
            if isunknown(outs) then
                get_number_of_units('Number of output units or datatype list', 16)
                    -> outs;
            else
                cont_data_units(%outs%) -> testproc;
                get_1_item(sprintf(outs,
                                'Enter no. of output units (multiple of %p)'),
                            testproc, 'integer') -> outs;
            endif;
        endif;

#_ELSE      /* Discrete data only */

        if isunknown(outs) then
            nl(1);
            npr('Undefined number of output units in example set');
            get_number_of_units('Number of output units or datatype list', 16)
                -> outs;
        else
            printf(outs, ' and %p output units\n');
        endif;

#_ENDIF

    else
        get_number_of_units('Number of input units or datatype list', 16)
            -> ins;
        get_number_of_units('Number of output units or datatype list', 16)
            -> outs;
    endif;
    while layers < 0 then
        get_item_default([], 'Number of hidden layers', 1) -> layers;
        if layers < 0 then
            inputerr('number greater than/equal to 0 needed');
        endif;
    endwhile;
    initv(layers + 1) -> format;
    for layer from 1 to layers do
        get_item_default([], 'Nodes in hidden layer ' >< layer >< '', ins)
            -> format(layer);
        if format(layer) < 0 then
            inputerr('number greater than/equal to 0 needed');
            layer - 1 -> layer;
        endif;
    endfor;
    get_item_default([], 'Variance of weights', 2.0) -> arg1;
    get_item_default([], 'Learning rate (eta)', 0.5) -> arg2;
    get_item_default([], 'Learning momentum (alpha)', 0.9) -> arg3;
    outs -> format(layers + 1);
    pr('Creating network...');
    make_bpnet(ins, format, arg1, arg2, arg3) -> nn_neural_nets(name);
    name -> nn_current_net;
    npr('done');
enddefine;


define global nn_create_clnet();
lvars name type ins = 0, outs = {2}, layers = -1,
      layer format arg1 arg2 arg3 arg4 group eg_rec testproc;

    use_basewindow(true);
    nl(1);
    heading('Competitive Learning Network');
    until not(isneuralnet(gensym("clnet_") ->> name)) do
    enduntil;
    get_item_default([], 'Network name', name) -> name;
    if not(isempty(nn_example_sets)) and
      y_or_n_txt('Do you want to use an existing example set with this net')
        then
        get_item_default([], 'Example set name', nn_current_egs)
            -> nn_current_egs;

        eg_in_units(nn_example_sets(nn_current_egs) ->> eg_rec) -> ins;


#_IF DEF NEURAL_CONTINUOUSDATA
        if eg_discrete(eg_rec) then
            if isunknown(ins) then
                npr('Undefined number of input units in example set');
                get_number_of_units('Number of input units or datatype list', 16)
                    -> ins;
            else
                printf(ins, 'Network requires %p input units\n');
            endif;
        else
            if isunknown(ins) then
                get_number_of_units('Number of input units or datatype list', 16)
                    -> ins;
            else
                cont_data_units(%ins%) -> testproc;
                get_1_item(sprintf(ins,
                                'Enter no. of input units (multiple of %p)'),
                            testproc, 'integer') -> ins;
            endif;
        endif;

#_ELSE      /* Discrete data only */

        if isunknown(ins) then
            npr('Undefined number of input units in example set');
            get_number_of_units('Number of input units or datatype list', 16)
                -> ins;
        else
            printf(ins, 'Network requires %p input units\n');
        endif;

#_ENDIF

    else
        get_number_of_units('No. of input units or datatypes list', 16) -> ins;
    endif;
    get_item_default([list pair vector], 'Format of output layer', {2}) -> outs;
    if islist(outs) then
        consvector(explode(outs), length(outs)) -> outs;
    endif;
    while layers < 0 then
        get_item_default([], 'Number of hidden layers', 1) -> layers;
        if layers < 0 then
            inputerr('number greater than/equal to 0 needed');
        endif;
    endwhile;
    initv(layers + 1) -> format;
    for layer from 1 to layers do
        get_item_default([list pair vector], 'Format of hidden layer ' >< layer >< '', {2})
            -> format(layer);
        if islist(format(layer)) then
            consvector(explode(format(layer)),
                       length(format(layer))) -> format(layer);
        endif;
        for group from 1 to length(format(layer)) do
            if not(isinteger(format(layer)(group))) then
                inputerr('integer(s) needed to specify group size');
            elseif format(layer)(group) < 1 then
                inputerr('cannot have a group with less than one unit');
                layer - 1 -> layer;
                quitloop();
            endif;
        endfor;
    endfor;
    get_item_default([], 'Learning rate for winning units', 0.02) -> arg1;
    get_item_default([], 'Learning rate for losing units', false) -> arg2;
    get_item_default([], 'Sensitivity equalisation for winning units', 0.02)
        -> arg3;
    get_item_default([], 'Sensitivity equalisation for losing units', 0.001)
        -> arg4;
    outs -> format(layers + 1);
    pr('Creating network...');
    make_clnet(ins, format, arg1, arg2, arg3, arg4)
        -> nn_neural_nets(name);
    name -> nn_current_net;
    npr('done');
enddefine;

define create_net();
dlocal nn_exitfromproc = create_net;
dlocal interrupt = nn_interrupt;
lvars name type;

    use_basewindow(true);
    show_menu_txt('Network Types', hd(nn_net_type_menu),tl(nn_net_type_menu),
                  false, false) -> type;
    if nn_net_descriptors(type) then
        if type == "bpropnet" then
            nn_create_bpnet();
        elseif type == "clearnnet" then
            nn_create_clnet();
        endif;
        txt_pause();
    else
        nui_message(type >< 'is an unknown network type.');
    endif;
enddefine;

define list_all_nets();
lvars item net_list = prop_list(nn_neural_nets), list;
    use_basewindow(false);
    if net_list == [] then
        nui_message('No networks have been defined');
    else
#_IF DEF GFXNEURAL
        if GUI then
            nui_message(build_titled_string('Networks:', net_list));
        else
            print_list('Networks:', net_list);
            txt_pause();
        endif;
#_ELSE
        print_list('Networks:', net_list);
        txt_pause();
#_ENDIF
    endif;
    sys_grbg_list(net_list);
enddefine;

define select_which_net(prompt, select_label) -> res;
lvars prompt select_label res = false, menu;

    if isempty(nn_neural_nets) then
        nui_message(err(NO_NETS));
    else
#_IF DEF GFXNEURAL
        if GUI then
            nn_singlechoice_gfx(prop_list(nn_neural_nets), prompt,
                'Networks', select_label) -> res;
        else
#_ENDIF
            use_basewindow(false);
            print_list('Networks:', prop_list(nn_neural_nets));
            get_item_default([], 'Which network', nn_current_net)
                -> res;
#_IF DEF GFXNEURAL
        endif;
#_ENDIF
    endif;
enddefine;

define set_current_net();
lvars res;
    select_which_net('Set Current Network', 'Select') -> res;
    if res then
        res -> nn_current_net;
    endif;
enddefine;

define display_net();
lvars netname net layers layer;
    unless nn_use_curr_net then
        select_which_net('Display Network', 'Display') -> netname;
    else
        nn_current_net -> netname;
    endunless;
    nn_neural_nets(netname) -> net;
    if net then
#_IF DEF GFXNEURAL
        if GUI then
            nn_show_topology(netname,
                             nn_total_layers(net),
                             nn_max_units_in_layer(net),
                             [0 0], false) ->;
        else
#_ENDIF
            nn_pr_net(netname);
            txt_pause();
#_IF DEF GFXNEURAL
        endif;
#_ENDIF
    endif;
enddefine;

define copy_net();
dlocal nn_exitfromproc = copy_net;
dlocal interrupt = nn_interrupt;
lvars netname net name;
    unless isempty(nn_neural_nets) then
        use_basewindow(true);
        nl(1);
        heading('Copy Network');
        unless nn_use_curr_net then
            select_which_net('Copy Network', 'Copy') -> netname;
        else
            nn_current_net -> netname;
        endunless;
        nn_neural_nets(netname) -> net;
        if net then
            until not(isneuralnet(gensym("copy_") ->> name)) do
            enduntil;
            get_item_default([word], 'Name of new network', name) -> name;
            nn_copy_net(netname) -> nn_neural_nets(name);
            nui_message(netname >< ' copied to ' >< (name >< '.'));
        endif;
    else
        nui_message(err(NO_NETS));
    endunless;
enddefine;

define delete_net();
dlocal nn_exitfromproc = delete_net;
dlocal interrupt = nn_interrupt;
lvars netname menu;
    if isempty(nn_neural_nets) then
        nui_message(err(NO_NETS));
    else
        use_basewindow(true);
        nl(1);
        heading('Delete Network');
        unless nn_use_curr_net then
            select_which_net('Delete Network', 'Delete') -> netname;
        else
            nn_current_net -> netname;
        endunless;
        returnunless(netname);
        if isneuralnet(netname) and
          nui_confirm(sprintf(netname, 'Really delete %p ?'),
                        ['Delete' 'Cancel'], 2) == 1 then
             nn_delete_net(netname);
        endif;
    endif;
enddefine;

define edit_net();
dlocal nn_exitfromproc = edit_net;
dlocal interrupt = nn_interrupt;
lvars netname;
    unless isempty(nn_neural_nets) then
        use_basewindow(true);
        nl(1);
        heading('Edit Network');
        unless nn_use_curr_net then
            select_which_net('Edit Network', 'Edit') -> netname;
        else
            nn_current_net -> netname;
        endunless;
        returnunless(netname);
        nn_edit_net(netname);
    else
        nui_message(err(NO_NETS));
    endunless;
enddefine;


define load_net();
dlocal nn_exitfromproc = load_net;
dlocal interrupt = nn_interrupt;
lvars netfiles netdir update_proc netname netnames loadnames;

    saved_object_names(%'*.net'%) -> update_proc;
    update_proc(current_net_dir) -> netnames;
    nui_select_loaditems(current_net_dir, update_proc, netnames, 'Load Networks',
                    'Networks') -> netdir -> netnames;

    returnunless(netdir);
    netdir -> current_net_dir;

    if netnames /== [] then
        nui_do_loaditems(netnames, netdir, '.net', nn_load_net) -> loadnames;
        if null(loadnames) then
            nui_message('No networks loaded');
        else
            nui_message(build_titled_string('Loaded networks:', loadnames));
        endif;
    else
        nui_message('No networks loaded');
    endif;
enddefine;


define save_net();
dlocal nn_exitfromproc = save_net;
dlocal interrupt = nn_interrupt;
lvars netnames netdir netname savenames;

    unless isempty(nn_neural_nets) then
        nui_select_saveitems(current_net_dir, prop_list(nn_neural_nets), 'Save Networks',
                    'Networks') -> netdir -> netnames;
        returnunless(netdir);
        netdir -> current_net_dir;
        nui_do_saveitems(netnames, netdir, '.net', nn_save_net) -> savenames;
        if null(savenames) then
            nui_message('No networks saved');
        else
            nui_message(build_titled_string('Saved networks:', savenames));
        endif;
    else
        nui_message(err(NO_NETS));
    endunless;
enddefine;


/* ----------------------------------------------------------------- *
    Example Set Command Functions
 * ----------------------------------------------------------------- */

define create_egs();
dlocal nn_exitfromproc = create_egs;
dlocal interrupt = nn_interrupt;
dlocal EG_DEFAULTS;
lvars name total=0, template dir = "in", ask_names field fname genfn index=0,
      gen = false, egs, eg, type = "boolean", temp_list = [], tmp_dir,
      newtype = false, input_len = 0, subf, args, loops,
      field_items field_type discrete_p = false,
      default, data_source data_generator data_destination dest_info
      name_stub name_word filetype_flag = undef;

    define lconstant check_file_type(field, type) -> boole;
    lvars field type boole;
        if field == 1 then
            is_file_dt(type) -> filetype_flag;
            true
        elseif is_file_dt(type) and not(filetype_flag) then
            inputerr('non-file datatype needed');
            false
        elseif not(is_file_dt(type)) and filetype_flag then
            inputerr('file datatype needed');
            false
        else
            true
        endif -> boole;
    enddefine;

    use_basewindow(true);
    nl(1);
    heading('Create Example Set');
    until not(isexampleset(gensym("egs_") ->> name)) do
    enduntil;
    get_item_default([], 'What is the example set name', name) -> name;


#_IF DEF NEURAL_CONTINUOUSDATA
    if (edit_flag_value('Are the examples discrete or continuous',
        "discrete", "continuous", eg_default_discrete)
            ->> eg_default_discrete ->> discrete_p) then
        'field ' -> name_stub;
        "field_" -> name_word;
    else
        'sequence ' -> name_stub;
        "seq_" -> name_word;
    endif;

#_ELSE      /* Discrete data only */

    'field ' -> name_stub;
    "field_" -> name_word;
#_ENDIF


#_IF DEF NEURAL_CONTINUOUSDATA
    if discrete_p then
        while total < 1 do
            get_item_default([integer],
              'How many datatype fields are there in each example', 3) -> total;
            if total < 1 then
                inputerr('must have at least 1 field');
            endif;
        endwhile;
    else
        while total < 1 do
            get_item_default([integer],
                             'How many data sequences are there', 2) -> total;
            if total < 1 then
                inputerr('must have at least 1 sequence');
            endif;
        endwhile;
    endif;

#_ELSE      /* Discrete data only */

    while total < 1 do
        get_item_default([integer],
          'How many datatype fields are there in each example', 3) -> total;
        if total < 1 then
            inputerr('must have at least 1 field');
        endif;
    endwhile;
#_ENDIF

    y_or_n_txt('Do you want to name them') -> ask_names;

    if ask_names then
        for field from 1 to total do
            get_item_default([], 'Name of ' sys_>< name_stub sys_>< field,
                            consword(name_word sys_>< field)) -> fname;
            [none undef ^fname];
        endfor;
    else
        for field from 1 to total do
            consword(name_word sys_>< field) -> fname;
            [none undef ^fname];
        endfor;
    endif;

    conslist(total) -> template;

    for field from 1 to total do
        if ask_names then
            get_item_default([pair word], 'Direction of "' ><
                                         nn_template_name(template(field)) ><
                                '" - in, out, both or none', dir) -> dir;
        else
            get_item_default([pair word], 'Direction of ' sys_>< name_stub
                        >< field >< ' - in, out, both or none', dir) -> dir;
        endif;

        if isword(dir) and (uppertolower(dir) ->> dir)
          and (isvalidfield(dir) ->> tmp_dir) then
            tmp_dir ->> dir -> nn_template_io(template(field));

        elseif islist(dir) and length(dir) == 2 then

            explode(dir) -> field_type -> field_items;

            if not(isvalidfield(field_type)) then
                false
            elseif field_items == "*" then
                total - field
            elseif isinteger(field_items) then
                max(1, min(field_items - 1, total - field))
            else
                false
            endif -> loops;

            if loops then
                field_type ->> nn_template_io(template(field)) -> dir;
                repeat loops times
                    field + 1 -> field;
                    field_type -> nn_template_io(template(field));
                endrepeat;
            else
                inputerr('incorrect list expression');
                field - 1 -> field;
                "in" -> dir;
            endif;

        else
            inputerr('in, out, both or none expected');
            field - 1 -> field;
            "in" -> dir;

        endif;
    endfor;

    [] -> temp_list;

    for field from 1 to total do
        if ask_names then
            if isdatatype(nn_template_name(template(field))) then
                nn_template_name(template(field)) -> type;
            endif;
            get_item_default([pair word],
                sprintf(nn_template_name(template(field)),
                        'Datatype of "%p"'), type) -> newtype;
        else
            get_item_default([pair word],
                sprintf(field, name_stub, 'Datatype of %p%p'), type) -> newtype;
        endif;

        if ishelp_request(newtype) then
              print_list('Datatypes:', prop_list(nn_datatypes));
              field - 1 -> field;
        elseif isword(newtype) and isdatatype(newtype) then
            if check_file_type(field, newtype) then
                newtype -> type;
                false -> newtype;
                type :: temp_list -> temp_list;
                type -> nn_template_type(template(field));
            else
                field - 1 -> field;
                nextloop();
            endif;
        elseif islist(newtype) and length(newtype) == 2 then

            explode(newtype) -> field_type -> field_items;

            if not(isdatatype(field_type)) then
                false
            elseif field_items == "*" then
                ;;; make the rest of the datafields this datatype
                total - field
            elseif isinteger(field_items) then
                ;;; only make the next field_items of the datafields
                ;;; this datatype
                max(1, min(field_items - 1, total - field))
            else
                false
            endif -> loops;

            if loops then
                unless check_file_type(field, field_type) then
                    field - 1 -> field;
                    nextloop();
                endunless;
                field_type :: temp_list -> temp_list;
                field_type ->> nn_template_type(template(field)) -> type;
                repeat loops times
                    field + 1 -> field;
                    field_type :: temp_list -> temp_list;
                    field_type -> nn_template_type(template(field));
                endrepeat;
                false -> newtype;
            else
                inputerr('incorrect expression');
                field - 1 -> field;
            endif;

        else
            inputerr(newtype >< ' is an unknown datatype');
            field - 1 -> field;
        endif;
    endfor;

    ncrev(temp_list) -> temp_list;

    edit_flag_value('Keep parsed examples - yes or no',
                "yes", "no", eg_default_keep_egs)
                                -> eg_default_keep_egs;

    edit_flag_value('Generate output fields as target data - yes or no',
                "yes", "no", eg_default_gen_output)
                                -> eg_default_gen_output;

    if eg_default_gen_output then
        nn_items_needed(temp_list)
    else
        false
    endif -> input_len;

    get_data_source_txt(template, filetype_flag, input_len)
                                    -> data_source -> data_generator;

    get_data_dest_txt(template, filetype_flag)
                        -> data_destination -> dest_info;

    pr('Making example set...');
    nn_make_egs(name, template, data_source, data_generator,
                data_destination, dest_info, eg_default_flags);
    name -> nn_current_egs;
    npr('done.');

    if y_or_n_txt('Generate example data') then
        call_genfn(nn_current_egs);
    endif;
    txt_pause();
enddefine;


define list_all_egss();
lvars item egs_list = prop_list(nn_example_sets);
    if egs_list == [] then
        nui_message('No example sets have been defined');
    else
#_IF DEF GFXNEURAL
        if GUI then
            nui_message(build_titled_string('Example Sets:', egs_list));
        else
            print_list('Example Sets:', egs_list);
            txt_pause();
        endif;
#_ELSE
        print_list('Example Sets:', egs_list);
        txt_pause();
#_ENDIF
    endif;
    sys_grbg_list(egs_list);
enddefine;


define select_which_egs(prompt, select_label) -> res;
lvars prompt select_label menu res = false;

    if isempty(nn_example_sets) then
        nui_message(err(NO_EGSS));
    else
#_IF DEF GFXNEURAL
        if GUI then
            nn_singlechoice_gfx(prop_list(nn_example_sets), prompt,
                'Example Sets', select_label) -> res;
        else
#_ENDIF
            use_basewindow(false);
            print_list('Example sets:', prop_list(nn_example_sets));
            get_item_default([], 'Which example set', nn_current_egs)
                -> res;
#_IF DEF GFXNEURAL
        endif;
#_ENDIF
    endif;
enddefine;

define set_current_egs();
lvars res;
    select_which_egs('Set Current Example Set', 'Select') -> res;
    if res then
        res -> nn_current_egs;
    endif;
enddefine;

define generate_egs();
dlocal nn_exitfromproc = generate_egs;
dlocal interrupt = nn_interrupt;
lvars egsname egs menu args;

    unless isempty(nn_example_sets) then
        unless nn_use_curr_egs then
            select_which_egs('Generate Example Data', 'Generate') -> egsname;
        else
            nn_current_egs -> egsname;
        endunless;
        returnunless(egsname);
        nn_example_sets(egsname) -> egs;
        if egs then
            egsname -> nn_current_egs;
            use_basewindow(true);
            nl(1);
            heading('Call Example Generator Function');
            nl(1);
            call_genfn(nn_current_egs);
            txt_pause();
        endif;
    else
        nui_message(err(NO_EGSS));
    endunless;
enddefine;

define copy_egs();
dlocal nn_exitfromproc = copy_egs;
dlocal interrupt = nn_interrupt;
lvars egsname egs name;
    unless isempty(nn_example_sets) then
        use_basewindow(true);
        nl(1);
        heading('Copy Example Set');
        unless nn_use_curr_egs then
            select_which_egs('Copy Example Set', 'Copy') -> egsname;
        else
            nn_current_egs -> egsname;
        endunless;
        nn_example_sets(egsname) -> egs;
        if egs then
            until not(isexampleset(gensym("copy_") ->> name)) do
            enduntil;
            get_item_default([], 'Name of new example set', name) -> name;
            nn_copy_egs(egsname) -> nn_example_sets(name);
            npr(egsname >< ' copied to ' >< (name >< '.'));
            txt_pause();
        endif;
    else
        nui_message(err(NO_EGSS));
    endunless;
enddefine;

define delete_egs();
dlocal nn_exitfromproc = delete_egs;
dlocal interrupt = nn_interrupt;
lvars egsname menu;
    if isempty(nn_example_sets) then
        nui_message(err(NO_EGSS));
    else
        use_basewindow(true);
        nl(1);
        heading('Delete Example Set');
        unless nn_use_curr_egs then
            select_which_egs('Delete Example Set', 'Delete') -> egsname;
        else
            nn_current_egs -> egsname;
        endunless;
        if isexampleset(egsname) and
          nui_confirm(sprintf(egsname, 'Really delete %p ?'),
                        ['Delete' 'Cancel'], 2) == 1 then
             nn_delete_egs(egsname);
        endif;
    endif;
enddefine;


define display_egs();
dlocal nn_exitfromproc = display_egs;
dlocal interrupt = nn_interrupt;
lvars ts egsname egs filename filelist ftype;

    if isempty(nn_example_sets) then
        nui_message(err(NO_EGSS));
        return();
    endif;

    use_basewindow(true);
    unless nn_use_curr_egs then
        select_which_egs('Display Example Set', 'Display') -> egsname;
    else
        nn_current_egs -> egsname;
    endunless;
    if (nn_example_sets(egsname) ->> egs) then
        nn_pr_egs(egs);
        if egs_from_literal(egs) and
          eg_keep_egs(egs) and
          nui_confirm('Browse examples ?', ['Browse' 'Cancel'], 1) == 1 then
            nn_browse_list({%eg_gendata(nn_example_sets(egsname))%},
                {'Example'});
        elseif egs_from_file(egs) and not(eg_rawdata_in(egs)) and
          nui_confirm('Browse examples ?', ['Browse' 'Cancel'], 1) == 1 then
            get_examplefile_name(egs) -> filename -> ftype;
            if filename then
                ;;; now we have the filename, try to work out how to display it
                if is_char_file_dt(ftype) or is_item_file_dt(ftype) then
                    vededitor(vedhelpdefaults, filename);
                else
                    nui_message('Cannot browse this file using VED');
                endif;
            endif;
        else
            txt_pause();
        endif;
    endif;
enddefine;


define edit_egs();
dlocal nn_exitfromproc = edit_egs;
dlocal interrupt = nn_interrupt;
lvars egsname;
    unless isempty(nn_example_sets) then
        use_basewindow(true);
        nl(1);
        heading('Edit Example Set');
        unless nn_use_curr_egs then
            select_which_egs('Edit Example Set', 'Edit') -> egsname;
        else
            nn_current_egs -> egsname;
        endunless;
        returnunless(egsname);
        nn_edit_egs(egsname);
    else
        nui_message(err(NO_EGSS));
    endunless;
enddefine;


define load_egs();
dlocal nn_exitfromproc = load_egs;
dlocal interrupt = nn_interrupt;
lvars egsfiles update_proc egsdir egsname egsnames loadnames
    gennames = false, failed = [];

    saved_object_names(%'*.egs'%) -> update_proc;
    update_proc(current_egs_dir) -> egsnames;
    nui_select_loaditems(current_egs_dir, update_proc, egsnames, 'Load Example Sets',
                    'Example Sets') -> egsdir -> egsnames;

    returnunless(egsdir);
    egsdir -> current_egs_dir;

    if egsnames /== [] then
        nui_do_loaditems(egsnames, egsdir, '.egs', nn_load_egs) -> loadnames;
        if null(loadnames) then
            nui_message('No example sets loaded');
        else
            unless (not(GUI) and
                nui_confirm(build_titled_string('Example sets loaded. Generate examples ?',
                                    loadnames),
                        ['Generate' 'Cancel'], 1) == 2) then
                nui_multiselect(loadnames, 'Generate New Example Sets',
                    'Example Sets', 'Generate') -> gennames;
                if islist(gennames) and gennames /== [] then
                    for egsname in gennames do
                        call_genfn(egsname);
                    endfor;
                    nui_message('Example set(s) generated.');
                endif;
            endunless;
        endif;
    else
        nui_message('No example sets loaded');
    endif;
enddefine;


define save_egs();
dlocal nn_exitfromproc = save_egs;
dlocal interrupt = nn_interrupt;
lvars egsname egsdir egsnames savenames;

    unless isempty(nn_example_sets) then
        nui_select_saveitems(current_egs_dir, prop_list(nn_example_sets), 'Save Example Sets',
                    'Example sets') -> egsdir -> egsnames;
        returnunless(egsdir);
        egsdir -> current_egs_dir;
        nui_do_saveitems(egsnames, egsdir, '.egs', nn_save_egs) -> savenames;
        if null(savenames) then
            nui_message('No example sets saved');
        else
            nui_message(build_titled_string('Saved example sets:', savenames));
        endif;
    else
        nui_message(err(NO_EGSS));
    endunless;
enddefine;


/* ----------------------------------------------------------------- *
    Teach And Test Command Functions
 * ----------------------------------------------------------------- */

define teach_all();
dlocal nn_exitfromproc = teach_all;
dlocal interrupt = nn_interrupt;
lconstant query = 'Teach example set %p to net %p %p times ?';
lvars netname egsname incr session;

    if isempty(nn_neural_nets) then
        nui_message(err(NO_NETS));
    elseif isempty(nn_example_sets) then
        nui_message(err(NO_EGSS));
    else
        unless nn_use_curr_net then
            select_which_net('Teach Which Network', 'Select') -> netname;
        else
            nn_current_net -> netname;
        endunless;

        returnunless(netname);

        unless nn_use_curr_egs then
            select_which_egs('Using Which Example Set', 'Select') -> egsname;
        else
            nn_current_egs -> egsname;
        endunless;
        ;;; unless we have something for both then exit
        unless netname and egsname then
            return();
        endunless;
        netname -> nn_current_net;
        egsname -> nn_current_egs;
        if nui_confirm(sprintf(nn_training_cycles, nn_current_net,
                             nn_current_egs, query),
                        ['Teach' 'Cancel'], 1) == 1 then
            if nn_call_genfn then call_genfn(nn_current_egs) endif;
            nn_learn_egs(nn_current_egs,
                         nn_current_net,
                         nn_training_cycles,
                         not(nn_random_select));
#_IF DEF GFXNEURAL
            if nn_update_wins then
                nn_update_windows(nn_current_net)
            endif;
#_ENDIF
            nui_message('Teaching completed.');
        endif;
    endif;
enddefine;


define teach_select();
dlocal nn_exitfromproc = teach_select;
dlocal interrupt = nn_interrupt;
lvars netname egsname session incr results targs = false, item = false,
    n_examples;

    if isempty(nn_neural_nets) then
        nui_message(err(NO_NETS));
    elseif isempty(nn_example_sets) then
        nui_message(err(NO_EGSS));
    else
        use_basewindow(true);
        nl(1);
        heading('Teach Example');
        unless nn_use_curr_net then
            select_which_net('Teach Which Network', 'Select') -> netname;
        else
            nn_current_net -> netname;
        endunless;

        returnunless(netname);

        unless nn_use_curr_egs then
            select_which_egs('Using Example From', 'Select') -> egsname;
        else
            nn_current_egs -> egsname;
        endunless;

        ;;; unless we have something for both then exit
        unless netname and egsname then
            return();
        endunless;
        netname -> nn_current_net;
        egsname -> nn_current_egs;

        eg_examples(nn_example_sets(nn_current_egs)) -> n_examples;

        false -> item;

        npr('Please enter the number of the example you wish to use for training.');
        printf(n_examples, 'This should be an integer between 1 and %p.\n');
        until isinteger(item) do
            get_1_item('Which example', isinteger, 'integer') -> item;
            unless item > 0 and item <= n_examples then
                printf(n_examples, 'Integer between 1 and %p needed.\n');
                false -> item;
            endunless;
        enduntil;

        if item then
            if nn_call_genfn then call_genfn(nn_current_egs); endif;
            nn_learn_egs_item(item, nn_current_egs,
                              nn_current_net, nn_training_cycles);
            nui_message('Teaching finished');
        endif;
    endif;
enddefine;


define global test_interactive(egsname, netname);
dlocal nn_exitfromproc = test_interactive;
dlocal interrupt = nn_interrupt;
lvars egsname netname innames outnames intemp outtemp arrayfn
    invec example results network outvec egs n_examples;

    if isword(netname) then
        nn_neural_nets(netname) -> network;
    else
        mishap(netname, 1, 'network name needed');
    endif;

    if isword(egsname) then
        nn_example_sets(egsname) -> egs;
    else
        mishap(egsname, 1, 'example set name needed');
    endif;

    eg_in_template(egs) -> intemp;
    eg_out_template(egs) -> outtemp;
    eg_in_names(egs) -> innames;
    eg_out_names(egs) -> outnames;

    eg_name(egs) -> nn_current_egs;
    eg_examples(egs) -> n_examples;
    netname -> nn_current_net;

    nn_net_array_fn(dataword(nn_neural_nets(nn_current_net))) -> arrayfn;

    if isunknown(eg_in_units(egs)) then
        check_array_size(eg_in_vector(egs), nn_input_units(network),
                false, arrayfn) ->> eg_in_vector(egs) -> invec;
    else
        check_array_size(eg_in_vector(egs), eg_in_units(egs),
                false, arrayfn) ->> eg_in_vector(egs) -> invec;
    endif;

    if isunknown(eg_out_units(egs)) then
        check_array_size(eg_out_vector(egs), nn_output_units(network),
                false, arrayfn) ->> eg_out_vector(egs) -> outvec;
    else
        check_array_size(eg_out_vector(egs), eg_out_units(egs),
                false, arrayfn) ->> eg_out_vector(egs) -> outvec;
    endif;

    nl(1);
    if y_or_n_txt('Use existing data') then
        repeat forever
            ;;; get example index
            false -> example;
            npr('Please enter the number of the example you wish to test.');
            printf(n_examples, 'This should be an integer between 1 and %p.\n');
            until isinteger(example) do
                get_1_item('Which example', isinteger, 'integer') -> example;
                unless example > 0 and example <= n_examples then
                    printf(n_examples, 'Integer between 1 and %p needed.\n');
                    false -> example;
                endunless;
            enduntil;

            if example then
                nn_test_egs_item(example, egsname, netname, false) -> results;

#_IF DEF GFXNEURAL
                if nn_update_wins then
                    nn_update_windows(nn_current_net);
                endif;
#_ENDIF

                if nn_show_targ then
                    nn_browse_list({%results,
                                   subscrl(example, eg_targ_examples(egs))%},
                                   {'Actual' 'Target'});
                else
                    nn_browse_list({%outnames, results%}, {'Field' 'Result'});
                endif;
            endif;
            unless y_or_n_txt('Another test') then quitloop() endunless;
        endrepeat;
    else
        repeat forever
            ;;; get example information from the user
            get_user_example(innames, intemp) -> example;
            if example then
                nn_apply_example(example, intemp, outtemp,
                                 invec, outvec, network) -> results;
            endif;
#_IF DEF GFXNEURAL
            if nn_update_wins then nn_update_windows(nn_current_net) endif;
#_ENDIF
            nn_browse_list({%outnames, results%}, {'Field' 'Result'});
            unless y_or_n_txt('Another test') then quitloop() endunless;
        endrepeat;
    endif;
enddefine;


define test_all();
dlocal nn_exitfromproc = test_all, interrupt = nn_interrupt;
dlocal pop_pr_places = 4;
lvars netname egsname egs_rec targs = false;

    if isempty(nn_neural_nets) then
        nui_message(err(NO_NETS));
    elseif isempty(nn_example_sets) then
        nui_message(err(NO_EGSS));
    else
        use_basewindow(true);
        nl(1);
        heading('Test Network');
        unless nn_use_curr_net then
            select_which_net('Test Which Network', 'Select') -> netname;
        else
            nn_current_net -> netname;
        endunless;

        returnunless(netname);

        unless nn_use_curr_egs then
            select_which_egs('Using Which Example Set', 'Select') -> egsname;
        else
            nn_current_egs -> egsname;
        endunless;

        ;;; unless we have something for both then exit
        unless netname and egsname then
            return();
        endunless;

        netname -> nn_current_net;
        egsname -> nn_current_egs;

        lvars acc;
        nn_result_accuracy(nn_current_egs, nn_current_net) -> acc;
#_IF DEF GFXNEURAL
        if nn_update_wins then nn_update_windows(nn_current_net) endif;
#_ENDIF
        npr('Accuracy:');
        printf(nn_current_egs, 100.0s0 * acc, nn_current_net,
            '%p net gave the correct response for %p%% of the examples in %p\n');
        nn_result_error(nn_current_egs) -> acc;
        printf(acc, 'Network Error: %p\n');
        if nui_confirm('Browse results ?', ['Browse' 'Cancel'], 1) == 1 then
            nn_example_sets(nn_current_egs) -> egs_rec;
            if nn_show_targ then
                nn_browse_list({%eg_out_examples(egs_rec),
                               eg_targ_examples(egs_rec)%},
                               {'Actual' 'Target'});
            else
                nn_browse_list({%eg_out_examples(egs_rec)%}, {'Result'});
            endif;
        endif;
    endif;
enddefine;


define test_select();
dlocal nn_exitfromproc = test_select;
dlocal interrupt = nn_interrupt;
lvars netname egsname;

    if isempty(nn_neural_nets) then
        nui_message(err(NO_NETS));
    elseif isempty(nn_example_sets) then
        nui_message(err(NO_EGSS));
    else
        use_basewindow(true);
        nl(1);
        heading('Test Selected Data');
        unless nn_use_curr_net then
            select_which_net('Test Which Network', 'Select') -> netname;
        else
            nn_current_net -> netname;
        endunless;

        returnunless(netname);

        unless nn_use_curr_egs then
            select_which_egs('Using Which Example Set', 'Select') -> egsname;
        else
            nn_current_egs -> egsname;
        endunless;
        ;;; unless we have something for both then exit
        unless netname and egsname then
            return();
        endunless;
        netname -> nn_current_net;
        egsname -> nn_current_egs;
        test_interactive(nn_current_egs, nn_current_net);
    endif;
enddefine;


define browse_eg_examples();
dlocal nn_exitfromproc = browse_eg_examples;
dlocal interrupt = nn_interrupt;
lvars egsname egs filename filelist ftype outdata;

    if isempty(nn_example_sets) then
        nui_message(err(NO_EGSS));
    else
        use_basewindow(true);
        nl(1);
        heading('Browse Examples');
        unless nn_use_curr_egs then
            select_which_egs('Browse Examples', 'Browse') -> egsname;
        else
            nn_current_egs -> egsname;
        endunless;

        nn_example_sets(egsname) -> egs;

        returnunless(egs);

        if egs_from_literal(egs) or egs_from_proc(egs) then
            eg_gendata(nn_example_sets(nn_current_egs)) -> outdata;
            if not(outdata) or outdata == [] then
                nui_message(sprintf(egsname, 'No examples in example set %p'));
            else
                nn_browse_list({%outdata%}, {'Example'});
            endif;
        elseif egs_from_file(egs) and not(eg_rawdata_in(egs)) then
            get_examplefile_name(egs) -> filename -> ftype;
            if filename then
                ;;; now we have the filename, try to work out how to display it
                if is_char_file_dt(ftype) or is_item_file_dt(ftype) then
                    vededitor(vedhelpdefaults, filename);
                else
                    nui_message('Cannot browse this file using VED');
                endif;
            endif;
        endif;
    endif;
enddefine;


define browse_eg_outputs();
dlocal nn_exitfromproc = browse_eg_outputs;
dlocal interrupt = nn_interrupt;
lvars egsname egs filename filelist ftype outdata;

    if isempty(nn_example_sets) then
        nui_message(err(NO_EGSS));
    else
        use_basewindow(true);
        nl(1);
        heading('Browse Results');
        unless nn_use_curr_egs then
            select_which_egs('Browse Results', 'Browse') -> egsname;
        else
            nn_current_egs -> egsname;
        endunless;

        nn_example_sets(egsname) -> egs;

        returnunless(egs);

        if egs_to_literal(egs) then
            eg_out_examples(egs) -> outdata;
            if not(outdata) or outdata == [] then
                nui_message(sprintf(egsname, 'No results in example set %p'));
            else
                if eg_targ_examples(egs) then
                    nn_browse_list({%eg_out_examples(egs), eg_targ_examples(egs)%},
                        {'Actual' 'Target'});
                else
                    nn_browse_list({%eg_out_examples(egs)%},
                        {'Output'});
                endif;
            endif;
        elseif egs_to_file(egs) and not(eg_rawdata_out(egs)) then
            get_outputfile_name(egs) -> filename -> ftype;
            if filename then
                ;;; now we have the filename, try to work out how to display it
                if is_char_file_dt(ftype) or is_item_file_dt(ftype) then
                    vededitor(vedhelpdefaults, filename);
                else
                    nui_message('Cannot browse this file using VED');
                endif;
            endif;
        else
            nui_message('Cannot browse when destination is a procedure');
        endif;
    endif;
enddefine;


define apply_all();
dlocal nn_exitfromproc = apply_all, interrupt = nn_interrupt;
lvars netname egsname;

    if isempty(nn_neural_nets) then
        nui_message(err(NO_NETS));
    elseif isempty(nn_example_sets) then
        nui_message(err(NO_EGSS));
    else
        use_basewindow(true);
        nl(1);
        heading('Apply Example Set');
        unless nn_use_curr_net then
            select_which_net('Apply To Which Network', 'Select') -> netname;
        else
            nn_current_net -> netname;
        endunless;
        unless nn_use_curr_egs then
            select_which_egs('Using Which Example Set', 'Select') -> egsname;
        else
            nn_current_egs -> egsname;
        endunless;

        ;;; unless we have something for both then exit
        unless netname and egsname then
            return();
        endunless;

        netname -> nn_current_net;
        egsname -> nn_current_egs;

        nn_apply_egs(nn_current_egs, nn_current_net);
#_IF DEF GFXNEURAL
        if nn_update_wins then nn_update_windows(nn_current_net) endif;
#_ENDIF
        nui_message('Apply completed.');
    endif;
enddefine;


define print_activs();
lvars netname;

    if isempty(nn_neural_nets) then
        nui_message(err(NO_NETS));
    else
        use_basewindow(true);
        nl(1);
        heading('Network Activation');
        unless nn_use_curr_net then
            select_which_net('Print Network Activation', 'Print') -> netname;
        else
            nn_current_net -> netname;
        endunless;
        returnunless(netname);
        nn_print_activs(netname);
        txt_pause();
    endif;
enddefine;

define print_weights();
lvars netname;

    if isempty(nn_neural_nets) then
        nui_message(err(NO_NETS));
    else
        use_basewindow(true);
        nl(1);
        heading('Network Weights');
        unless nn_use_curr_net then
            select_which_net('Print Network Weights', 'Print') -> netname;
        else
            nn_current_net -> netname;
        endunless;
        returnunless(netname);
        nn_print_weights(netname);
        txt_pause();
    endif;
enddefine;

define show_trainoptions();
dlocal nn_exitfromproc = show_trainoptions;
dlocal interrupt = nn_interrupt;

    set_options("training_options");
enddefine;

define show_logoptions();
dlocal nn_exitfromproc = show_logoptions;
dlocal interrupt = nn_interrupt;

    set_options("log_options");
enddefine;


/* ----------------------------------------------------------------- *
     Menu-based Shutdown
 * ----------------------------------------------------------------- */

define quit_neural();
    use_basewindow(false);
    nl(1);
    if nui_confirm('Really quit from Poplog-Neural ?',
                ['Exit' 'Cancel'], 1) == 1 then
#_IF DEF XNEURAL
        if popunderx then
            XptDeferApply(sysexit);
            XptSetXtWakeup();
            return();
        endif;
#_ENDIF
        sysexit();
    endif;
enddefine;


/* ----------------------------------------------------------------- *
     Top Level Panel And Menu Definitions
 * ----------------------------------------------------------------- */

;;; The following generic menu labels are used to generate the menu structures
;;; required by the particular UI (terminal, PWM or X). The first item
;;; is maximum width of the menu (usually ignored by PWM and X), the
;;; second item is a boolean flag to signify whether to add the standard
;;; suffix to the menu title or leave it as is, the third item is the
;;; menu title while the rest are the strings which make up the menu options.


vars
help_menu_labels = [20 ^true 'Help' 'Introduction'
                'Using Datatypes' 'Using Example Sets'
                'Teaching Networks' 'Generic Functions' 'Display Functions'
                'Back-propagation nets' 'Competitive Learning nets' 'Index'],

net_menu_labels = [20 ^true 'Networks' 'New' 'Display' 'Edit' 'Copy'
             'Delete' 'Set Current' 'List All' 'Load' 'Save'],

egs_menu_labels = [20 ^true 'Example Sets' 'New' 'Generate' 'Display' 'Edit'
            'Copy' 'Delete' 'Set Current' 'List All' 'Load' 'Save'],

dt_menu_labels = [20 ^true 'Datatypes' 'New' 'Display' 'Edit'
            'Delete' 'Set Current' 'List All' 'Load' 'Save'];


/*
    Panels and menus are lists made up of the following :
        hd(menu) is a list of labels where:
            hd(labels) = menu title,
            tl(labels) = list of menu options.

        tl(menu) is a list of the values to be returned where:
            if the item is a list then the head of the list is
            partially applied to the tail of the list before
            being returned,
            otherwise just the value is returned
*/

define initialise_options_table();
    unless isproperty(ui_options_table) then
        newproperty([], 30, false, "perm") -> ui_options_table;
    endunless;

    [^create_dt ^display_dt ^edit_dt ^delete_dt
        ^set_current_dt ^list_all_dts ^load_dt ^save_dt]
            -> ui_options_table("dt_menu_base");

    [^create_egs ^generate_egs ^display_egs ^edit_egs ^copy_egs ^delete_egs
        ^set_current_egs ^list_all_egss ^load_egs ^save_egs]
            -> ui_options_table("egs_menu_base");

    [^create_net ^display_net ^edit_net ^copy_net ^delete_net
        ^set_current_net ^list_all_nets ^load_net ^save_net]
            -> ui_options_table("net_menu_base");

    [ ['Choose one:'
            'toggle' 'range' 'set'
            'sequence format' 'choice format'
            'character file' 'itemised file' 'line file' 'full file'
            'general']
        ^DT_TOGGLE ^DT_RANGE ^DT_SET
        ^DT_SEQ_FIELD ^DT_CHOICE_FIELD
        ^DT_CHAR_FILE ^DT_ITEM_FILE ^DT_LINE_FILE
        ^DT_FULL_FILE ^DT_GENERAL]
        -> ui_options_table("select_dt_menu");

    [%
        partapply(help_on, [teachneural]),
        partapply(help_on, [datatypes]),
        partapply(help_on, [examplesets]),
        partapply(help_on, [nettraining]),
        partapply(help_on, [netgenerics]),
        partapply(help_on, [netdisplay]),
        partapply(help_on, [backprop]),
        partapply(help_on, [complearn]),
        partapply(help_on, [neuralindex])%] -> ui_options_table("help_menu_base");

    [% ['Training Options' 40
        'Current network'
        'Current example set'
        'Training cycles'
        'Use current network'
        'Use current example set'
        'Use random selection'
        'Call generator function'
        'Update display'
        'Show target result'],
        conspair(ident nn_current_net, "word"),
        conspair(ident nn_current_egs, "word"),
        conspair(ident nn_training_cycles, "integer"),
        conspair(ident nn_use_curr_net, "boolean"),
        conspair(ident nn_use_curr_egs, "boolean"),
        conspair(ident nn_random_select, "boolean"),
        conspair(ident nn_call_genfn, "boolean"),
        conspair(ident nn_update_wins, "boolean"),
        conspair(ident nn_show_targ, "boolean")
    %] -> ui_options_table("training_options");

    [% ['Log Options' 40
        'Write logfile'
        'Logfile name'
        'Log frequency'
        'Include network error'
        'Include accuracy'
        'Include test set'
        'Save network after log'
        'Echo to screen'],
        conspair(ident logfilewrite, "boolean"),
        conspair(ident logfilename, "string"),
        conspair(ident logfrequency, "integer"),
        conspair(ident logerror, "boolean"),
        conspair(ident logaccuracy, "boolean"),
        conspair(ident logtestset, "boolean"),
        conspair(ident logsavenet, "boolean"),
        conspair(ident logecho, "boolean"),
    %] -> ui_options_table("log_options");

    [ [ 'Teach & Test Panel' 25
        'Teach Network'
        'Teach Selected Data'
        'Test Network'
        'Test Selected Data'
        'Apply Example Set'
        'Browse Examples'
        'Browse Results'
        'Print Network Activation'
        'Print Network Weights'
        'Training Options'
        'Log Options']
        ^teach_all ^teach_select ^test_all ^test_select ^apply_all
        ^browse_eg_examples ^browse_eg_outputs
        ^print_activs ^print_weights ^show_trainoptions
        ^show_logoptions ] -> ui_options_table("tat_panel");

    [ ['Main Panel' 16
        'Datatypes'
        'Example Sets'
        'Networks'
        'Teach/Test'
        'Help'
        'Exit']
        [^NUI_MENU dt_menu]
        [^NUI_MENU egs_menu]
        [^NUI_MENU net_menu]
        [^NUI_PANEL tat_panel]
        [^NUI_MENU help_menu]
        ^quit_neural] -> ui_options_table("main_panel");
enddefine;


/* ----------------------------------------------------------------- *
     Top Level Start Up
 * ----------------------------------------------------------------- */

;;; txtneural_startup constructs the menus and options for a character
;;; terminal version of Neural
define txtneural_startup();

    ;;; set up input streams to read from terminal
    proglist_new_state(charin) -> proglist_state;

    false -> GUI;
    build_txt_menu(net_menu_labels) :: ui_options_table("net_menu_base")
            -> ui_options_table("net_menu");
    build_txt_menu(egs_menu_labels) :: ui_options_table("egs_menu_base")
            -> ui_options_table("egs_menu");
    build_txt_menu(dt_menu_labels) :: ui_options_table("dt_menu_base")
            -> ui_options_table("dt_menu");
    build_txt_menu(help_menu_labels) :: ui_options_table("help_menu_base")
            -> ui_options_table("help_menu");
    use_basewindow(true);
    nl(3);
    bold_on();
    npr('            (c) Integral Solutions Ltd. and');
    npr('                The University Of Sussex 1990-1995.');
    npr('                All Rights Reserved');
    bold_off();
    nl(3);
    txt_pause();
enddefine;


#_IF DEF PWMNEURAL
;;; pwmneural_startup constructs the menus and other UI components
;;; for a PWM version of the Neural interface
define pwmneural_startup();

    ;;; get Poplog running
    syssetup();
    sysinitcomp();

    ;;; then the standard graphics setup
    nn_gfx_setup();

    ;;; now the UI setup
    build_pwm_menu(net_menu_labels) :: ui_options_table("net_menu_base")
            -> ui_options_table("net_menu");
    build_pwm_menu(egs_menu_labels) :: ui_options_table("egs_menu_base")
            -> ui_options_table("egs_menu");
    build_pwm_menu(dt_menu_labels) :: ui_options_table("dt_menu_base")
            -> ui_options_table("dt_menu");
    build_pwm_menu(help_menu_labels) :: ui_options_table("help_menu_base")
            -> ui_options_table("help_menu");
    nn_banner -> pwm_windowlabel(pwmbasewindow);
    PWM_SRC -> pwmgfxrasterop;
    {170 93} -> pwm_window_location(pwmbasewindow);
    show_banner_pwm(false);         ;;; need to add dummy argument
    {0 93} -> pwm_window_location(pwmnxtwin);
enddefine;
#_ENDIF

#_IF DEF XNEURAL
;;; xneural_startup constructs the menus and other UI components
;;; for an X version of the Neural interface
define xneural_startup();

    ;;; get Poplog running
    syssetup();
    sysinitcomp();

    ;;; then the standard graphics setup
    nn_gfx_setup();

    ;;; now the UI specific setup
    propsheet_init();
    build_x_menu(net_menu_labels) :: ui_options_table("net_menu_base")
            -> ui_options_table("net_menu");
    build_x_menu(egs_menu_labels) :: ui_options_table("egs_menu_base")
            -> ui_options_table("egs_menu");
    build_x_menu(dt_menu_labels) :: ui_options_table("dt_menu_base")
            -> ui_options_table("dt_menu");
    build_x_menu(help_menu_labels) :: ui_options_table("help_menu_base")
            -> ui_options_table("help_menu");
enddefine;
#_ENDIF

define global nn_init();

#_IF DEF UNIX
    systranslate('TERM') -> nn_terminal;
    if nn_terminal then
        consword(nn_terminal) -> nn_terminal;
    endif;
#_ELSE
    vedtermsetup();
    vedterminalname -> nn_terminal;
#_ENDIF
    setpop -> interrupt;
    'teachneural' -> vedteachname;
    'mainmenu' -> vedhelpname;
    'neuralindex' -> vedrefname;
    trycompile('$poplib/neuralinit.p')->;
    initialise_options_table();    ;;; setup ui_options_table and base menus

#_IF DEF PWMNEURAL
    if popunderpwm then
        pwmneural_startup();
        chain("main_panel", display_control_panel);
    endif;
#_ENDIF

#_IF DEF XNEURAL
    if popunderx then
        xneural_startup();
        chain("main_panel", display_control_panel);
    endif;
#_ENDIF

    txtneural_startup();
    chain("main_panel", display_control_panel);
enddefine;

;;; txtneural_shutdown performs any actions associated with the
;;; character terminal version of Neural
define txtneural_shutdown();
    setpop();
enddefine;

#_IF DEF PWMNEURAL
;;; pwmneural_shutdown closes down all windows associated with Neural
;;; when running under the PWM
define pwmneural_shutdown();
lvars tmp_id;
    applist(prop_list(nn_window_record), nn_kill_window);
    if ispwm_id(ui_options_table("main_panel_win") ->> tmp_id)
      and islivepwm_id(tmp_id) then
        pwm_killwindow(tmp_id);
    endif;
    if ispwm_id(ui_options_table("banner_win") ->> tmp_id)
       and islivepwm_id(tmp_id) then
        pwm_killwindow(tmp_id);
    endif;
    if ispwm_id(ui_options_table("tat_panel_win") ->> tmp_id)
       and islivepwm_id(tmp_id) then
        pwm_killwindow(tmp_id);
    endif;
    if ispwm_id(ui_options_table("log_options_win") ->> tmp_id)
       and islivepwm_id(tmp_id) then
        pwm_killwindow(tmp_id);
    endif;
    if ispwm_id(ui_options_table("training_options_win") ->> tmp_id)
       and islivepwm_id(tmp_id) then
        pwm_killwindow(tmp_id);
    endif;
    false ->> ui_options_table("banner_win")
          ->> ui_options_table("main_panel_win")
          -> ui_options_table("training_options_win");
enddefine;
#_ENDIF


#_IF DEF XNEURAL
;;; xneural_shutdown closes down all the windows in the X
;;; version of Neural
define xneural_shutdown();
    sysexit();
enddefine;
#_ENDIF

define global nn_exit();
#_IF DEF PWMNEURAL
    if popunderpwm then
        pwmneural_shutdown();
        setpop();
    endif;
#_ENDIF
#_IF DEF XNEURAL
    if popunderx then
        xneural_shutdown();
        setpop();
    endif;
#_ENDIF
    txtneural_shutdown();
    setpop();
enddefine;

define macro neural;
    nn_init();
enddefine;

endexload_batch;

endsection;     /* $-popneural */

global vars nui_main = true;            ;;; for "uses"

/*  --- Revision History --------------------------------------------------
--- Julian Clinton, 30/8/95
    Added exload_batch/endexload_batch.
-- Julian Clinton, 26/8/95
    Added missing lvars declaration in test_all.
-- Julian Clinton, 27/4/93
    Fixed PNF0039 (delete example set prompt under X actually says 'Copy').
    nn_init now assigns setpop to interrupt rather than assigning
    interrupt to nn_exitfromproc.
-- Julian Clinton, 26/1/93
    Corrected bug which caused generate_egs to always use the current egs
        and ignore what the user types in.
-- Julian Clinton, 17/11/92
    Prevented the 'Generate Example Sets' dialog from appearing when
        a new example set is loaded (now simply lists the newly loaded
        example sets). Now only happens in text mode.
    Also corrected checking for displaying target results.
-- Julian Clinton, 12/11/92
    Fixed a couple of typos and modified display of results when the
        'show target' flag is false in -test_all-.
-- Julian Clinton, 15/9/92
    Made datatype, example sets and network names appear in a dialog for
        GUI versions.
-- Julian Clinton, 28/8/92
    Added support for allowing user to specify that output items
        should be ignored during a call to -nn_generate_egs-.
-- Julian Clinton, 18/8/92
    Various minor bug fixes and enhancements.
    Removed use of fmatches.
-- Julian Clinton, 12/8/92
    #_IF'd out the support for continuous data.
-- Julian Clinton, 3/8/92
    Made -select_exec- and -sub_menu- text only.
-- Julian Clinton, 27/7/92
    Modified calls to show_panel_gfx and show_options_gfx to simply pass
        the panel name.
    Renamed GFX to GFXNEURAL.
-- Julian Clinton, 24/7/92
    Modified for splitting menus, options and panels into discrete types.
    Added some of the basic support for X.
    Modified panel definition format.
-- Julian Clinton, 17/7/92
    Renamed to nui_main.p and added nui_main variable.
-- Julian Clinton, 30/6/92
    Added support for field and file format datatype entry.
-- Julian Clinton, 27/6/92
    Added support for toggle datatype.
    Allowed user to specify example data source and whether the data
        is discrete or continuous.
-- Julian Clinton, 22/6/92
    Added support for supplying threshold value to sets in -create_dt-.
-- Julian Clinton, 19/6/92
    Modified menu creation - generic menu structures now used to create
        valid menu structures for the appropriate UI (txt, PWM or X) at
        runtime rather than storing separate formats.
    Split UI startup and shutdown code into seprate procs depending on UI.
    Changed show_menu_gfx to show_panel_gfx and split the functionality
        of showing control panels (which can contain menus and exec buttons)
        from those which are effectively property sheets (now displayed by
        -show_options_gfx-).
    Modified panels to use idents rather than words for variables.
    Renamed -top_menu- to -display_control_panel-.
    Changed "main_menu" and "main_menu_win" to "main_panel" and
        "main_panel_win".
    Changed "var_options" and "var_options_win" to "training_options" and
        "training_options_win".
-- Julian Clinton, 18/6/92
    Re-ordered creation of field names in create_egs. This means the user
        gets more "friendly" feedback if required.
-- Julian Clinton, 10/6/92
    Renamed eg_out_info and eg_targ_info to eg_out_examples and
        eg_targ_examples.
    Modifed teach_all and teach_select so that they no longer
        execute the events in nn_events list during training (this
        facility has now been made part of the functionality of
        nn_learn_egs and nn_learn_egs_item).
-- Julian Clinton, 1/6/92
    Now ensures generated egs, datatype and network names do not conflict
        with existing egs, datatypes and networks.
-- Julian Clinton, 29/5/92
    Menus and window ids now held in ui_options_table rather than
        variables.
    Moved menu definitions in from menudefs.p (now deleted).
    Added compiler checks for compiling GUI code (makes txt_top_level.p
        redundant).
    Now uses fmatches.
-- Julian Clinton, 8/5/92
    Sectioned.
-- Julian Clinton, PNE0044, 23 Aug 1990
    changed field names for browsing results
-- Julian Clinton, PNE0018, Aug 1990
    changed create_egs to allow multiple field definitions
-- Julian Clinton, PNE0017, Aug 1990
    added print statments for input and output units in nn_create_bpnet
    and nn_create_clnet
*/
