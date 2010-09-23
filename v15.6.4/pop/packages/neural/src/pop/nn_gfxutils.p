/* --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved ---------
 > File:           	$popneural/src/pop/nn_gfxutils.p
 > Purpose:        	graphics display utilities
 > Author:         	Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:  	nn_gfxdefs.p nn_gfxdraw.p nn_gfxevents.p
 */

section $-popneural;

#_IF DEF XNEURAL
uses format_print;		;;; X colour allocator uses format_string
uses popxlib;
include xdefs.ph;
include xpt_coretypes;
include xpt_xgcvalues;

exload_batch
include xt_constants;
uses xt_init;
uses xt_widget;				;;; needed
uses xt_widgetclass;
uses xt_widgetinfo;
uses xt_callback;
uses xt_event;
uses xt_popup;
uses xt_action;
uses xt_composite;
uses xt_popup;
uses xt_resource;
uses XptGarbageCursorFeedback;
uses XptBusyCursorFeedback;
uses XptNewWindow;
uses XptScreenPtrApply;

uses
	XpwGraphic,
	xpwGraphicWidget,
    xpwCompositeWidget,
    xtTopLevelShellWidget,
    xtApplicationShellWidget,
    xtTransientShellWidget,
;

#_IF DEF XOPENLOOK
include XolConstants;
#_ELSEIF DEF XMOTIF
include XmConstants;
#_ENDIF

endexload_batch;
#_ENDIF


/* ----------------------------------------------------------------- *
    UI Switch
 * ----------------------------------------------------------------- */

;;; Closures of runtime_gfxswitch are assigned to the various UI
;;; routines which can have either PWM or X routines associated with
;;; them. The first time the routine is run, the switch selects between
;;; the two possible identifiers and assigns the appropriate value
;;; to the idval of the supplied identifier before chaining the routine.
;;; Note that this means that once the system has been started in one
;;; way, it cannot be re-set to use the alternative.
;;;
define runtime_gfxswitch(Xval, Pwmval, identifier);
lvars Xval Pwmval identifier;

#_IF DEF XNEURAL
	if popunderx then
		Xval -> idval(identifier);
		chain(Xval);
	endif;
#_ENDIF

#_IF DEF PWMNEURAL
	if popunderpwm then
		Pwmval -> idval(identifier);
		chain(Pwmval);
	endif;
#_ENDIF
enddefine;


;;; check_gfxswitch is a macro used to determine whether the appropriate
;;; X or PWM routine or value can be bound to a variable directly or whether
;;; a closure for runtime selection has to be produced.
;;;
define macro CHECK_GFXSWITCH x_val pwm_val identifier_id;
lvars x_val pwm_val identifier_id;

	sys_current_ident(identifier_id) -> identifier_id;

#_IF DEF XNEURAL
	idval(sys_current_ident(x_val)) -> x_val;
#_ENDIF

#_IF DEF PWMNEURAL
	idval(sys_current_ident(pwm_val)) -> pwm_val;
#_ENDIF

#_IF (DEF XNEURAL) and (DEF PWMNEURAL)
	;;; have to make switch at runtime
    runtime_gfxswitch(%x_val, pwm_val, identifier_id%)
#_ELSEIF DEF XNEURAL
	x_val
#_ELSEIF DEF PWMNEURAL
	pwm_val
#_ENDIF
enddefine;


/* ----------------------------------------------------------------- *
    Active Rasterops
 * ----------------------------------------------------------------- */

lvars
	gfx_src_op = false,
	gfx_clr_op = false,
	gfx_xor_op = false,
	gfx_notdst_op = false,
;

define active:1 SRC_OP;
	unless gfx_src_op then
    #_IF DEF XNEURAL
	    if popunderx then
			GXcopy -> gfx_src_op;
	    endif;
	#_ENDIF

    #_IF DEF PWMNEURAL
	    if popunderpwm then
			PWM_SRC -> gfx_src_op;
	    endif;
    #_ENDIF
	endunless;

	gfx_src_op;
enddefine;

