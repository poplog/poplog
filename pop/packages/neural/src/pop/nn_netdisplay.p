/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved ---------
 > File:           $popneural/src/pop/nn_netdisplay.p
 > Purpose:        top level display procedures for graphics consoles
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:  nn_gfxdefs.p nn_gfxdraw.p nn_gfxevents.p
 */

section $-popneural =>  nn_show_topology
                        nn_show_bias
                        nn_show_activs
                        nn_show_weights_to
                        nn_show_weights_from
                        nn_show_extent
                        nn_kill_window
                        nn_kill_windows
                        nn_update_window
                        nn_update_windows
                        nn_redraw_window
;


/* ----------------------------------------------------------------- *
    Visible Functions
 * ----------------------------------------------------------------- */

define global nn_show_topology(netname, rows, cols,
                        row_col_offset, pos) -> wid;
lvars netname network layer row_col_offset pos wid = false,
    rows, cols, win_rec;

    if isword(netname) then
        nn_neural_nets(netname) -> network;
    else
        mishap(netname, 1,'Network name needed');
    endif;

    ;;; first create the window record
    make_window_record(netname, nn_total_layers(network), rows, cols,
                       row_col_offset(1), row_col_offset(2),
                       [%
                            nn_total_layers(network),
                            nn_max_units_in_layer(network)
                       %],
                       "topology") -> win_rec;

    ;;; now create an appropriate blank window
    make_window(win_rec, netname >< ' topology', pos,
                cell_w * 2, cell_h * 2,
                cell_w, 0) ->> nn_win_id(win_rec) -> wid;

    if nn_win_id(win_rec) then
        win_rec -> nn_window_record(nn_win_id(win_rec));

        add_topology_event_handlers(wid);

        ;;; create a mapping between the cells on the window
        ;;; and the nodes in the network layer
        make_topology_map(win_rec);

        ;;; draw the topology on the window
        clear_window(wid);
        draw_topology(win_rec);
        draw_top_activs(win_rec);
    else
        warning(0, err(FAIL_WINMAKE));
    endif;
enddefine;


define global nn_show_bias(netname, layer, rows, cols,
                                      pos) -> wid;
lvars netname network layer row_col_offset = [0 0],
      pos format = {%rows, cols%}, wid = false, rows, cols, win_rec;

    if isword(netname) then
        nn_neural_nets(netname) -> network;
    else
        mishap(netname, 1,'Network name needed');
    endif;

    unless format then
        hd(make_format_list(nn_units_in_layer(layer, network))) -> format;
    endunless;

    ;;; first create the window record
    make_window_record(netname, [%layer, 1, 1%], rows, cols,
                       row_col_offset(1), row_col_offset(2),
                       format, "bias2d") -> win_rec;

    ;;; now create an appropriate blank window
    make_window(win_rec,
                sprintf(layer, netname, '%p layer %p bias'),
                pos, cell_w, cell_w, 0, 0) ->> nn_win_id(win_rec) -> wid;

    if nn_win_id(win_rec) then
        win_rec -> nn_window_record(nn_win_id(win_rec));

        add_bias_event_handlers(wid);

        ;;; create a mapping between the cells on the window
        ;;; and the nodes in the network layer
        make_layer_map(win_rec);

        ;;; draw the activations on the window
        clear_window(wid);
        draw_bias(win_rec);
    else
        warning(0, err(FAIL_WINMAKE));
    endif;

enddefine;


define global constant nn_show_activs(netname, layer, rows, cols,
                                      pos) -> wid;
lvars netname network layer row_col_offset = [0 0],
      pos format = {%rows, cols%}, wid = false, rows, cols, win_rec;

    if isword(netname) then
        nn_neural_nets(netname) -> network;
    else
        mishap(netname, 1,'Network name needed');
    endif;

    unless format then
        hd(make_format_list(nn_units_in_layer(layer, network))) -> format;
    endunless;

    ;;; first create the window record
    make_window_record(netname, [%layer, 1, 1%], rows, cols,
                       row_col_offset(1), row_col_offset(2),
                       format, "activs2d") -> win_rec;

    ;;; now create an appropriate blank window
    make_window(win_rec,
                sprintf(layer, netname, '%p layer %p activation'),
                pos, cell_w, cell_w, 0, 0) ->> nn_win_id(win_rec) -> wid;

    if nn_win_id(win_rec) then
        win_rec -> nn_window_record(nn_win_id(win_rec));

        add_activs_event_handlers(wid);

        ;;; create a mapping between the cells on the window
        ;;; and the nodes in the network layer
        make_layer_map(win_rec);

        ;;; draw the activations on the window
        clear_window(wid);
        draw_activs(win_rec);
    else
        warning(0, err(FAIL_WINMAKE));
    endif;

