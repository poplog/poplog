/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved ---------
 > File:            $popneural/src/pop/nn_gfxdraw.p
 > Purpose:         graphics display for neural networks
 > Author:          Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:   nn_gfxdefs.p, nn_gfxevents.p, nui_main.p
 */

section $-popneural;

/* ----------------------------------------------------------------- *

Procedures defined in this file:

    draw_box_pwm(xcent, ycent, plusx, plusy, minusx, minusy,
    draw_box_x(xcent, ycent, plusx, plusy, minusx, minusy,
    draw_box(xcent, ycent, scale, wid, positive, clear_box);
    draw_cell_pwm(x, y, wid);
    draw_cell_x(x, y, wid);
    clear_window(wid);
    draw_extent_diagram(cols, rows, col_scale, row_scale, netname, wid);
    draw_extent_region( start_x, start_y, width, height, wid, op);
    draw_top_groups_pwm(wid, rows, cols, win_map, network);
    draw_top_groups_x(wid, rows, cols, win_map, network);
    draw_links_to_pwm(from_row, n_cols, end_x, end_y, start_y,
    draw_links_to_x(from_row, n_cols, end_x, end_y, start_y,
    generic_draw_links_to(row, col, win_rec, op);
    draw_links_from_pwm(to_row, n_cols, start_x, start_y, end_y,
    draw_links_from_x(to_row, n_cols, start_x, start_y, end_y,
    generic_draw_links_from(row, col, win_rec, op);
    draw_links_to();
    undraw_links_to();
    draw_links_from();
    undraw_links_from();
    draw_topology(win_rec);
    draw_box_layer(data_access, win_map, row, cols, offset_h, wid);
    draw_top_activs(win_rec);
    draw_top_input(win_rec);
    draw_weights_to(row, col, win_rec);
    draw_weights_from(row, col, win_rec);
    draw_stims_to(row, col, win_rec);
    draw_stims_from(row, col, win_rec);
    draw_bias(win_rec);
    draw_activs(win_rec);
    draw_weights2d_to(win_rec);
    draw_weights2d_from(win_rec);
    draw_all_links(win_rec);
    draw_extent_window(ext_rec);

 * ----------------------------------------------------------------- */


/* ----------------------------------------------------------------- *
    Low Level Graphic Operations
 * ----------------------------------------------------------------- */

#_IF DEF PWMNEURAL
define draw_box_pwm(xcent, ycent, plusx, plusy, minusx, minusy,
                 scale, point, positive, clear_box, wid);
lvars xcent ycent plusx plusy minusx minusy scale point
    positive clear_box wid;
dlocal pwmgfxrasterop, pwmgfxpaintnum,
       pwmgfxsurface = wid;
lconstant border = half_cell_w - 1;

    PWM_CLR -> pwmgfxrasterop;
    if clear_box then
        if nn_use_colour then
            pwmsun_gfxusecms(nn_colour_map);
            0 -> pwmgfxpaintnum;
        endif;
        pwm_gfxwipearea(xcent fi_- border, ycent fi_- border,
                        cell_w fi_- 1, cell_w fi_- 1);
    endif;
    if nn_use_colour then
        pwmsun_gfxusecms(nn_colour_map);
        colour_of(scale, positive) -> pwmgfxpaintnum;
        PWM_SRC -> pwmgfxrasterop;
        pwm_gfxwipearea(xcent fi_- border, ycent fi_- border,
                        cell_w fi_- 1, cell_w fi_- 1);
    else
        PWM_SRC -> pwmgfxrasterop;
        if positive then
            pwm_gfxdrawline(minusx, minusy,
                            plusx, minusy,
                            plusx, plusy,
                            minusx, plusy,
                            minusx, minusy, 5);
        else
            pwm_gfxwipearea(minusx, minusy,
                            2 fi_* point fi_+ 1, 2 fi_* point fi_+ 1);
        endif;
    endif;
enddefine;
#_ENDIF


#_IF DEF XNEURAL
define draw_box_x(xcent, ycent, plusx, plusy, minusx, minusy,
                 scale, point, positive, clear_box, wid);