define active:1 CLR_OP;
	unless gfx_clr_op then
    #_IF DEF XNEURAL
	    if popunderx then
			GXclear -> gfx_clr_op;
	    endif;
	#_ENDIF

    #_IF DEF PWMNEURAL
	    if popunderpwm then
			PWM_CLR -> gfx_clr_op;
	    endif;
    #_ENDIF
	endunless;

	gfx_clr_op;
enddefine;

define active:1 XOR_OP;
	unless gfx_xor_op then
    #_IF DEF XNEURAL
	    if popunderx then
			GXxor -> gfx_xor_op;
	    endif;
	#_ENDIF

    #_IF DEF PWMNEURAL
	    if popunderpwm then
			PWM_XOR -> gfx_xor_op;
	    endif;
    #_ENDIF
	endunless;

	gfx_xor_op;
enddefine;

define active:1 NOTDST_OP;
	unless gfx_notdst_op then
    #_IF DEF XNEURAL
	    if popunderx then
	#_IF (DEF VMS) or (DEF DECSTATION) or (DEF IRIS) or (DEF HP9000)
			GXxor -> gfx_notdst_op;
	#_ELSE
			GXinvert -> gfx_notdst_op;
	#_ENDIF
	    endif;
	#_ENDIF

    #_IF DEF PWMNEURAL
	    if popunderpwm then
			PWM_NOTDST -> gfx_notdst_op;
	    endif;
    #_ENDIF
	endunless;

	gfx_notdst_op;
enddefine;


/* ----------------------------------------------------------------- *
    General Event Handlers
 * ----------------------------------------------------------------- */

;;; closures on generic_quit are created to kill menu windows etc. tidily
;;; Have to erase the event since generic_quit is assigned directly
;;; to the "quit" event handler of the window
define /* constant */ generic_quit(win_id, wid_var);
lvars win_id wid_var;

    false -> ui_options_table(wid_var);

#_IF DEF PWMNEURAL
	if popunderpwm then
    	erase();
    	pwm_killwindow(win_id);
		return();
	endif;
#_ENDIF

#_IF DEF XNEURAL
	if popunderx then
    	erasenum(3);
    	XptDestroyWindow(win_id);
		return();
	endif;
#_ENDIF
enddefine;


/* ----------------------------------------------------------------- *
     X-Specific Neural Shell Definitions
 * ----------------------------------------------------------------- */

#_IF DEF XNEURAL
lvars
	toplevel_shell = false,
	app_shell = false,
	trans_shell = false,
;

define lconstant gen_shell(name, class) -> widget;
	lvars name widget class;

	unless XptDefaultDisplay then
		XptDefaultSetup();
	endunless;

	XtAppCreateShell(name, 'PoplogNeural', class, XptDefaultDisplay,
			XptArgList([{width 1} {height 1}
						{mappedWhenManaged ^false}])) -> widget;
	XtRealizeWidget(widget);
enddefine;


define global active nn_toplevel_shell;
	unless toplevel_shell then
		gen_shell('topLevelShell', xtTopLevelShellWidget) -> toplevel_shell;
	endunless;
	toplevel_shell;
enddefine;

define updaterof active nn_toplevel_shell(val);
lvars val;
	val -> toplevel_shell;
enddefine;

define global active nn_trans_shell;
	unless trans_shell then
		gen_shell('transientShell', xtTransientShellWidget) -> trans_shell;
		XptCenterWidgetOn(trans_shell, "screen");
	endunless;
	trans_shell;
enddefine;

define updaterof active nn_trans_shell(val);
lvars val;
	val -> trans_shell;
enddefine;


define global active nn_app_shell;
	unless app_shell then
		gen_shell('applicationShell', xtApplicationShellWidget) -> app_shell;
		XptCenterWidgetOn(app_shell, "screen");
	endunless;
	app_shell;
enddefine;

define updaterof active nn_app_shell(val);
lvars val;
	val -> app_shell;
enddefine;
#_ENDIF


/* ----------------------------------------------------------------- *
     Lookup Utilities
 * ----------------------------------------------------------------- */

