/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved ---------
 > File:           $popneural/src/pop/nn_gfxevents.p
 > Purpose:        graphics event handling procedures
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:  nn_gfxdraw.p
 */

section $-popneural;

#_IF DEF XNEURAL
include xdefs.ph;
include xpt_coretypes;

#_ENDIF

/* ----------------------------------------------------------------- *
    Select Information Functions
 * ----------------------------------------------------------------- */

;;; select_vector_apply takes a vector from a select slot and calls
;;; the function on the two args
define /* constant */ select_vector_apply(vector, win_rec);
lvars vector win_rec
      row = win_select_row(vector),
      col = win_select_col(vector),
      fn = win_select_fn(vector);

    if row fi_<= nn_win_rows(win_rec) and row fi_> 0
       and col fi_<= nn_win_cols(win_rec) and col fi_> 0 then
        apply(row, col, fn);
    endif;
enddefine;


/* ----------------------------------------------------------------- *
    Event Handlers For Topology Windows
 * ----------------------------------------------------------------- */

define /* constant */ topology_press_at(button,x,y, win_id);
lvars button x y win_id;
lvars row col row_rem col_rem entry result menu = false,
        win_rec = nn_window_record(win_id);

    y // dcell_h -> row -> row_rem;
    x // dcell_w -> col -> col_rem;
    row + 1 -> row;
    col + 1 -> col;
    if button == 1 then
        "top_menu1" -> menu;
    elseif button == 3 then
        "top_menu3" -> menu;
    endif;

    if menu and (row_rem fi_< cell_h) and (col_rem fi_>= cell_w)
        and (nn_win_map(win_rec)(row, col) ->> entry) then
                                     ;;; moused on a cell
        popup_menu_gfx(row, col, win_rec, 3, win_id, x, y, menu);
    else
        ;;; display the default menu
        popup_menu_gfx(win_rec, 1, win_id, x, y, "background_menu");
    endif;
enddefine;


define /* constant */ topology_release_at(button,x,y, win_id);
lvars button x y win_id;
enddefine;

#_IF DEF XNEURAL
;;; toplogy_mouse_at_cb is attached to the XtNbuttonEvent resource
define topology_mouse_at_cb(widget, clientdata, calldata);
lvars widget clientdata calldata button mx my;

    fast_XptValue(widget, XtN mouseX) -> mx;
    fast_XptValue(widget, XtN mouseY) -> my;

    exacc ^int calldata -> calldata;
    abs(calldata) -> button;
    if sign(calldata) == 1 then
        XptDeferApply(topology_press_at(%button, mx, my, widget%));
    else
        XptDeferApply(topology_release_at(%button, mx, my, widget%));
    endif;
    XptSetXtWakeup();
enddefine;
#_ENDIF

define /* constant */ topology_move_to(button,x,y, win_id);
lvars button x y win_id;
enddefine;

define /* constant */ topology_mouse_out(button, win_id);
lvars button x y win_id;
enddefine;

define /* constant */ topology_quit(win_id);
lvars win_id win_rec ext_rec;

    if (nn_window_record(win_id) ->> win_rec) then
        false -> nn_window_record(win_id);
        killwindow_gfx(win_id);
        if (nn_win_ext(win_rec) ->> ext_rec) then
            false -> is_extent_window(nn_ext_id(ext_rec));
            killwindow_gfx(nn_ext_id(ext_rec));
        endif;
    endif;
enddefine;


#_IF DEF XNEURAL
;;; topology_quit_cb is attached to the XtNdestroyCallback of the parent shell
define topology_quit_cb(widget, clientdata, calldata);
lvars widget clientdata calldata;

    XptDeferApply(topology_quit(%clientdata%));
    XptSetXtWakeup();
enddefine;
#_ENDIF

define /* constant */ topology_resized(width, height, win_id);
lvars width height win_id layers win_id rows row_rem cols col_rem net
      win_rec ext_rec;

    width // dcell_w -> cols -> col_rem;
    height // dcell_h -> rows -> row_rem;

    if col_rem fi_>= cell_w then
        1 + cols -> cols;
    endif;

    if row_rem fi_>= cell_h then
        1 + rows -> rows;
    endif;

    nn_window_record(win_id) -> win_rec;

    update_select_cells(rows fi_- nn_win_rows(win_rec), 0, win_rec);

    rows -> nn_win_rows(win_rec);
    cols -> nn_win_cols(win_rec);

    newarray([1 ^rows 1 ^cols], false) -> nn_win_map(win_rec);

    make_topology_map(win_rec);
    clear_window(win_id);
    draw_topology(win_rec);
    draw_top_activs(win_rec);
    draw_all_links(win_rec);
    applist(nn_win_select(win_rec), select_vector_apply(%win_rec%));
    if (nn_win_ext(win_rec) ->> ext_rec) then
        rows -> nn_ext_box_height(ext_rec);
        cols -> nn_ext_box_width(ext_rec);
        clear_window(nn_ext_id(ext_rec));
        draw_extent_window(ext_rec);
    endif;
    win_rec -> nn_window_record(win_id);