lconstant border = half_cell_w - 1;
lvars xcent ycent plusx plusy minusx minusy scale point
    positive clear_box wid;

    if nn_use_colour then
        if clear_box then
            CLR_OP -> fast_XptValue(wid, XtN function);
            XpwFillRectangle(wid, xcent fi_- border, ycent fi_- border,
                                  cell_w fi_- 1, cell_w fi_- 1);
        endif;

        nn_colour_map(colour_of(scale, positive))
                    -> fast_XptValue(wid, XtN foreground);
        SRC_OP -> fast_XptValue(wid, XtN function);
        XpwFillRectangle(wid, xcent fi_- border, ycent fi_- border,
                        cell_w fi_- 1, cell_w fi_- 1);
    else
        SRC_OP -> fast_XptValue(wid, XtN function);
        if clear_box then
            nn_white_pixel -> fast_XptValue(wid, XtN foreground);
            XpwFillRectangle(wid, xcent fi_- border, ycent fi_- border,
                                  cell_w fi_- 1, cell_w fi_- 1);
        endif;

        nn_black_pixel -> fast_XptValue(wid, XtN foreground);
        if positive then
            XpwDrawRectangle(wid, minusx, minusy,
                            plusx - minusx, plusy - minusy);
        else
            XpwFillRectangle(wid, minusx, minusy,
                            2 fi_* point fi_+ 1, 2 fi_* point fi_+ 1);
        endif;
    endif;
enddefine;
#_ENDIF

global vars procedure draw_box_gfx =
    CHECK_GFXSWITCH draw_box_x draw_box_pwm draw_box_gfx;


define /* constant */ draw_box(xcent, ycent, scale, wid, positive, clear_box);
lvars
      point = min(abs(intof(half_cell_w * scale)), half_cell_w),
      xcent ycent clear_box
      minusx = xcent fi_- point,
      minusy = ycent fi_- point,
      plusx = xcent fi_+ point,
      plusy = ycent fi_+ point;

    draw_box_gfx(xcent, ycent, plusx, plusy, minusx, minusy,
                 scale, point, positive, clear_box, wid);
enddefine;


#_IF DEF PWMNEURAL
define draw_cell_pwm(x, y, wid);
lvars x y wid lines;
dlocal pwmgfxrasterop = PWM_SRC, pwmgfxpaintnum
       pwmgfxsurface = wid;

    if nn_use_colour then
        pwmsun_gfxusecms(nn_colour_map);
        1 -> pwmgfxpaintnum;
    endif;

    fast_for lines from 0 to 3 do
        pwm_gfxdrawline(x, y fi_+ cell_w fi_* lines,
                        x fi_+ cell_w, y fi_+ cell_w fi_* lines,
                        2);
    endfast_for;
    pwm_gfxdrawline(x, y,
                    x, y fi_+ cell_h,
                    2);
    pwm_gfxdrawline(x fi_+ cell_w, y,
                    x fi_+ cell_w, y fi_+ cell_h,
                    2);
enddefine;
#_ENDIF

#_IF DEF XNEURAL
define draw_cell_x(x, y, wid);
lvars x y yc wid lines;

    if nn_use_colour then
        nn_colour_map(1) -> fast_XptValue(wid, XtN foreground);
    else
        nn_black_pixel -> fast_XptValue(wid, XtN foreground);
    endif;

    SRC_OP -> fast_XptValue(wid, XtN function);

    fast_for lines from 1 to 2 do
        XpwDrawLine(wid, x, (y fi_+ cell_w fi_* lines) ->> yc,
                        x fi_+ cell_w, yc);
    endfast_for;
    XpwDrawRectangle(wid, x, y, cell_w, cell_h);
enddefine;
#_ENDIF

global vars procedure draw_cell =
    CHECK_GFXSWITCH draw_cell_x draw_cell_pwm draw_cell;


define /* constant */ clear_window(wid);
#_IF DEF PWMNEURAL
dlocal  pwmgfxsurface pwmgfxrasterop;
#_ENDIF
lvars wid;

#_IF DEF XNEURAL
    if popunderx then
        CLR_OP -> fast_XptValue(wid, XtN function);
        XpwClearWindow(wid);
        return();
    endif;
#_ENDIF

#_IF DEF PWMNEURAL
    if popunderpwm then
        wid -> pwmgfxsurface;
        PWM_CLR -> pwmgfxrasterop;
        pwm_gfxwipearea(false);
        return();
    endif;
#_ENDIF
enddefine;


define /* constant */ draw_extent_diagram(cols, rows, col_scale, row_scale, netname, wid);
#_IF DEF PWMNEURAL
dlocal pwmgfxsurface pwmgfxrasterop pwmgfxpaintnum;
#_ENDIF

lvars cols rows col_scale row_scale net wid
      net = nn_neural_nets(netname),
      layers = nn_total_layers(net),
      win_row = 0, start_col, end_col, y_coord, net_layer, layer_len,
      half_row_scale = row_scale div 2;

#_IF DEF PWMNEURAL
    if popunderpwm then
        wid -> pwmgfxsurface;
        PWM_SRC -> pwmgfxrasterop;
    endif;
