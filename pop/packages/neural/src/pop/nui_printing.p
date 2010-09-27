/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved ---------
 > File:           $popneural/src/pop/nui_printing.p
 > Purpose:        display procedures for standard terminals
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:  nui_txtedit.p
 */

section $-popneural =>  nn_print_input
                        nn_pr_net
                        nn_pr_egs
                        nn_pr_dt

;

pr(';;; Loading printing utilities\n');

uses nn_dtconverters;
uses nn_examplesets;
uses nui_utils;

/* ----------------------------------------------------------------- *
    Visible Functions
 * ----------------------------------------------------------------- */

define global constant nn_print_input(invec);
lvars invec i;
    nl(1);
    pr('Input    :  ');
    for i from 1 to length(invec) do
        format_print('~7,3F', {%invec(i)%});
    endfor;
    nl(1);
enddefine;


define global constant nn_pr_net(netname);
lvars net netname layers layer group;
lconstant width = 35;

    if isword(netname) then
        nn_neural_nets(netname)
    else
        netname
    endif -> net;

    use_basewindow(true);
    nl(1);
    pr_field('Network: ', width, ` `, false);
    npr(netname);
    pr_field('Type: ', width, ` `, false);
    npr(nn_net_type(net));
    pr_field('Input nodes: ', width, ` `, false);
    npr(nn_input_units(net));
    pr_field('Output nodes: ', width, ` `, false);
    npr(nn_output_units(net));
    pr_field('Hidden layers: ', width, ` `, false);
    npr(nn_hidden_layers(net) ->> layers);
    if nn_net_type(net) == "bpropnet" then
        for layer from 1 to layers do
            pr('Nodes in hidden layer  ');
            pr(layer);
            pr(' : ');
            npr(nn_units_in_layer(layer, net));
        endfor;
    elseif nn_net_type(net) == "clearnnet" then
        for layer from 1 to layers do
            pr('Format of hidden layer ');
            pr(layer);
            pr(' : ');
            for group from 1 to nn_groups_in_layer(layer, net) do
                spr(nn_units_in_group(layer, group, net));
            endfor;
            nl(1);
        endfor;
    endif;
    nl(2);
enddefine;


define global constant nn_pr_egs(egsname);
lvars egs egsname index = 1, data_source data_dest discrete_p = false;
lconstant width = 35,
    tab1 = 8, tab2 = 20, tab3 = 12, tab4 = 24;
    if isword(egsname) then
        nn_example_sets(egsname)
    else
        egsname
    endif -> egs;
    use_basewindow(true);
    nl(1);
    pr_field('Example Set Name: ', width, ` `, false);
    npr(eg_name(egs));
    pr_field('Data source: ', width, ` `, false);
    eg_data_source(egs) -> data_source;
    if egs_from_file(data_source) then
        'data file(s)'
    elseif egs_from_proc(data_source) then
        sprintf(eg_gen_params(egs), 'procedure %p');
    elseif egs_from_egs(data_source) then
        sprintf(eg_gen_params(egs), 'example set "%p"');
    elseif egs_from_literal(data_source) then
        'literal data'
    else false
    endif.npr;

    pr_field('Data destination: ', width, ` `, false);
    eg_data_destination(egs) -> data_dest;
    if egs_to_file(data_dest) then
        'data file(s)'
    elseif egs_to_proc(data_dest) then
        sprintf(eg_apply_params(egs), 'procedure %p');
    elseif egs_to_egs(data_dest) then
        sprintf(eg_apply_params(egs), 'example set "%p"');
    elseif egs_to_literal(data_dest) then
        'literal data'
    else false
    endif.npr;

#_IF DEF NEURAL_CONTINUOUSDATA
    eg_discrete(egs) -> discrete_p;
    pr_field('Data organisation: ', width, ` `, false);
    if discrete_p then
        "discrete"
    else
        "continuous"
    endif.npr;