enddefine;


#_IF DEF XNEURAL
;;; topology_resized_cb is attached to the XtNresizeEvent
define topology_resized_cb(widget, clientdata, calldata);
lvars widget clientdata calldata width height;

    fast_XptValue(widget, XtN width, "short") -> width;
    fast_XptValue(widget, XtN height, "short") -> height;
    XptDeferApply(topology_resized(%width, height, clientdata%));
    XptSetXtWakeup();
enddefine;
#_ENDIF


/* ----------------------------------------------------------------- *
    Event Handlers For Weight Display Windows
 * ----------------------------------------------------------------- */

define /* constant */ weights_press_at(button,x,y, win_id);
lvars button x y win_id;
lvars row col row_rem col_rem entry result background_menu
        win_rec = nn_window_record(win_id);

    y // cell_w -> row -> row_rem;
    x // cell_w -> col -> col_rem;
    row + 1 -> row;
    col + 1 -> col;
    popup_menu_gfx(win_rec, 1, win_id, x, y, "background_menu");
enddefine;

define /* constant */ weights_release_at(button,x,y, win_id);
lvars button x y win_id;
enddefine;

#_IF DEF XNEURAL
;;; weights_mouse_at_cb is attached to the XtNbuttonEvent resource
define weights_mouse_at_cb(widget, clientdata, calldata);
lvars widget clientdata calldata button mx my;

    fast_XptValue(widget, XtN mouseX) -> mx;
    fast_XptValue(widget, XtN mouseY) -> my;

    exacc ^int calldata -> calldata;
    abs(calldata) -> button;
    if sign(calldata) == 1 then
        XptDeferApply(weights_press_at(%button, mx, my, widget%));
    else
        XptDeferApply(weights_release_at(%button, mx, my, widget%));
    endif;
    XptSetXtWakeup();
enddefine;
#_ENDIF

define /* constant */ weights_move_to(button,x,y, win_id);
lvars button x y win_id;
enddefine;

define /* constant */ weights_mouse_out(button, win_id);
lvars button x y win_id;
enddefine;

define /* constant */ weights_quit(win_id);
lvars win_id win_rec ext_rec;

    if (nn_window_record(win_id) ->> win_rec) then
        false -> nn_window_record(win_id);
        killwindow_gfx(win_id);
        if (nn_win_ext(win_rec) ->> ext_rec) then
            false -> is_extent_window(nn_ext_id(ext_rec));
            killwindow_gfx(nn_ext_id(ext_rec));
        endif;
    endif;
enddefine;

#_IF DEF XNEURAL
;;; weights_quit_cb is attached to the XtNdestroyCallback of the parent shell
define weights_quit_cb(widget, clientdata, calldata);
lvars widget clientdata calldata;

    XptDeferApply(weights_quit(%clientdata%));
    XptSetXtWakeup();
enddefine;
#_ENDIF


define /* constant */ weights_resized(width, height, win_id);
lvars width height win_id rows cols win_rec net;

    (width + 1) div cell_w -> cols;
    (height + 1) div cell_w -> rows;

    nn_window_record(win_id) -> win_rec;

    rows -> nn_win_rows(win_rec);
    cols -> nn_win_cols(win_rec);

    newarray([1 ^rows 1 ^cols], false) -> nn_win_map(win_rec);
    clear_window(win_id);
    make_layer_map(win_rec);
    if nn_win_type(win_rec) == "weights2d_from" then
        draw_weights2d_from(win_rec);
    else
        draw_weights2d_to(win_rec);
    endif;
    win_rec -> nn_window_record(win_id);
enddefine;


#_IF DEF XNEURAL
;;; weights_resized_cb is attached to the XtNresizeEvent
define weights_resized_cb(widget, clientdata, calldata);
lvars widget clientdata calldata width height;

    fast_XptValue(widget, XtN width, "short") -> width;
    fast_XptValue(widget, XtN height, "short") -> height;
    XptDeferApply(weights_resized(%width, height, clientdata%));
    XptSetXtWakeup();
enddefine;
#_ENDIF


/* ----------------------------------------------------------------- *
    Event Handlers For Bias Display Windows
 * ----------------------------------------------------------------- */