enddefine;


define global nn_show_weights_to(netname, layer, group, node,
                                          rows, cols, pos) -> wid;
lvars netname network layer group node row_col_offset = {0 0},
      pos format = {%rows, cols%}, wid = false, rows, cols, win_rec;

    if isword(netname) then
        nn_neural_nets(netname) -> network;
    else
        mishap(netname, 1,'Network name needed');
    endif;

    unless format then
    ;;; subtract 1 from layer because we need a map for layer below
        hd(make_format_list(nn_units_in_layer(layer - 1, network)))
           -> format;
    endunless;

    make_window_record(netname,
                       [% layer - 1, group, node%],
                       rows, cols,
                       row_col_offset(1), row_col_offset(2),
                       format, "weights2d_to") -> win_rec;

    ;;; now create an appropriate blank window
    make_window(win_rec,
                sprintf(node, group, layer, netname,
                        '%p wts to (%p,%p,%p)'),
                pos, cell_w, cell_w, 0, 0) ->> nn_win_id(win_rec) -> wid;

    if nn_win_id(win_rec) then
        win_rec -> nn_window_record(nn_win_id(win_rec));
        nn_win_id(win_rec) -> wid;

        add_weights_event_handlers(wid);

        ;;; create a mapping between the cells on the window
        ;;; and the nodes in the network layer
        make_layer_map(win_rec);

        ;;; draw the activations on the window
        clear_window(wid);
        draw_weights2d_to(win_rec);
    else
        warning(0, err(FAIL_WINMAKE));
    endif;
enddefine;


define global nn_show_weights_from(netname, layer, group, node,
                                            rows, cols, pos) -> wid;
lvars netname network layer group node row_col_offset = {0 0},
      pos format = {%rows, cols%}, wid = false, rows, cols, win_rec;

    if isword(netname) then
        nn_neural_nets(netname) -> network;
    else
        mishap(netname, 1,'Network name needed');
    endif;

    ;;; add 1 to layer to get map for next layer
    unless format then
        hd(make_format_list(nn_units_in_layer(layer + 1, network))) -> format;
    endunless;

    ;;; node is either an integer if displaying a bp net or
    ;;; a vector,list etc containing the node and the node group
    ;;; if displaying a cl net
    make_window_record(netname,
                       [% layer + 1, group, node %],
                       rows, cols,
                       row_col_offset(1), row_col_offset(2),
                       format, "weights2d_from") -> win_rec;

    ;;; now create an appropriate blank window
    make_window(win_rec,
                sprintf(node, group, layer, netname,
                        '%p wts from (%p,%p,%p)'),
                pos, cell_w, cell_w, 0, 0) ->> nn_win_id(win_rec) -> wid;
    if nn_win_id(win_rec) then
        win_rec -> nn_window_record(nn_win_id(win_rec));
        nn_win_id(win_rec) -> wid;

        add_weights_event_handlers(wid);

        ;;; create a mapping between the cells on the window
        ;;; and the nodes in the network layer
        make_layer_map(win_rec);

        ;;; draw the activations on the window
        clear_window(wid);
        draw_weights2d_from(win_rec);
    else
        warning(0, err(FAIL_WINMAKE));
    endif;
enddefine;


;;; nn_kill_window takes a window id and kills the particular window
define global nn_kill_window(wid);
lvars wid win_rec = nn_window_record(wid), type;
    if win_rec then
        nn_win_type(win_rec) -> type;
        if type == "topology" then
            topology_quit(wid);
        elseif type == "weights2d" then
            weights_quit(wid);
        elseif type == "bias2d" then
            bias_quit(wid);
        elseif type == "activs2d" then
            activs_quit(wid);
        endif;
    elseif is_extent_window(wid) then
        extent_quit(wid);
    endif;
enddefine;

;;; nn_kill_windows kills all windows associated with a particular
;;; network
define global nn_kill_windows(netname);
lvars netname network win
      win_list = [%appproperty(nn_window_record, conspair)%];

    if isword(netname) then
        nn_neural_nets(netname) -> network;
    else
        mishap(netname, 1,'Network name needed');
    endif;

    for win in win_list do
        if nn_win_net(fast_back(win)) == netname then
            nn_kill_window(fast_front(win));
        endif;
    endfor;
