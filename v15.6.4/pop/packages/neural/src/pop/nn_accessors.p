/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:           $popneural/src/pop/nn_accessors.p
 > Purpose:        network accessor functions
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:
 */

section $-popneural =>  nn_input_units
                        nn_output_units
                        nn_hidden_layers
                        nn_net_layers
                        nn_total_layers
                        nn_units_in_layer
                        nn_groups_in_layer
                        nn_start_group_in_layer
                        nn_units_in_group
                        nn_max_units_in_layer
                        nn_node_group_index
                        nn_index_in_layer
                        nn_node_absgroup_index
                        nn_net_type
                        nn_layer_bias
                        nn_layer_activation
                        nn_layer_weights
                        nn_print_activs
                        nn_print_weights
;

/* ----------------------------------------------------------------- *
    Predicates
 * ----------------------------------------------------------------- */

define constant isinputlayer(layer, network);
lvars layer;
    layer == 0
enddefine;

define constant isempty(struct);
lvars struct;
    datalength(struct) == 0
enddefine;


/* ----------------------------------------------------------------- *
    Main Access Functions
 * ----------------------------------------------------------------- */

define global constant nn_input_units(network);
lvars type = dataword(network);
    if type == "bpropnet" then
        bpninunits(network);
    elseif type == "clearnnet" then
        clninunits(network);
    else
        false
    endif;
enddefine;

define global constant nn_output_units(network);
lvars type = dataword(network);
    if type == "bpropnet" then
        bpnoutunits(network);
    elseif type == "clearnnet" then
        clnoutunits(network);
    else
        false
    endif;
enddefine;

;;; number of hidden layers (i.e. excluding input and output layers)
define global constant nn_hidden_layers(network);
lvars type = dataword(network);
    if type == "bpropnet" then
        bpnlevels(network) fi_- 1;
    elseif type == "clearnnet" then
        clnlevels(network) fi_- 1;
    else
        false
    endif;
enddefine;

;;; array of number of nodes in each layer
;;; from first hidden layer to output
define global constant nn_net_layers(network);
lvars type = dataword(network);
    if type == "bpropnet" then
        bpnhunits(network);
    elseif type == "clearnnet" then
        clnhunits(network);
    else
        false
    endif;
enddefine;

;;; total number of layers including input and output layers
define global constant nn_total_layers(network);
lvars type = dataword(network);
    if type == "bpropnet" then
        bpnlevels(network) fi_+ 1;
    elseif type == "clearnnet" then
        clnlevels(network) fi_+ 1;
    else
        false
    endif;
enddefine;

define global constant nn_units_in_layer(layer, network);
lvars type = dataword(network);
    if type == "bpropnet" then
        if layer == 0 then
            bpninunits(network);
        else
            bpnhunits(network)(layer);
        endif;
    elseif type == "clearnnet" then
        if isinputlayer(layer, network) then
            clninunits(network);
        else
            clnhunits(network)(layer);
        endif;
    else
        false
    endif;
enddefine;

define global constant nn_groups_in_layer(layer, network);
lvars type = dataword(network);
    if type == "bpropnet" then
        1
    elseif type == "clearnnet" then
        if isinputlayer(layer, network) then
            1
        else
            clclustlev(network)(layer);
        endif;
    else
        false
    endif;
enddefine;

define global constant nn_start_group_in_layer(layer, network);
lvars type = dataword(network), i start_group = 1;
    if type == "bpropnet" then
        1               ;;; only one group per layer
    elseif type == "clearnnet" then
        fast_for i from 2 to layer do
            start_group fi_+ clclustlev(network)(i fi_- 1) -> start_group;
        endfast_for;
        start_group;
    else
        false
    endif;
enddefine;

define global constant nn_units_in_group(layer, group, network);
lvars type = dataword(network);
    if type == "bpropnet" then
        if layer == 0 then
            network.bpninunits;
        else
            bpnhunits(network)(layer);
        endif;
    elseif type == "clearnnet" then
        if layer == 0 then
            network.clninunits;
        else
            clclusters(network)
                (group fi_+ nn_start_group_in_layer(layer, network) - 1);
        endif;
    else
        false
    endif;
enddefine;

define global constant nn_max_units_in_layer(network);
lvars type = dataword(network), i max_n;
    if type == "bpropnet" then
        max(bpninunits(network), bp_maxunits(network));
    elseif type == "clearnnet" then
        clninunits(network) -> max_n;
        fast_for i from 1 to network.clnlevels do
            if clnhunits(network)(i) > max_n
                then
                   clnhunits(network)(i) -> max_n;
            endif;
        endfast_for;
        max_n;
    else
        false
    endif;
enddefine;