define /* constant */ bias_press_at(button,x,y, win_id);
lvars button x y win_id;
lvars row col row_rem col_rem entry result background_menu
    win_rec = nn_window_record(win_id);

    y // cell_w -> row -> row_rem;
    x // cell_w -> col -> col_rem;
    row + 1 -> row;
    col + 1 -> col;
    popup_menu_gfx(win_rec, 1, win_id, x, y, "background_menu");
enddefine;

define /* constant */ bias_release_at(button,x,y, win_id);
lvars button x y win_id;
enddefine;

#_IF DEF XNEURAL
;;; bias_mouse_at_cb is attached to the XtNbuttonEvent resource
define bias_mouse_at_cb(widget, clientdata, calldata);
lvars widget clientdata calldata button mx my;

    fast_XptValue(widget, XtN mouseX) -> mx;
    fast_XptValue(widget, XtN mouseY) -> my;

    exacc ^int calldata -> calldata;
    abs(calldata) -> button;
    if sign(calldata) == 1 then
        XptDeferApply(bias_press_at(%button, mx, my, widget%));
    else
        XptDeferApply(bias_release_at(%button, mx, my, widget%));
    endif;
    XptSetXtWakeup();
enddefine;
#_ENDIF

define /* constant */ bias_move_to(button,x,y, win_id);
lvars button x y win_id;
enddefine;

define /* constant */ bias_mouse_out(button, win_id);
lvars button win_id;
enddefine;

define /* constant */ bias_quit(win_id);
lvars win_id win_rec ext_rec;
    if (nn_window_record(win_id) ->> win_rec) then
        false -> nn_window_record(win_id);
        killwindow_gfx(win_id);
        if (nn_win_ext(win_rec) ->> ext_rec) then
            false -> is_extent_window(nn_ext_id(ext_rec));
            killwindow_gfx(nn_ext_id(ext_rec));
        endif;
    endif;
enddefine;


#_IF DEF XNEURAL
;;; bias_quit_cb is attached to the XtNdestroyCallback of the parent shell
define bias_quit_cb(widget, clientdata, calldata);
lvars widget clientdata calldata;

    XptDeferApply(bias_quit(%clientdata%));
    XptSetXtWakeup();
enddefine;
#_ENDIF


define /* constant */ bias_resized(width, height, win_id);
lvars width height win_id rows cols win_rec net;
    (width + 1) div cell_w -> cols;
    (height + 1) div cell_w -> rows;

    nn_window_record(win_id) -> win_rec;

    rows -> nn_win_rows(win_rec);
    cols -> nn_win_cols(win_rec);

    newarray([1 ^rows 1 ^cols], false) -> nn_win_map(win_rec);

    clear_window(win_id);
    make_layer_map(win_rec);
    draw_bias(win_rec);
    win_rec -> nn_window_record(win_id);
enddefine;


#_IF DEF XNEURAL
;;; bias_resized_cb is attached to the XtNresizeEvent
define bias_resized_cb(widget, clientdata, calldata);
lvars widget clientdata calldata width height;

    fast_XptValue(widget, XtN width, "short") -> width;
    fast_XptValue(widget, XtN height, "short") -> height;
    XptDeferApply(bias_resized(%width, height, clientdata%));
    XptSetXtWakeup();
enddefine;
#_ENDIF


/* ----------------------------------------------------------------- *
    Event Handlers For Activation Display Windows
 * ----------------------------------------------------------------- */

define /* constant */ activs_press_at(button,x,y, win_id);
lvars button x y win_id;
lvars row col row_rem col_rem entry result background_menu
    win_rec = nn_window_record(win_id);

    y // cell_w -> row -> row_rem;
    x // cell_w -> col -> col_rem;
    row + 1 -> row;
    col + 1 -> col;
    popup_menu_gfx(win_rec, 1, win_id, x, y, "background_menu");
enddefine;

define /* constant */ activs_release_at(button,x,y, win_id);
lvars button x y win_id;
enddefine;

#_IF DEF XNEURAL
;;; activs_mouse_at_cb is attached to the XtNbuttonEvent resource
define activs_mouse_at_cb(widget, clientdata, calldata);
lvars widget clientdata calldata button mx my;

    fast_XptValue(widget, XtN mouseX) -> mx;
    fast_XptValue(widget, XtN mouseY) -> my;

    exacc ^int calldata -> calldata;
    abs(calldata) -> button;
    if sign(calldata) == 1 then
        XptDeferApply(activs_press_at(%button, mx, my, widget%));
    else
        XptDeferApply(activs_release_at(%button, mx, my, widget%));
    endif;
    XptSetXtWakeup();
enddefine;
#_ENDIF

define /* constant */ activs_move_to(button,x,y, win_id);
lvars button x y win_id;
enddefine;

