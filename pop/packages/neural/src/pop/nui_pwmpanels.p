/* --- Copyright Integral Solutions Ltd. 1992. All Rights Reserved --------
 > File:            $popneural/src/pop/nui_pwmpanels.p
 > Purpose:         PWM UI panel creators
 > Author:          Julian Clinton, July 1992
 > Documentation:
 > Related Files:
 */

section $-popneural;

pr(';;; Loading PWM panels\n');

uses nui_utils;


/* ----------------------------------------------------------------- *
    PWM Item Accessors/Updaters
 * ----------------------------------------------------------------- */

define constant update_pwmitem(value, var);
lvars var value;
    pwmitem_valof(value) -> idval(var);
enddefine;


/* ----------------------------------------------------------------- *
     PWM Specific Dialogs
 * ----------------------------------------------------------------- */

define /* constant */ sub_menu_pwm(options, values) -> val;
lvars options values val = false, int = false;

    pwm_displaymenu(options) -> int;
    if int and int > 0 then
        menu_valof(values(int))
    else
        false
    endif -> val;
enddefine;


define constant y_or_n_pwm(query) -> saidyes;
lvars query saidyes ans = [];
lconstant guiprompt = ' OK ? (L = Confirm, M/R = Cancel)',
          guipromptlen = length(guiprompt);
    pwm_promptuser(max(length(query) + 1, guipromptlen),
                   query <> guiprompt) -> ans;
    if ans(2) == `!` then
        true
    else
        false
    endif -> saidyes;
enddefine;


;;; the next two routines are used to implement a popup dialog in the PWM
lvars dlg_pwm_select = false;

define lconstant generic_select(val);
lvars val;
    val -> dlg_pwm_select;
enddefine;


define nui_confirm_pwm(prompt, options, default) -> val;
dlocal nn_exitfromproc = nui_confirm_pwm;
dlocal pwmgfxsurface, pwmgfxrasterop = PWM_SRC;
lvars x_offset prompt options default opt pad
    button_width prompt_width total_width n_selects win_id index y_offset;

    ;;; the formula for working out the width of the window is
    ;;; the sum of the lengths of all the options strings +
    ;;; the number of options supplied
    ;;;
    0 -> button_width;
    fast_for opt in options do
        length(opt) + button_width -> button_width;
    endfast_for;

    button_width + 1 + (length(options) ->> n_selects) -> button_width;

    max((length(prompt) + 2 ->> prompt_width), button_width) -> total_width;

    create_pwm_gfxwin('Confirm Window',
                    intof(total_width * nn_stdfont_width),
                    6 * nn_stdfont_height) -> win_id;

    win_id -> pwmgfxsurface;

    nn_stdfont_width -> x_offset;
    2 * nn_stdfont_height -> y_offset;

    pwm_draw_text(x_offset, y_offset, prompt);

    (max(total_width - button_width, 0) / n_selects) * 1.0s0 -> pad;

    intof(nn_stdfont_width * pad / 2) + x_offset -> x_offset;
    4 * nn_stdfont_height -> y_offset;

    fast_for index from 1 to n_selects do

        pwm_make_execitem(win_id, x_offset, y_offset, options(index),
                            generic_select(%index%)) ->;
        intof(nn_stdfont_width * (pad + 1 + length(options(index))))
            + x_offset -> x_offset;
    endfast_for;

    false -> dlg_pwm_select;
    pwm_wait_inevent(win_id, true);
    pwm_kill_window(win_id);
    pwm_reset_input();
    dlg_pwm_select -> val;

    unless val then
        default -> val;
    endunless;
enddefine;


