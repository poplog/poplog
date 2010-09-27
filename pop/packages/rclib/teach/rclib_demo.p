/*
TEACH RCLIB_DEMO.P                                 Aaron Sloman June 1997
                                                     Updated 25 Aug 2002

Note:
    replaced "rc_informant_contents" with "rc_informant_value"
	The former is left as a synonym for the latter, to enable
	old user code to continue work.

This file gives a rapid-fire introduction to a subset of the facilities
in the RCLIB package described more fully in HELP * RCLIB and the files
referred to therein.

RCLIB includes graphical windows into which you can draw static and
movable pictures using a variety of drawing commands, active buttons,
menus, text-input and number-input panels, sliders, scrolling text
panels, and tools for creating automatically formatted panels so that
you don't have to work out detailed locations for every item.

There is also a library for displaying tree structures graphically,
in various formats: rc_showtree

Some of the main facilities are demonstrated below, with simple
examples. Working through the file should take 20 to 40 minutes,
depending on how much experimenting you do. At the end, pointers
are given to additional teach and help files.

Start with this command, to make all the files accessible.

    uses rclib

(If that doesn't work, ask your local poplog administrator to install
a link to the rclib.p file.)

RCLIB makes available a powerful collection of object-oriented graphical
facilities based on the X window interface in Pop-11. There are teach
and help files giving documentation for a collection of library files
(some autoloadable) giving a wide range of facilities for building
graphical interfaces. If you have previously used RC_GRAPHIC you are
advised not to try mixing RC_CONTEXT with the facilities described here.
The rc_window_object class makes that completely redundant.

NOTE: some of the default colours may not work well for your screen.
If you need help changing the defaults post your query to this news
group:
	comp.lang.pop


Changes 19 Feb 2000

Changed to reflect new conventions using "background" to mean
background colour and false to mean current foreground colour,
e.g. in rc_draw_blob, rc_draw_centred_rect, rc_draw_centred_square

Changes 16 Dec 1999

Added introductory section and examples using rc_get_coords

Changes 29 May 1999:
Reorganised, with more information on moving sub-panels and panel
sliders.

Latest changes 20 May 1999:
(Showed how one panel can contain another).
(Showed how sliders can now be moved by "clicking".
Examples of Text and Number input fields, and Someof and Radio buttons,
all linked to variables, and with labels added,
and constrained number values.
Examples of sliders with step values added. Changed 'bg' to 'barcol' in
sliders.)


CONTENTS

 -- INTRODUCTION
 -- Using rc_poster to display persistent messages
 -- Using rc_message to display dismissable messages
 -- Using rc_message_wait to display synchronous messages
 -- Using the scrolling text panel mechanism
 -- Using rc_popup_query to present menus
 -- -- Single option menus
 -- -- Multiple option menus ("someof" menus)
 -- An alternative popup menu facility: rc_popup_strings
 -- CREATING GRAPHICAL WINDOWS
 -- Using rc_get_coords to select locations in the window
 -- Using rc_mouse_coords to select locations in a window
 -- Using points that are visible and movable
 -- Using rc_get_mouse_points to select visible locations
 -- Drawing movable pictures in a graphic window
 -- Making the the object drag1 draggable with the mouse
 -- Adding buttons to control a movable object
 -- Making a movable panel inside another panel
 -- Using "opaque" movable objects
 -- Making sliders: horizontal, vertical, diagonal
 -- Sliders with panels with 'proper' colours
 -- Linking a picture into two windows: rc_linked_pic
 -- Creating a rotating object
 -- More types of buttons
 -- -- Counter buttons and toggle buttons
 -- -- Radio buttons and someof buttons: an example.
 -- Complete list of action specifications for action buttons
 -- USING RC_CONTROL_PANEL
 -- A simple control panel
 -- Another example with text and number input fields
 -- Example, putting a new panel inside an old one
 -- Moving sub-panels
 -- Using rc_popup_panel to display a panel which waits
 -- "popup" text or number input panels: rc_getinput
 -- A "popup" version of readline: rc_readline
 -- A more complex control panel
 -- Using rc_showtree
 -- rc_scratchpad
 -- -- using the mouse to make a previous scratchpad the current one
 -- -- "saving" the current scratchpad
 -- -- rc_scratch_panel
 -- See also
 -- Additional demonstration packages

-- INTRODUCTION -------------------------------------------------------

In the rest of this file you are shown how to use RCLIB facilities to
create and manipulate various kinds of graphical objects, poster
windows, pop-up menus of various sorts, scrolling text windows,
graphical windows in which you can draw static objects or objects that
are movable by mouse or by program, sliders, buttons, control panels,
etc.

It should take about 30-40 minutes to work through the examples,
trying them out with your own variations.

There are many references to additional help and teach files giving more
information. The main overview file is HELP RCLIB

All the pop-11 source programs are available and can be inspected using
Ved's "showlib" command, after "uses" has put the RCLIB directories on
appropriate search lists e.g.

    uses rclib

then

    ENTER showlib rc_get_coords

The next few sections demonstrate windows that pop up with messages, to
be removed by under program control or by clicking on them. After that
various kinds of pop-up menus (with "oneof" or "someof" buttons) are
demonstrated, and following that programs for creating windows with
various kinds of static and moving pictures. More sophisticated examples
including control panels with sliders, etc. are shown later.

-- Using rc_poster to display persistent messages --------------------

Displaying a message is one of the simplest facilities provided in the
RCLIB package.

You can control font, colour, and whether the text is aligned left, or
right or centrally. The message panel may persist until destroyed by
program, or until you click on it. Alternatively the panel may REQUIRE
you to dismiss it by clicking, and until that happens the procedure
invoking it will be suspended.

*/
;;; Make the RCLIB package available:

uses rclib

;;; Compile the library for creating poster messages
uses rc_poster

;;; Create a list of strings to be displayed in a message panel

vars strings =
    ['This is a panel' 'created by the rc_poster'
     'utility. It remains' 'Until destroyed by'
     'a user procedure or a garbage collection'];

;;; rc_poster displays a panel and returns the window
;;; Format is
;;;rc_poster(x,y, strings, spacing, centre, font, bgcol, fgcol) -> win;

vars posters =
    ;;; a poster at location 300 300, no spacing, centred, etc.
    [% rc_poster(300, 300, strings, 1, true, '9x15', false, false),

    ;;; A panel near top left of screen, with a smaller font, and
    ;;; 10 pixel spacing between lines
    rc_poster(10,30,strings, 10, "right", '6x13bold', 'pink', false),

    ;;; A larger font, with strings not centred
    rc_poster(300, 100, strings, 0, "left", '10x20', 'darkslategrey', 'yellow'),

    ;;; The words "left", "middle","right" can be used for x, and
    ;;; "top", "middle" "bottom" for y, e.g.
    rc_poster("left", "bottom", strings, 0, "left", '10x20', 'darkslategrey', 'yellow'),

    rc_poster("middle", "middle", strings, 0, "left", '10x20', 'darkslategrey', 'yellow'),

    ;;; Negative integers can be used for x and y, to indicate measurements from
    ;;; right and bottom of screen
    ;;; e.g. -5, -5, means in by 5 and 5 from bottom right of screen.

    rc_poster(-5, -5, strings, 0, "left", '10x20', 'darkslategrey', 'yellow'),

    %];

;;; You can use a program command to get rid of all these panels,
;;; which is quicker than using the window manager's close window
;;; button on each of them.

    applist( posters, rc_kill_window_object);

;;; Note: more complex panels can be displayed using rc_control_panel
;;; and rc_popup_panel described below.

/*
-- Using rc_message to display dismissable messages --------------------
*/
;;; Compile the library for creating dismissable messages
uses rclib
uses rc_message

;;; Create a list of strings to be displayed in a message panel
;;; Unlike the previous ones these messages can be dismissed by
;;; clicking anywhere on the panel with the left mouse button.

vars strings2 =
    ['This is a panel' 'created by the rc_message'
     'utility. It will disappear if'
     'you click on the panel with'
     'the left mouse button'];

;;; rc_message displays a panel and returns the window
;;; Format is
;;; rc_message(x,y, strings, spacing, centre, font, bgcol, fgcol) -> win;
;;; As before, the words "left", "middle","right" can be used for x, and
;;; "top", "middle" "bottom" for y, and negative integers can be used
;;; for x and y, to indicate measurements from right and bottom of screen.

;;; We don't need to save the result of rc_message since the panel
;;; can be removed by clicking on it.
rc_message(300, 300, strings2, 0, true, '9x15', false, false)->;

rc_message("right", "top", strings2, 0, true, '9x15', false, false)->;

;;; A panel near top left of screen, with a smaller font, and
;;; 10 pixel spacing between lines
rc_message(10, 30, strings2, 10, true, '6x13bold', 'pink', false)->;

;;; A larger font, with strings aligned left
rc_message(300, 200, strings2, 1, "left", '10x20', 'darkslategrey', 'yellow')->;

;;; At bottom right
rc_message(-1, -1, strings2, 1, true, '10x20', 'blue', 'yellow')->;

/*
For more on rc_message see

        HELP * RC_BUTTONS/rc_message


-- Using rc_message_wait to display synchronous messages --------------

rc_message_wait can be used to create a "popup" message which suspends
the invoking procedure until you acknowledge by clicking on the panel.

It offers the same flexibility regarding specification of window location
as the previous two.

*/

;;; Compile the library

uses rclib
uses rc_message_wait

;;; Create a list of strings to be displayed in a message panel

vars strings3 =
    ['This is a panel created' 'by the rc_message_wait'
     'utility. You cannot proceed'
     'until you click on the panel'
     'with the left mouse button,'
	 'or press a key.'];

rc_message_wait("middle", "middle", strings3, 1, true, '9x15', 'black', 'white');

rc_message_wait(
    100, 30, strings3, 5, "left", '*lucida*-r-*sans-14*', 'red', 'blue');

;;; change the instructions at the top of panel

'---CLICK AFTER READING---' -> rc_message_wait_instruct;

rc_message_wait(
    300, 200, strings3, 2, true, '10x20', 'darkslategrey', 'yellow');

;;; Or suppress the message at the top

false -> rc_message_wait_instruct;

rc_message_wait(
    "right", "top", strings3, 1, true, '10x20', 'darkslategrey', 'yellow');

/*
For more on this see
    HELP * RC_BUTTONS/rc_message_wait
*/

/*

-- Using the scrolling text panel mechanism ---------------------------

The RCLIB package includes a facility to display a collection of strings
in a text panel which can be scrolled up and down or left and right, and
which has a currently selected string at every time. This means that you
can display options which cannot all fit on the screen at the same time.

Details of the mechanism can be found in HELP * RC_SCROLLTEXT. However a
fairly high level example is shown below to illustrate what instances of
the rc_scroll_text class can do. It is invoked by rc_display_strings
in the example below. The first two arguments of rc_display_strings
are the x, and y, coordinates on the screen. As in previous cases
these can be symbolic coordinates or positive or negative integers.

*/

uses rclib
uses rc_scrolltext
uses rc_display_strings

;;; First create a vector of strings (a list will also do):

vars poem =
    {'     THE POEM'
    'Mary had a little lamb'
    'Its fleece was white as snow'
    'and everywhere that Mary went'
    'the lamb was sure to go.'
    'It followed her to school one day'
    'and made the children laugh and play.'
    'Another child had a dog,'
    'and two of them had pet boa constrictors'
    };

;;; We'll display the strings in a scrolling text panel, and allow the
;;; user to select one.
;;; Define a variable to be associated with the string which happens to
;;; be the selected one at any time.