#_ENDIF

    fast_for net_layer from layers fi_- 1 by -1 to 0 do
        nn_units_in_layer(net_layer, net) -> layer_len;
        (cols fi_- layer_len) div 2 -> start_col;
        min(layer_len fi_+ start_col, cols) -> end_col;
        start_col * col_scale -> start_col;
        end_col * col_scale fi_- 1 -> end_col;
        win_row * row_scale -> y_coord;
        win_row + 1 -> win_row;

#_IF DEF XNEURAL
        if popunderx then
            nn_black_pixel -> fast_XptValue(wid, XtN foreground);
            SRC_OP -> fast_XptValue(wid, XtN function);
            XpwDrawRectangle(wid, start_col, y_coord,
                            end_col fi_- start_col, half_row_scale);
            nextloop();
        endif;
#_ENDIF

#_IF DEF PWMNEURAL
        if popunderpwm then
            pwm_gfxdrawline(start_col, y_coord, end_col, y_coord,
                            end_col, y_coord + half_row_scale,
                            start_col, y_coord + half_row_scale,
                            start_col, y_coord, 5);
            nextloop();
        endif;
#_ENDIF
    endfast_for;
enddefine;


define /* constant */ draw_extent_region( start_x, start_y, width, height, wid, op);
lvars start_x start_y width height wid op;

#_IF DEF PWMNEURAL
dlocal  pwmgfxsurface pwmgfxrasterop;

    if popunderpwm then
        wid -> pwmgfxsurface;
        op -> pwmgfxrasterop;
        pwm_gfxwipearea(start_x, start_y, width, height);
        return();
    endif;
#_ENDIF

#_IF DEF XNEURAL
    if popunderx then
        1 -> fast_XptValue(wid, XtN foreground);
        op -> fast_XptValue(wid, XtN function);
        XpwFillRectangle(wid, start_x, start_y, width, height);
        return();
    endif;
#_ENDIF
enddefine;


#_IF DEF PWMNEURAL
define /* constant */ draw_top_groups_pwm(wid, rows, cols, win_map, network);
lconstant qcell_h = intof(cell_h / 4),
          qcell_w = intof(cell_w / 4);
lvars row col entry top_y upper_y lower_y left_x,
      wid, rows, cols, win_map;

dlocal  pwmgfxsurface = wid, pwmgfxpaintnum, pwmgfxrasterop = PWM_SRC;

    if nn_use_colour then
        pwmsun_gfxusecms(nn_colour_map);
        1 -> pwmgfxpaintnum;
    endif;

    fast_for row from 1 to rows do
        (row fi_- 1) * dcell_h -> top_y;
        max(0, top_y fi_- qcell_h) -> upper_y;
        top_y fi_+ cell_h fi_+ qcell_h -> lower_y;
        fast_for col from 1 to cols do
            if (win_map(row, col)->> entry) then
                (col - 1) * dcell_w + cell_w -> left_x;
                pwm_gfxdrawline(left_x, upper_y,
                                left_x fi_+ cell_w, upper_y, 2);
                pwm_gfxdrawline(left_x, lower_y,
                                left_x fi_+ cell_w, lower_y, 2);
                if win_map_index(entry) == 1 then       ;;; start group
                    pwm_gfxdrawline(left_x fi_- qcell_w, upper_y,
                                    left_x fi_- qcell_w, lower_y, 2);
                endif;
                if win_map_index(entry) ==
                  nn_units_in_group(win_map_layer(entry),
                                     win_map_group(entry),
                                     network) then  ;;; end group
                    pwm_gfxdrawline(left_x fi_+ cell_w fi_+ qcell_w,
                                    upper_y,
                                    left_x fi_+ cell_w fi_+ qcell_w,
                                    lower_y, 2);
                endif;
            endif;
        endfast_for;
    endfast_for;
enddefine;
#_ENDIF


#_IF DEF XNEURAL
define /* constant */ draw_top_groups_x(wid, rows, cols, win_map, network);
lconstant qcell_h = intof(cell_h / 4),
          qcell_w = intof(cell_w / 4);