;;; gfxmenustruct_id takes a menu name and returns the
;;; name of the identified which should be the key into gfxmenu_table
;;; which contains the menu struct.
;;;
define constant gfxmenustruct_id(menu_name) -> menu_struct_id;
lvars menu_name menu_struct_id;
    menu_name <> "_menu" -> menu_struct_id;
enddefine;


;;; window_var takes a variable name and returns the
;;; name of the variable which should correspond to the window displaying
;;; the contents of that variable.
;;;
define constant window_var(var_name) -> var_win_name;
lvars var_name var_win_name;
    var_name <> "_win" -> var_win_name;
enddefine;


/* ----------------------------------------------------------------- *
     Colour Utilities
 * ----------------------------------------------------------------- */

#_IF DEF XNEURAL
define colour_init_x(wid);
lvars wid scrn colour pixel_val clr_inc = 255 div nn_colour_range;

    define lconstant hex_string() -> str;
	lconstant hex_vec = writeable initv(3);
	lconstant fstring = '#~2,`0,,X~2,`0,,X~2,`0,,X';
    lvars str;
		fill(hex_vec) ->;
	    format_string(fstring, hex_vec) -> str;
    enddefine;

	;;; the X colour map is a vector which maps activation and
	;;; weight intensity values to the paint number returned
	;;; by XpwSetColor. Note that we need an extra 2 cells
	;;; for black and white.
	;;;
	newarray([0 ^((2 * nn_colour_range) - 1)]) -> nn_colour_map;

	XtScreen(wid) -> scrn;
	;;; white
    ;;; XpwSetColor(wid, hex_string(255, 255, 255)) -> nn_colour_map(0);
	;;; scrn("white_pixel") -> nn_colour_map(0);

	;;; background colour
	XptValue(wid, XtN background) -> nn_colour_map(0);

	;;; black
    ;;; XpwSetColor(wid, hex_string(0, 0, 0)) -> nn_colour_map(1);
	;;; scrn("black_pixel") -> nn_colour_map(1);

	;;; foreground colour
	XptValue(wid, XtN foreground) -> nn_colour_map(1);


	;;; shades of blue
    for colour from 2 to nn_colour_range do
        XpwSetColor(wid, hex_string(
								(nn_colour_range - colour) * clr_inc,
								(nn_colour_range - colour) * clr_inc,
								255)) -> pixel_val;
		pixel_val -> nn_colour_map(colour);
    endfor;

	;;; shades of red
    for colour from 1 to nn_colour_range - 1 do
        XpwSetColor(wid, hex_string(255,
                             	(nn_colour_range - colour) * clr_inc,
								(nn_colour_range - colour) * clr_inc))
						-> pixel_val;
		pixel_val -> nn_colour_map(colour + nn_colour_range);
    endfor;

enddefine;
#_ENDIF


#_IF DEF PWMNEURAL
define /* constant */ colour_init_pwm(wid);
dlocal pwmgfxsurface = wid;
lvars colour clr_inc = 255 div nn_colour_range;

	unless nn_colour_map then
    	pwmsun_gfxnewcms(nn_colour_range * 2) -> nn_colour_map;
	endunless;

    unless nn_colour_map then
		;;; if we couldn't get a colour map then we can't use colour
        false -> nn_use_colour;
    else
		;;; make the window use the colour map
        pwmsun_gfxusecms(nn_colour_map);
        for colour from 2 to nn_colour_range do
            pwm_gfxsetmapentry(colour,
                               {%(nn_colour_range - colour) * clr_inc,
                                 (nn_colour_range - colour) * clr_inc,
                                 255%});
        endfor;
        for colour from 1 to nn_colour_range - 1 do
            pwm_gfxsetmapentry(colour + nn_colour_range,
                               {%255,
                                 (nn_colour_range - colour) * clr_inc,
                                 (nn_colour_range - colour) * clr_inc%});
        endfor;
        pwm_gfxsetmapentry(0, {255 255 255});
        pwm_gfxsetmapentry(1, {0 0 0});
    endunless;
enddefine;
#_ENDIF


define setup_colour_map(wid);
lvars wid;

	unless nn_colour_map then

#_IF DEF XNEURAL
	    if popunderx then
		    colour_init_x(wid);
	    endif;