define nui_message_pwm(prompt);
dlocal nn_exitfromproc = nui_message_pwm;
dlocal pwmgfxsurface, pwmgfxrasterop = PWM_SRC;
lvars prompt win_width total_width prompt_width win_id
        x_offset y_offset;

    max((length(prompt) + 2 ->> prompt_width), 8) -> total_width;

    intof(total_width * nn_stdfont_width) -> win_width;

    create_pwm_gfxwin('Message Window', win_width,
                    6 * nn_stdfont_height) -> win_id;

    win_id -> pwmgfxsurface;

    nn_stdfont_width -> x_offset;
    2 * nn_stdfont_height -> y_offset;

    pwm_draw_text(x_offset, y_offset, prompt);

    ((total_width div 2) - 3) * nn_stdfont_width -> x_offset;
    4 * nn_stdfont_height -> y_offset;

    pwm_make_execitem(win_id, x_offset, y_offset, ' Okay ', identfn) ->;
    pwm_wait_inevent(win_id, true);
    pwm_kill_window(win_id);
    pwm_reset_input();
enddefine;



/* ----------------------------------------------------------------- *
     PWM Specific Utility Functions
 * ----------------------------------------------------------------- */

global vars procedure
    (show_banner_pwm show_menu_pwm show_panel_pwm show_options_pwm);

;;; nui_pwm_select is used as the basis of closures to perform
;;; suitable actions when the PWM user interface has events on it.
;;; Only used for panels and options.
;;;
define nui_pwm_select(menu_item) -> press_handler;
lvars menu_item press_handler = false,
        ui_itemname ui_item title maxwidth labels values wid_var;

    if isprocedure(menu_item) then
        menu_item -> press_handler;

    elseif islist(menu_item) and length(menu_item) > 1 then
        ui_options_table(subscrl(2, menu_item) ->> ui_itemname) -> ui_item;
        if is_menu_ref(menu_item) then
            show_menu_pwm(%hd(ui_item), tl(ui_item)%) -> press_handler;

        elseif is_panel_ref(menu_item) then
            show_panel_pwm(%ui_itemname%) -> press_handler;

        elseif is_options_ref(menu_item) then
            show_options_pwm(%ui_itemname%) -> press_handler;

        endif;
    endif;
    unless press_handler then
        mishap(menu_item, 1, 'NUI: cannot create appropriate PWM selector');
    endunless;
enddefine;


define show_banner_pwm(dummy);
dlocal pwmgfxsurface, pwmgfxrasterop = PWM_SRC;
lvars dummy tmp_id;
    if ispwm_id(ui_options_table("banner_win") ->> tmp_id)
      and islivepwm_id(tmp_id) then
        pwm_killwindow(tmp_id);
        false -> ui_options_table("banner_win");
    endif;
    {0 0} -> pwm_window_location(pwmnxtwin);
    create_pwm_gfxwin('(c) 1992 Integral Solutions Ltd./University Of Sussex',
                      430, 70)
             ->> tmp_id -> ui_options_table("banner_win");
    if tmp_id then
        show_banner_pwm ->> pwmeventhandler(tmp_id, "resized")
                    -> pwmeventhandler(tmp_id, "quitrequest");
        erase ->> pwmeventhandler(tmp_id, "opened")
              ->> pwmeventhandler(tmp_id, "closed")
              ->> pwmeventhandler(tmp_id, "press")
              ->> pwmeventhandler(tmp_id, "release")
              ->> pwmeventhandler(tmp_id, "move")
              ->> pwmeventhandler(tmp_id, "mousexit")
              -> pwmeventhandler(tmp_id, "character");
        tmp_id -> pwmgfxsurface;
        pwm_gfxreadrasterfile( false,
                            sysfileok('$popneural/bitmaps/popneural.ras'),
                            10, 10);
    endif;
enddefine;


define show_menu_pwm(menu_string, values);
lvars menu_string val = false, int = false;

    pwm_displaymenu(menu_string) -> int;

    if int and int > 0 then
        menu_valof(values(int))
    else
        false
    endif -> val;

    if isprocedure(val) then
        apply(val);
    elseif val then
        mishap(val, 1, 'NUI: illegal menu result');
    endif;
enddefine;