lvars row col entry top_y upper_y lower_y left_x,
      wid, rows, cols, win_map
    xval yval;          ;;; used as temporary stores

    if nn_use_colour then
        nn_colour_map(1) -> fast_XptValue(wid, XtN foreground);
    else
        nn_black_pixel -> fast_XptValue(wid, XtN foreground);
    endif;

    SRC_OP -> fast_XptValue(wid, XtN function);
    fast_for row from 1 to rows do
        (row fi_- 1) * dcell_h -> top_y;
        max(0, top_y fi_- qcell_h) -> upper_y;
        top_y fi_+ cell_h fi_+ qcell_h -> lower_y;

        fast_for col from 1 to cols do
            if (win_map(row, col)->> entry) then
                (col - 1) * dcell_w + cell_w -> left_x;
                XpwDrawLine(wid, left_x, upper_y,
                            (left_x fi_+ cell_w) ->> xval, upper_y);
                XpwDrawLine(wid, left_x, lower_y, xval, lower_y);

                if win_map_index(entry) == 1 then       ;;; start group
                    XpwDrawLine(wid, (left_x fi_- qcell_w) ->> xval, upper_y,
                                     xval, lower_y);
                endif;

                if win_map_index(entry) ==
                  nn_units_in_group(win_map_layer(entry),
                                     win_map_group(entry),
                                     network) then  ;;; end group
                    XpwDrawLine(wid,
                                (left_x fi_+ cell_w fi_+ qcell_w) ->> xval,
                                upper_y, xval, lower_y);
                endif;
            endif;
        endfast_for;
    endfast_for;
enddefine;
#_ENDIF

global vars procedure draw_top_groups =
    CHECK_GFXSWITCH draw_top_groups_x draw_top_groups_pwm
                draw_top_groups;


;;;
;;; The next set of routines are used to draw all the links
;;; a unit in one layer from the all units in the previous layer.
;;;
#_IF DEF PWMNEURAL
define draw_links_to_pwm(from_row, n_cols, end_x, end_y, start_y,
                        win_map, wid, op);
lvars from_row n_cols end_x end_y start_y win_map wid op col;
dlocal pwmgfxsurface = wid, pwmgfxpaintnum,
       pwmgfxrasterop = op;

    if nn_use_colour then
        pwmsun_gfxusecms(nn_colour_map);
        1 -> pwmgfxpaintnum;
    endif;

    fast_for col from 1 to n_cols do
        if win_map(from_row, col) then
            pwm_gfxdrawline((col fi_- 1) * dcell_w fi_+ ohcell_w,
                            start_y, end_x, end_y, 2);
        endif;
    endfast_for;
enddefine;
#_ENDIF


#_IF DEF XNEURAL
define draw_links_to_x(from_row, n_cols, end_x, end_y, start_y,
                        win_map, wid, op);
lvars from_row n_cols end_x end_y start_y win_map wid op col colour_num;

    if op == CLR_OP then
        0
    else
        1
    endif -> colour_num;

    if nn_use_colour then
        nn_colour_map(colour_num) -> fast_XptValue(wid, XtN foreground);
    else
        if colour_num == 0 then
            nn_white_pixel
        else
            nn_black_pixel
        endif -> fast_XptValue(wid, XtN foreground);
    endif;

    SRC_OP -> fast_XptValue(wid, XtN function);

    fast_for col from 1 to n_cols do
        if win_map(from_row, col) then
            XpwDrawLine(wid, (col fi_- 1) * dcell_w fi_+ ohcell_w,
                            start_y, end_x, end_y);
        endif;
    endfast_for;
enddefine;
#_ENDIF

global vars procedure draw_links_to_gfx =
    CHECK_GFXSWITCH draw_links_to_x draw_links_to_pwm draw_links_to_gfx;


;;; generic_draw_links_to takes a topology window record and draws
;;; the links to a particular node.
;;; row is the row on the window rather than of the network
define /* constant */ generic_draw_links_to(row, col, win_rec, op);
lvars row col
      network = nn_neural_nets(nn_win_net(win_rec)),
      wid = nn_win_id(win_rec),
      cols = nn_win_cols(win_rec),
      win_map = nn_win_map(win_rec),
      fgroup, findex,
      from_row = row + 1,
      end_h = dcell_h * row - cell_h + 1,
      end_w = dcell_w * (col - 1) + ohcell_w,
      start_h = dcell_h * (from_row - 1) - 1,
      val weights_map;

    unless row fi_>= nn_win_rows(win_rec) then
        draw_links_to_gfx(from_row, cols, end_w, end_h, start_h,
                            win_map, wid, op);
    endunless;
enddefine;


;;;
;;; The next set of routines are used to draw all the links
;;; from a unit in one layer to the all units in the next layer.
;;;
#_IF DEF PWMNEURAL
define draw_links_from_pwm(to_row, n_cols, start_x, start_y, end_y,
                        win_map, wid, op);
lvars to_row n_cols start_x start_y end_y win_map wid op col;

dlocal pwmgfxsurface = wid, pwmgfxpaintnum,
       pwmgfxrasterop = op;

    if nn_use_colour then
        pwmsun_gfxusecms(nn_colour_map);
        1 -> pwmgfxpaintnum;
    endif;

    fast_for col from 1 to n_cols do
        if win_map(to_row, col) then
            pwm_gfxdrawline((col fi_- 1) * dcell_w fi_+ ohcell_w,
                            end_y, start_x, start_y, 2);
        endif;
    endfast_for;
