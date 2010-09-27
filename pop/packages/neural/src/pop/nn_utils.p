/* --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:           $popneural/src/pop/nn_utils.p
 > Purpose:        miscellaneous utility functions
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:
 */

/* ----------------------------------------------------------------- *
    New Version Of COPYDATA For Arrays
 * ----------------------------------------------------------------- */

section;

lconstant Prologvar_key = datakey(prolog_newvar());

define global procedure newcopydata(x);
    lvars x key = datakey(x);

    define copyarray(A) -> NA;
        unless A.isarray then mishap('ARRAY NEEDED', [^A]); endunless;
        newanyarray(boundslist(A),  copydata(A.arrayvector)) -> NA;
    enddefine;

    if key == Prologvar_key then prolog_newvar()
    elseif class_spec(key) then
        appdata(x,
            procedure(y);
                lvars y;
                if y == x and not(isprologvar(y)) then
                    ;;; printinging the circular culprit
                    ;;; gives another problem
                        mishap(0, 'TRYING TO COPY A CIRCULAR '
                            sys_>< dataword(y));
                else
                    copydata(y)
                endif
            endprocedure);
        if isvectorclass(x) then datalength(x) endif;
        apply(class_cons(key));
    elseif isarray(x) then
        copyarray(x);
    else
        x;
    endif;
enddefine;

endsection;

section $-popneural;

include sysdefs;

/* ----------------------------------------------------------------- *
    Type Checkers
 * ----------------------------------------------------------------- */

define lconstant Check_type(item, allow_false, word);
lvars item allow_false word;
    unless not(item) and allow_false then
        unless dataword(item) == word then
            mishap(item, 1, sprintf(word, '%p needed'));
        endunless;
    endunless;
enddefine;

global constant procedure (
    Check_string = Check_type(%"string"%),
    Check_word = Check_type(%"word"%),
    Check_integer = Check_type(%"integer"%),
);

define global Check_list(item, allow_false);
lvars item allow_false dword;
    unless not(item) and allow_false then
        unless islist(item) then
            mishap(item, 1, 'list needed');
        endunless;
    endunless;
enddefine;

define global Check_vectorclass(item, allow_false);
lvars item allow_false;
    unless not(item) and allow_false then
        unless isvectorclass(item) or
          (isarray(item) and length(boundslist(item)) == 2) then
            mishap(item, 1, 'vector or 1-d array needed');
        endunless;
    endunless;
enddefine;


/* ----------------------------------------------------------------- *
    List Utilities
 * ----------------------------------------------------------------- */

define constant sublist(start_at, items, list);
lvars start_at items list index;
    [%
        fast_for index from 0 to
                 min(items fi_- 1, length(list) fi_- start_at) do
            list(start_at fi_+ index);
        endfast_for;
    %]
enddefine;


/* ----------------------------------------------------------------- *
    File System Utilities
 * ----------------------------------------------------------------- */

global vars isdirectory;
#_IF DEF UNIX
sysisdirectory -> isdirectory; ;;; use system definition
#_ELSE  /* VMS */
define isdirectory(path); /* -> boolean */
    lvars path;

    define dlocal prmishap(str, list);
        lvars str, list;
        exitfrom(false, isdirectory)
    enddefine;

    dlocal current_directory = path;
    true
enddefine;
#_ENDIF


/* ----------------------------------------------------------------- *
    List And Array Handling
 * ----------------------------------------------------------------- */

;;; set_array takes a value and an array and assigns the value
;;; to each cell in that array
define constant set_array(array, bounds, value);
lvars array value bounds len arr_index;
    unless isarray(array) then
        mishap('Array needed', [^array]);
    else
        unless (length(bounds) ->> len) == 2 then
            fast_for arr_index from bounds(len - 1) to bounds(len) do
                set_array(array(%arr_index%),
                          sublist(1, len - 2, bounds), value);
            endfast_for;
        else
            fast_for arr_index from bounds(1) to bounds(2) do
                value -> array(arr_index);
            endfast_for;
        endunless;
    endunless;
enddefine;

;;; sumlist takes a list containing numbers and returns
;;; the sum of all those numbers
define constant sumlist(list) -> sum;
lvars list num sum = 0;
    for num in list do
        num + sum -> sum;
    endfor;
enddefine;

;;; vecerror takes two vectors, a start and end index and returns the
;;; error factor between the two
define vecerror(vec1, vec2, start, finish) -> err;
lvars vec1 vec2 start finish err = 0.0,  index;
    fast_for index from start to finish do
        (vec1(index) - vec2(index)) ** 2 + err -> err;
    endfast_for;
    err / 2.0 -> err;
enddefine;

;;; are_types takes a predicate and a list of items and applies the
;;; predicate to all items in the list. If an application
;;; returns false then the procedure returns false
define constant are_types(pred, typelist) -> result;
lvars typelist pred item result = true;
    unless islist(typelist) then
        mishap('List needed', [^typelist]);
    else
        fast_for item from 1 to length(typelist) do
            unless pred(subscrl(item, typelist)) then
                false -> result;
                quitloop();
            endunless;
        endfast_for;
    endunless;
enddefine;


;;; flushbuffers clears the various POPLOG buffers
define constant flushbuffers();
    sys_clear_input(poprawdevin);
    sys_clear_input(popdevin);
    sysflush(popdevout);
    sysflush(poprawdevout);
enddefine;