vars the_string;

;;; Now display the strings in a panel which allows you to scroll up and
;;; down or left and right. The panel has top left corner at screen
;;; location 500, 20, and has 6 rows and 20 columns of text.
;;; (for now ignore the unexplained arguments of rc_display_panel).

vars mary_panel =
    rc_display_strings(
        "middle", "top", poem, [], false, false, 6, 20,
            [{font '9x15'} {ident the_string}], 'Mary');

the_string =>

/*
Try the following

o Click on various lines of the poem and print out the value of the
variable "the_string" after clicking. Note how the triangular pointer on
the left moves to the selected line.

    the_string =>

o Move the triangular pointer with the mouse, either by clicking above
or below it or dragging it. Click just above or below its highest and
lowest positions to see what happens. Alternatively drag it to the top
or to the bottom. Watch the effect of the blob on the right, which
shows how many rows of the text has been displayed.

o Put the mouse cursor in the text panel and try moving the text
  - by using the UP, DOWN, LEFT and RIGHT arrow keys.
  - by dragging the mouse pointer up, or down, including going beyond
    the limits of the text panel (and continue moving with the button
    down, e.g. moving it small amounts back and forth).

o Try using the blobs below and to the right of the panel to make the
the visible window of text scroll up or down, left or right. You can
drag the blob or click at a location to which you would like it to move.

o Try re-running the call of rc_display_strings with different numbers
of rows and columns (including 0) and different (fixed width) fonts.
If you specify 0 for the number of columns it automatically makes the
panel wide enough for the longest string and doesn't allow scrolling
left or right. Likewise if you specify 0 for the number of rows.

When done, you can click on "Dismiss All" to remove all the panels
created by rc_display_strings. "Dismiss" merely removes one at a time.

For more information on the arguments for rc_display_strings and other
ways of creating scrolling text panels, see HELP * RC_SCROLLTEXT

*/


/*
-- Using rc_popup_query to present menus ------------------------------

A versatile facility for presenting menus is provided in
the procedure rc_popup_query.

rc_popup_query(x, y, strings, answers, centre, columns,
    buttonW, buttonH, font, bgcol, fgcol, specs, options) -> selection;

It presents two kinds of menus, depending whether the last argument
(options) is true or false. If true, it allows 0 or more options to be
selected before the menu is dismissed, and the options selected are
returned in a list. If options is false you can select only one of the
displayed items, and that one is returned.

Either mode of use permits two main modes of presentation. In one, the
options are numbered and the selection is made by choosing a number. In
the other, the default, the options are not numbered.

You can also specify how many vertical columns should be used for
displaying the options. (If 0 they are all in one horizontal row.)

The x and y coordinates can be integers or symbols, as previously.

*/

;;; Make the library available
uses rclib
uses rc_popup_query

;;; Prepare strings for a question panel, and a list of possible words
;;; as answers:

vars
    query =
        ['What kind of food''would you like to'
         'eat at your next meal?'],

    foods = [fish meat apples pears bananas crab chips olives];

/*
-- -- Single option menus
*/

;;; First some menus requiring only one option to be chosen, using
;;; mouse button 1 (usually left mouse button)

rc_popup_query(
    "right", "middle", query, foods, true, false, 85, 25,
        '9x15', 'pink', 'black', false, false) =>

;;; The same but using four columns and different colours
;;; and location and font, etc. Add null strings to leave more
;;; space after the query

rc_popup_query(
    400,20, query<>[^nullstring ^nullstring], foods, true, 4, 80, 25,
        '8x13bold', 'blue', 'yellow', false, false) =>

;;; Now using two columns and different colours
;;; and location and font, etc., with wider buttons
rc_popup_query(
    400, 20, query, foods, true, 2, 100, 25,
        '10x20', 'blue', 'yellow', false, false) =>

;;; Note that if you click on a selection then move the mouse off
;;; and release it, the selection is undone, and you can choose another.

;;; It is possible to replace the second last argument (false) with a
;;; featurespec data structure to change defaults. See
;;;    HELP * FEATURESPEC

;;; Here is an example. E.g. the button label will be in yellow and
;;; its background brown. This featurespec structure can be used
;;; several times.

vars button_spec =
  {rc_button_font '8x13' rc_button_stringcolour 'yellow'
     rc_button_bordercolour 'red' rc_button_labelground 'brown'
     rc_chosen_background 'darkgreen'};

rc_popup_query(
    -1, 0, query, foods, true, 2, 100, 25,
        '10x20', 'blue', 'yellow', button_spec, false) =>

;;; Note that the answers list can contain words or strings or
;;; numbers

;;; You can make it present numbers to select, after automatically
;;; numbering the options, if you use "numbers" as the fourth
;;; argument. The third argument should then be the list of options.
;;; Use 4 columns, and buttons only 30 pixels wide

rc_popup_query(
    "middle", 20, foods, "numbers", false, 4, 30, 25,
        '10x20', 'blue', 'yellow', button_spec, false) =>

;;; The value returned is the number selected.

/*
-- -- Multiple option menus ("someof" menus)

By making the last argument of rc_popup_query true we turn the above
commands into multiple option commands. You can select several options
or all or none. You can also turn options on and off if you change your
mind before deciding. The list of selected answers is returned when you
click on Accept.

*/

rc_popup_query(
    -100, "top", query, foods, true, false, 80, 25,
        '9x15', 'pink', 'black', false, true) =>

;;; Make your choice either by selecting All, or None, or choosing a
;;; subset and clicking on the "Accept" button

;;; the same but using four columns and different colours
;;; and location and font, etc.
rc_popup_query(
    400, 20, query, foods, true, 4, 80, 25,
        '8x13bold', 'blue', 'yellow', false, true) =>

;;; Now using two columns and different colours
;;; and location and font, etc., with wider buttons
rc_popup_query(
    400,20, query, foods, true, 2, 100, 25,
        '10x20', 'blue', 'yellow', false, true) =>

;;; Now making it present numbered foods, and return a list
;;; of numbers
rc_popup_query(
    "middle", "middle", foods, "numbers", true, 2, 100, 25,
        '10x20', 'blue', 'yellow', false, true) =>

;;; Using the button_spec feature spec again
rc_popup_query(
    400,20, query, foods, true, 2, 100, 25,
        '10x20', 'blue', 'yellow', button_spec, true) =>

/*

-- An alternative popup menu facility: rc_popup_strings ---------------

Sometimes not all the options available can be displayed simultaneously.

The rc_popup_strings procedure allows you to display a list of strings
from which a selection must be made, using a scrolling text mechanism,
demonstrated above, so that the list of strings need not fit on the screen.

It is like rc_display_strings, shown above, except that computation
is suspended until you select a string, by double-clicking on one, or
clicking once and then clicking on "OK", or using the Up/Down arrow
keys to change the selection, and RETURN to finish.

E.g.

*/
uses rclib
uses rc_popup_strings

;;; create a vector (or list) of strings as before
vars poem =
    {'     THE POEM'
    'Mary had a little lamb'
    'Its fleece was white as snow'
    'and everywhere that Mary went'
    'the lamb was sure to go.'
    'It followed her to school one day'
    'and made the children laugh and play.'
    'Another child had a dog,'
    'and two of them had pet boa constrictors'
    };

;;; Instructions
vars instructions =
    ['Select your favourite line' 'Then press Return or double-click'];

;;; Use them to provide a menu:

rc_popup_strings(400, 20, poem, instructions, 8, 0, '9x15') =>

;;; Select using Up/Down arrow keys, and RETURN, or double-click

;;; Use a larger font, but only 6 rows and 20 columns
rc_popup_strings(-50, "top",  poem, [], 6, 20, '10x20') =>

;;; You can use the Left/Right arrow keys to inspect a long string.


/*
-- CREATING GRAPHICAL WINDOWS -----------------------------------------

The above examples presented windows containing a particular message,
or a particular choice to be made. It is also possible to create
panels that "stay up" with various buttons, pictures and other features
on them, including pictures that move under program control.

The above posters, messages, and menu panels all make use of the
rc_window_object facility. A window object is an instance of an
objectclass class, and it contains a graphic window in which you can
draw using commands like those demonstrated or described in

    TEACH RC_GRAPHIC, HELP RC_GRAPHIC, HELP RCLIB

You can also use facilities for creating buttons, moving objects,
sliders, etc. You can easily switch between different windows which use
different scales, different origins, etc. by making one of them the
"current" window object.

*/

;;; The procedure rc_new_window can be used to create different
;;; windows only one of which is "current" for rc_graphic drawing
;;; commands

;;; Make the library available

uses rclib;
uses rc_window_object;

;;; Create two window objects so that we can draw different pictures on
;;; them. There are several formats. One common format is
;;;     rc_new_window_object(x, y, width, height, setframe, title),

;;; The setframe argument may be "true" meaning: use default with the
;;; origin in the middle and y increasing upwards.
;;; Alternatively give a vector of four numbers specifying xorigin,
;;; yorigin, xscale and yscale for rc_graphic procedures.

vars
    win1 = rc_new_window_object(200, 40, 300, 250, true, 'win1'),

    win2 = rc_new_window_object(510, 40, 300, 250, {150 125 1 1}, 'win2');

;;; Make win1 current and draw something on it

win1 -> rc_current_window_object;

;;; Draw on it:

rc_drawline(0, 0, 150, 150);

;;; draw a blob of radius 50 coloured red
rc_draw_blob(0, 50, 50, 'red');
;;; a smaller one with the same colour as current background
rc_draw_blob(0, 50, 30, "background");
;;; a smaller one with the same colour as current foreground
rc_draw_blob(0, 50, 20, false);

;;; Hide the window

rc_hide_window(win1);

;;; Now draw on win2. Note: y increases downwards on win2
win2 -> rc_current_window_object;

rc_drawline(0, 0, 100, 100);
rc_drawline(0, 100, 100, 100);
rc_drawline(100, -100, 100, 100);
rc_circle(0,0,30);

rc_draw_centred_rect(10,-60,160,140,'red',16);
rc_draw_centred_rect(10,-60,80,60,'pink',30);
;;; draw a narrower one using the current background colour
rc_draw_centred_rect(10,-60,80,60,"background",16);
;;; draw a still narrower one using the current foreground colour
rc_draw_centred_rect(10,-60,80,60,false,8);

;;; You can also draw a centred square:
rc_draw_centred_square(-30,40,80,'blue',20);
;;; and a thiner one on it
rc_draw_centred_square(-30,40,80,"background",10);
rc_draw_centred_square(-30,40,80,'green',4);

;;; You can also draw a filled in coloured square, using the format:
;;; rc_draw_coloured_square(x, y, colour, width);

rc_draw_coloured_square(0, 0 , 'green', 60);
rc_draw_coloured_square(0, 0 , 'blue', 40);
rc_draw_coloured_square(0, 0 , "background", 20);

;;; or a blob
rc_draw_blob(50, -100, 60, 'grey70');

;;; Move the window

700, 300, false, false -> rc_window_location(win2);

;;; The updater of rc_window_location takes X, Y, Height, Width, but ignores
;;; any argument which is false.

;;; get back win1 and make it current

rc_show_window(win1);
win1 -> rc_current_window_object;

;;; Draw an oblong and a blob on it
rc_draw_ob(0, 0, 100, 100, 15, 15);
rc_draw_blob(-50, 0, 30, 'blue');

;;; and a green bar

rc_drawline_relative(50, 50, 0, 100, 'green', 8);