enddefine;
#_ENDIF


#_IF DEF XNEURAL
define draw_links_from_x(to_row, n_cols, start_x, start_y, end_y,
                        win_map, wid, op);
lvars to_row n_cols start_x start_y end_y win_map wid op col colour_num;

    if op == CLR_OP then
        0
    else
        1
    endif -> colour_num;

    if nn_use_colour then
        nn_colour_map(colour_num) -> fast_XptValue(wid, XtN foreground);
    else
        if colour_num == 0 then
            nn_white_pixel
        else
            nn_black_pixel
        endif -> fast_XptValue(wid, XtN foreground);
    endif;

    SRC_OP -> fast_XptValue(wid, XtN function);

    fast_for col from 1 to n_cols do
        if win_map(to_row, col) then
            XpwDrawLine(wid, (col fi_- 1) * dcell_w fi_+ ohcell_w,
                            end_y, start_x, start_y);
        endif;
    endfast_for;
enddefine;
#_ENDIF

global vars procedure draw_links_from_gfx =
    CHECK_GFXSWITCH draw_links_from_x draw_links_from_pwm draw_links_from_gfx;


;;; generic_draw_links_from takes a topology window record and draws
;;; the links from a particular node
;;; row is the row on the window rather than of the network
define /* constant */ generic_draw_links_from(row, col, win_rec, op);
lvars row col
      network = nn_neural_nets(nn_win_net(win_rec)),
      wid = nn_win_id(win_rec),
      cols = nn_win_cols(win_rec),
      win_map = nn_win_map(win_rec),
      fgroup, findex,
      to_row = row - 1,
      start_h = dcell_h * (row - 1) - 1,
      start_w = dcell_w * (col - 1) + ohcell_w,
      end_h = dcell_h * (to_row fi_- 1) fi_+ cell_h fi_+ 1,
      val weights_map;

    unless row fi_< 2 then
        draw_links_from_gfx(to_row, cols, start_w, start_h, end_h,
                        win_map, wid, op);
    endunless;
enddefine;


define draw_links_to();
    generic_draw_links_to(SRC_OP);
enddefine;

define undraw_links_to();
    generic_draw_links_to(CLR_OP);
enddefine;

define draw_links_from();
    generic_draw_links_from(SRC_OP);
enddefine;

define undraw_links_from();
    generic_draw_links_from(CLR_OP);
enddefine;


/* ----------------------------------------------------------------- *
    Main Display Functions
 * ----------------------------------------------------------------- */

;;; draw_topology takes a window record and displays the topology
define /* constant */ draw_topology(win_rec);
lvars
      dcell_w = cell_w * 2,
      dcell_h = cell_h * 2,
      wid = nn_win_id(win_rec),
      rows = nn_win_rows(win_rec),
      cols = nn_win_cols(win_rec),
      win_map = nn_win_map(win_rec),
      row col activ;

    fast_for row from 1 to rows do
        fast_for col from 1 to cols do
            if win_map(row, col) then
                draw_cell((col fi_- 1) fi_* dcell_w fi_+ cell_w,
                          (row fi_- 1) fi_* dcell_h, wid);
            endif;
        endfast_for;
    endfast_for;
    draw_top_groups(wid, rows, cols, win_map,
                    nn_neural_nets(nn_win_net(win_rec)));
enddefine;


define /* constant */ draw_box_layer(data_access, win_map, row, cols, offset_h, wid);
lvars col entry val offset_h data_access win_map row cols wid;
    if row fi_> 0 then
        fast_for col from 1 to cols do
            if win_map(row, col) then
                win_map(row, col) -> entry;
                if data_access then
                    data_access(win_map_group(entry))(win_map_index(entry));
                else
                    0
                endif -> val;
                draw_box((col fi_- 1) fi_* dcell_w fi_+ ohcell_w,
                         (row fi_- 1) fi_* dcell_h fi_+ offset_h,
                         val * nn_activs_scale, wid, val > 0, true);
            endif;
        endfast_for;
    endif;
enddefine;


;;; draw_top_activs takes a topology window record and displays
;;; the activation
define /* constant */ draw_top_activs(win_rec);
lvars
      network = nn_neural_nets(nn_win_net(win_rec)),
      wid = nn_win_id(win_rec),
      rows = nn_win_rows(win_rec),
      cols = nn_win_cols(win_rec),
      row_offset = nn_win_row_offset(win_rec),
      win_map = nn_win_map(win_rec),
      hcell_h = cell_w fi_+ half_cell_w,
      row activs_map;

    lvars layer;
    fast_for row from 1 to rows do
        find_layer(row, cols, win_map) -> layer;
        if layer then
            nn_layer_activation(layer, network) -> activs_map;
            draw_box_layer(activs_map, win_map, row, cols, hcell_h, wid);
        endif;
    endfast_for;