define /* constant */ activs_mouse_out(button, win_id);
lvars button x y win_id;
enddefine;

define /* constant */ activs_quit(win_id);
lvars win_id win_rec ext_rec;
    if (nn_window_record(win_id) ->> win_rec) then
        false -> nn_window_record(win_id);
        killwindow_gfx(win_id);
        if (nn_win_ext(win_rec) ->> ext_rec) then
            false -> is_extent_window(nn_ext_id(ext_rec));
            killwindow_gfx(nn_ext_id(ext_rec));
        endif;
    endif;
enddefine;

#_IF DEF XNEURAL
;;; activs_quit_cb is attached to the XtNdestroyCallback of the parent shell
define activs_quit_cb(widget, clientdata, calldata);
lvars widget clientdata calldata;

    XptDeferApply(activs_quit(%clientdata%));
    XptSetXtWakeup();
enddefine;
#_ENDIF


define /* constant */ activs_resized(width, height, win_id);
lvars width height win_id rows cols win_rec net;

    (width + 1) div cell_w -> cols;
    (height + 1) div cell_w -> rows;

    nn_window_record(win_id) -> win_rec;

    rows -> nn_win_rows(win_rec);
    cols -> nn_win_cols(win_rec);

    newarray([1 ^rows 1 ^cols], false) -> nn_win_map(win_rec);

    clear_window(win_id);
    make_layer_map(win_rec);
    draw_activs(win_rec);
    win_rec -> nn_window_record(win_id);
enddefine;


#_IF DEF XNEURAL
;;; activs_resized_cb is attached to the XtNresizeEvent
define activs_resized_cb(widget, clientdata, calldata);
lvars widget clientdata calldata width height;

    fast_XptValue(widget, XtN width, "short") -> width;
    fast_XptValue(widget, XtN height, "short") -> height;
    XptDeferApply(activs_resized(%width, height, clientdata%));
    XptSetXtWakeup();
enddefine;
#_ENDIF


/* ----------------------------------------------------------------- *
    Event Handlers For Extent Windows
 * ----------------------------------------------------------------- */

#_IF DEF PWMNEURAL
;;; init_x and init_y are the initial mouse position
define extent_starttracking_pwm(init_x, init_y,
            lolim_x, lolim_y, hilim_x, hilim_y, box_width, box_height, win_id);
dlocal pwmgfxsurface = win_id, pwmgfxrasterop = PWM_XOR;
lconstant constraint_list = writeable initl(4);
lvars init_x init_y lolim_x lolim_y hilim_x hilim_y
      box_width box_height win_id;

    lolim_x -> subscrl(1, constraint_list);
    lolim_y -> subscrl(2, constraint_list);
    hilim_x -> subscrl(3, constraint_list);
    hilim_y -> subscrl(4, constraint_list);

    pwm_trackmouse(constraint_list,
                    init_x - (box_width div 2),     ;;; position box so mouse
                    init_y - (box_height div 2),    ;;; is in the center
                    box_width, box_height, "bouncy_box", false);
enddefine;

;;; used in case some conversion is needed between where the release
;;; event occurred and where the box is thought to be (not needed in PWM)
define extent_stoptracking_pwm(x, y, win_id) -> ext_x -> ext_y;
lvars x y win_id ext_x ext_y;

    x -> ext_x;
    y -> ext_y;
enddefine;
#_ENDIF

#_IF DEF XNEURAL
defclass lvars nn_dragContext {
    inDrag :XptBoolean,     ;;; true if we are in a drag operation
    lastCoords,             ;;; records where the object is drawn
    minX   :int,
    minY   :int,
    maxX   :int,
    maxY   :int,
    boxW   :int,
    boxH   :int,
    half_boxW   :int,
    half_boxH   :int,
};

lvars ext_drag_context = consnn_dragContext(false, initv(2),0,0,0,0,0,0,0,0);

;;; extent_drag_cb is called when the mouse is moved in an extent
;;; window. It is attached to the motionEvent callback.
define extent_drag_cb(widget, client, call);
lvars widget client call mx my width height;

    returnunless(ext_drag_context.inDrag);

    fast_XptValue(widget, XtN mouseX) fi_- ext_drag_context.half_boxW -> mx;
    fast_XptValue(widget, XtN mouseY) fi_- ext_drag_context.half_boxH -> my;

    ;;; clip the co-ordinates
    max(min(mx, ext_drag_context.maxX), ext_drag_context.minX) -> mx;
    max(min(my, ext_drag_context.maxY), ext_drag_context.minY) -> my;


    false -> fast_XptValue(widget, XtN autoFlush, TYPESPEC(:XptBoolean));

    NOTDST_OP -> XptValue(widget, XtN function);

    ;;; undraw the old rectangle...
    XpwDrawRectangle(widget, explode(ext_drag_context.lastCoords),
        (ext_drag_context.boxW) ->> width,
        (ext_drag_context.boxH) ->> height);

    mx, my -> explode(ext_drag_context.lastCoords);

    ;;; ...and draw a new one
    XpwDrawRectangle(widget, mx, my, width, height);
    true -> fast_XptValue(widget, XtN autoFlush, TYPESPEC(:XptBoolean));