;;; and compare the absolute version, which uses pixel coordinates
rc_drawline_absolute(50, 50, 0, 100, 'orange', 8);

;;; Make win1 100 pixels wider using the current background colour
rc_widen_window_by(win1, 100, "background");

;;; add another region at the bottom coloured yellow
rc_lengthen_window_by(win1, 50, 'yellow');

rc_draw_blob(200, 0, 40, 'pink');

;;; Draw a random collection of blobs of random sizes,
;;; colours and locations.

vars colours =
    ['red' 'orange' 'yellow' 'green' 'blue' 'violet'
     'pink' 'brown' 'white' 'black'];

repeat 300 times
    rc_draw_blob(random(850) - 350, random(300) - 150,
        5 + random(100), oneof(colours));
    ;;; slow it down a bit.
    syssleep(1);
endrepeat;

;;; make win2 current and repeat that command

win2 -> rc_current_window_object;

/*
-- Using rc_get_coords to select locations in the window --------------

It is often useful to indicate an object or location on a window by
clicking on it. The simplest way to do this is to use the procedure
rc_get_coords.

rc_get_coords(win_obj, pdr, button)

This method takes an instance of the class rc_window_object, win_obj, a
procedure pdr of two arguments (coordinates), and an integer
representing a mouse button.

When invoked, it warps the mouse pointer to the window and then waits
until a mouse button is clicked in that window.

When that happens, the procedure pdr, is applied to the two integers X,
and Y, and the procedure returns. If pdr is identifn, then the two
integers are simply left on the stack. If it is conspair, then a pair is
created containing the two integers, and so on.
*/

;;;Examples:

uses rclib
uses rc_get_coords  ;;; not strictly necessary: autoloaded as needed

;;; Assume the windows win1, and win2 created above are still
;;; available. If not re-create them.

;;; Get and print out a pair of coordinates in win1
;;; using mouse button 1
rc_get_coords(win1, identfn, 1)=>

;;; Get and print out a pair of coordinates in win2
;;; using mouse button 1
rc_get_coords(win2, identfn, 1)=>

;;; Get and save a pair of coordinates in win1, and another in win2,
;;; using conspair to save the coordinates.

vars
    p1 = rc_get_coords(win1, conspair, 1),
    p2 = rc_get_coords(win2, conspair, 1);

p1,p2=>

For more examples see HELP RC_GET_COORDS


;;; Kill both windows
rc_kill_window_object(win1);
rc_kill_window_object(win2);


/*
-- Using rc_mouse_coords to select locations in a window --------------
*/

This section demonstrates a procedure for collecting multiple locations
in a window.

uses rclib;
uses rc_window_object
uses rc_mousepic

;;; Create a window, with origin in the middle, and y going up
vars win1 = rc_new_window_object("right", "top", 400, 400, true, 'win1');

;;; Make it capable of having mouse sensitive objects on it

rc_mousepic(win1);

;;; To select a number of points, using button 3 to terminate, do the
;;; following, then click at desired locations using mouse button 1 or 2,
;;; and then terminate with 3 (which does not record a point)

rc_mouse_coords(3)=>

;;; E.g. try clicking at the corners and the centre. The result is
;;; a list of pairs, with each pair printing in the format [<x> | <y>],
;;; e.g.:

** [[-184|168] [-119|68] [41|9]]

;;; The user definable procedure rc_conspoint, which defaults to
;;; conspair is used to create each point
;;; The result might be something like this, if you have not redefined
;;; rc_conspoint:

;;;   ** [[-137|123] [-76|40] [-4|-50]]

;;; To make it use a two element vector for each point do
define rc_conspoint(x, y);
    {^x ^y}
enddefine;

;;; Then try again
rc_mouse_coords(3)=>

;;; result something like
;;;    ** [{-188 190} {191 191} {-10 5}]

;;; See
;;;    HELP * RC_MOUSE_COORDS, * RC_APP_MOUSE

/*
-- Using points that are visible and movable --------------------------
*/

;;; Use the same window as before, or create one, using
;;; rc_new_window_object as shown above.
;;; Make rc_point available

uses rclib
uses rc_point

;;; That defines rc_new_live_point which can create individual
;;; points, including points represented by e.g. a circle and
;;; a blob, as described in HELP * RC_POINT

;;; E.g. make two mouse sensitive points
vars
    p1 = rc_new_live_point(0, 0, 6, 'a'),

    p2 =
       rc_new_live_point(0, 50, 20, false,
            [^(rc_draw_blob(%0,0,5,'red'%))]);

p1,p2 =>

;;; The two points can be moved around using mouse button 1 and their
;;; recorded locations will be changed:

p1,p2 =>

;;; get the coordinates of p1 after moving it (the smaller picture):

rc_coords(p1) =>

rc_picx(p1)=>
rc_picy(p1)=>

;;; Move p2 to the origin, then check its coordinates:

rc_move_to(p2, 0, 0, true);

rc_coords(p2) =>

;;; The points can be moved under program control. E.g. make them
;;; move out of phase in circles
vars ang;
for ang from 0 by 5 to 360*4 do
    rc_move_to(p1, 100*cos(ang), 100*sin(ang), true);
    rc_move_to(p2, 80*cos(2*ang), 80*sin(2*ang), true);

    syssleep(1); ;;; increase the number to slow down movement
endfor;

;;; You can make a moving point leave a trail, by replacing true with "trail"

vars ang, rad = 10;
for ang from 0 by 5 to 360*4 do
    rc_move_to(p1, rad*cos(ang), rad*sin(ang), "trail");
    rc_move_to(p2, 80*cos(2*ang), 80*sin(2*ang), true);
    rad + 0.5 -> rad;

    syssleep(1); ;;; increase the number to slow down movement
endfor;


;;; remove the points

rc_kill_point(p1);
rc_kill_point(p2);

rc_start();

/*
-- Using rc_get_mouse_points to select visible locations --------------
*/

;;; rc_get_mouse_points shows the locations of the points, and allows you to
;;; change them with the mouse

uses rclib
uses rc_point;

;;; Use the same window as before, or create one, using
;;; rc_new_window_object as shown above.

;;; We define a procedure that replaces the default label of
;;; a point with one produced using a counter, so that points are labelled
;;; a, b, c, d, etc.

;;; Use a counter to name points
vars point_counter = 0;

;;; A procedure to be run as each point is created
define rc_name_point(p) -> p;
    ;;; p is a newly created and drawn point

    ;;; Undraw p, give it a string, and redraw it.
    rc_undraw_linepic(p);

    consstring(`a` + point_counter, 1) -> rc_point_string(p);
    rc_draw_linepic(p);

    ;;; increment the counter, and restart after 26 (= z)
    (point_counter + 1) mod 26 -> point_counter;
enddefine;

;;; Use the mouse to create points of radius 8 using rc_name_point as
;;; the third argument to rc_get_mouse_points. The second argument is
;;; the point radius, and the final argument the "stop" mouse button.

;;; Create six or more points and stop with button 3
;;; Note that newly created points can be dragged if you don't release
;;; button 1.

vars points = [%rc_get_mouse_points(win1, 8, rc_name_point, 3) %];
points ==>

;;; Now move some of the points with the mouse, and print out the list
;;; again to see how the coordinates have changed
points ==>

;;; The coordinates of the moved points will have changed

;;; Make them do a random walk
vars point;

repeat 500 times
    for point in points do
        rc_move_by(point, 3-random(5), 3-random(5), true);
    endfor;
    syssleep(3);    ;;; increase the number to slow things down
endrepeat;

;;; You may be able to select one and move it with the mouse while
;;; that is running. If it is too difficult, interrupt (CTRL-C) then
;;; replace the argument to syssleep with a larger number to slow things down.
;;; e.g. syssleep(10);

;;; Get rid of the points from the window

applist(points, rc_kill_point);

;;; See also the following
    HELP * RC_POINT


;;; Get rid of the window if necessary
rc_kill_window_object(win1);

/*
-- Drawing movable pictures in a graphic window -----------------------
*/
;;; The rclib package makes use of a number of classes and mixins with
;;; associated methods.

;;; LIB * RC_LINEPIC defines a variety of mixins for pictures, drawable,
;;; movable, rotatable
;;; LIB * RC_MOUSEPIC and LIB * RC_WINDOW_OBJECT make it easy to
;;; create a mouse-sensitive window, in which picture objects of various
;;; kinds can be created, including objects that can be selected and moved.

;;; Picture objects which are instances of the mixin rc_linepic
;;; are defined by a list of instructions for drawing lines, circles, blobs etc.
;;; in an rc_graphic (relative coordinates) reference frame local to the
;;; picture object, along with a list of instructions for printing
;;; strings in the picture.

;;; When such an object is moved the old picture is obliterated (using
;;; the XOR or EQUIV graphical drawing mode) and then redrawn in the
;;; new location. The gory details are hidden inside methods like
;;; rc_move_to, rc_move_by and rotation methods.

uses rclib;
uses rc_linepic;
uses rc_window_object;
uses rc_mousepic;
uses rc_buttons;

;;; Create a window, with origin in the middle, and y going up
;;; which is also able to include buttons
vars
    win1 = rc_new_window_object(
                500, 40, 400, 400, true, newrc_button_window, 'win1');

;;; Use the predefined mixins
;;;     rc_keysensitive rc_selectable rc_linepic_movable
;;; to define a new class of movable draggable objects: dragpic

define :class dragpic;
    ;;; this class inherits from three different "mixins"
    is rc_keysensitive rc_selectable rc_linepic_movable;

    ;;; default names for instances are dragpic1, dragpic2, etc.
    slot pic_name = gensym("dragpic");
enddefine;

define :method print_instance(p:dragpic);
    ;;; define a print method to simplify printing of instances
    printf('<dragpic %P %P %P>', [%pic_name(p), rc_coords(p) %])
enddefine;


;;; Create an instance of the class dragpic, containing
;;; a blue square a blue rectangle and red and green text strings.

define :instance drag1:dragpic;
    pic_name = "drag1";

    ;;; location of the picture's reference frame origin
    rc_picx = 100;
    rc_picy = 50;

    ;;; define the object's graphical appearance: a square and a
    ;;; rectangle, overlapping
    rc_pic_lines =
        [WIDTH 2 COLOUR 'blue'
            [SQUARE {-40 40 80}]
            [CLOSED {-45 20} {45 20} {45 -20} {-45 -20}]
        ];

    ;;; and two strings
    rc_pic_strings =
        [FONT '9x15bold'
            [COLOUR 'red' {-22 -5 'drag1'}]
            [COLOUR 'green' {-22 -35 'hello'}]];
enddefine;

;;; Compile that definition
;;; Now draw drag1 on win1

win1 -> rc_current_window_object;
rc_draw_linepic(drag1);

;;; See how it prints out:

drag1=>

/*
If you find that the picture drag1 does not have the colours given in
its specification (blue, red, and green), this may be because you are
using a terminal with an unusual way of representing colours.

For more information on difficulties with colours, and the reasons,
see HELP RCLIB_PROBLEMS.
*/

;;; You cannot yet drag the picture (try it), though you can move it
;;; under program control

repeat 20 times rc_move_by(drag1, -5, 5, true); syssleep(1); endrepeat;
drag1 =>

;;; Draw a blob then move it down over the blob
rc_draw_blob(0,0,100,'grey5');

repeat 60 times rc_move_by(drag1, 0, -5, true);syssleep(1) endrepeat;

;;; and up over the blob

repeat 60 times rc_move_by(drag1, 0, 5, true);syssleep(1) endrepeat;

drag1 =>

