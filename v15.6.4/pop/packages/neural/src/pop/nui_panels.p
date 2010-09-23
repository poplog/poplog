/* --- Copyright Integral Solutions Ltd. 1992. All Rights Reserved --------
 > File:            $popneural/src/pop/nui_panels.p
 > Purpose:         Generic UI panel procedures
 > Author:          Julian Clinton, July 1992
 > Documentation:
 > Related Files:
 */

section $-popneural;

uses nui_txtpanels;

#_IF DEF PWMNEURAL
uses nui_pwmpanels;
#_ENDIF

#_IF DEF XNEURAL
uses nui_xpanels;
#_ENDIF


/* ----------------------------------------------------------------- *
    Generic Dialogs
 * ----------------------------------------------------------------- */

;;; nui_message takes a string and displays either in a prompt box or as
;;; text
;;;
define constant nui_message(string);
lvars string;
dlocal pop_readline_prompt = '';

    if GUI then

#_IF DEF PWMNEURAL
        if popunderpwm then
            nui_message_pwm(string);
            return();
        endif;
#_ENDIF

#_IF DEF XNEURAL
        if popunderx then
            nui_message_x(string);
            return();
        endif;
#_ENDIF

    else
        nui_message_txt(string);
    endif;
enddefine;


define constant y_or_n(query) -> saidyes;
lvars query saidyes;

    if GUI then
#_IF DEF PWMNEURAL
        y_or_n_pwm(query) -> saidyes;
#_ENDIF

#_IF DEF XNEURAL
        y_or_n_x(query) -> saidyes;
#_ENDIF

    else
        y_or_n_txt(query) -> saidyes;
    endif;
enddefine;


define nui_confirm(prompt, options, default) -> val;
lvars prompt options default;

#_IF DEF PWMNEURAL
    if popunderpwm then
        nui_confirm_pwm(prompt, options, default) -> val;
        return();
    endif;
#_ENDIF

#_IF DEF XNEURAL
    if popunderx then
        nui_confirm_x(prompt, options, default) -> val;
        return();
    endif;
#_ENDIF

    nui_confirm_txt(prompt, options, default) -> val;
enddefine;


/* ----------------------------------------------------------------- *
     Graphics Menu/Panel Utility Functions
 * ----------------------------------------------------------------- */

define show_panel_gfx();
#_IF DEF PWMNEURAL
    if popunderpwm then
        chain(show_panel_pwm);
    endif;
#_ENDIF

#_IF DEF XNEURAL
    if popunderx then
        chain(show_panel_x);
    endif;
#_ENDIF
enddefine;


define show_options_gfx();
#_IF DEF PWMNEURAL
    if popunderpwm then
        chain(show_options_pwm);
    endif;
#_ENDIF

#_IF DEF XNEURAL
    if popunderx then
        chain(show_options_x);
    endif;
#_ENDIF
enddefine;


define show_mainpanel_gfx();
#_IF DEF PWMNEURAL
    if popunderpwm then
        chain(show_mainpanel_pwm);
    endif;
#_ENDIF

#_IF DEF XNEURAL
    if popunderx then
        chain(show_mainpanel_x);
    endif;
#_ENDIF
enddefine;


/* ----------------------------------------------------------------- *
    Generic File IO Dialogs
 * ----------------------------------------------------------------- */

define nui_select_saveitems(directory, choice_list,
                        prompt, list_label) -> savedir -> saveitems;
lvars directory choice_list prompt list_label savedir saveitems;
dlocal current_directory;

#_IF DEF XNEURAL
    if popunderx then
        nui_select_saveitems_x(directory, choice_list,
                            prompt, list_label) -> savedir -> saveitems;
        return();
    endif;
#_ENDIF

    if directory then
        directory -> current_directory;
    endif;
    use_basewindow(true);
    nl(1);
    heading(prompt);
    nl(1);
    get_directory() -> savedir;
    print_list(list_label, choice_list);
    get_lists(1, 'Selection', false, "all") -> saveitems;
    if saveitems = [all] then
        choice_list -> saveitems;
    endif;
enddefine;


define nui_select_loaditems(directory, update_proc, choice_list,
                            prompt, list_label) -> loaddir -> loaditems;
lvars directory choice_list update_proc prompt list_label
        loaddir loaditems = false, filenames;
dlocal current_directory;