enddefine;


define extent_starttracking_x(init_x, init_y,
            lolim_x, lolim_y, hilim_x, hilim_y, box_width, box_height, win_id);
lvars init_x init_y lolim_x lolim_y hilim_x hilim_y
      box_width box_height win_id;

    lolim_x -> ext_drag_context.minX;
    lolim_y -> ext_drag_context.minY;
    hilim_x -> ext_drag_context.maxX;
    hilim_y -> ext_drag_context.maxY;
    box_width -> ext_drag_context.boxW;
    box_height -> ext_drag_context.boxH;
    box_width div 2 -> ext_drag_context.half_boxW;
    box_height div 2 -> ext_drag_context.half_boxH;

    init_x fi_- (box_width div 2) -> init_x;
    init_y fi_- (box_height div 2) -> init_y;
    max(min(init_x, ext_drag_context.maxX), ext_drag_context.minX) -> init_x;
    max(min(init_y, ext_drag_context.maxY), ext_drag_context.minY) -> init_y;
    init_x -> subscrv(1, ext_drag_context.lastCoords);
    init_y -> subscrv(2, ext_drag_context.lastCoords);

    NOTDST_OP -> XptValue(win_id, XtN function);

    XpwDrawRectangle(win_id, explode(ext_drag_context.lastCoords),
        box_width, box_height);

    true -> ext_drag_context.inDrag;
enddefine;


;;; this procedure is used to convert between where the release mouse
;;; event occurred and where the box is actually positioned. The PWM
;;; keeps the mouse within a restricted zone but under X, this
;;; has to be done explicitly.
define extent_stoptracking_x(x, y, win_id) -> ext_x -> ext_y;
lvars x y win_id ext_x ext_y;

    ;;; if we weren't in a drag then do nothing
    unless ext_drag_context.inDrag then
        x -> ext_x;
        y -> ext_y;
        return();
    endunless;

    false -> ext_drag_context.inDrag;

    fast_XptValue(win_id, XtN mouseX) fi_- ext_drag_context.half_boxW -> ext_x;
    fast_XptValue(win_id, XtN mouseY) fi_- ext_drag_context.half_boxH -> ext_y;

    ;;; clip the co-ordinates
    max(min(ext_x, ext_drag_context.maxX), ext_drag_context.minX) -> ext_x;
    max(min(ext_y, ext_drag_context.maxY), ext_drag_context.minY) -> ext_y;

    ;;; ext_x fi_+ ext_drag_context.half_boxW -> ext_x;
    ;;; ext_y fi_+ ext_drag_context.half_boxH -> ext_y;

    NOTDST_OP -> XptValue(win_id, XtN function);

    ;;; undraw the rectangle
    XpwDrawRectangle(win_id, explode(ext_drag_context.lastCoords),
        ext_drag_context.boxW, ext_drag_context.boxH);
enddefine;
#_ENDIF

global vars procedure extent_starttracking =
    CHECK_GFXSWITCH extent_starttracking_x extent_starttracking_pwm
        extent_starttracking;

global vars procedure extent_stoptracking =
    CHECK_GFXSWITCH extent_stoptracking_x extent_stoptracking_pwm
        extent_stoptracking;


define /* constant */ extent_press_at(button,x,y, win_id);
lvars button x y win_id;
lvars win_rec = nn_window_record(is_extent_window(win_id)),
     ext_rec = nn_win_ext(win_rec);
lvars
     row_scale = nn_ext_row_scale(ext_rec),
     col_scale = nn_ext_col_scale(ext_rec),
     box_height = nn_ext_box_height(ext_rec),
     box_width = nn_ext_box_width(ext_rec),
     row_offset = nn_ext_row_offset(ext_rec),
     col_offset = nn_ext_col_offset(ext_rec),
     rows = nn_ext_rows(ext_rec),
     cols = nn_ext_cols(ext_rec),
     hbox_h hbox_w
     abs_row = (rows - box_height) * row_scale,
     abs_col = col_offset * col_scale;

    if button == 1 then
        draw_extent_region( max(0, col_offset) * col_scale,
                            max(0, rows - box_height - row_offset)
                                * row_scale,
                            min(cols, box_width) * col_scale,
                            min(rows, box_height) * row_scale,
                            nn_ext_id(ext_rec), NOTDST_OP);

        box_width * col_scale div 2 -> hbox_w;
        box_height * row_scale div 2 -> hbox_h;
        consvector(x - hbox_w, y - hbox_h, 2) -> nn_ext_mouse_at(ext_rec);

        extent_starttracking(x, y, 0, 0,
            (cols - box_width) * col_scale, (rows - box_height) * row_scale,
            box_width * col_scale, box_height * row_scale, nn_ext_id(ext_rec));
    endif;