/*
Try the same thing with blobs of different colours (HELP XCOLOURS). The
appearance of drag1 changes as it moves over non-white objects. This is
due to the drawing method used for movable objects of arbitrary shapes.
We can make rectangular movable objects (e.g. coloured panels), which do
not have this property, as shown below. Or we can use the facilities
defined in LIB rc_opaque_mover, also illustrated below, when it is known
that the coloured objects will move over a uniform background.

*/

;;; If the "true" argument in rc_move_to or rc_move_by is replaced by
;;; false, no motion is shown in the picture though the coordinates change.
;;; If it is replaced by "trail" the picture leaves a (messy) trail
;;; while moving.

repeat 30 times
    rc_move_by(drag1, 0, -5, "trail")
endrepeat;

;;; Undraw the picture object
rc_undraw_linepic(drag1);

;;; clear the current window
rc_start();

;;; redraw the picture
rc_draw_linepic(drag1);
rc_move_to(drag1, 0, 0, true);

;;; (If you forgot to use rc_undraw_linepic before rc_start you will have
;;; a spurious unmovable copy of drag1 at its old location.)

/*
-- Making the the object drag1 draggable with the mouse ---------------
*/

;;; Now make the window mouse button sensitive (it should be
;;; already, but just in case):

rc_mousepic(win1, [button motion ]);

;;; and tell the window win1 about drag1

rc_add_pic_to_window(drag1, win1, true);

;;; Now you should be able to drag the picture around, using the
;;; (small) sensitive area near the middle of the picture. See how
;; the printed information changes after each move:

drag1 =>
rc_coords(drag1)=>

;;; You can enlarge the mouse sensitive area for drag1, making it easier
;;; to drag. The area is by default defined by a vector of numbers
;;; specifying a rectangle. (But it could be a procedure.)

;;; Print the default mouse limit: a 20x20 square around the picture
;;; centre, defined by a vector giving coordinates of corners of the
;;; square, relative to the object's origin:

rc_mouse_limit(drag1) =>
** {-10 -10 10 10}

;;; increase the sensitive area to a 60x60 square
{-30 -30 30 30} -> rc_mouse_limit(drag1);

;;; Now it should be easier to drag. Try it.

/*
Note, after you have selected drag1 you can control the picture more
easily by holding down the shift key and making the picture jump to
any location in the picture pointed to with the left mouse button.
If you click in a blank area without the shift key down you will
deselect the object. For more on this see

        TEACH * RC_LINEPIC/shift, * RC_MOUSEPIC

Exercise: make another instance of the class dragpic shown as a red
square of side 60, drawn with lines of thickness 5, with the printed
label 'red' shown in blue.

Then draw it, and make it draggable. Drag it around for a while, seeing
what happens if it passes across drag1, or vice versa.

Then remove it using the rc_undraw_linepic command, shown above.

*/

/*
-- Adding buttons to control a movable object -------------------------

*/

;;; Move the drag1 picture to bottom right of the window
;;; Add buttons to move the picture up and down

uses rclib
uses rc_buttons

;;; Create a button of type "action" labelled "UP" to move the picture
;;; up. Its width is 60 pixels, its height 25. It is located on the left
;;; below the centre (with top left corner at -200, 0).

vars button1 =
    create_rc_button(
        -200,0,60,25,
            ['UP' [POP11 rc_move_by(drag1,0,5,true)]], "action", false);

;;; Create a button labelled "DOWN" to move the picture down, located
;;; below the Up button, at (-200, -30).

vars button2 =
    create_rc_button(
        -200,-30,60,25,
            ['DOWN' [POP11 rc_move_by(drag1,0,-5,true)]], "action", false);

/*
Try clicking on the buttons to move the drag1 object up or down. Note the
change of appearance as you press and release the mouse button, and also
what happens if you move the mouse out of the button before releasing it.
(Buttons can have various visible appearances: this demonstration uses
the default. There are also alternative ways of associating an action with
a button. See HELP RC_BUTTONS, and HELP RC_CONTROL_PANEL.)
*/

;;; Try creating two buttons labelled 'LEFT' and 'RIGHT' to make drag1
;;; move horizontally.

/*
-- Making a movable panel inside another panel ------------------------

The odd changes of colour as a movable object moves over a coloured
portion of the window are due to the simplified drawing method used
for objects of arbitrary shapes, as described in HELP RCLIB_PROBLEMS.

(It uses either the GXxor or the GXequiv drawing mode, described in
REF XpwPixmap/GXcopy)

Alternatively the autoloadable procedure rc_coloured_panel can be used
to make a panel that moves without having its colours mangled.

The format is as follows:

    rc_coloured_panel(
        x, y, width, height, colour, contents, container) -> panel

where contents is a (possibly empty) list giving information about
contents of the panel (using the field specifier formats for
rc_control_panel, illustrated in more detail below. Container can be
false to create a new coloured window, or an existing panel to contain
the new panel.

We'll use the window win1 created previously as container. Recreate it
if necessary, using rc_new_window_object.
*/

;;; Move drag1 then create a red blob in win1
rc_move_to(drag1, 100, 100, true);

rc_draw_blob(0, 0, 40, 'red');

;;; Create a yellow 40x40 panel at the left of win1

uses rc_coloured_panel

vars yellow = rc_coloured_panel(-200, 100, 40, 40, 'yellow', [], win1);

;;; The yellow panel can be moved, without changing colour as it passes
;;; over other pictures (compare drag1 which changes colour).

rc_move_to(yellow, 0,0, true);
rc_move_to(yellow, 0,-60, true);

repeat 80 times rc_move_by(yellow, 0, 2, true); syssleep(1);endrepeat;
repeat 80 times rc_move_by(yellow, 0, -2, true); syssleep(1);endrepeat;

;;; Try dragging drag1 past the yellow panel. Notice that bits of drag1
;;; disappear under the yellow panel. The moving panel keeps its proper
;;; unlike drag1 when it moved over a coloured object.

;;; Create a smaller green one at the middle of the right edge

vars green =
    rc_coloured_panel("right", "middle", 20, 20, 'green', [], win1);

;;; Try giving some commands to move it around.

;;; The yellow panel can be made draggable by its centre, using mouse
;;; button 1.

rc_make_draggable(yellow, 1, 20, 20);
;;; Now try dragging it.

;;; And make mouse button 3 drag it by the top left corner
rc_make_draggable(yellow, 3, 0, 0);
;;; Now try dragging it with button 3

;;; Try making the green panel draggable by its centre using mouse
;;; button 1.

;;; See what happens if you try making the green and yellow panels move
;;; past each other: the one created last is always "on top".

;;; Subpanels can contain text and drawings. The location can be
;;; specified symbolically instead of numerically.
;;; Create a blue 60x60 panel

vars blue =
    rc_coloured_panel("middle", "middle", 60, 60, 'blue', [], win1);

;;; move it

-100, 100 -> rc_coords(blue);

;;; draw in it
blue -> rc_current_window_object
rc_draw_blob(30,40,20,'pink')

;;; print in it
rc_print_at(5,20,'blue');

;;; make win1 current again
win1 -> rc_current_window_object

;;; make the blue panel draggable at its centre:
rc_make_draggable(blue, 1, 30, 30);

;;; Drag the blue, yellow and green panels past each other.
;;; More recently created sub-panels always obscure older sub-panels
;;; when they overlap.

;;; Kill the window

rc_kill_window_object(win1);

/*
-- Using "opaque" movable objects -------------------------------------

The movable panels illustrated in the previous section are opaque in
that they cover up coloured portions of the backround and the colours
are restored when the small panel is moved.

If you know that a picture object is going to move over a uniform
coloured background without any other objects being temporarily
obscured, you can use an "opaque" movable object class, whose instances
always have the correct colour and always restore the background to the
same colour when they move. Here's a modified version of the drag1
example above, to illustrate this.
*/

uses rclib;
uses rc_linepic;
uses rc_window_object;
uses rc_mousepic;
uses rc_opaque_mover;

;;; Create a window, with origin in the middle, and y going up
vars
    win1 = rc_new_window_object( "right", "top", 400, 400, true, 'win1');

;;; give it a pink background colour

'pink' -> rc_background(rc_window);

;;; define an opaque movable draggable class

define :class opaque;
    is rc_selectable rc_opaque_movable;
enddefine;

;;; create an instance:
define :instance op1:opaque;
    rc_picx = 100;
    rc_picy = 50;

    rc_pic_lines =
        [WIDTH 3 COLOUR 'blue'
            [SQUARE {-40 40 80}]
            [CLOSED {-45 20} {45 20} {45 -20} {-45 -20}]
        ];

    rc_pic_strings =
        [FONT '9x15bold'
            [COLOUR 'red' {-22 -5 'op1'}]
            [COLOUR 'yellow' {-25 -35 'opaque'}]];

	rc_mouse_limit = 50;
enddefine;

;;; draw it and add to window
rc_draw_linepic(op1);
rc_add_pic_to_window(op1, win1, true);

;;; It should now be draggable using the mouse. It should have
;;; the correct colour which is preserved as it moves.

;;; Try changing the background, after undrawing the object

rc_undraw_linepic(op1);

'khaki' -> rc_background(rc_window);
;;; re-draw it
rc_draw_linepic(op1);

;;; It respects the new background colour. However if it moves over
;;; a blob of a different colour it will leave a trail which is the
;;; colour of the background

rc_move_to(op1, 150, 150, true);

rc_draw_blob(0,0,60,'pink');

;;; Now try dragging op1 over the blob. It can be used to
;;; obliterate the blob!

;;; Kill the window

rc_kill_window_object(win1);

For more information see
	TEACH rc_opaque_mover



/*
-- Making sliders: horizontal, vertical, diagonal ---------------------

RCLIB includes a library LIB * RC_SLIDER which is based on the mixin
rc_constrained_mover. Sliders can take many forms, though the default
is a straight bar, in any orientation, with a movable "blob", a numerical
panel into which you can type a desired value, and textual labels
associated with the slider. The defaults provide a standard format, but
you can easily override the defaults.
*/

uses rclib
uses rc_slider

;;; create a window object to contain sliders
vars
    win1 = rc_new_window_object( 550, 40, 350, 300, true, 'win1');


;;; This is the basic format for creating sliders
;;; rc_slider(x1, y1, x2, y2, range, radius,
;;;         linecol, slidercol, strings) -> slider;

;;; Additional formats described in HELP RC_SLIDER allow the
;;; standard appearance of a slider to be modified or allow the
;;; slider to be associated with an identifier.

;;; The range can be a number or a pair of numbers or a vector

;;; A horizontal slider, range 80, blob radius 6, 'red' on a 'grey80'
;;; background. The default value is 0.00

vars ss1 = rc_slider(0, 0, 100, 0, 80, 8, 'grey80', 'red', false);

;;; Move the slider blob and see how the slider prints out
ss1 =>
ss1.rc_line_length =>
ss1.rc_slider_value =>

;;; You can also move the slider by clicking with mouse button 1 on
;;; the bar.  Try it.

;;; Move it under program control
vars x;
for x from 0 to 80 do x -> rc_slider_value(ss1); syssleep(1); endfor;

You can also change the value by typing a number in the number
input panel showing the slider's value. See what happens if you
type a value beyond the slider's range. (Typing a number in the
panel requires the mouse cursor to be in the number panel.)
Use DEL, Backspace, the left/right arrow keys. When finished typing the
number click on the panel or press RETURN (see HELP RC_TEXT_INPUT).

Note the different appearance when the number panel is in "edit" mode
after you type something.

;;; Create a vertical slider associated with a variable

vars slidertest;