;;; given a node, layer and network, returns the group the node is in
;;; and the index within the group
define global constant nn_node_group_index(node, layer, network) /*-> index -> group */;
lvars type = dataword(network), i, group, start_group;
    if type == "bpropnet" then
        1, node;
    elseif type == "clearnnet" then
        if layer == 0 then
            1, node;
        else
            nn_start_group_in_layer(layer, network) ->> start_group -> group;
            while clclusters(network)(group) < node do
                node fi_- clclusters(network)(group) -> node;
                group fi_+ 1 -> group;
            endwhile;
            group fi_+ 1 fi_- start_group, node;
        endif;
    else
        false
    endif;
enddefine;

;;; given an index, group, layer and network, returns
;;; the absolute index of the node in the layer
define global constant nn_index_in_layer(index, group, layer, network) /*-> absindex */;
lvars type = dataword(network), group, start_group end_group
    absindex = 0;
    if type == "bpropnet" then
        index;
    elseif type == "clearnnet" then
        if isinputlayer(layer, network) then
            index
        else
            nn_start_group_in_layer(layer, network) -> start_group;
            start_group fi_+ group - 2 -> end_group;
            fast_for group from start_group to end_group do
                absindex + clclusters(network)(group) -> absindex;
            endfast_for;
            absindex + index;
        endif;
    else
        false
    endif;
enddefine;


define global constant nn_node_absgroup_index(node, layer, network) /*-> index -> group */;
lvars type = dataword(network),
      group = nn_start_group_in_layer(layer,network);
    if type == "bpropnet" then
        1, node;
    elseif type == "clearnnet" then
        if isinputlayer(layer, network) then
            1, node;
        else
            while clclusters(network)(group) < node do
                node fi_- clclusters(network)(group) -> node;
                group fi_+ 1 -> group;
            endwhile;
            group, node;
        endif;
    else
        false
    endif;
enddefine;

define global constant nn_net_type(network);
lvars network;
    dataword(network);
enddefine;


;;; returns a list of arrays of biases for layer. Each array
;;; represents the biases of a group in the layer.
define global constant nn_layer_bias(layer, network);
lvars type = dataword(network), group_activs;
    if layer fi_>= 0 and layer fi_< nn_total_layers(network) then
        if type == "bpropnet" then
            if layer == 0 then
                [%bpinputarr(network)%];
            else
                ;;; need to list for consistency
                [%bpbiases(network)(layer)%];
            endif;
        elseif type == "clearnnet" then
            if layer == 0 then
                [%clinputarr(network)%];
            else
                clbiases(network)(layer);
            endif;
        else
            false
        endif;
    else
        false
    endif;
enddefine;


;;; returns a list of arrays of activations for layer. Each array
;;; represents the activations of a group in the layer.
define global constant nn_layer_activation(layer, network);
lvars type = dataword(network), group_activs;
    if layer fi_>= 0 and layer fi_< nn_total_layers(network) then
        if type == "bpropnet" then
            if layer == 0 then
                [%bpinputarr(network)%];
            else
                ;;; need to list for consistency
                [%bpactivs(network)(layer)%];
            endif;
        elseif type == "clearnnet" then
            if layer == 0 then
                [%clinputarr(network)%];
            else
                clactivs(network)(layer);
            endif;
        else
            false
        endif;
    else
        false
    endif;
enddefine;


;;; returns a list of arrays of weights from layer - 1 to layer
define global constant nn_layer_weights(layer, network);
lvars type = dataword(network);
    if layer fi_> 0 and layer fi_< nn_total_layers(network) then
        if type == "bpropnet" then
            ;;; both results return as list
            [%bpweights(network)(layer)%];
        elseif type == "clearnnet" then
            clweights(network)(layer);
        else
            false
        endif;
    else
        false
    endif;
enddefine;


/* ----------------------------------------------------------------- *
    Network Printing Functions
 * ----------------------------------------------------------------- */

define global constant nn_print_activs(netname);
lvars netname machine type;
    if isword(netname) then
       nn_neural_nets(netname)
    else
       netname
    endif -> machine;
    dataword(machine) -> type;
    if type == "bpropnet" then
        pr_bpactivs(machine);
    elseif type == "clearnnet" then
        pr_clactivs(machine);
    else
        npr(type >< ' is not a valid network type');
    endif;
enddefine;


define global constant nn_print_weights(netname);
lvars netname machine type;
    if isword(netname) then
       nn_neural_nets(netname)
    else
       netname
    endif -> machine;
    dataword(machine) -> type;
    if type == "bpropnet" then
        pr_bpweights(machine);
    elseif type == "clearnnet" then
        pr_clweights(machine);
    else
        npr(type >< ' is not a valid network type');
    endif;
enddefine;

endsection; /* $-popneural */

global vars nn_accessors = true;


/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 9/9/92
    PNF0018: Moved nn_print_weights and nn_print_activs in here.
-- Julian Clinton, 17/7/92
    Renamed from accessors.p to nn_accessors.p.
-- Julian Clinton, 8/5/92
    Sectioned.
*/