enddefine;



define global nn_show_extent(nwid);
lvars nwid wid = false, win_rec = nn_window_record(nwid),
     ext_rec;

    ;;; if this window already has an extent window then kill it off
    if (nn_win_ext(win_rec) ->> wid) then
        nn_kill_window(nn_ext_id(nn_win_ext(win_rec)));
        false -> wid;
    endif;

    ;;; create the extent window record
    make_extent_record(win_rec) -> ext_rec;

    ;;; create the window
    make_extent_window( ext_rec, nn_win_net(win_rec) >< ' extent',
                        windowlocation_gfx(nn_win_id(win_rec)))
                      ->> nn_ext_id(ext_rec) -> wid;

    if nn_ext_id(ext_rec) then
        ;;; now draw on the window
        ;;; and add the main window id to the is_extent_window
        ;;; hash table

        nn_win_id(win_rec) -> is_extent_window(nn_ext_id(ext_rec));

        nn_ext_id(ext_rec) -> wid;
        ext_rec -> nn_win_ext(win_rec);

        add_extent_event_handlers(wid);
        clear_window(wid);
        draw_extent_window(ext_rec);
    else
        warning(0, err(FAIL_WINMAKE));
    endif;
enddefine;


;;; nn_update_window updates the display of a particular window
define global nn_update_window(nwid);
lvars nwid, win_rec = nn_window_record(nwid), type;
    if win_rec then
        nn_win_type(win_rec) -> type;
        if type == "topology" then
            draw_top_activs(win_rec);
        elseif type == "weights2d_from" then
            draw_weights2d_from(win_rec);
        elseif type == "weights2d_to" then
            draw_weights2d_to(win_rec);
        elseif type == "bias2d" then
            draw_bias(win_rec);
        elseif type == "activs2d" then
            draw_activs(win_rec);
        endif;
        applist(nn_win_select(win_rec), select_vector_apply(%win_rec%));
    endif;
enddefine;

;;; nn_update_windows takes a network and updates all the windows
;;; associated with that network;
define global nn_update_windows(netname);
lvars netname network win win_list = [%appproperty(nn_window_record, conspair)%];
    if isword(netname) then
        nn_neural_nets(netname) -> network;
    else
        mishap(netname, 1,'Network name needed');
    endif;

    for win in win_list do
        if nn_win_net(fast_back(win)) == netname then
            nn_update_window(fast_front(win));
        endif;
    endfor;
enddefine;

;;; Next procedure is added to the nn_events list when the update window
;;; flag is true
;;;
define global nn_winrefresh;
    nn_update_windows(nn_current_net);
enddefine;


;;; nn_redraw_window takes a window record and redraws the window
;;; associated with that window
define global nn_redraw_window(nwid);
lvars nwid, win_rec = nn_window_record(nwid), type;
    if win_rec then
        clear_window(nn_win_id(win_rec));
        nn_win_type(win_rec) -> type;
        if type == "topology" then
            draw_topology(win_rec);
            draw_top_activs(win_rec);
            draw_all_links(win_rec);
        elseif type == "weights2d_from" then
            draw_weights2d_from(win_rec);
        elseif type == "weights2d_to" then
            draw_weights2d_to(win_rec);
        elseif type == "bias2d" then
            draw_bias(win_rec);
        elseif type == "activs2d" then
            draw_activs(win_rec);
        endif;
        applist(nn_win_select(win_rec), select_vector_apply(%win_rec%));
    endif;

enddefine;


/* ----------------------------------------------------------------- *
    Functions Called From Menus Which Add Or Remove Information
    Displayed In The Current Window
 * ----------------------------------------------------------------- */

define select_node(row, col, op, dir, win_rec);
lvars row col win_rec;
    fill(row, col, op, dir, initv(4)) :: nn_win_select(win_rec)
                                        -> nn_win_select(win_rec);
enddefine;

define show_weights_to(row, col, win_rec);
lvars row col win_rec;
    select_node(row, col,
                partapply(draw_weights_to, [%win_rec%]), "to", win_rec);
    draw_links_to(row, col, win_rec);
    apply(row, col, win_select_fn(hd(nn_win_select(win_rec))));
enddefine;