vars ss2 =
    rc_slider(-150, 100, -150, -100, 80, 8, 'grey80', 'red', false, "slidertest");

;;; keep moving the slider and testing the effect on the variable
slidertest=>

;;; Make a labelled diagonal slider, range -500 to 500, starting at 10
;;; Give the bar a red frame and blob and a white background. The
;;; red frame has thickness 3 pixels.
;;; Make it round values

vars ss3 =
    rc_slider(-115, 85, 85, -115, {-500 500 10}, 6,
        'white', 'blue', [[{5 5 'MIN'}] [{5 10 'MAX'}]],
            {rc_slider_barframe %conspair('red', 3)%
                rc_constrain_contents ^round});

;;; Move the blob, e.g. by clicking on the bar and check the slider value

rc_slider_value(ss3) =>

;;; Move it under program control
500 -> rc_slider_value(ss3);
-500 -> rc_slider_value(ss3);

;;; Observe the automatic rounding
20.55 -> rc_slider_value(ss3);
rc_slider_value(ss2)=>
245.345 -> rc_slider_value(ss3);
rc_slider_value(ss3)=>

;;; The diagonal slider can also be moved by clicking on the slider bar,
;;; Though the sensitive area is only approximately rectangular and
;;; may extend a bit beyond the frame in some places.

;;; Create a horizontal slider, range 0 to 1, with square "blob"
;;; First load the library for square blobs

uses rc_square_slider

;;; Associate the slider with a pre-initialised identifier
vars squareval = 0.7;

vars ss4 =
    rc_square_slider(-60, 90, 95, 90, 1, 8, 'white', 'red',
            [[{-5 15 'lo'}] [{-10 15 'hi'}]],
                {rc_slider_barframe %conspair('black',2)%},
                ident squareval);

rc_slider_value(ss4) =>
squareval =>

0.5 -> rc_slider_value(ss4);
rc_slider_value(ss4) =>

;;; You can also check how changing the slider value alters the
;;; value of the identifier
squareval =>

;;; clear the picture if it is too cluttered
rc_start();

;;; Initialise new slider via the range vector argument, and
;;; also constrain it to move in steps of 0.05. This uses the
;;; four element vector {min max startval step}, e.g.
;;;                     {0   1   0.7      0.05}


;;; use a new variable for the value
vars ss5_val;

vars ss5 =
    rc_square_slider(-115, 30, 50, -135, {0 1 0.7 0.05}, 8, 'white', 'red',
            [[{-5 15 'lo'}] [{-10 15 'hi'}]],
                {rc_slider_barframe %conspair('black',2)%},
                ident ss5_val);

ss5_val=>
rc_slider_value(ss5) =>

;;; See how the values in the panel change only by 0.05, as you attempt
;;; to slide the blob smoothly.


;;; Now with a circular blob (Note: blob colours may be surprising unless
;;; bar colour is 'white'. See HELP RCLIB_PROBLEMS for explanation:
;;; This follows from the method used to draw coloured movable objects)

vars ss6 =
    rc_slider(-80, -35, 95, -35, 1, 8, 'grey91', 'blue',
            [[{-5 8 'lo'}] [{-10 8 'hi'}]],
              {rc_slider_barwidth 20});

/*
-- Sliders with panels with 'proper' colours

Provided that you are happy for your slider to have a movable portion
that is always rectangular, with sides vertical and horizontal you can
use the procedure rc_panel_slider instead of rc_slider, to make sliders
whose panels always have the colour specified.

Clear the picture and repeat some of the previous commands with rc_panel
slider.

*/
;;; kill the previous window and start a new one
rc_kill_window_object(win1);

vars
    win1 = rc_new_window_object( 500, 40, 300, 300, true, 'win1');


vars ps1 = rc_panel_slider(-10, 0, 90, 0, 80, 8, 'grey80', 'red', false);

;;; you should be able to move the red square with the mouse, as previously

;;; and by program:

vars x;
for x from 0 to 80 do x -> rc_slider_value(ps1); syssleep(1); endfor;