enddefine;


;;; draw_top_input takes a topology window record and displays
;;; the input activation
define /* constant */ draw_top_input(win_rec);
lvars
      network = nn_neural_nets(nn_win_net(win_rec)),
      wid = nn_win_id(win_rec),
      rows = nn_win_rows(win_rec),
      cols = nn_win_cols(win_rec),
      row_offset = nn_win_row_offset(win_rec),
      win_map = nn_win_map(win_rec),
      hcell_h = cell_w fi_+ half_cell_w,
      row activs_map;

    lvars layer;
    fast_for row from rows by -1 to 1 do
        find_layer(row, cols, win_map) -> layer;
        if layer then
            if layer == 0 then
                nn_layer_activation(0, network) -> activs_map;
                draw_box_layer(activs_map, win_map, row, cols, hcell_h, wid);
            endif;
            quitloop();
        endif;
    endfast_for;
enddefine;


;;; draw_weights_to takes a topology window record and displays
;;; the weights from one layer to all nodes in the next
;;; row is the row on the window rather than of the network
define /* constant */ draw_weights_to(row, col, win_rec);
lvars row col
      network = nn_neural_nets(nn_win_net(win_rec)),
      wid = nn_win_id(win_rec),
      cols = nn_win_cols(win_rec),
      win_map = nn_win_map(win_rec),
      entry = win_map(row, col),
      layer = win_map_layer(entry),
      group = win_map_group(entry),
      index = win_map_index(entry),
      from_row = row fi_+ 1,
      offset_h = half_cell_w,
      weights_map val;

    unless (layer fi_< 1) or (from_row fi_> nn_win_rows(win_rec)) then
        ;;; get weights from this row to next
        nn_layer_weights(layer, network) -> weights_map;
        fast_for col from 1 to cols do
            if win_map(from_row, col) then
                win_map(from_row, col) -> entry;
                weights_map(group)
                           (nn_index_in_layer(win_map_index(entry),
                                              win_map_group(entry),
                                              win_map_layer(entry),
                                              network), index) -> val;
                draw_box((col fi_- 1) fi_* dcell_w fi_+ ohcell_w ,
                         row fi_* dcell_h fi_+ offset_h,
                         val * nn_weights_scale, wid, val > 0, true);
            endif;
        endfast_for;
    endunless;
enddefine;


;;; draw_weights_from takes a topology window record and displays
;;; the weights from a node at the given position on the window
;;; row is the row on the window rather than of the network
define /* constant */ draw_weights_from(row, col, win_rec);
lvars row col
      network = nn_neural_nets(nn_win_net(win_rec)),
      wid = nn_win_id(win_rec),
      cols = nn_win_cols(win_rec),
      win_map = nn_win_map(win_rec),
      entry = win_map(row, col),
      layer = win_map_layer(entry),
      index = nn_index_in_layer(win_map_index(entry),
                                win_map_group(entry),
                                layer, network),
      to_row = row - 1,
      offset_h = dcell_w + half_cell_w,
      val weights_map;

    unless (row fi_< 2) or (layer fi_>= nn_total_layers(network)) then
        ;;; get weights from this row to next
        nn_layer_weights(layer + 1, network) -> weights_map;
        fast_for col from 1 to cols do
            if win_map(to_row, col) then
                win_map(to_row, col) -> entry;
                weights_map(win_map_group(entry))
                           (index, win_map_index(entry)) -> val;
                draw_box((col fi_- 1) fi_* dcell_w fi_+ ohcell_w ,
                         (to_row fi_- 1) fi_* dcell_h fi_+ offset_h,
                         val * nn_weights_scale, wid, val > 0, true);
            endif;
        endfast_for;
    endunless;
enddefine;