enddefine;


define /* constant */ extent_release_at(button,x,y, win_id);
lvars button x y win_id
     net_win_id = is_extent_window(win_id),
     win_rec = nn_window_record(net_win_id),
     ext_rec = nn_win_ext(win_rec),
     row_offset = nn_ext_row_offset(ext_rec),
     col_offset = nn_ext_col_offset(ext_rec),
     row_scale = nn_ext_row_scale(ext_rec),
     col_scale = nn_ext_col_scale(ext_rec),
     box_height = nn_ext_box_height(ext_rec),
     box_width = nn_ext_box_width(ext_rec),
     rows = nn_ext_rows(ext_rec),
     cols = nn_ext_cols(ext_rec),
     row col box_h win_rows win_cols;

    if button == 1 and nn_win_type(win_rec) == "topology" then
        extent_stoptracking(x, y, win_id) -> x -> y;
        box_height * row_scale -> box_h;
        (x + col_scale div 2) div col_scale -> col;
        rows - ((y + box_h + row_scale div 2) div row_scale) -> row;

        unless row == row_offset and col == col_offset then
            row ->> nn_ext_row_offset(ext_rec)
                -> nn_win_row_offset(win_rec);
            col ->> nn_ext_col_offset(ext_rec)
                -> nn_win_col_offset(win_rec);
            update_select_cells(row - row_offset, col_offset - col, win_rec);
            make_topology_map(win_rec);
            clear_window(win_id);
            draw_extent_window(ext_rec);
            clear_window(net_win_id);
            draw_topology(win_rec);
            draw_top_activs(win_rec);
            draw_all_links(win_rec);
            applist(nn_win_select(win_rec), select_vector_apply(%win_rec%));
            win_rec -> nn_window_record(net_win_id);
        else
            clear_window(win_id);
            draw_extent_window(ext_rec);
        endunless;
    endif;
enddefine;


#_IF DEF XNEURAL
;;; extent_mouse_at_cb is attached to the XtNbuttonEvent resource
define extent_mouse_at_cb(widget, clientdata, calldata);
lvars widget clientdata calldata button mx my;

    fast_XptValue(widget, XtN mouseX) -> mx;
    fast_XptValue(widget, XtN mouseY) -> my;
    exacc ^int calldata -> calldata;
    abs(calldata) -> button;
    if sign(calldata) == 1 then
        XptDeferApply(extent_press_at(%button, mx, my, widget%));
    else
        XptDeferApply(extent_release_at(%button, mx, my, widget%));
    endif;
    XptSetXtWakeup();
enddefine;
#_ENDIF


define /* constant */ extent_move_to(button,x,y, win_id);
lvars button x y win_id;
enddefine;


define /* constant */ extent_mouse_out(button, win_id);
lvars button win_id
     win_rec = nn_window_record(is_extent_window(win_id)),
     ext_rec = nn_win_ext(win_rec);

#_IF DEF XNEURAL
    false -> ext_drag_context.inDrag;
#_ENDIF
    false -> nn_ext_mouse_at(ext_rec);
    draw_extent_window(ext_rec);
enddefine;


define /* constant */ extent_quit(win_id);
lvars win_id win_rec;
    if (is_extent_window(win_id) ->> win_rec) then
        false ->> is_extent_window(win_id)
              -> nn_win_ext(nn_window_record(win_rec));
        killwindow_gfx(win_id);
    endif;
enddefine;


#_IF DEF XNEURAL
;;; extent_quit_cb is attached to the XtNdestroyCallback of the parent shell
define extent_quit_cb(widget, clientdata, calldata);
lvars widget clientdata calldata;

    XptDeferApply(extent_quit(%clientdata%));
    XptSetXtWakeup();
enddefine;
#_ENDIF


define /* constant */ extent_resized(width, height, win_id);
lvars width height win_id;
    extent_quit(win_id);
enddefine;


#_IF DEF XNEURAL
;;; extent_resized_cb is attached to the XtNresizeEvent
define extent_resized_cb(widget, clientdata, calldata);
lvars widget clientdata calldata width height;

    fast_XptValue(widget, XtN width, "short") -> width;
    fast_XptValue(widget, XtN height, "short") -> height;
    XptDeferApply(extent_resized(%width, height, clientdata%));
    XptSetXtWakeup();