;;; a diagonal slider with a frame round the bar (alas we can't rotate
;;; this sort of panel 45 degrees. But perhaps the appearance is still
tolerable?

vars ps2 =
    rc_panel_slider(-115, 115, 85, -115, {-500 500 10}, 6,
        'white', 'blue', [[{5 5 'MIN'}] [{5 10 'MAX'}]],
            {rc_slider_barframe %conspair('red', 3)%
                rc_constrain_contents ^round});

;;; A panel slider with an associated variable
vars ps3_val;

vars ps3 =
    rc_panel_slider(-80, 110, 95, 110, {0 1 0.7 0.05}, 8, 'white', 'red',
            [[{-5 15 'lo'}] [{-10 15 'hi'}]],
                {rc_slider_barframe %conspair('black',2)%},
                ident ps3_val);
ps3_val =>

/*
For more information on sliders, text and number input panels, etc.
see HELP * RC_SLIDER, HELP * RC_TEXT_INPUT

For a more complex set of examples, including sliders linked to
action buttons see
    LIB * RC_POLYPANEL

*/

;;; try adding some more sliders, then
;;; kill the window
rc_kill_window_object(win1);

/*

-- Linking a picture into two windows: rc_linked_pic ------------------

It is sometimes useful to show the same thing in two or more different
windows, e.g. because they use different scales, or show different
terrain features.
*/

uses rclib
uses rc_linked_pic

;;; Create two rc_window_objects, to install pictures in. One has the
;;; standard coordinate frame with y going up, and the other has y
;;; going down.
vars
    win1 =
        rc_new_window_object(20, 5, 250, 250, true, 'win1'),
    win2 =
        rc_new_window_object(300, 5, 250, 250, {125 125 1 1}, 'win2');

vars
    windows = [^win1 ^win2];

;;; define a subclass of rc_linked_pic and make some instances


define :class rc_linked;
    ;;; for movable linked pictures
    is rc_linked_pic;

    slot rc_pic_lines = [WIDTH 2 CIRCLE {0 0 20}];
    slot rc_mouse_limit = 10;
enddefine;

;;; create two pictures

vars
    p1 =
    instance rc_linked;
        rc_picx = -20;
        rc_picy = -20;
        ;;; a string to left of centre
        rc_pic_strings = [{-4 0 'p1'}];
    endinstance,

    p2 =
    instance rc_linked;
        rc_picx = 20;
        rc_picy = 20;
        ;;; a string to left of centre
        rc_pic_strings = [{-4 0 'p2'}];
    endinstance;

;;; Add p1 to each of the windows. It will appear in all the windows,
;;; appropriately scaled, etc.
rc_add_containers(p1, windows);

;;; now move p1 around in either window. note that because rc_yscale
;;; is positive in one window and negative in the other, the movements
;;; are different, though linked.

;;; We can add p2 to win1
rc_add_container(p2, win1);

;;; and add it to win2 stretched sideways, and coloured blue
rc_add_container(p2, [^win2 XSCALE 2 COLOUR 'blue']);


;;; p2 can also be selected and moved in either window. However,
;;; its mouse sensitive area is still restricted to the original radius
;;; even when it appears stretched.

;;; Put p1 at top right of win1 and p2 and bottom left, then
win1 -> rc_current_window_object;
repeat 40 times
    rc_move_by(p1, -3, -3, true);
    rc_move_by(p2, 3, 3, true);
    syssleep(1);
endrepeat;

rc_move_to(p1, -50, 50, true);
rc_move_to(p2, 50, -50, true);

;;; Remove the windows

applist(windows, rc_kill_window_object);

/*
For more on linked pictures see HELP * RC_LINKED_PIC
*/


-- Creating a rotating object -----------------------------------------

uses rclib
uses rc_linepic
uses rc_mousepic
uses rc_buttons

;;; create a window
vars
    win1 = rc_new_window_object(
              500, 40, 400, 400, true, newrc_button_window, 'win1');

;;; A class, based on the rc_rotatable mixin
define :class rc_rotator; is rc_rotatable;
    slot rc_axis = 0;
    slot rc_picname;
enddefine;


;;; Make a new printing procedure for the class, showing the axis
;;; as well as coordinates

define :method print_instance(p:rc_rotator);
    printf('<rotator %P %P %P axis:%P>',
        [%rc_picname(p), rc_coords(p), rc_axis(p) %])
enddefine;

;;; Make an object in that class consisting of a line with a circle near
;;; each end.
define :instance rp1:rc_rotator;
    rc_picname = "rp1";
    rc_picx = -50;
    rc_picy = 100;
    rc_pic_lines =
        [WIDTH 3
            ;;; a blue line
            [COLOUR 'blue' {0 0} {30 30}]
            ;;; two pink circles
            [COLOUR 'pink' CIRCLE {25 25 10} {3 3 5}]];
enddefine;

;;; draw it
rc_draw_linepic(rp1);

rp1 =>

;;; move and rotate it
repeat 90 times
    rc_move_by(rp1, 0, -1, true);
    rc_turn_by(rp1, 2, true);
    ;;; remove next command to make it go faster
    syssleep(1);
endrepeat;

rp1 =>

;;; and back again
repeat 90 times
    rc_move_by(rp1, 0, 1, true);
    rc_turn_by(rp1, -2, true);
    syssleep(1);
endrepeat;

rp1 =>
;;; Make it rotate on its own, driven by a timer
;;; but not if in rc_event_handler as then coordinates may be
;;; wrong, e.g. if dragging is going on.

vars count_rotate = 0;

define time_rotate();

    dlocal rc_current_window_object = win1;

    unless rc_in_event_handler then
        ;;; draw it
        rc_turn_by(rp1, 2, true);
    endunless;
    count_rotate + 1 -> count_rotate;
    ;;; make the rotation contine up to 180 times
    if count_rotate < 180 then
        ;;; continue half a second later
        5e5 -> sys_timer(time_rotate)
    endif;
enddefine;

;;; start off the rotation
0-> count_rotate; time_rotate();

;;; It should continue rotating on its own, in parallel with
;;; everything else going on.

;;; Exercise:
;;; Try adding a button to start the rotation and another to
;;; stop it (by assigning a large number to the counter)

300 -> count_rotate;

;;; remove the window if necessary
rc_kill_window_object(win1);

-- More types of buttons ----------------------------------------------

uses rclib

uses rc_buttons

-- -- Counter buttons and toggle buttons

;;; It is possible to have buttons that increment and decrement
;;; numerical variables, while displaying the value, and buttons that
;;; display and toggle the value of a boolean variable.

;;; create a window
vars
    buttonwin =
      rc_new_window_object(
         500, 40, 150*2, 30*3, {1 1 1 1}, newrc_button_window,
            'buttonwin');

;;; create an amount by which to change popmemlim

vars popmemliminc = 10000;

;;; create a list of button specifications (for more examples of
;;; types of button specifications see HELP RC_BUTTONS)
;;; Note for the counter and toggle buttons it is possible
;;; to use idents instead of the words used here.

vars buttonlist =
    [
        ;;; Toggle popgctrace
        {toggle 'Gctrace' popgctrace}
        ;;; toggle the value of vedbreak
        {toggle 'Break' vedbreak}
        ;;; increment or decrement pop_pr_places
        {counter Dpoints pop_pr_places 1}
        ;;; Action button to print pi
        ['Show PI' [POP11 pi => ]]
        {counter 'Memlim' popmemlim popmemliminc}
        ;;; a blob button to destroy the window
        {blob 'KILL' rc_kill_panel}
    ];

;;;; Now create the buttons in two columns, each 119 pixels
;;; wide and 29 pixels high, separated by 1 pixel, starting
;;; top left in the window. The default type is an "action"
;;; button. Action buttons and blob buttons have different
;;; borders from display (toggle and counter) buttons

vars buttons=
  create_button_columns(0,0,149,29,1,2,buttonlist, "action", false);

;;; Note how popgctrace changes its value as you click on the Gctrace
;;; button
popgctrace =>

;;; You can increment or decrement the numerical variables using
;;; mouse button 1 or 3 on the appropriate counter buttons.
;;; Change the value of pop_pr_places up or down by clicking on
;;; the Dpoints button then see how that alters the effect of
;;; clicking on the button to print out PI.

;;; You can change the appearance of a toggle or counter button.

;;; e.g.
{' [+]' ' [-]'} -> rc_toggle_labels(buttons(1));
rc_draw_linepic(buttons(1));
{' [Yes]' ' [No]'} -> rc_toggle_labels(buttons(2));
rc_draw_linepic(buttons(2));

{'-|' '|+'} -> rc_counter_brackets(buttons(3));
rc_draw_linepic(buttons(3));

It is also possible to have "invisible" action buttons, as explained
in HELP RC_BUTTONS

/*
-- -- Radio buttons and someof buttons: an example.
*/

;;; Load the library
uses rc_button_utils

;;; Use this variable to record previous message put up, in case it
;;; needs to be removed
vars last_message = false;

define show_selected(button);
    ;;; When a radio button has been selected with a colour name, put
    ;;; up a message using the colour as the background.
    lvars
        label = rc_button_label(button),

        strings = ['The selected item is now' ^label '' 'Thank you'];

    if last_message then
        rc_kill_window_object(last_message);
        false -> last_message;
    endif;

    rc_message(300,300, strings, 0, true, '10x20', label, 'black')
        -> last_message;
enddefine;

define selecting_someof(button);
    ;;; Report selection of a someof button
    [selection ^(rc_button_label(button)) ] =>
enddefine;

define deselecting_someof(button);
    ;;; Report deselection of a someof button
    [Deselecting ^(rc_button_label(button)) ] =>
enddefine;


vars
    radio_labels =
        ['yellow' 'pink' 'orange' 'gold' 'ivory' 'grey' 'green' 'blue'];

;;; Create a window large enough to hold the two arrays of buttons and a
;;; cancel button, with origin in top left corner and y axis going down.

vars panel =
    rc_new_window_object(
        650, 20,72*4, 26*7, {0 0 1 1}, newrc_button_window, 'panel');

;;; Now create the two lots of buttons, using featurespecs to set the
;;; actions and vary colours.

;;; It would be possible to use create_button_columns, but two utilities
;;; specifically for radio buttons and someof buttons are provided
;;; in LIB * RC_BUTTON_UTILS
vars
    radio_buttons =
        create_radio_button_columns(
            0,0,70,25,3,4, 'Choose your colour (only one)',
                radio_labels, {rc_radio_select_action ^show_selected }),

    someof_buttons =
        create_someof_button_columns(
            0,75,70,25,3,4, 'Select some colours (any combination)',
              radio_labels,
                {rc_radio_select_action ^selecting_someof
                    rc_radio_deselect_action ^deselecting_someof
                    rc_button_bordercolour 'blue' }),

    killbutton =
    ;;; add a cancel button
    create_rc_button(
       0, 145, 175, 35, ['Cancel' rc_kill_panel], "blob", false);



;;; Check the contents after choosing options

rc_options_chosen(radio_buttons) =>
rc_options_chosen(someof_buttons) =>

;;; if necessary
rc_kill_window_object(panel);

NOTE: A more complex version of this example can be found in
	HELP RC_BUTTONS

After experimenting with the other buttons, use the Cancel button
to get rid of the window.

More variations can be found in HELP * RC_BUTTONS
TEACH * RC_CONSTRAINED_PANEL
TEACH * POPCONTROL




/*
-- USING RC_CONTROL_PANEL ---------------------------------------------
-- A simple control panel ---------------------------------------------

rc_control_panel is an extremely versatile tool for building various
kinds of panels and displays. The main features are that it formats
items automatically, it allows one panel to occur inside another, and it
allows graphics objects (including moving pictures) to be included
alongside buttons, sliders and the like.

The format for use is

    rc_control_panel(x, y, fields, title) -> panel;
or
    rc_control_panel(x, y, fields, title, container) -> panel;

The second case is used when creating a new panel inside an old one.

As before, the words "left", "middle","right" can be used for x, and
"top", "middle" "bottom" for y, and negative integers can be used
for x and y, to indicate measurements from right and bottom of screen.

The important point is that fields is a list of descriptions of fields
to be included in the panel. A convenient language for specifying the
fields is described in detail in HELP * RC_CONTROL_PANEL, and a subset
is illustrated below.

*/

uses rclib
uses rc_control_panel
uses rc_scratchpad

;;; Create a set of fields, of type TEXT, RADIO, SOMEOF, ACTIONS,
;;; SLIDER, GRAPHIC, with various settings specified, but basically
;;; using defaults defined in LIB * RC_CONTROL_PANEL

;;; The sliders here don't do anything. The examples in
;;; LIB * RC_POLYPANEL show sliders whose values are used.

;;; Note that a colon occurs after each field type name, possibly
;;; preceded by some feature specifiers to override defaults.
;;; In a TEACH file, a colon must not be the first non-space character in
;;; the line, otherwise it will be ignored.

;;; two variables to be associated with sliders
vars S1, S2;

;;; two variables corresponding to RADIO and SOMEOF panels

vars
    the_colour = undef, all_moods = undef;

vars panel_fields =
    [
        ;;; Try uncommenting and changing some of these properties
        ;;; {offset 400}
        ;;; try different origins
        ;;; {xorigin 5}{yorigin -300}
        ;;; Try different scale combinations. It should make no difference
        ;;; to the "controls"
        ;;; {xscale 1}
        ;;; {yscale -1}
        ;;; General defaults for the panel
        {bg 'grey75'} ;;; try other colours, e.g. 'pink', 'ivory'

        {fg 'grey20'} ;;; try {fg 'red'}

        ;;; Try uncommenting these to to change minimal size
        ;;; {width 500}
        ;;; {height 900}

        ;;; A text field with two strings, offset 5 pixels left and
        ;;; right. Leave a gap above of 25 for a piece of graphics
        ;;; in the second GRAPHIC field below
        [TEXT {offset 15} {margin 0}
            {gap 25} :
            'Demonstration of rc_control_panel'
        ]

        ;;; some action buttons in two columns
        [ACTIONS {cols 2}
            {bg 'blue'}
            {gap 0} {margin 4}
            {width 100} {height 28}:
            'help rclib'
            ['help panel' 'help rc_control_panel']
            ['Who\'s in?' 'sh who']
            {blob 'KILL Panel' rc_kill_panel}
        ]

        ;;; Another text field, with small print, left aligned
        [TEXT {font '6x13bold'}
            ;;;{bg 'blue'}
            {fg 'yellow'}
            {gap 1}
            {align left}:
        'This is a small display' 'showing uncentred text'
        '' 'Not very readable!']

        ;;; A graphic field. You must specify the height required.
        ;;; width defaults to the width of the panel
        [GRAPHIC
            {height 40}
            {bg 'ivory'}
            {gap 0}
            ;;; try with and without the next line commented out
            ;;; {width 500}

            ;;; You can either specify the origin of the field
            ;;; relative to its top left corner, or just ask for the
            ;;; origin to be central
            {align centre}  ;;; the default is "centre"
            ;;; Instead of centre, try left, right, panel
            ;;; These can be used to displace the origin
            ;;; {xorigin -150} {yorigin -100}

            ;;; The xscale and yscale each default to 1
            {xscale 1}
            ;;; if you want y to increase upwards
            {yscale -1} :
            ;;; graphic instructions in pop11 format
            [POP11
                ;;; A circle at the origin and two blobs, above left
                ;;; and below right (if yscale = -1)
                rc_circle(0, 0, 5);
                rc_draw_bar(-150,15,6,300,'brown');
                rc_draw_bar(-150,-15,6,300,'brown');
                rc_draw_blob(-25, 5, 15, 'orange');
                rc_draw_blob(30, -5, 15, 'blue');
                rc_draw_blob(0, 15, 3, 'red');
                rc_draw_blob(0, -15, 3, 'red');
                ]
        ]

        [GRAPHIC
            ;;; Another graphic field, this time with origin at top
            ;;; left of the panel
            {align panel}
            ;;; could do this instead
            ;;; {xorigin 0}
            ;;; {yorigin 20}
            {gap 0}
            {height 0} :

            [POP11 rc_drawline(0,0, 400, 25);
                ]
        ]

        [TEXT
            {gap 1}
            {margin 4}  ;;; space above and below the text
            {font '10x20'} {bg 'gray90'} {fg 'black'}:
            'Try sliding the blobs.'
            'Then try S1=> S2=>']

        [SLIDERS
            {label sliders} ;;; needed for accessing the value
            {gap 1} {width 300} {height 35}
            {margin 5}
            {fieldbg 'pink'}
            {barcol 'white'}    ;;; colour of slider bar
            {radius 6}      ;;; diameter of slider blob
            ;;; try uncommenting this
            ;;; {framewidth 2} {framecol 'black'}
            ;;; try uncommenting this
            ;;; {type panel}
            {spacing 4}:
            ;;; Try uncommenting the following to see what difference
            ;;; it makes to the sliding blob
            ;;; {type square}
            ;;; first slider, range -100 to 100 default 0, values rounded,
            ;;; value associated with variable S1
            [S1 {-100 100 0} round [{-8 12 'S1: Range -100 to 100'}]]

            ;;; Second slider, range 0 to 1, not rounded, default 0.5,
            ;;; step value 0.05, linked to variable S2
            [S2 {0 1 0.5 0.05} noround
                [[{-4 12 'S2: Min(0)'}][{-35 12 'Max(1)'}]]]
        ]


        [TEXT  ;;; {bg 'brown'}
            {fg 'yellow'}:
            'Some "radio" buttons' 'Choose one at a time, then'
            'try the DRAWBLOB button below']

        ;;; Now some radio buttons in two columns, centred by default
        [RADIO {cols 4} {spacing 2}
            {margin 2} {width 80}
            {gap 0}
            ;;; The variable the_colour will show the selected colour
            {ident the_colour}
            {default 'red'}
            {fieldbg 'orange'} :
            'red' 'orange'  'yellow' 'green' 'blue' 'pink'
            'black' 'white'
        ]

        [ACTIONS {cols 2} {width 160}
            {fieldbg 'red'}
            {margin 5}
            {spacing 1}:
            ['DRAWBLOB'
                [POP11
                    rc_scratch_window -> rc_current_window_object;
                    rc_draw_blob(
                        200-random(400),200-random(400), 5+random(50),the_colour)
                        ]]

            ;;; This hides the current scratchpad window
            ['HIDE SCRATCHPAD' [POP11 false -> rc_scratch_window]]

            ;;; This saves the previous scratchpad and starts a new one
            ['TEAROFF'  rc_tearoff]

            ;;; this kills all the saved tearoffs
            ['KILL TEAROFFS' rc_kill_tearoffs]

        ]
        [TEXT {bg 'brown'} {fg 'yellow'} :
            '"Someof" buttons.' 'Toggle them on and off'
            'Then try: all_moods =>']

        ;;; Some "someof" buttons (toggle buttons) in two columns
        [SOMEOF {margin 5}{cols 2} {spacing 2} {width 80}
            ;;; the variable all_moods will show selected values
            {ident all_moods}
            ;;; Turn on two features by default
            {default ['happy' 'smug']}:
            'happy' 'sad' 'elated' 'smug']

        [TEXT : 'Try polyspiral demo library']

        ;;; Action buttons for invoking scratchpad and for demonstrating
        ;;; LIB RC_POlYPANEL
        [ACTIONS {cols 3} {width 110}
            {fieldbg 'red'}
            {margin 5}
            {spacing 1}:
            ['FETCH DEMO' 'showlib rc_polypanel']
            ['COMPILE IT' 'lib rc_polypanel']
            ['RUN IT ' rc_poly]
        ]

    ];

vars demo_panel = rc_control_panel(550, 10, panel_fields, 'DEMO PANEL');

;;; Try to examine the panel closely and compare the fields displayed
;;; with the descriptions in the panel_fields list, above.

;;; check the values of S1 and S2, and use sliders to change them:
S1, S2 =>

;;; A slider's value can be changed either by dragging the "blob" on the
;;; slider (with mouse button 1) or by clicking at the desired location on
;;; the slider bar, or by typing a number into the slider's number
;;; panel (press RETURN when the number is complete).

;;; Check that selection of colour and someof buttons is recorded
the_colour =>
all_moods =>

;;; The demo panel is a subclass of rc_window_object
demo_panel =>

;;; Its contents can be accessed, e.g.
vars
    sliderfield = rc_field_of_label(demo_panel, "sliders"),
    sliderlist = rc_field_contents(sliderfield),
    slider1 = hd(sliderlist);

;;; Try moving the top slider and printing this
rc_slider_value(slider1) =>

30 -> rc_slider_value(slider1);
60 -> rc_slider_value(slider1);

;;; watch the effect of this
vars x;
for x from -100 to 100 do
    x -> rc_slider_value(slider1);
    syssleep(1)
endfor;

;;; try making the other slider go from 1 to 0
;;; in steps of -0.01.

Press the KILL button to remove the panel.

You can try varying some of the text.

-- Another example with text and number input fields ------------------

uses rc_control_panel
uses rc_text_input

;;; Two variables linked to text input and number input fields.
vars textin1, numberin1 = 1;

;;; create the panel specification list.
vars
    panel2_info =
      [
          {events []}
          ;;; Try with and without the following properties
          ;;; {width 450} {height 550}
          ;;; "offset" can be used to leave a section clear to the left
          ;;; {offset 100}
          ;;; The origin and scale of the panel should not affect
          ;;;  its appearance
          ;;; {xorigin -50}
          ;;; {yorigin 100}
          ;;; {xscale -2} ;;; or 1 or -1
          ;;; {yscale 2}
          ;;; A text header field
          [TEXT
              {margin 5}  ;;; margin above and below the text
              {align left} :
              ;;; Now the strings
              'Panel demo' 'Click to dismiss:']

          ;;; An action field with a dismiss button. Align right and
          ;;; use negative gap to superimpose on previous text field
          [ACTIONS
              {offset 10} ;;; Horizontal displacement if right or left
              ;;; button width
              {width 95}
              {align right} {gap -30} :
              ['KILL PANEL' rc_kill_panel]
          ]

          [TEXT {bg 'pink'} {fg 'blue'} {gap 15} {align right}
              {offset 10} {margin 15} :
              'This simple demo does not'
              'do anything very useful.'
          ]
          [TEXT {bg 'pink'} {fg 'blue'}
              {gap 10} {margin 5}
              {align left}
              {offset 5}:
              'The next field is for text input.'
              'Use left/right arrow keys, and'
              'Backspace or Delete for editing.'
              'Use RETURN when changes are done.'
              'To print contents: CTRL + "=", or'
              '  textin1=> '
          ]

          [TEXTIN
              ;;; align the text input field left, then offset 65
              ;;; and negative gap, to superimpose on previous field
              {label text1}
              ;;; Variable whose value will be the string
              {ident textin1}
              {align left}
              {gap -10} {margin 5}
              {width 300} {height 30} {font '10x20'}
              ;;; if the offset is too small it will be adjusted
              {offset 10}
              {labelstring 'Message:'}
              {labelcolour 'blue'}
              {labelfont '9x15bold'}
              {bg 'pink'}:
              ['Hello']
          ]
          [TEXT {bg 'pink'} {fg 'brown'}
              {gap 10} {align centre}
              {offset 10} {margin 3} :
              'The next field is for number input.'
              'Use RETURN when changes are done.'
              'To print contents: CTRL + "=", or use'
              ' numberin1 => '
          ]

          [NUMBERIN
              ;;; link this with variable numberin1
              {ident numberin1}
              {align centre}
              {gap 5}
              {margin 5}
              {width 90} {height 30} {font '10x20'}
              {labelstring 'No of blobs:'}
              {bg 'orange'}:
              ;;; constrain the number to be an integer
              [5 {constrain round}]
          ]
          [TEXT :
              'A simple graphical demo follows:'
              'The number of blobs drawn depends'
              'on the number shown above.'
              'Try a larger number.'
          ]

          ;;; define an actions field with two buttons
          [ACTIONS
              {align centre}
              {gap 10} {width 120} {height 40}:
              ['DRAW BLOBS'
                  ;;; This button invokes a POP11 action to draw in
                  ;;; a 'scratch' graphical window, after printing out
				  ;;; the contents of the text input panel
                  [POP11
                      textin1=>
                      dlocal rc_current_window_object= rc_scratch_window;
                      repeat numberin1 times
                      lvars
                      x = 200 - random(400),
                      y = 200 - random(400),
                      radius = 5+random(60),
                      colour =
                      oneof(['red' 'green' 'blue' 'pink' 'black']);
                      rc_draw_blob(x, y, radius, colour)
                      endrepeat;]]

              ['HIDE GRAPHIC'
                  ;;; This button destroys the scratch window
                  [POP11 false -> rc_scratch_window]]
          ]
      ];

;;; now create panel2

vars panel2 =
    rc_control_panel(600,45, panel2_info, 'panel2');

/*
After editing the text input and number input fields, check the
values of these variables:
*/

    textin1 =>
    numberin1 =>
/*
To find out more about text input and number input fields look at

    HELP * RC_TEXT_INPUT
*/

/*
-- Example, putting a new panel inside an old one ---------------------

You can also create a version of panel2 inside demo_panel if you
have not deleted that. If you have, try recreating demo_panel:
*/

vars demo_panel = rc_control_panel(550, 10, panel_fields, 'DEMO PANEL');

/*
then give the following command which is similar to that for panel2,
except that demo_panel is given as an extra argument to
rc_control_panel, implying that that should be used as "container".

*/

;;; Now create subpanel2, after first identifying the required
;;; location in demo_panel. Extract its width, the third result of
;;; rc_window_location:

vars ( , , panel_w, ) = rc_window_location(demo_panel);

panel_w=>

vars subpanel2 =
    rc_control_panel(panel_w,1, panel2_info, 'subpanel2', demo_panel);

;;; Now delete the two panels. The Dismiss button on subpanel2 deletes
;;; only that panel.

/*

-- Moving sub-panels --------------------------------------------------

If you have dismissed the previous panel (panel2), first recreate it.
*/

vars panel2 =
    rc_control_panel(600,45, panel2_info, 'panel2');

/*
As shown above, you can give a panel as optional extra argument to
rc_control_panel, in which case the new panel will be created inside the
old one. Here, to illustrate, we create a little yellow 15 by 15 panel
inside the old one near the top left corner.
*/


vars yellow_panel =
    rc_control_panel(5, 5,
        [{width 20}{height 20} {bg 'yellow'}], 'panel', panel2);

/*
Note that that panel can be moved within the larger one using rc_move_to
and rc_move_by. E.g. try this repeatedly
*/

    rc_move_by(yellow_panel, 5, 5, true);

/*
It is easy to make the sub-panel draggable using mouse button 3. There
is an autoloadable procedure rc_drag_window which can be made the third
drag handler for the yellow_panel

    rc_drag_window -> rc_drag_handlers(yellow_panel)(3);

Try using button 3 to drag the panel around the picture.

Alternatively you can make it draggable by mouse button1, using the
location 20,20 in the panel (the bottom right corner) as the drag point:
the format is:

    rc_make_draggable(win_obj, button, xloc, yloc);

e.g.
*/

    rc_make_draggable(yellow_panel, 1, 20, 20);

;;; or make it draggable by the middle

    rc_make_draggable(yellow_panel, 1, 10, 10);

;;; Remove the panels by using the Kill button.
;;; Additional examples are in HELP RC_CONTROL_PANEL

/*
-- Using rc_popup_panel to display a panel which waits ----------------

The procedure rc_popup_panel is based on rc_control_panel, but
it suspends processing until you take appropriate action with the panel,
e.g. answering a question posed. In that sense it is partly like
rc_popup_query (demonstrated above), though more general as it can
contain arbitrary fields.

It is invoked with this format:

    rc_popup_panel(x, y, panel_info, title, control_ident);

where control_ident is a variable or identifier which has to be made
true for the procedure to finish.

Here is a panel which allows you to select from a list of options by
clicking on one of them:
*/

define popup_options(string, options) -> result;
    ;;; display the string and the list of options to be selected

    ;;; default result
    false -> result;

    ;;; control variable: panel exits when this is true.
    lvars finished = false;

    define do_answer(option);
        ;;; use a closure of this procedure for each option
        option -> result;
        true -> finished;
    enddefine;

    lvars option, actions;

    ;;; make a list of action buttons with corresponding
    ;;; procedures created using do_answer
    [%for option in options do
            [%option, do_answer(%option%) %]
        endfor%] -> actions;

    rc_popup_panel(
        400, 400,
        [[TEXT : ^string]
            [ACTIONS {width 70}: ^^actions ]
        ],
        'test_window', ident finished);

enddefine;

;;; test it:

popup_options('Do you agree?', [Yes No Maybe])=>

popup_options('Do you agree?', [Yes No Maybe Dunno])=>

/*
Similar mechanisms are used to define the autoloadable libraries
demonstrated in the next few sections.

-- "popup" text or number input panels: rc_getinput -------------------

Try these mechanisms for getting information from the user
*/

uses rclib
uses rc_getinput

;;; a message to be displayed
vars instruct =
    ['Type your name in'
    'Press RETURN, or click on "OK"'];

;;; Three ways of asking for your name (the result is a string):

;;; 1. Using the default font, etc.
rc_getinput(400, 300, instruct, '', [], 'Name?')=>

;;; 2. Using a specified font
rc_getinput(400, 300, instruct, '', [{font '12x24'}], 'Name?')=>

;;; 3. Using a wider text input area and a non-empty default string,
;;; the user's login name
rc_getinput(400, 300, instruct, popusername, [{font '12x24'}{width 500}], 'Name?')=>

;;; 4. Using a number as default invokes a number input panel
rc_getinput(400, 300, ['type a number'], 0, [{font '10x20'}], 'A number')=>


;;; 5 Making the input request appear inside another panel

;;; A silly "permanent" panel first
vars panel =
    rc_control_panel(400, 10,
        [{width 400}{height 100}
            [TEXT: 'Anything could come here']
            [ACTIONS {gap 100}{margin 5}:
                [DISMISS rc_kill_panel]]], 'TEST');

;;; create a popup panel inside that panel, by using the panel
;;; as the final argument of rc_getinput. The coordinates are now
;;; relative to the panel:

rc_getinput(
    100, 40, ['your name?'], '',
        [{font '6x13'}{width 200}], 'Name?', panel)=>

;;; The result returned should be the string typed in, or false if you
;;; click on Cancel.

;;; Now you can dismiss the previous panel

;;; See HELP RC_control_panel for more examples, including an example
;;; showing how to format control panel fields side by side.

/*
A procedure partly similar to rc_getinput, defined before rc_popup_panel
was available can be found in LIB * RC_POPUP_READIN

-- A "popup" version of readline: rc_readline -------------------------

    rc_readline(x, y, strings, prompt, specs, title) -> list;

The result of this should be a list of words, or words numbers and
strings.
*/

vars instruct =
    ['Type in a sentence, then'
    'Press RETURN or double-click'
    'Or click on "OK"'];

rc_readline(400, 300, instruct, '', [], 'Sentence?')=>

rc_readline(400, 300, instruct, '', [{font '12x24'}], 'Sentence?')=>

rc_readline(400, 300, instruct, '', [{font '12x24'}{width 500}], 'Sentence?')=>

;;; You can give a default input string, and change the text colour

rc_readline(
    300, 30, instruct, 'hello',
        [{font '6x13'}{textinfg 'blue'}], 'Sentence?')=>

/*
A procedure partly similar to rc_readline, defined before rc_popup_panel
was available can be found in LIB * RC_POPUP_READLINE

-- A more complex control panel ---------------------------------------

There is a file giving a far more complex demonstration, a graphical
teaching panel:

    LIB * RC_POLYPANEL

More information can be found in:
    TEACH * RC_CONTROL_PANEL
    HELP  * RC_CONTROL_PANEL
*/


/*
-- Using rc_showtree --------------------------------------------------

Here is an application of window objects. it uses a version of
    LIB * SHOWTREE
ported to RCLIB by Riccardo Poli. See HELP * RC_SHOWTREE
*/

uses rclib
uses rc_window_object
uses rc_showtree

;;; Create a window to draw in, with origin top left, and
;;; y going down
vars
    win1 = rc_new_window_object(500, 40, 400, 400, {1 1 1 -1}, 'win1');

;;; Display an arithmetical expression represented using lists, at
;;; position 20, 20

rc_showtree([+ [* 1 x][/ [+ 3 y] 10]], 20, 20);

;;; clear the window
rc_start();

;;; Changing fonts and types of connections
true -> showtree_oblong_nodes;  ;;; default
false -> showtree_ortho_links;  ;;; default

;;; Now display the structure of a logical expression, using
;;; default settings for links and nodes
rc_showtree([OR [NAND x2 x1] [NOR x1 x1]], 80, 5, '9x15');

;;; Now with vertical and horizontal links
true -> showtree_ortho_links;
rc_showtree([OR [NAND x2 x1] [NOR x1 x1]], 0, 100, 'fixed');

;;; Turn the oblongs into rectangles, and use a bigger font.
false -> showtree_oblong_nodes;
rc_showtree([OR [NAND x2 x1] [NOR x1 x1]], 100, 190, '10x20');

;;; A wider tree, so widen the picture, i.e. to width 700

5, 5, 700, false -> rc_window_location(win1);

;;; clear it
rc_start();


2 -> rc_linewidth;
false -> rc_clipping;   ;;; ignore previous boundaries
rc_showtree(
    [University
        [Science
            [Psychology Glyn Cristina '...']
            [ComputerScience
                [CS Achim Marta Valeria '...']
                [AI Ela Aaron Riccardo Manfred '...']]
            '...']
        [Engineering
            MechEng
            ElecEng
            '...']
        '...'], 1, 1, '6x13');


;;; Change the format and try the above again
rc_start();
false -> showtree_ortho_links;
true -> showtree_oblong_nodes;

rc_kill_window_object(win1);

;;; See also HELP * RC_SHOWTREE
;;; (and HELP * SHOWTREE, for the VED version)

;;;

/*
-- rc_scratchpad ------------------------------------------------------

It can be confusing using rc_window_object instances alongside
the "raw" rc_graphic facilities, since the latter can draw over
windows in an unexpected way. To ensure that you have a "safe" window
to draw on use LIB * RC_SCRATCHPAD. The main ideas here are due to
Brian Logan
*/

uses rclib
uses rc_window_object
uses rc_buttons
uses rc_scratchpad

;;; Make a window that is to be protected from rough drawings.

vars
    win1 = rc_new_window_object(
                500, 5, 300, 300, true, newrc_button_window, 'win1');

win1 -> rc_current_window_object;
rc_xorigin =>
rc_yorigin =>

rc_draw_blob(0,0,60,'red');
rc_draw_blob(0,0,30,'blue');

;;;Now create a new scratchpad window and draw some lines on it:

rc_scratch_window -> rc_current_window_object;

rc_drawline(-100,-100,100, 100);
rc_draw_blob(30,40,30,'pink');

;;; go back to win1
win1 -> rc_current_window_object;
rc_draw_square(-50, 100, 30);

;;; Use the syntax word RCSCRATCH to give a command to draw on the
;;; scratchpad

RCSCRATCH rc_drawline(-50, 200, -50, -200);

;;; The next command goes on the last window which was explicitly
;;; selected as current.
;;; (Use this command several times to get a different randomly located
;;; blob each time.)

rc_draw_blob(50 - random(100),50 - random(100),5+random(30),'pink');

;;; Start a new scratch pad, leaving the old one
;;; Check that the old scratchpad is still there after this command
rc_tearoff();

;;; This is equivalent to the following two commands

    ;;; make current scratchpad window no longer accessible
    undef -> rc_scratch_window;
    ;;; Get new one and make it current
    rc_scratch_window -> ;

;;; The new one will appear close to the old one and the same size,
;;; with the origin in the middle, and with rc_xscale = 1 and
;;; rc_yscale = -1, i.e. y increasing upwards

;;; draw on the new one (another randomly located blob.)

RCSCRATCH
    rc_draw_blob(100 - random(200),100 - random(200),5+random(40),'red');

;;; several commands can be grouped, inside parentheses
RCSCRATCH
    (rc_draw_blob(50, 200, 40, 'orange'),
     rc_draw_square(0,0,80));

;;; Get rid of old "torn off" scratch pads, keeping only the most recent
;;; one

rc_kill_tearoffs();

;;; get rid of the current scratchpad

false -> rc_scratch_window;

;;; get rid of win1
rc_kill_window_object(win1);

;;; create a new scratchpad
RCSCRATCH
    rc_draw_blob(100 - random(200),100 - random(200),5+random(40),'red');

;;; Use the mouse to move that window to a different location, and perhaps
;;; make it smaller

;;; Start a new scratch pad
rc_tearoff();

;;; The new pad should be close to the old one.
;;; You can draw on it. Do this several times
RCSCRATCH
    rc_draw_blob(100 - random(200),100 - random(200),5+random(40),'blue');

/*
-- -- using the mouse to make a previous scratchpad the current one
*/

;;; If you want to make the old one the CURRENT scratch pad, make it
;;; visible then press the Control key and click on the window with
;;; mouse button 1 while holding Control down.
;;; Then the next command will draw on the selected window.

RCSCRATCH
    rc_draw_blob(100 - random(200),100 - random(200),5+random(40),'yellow');

;;; Try alternately making different scratchpad windows current using
;;; CTRL+button 1.

/*
-- -- "saving" the current scratchpad
*/

;;; Make the current scratchpad "torn off", or "saved" without
;;; creating a new one

undef -> rc_scratch_window;

;;; Then trying to draw on the "current" scratchpad will create a
;;; new current scratchpad

RCSCRATCH
    rc_draw_blob(100 - random(200),100 - random(200),5+random(40),'orange');

;;; get rid of all of the old ones

rc_kill_tearoffs();

;;; and the current one
false -> rc_scratch_window;

-- -- rc_scratch_panel

;;; It is possible to create a control panel on the screen for creating
;;; new scratchpad windows, removing them, etc. Try

rc_scratch_panel(10,10);    ;;;; create panel at screen location 10,10

;;; After that experiment with the buttons, using the following command
;;; to draw things on the "current" scratchpad window.

rc_draw_blob(100 - random(200),100 - random(200),5+random(40),'orange');

rc_draw_blob(100 - random(200),100 - random(200),5+random(40),
					oneof(['red' 'blue' 'orange' 'black']));

;;; rc_scratch panel presents some "Action" buttons, using the
;;; rc_control_panel library described below.


-- See also -----------------------------------------------------------

There are many more examples in these teach and help files


TEACH * POPCONTROL
	This teach file gives examples of buttons which control global
	variables e.g. booleans that can be turned on and off (like popgctrace),
	or numerical variables (like popmemlim) which can be increased or
	decreased. It can be used to control the environment of the Pop-11
	programmer or Ved user.

TEACH * RC_LINEPIC
	Many examples showing how to create static, movable, rotatable,
	draggable pictures of various kinds

TEACH * RC_MOUSEPIC
	Shows how to change the methods that define effects of mouse or
	keyboard events.

 HELP * RC_BUTTONS
    This demonstrates a lot more button based facilities

 HELP * RC_POINT
A library to make mouse movable points, each depicted (by default) as a
circle with a label in the middle. Make it available thus

 HELP * RC_SHOWTREE
A graphical version of * showtree

For more on control panels, see
TEACH * RC_CONTROL_PANEL
 HELP * RC_CONTROL_PANEL
 LIB  * RC_POLYPANEL

For more on text input fields, see

 HELP * RC_TEXT_INPUT

For an overview of the whole range of facilities see
 HELP * RCLIB

For news of recent changes see
 HELP * RCLIB_NEWS

For information about problems with colours and fonts see

 HELP * RCLIB_PROBLEMS

For more information on event handling, see

 HELP * RC_LINEPIC

For some examples showing how to use panel buttons to launch programs
whose behaviour can be altered asynchronously by other buttons, see
 TEACH * RC_ASYNC_DEMO

Examples of the use of constrainer procedures and reactor procedures
linking different fields in a panel can be found here:
 TEACH * RC_CONSTRAINED_PANEL



-- Additional demonstration packages ----------------------------------

    ENTER showlib rc_blocks

This, together with LIB RC_HAND provides a demonstration of a simulated
robot that can be given questions or instructions in English to
manipulate coloured blocks on a table.

    ENTER rcdemo painting_demo

(or look at $poplocal/local/rclib/demo/painting_demo.p )

This shows how to produce a demonstration artists package with a
painting easel consisting of a row of paint brushes and a column of pots
of coloured paint. (It was developed before the RC_BUTTONS package
was implemented, and could be much improved).


    ENTER rcdemo rc_ant_demo

(or look at $poplocal/local/rclib/demo/rc_ant_demo.p )

This shows how to make a lot of ants that roam around and occasionally
meet up, do a little dance then move away. There are buttons to increase
or decrease the number of ants, or to stop. Could be much improved.
See if you can work out the behaviour rules of the ants simply by watching
them.

    ENTER rcdemo aze.connect4

This was the Cognitive Science MSc project of Athina Economou in the
Summer of 1997. It is a program to play the game of Connect4 with a
graphical interface. Compile the file, then, to play, give the command

    connect4();

(It is not easy to beat the program.)

There are additional demonstrations of the use of RCLIB within the
SIM_AGENT toolkit. See HELP SIM_AGENT, or
    http://www.cs.bham.ac.uk/~axs/cog_affect/sim_agent.html

Additional demos using RCLIB may be added later. Look in
	$poplocal/local/rclib/demo/



--- $poplocal/local/rclib/teach/rclib_demo.p
--- Copyright University of Birmingham 2004. All rights reserved. ------