;;; draw_stims_to takes a topology window record and displays
;;; the stimulation (activation * weights) to a particular node
;;; row is the row on the window rather than of the network
define /* constant */ draw_stims_to(row, col, win_rec);
lvars row col
      network = nn_neural_nets(nn_win_net(win_rec)),
      wid = nn_win_id(win_rec),
      cols = nn_win_cols(win_rec),
      win_map = nn_win_map(win_rec),
      entry = win_map(row, col),
      layer = win_map_layer(entry),
      group = win_map_group(entry),
      index = win_map_index(entry),
      from_row = row fi_+ 1,
      offset_h = half_cell_w,
      fgroup findex weights_map val activs_map;

    unless (layer fi_< 1) or (from_row fi_> nn_win_rows(win_rec)) then
        ;;; get weights from this row to next
        nn_layer_weights(layer, network) -> weights_map;
        nn_layer_activation(layer fi_- 1 , network) -> activs_map;
        fast_for col from 1 to cols do
            if win_map(from_row, col) then
                win_map(from_row, col) -> entry;
                win_map_group(entry) -> fgroup;
                win_map_index(entry) -> findex;
                activs_map(fgroup)(findex) *
                  weights_map(group)
                             (nn_index_in_layer(findex, fgroup,
                                                win_map_layer(entry),
                                                network), index) -> val;
                draw_box((col fi_- 1) fi_* dcell_w fi_+ ohcell_w ,
                         row fi_* dcell_h fi_+ offset_h,
                         val * nn_weights_scale, wid, val > 0, true);
            endif;
        endfast_for;
    endunless;
enddefine;


;;; draw_stims_from takes a topology window record and displays
;;; the stimulation (activation * weights) from a particular node.
;;; row is the row on the window rather than of the network
define /* constant */ draw_stims_from(row, col, win_rec);
lvars row col
      network = nn_neural_nets(nn_win_net(win_rec)),
      wid = nn_win_id(win_rec),
      cols = nn_win_cols(win_rec),
      win_map = nn_win_map(win_rec),
      entry = win_map(row, col),
      layer = win_map_layer(entry),
      group = win_map_group(entry),
      index = win_map_index(entry),
      to_row = row - 1,
      offset_h = dcell_w + half_cell_w,
      val weights_map node_activ;

    unless (row fi_< 2) or (layer fi_>= nn_total_layers(network)) then
        ;;; get weights from this row to next
        nn_layer_weights(layer + 1, network) -> weights_map;
        nn_layer_activation(layer, network)(group)(index) -> node_activ;
        fast_for col from 1 to cols do
            if win_map(to_row, col) then
                win_map(to_row, col) -> entry;
                node_activ *
                  weights_map(win_map_group(entry))
                             (index, win_map_index(entry)) -> val;
                draw_box((col fi_- 1) fi_* dcell_w fi_+ ohcell_w ,
                         (to_row fi_- 1) fi_* dcell_h fi_+ offset_h,
                         val * nn_weights_scale, wid, val > 0, true);
            endif;
        endfast_for;
    endunless;
enddefine;



;;; draw_bias takes a window record and displays the biases
define /* constant */ draw_bias(win_rec);
lvars network = nn_neural_nets(nn_win_net(win_rec)),
      wid = nn_win_id(win_rec),
      layer = win_info_layer(nn_win_info(win_rec)),
      format = nn_win_format(win_rec),
      rows = nn_win_rows(win_rec),
      cols = nn_win_cols(win_rec),
      entry
      bias_map = nn_layer_bias(layer, network),
      row col bias
      win_map = nn_win_map(win_rec);

    fast_for row from 1 to rows do
        fast_for col from 1 to cols do
            if (win_map(row, col) ->> entry) then
                bias_map(win_map_group(entry))(win_map_index(entry))
                         -> bias;
                draw_box(col * cell_w - half_cell_w ,
                         row * cell_w - half_cell_w,
                         bias * nn_bias_scale, wid, bias > 0, true);
            endif;
        endfast_for;
    endfast_for;
enddefine;


;;; draw_activs takes a window record and displays the activations
define /* constant */ draw_activs(win_rec);
lvars network = nn_neural_nets(nn_win_net(win_rec)),
      wid = nn_win_id(win_rec),
      layer = win_info_layer(nn_win_info(win_rec)),
      format = nn_win_format(win_rec),
      rows = nn_win_rows(win_rec),
      cols = nn_win_cols(win_rec),
      entry
      activs_map = nn_layer_activation(layer, network),
      row col activ
      win_map = nn_win_map(win_rec);

    fast_for row from 1 to rows do
        fast_for col from 1 to cols do
            if (win_map(row, col) ->> entry) then
                activs_map(win_map_group(entry))(win_map_index(entry))
                           -> activ;
                draw_box(col * cell_w - half_cell_w ,
                         row * cell_w - half_cell_w,
                         activ * nn_activs_scale, wid, activ > 0, true);
            endif;
        endfast_for;
    endfast_for;
enddefine;