enddefine;
#_ENDIF


/* ----------------------------------------------------------------- *
    Top Level PWM Event Handlers
 * ----------------------------------------------------------------- */

#_IF DEF PWMNEURAL
define pwm_topology_event_handler(vector, win_id);
dlocal interrupt = exitfrom(%pwm_topology_event_handler%);
lvars event arg1 arg2 arg3;
    explode(vector) -> arg3 -> arg2 -> arg1 -> event;
    if event == "press" then
        topology_press_at(arg1, arg2, arg3, win_id);
    elseif event == "release" then
        topology_release_at(arg1, arg2, arg3, win_id);
    elseif event == "move" then
        topology_move_to(arg1, arg2, arg3, win_id);
    elseif event == "mousexit" then
        topology_mouse_out(arg1, win_id);
    elseif event == "quitrequest" then
        topology_quit(win_id);
    elseif event == "resized" then
        topology_resized(arg2, arg3, win_id);
    endif;
enddefine;

define pwm_weights_event_handler(vector, win_id);
dlocal interrupt = exitfrom(%pwm_weights_event_handler%);
lvars event arg1 arg2 arg3;
    explode(vector) -> arg3 -> arg2 -> arg1 -> event;
    if event == "press" then
        weights_press_at(arg1, arg2, arg3, win_id);
    elseif event == "release" then
        weights_release_at(arg1, arg2, arg3, win_id);
    elseif event == "move" then
        weights_move_to(arg1, arg2, arg3, win_id);
    elseif event == "mousexit" then
        weights_mouse_out(arg1, win_id);
    elseif event == "quitrequest" then
        weights_quit(win_id);
    elseif event == "resized" then
        weights_resized(arg2, arg3, win_id);
    endif;
enddefine;

define pwm_bias_event_handler(vector, win_id);
dlocal interrupt = exitfrom(%pwm_bias_event_handler%);
lvars event arg1 arg2 arg3;
    explode(vector) -> arg3 -> arg2 -> arg1 -> event;
    if event == "press" then
        bias_press_at(arg1, arg2, arg3, win_id);
    elseif event == "release" then
        bias_release_at(arg1, arg2, arg3, win_id);
    elseif event == "move" then
        bias_move_to(arg1, arg2, arg3, win_id);
    elseif event == "mousexit" then
        bias_mouse_out(arg1, win_id);
    elseif event == "quitrequest" then
        bias_quit(win_id);
    elseif event == "resized" then
        bias_resized(arg2, arg3, win_id);
    endif;
enddefine;

define pwm_activs_event_handler(vector, win_id);
dlocal interrupt = exitfrom(%pwm_activs_event_handler%);
lvars event arg1 arg2 arg3;
    explode(vector) -> arg3 -> arg2 -> arg1 -> event;
    if event == "press" then
        activs_press_at(arg1, arg2, arg3, win_id);
    elseif event == "release" then
        activs_release_at(arg1, arg2, arg3, win_id);
    elseif event == "move" then
        activs_move_to(arg1, arg2, arg3, win_id);
    elseif event == "mousexit" then
        activs_mouse_out(arg1, win_id);
    elseif event == "quitrequest" then
        activs_quit(win_id);
    elseif event == "resized" then
        activs_resized(arg2, arg3, win_id);
    endif;
enddefine;

define pwm_extent_event_handler(vector, win_id);
dlocal interrupt = exitfrom(%pwm_extent_event_handler%);
lvars event arg1 arg2 arg3;
    explode(vector) -> arg3 -> arg2 -> arg1 -> event;
    if event == "press" then
        extent_press_at(arg1, arg2, arg3, win_id);
    elseif event == "release" then
        extent_release_at(arg1, arg2, arg3, win_id);
    elseif event == "move" then
        extent_move_to(arg1, arg2, arg3, win_id);
    elseif event == "mousexit" then
        extent_mouse_out(arg1, win_id);
    elseif event == "quitrequest" then
        extent_quit(win_id);
    elseif event == "resized" then
        extent_resized(arg2, arg3, win_id);
    endif;
enddefine;
#_ENDIF


/* ----------------------------------------------------------------- *
    Generic Procs For Adding Event Handlers
 * ----------------------------------------------------------------- */

;;; generic way of adding the appropriate handler for quitting
;;; from a window
;;;
define add_quit_window_handler(wid, proc);
lvars wid proc;

#_IF DEF XOPENLOOK
        XtAddCallback(XtParent(wid), XtN destroyCallback, proc, wid);
        XtDestroyWidget -> XptDeleteResponse(XtParent(wid));