define show_stims_to(row, col, win_rec);
lvars row col win_rec;
    select_node(row, col,
                partapply(draw_stims_to, [%win_rec%]), "to", win_rec);
    draw_links_to(row, col, win_rec);
    apply(row, col, win_select_fn(hd(nn_win_select(win_rec))));
enddefine;

define show_weights_from(row, col, win_rec);
lvars row col win_rec;
    select_node(row, col,
                partapply(draw_weights_from, [%win_rec%]), "from", win_rec);
    draw_links_from(row, col, win_rec);
    apply(row, col, win_select_fn(hd(nn_win_select(win_rec))));
enddefine;

define show_stims_from(row, col, win_rec);
lvars row col win_rec;
    select_node(row, col,
                partapply(draw_stims_from, [%win_rec%]), "from", win_rec);
    draw_links_from(row, col, win_rec);
    apply(row, col, win_select_fn(hd(nn_win_select(win_rec))));
enddefine;

define deselect_node(row, col, win_rec);
lvars row col vec_list vec win_rec;
    get_node_select(row, col, win_rec) -> vec_list;
    fast_for vec in vec_list do
        if win_select_dir(vec) == "from" then
            undraw_links_from(row, col, win_rec);
            draw_box_layer(false, nn_win_map(win_rec), row fi_- 1,
                            nn_win_cols(win_rec), dcell_w + half_cell_w,
                            nn_win_id(win_rec));
            delete(vec, nn_win_select(win_rec), 1)
                -> nn_win_select(win_rec);
        elseif win_select_dir(vec) == "to" then
            undraw_links_to(row, col, win_rec);
            draw_box_layer(false, nn_win_map(win_rec), row fi_+ 1,
                            nn_win_cols(win_rec), half_cell_w,
                            nn_win_id(win_rec));
            delete(vec, nn_win_select(win_rec), 1)
                -> nn_win_select(win_rec);
        endif;
    endfast_for;
enddefine;


/* ----------------------------------------------------------------- *
    Functions Called From Menus Which Produce A New Window
 * ----------------------------------------------------------------- */

define show_bias2d(row, col, win_rec);
lvars row col win_rec layer sizes result;
    win_map_layer(nn_win_map(win_rec)(row, col)) -> layer;
    make_format_list(nn_units_in_layer(layer,
                                        nn_neural_nets(nn_win_net(win_rec))))
        -> sizes;

    select_window_dimensions(sizes) -> result;

    if islist(sizes) then
        sys_grbg_list(sizes);
    endif;

    if result then
        nn_show_bias(nn_win_net(win_rec), layer, result(1), result(2),
                       false) ->;
    endif;
enddefine;


define show_activs2d(row, col, win_rec);
lvars row col win_rec layer sizes result;
    win_map_layer(nn_win_map(win_rec)(row, col)) -> layer;
    make_format_list(nn_units_in_layer(layer,
                                        nn_neural_nets(nn_win_net(win_rec))))
        -> sizes;

    select_window_dimensions(sizes) -> result;

    if islist(sizes) then
        sys_grbg_list(sizes);
    endif;

    if result then
        nn_show_activs(nn_win_net(win_rec), layer, result(1), result(2),
                       false) ->;
    endif;
enddefine;


define show_weights2d_to(row, col, win_rec);
lvars row col win_rec layer group index sizes result
      netname = nn_win_net(win_rec),
      net = nn_neural_nets(netname),
      entry = nn_win_map(win_rec)(row, col);

    win_map_layer(entry) -> layer;
    win_map_group(entry) -> group;
    win_map_index(entry) -> index;
    unless layer < 1 then
        make_format_list(nn_units_in_layer(layer - 1, net))
            -> sizes;

        select_window_dimensions(sizes) -> result;

        if islist(sizes) then
            sys_grbg_list(sizes);
        endif;

        if result then
            nn_show_weights_to(netname, layer, group, index,
                               result(1), result(2), false) ->;
        endif;
    endunless;
enddefine;


define show_weights2d_from(row, col, win_rec);
lvars row col win_rec layer group index sizes result
      netname = nn_win_net(win_rec),
      net = nn_neural_nets(netname),
      entry = nn_win_map(win_rec)(row, col);

    win_map_layer(entry) -> layer;
    win_map_group(entry) -> group;
    win_map_index(entry) -> index;
    unless layer > nn_total_layers(net) then
        make_format_list(nn_units_in_layer(layer + 1, net))
            -> sizes;

        select_window_dimensions(sizes) -> result;

        if islist(sizes) then
            sys_grbg_list(sizes);
        endif;

        if result then
            nn_show_weights_from(netname, layer, group, index,
                                 result(1), result(2), false) ->;
        endif;
    endunless;
