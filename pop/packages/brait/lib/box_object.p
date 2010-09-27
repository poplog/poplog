/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/lib/box_object.p
 > Purpose:         box object definition
 > Author:          Duncan K Fewkes, Feb 2 2000 (see revisions)
 > Documentation:
 > Related Files:
 */
/*

         CONTENTS - (Use <ENTER> gg to access required sections)

 define:class box;is sim_immobile sim_object;
 define :method sim_run_agent(object:box, objects);
 define create_box(vert_list)-> new_box;
 define rc_mouse_draw_box(stop_button)-> list;
 define draw_box()->box;

*/

/*
CLASS    : box
CREATED  : 2 Feb 2000
PURPOSE  : ???

*/

define:class box;is sim_immobile sim_object;


    slot vertices = [];
    ;;; This will contain a list of vertices, specified as the x and y
    ;;; coordinates of each vertex.

    ;;; e.g.
    ;;; [ [x1 y1] [x2 y2] [x3 y3] ... [xn yn] ]

    ;;; NB - all boxes are closed loops.

    slot source_info = [];
    slot rc_pic_lines;
    slot sim_name = gensym("box");
    slot sim_status = [active];
    slot pic_name = sim_name;
	slot sim_sensors = [];


enddefine;

define :method sim_run_agent(object:box, objects);
	;;; added by A.S.

	;;; dkf added - stops mouse-selected obj's from moving
	returnif(object == rc_mouse_selected(brait_world));

	call_next_method(object, objects);

enddefine;


/****************************************************************************/


/*
PROCEDURE: create_box (vert_list) -> new_box
INPUTS   : vert_list is a list of the vertices that make up the structure
            (specified by their coordinates)
OUTPUTS  : new_box is a box object
USED IN  : sim_scheduler
CREATED  : 3 Feb 2000
PURPOSE  : to create instances of boxes

TESTS:

create_box( [[0 0] [0 200] [200 200] [200 0]]) -> box1;
box1==>;

*/


define create_box(vert_list)-> new_box;

    lvars point, count, check, pic_lines = [], name=gensym("box");


    /******************** QUICK CHECK!******************************************/

    for count in vert_list do
        if length(count) /= 2 then

            [BOX CREATION ERROR. EACH VERTEX MUST BE SPECIFIED BY
                AN X AND A Y COORDINATE] ==>;
            return(false);

        endif;
    endfor;

;;;[VERTICES = %vert_list%]==>; ;;;debug



    /******************** CHECK VERTICES ***************************************/

    for count from 1 to length(vert_list) do
        if count = length(vert_list) then
            if vert_list(count)(1) /= vert_list(1)(1) and
                vert_list(count)(1) /= vert_list(1)(2) and
                vert_list(count)(2) /= vert_list(1)(1) and
                vert_list(count)(2) /= vert_list(1)(2) then
                [ERROR IN VERTICES COORDINATES. EITHER WALLS ARE NOT VERTICAL/HORIZONTAL OR VERTICES NOT IN ORDER] ==>;
                return(false);
            endif;
        else
            if vert_list(count)(1) /= vert_list(count+1)(1) and
                vert_list(count)(1) /= vert_list(count+1)(2) and
                vert_list(count)(2) /= vert_list(count+1)(1) and
                vert_list(count)(2) /= vert_list(count+1)(2) then
                [ERROR IN VERTICES COORDINATES. EITHER WALLS ARE NOT VERTICAL/HORIZONTAL OR VERTICES NOT IN ORDER] ==>;
                return(false);
            endif;
        endif;
    endfor;


    /******************** CALCULATE PIC_LINES ***********************************/
    for point in vert_list do
        pic_lines <> [{ %point(1)% %point(2)% }] -> pic_lines;
    endfor;


    [COLOUR 'purple' CLOSED ^^pic_lines] -> pic_lines;

;;;[BOX PIC_LINES = %pic_lines%] ==>; ;;;debug



    /********************* CREATE INSTANCE **************************************/

    instance box

        vertices = vert_list;
        rc_pic_lines = pic_lines;

        sim_name = name;
        ;;;rc_mouse_limit = 100;

    endinstance -> new_box;

    sim_set_coords(new_box, 0, 0);


    if isundef(brait_world) or not(rc_islive_window_object(brait_world)) then
        create_window(500,500);
    endif;

    unless sim_running then
        show_and_name_instance(name, new_box, brait_world);
    endunless