#_ENDIF
#_IF DEF PWMNEURAL
	    if popunderpwm then
		    colour_init_pwm(wid);
	    endif;
#_ENDIF
	endunless;
enddefine;


;;; colour_of returns a paintnum according to scale which should
;;; be a real number. positive is a boolean to describe whether
;;; the colour should be (true) in the red range or (false) in the
;;; blue range.
define /* constant */ colour_of(scale, positive) -> colnum;
lconstant colours_less_1 = nn_colour_range - 1;
lvars scale positive colnum = 0;

    abs(scale) -> scale;
    if scale = 0.0 then
        0 -> colnum;
    else
        min(abs(intof(scale * colours_less_1 + 0.5)), colours_less_1 - 1) + 2
            -> colnum;
        if positive then colours_less_1 + colnum -> colnum; endif;
    endif;
enddefine;


/* ----------------------------------------------------------------- *
    PWM Window Creators
 * ----------------------------------------------------------------- */

#_IF DEF PWMNEURAL

;;; special text window creator which tries to make a window a second
;;; time if the first attempt failed
define /* constant */ create_pwm_txtwin(title, width, height) -> wid;
dlocal pwmtextwindow;
lvars title width height wid;
    pwm_maketxtwin(title, width, height) -> wid;
    unless wid then          ;;; try again
        syssleep(100);
        pwm_maketxtwin(title, width, height) -> wid;
    endunless;
enddefine;


;;; special graphics window creator which tries to make a window a second
;;; time if the first attempt failed
define /* constant */ create_pwm_gfxwin(title, width, height) -> wid;
dlocal pwmgfxsurface;
lvars title width height wid;
    pwm_makegfxwin(title, width, height) -> wid;
    unless wid then          ;;; try again
        syssleep(100);
        pwm_makegfxwin(title, width, height) -> wid;
    endunless;
enddefine;

#_ENDIF


/* ----------------------------------------------------------------- *
    X Window Creators
 * ----------------------------------------------------------------- */

#_IF DEF XNEURAL

define create_x_gfxwin(title, width, height, location) -> win_id;
#_IF (DEF XOPENLOOK and DEFV XLINK_VERSION > 2005) or DEF XMOTIF
dlocal XptWMProtocols = false;
#_ENDIF
lconstant svec = writeable initv(2),	;;; used when no location is provided
		  lvec = writeable initv(4);	;;; used when window location defined
lvars title width height location win_id vec;

	if location then
		width -> fast_subscrv(1, lvec);
		height -> fast_subscrv(2, lvec);
		subscrv(1, location) -> fast_subscrv(3, lvec);
		subscrv(2, location) -> fast_subscrv(4, lvec);
		lvec
	else
		width -> fast_subscrv(1, svec);
		height -> fast_subscrv(2, svec);
		svec
	endif -> vec;

	XptNewWindow(title, vec, [], xpwGraphicWidget,
#_IF DEF XOPENLOOK
					[]
#_ELSEIF DEF XMOTIF
					[{deleteResponse ^XmUNMAP}]
#_ENDIF
			) -> win_id;
    true ->> XptGarbageCursorFeedback(win_id) -> XptBusyCursorFeedback(win_id);
enddefine;

#_ENDIF


/* ----------------------------------------------------------------- *
    Generic Window Functions
 * ----------------------------------------------------------------- */

;;; killwindow_gfx is a generic generic routine to kill X or PWM windows
define /* constant */ killwindow_gfx(win_id);
lvars win_id;

#_IF DEF XNEURAL
	if popunderx then
		if XptIsLiveType(win_id, "Widget") then
    		XptDestroyWindow(win_id);
		endif;
		return();
	endif;
#_ENDIF

#_IF DEF PWMNEURAL
	if popunderpwm then
    	pwm_killwindow(win_id);
		return();
	endif;
#_ENDIF
enddefine;


;;; windowlocation_gfx is a generic generic routine which returns the
;;; position of X or PWM windows
define /* constant */ windowlocation_gfx(win_id) -> vec;
lconstant vec = writeable initv(2);
lvars win_id val;

