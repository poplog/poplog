/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved ---------
 > File:            $popneural/src/pop/nn_gfxdefs.p
 > Purpose:         graphics display definitions
 > Author:          Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:   nn_netdisplay.p
 */

section $-popneural => nn_colour_range
                       nn_use_colour
                       nn_colour_map
                       nn_activs_scale
                       nn_bias_scale
                       nn_weights_scale
                       nn_min_win_height
                       nn_max_win_height
                       nn_max_win_width
                       nn_extent_width
                       nn_extent_height
                       nn_gfx_setup_done
;

;;; global flag which defines whether the graphics variables have been
;;; initialised
global vars nn_gfx_setup_done = false;

global constant nn_colour_range = 16;

global vars
        sys_colour_map = false,
        nn_use_colour = false,
        nn_colour_map = false,
        nn_black_pixel = 1,     ;;; not exported:may be changed during X setup
        nn_white_pixel = 0,     ;;; not exported:may be changed during X setup
        nn_activs_scale = 1,
        nn_bias_scale = 1,
        nn_weights_scale = 1,
        nn_min_win_height = 200,
        nn_max_win_height = 800,
        nn_max_win_width = 800,
        nn_extent_width = 256,
        nn_extent_height = 200,
        nn_stdfont_width = 10,
        nn_stdfont_height = 16;


/* ----------------------------------------------------------------- *
     Graphics Window Menu Table (Definition in nn_netdisplay.p)
 * ----------------------------------------------------------------- */

global vars gfxmenu_table;      ;;; property table to be set up at runtime


/* ----------------------------------------------------------------- *
     Window Structure Definitions
 * ----------------------------------------------------------------- */

/*
A network window consists of:
    a network which the window is displaying part of
    a window id as returned by the PWM
    an extent window record
    the number of rows being displayed
    the number of columns being displayed
    the row offset in the network (i.e. top row of display)
    the column offset in the network (i.e. left column of display)
    the node map (array mapping window cells onto indices onto
                  network, each item is a vector {layer group unit})
    the layer format (mapping from 1D onto 2D space)
    a slot holding the selected units
    a list of words identifying the function to be called
    a window type (e.g. "activs2d")
*/

recordclass nn_window
            nn_win_net
            nn_win_id
            nn_win_ext
            nn_win_info     ;;; [layer group node] for activs2d, weights2d
            nn_win_rows
            nn_win_cols
            nn_win_row_offset
            nn_win_col_offset
            nn_win_map      ;;; array size (row, col) containing:
                            ;;; {layer group index}
            nn_win_format
            nn_win_select   ;;; nodes interested in - format:
                            ;;; [{screen_row, screen_col, disp_proc}..]
            nn_win_type;


/* An extent window record consists of :
    the network being shown
    a window id
    number of network rows
    number of network columns
    number of pixels per row
    number of pixels per column
    the row offset of the highlighted area
    the column offset of the highlighted area
    the height of the box (in rows)
    the width of the box (in columns)
*/

recordclass nn_extent_window
            nn_ext_net
            nn_ext_mouse_at
            nn_ext_id
            nn_ext_rows
            nn_ext_cols
            nn_ext_row_scale
            nn_ext_col_scale
            nn_ext_row_offset
            nn_ext_col_offset
            nn_ext_box_height
            nn_ext_box_width;


;;; nn_window_record is a property table used to associate a
;;; window id with a window record
global vars nn_window_record = newproperty( [] , 20, false, "perm");

;;; is_extent_window is used to obtain the window id of the main
;;; window to which the extent is associated. This is then hashed
;;; into nn_window_record to obtain the main recordclass
global vars is_extent_window = newproperty( [], 20, false, "perm");

global constant half_cell_w = 8,
         cell_w = half_cell_w * 2,
         dcell_w = cell_w * 2,
         cell_h = cell_w * 3,
         dcell_h = cell_h * 2,
         ohcell_w = cell_w + half_cell_w;

endsection; /* $-popneural */

global vars nn_gfxdefs = true;

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 9/12/93
    Added nn_white_pixel and nn_black_pixel.
-- Julian Clinton, 17/7/92
    Renamed from gfxdefs.p to nn_gfxdefs.p.
-- Julian Clinton, 19/6/92
    Moved definitions of display menus out to nn_netdisplay.p
    Commented out weights_menu1 and activs_menu1.
-- Julian Clinton, 8/5/92
    Sectioned.
*/