enddefine;


/*
PROCEDURE: rc_mouse_draw_box(stop_button)
INPUTS   : stop_button
  Where  :
    stop_button is the button that will finish the box and create it.
OUTPUTS  : creates/returns the new box object
USED IN  :
CREATED  : 4 Jul 2000
PURPOSE  : to allow the user to draw box objects with the mouse

TESTS:

create_window(500,500);
rc_mouse_draw_box(3);

sim_scheduler(100);

*/

define rc_mouse_draw_box(stop_button)-> list;
    ;;; Draw a picture using the mouse. If listpoints is true, then
    ;;; return a list of points. Use "rubber banding effect"

    lvars listpoints, list = [], stop_button,
        lastx, lasty,   ;;; last actual point
        tempx, tempy,   ;;; last end of "rubber band" line
        cornerx, cornery,
        corner2x, corner2y, boxstarted=false, newbox;

    dlocal rc_linefunction;

    define lconstant first(x, y, data, item);
        lvars x, y, data, item;
        rc_jumpto(x,y);
        rc_drawpoint(x,y);
        x ->> lastx -> tempx; y->> lasty -> tempy;
    enddefine;

    define lconstant other(x, y, data, item);
        lvars x,y,data, item;
        returnif(item == "button" and data < 0);
        ;;; clear last line
        rc_jumpto(lastx,lasty);
        rc_rubber_function -> rc_linefunction;
        if boxstarted then
            rc_drawto(cornerx, cornery);
            rc_drawto(tempx,tempy);
            rc_jumpto(lastx, lasty);
            rc_drawto(corner2x, corner2y);
            rc_drawto(tempx,tempy);
        endif;

        ;;; draw new line (properly if button pressed)
        rc_jumpto(lastx,lasty);
        if item == "button" then GXcopy else rc_rubber_function endif
            -> rc_linefunction;
        lastx -> cornerx; y -> cornery;
        lasty -> corner2y; x -> corner2x;
        rc_drawto(cornerx, cornery);
        rc_drawto(x,y);
        rc_jumpto(lastx, lasty);
        rc_drawto(corner2x, corner2y);
        rc_drawto(x,y);
        true -> boxstarted;


        if item == "button" then
            if listpoints then
                [[^lastx ^lasty] [^cornerx ^cornery] [^x ^y]
                [^corner2x ^corner2y] ]  -> list;
            endif;

            ;;;create_box(list) -> box;
            rc_redraw_window_object(brait_world);

            ;;;list==>; ;;;debug
            ;;;object_list==>; ;;;debug
            x -> lastx; y -> lasty;
        else
            x -> tempx; y -> tempy;
        endif;
    enddefine;

    define lconstant exit(/*x, y,*/ data, item);
        lvars data, item;
        -> ->;  ;;; remove x and y from stack
        item == "button" and data == stop_button
    enddefine;

    rc_mouse_do(first, other, exit);

enddefine;


/*
PROCEDURE: draw_box ()-> box
INPUTS   : NONE
OUTPUTS  : box is a box object
USED IN  :
CREATED  : 4 July 2000
PURPOSE  : shortcut for calling the mouse draw box procedure. Also allows it to
be called from asynchronous menu panel.

TESTS:

*/

define draw_box()->box;

    dlocal rc_in_event_handler = true;

    lvars list;

    if isundef(brait_world) or not(xt_islivewindow(rc_widget(brait_world))) then
        create_window(500,500);
    endif;

    rc_mouse_draw_box(3)->list;
    create_box(list) -> box;
    rc_redraw_window_object(brait_world);

enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec 23 2000
	Renamed file as box_object.p

--- Aaron Sloman, Oct 13 2000
	Changed A.Sloman to remove sensors, which caused a memory leak.

--- Aaron Sloman, Oct  8 2000
	added method: sim_run_agent
	Also fixed file name, and added index

--- Duncan K Fewkes, Aug 30 2000
	converted to lib format
 */