#_IF DEF XNEURAL
	if popunderx then
    	XptValue(win_id, XtN x) -> subscrv(1, vec);;
    	XptValue(win_id, XtN y) -> subscrv(2, vec);;
		return();
	endif;
#_ENDIF

#_IF DEF PWMNEURAL
	if popunderpwm then
    	explode(pwm_windowlocation(win_id)) -> explode(vec);
		return();
	endif;
#_ENDIF
enddefine;


/* ----------------------------------------------------------------- *
    Accessors For Structures Held In Window Records
 * ----------------------------------------------------------------- */

define /* constant */ win_map_layer(list);
    list(1);
enddefine;

define /* constant */ win_map_group(list);
    list(2);
enddefine;

define /* constant */ win_map_index(list);
    list(3);
enddefine;

define /* constant */ win_info_layer(list);
    list(1);
enddefine;

define /* constant */ win_info_group(list);
    list(2);
enddefine;

define /* constant */ win_info_node(list);
    list(3);
enddefine;

define /* constant */ win_format_rows(list);
    list(1);
enddefine;

define /* constant */ win_format_cols(list);
    list(2);
enddefine;

define /* constant */ win_select_row(list);
    list(1);
enddefine;

define updaterof constant win_select_row(val, list);
lvars val list;
    val -> list(1);
enddefine;

define /* constant */ win_select_col(list);
    list(2);
enddefine;

define updaterof constant win_select_col(val, list);
lvars val list;
    val -> list(2);
enddefine;

define /* constant */ win_select_fn(list);
    list(3);
enddefine;

define updaterof constant win_select_fn(val, list);
lvars val list;
    val -> list(3);
enddefine;

define /* constant */ win_select_dir(list);
    list(4);
enddefine;

define updaterof constant win_select_dir(val, list);
lvars val list;
    val -> list(4);
enddefine;


/* ----------------------------------------------------------------- *
    Screen Data/Node Data Converters
 * ----------------------------------------------------------------- */

;;; format is [rows columns]
define global constant nn_node_at(row, column, format) -> node;
lvars row column format node;
    (row - 1) * format(2) + column -> node;
enddefine;

define global constant nn_node_pos(node, format) -> row -> column;
lvars node format
      row = (node div format(2)) + 1,
      column = (node mod format(2));
enddefine;


;;; make_format_list takes a an integer and returns a list of the dimensions
;;; of a rectangle which will hold exactly that many number
;;; of items. The squarest possible shape is returned.
define /* constant */ make_format_list(number) -> format_list;
lvars rows = intof(sqrt(number)), row;
    [%
        fast_for row from rows by -1 to 1 do
            if (row * (number div row)) = number then
                {% row, number div row %}
            endif;
        endfast_for;
    %] -> format_list;
enddefine;


;;; prune_window checks the width and height of the window according
;;; to the size of the cell being displayed.
;;;
define /* constant */ prune_window(rows, cols, h_factor, w_factor)
	-> newrows -> newcols;
lvars rows cols h_factor w_factor newrows newcols;

    ;;; check that the window is not too big
    if rows * h_factor > nn_max_win_height then
        nn_max_win_height div h_factor -> newrows;
	else
		rows -> newrows;
    endif;

    if cols * w_factor > nn_max_win_width then
        nn_max_win_width div w_factor -> newcols;
	else
		cols -> newcols;
    endif;
enddefine;


define /* constant */ get_node_select(row, col, win_rec) -> veclist;
lvars row, col, win_rec, vec, veclist = [],
      selected = nn_win_select(win_rec);
    fast_for vec in selected do
        if win_select_row(vec) == row and win_select_col(vec) == col then
            vec :: veclist -> veclist;
        endif;
    endfast_for;
enddefine;


;;; update_select_cells takes the row and column position changes
;;; of a window and updates the row/column position of the cells
define /* constant */ update_select_cells(row_delta, col_delta, win_rec);
lvars win_rec index row_delta col_delta entry entries = nn_win_select(win_rec);
    fast_for index from 1 to length(entries) do
        win_select_row(entries(index)) + row_delta
            -> win_select_row(nn_win_select(win_rec)(index));
        win_select_col(entries(index)) + col_delta
            -> win_select_col(nn_win_select(win_rec)(index));
    endfast_for;