#_ENDIF

    pr_field('Keep parsed examples: ', width, ` `, false);
    if eg_keep_egs(egs) then
        "yes"
    else
        "no"
    endif.npr;

    pr_field('No. of examples: ', width, ` `, false);
    npr(eg_examples(egs));

    pr('\nExample Format\n');
    pr_field('Index', tab1, ` `, false);
    pr(': ');
    pr_field('Name', tab2, false, ` `);
    pr_field('Direction', tab3, false, ` `);
    pr_field('Type', tab4, false, ` `);
    nl(1);
    lvars type;
    for type in eg_template(egs) do
        pr_field(index, tab1, ` `, false);
        pr(': ');
        if islist(type) then
            pr_field(nn_template_name(type), tab2, false, ` `);
            pr_field(nn_template_io(type), tab3, false, ` `);
            pr_field(nn_template_type(type), tab4, false, ` `);
        else
            pr_field("none", tab2, false, ` `);
            pr_field('----', tab3, false, ` `);
            pr_field('----', tab4, false, ` `);
        endif;
        nl(1);
        index + 1 -> index;
    endfor;
    nl(2);
enddefine;


define global constant nn_pr_dt(dtname);
dlocal pop_pr_quotes = false;
lvars dt dtname type;
lconstant width = 35;

    if isword(dtname) then
        nn_datatypes(dtname)
    else
        dtname
    endif -> dt;

    use_basewindow(true);
    nl(1);
    pr_field('Datatype Name: ', width, ` `, false);
    npr(dtname);
    pr_field('Generic Type: ', width, ` `, false);
    npr(nn_dt_type(dt));
    nn_dt_type(dt) -> type;
    if type == "set" then
        pr_field('Output threshold: ', width, ` `, false);
        npr(nn_dt_setthreshold(dt));
        print_list('Set members:', nn_dt_setmembers(dt));
    elseif type == "range" then
        pr_field('Lower bound: ', width, ` `, false);
        npr(nn_dt_lowerbound(dt));
        pr_field('Upper bound: ', width, ` `, false);
        npr(nn_dt_upperbound(dt));
    elseif type == "toggle" then
        pr_field('True value: ', width, ` `, false);
        npr(nn_dt_toggle_true(dt));
        pr_field('False value: ', width, ` `, false);
        npr(nn_dt_toggle_false(dt));
    else
        pr_field('Values needed: ', width, ` `, false);
        npr(nn_items_needed(dt));
        pr_field('Nodes needed: ', width, ` `, false);
        npr(nn_units_needed(dt));
        pr_field('Input converter: ', width, ` `, false);
        npr(nn_dt_inconv(dt));
        pr_field('Output converter: ', width, ` `, false);
        npr(nn_dt_outconv(dt));
    endif;
    nl(2);
enddefine;

endsection;     /* $-popneural */

global vars nui_printing = true;         ;;; for "uses"

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 27/8/95
    Added missign lvars declaration in nn_pr_egs.
-- Julian Clinton, 9/9/92
    PNF0018: Moved nn_print_weights and nn_print_activs to nn_accessors.p
-- Julian Clinton, 21/8/92
    Renamed -eg_genfn- to -eg_gen_params- and -eg_applyfn- to
        -eg_apply_params-.
-- Julian Clinton, 12/8/92
    #_IF'd out the support for continuous data.
-- Julian Clinton, 17/7/92
    Renamed from txtdisplay.p to nui_printing.p.
-- Julian Clinton, 2/7/92
    Added display of data destination.
-- Julian Clinton, 27/6/92
    Added support for discrete/continous data and data source.
    Changed printers to use pr_field rather than printf.
-- Julian Clinton, 26/6/92
    Added support for toggle datatype.
-- Julian Clinton, 22/6/92
    Added display of -nn_dt_setthreshold- in -nn_pr_dt-.
-- Julian Clinton, 8/5/92
    Sectioned.
*/