define show_panel_pwm(panel_name);
dlocal nn_exitfromproc = show_panel_pwm;
lvars menu panel_name panel title maxwidth labels index = 1, num
      values wid_var win_id menu_name itemtype result;

    window_var(panel_name) -> wid_var;

    ;;; only create it if not already created
    if (ui_options_table(wid_var) ->> win_id) and ispwm_id(win_id) and
      islivepwm_id(win_id) then
        pwm_open_window(win_id);

    else

        ui_options_table(panel_name) -> panel;
        destpanel_txt(panel) -> title -> maxwidth -> labels -> values;
        length(labels) -> num;
        pad_spaces(title, maxwidth) -> title;

        create_pwm_gfxwin(title,
                        intof(length(title) * 5_/4  * nn_stdfont_width),
                        (num + 1) * 2 * nn_stdfont_height) -> win_id;
        if win_id then
            erase -> pwmeventhandler(win_id, false);
            for index from 1 to num do
                menu_valof(values(index)) -> result;
                pwm_make_execitem(win_id, 10, index * 2 * nn_stdfont_height,
                                pad_spaces(labels(index), maxwidth),
                                nui_pwm_select(result)) ->;
            endfor;
            generic_quit(%win_id, wid_var%) -> pwmeventhandler(win_id, "quitrequest");
            win_id -> ui_options_table(wid_var);
        else
            warning(0, err(FAIL_WINMAKE));
        endif;
    endif;
enddefine;


define show_options_pwm(panel_name);
dlocal nn_exitfromproc = show_options_pwm;
lvars menu panel_name panel title maxwidth labels index = 1, num
      values wid_var win_id menu_name menuval disp_item itemtype;

    window_var(panel_name) -> wid_var;

    ;;; only create it if not already created
    if (ui_options_table(wid_var) ->> win_id) and ispwm_id(win_id) and
      islivepwm_id(win_id) then

        pwm_open_window(win_id);
    else
        ui_options_table(panel_name) -> panel;
        destpanel_txt(panel) -> title -> maxwidth -> labels -> values;
        length(labels) -> num;

        pad_spaces(title, maxwidth) -> title;
        create_pwm_gfxwin(title,
                        intof(length(title) * 5_/4  * nn_stdfont_width),
                        (num + 1) * 2 * nn_stdfont_height) -> win_id;

        if win_id then
            erase -> pwmeventhandler(win_id, false);
            for index from 1 to num do
                if back(menu_valof(values(index)) ->> menuval) == "boolean" then
                    pwm_make_toggleitem(win_id, 10, index * 2 * nn_stdfont_height,
                                  idval(front(menuval)),
                                  pad_spaces(labels(index), maxwidth),
                                  updater(idval(%front(menuval)%))) -> disp_item;
                    conspair(win_id, disp_item) -> ui_options_table(front(menuval));
                else
                    pwm_make_labelitem(win_id, 10, index * 2 * nn_stdfont_height,
                                 20, pad_spaces(labels(index), maxwidth - 20),
                                 idval(front(menuval)),
                                 update_pwmitem(%front(menuval)%)) -> disp_item;
                    conspair(win_id, disp_item) -> ui_options_table(front(menuval));
                endif;
            endfor;
            generic_quit(%win_id, wid_var%) ->
                pwmeventhandler(win_id, "quitrequest");
            win_id -> ui_options_table(wid_var);
        else
            warning(0, err(FAIL_WINMAKE));
        endif;
    endif;
enddefine;


;;; show_mainpanel_pwm displays the main control panel under PWM.
;;; Currently it simply calls show_panel_pwm.
;;;
define show_mainpanel_pwm(panel_name);
lvars panel_name;

    show_panel_pwm(panel_name);
enddefine;

global vars nui_pwmpanels = true;       ;;; for "uses"

endsection;

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 27/7/92
    Modified calls to show_panel_pwm and show_options_pwm to take
    the panel name only.
*/