enddefine;


;;; find_layer takes a window map and attempts to locate an entry in
;;; the layer. This entry then supplies the value for the current layer
;;; of the network being shown. If there are no entries then false
;;; is returned
define /* constant */ find_layer(row, cols, win_map) -> layer;
lvars row cols win_map layer = false,  index entry;
    fast_for index from 1 to cols do
        if (win_map(row, index) ->> entry) then
            win_map_layer(entry) -> layer;
            quitloop();
        endif;
    endfast_for;
enddefine;


/* ----------------------------------------------------------------- *
    Window Record Structure Functions
 * ----------------------------------------------------------------- */

;;; make_window_record takes the dimensions of the window
;;; to be created and builds the appropriate window structure.
;;; It ensures that there are no extraneous empty cells on the window.
;;; The cell width and height factor passed to -prune_window-
;;; depends on the type of window being displayed.
;;;
define /* constant */ make_window_record(netname, layer, rows, cols,
                          r_offset, c_offset, format, type) -> win_rec;
lvars netname layer format type i j rows cols r_offset c_offset
     win_rec width_factor height_factor;

	if type == "topology" then
		dcell_h -> height_factor;
		dcell_w -> width_factor;
	else
		cell_h -> height_factor;
		cell_w -> width_factor;
	endif;

	;;; make sure the window isn't too big
	prune_window(rows, cols, height_factor, width_factor) -> rows -> cols;

	consnn_window(netname, false, false, layer,
                             rows, cols, r_offset, c_offset,
                             false, format, [], type) -> win_rec;

    ;;; now create the window map
    newarray([%1, nn_win_rows(win_rec),
               1, nn_win_cols(win_rec)%], false) -> nn_win_map(win_rec);
enddefine;


;;; make_extent_record takes an existing window record and
;;; creates an appropriate extent record
define /* constant */ make_extent_record(win_rec) -> ext_rec;
lvars
    format = nn_win_format(win_rec),
    rows = win_format_rows(format),
    cols = win_format_cols(format),
    pix_rows = nn_extent_height - (nn_extent_height rem rows),
    pix_cols = nn_extent_width - (nn_extent_width rem cols),
    r_scale = max(pix_rows div rows, 1),    ;;; PNF0015
    c_scale = max(pix_cols div cols, 1),    ;;; PNF0015
    ext_rec = consnn_extent_window( nn_win_net(win_rec),
                                    false,
                                    false,
                                    rows,
                                    cols,
                                    r_scale,
                                    c_scale,
                                    nn_win_row_offset(win_rec),
                                    nn_win_col_offset(win_rec),
                                    nn_win_rows(win_rec),
                                    nn_win_cols(win_rec));

enddefine;


/* ----------------------------------------------------------------- *
    Window Map Creation Functions
 * ----------------------------------------------------------------- */

;;; make_topology_map takes a window record and creates the mapping
;;; from the cells on the window to an index into a layer
define /* constant */ make_topology_map(win_rec);
lvars win_rec top_map = nn_win_map(win_rec), row col,
	  rows = nn_win_rows(win_rec),
      cols = nn_win_cols(win_rec),
      row_offset = nn_win_row_offset(win_rec),
      col_offset = nn_win_col_offset(win_rec),
      net_map = nn_win_map(win_rec),
      network = nn_neural_nets(nn_win_net(win_rec)),
      start_c, layer_len, net_layer, end_col, start_index,
      displayable_rows, window_row,
      layers = nn_total_layers(network),
      max_cols = win_format_cols(nn_win_format(win_rec));

    ;;; clear out values in the array map
    set_array(net_map, boundslist(net_map), false);

    if row_offset >= 0 then
        min(layers - row_offset, rows) -> displayable_rows;
        max(rows - displayable_rows, 0) fi_+ 1 -> window_row;
        min(rows + row_offset, layers) fi_- 1 -> net_layer;
    else
        min(rows + row_offset, layers) -> displayable_rows;
        max(rows + row_offset - displayable_rows, 0) fi_+ 1 -> window_row;
        displayable_rows fi_- 1 -> net_layer;
    endif;

    fast_for row from 1 to displayable_rows do
        nn_units_in_layer(net_layer, network) -> layer_len;
        (max_cols fi_- layer_len) div 2 fi_- col_offset -> start_c;
        min(layer_len fi_+ start_c, cols) -> end_col;
        max(0 - start_c, 0) + 1 -> start_index;
        fast_for col from max(1, start_c fi_+ 1) to end_col do
            fill(net_layer,                ;;; net layer
                 nn_node_group_index(start_index,              ;;; group &
                                     net_layer, network),      ;;; index
                 initv(3)) -> net_map(window_row, col);
            start_index fi_+ 1 -> start_index;
        endfast_for;
        window_row fi_+ 1 -> window_row;
        net_layer fi_- 1 -> net_layer;
    endfast_for;
    net_map -> nn_win_map(win_rec);