;;; draw_weights2d_to takes a 2d-weights window record and displays
;;; the weights from one layer to all nodes in the next
;;; row is the row on the window rather than of the network
define /* constant */ draw_weights2d_to(win_rec);
lvars row col win_rec
      network = nn_neural_nets(nn_win_net(win_rec)),
      wid = nn_win_id(win_rec),
      rows = nn_win_rows(win_rec),
      cols = nn_win_cols(win_rec),
      win_map = nn_win_map(win_rec),
      entry = nn_win_info(win_rec),
      layer = win_info_layer(entry) + 1,     ;;; needed because of map maker
                                             ;;; maps layer below
      group = win_info_group(entry),
      index = win_info_node(entry),
      weights_map val;

    ;;; get weights from this row to next
    nn_layer_weights(layer, network) -> weights_map;
    fast_for row from 1 to rows do
        fast_for col from 1 to cols do
            if (win_map(row, col) ->> entry) then
                weights_map(group)
                           (nn_index_in_layer(win_map_index(entry),
                                              win_map_group(entry),
                                              win_map_layer(entry),
                                              network), index) -> val;
                draw_box(col * cell_w - half_cell_w ,
                         row * cell_w - half_cell_w,
                         val * nn_weights_scale, wid, val > 0, true);
            endif;
        endfast_for;
    endfast_for;
enddefine;


;;; draw_weights2d_from takes a 2d-weights window record and displays
;;; the weights from a node at the given position on the window
;;; row is the row on the window rather than of the network
define /* constant */ draw_weights2d_from(win_rec);
lvars row col win_rec
      network = nn_neural_nets(nn_win_net(win_rec)),
      wid = nn_win_id(win_rec),
      rows = nn_win_rows(win_rec),
      cols = nn_win_cols(win_rec),
      win_map = nn_win_map(win_rec),
      entry = nn_win_info(win_rec),
      layer = win_info_layer(entry) - 1,    ;;; needed because map maker
                                            ;;; looks at layer above
      index = nn_index_in_layer(win_info_node(entry),
                                win_info_group(entry),
                                layer, network),
      val weights_map;

    ;;; get weights from this row to next
    nn_layer_weights(layer + 1, network) -> weights_map;
    fast_for row from 1 to rows do
        fast_for col from 1 to cols do
            if (win_map(row, col) ->> entry) then
                weights_map(win_map_group(entry))
                           (index, win_map_index(entry)) -> val;
                draw_box(col * cell_w - half_cell_w ,
                         row * cell_w - half_cell_w,
                         val * nn_weights_scale, wid, val > 0, true);
            endif;
        endfast_for;
    endfast_for
enddefine;


;;; draw_all_links takes a window record and draw all the visible
;;; links on the window on the window
define /* constant */ draw_all_links(win_rec);
lvars win_rec vec row col
      rows = nn_win_rows(win_rec),
      cols = nn_win_cols(win_rec);

    fast_for vec in nn_win_select(win_rec) do
        win_select_row(vec) -> row;
        win_select_col(vec) -> col;
        if row fi_> 0 and row fi_<= rows            ;;; check on screen
            and col fi_> 0 and col fi_<= cols then
            if win_select_dir(vec) == "from" then
                draw_links_from(row, col, win_rec);
            else
                draw_links_to(row, col, win_rec);
            endif;
        endif;
    endfast_for;
enddefine;


;;; draw_extent_window takes a window record and creates a window
;;; showing the general shape of the net and the portion
;;; currently being displayed
define /* constant */ draw_extent_window(ext_rec);
lvars row_scale = nn_ext_row_scale(ext_rec),
      col_scale = nn_ext_col_scale(ext_rec),
      rows = nn_ext_rows(ext_rec),
      cols = nn_ext_cols(ext_rec);

    draw_extent_diagram(cols, rows, col_scale, row_scale,
                        nn_ext_net(ext_rec), nn_ext_id(ext_rec));

    draw_extent_region( max(0, nn_ext_col_offset(ext_rec)) * col_scale,
                        max(0, rows - nn_ext_box_height(ext_rec)
                               - nn_ext_row_offset(ext_rec))
                            * row_scale,
                        min(cols, nn_ext_box_width(ext_rec)) * col_scale,
                        min(rows, nn_ext_box_height(ext_rec))
                            * row_scale,
                        nn_ext_id(ext_rec), NOTDST_OP);
enddefine;

endsection;     /* $-popneural */

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 26/8/95
    Added missing lvars from draw_top_activs and draw_top_input.
-- Julian Clinton, 9/12/93
    Incorporated nn_black_pixel and nn_white_pixel for mono X displays.
-- Julian Clinton, 29/7/92
    Added X drawing routines and split out PWM code.
    Moved toplogy and extent map creator functions to nn_gfxutils.p.
-- Julian Clinton, 17/6/92
    Renamed from graphics.p to nn_gfxdraw.p
-- Julian Clinton, 8/5/92
    Sectioned.
-- Julian Clinton, PNF0015, Aug 1990
    Put extent window pixel scale calculation within a max( <X>, 1)
*/