#_ELSEIF DEF XMOTIF
#_IF not(DEF XLINK_VERSION) or DEFV XLINK_VERSION < 1002
        XtAddCallback(XtParent(wid), XtN popdownCallback, proc, wid);
        XtPopdown -> XptDeleteResponse(XtParent(wid));
#_ELSE
        XtAddCallback(XtParent(wid), XtN destroyCallback, proc, wid);
        XtDestroyWidget -> XptDeleteResponse(XtParent(wid));
#_ENDIF
#_ENDIF
enddefine;

define add_topology_event_handlers(wid);
lvars wid;

#_IF DEF XNEURAL
    if popunderx then
        add_quit_window_handler(wid, topology_quit_cb);
        topology_resized_cb(%wid, false%) -> XptResizeResponse(XtParent(wid));
        XtAddCallback(wid, XtN buttonEvent, topology_mouse_at_cb, false);
        return();
    endif;
#_ENDIF

#_IF DEF PWMNEURAL
    if popunderpwm then
        pwm_topology_event_handler(%wid%) -> pwmeventhandler(wid, false);
        return();
    endif;
#_ENDIF
enddefine;


define add_bias_event_handlers(wid);
lvars wid;

#_IF DEF XNEURAL
    if popunderx then
        add_quit_window_handler(wid, bias_quit_cb);
        bias_resized_cb(%wid, false%) -> XptResizeResponse(XtParent(wid));
        XtAddCallback(wid, XtN buttonEvent, bias_mouse_at_cb, false);
        return();
    endif;
#_ENDIF

#_IF DEF PWMNEURAL
    if popunderpwm then
        pwm_bias_event_handler(%wid%) -> pwmeventhandler(wid, false);
        return();
    endif;
#_ENDIF
enddefine;


define add_activs_event_handlers(wid);
lvars wid;

#_IF DEF XNEURAL
    if popunderx then
        add_quit_window_handler(wid, activs_quit_cb);
        activs_resized_cb(%wid, false%) -> XptResizeResponse(XtParent(wid));
        XtAddCallback(wid, XtN buttonEvent, activs_mouse_at_cb, false);
        return();
    endif;
#_ENDIF

#_IF DEF PWMNEURAL
    if popunderpwm then
        pwm_activs_event_handler(%wid%) -> pwmeventhandler(wid, false);
        return();
    endif;
#_ENDIF
enddefine;


define add_weights_event_handlers(wid);
lvars wid;

#_IF DEF XNEURAL
    if popunderx then
        add_quit_window_handler(wid, weights_quit_cb);
        weights_resized_cb(%wid, false%) -> XptResizeResponse(XtParent(wid));
        XtAddCallback(wid, XtN buttonEvent, weights_mouse_at_cb, false);
        return();
    endif;
#_ENDIF

#_IF DEF PWMNEURAL
    if popunderpwm then
        pwm_weights_event_handler(%wid%) -> pwmeventhandler(wid, false);
        return();
    endif;
#_ENDIF
enddefine;


define add_extent_event_handlers(wid);
lvars wid;

#_IF DEF XNEURAL
    if popunderx then
        add_quit_window_handler(wid, extent_quit_cb);
        XtAddCallback(wid, XtN buttonEvent, extent_mouse_at_cb, false);
        XtAddCallback(wid, XtN motionEvent, extent_drag_cb, false);
        extent_resized_cb(%wid, false%) -> XptResizeResponse(XtParent(wid));
        return();
    endif;
#_ENDIF

#_IF DEF PWMNEURAL
    if popunderpwm then
        pwm_extent_event_handler(%wid%) -> pwmeventhandler(wid, false);
        return();
    endif;
#_ENDIF
enddefine;

global vars nn_gfxevents = true;        ;;; for "uses"

endsection;     /* $-popneural */

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 1/9/93
    Added include of xpt_coretypes.
-- Julian Clinton, 17/8/93
    Changed #_IF X* to #_IF DEF X*.
    Tidied the adding of quit event handlers for the various types of
    windows and added conditions for Motif 1.2.
-- Julian Clinton, 14/9/92
    Added XptDeleteResponse.
-- Julian Clinton, 10/9/92
    Enabled background menu on bias, activation and weights windows.
-- Julian Clinton, 30/7/92
    Added support for X events.
-- Julian Clinton, 17/7/92
    Renamed from gfxevents.p to nn_gfxevents.p.
-- Julian Clinton, 19/6/92
    Modified event handlers so that they simplay -apply- the value
    of the menu rather than calling valof.
-- Julian Clinton, 8/5/92
    Sectioned.
*/