enddefine;


;;; make_layer_map takes a window record and creates the mapping
;;; from the cells on the window to an index into a layer
section $-popneural;
define /* constant */ make_layer_map(win_rec);
lvars win_rec node_map = nn_win_map(win_rec),
	  rows = nn_win_rows(win_rec),
      cols = nn_win_cols(win_rec),
      layer = win_info_layer(nn_win_info(win_rec)),
      net = nn_neural_nets(nn_win_net(win_rec)),
      row_offset = nn_win_row_offset(win_rec),
      col_offset = nn_win_col_offset(win_rec),
      format = nn_win_format(win_rec), node_num = 1,
	  row col start_r rsize csize;

    ;;; clear out values in the array map
    set_array(node_map, boundslist(node_map), false);
    min(rows, format(1)) -> rsize;
    min(cols, format(2)) -> csize;
    fast_for row from 1 to rsize do
        fast_for col from 1 to csize do
            fill(layer,
                 nn_node_group_index(node_num, layer, net),
                 initv(3)) -> node_map(/* rows - row + 1 */ row, col);
			node_num fi_+ 1 -> node_num;
        endfast_for;
    endfast_for;
    node_map -> nn_win_map(win_rec);
enddefine;
endsection;


/* ----------------------------------------------------------------- *
    Window Creator Functions
 * ----------------------------------------------------------------- */

;;; make_window takes a window record, a window title and a
;;; position and creates a window of the appropriate dimensions
define /* constant */ make_window(win_rec, title, pos, scale_w, scale_h,
                   extra_w, extra_h) -> wid;
lvars win_rec title pos
      scale_w scale_h extra_w extra_h
      width = nn_win_cols(win_rec),
      height = nn_win_rows(win_rec),
      wid = false;

#_IF DEF PWMNEURAL
    if popunderpwm then
        if pos then
            pos -> pwm_window_location(pwmnxtwin);
        endif;

        create_pwm_gfxwin(title, width * scale_w + extra_w,
                          height * scale_h + extra_h) -> wid;

		if wid and nn_use_colour then
			setup_colour_map(wid);
		endif;
        return();
    endif;
#_ENDIF

#_IF DEF XNEURAL
    if popunderx then
        create_x_gfxwin(title, width * scale_w + extra_w,
                          height * scale_h + extra_h, pos) -> wid;
		if wid and nn_use_colour then
			setup_colour_map(wid);
		endif;
        return();
    endif;
#_ENDIF
    false -> wid;
enddefine;


;;; make_extent_window takes an extent record, a window title and a
;;; position and creates a window of the appropriate dimensions
define /* constant */ make_extent_window(ext_rec, title, pos) -> wid;
lvars title pos wid ext_rec;

#_IF DEF PWMNEURAL
    if popunderpwm then
        if pos then
            pos -> pwm_window_location(pwmnxtwin);
        endif;
        create_pwm_gfxwin(title,
                       nn_ext_cols(ext_rec) fi_* nn_ext_col_scale(ext_rec),
                       nn_ext_rows(ext_rec) fi_* nn_ext_row_scale(ext_rec))
            -> wid;
        return();
    endif;
#_ENDIF