#_IF DEF XNEURAL
    if popunderx then
        nui_select_loaditems_x(directory, update_proc, choice_list,
                            prompt, list_label) -> loaddir -> loaditems;
        return();
    endif;
#_ENDIF

    if directory then
        directory -> current_directory;
    endif;
    use_basewindow(true);
    nl(1);
    heading(prompt);
    nl(1);
    get_directory() -> current_directory;
    update_proc(current_directory) -> filenames;
    if filenames /== [] then
        print_list(sprintf(current_directory, list_label, '%p in %p'), filenames);
        get_lists(1, 'Select', false, "all") -> loaditems;
        if loaditems = [all] then
            filenames -> loaditems;
        endif;
    endif;
    current_directory -> loaddir;
enddefine;

define nui_do_saveitems(items, directory, file_extn, saveitem_proc) -> saved_items;
dlocal current_directory;
lvars items item directory file_extn saveitem_proc saved_items = [];

    if isstring(directory) then
        directory -> current_directory;
    endif;

    for item in items do
        if saveitem_proc(item, item sys_>< file_extn) then
            item :: saved_items -> saved_items;
        endif;
    endfor;
    ncrev(saved_items) -> saved_items;
enddefine;


define nui_do_loaditems(items, directory, file_extn, loaditem_proc) -> loaded_items;
dlocal current_directory;
lvars items item directory file_extn loaditem_proc loaded_items = [];

    if isstring(directory) then
        directory -> current_directory;
    endif;

    for item in items do
        if loaditem_proc(item, item sys_>< file_extn) then
            item :: loaded_items -> loaded_items;
        endif;
    endfor;
    ncrev(loaded_items) -> loaded_items;
enddefine;


/* ----------------------------------------------------------------- *
     Variable Updaters
 * ----------------------------------------------------------------- */

define nui_singleselect(choice_list, prompt, list_label, action_label) -> val;
lvars choice_list prompt list_label action_label val = false;

#_IF DEF XNEURAL
    if popunderx then
        nn_singlechoice_x(choice_list, prompt, list_label, action_label)
            -> val;
        return();
    endif;
#_ENDIF

#_IF DEF PWMNEURAL
    if popunderpwm then
        nn_singlechoice_pwm(choice_list, prompt, list_label, action_label)
            -> val;
        return();
    endif;
#_ENDIF

    nui_singlechoice_txt(choice_list, prompt, list_label, action_label)
        -> val;
enddefine;


define nui_multiselect(choice_list, prompt, list_label, action_label) -> selections;
lvars choice_list prompt list_label action_label selections = false;

#_IF DEF XNEURAL
    if popunderx then
        nn_multichoice_x(choice_list, prompt, list_label, action_label)
            -> selections;
        return();
    endif;
#_ENDIF

#_IF DEF PWMNEURAL
    if popunderpwm then
        nn_multichoice_pwm(choice_list, prompt, list_label, action_label)
            -> selections;
        return();
    endif;
#_ENDIF

    nui_multichoice_txt(choice_list, prompt, list_label, action_label)
        -> selections;
enddefine;


/* ----------------------------------------------------------------- *
     Variable Updaters
 * ----------------------------------------------------------------- */

;;; special variables which may appear in windows need to be
;;; updated accordingly. This fills in the hooks left in
;;; nn_activevars.p
;;;
define ui_variable_display(variable_ident, type) -> val;
lvars val variable_ident type tmp_id;

    mishap(variable_ident, 1, 'NUI: attempt to access variable value');
enddefine;

define updaterof ui_variable_display(val, variable_ident, type);
lvars val variable_ident tmp_id type;

    ;;; if we have been pased false and the datatype is not boolean
    ;;; then assume the result is a name so assign the nullstring.
    if not(val) and type /== boolean_key then
        nullstring -> val;
    endif;

#_IF DEF PWMNEURAL
    if popunderpwm and (ui_options_table(variable_ident) ->> tmp_id) and
      ispwm_id(front(tmp_id)) and islivepwm_id(front(tmp_id)) then
        val -> pwmitem_valof(back(tmp_id));
        return();
    endif;
#_ENDIF

#_IF DEF XNEURAL
    if popunderx and (ui_options_table(variable_ident) ->> tmp_id) then
        val -> propsheet_field_value(front(tmp_id), back(tmp_id));
    endif;
#_ENDIF
enddefine;

global vars nui_panels = true;       ;;; for "uses"

endsection;

/*  --- Revision History --------------------------------------------------
*/