enddefine;


/* ----------------------------------------------------------------- *
    Functions Called From The Background Menu
 * ----------------------------------------------------------------- */

define update_win(win_rec);
lvars win_rec, wid = false;
    if isnn_window(win_rec) then
        nn_update_window(nn_win_id(win_rec));
    endif;
enddefine;

define redraw_win(win_rec);
lvars win_rec, wid = false;
    if isnn_window(win_rec) then
        nn_redraw_window(nn_win_id(win_rec));
    endif;
enddefine;

define extent_win(win_rec);
lvars win_rec, wid = false;
    if isnn_window(win_rec) then
        nn_show_extent(nn_win_id(win_rec));
    endif;
enddefine;


/* ----------------------------------------------------------------- *
     Graphics Window Menu Definitions
 * ----------------------------------------------------------------- */

;;; initialise_gfx_menus is called the first time an attempt is made
;;; to access the menu table. It constructs the table (a property) and
;;; builds either X or PWM menus. It then calls the property on the
;;; supplied argument (which should have been left on the stack).
;;;
define initialise_gfx_menus();
#_IF DEF PWMNEURAL
    define lconstant initpwm_menus();
        'Unit\tweights from\tstimulation from\tweights to\tstimulation to\tdeselect\t'
            :: [^show_weights_from ^show_stims_from ^show_weights_to ^show_stims_to ^deselect_node]
                -> gfxmenu_table("top_menu1");

        'New Window\tlayer activation\tlayer bias\tweights from this unit\tweights to this unit\t'
            :: [^show_activs2d ^show_bias2d ^show_weights2d_from ^show_weights2d_to]
                -> gfxmenu_table("top_menu3");

        'Background\tupdate window\tredraw window\tshow extent\t'
            :: [^update_win ^redraw_win ^extent_win]
                -> gfxmenu_table("background_menu");
    enddefine;
#_ENDIF

#_IF DEF XNEURAL
    define lconstant initx_menus();
        ['Unit' 'weights from' 'stimulation from' 'weights to' 'stimulation to' 'deselect']
            :: [^show_weights_from ^show_stims_from ^show_weights_to ^show_stims_to ^deselect_node]
                -> gfxmenu_table("top_menu1");

        ['New Window' 'layer activation' 'layer bias' 'weights from this unit' 'weights to this unit']
            :: [^show_activs2d ^show_bias2d ^show_weights2d_from ^show_weights2d_to]
                -> gfxmenu_table("top_menu3");

        ['Background' 'update window' 'redraw window' 'show extent']
            :: [^update_win ^redraw_win ^extent_win]
                -> gfxmenu_table("background_menu");
    enddefine;
#_ENDIF

    newproperty([], 5, false, "perm") -> gfxmenu_table;

#_IF DEF XNEURAL
    if popunderx then
        initx_menus();
        ;;; now get the appropriate menu structure
        return(gfxmenu_table());
    endif;
#_ENDIF

#_IF DEF PWMNEURAL
    if popunderpwm then
        initpwm_menus();
        ;;; now get the appropriate menu structure
        return(gfxmenu_table());
    endif;
#_ENDIF
enddefine;

;;; the first time an attempt is made to access the menu table,
;;; the menus are constructed and assigned into the menu table.
;;;
vars gfxmenu_table = initialise_gfx_menus;

global vars nn_netdisplay = true;

endsection;     /* $-popneural */

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 18/11/92
    Modified all nn_show_* procs so they clear the window before drawing
        (needed if default beckground colour isn't white).
-- Julian Clinton, 13/8/92
    Moved colour map setup to -make_window- in nn_gfxutils.p.
-- Julian Clinton, 31/7/92
    Added X support for menus.
-- Julian Clinton, 17/7/92
    Renamed from gfxdisplay.p to nn_netdisplay.p
-- Julian Clinton, 19/6/92
    Moved definitions of display menus into here (from gfxdefs.p).
    Commented out weights_menu1 and activs_menu1.
-- Julian Clinton, 10/6/92
    Modified mishaps.
-- Julian Clinton, 8/5/92
    Sectioned.
*/