#_IF DEF XNEURAL
    if popunderx then
        create_x_gfxwin(title,
                       nn_ext_cols(ext_rec) fi_* nn_ext_col_scale(ext_rec),
                       nn_ext_rows(ext_rec) fi_* nn_ext_row_scale(ext_rec),
                       pos) -> wid;
        return();
    endif;
#_ENDIF
    false -> wid;
enddefine;


/* ----------------------------------------------------------------- *
    Routines For Initializing Graphics Variables
 * ----------------------------------------------------------------- */

#_IF DEF PWMNEURAL

define gfx_setup_pwm();

	returnif(nn_gfx_setup_done);
    popunderpwm(3)(1) -> nn_max_win_width;
    popunderpwm(3)(2) -> nn_max_win_height;
    popunderpwm(3)(3) > 1 -> nn_use_colour;
    pwm_fontwidth(pwmstdfont) -> nn_stdfont_width;
    pwm_fontheight(pwmstdfont) -> nn_stdfont_height;
    true -> GUI;
	true -> nn_gfx_setup_done;
enddefine;

#_ENDIF

#_IF DEF XNEURAL

define gfx_setup_x();
lvars tmp;

	returnif(nn_gfx_setup_done);

    unless XptDefaultDisplay then
        XptDefaultSetup();
    endunless;

    nn_app_shell -> tmp;       ;;; create it
    XtScreen(tmp) -> tmp;
	XptScreenPtrApply("width", tmp)  -> nn_max_win_width;
	XptScreenPtrApply("height", tmp)  -> nn_max_win_height;
	(XptScreenPtrApply("depth", tmp) > 1) -> nn_use_colour;
	XptScreenPtrApply("black_pixel", tmp)  -> nn_black_pixel;
	XptScreenPtrApply("white_pixel", tmp)  -> nn_white_pixel;
    true -> GUI;
	true -> nn_gfx_setup_done;
enddefine;
#_ENDIF

vars procedure gfx_setup_generic =
    CHECK_GFXSWITCH gfx_setup_x gfx_setup_pwm gfx_setup_generic;

define nn_gfx_setup;
	gfx_setup_generic();
enddefine;

global vars nn_gfxutils = true;		;;; for "uses"

endsection; 	/* $-popneural */


/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 26/8/95
	Added missing lvars from update_select_cells. Replaced vars with
	lvars in update_select_cells, make_topology_map and make_layer_map.
-- Julian Clinton, 9/12/93
	Added nn_black_pixel and nn_white_pixel fir mono X displays.
-- Julian Clinton, 1/9/93
	Added include of xpt_xgcvalues to define GXxor etc.
	Added include of xpt_coretypes to define TYPESPECS etc.
-- Julian Clinton, 17/8/93
    Changed #_IF X* to #_IF DEF X*.
	Added change to NOTDST_OP for HP9000 machines
-- Julian Clinton, 26/3/93
	Modified definition of NOTDST_OP for SG.
-- Julian Clinton, 2/2/93
	Fixed problem with non-topology windows being pruned too much
		in make_window_record.
-- Julian Clinton, 19/1/93
	Modified setup of X colours for black and white.
-- Julian Clinton, 10/11/92
    Modified last change so that XptWMProtocols is true for OPEN LOOK 1.3.
-- Julian Clinton, 14/9/92
	dlocal'd XptWMProtocols false for both Motif and OPEN LOOK.
-- Julian Clinton, 7/8/92
	Moved core gfx initialisations in here (from nui_main.p).
-- Julian Clinton, 29/7/92
	Moved toplogy and extent map creator functions in here.
-- Julian Clinton, 28/7/92
    Moved loading of PWM libraries into here.
-- Julian Clinton, 17/7/92
	Renamed from gfxutils.p to nn_gfxutils.p.
-- Julian Clinton, 19/6/92
	Changed show_menu_gfx to show_options_gfx and modified it to
		accept idents and use -idval- rather than words and -valof-.
	Split out the control panel aspects of the options into
		show_panel_gfx.
-- Julian Clinton, 29/5/92
    Menus and window ids now held in ui_options_table rather than
		variables.
-- Julian Clinton, 8/5/92
    Sectioned.
*/