;;;; eraseandquit takes a procedure which leaves an item on the
;;; stack and erases that item before quitting
define constant eraseandquit(proc);
lvars proc;
    erase();
    false;
    exitfrom(proc);
enddefine;


/* ----------------------------------------------------------------- *
    String Utilities
 * ----------------------------------------------------------------- */

define pad_spaces(item, maxlen) -> padded_string;
lvars item maxlen padded_string;

    explode(item);
    repeat (maxlen - length(item)) times
        ` `;
    endrepeat;
    consstring(max(length(item), maxlen)) -> padded_string;
enddefine;

/* ----------------------------------------------------------------- *
    Property To List Converters
 * ----------------------------------------------------------------- */

;;; prop_arg_list takes two arguments, an argument and a property table
;;; entry and returns a list containing the name twice (so that
;;; the list can be used with show_menu and get_choice).
define constant prop_arg_list(arg, entry) -> name;
lvars arg entry name = arg;
enddefine;


;;; prop_list takes a property table and returns a list of lists
;;; of all the arguments with associated entries
define constant prop_list(property) -> list;
lvars property list = [%appproperty(property, prop_arg_list)%];
    unless list == [] then
        if isstring(hd(list)) or isword(hd(list)) or isnumber(hd(list)) then
            sort(list) -> list;
        endif;
    endunless;
enddefine;


;;; menu_list takes a list of words and converts it into a list
;;; suitable for menus
define constant menu_list(list) -> menu;
lvars name list menu;
    [%
        fast_for name in list do
            name sys_>< '';
        endfast_for;
    %] :: list -> menu;
enddefine;


/* ----------------------------------------------------------------- *
    Menu Utilities
 * ----------------------------------------------------------------- */

;;; menu_valof takes the value returned as the value of the menu.
;;; If the value is a list and the head of the list is a procedure
;;; then the head and tail are partially applied, otherwise
;;; the value is returned
define constant menu_valof(value);
lvars value;
    if islist(value) and isprocedure(hd(value)) then
        partapply(hd(value), tl(value));
    else
        value
    endif;
enddefine;


;;; destmenu_txt takes a text menu and returns the three components
define constant destmenu_txt(menu) -> title -> labels -> values;
lvars menu title labels values;
    hd(hd(menu)) -> title;
    tl(hd(menu)) -> labels;
    tl(menu) -> values;
enddefine;


;;; destpanel_txt takes a text panel and returns the three components
;;; which make up the structure plus the width of the menu (which
;;; may be required by display mechanism). The structure of a panel
;;; definition is that the head contains the title, the maximum width
;;; that the panel should have and the options to be displayed. The
;;; tail is the list of return results.
define constant destpanel_txt(panel) -> title -> maxwidth -> labels -> values;
lvars panel paneldesc maxwidth title labels values;
    hd(panel) -> paneldesc;
    tl(panel) -> values;
    hd(paneldesc) -> title;
    hd(tl(paneldesc)) -> maxwidth;
    tl(tl(paneldesc)) -> labels;
enddefine;


;;; build_txt_menu takes a generic menu structure and returns a text menu
define build_txt_menu(menu) -> txtmenu;
lconstant std_suffix = ' Menu';
lvars menu txtmenu width add_suffix title;

    ;;; split out the main parts
    dest(menu) -> menu -> width;
    dest(menu) -> menu -> add_suffix;
    dest(menu) -> txtmenu -> title;

    if add_suffix then
        title sys_>< std_suffix -> title;
    endif;

    title :: txtmenu -> txtmenu;
enddefine;


;;; build_pwm_menu takes a generic menu structure and returns a PWM menu
define build_pwm_menu(menu) -> pwmmenu;
lvars menu item pwmmenu n_chars = 0;

    ;;; ignore width and whether to add suffix
    dest(menu) -> menu ->;
    dest(menu) -> menu ->;

    for item in menu do
        datalength(item) fi_+ 1 fi_+ n_chars -> n_chars;
        explode(item);`\t`;
    endfor;

    consstring(n_chars) -> pwmmenu;
enddefine;


;;; build_x_menu takes a generic menu structure and returns an X menu
define build_x_menu(menu) -> xmenu;
lvars menu xmenu;

    ;;; The X version simply needs to take the title and options
    copydata(tl(tl(menu))) -> xmenu;
enddefine;

global vars procedure nn_interrupt = setpop;

global vars nn_utils = true;

endsection;     /* $-popneural */


/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 27/4/93
    Changed initial setting of nn_interrupt to be setpop instead of
    interrupt.
-- Julian Clinton, 17/7/92
    Renamed utils.p to nn_utils.p and split out all UI-related code
    into nui_utils.p (note that some menu code has to stay here since
    menus are used by the network display stuff which is separate from
    the "normal" product UI).
-- Julian Clinton, 27/6/92
    Added get_strings and edit_flag_value.
-- Julian Clinton, 19/6/92
    Modifed change_var to take idents and use idval rather than to
    use words and valof.
    Added build_(txt/pwm/x)_menu procedures.
-- Julian Clinton, 29/5/92
    Modified menu_valof to partially apply the head and tail if the
    argument is a list.
    Now uses fmatches.
-- Julian Clinton, 8/5/92
    Sectioned.
-- Julian Clinton, 14th Sept. 1990:
    PNE0055 Added checks for "nn_std_ttys" so terminals other than vt100's
    can be used to display bold etc.
*/
