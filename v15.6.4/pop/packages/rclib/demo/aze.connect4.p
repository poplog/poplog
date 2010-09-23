/* --- Copyright University of Birmingham 1998. All rights reserved. ------
 > File:            $poplocal/local/rclib/demo/aze.connect4.p
 > Purpose:			Program to play connect4
 > Author:          Athina Economou, August 1997,
					part of Cognitive Science MSc project
 > Documentation:	Below
 > Related Files:	LIB * RCLIB, * RC_CONTROL_PANEL
 */

/*
This program, which plays connect4 using patterns designed to correspond
intuitively to how a moderately experienced human player would select a
move was part of a summer project by Athina Economou, MSc Cognitive
Science Student, University of Birmingham, 1996-7

This is included as a demonstration of the use of the RCLIB package,
with permission of the author.

To play the game

1. Compile this file (assuming RCLIB has been installed)

2. Give the Pop11 command

	connect4();

Click on
	Options button:
		to select colour for yourself and your opponent,
		unless you want the default colours.
		The defaults revert after every game.

	Play button:
		to choose whether you or the computer plays first
	Help button:
		to get an explanatory message.
	New button:
		to abort and restart
	Bye button:
		to finish.


*/


/*
         CONTENTS - (Use <ENTER> g to access required sections)

 define :class square;
 define :class grid;
 define :method draw_square(x:square);
 define :method make_board(xx:grid);
 define palette();
 define cancel();
 define customise();
 define help();
 define pass(player, element, num);
 define store(player, element);
 define length_col(num)-> y_of_column;
 define move(num, colour);
 define book_move(num);
 define play();
 define lookout(badmoves, column) -> moved;
 define tryadd(item, badmoves) -> badmoves;
 define tryaddall(items, badmoves) -> badmoves;
 define findThreeVertical_Rule(i, j, who, badmoves) -> foundMove;
 define findThreeHorizontal_Rule(i, j, who, badmoves) -> foundMove;
 define findThreeHorizontal_Rule1(i, j, who, badmoves) -> foundMove;
 define findThreeHorizontal_Rule2(i, j, who, badmoves) -> foundMove;
 define findThreeHorizontal_Rule3(i, j, who, badmoves) -> foundMove;
 define findThreeRightDiag_Rule(i, j, who, badmoves) -> foundMove;
 define findThreeRightDiag_Rule1(i, j, who, badmoves) -> foundMove;
 define findThreeRightDiag_Rule2(i, j, who, badmoves) -> foundMove;
 define findThreeRightDiag_Rule3(i, j, who, badmoves) -> foundMove;
 define findThreeLeftDiag_Rule(i, j, who, badmoves) -> foundMove;
 define findThreeLeftDiag_Rule1(i, j, who, badmoves) -> foundMove;
 define findThreeLeftDiag_Rule2(i, j, who, badmoves) -> foundMove;
 define findThreeLeftDiag_Rule3(i, j, who, badmoves) -> foundMove;
 define findTwoVertical_Rule(i, j, who, badmoves) -> foundMove;
 define findTwoHorizontal_Rule(i, j, who, badmoves) -> foundMove;
 define findTwoHorizontal_Rule1(i, j, who, badmoves) -> foundMove;
 define findTwoHorizontal_Rule2(i, j, who, badmoves) -> foundMove;
 define findTwoHorizontal_Rule3(i, j, who, badmoves) -> foundMove;
 define findTwoHorizontal_Rule4(i, j, who, badmoves) -> foundMove;
 define findTwoHorizontal_Rule5(i, j, who, badmoves) -> foundMove;
 define findTwoRightDiag_Rule(i, j, who, badmoves) -> foundMove;
 define findTwoRightDiag_Rule1(i, j, who, badmoves) -> foundMove;
 define findTwoRightDiag_Rule2(i, j, who, badmoves) -> foundMove;
 define findTwoRightDiag_Rule3(i, j, who, badmoves) -> foundMove;
 define findTwoRightDiag_Rule4(i, j, who, badmoves) -> foundMove;
 define findTwoRightDiag_Rule5(i, j, who, badmoves) -> foundMove;
 define findTwoLeftDiag_Rule(i, j, who, badmoves) -> foundMove;
 define findTwoLeftDiag_Rule1(i, j, who, badmoves) -> foundMove;
 define findTwoLeftDiag_Rule2(i, j, who, badmoves) -> foundMove;
 define findTwoLeftDiag_Rule3(i, j, who, badmoves) -> foundMove;
 define findTwoLeftDiag_Rule4(i, j, who, badmoves) -> foundMove;
 define findTwoLeftDiag_Rule5(i, j, who, badmoves) -> foundMove;
 define vertical(who, whichRule, badmoves) -> foundMove;
 define horizontal(who, whichRule, badmoves) -> foundMove;
 define rightDiagonal(who, whichRule, badmoves) -> foundMove;
 define leftDiagonal(who, whichRule, badmoves) -> foundMove;
 define compulsiveMove();
 define findSafeMove(badmoves);
 define cutoff(badmoves);
 define advance(badmoves);
 define block(badmoves);
 define computerMove();
 define connect4();
 define new();
 define win_message(who) -> choice;
 define draw_message();
 define draw() -> finished;
 define win(who) -> result;
 define col(num);

*/

uses objectclass
uses rclib;
uses rc_linepic;
uses rc_window_object;
uses rc_mousepic;
uses rc_buttons;
uses rc_control_panel;




define :class square;
    slot x_co = 0;
    slot y_co = 0;
    slot size = 30;
    slot colour = 0;
enddefine;




define :class grid;
    slot column = 7;
    slot row = 6;
enddefine;





define :method draw_square(x:square);
    0 -> rc_heading;
    rc_jumpto(x_co(x), y_co(x));
    repeat 4 times
        rc_draw(25);
        rc_turn(90);
    endrepeat;
enddefine;




define :method make_board(xx:grid);
    lvars x, y, z;
    for x from 1 to column(xx) do
        for y from 1 to row(xx) do
            conssquare(x*30, y*30, 30, 0) -> z;
            draw_square(z);
        endfor;
    endfor;
enddefine;

vars xx = consgrid(7, 6);



;;; Some global variables

vars move_status, full_status, current_panel, customise_panel;

vars user_piececolour_def  =
                              'red';

vars comp_piececolour_def =
                            'yellow';

vars user_piececolour = user_piececolour_def;
vars comp_piececolour = comp_piececolour_def;

vars panel_col =
                    {rc_button_stringcolour 'SaddleBrown'
                     rc_button_bordercolour 'IndianRed'
                     rc_button_labelground 'honeydew'
                     rc_chosen_background 'firebrick'
                     rc_button_pressedcolour 'firebrick'};

vars panel_depth, grid_bottom;

vars grid_x =
                111;

vars strings =
        ['Hello!'
         'You have entered the Connect4 Game'
         'The aim is to complete a sequence of'
         'four pieces before your opponent!'
         'The sequence can be either horizontal,'
         'vertical or diagonal.'
         'Care for a game?' ^nullstring];

vars
    query1 =
        ['Play first?'],
    query2 =
        ['Congratulations!''You won!''Play again?'],
    query3 =
        ['Sorry! I won!''Would you like''to try again?'],
    query4 =
        ['No winner this time!''Another game?' ^nullstring],

    options1 = [YES NO];


vars colours =
    [
        'Black' 'Blue' 'Red' 'Green' 'Yellow' 'White' 'Purple' 'Pink' 'Orange' 'Brown'
    ];



vars
    query_options =

        [
            {bg 'RosyBrown'}
            {fg 'ivory'}
            {font '10x20'}

            [TEXT {gap 5}
                    {bg 'IndianRed'}
                    {fg 'ivory'}
                        {margin 10}
                                :
                    'Please choose a colour for your pieces'
            ]

            [RADIO
                    {label user}
                {width 70} {height 24}
                {cols 5}
                {spec ^panel_col}
                :
                    ^^colours
                ]

            [TEXT {gap 5}
                    {bg 'IndianRed'}
                    {fg 'ivory'}
                        {margin 10}
                                :
                    'Please choose a colour for your opponent'
            ]

            [RADIO
                    {label computer}
                {width 70} {height 24}
                {cols 5}
                {spec ^panel_col}
                :
                    ^^colours
            ]

            [ACTIONS {cols 0} {width 70}
                         {spec [^panel_col {rc_button_pressedcolour 'LightSteelBlue'}]}
                :
                ['OK' [DEFER POP11 palette()]]
                ['Cancel' cancel]
            ]
];





/*
PROCEDURE: palette ()
INPUTS:   NONE
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        To accept the colour selection(s) made and make sure a player
                always has a colour, which is always different from that of
                the opponent.

TESTS:          Invoked by an action button(no tests).

*/

define palette();
    lvars
        user_selection =
        rc_options_chosen(rc_field_contents(rc_field_of_label
        (customise_panel, "user"))),
        comp_selection =
        rc_options_chosen(rc_field_contents(rc_field_of_label
        (customise_panel, "computer"))),
        ;
    user_selection -> user_piececolour;     ;;; The new choices update the
    comp_selection -> comp_piececolour;     ;;; default values for the colours

    ;;; Should the selection be the same for both players, then
    if user_selection = comp_selection then

        ;;; if it is nothing, both default values remain.
        if user_selection = [] then
            user_piececolour_def -> user_piececolour;
            comp_piececolour_def -> comp_piececolour;
        else
            ;;; Otherwise, pop up a warning message
            rc_message(440, 670, [' Please choose different colours '
                    'for each player' ^nullstring], 0, true, '12x24',
                'DarkSlateBlue', 'LightSteelBlue') -> ;
            return();
        endif;

    ;;; In case the user did not make a selection for her/himself,
    elseif user_selection = [] then

        ;;; if red(user's default) is chosen for the computer, make a warning
        if comp_selection = 'Red' then
            rc_message(477, 660, [' Red is your colour too!'
                    ' Please try something else ' ^nullstring], 0, true,
                '12x24', 'DarkSlateBlue', 'LIghtSteelBlue') -> ;
            return();
         else
            ;;; If it's not, the user gets her/his default colour
            user_piececolour_def -> user_piececolour;
        endif;

    ;;; If no new colour is selected for the computer,
    elseif comp_selection = [] then

        ;;; if the user selects yellow(computer's default) for him/herself,
        ;;; pop up a warning message
        if user_selection = 'Yellow' then
            rc_message(430, 650, [' Sorry! The default colour for the '
                    'computer is currently yellow' 'Please choose something else'
                    'for you or your opponent' ^nullstring], 0, true, '12x24',
                'DarkSlateBlue', 'LightSteelBlue') -> ;
            return();
         else
            ;;; If not, the computer gets its default colour
            comp_piececolour_def -> comp_piececolour;
        endif;

    endif;

    rc_kill_window_object(customise_panel);         ;;; Kill the OptionsPanel
    current_panel -> rc_current_window_object;      ;;; GamePanel is now the
                                                    ;;; active window
enddefine;




/*
PROCEDURE: cancel ()
INPUTS:   NONE
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        To cancel the invocation or a choice made in the
                Customise Panel, and set the piececolours to their default
                values.

TESTS:          Invoked by an action button(no tests).

*/

define cancel();

    user_piececolour_def -> user_piececolour;  ;;; Set the piece colours
    comp_piececolour_def -> comp_piececolour;  ;;; to their default values

    rc_kill_window_object(customise_panel);    ;;; Kill the OptionsPanel

enddefine;




vars panel_specs =
    [
        {bg 'SteelBlue'}
        {fg 'navy'}
        {font '10x20'}
        {width 400}
        {height 400}

        [TEXT
            {bg 'DarkSlateBlue'}
            {fg 'ivory'}
                {margin 10}   :

            'Connect 4'
    ]

    [TEXT {gap 5}
            {bg 'IndianRed'}
            {fg 'ivory'}:
            'Select column here'
    ]

    [ACTIONS
                {label columns}
            {width 30} {height 24}
            {cols 7}
                {spec [^panel_col {rc_button_labelground 'RosyBrown'}]}
            :
            ['1' [DEFER POP11 col(1)]]
            ['2' [DEFER POP11 col(2)]]
            ['3' [DEFER POP11 col(3)]]
            ['4' [DEFER POP11 col(4)]]
            ['5' [DEFER POP11 col(5)]]
            ['6' [DEFER POP11 col(6)]]
            ['7' [DEFER POP11 col(7)]]
            ]

    [GRAPHIC
        {bg 'SteelBlue'}
        {fg 'darkblue'}
        {label game}
        {height 230}
        {align left}
		 {xorigin 68} {yorigin -15}
		:
            [POP11

                ;;; get location of top of field boundary
                lvars field =
                rc_field_of_label(rc_current_panel, "game");
                rc_field_y(field) -> panel_depth;
                make_board(consgrid(7,6));
                ]
        ]

    [ACTIONS {cols 5} {width 70}
                 {spec [^panel_col {rc_button_labelground 'LightSteelBlue'}]}
                 :
        ['Options' customise]
        ['Play...' [DEFER POP11 play()]]
        ['Help' help]
        ['New' new]
        ['Bye' [POP11 rc_kill_menu();]]
    ]
];





/*
PROCEDURE: customise ()
INPUTS:   NONE
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        To create a customise panel which will enable the user to
                select a colour for his or his opponent's pieces.

TESTS:          Works in conjunction with the interface(no tests!)

*/

define customise();
    ;;; Create the Customise Panel
    rc_control_panel(390, 610, query_options, 'Customise') -> customise_panel;
enddefine;





/*
PROCEDURE: help ()
INPUTS:   NONE
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        To pop up a message with a short description of the rules
                of the game

TESTS:          No tests (Invoked by action button to show message)

*/

define help();
    ;;; Pop up a message
    rc_message(440, 600, strings, 0, true, '10x20', 'RosyBrown', 'ivory')->;
enddefine;





/*
PROCEDURE: pass (player, element, num)
INPUTS:   player, element, num
  Where:
    player is one of the two players (takes either 1 for the computer,
                                        or 2 for the user)
    element is one of the seven lists(in move_status) representing the columns
    num is one of six items in each element (representing the row number)
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        Used to pass the data (i.e., moves made) from the original
                store(move_status) onto the analogous position in full_status
                (new store).

TESTS:

*/

define pass(player, element, num);
    ;;; Pass the information about the players'
    ;;; moves to a specific location in full_status.
    player -> full_status(element)(num);
enddefine;





/*
PROCEDURE: store (player, element)
INPUTS:   player, element
  Where:
    player is one of the players(computer = 1, user = 2)
    element is one of the seven lists representing the 7 columns
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        To store the data concerning the moves made in a list(move_status)
                consisting of 7(originally empty) lists, one for each column.
                Then, pass on the same information in another storing place
                (full_status), where all states are represented(i.e., filled
                and empty squares)

TESTS:

*/

define store(player, element);
    ;;; Store 'player' in 'element' as the latter's last item
    [^^(move_status(element)) ^player] -> move_status(element);
    ;;; Pass the info from the move_status onto the same position
    ;;; in full_status.
    pass(player, element, length(move_status(element)));
enddefine;





/*
PROCEDURE: length_col (num) -> y_of_column
INPUTS:   num is a number(1 to 6) that points to one of the 6 items in a column.
OUTPUTS:  y_of_column is value that returns that number (i.e., how many things
          are in each column).
CREATION DATE:  25 Aug 1997
PURPOSE:        To discover the length of every column-lists. This is then
                used to calculate the depth (the y coordinate) of the next
                piece drawn in a srecific column.

TESTS:

*/

define length_col(num)-> y_of_column;
    ;;; Use the length of your column lists
    ;;; to calculate the bottom of each column
    ;;; at a given time
    length(move_status(num))-> y_of_column;
enddefine;





/*
PROCEDURE: move (num, colour)
INPUTS:   num, colour
  Where:
    num is one of the seven columns(takes 1 - 7)
    colour is one of the two values for the players' piece colour
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        To draw the new piece in a given column, in the right
                depth with the right colour.

TESTS:

*/

define move(num, colour);
    lvars y_of_column = length_col(num);           ;;; Look at the bottom
    lvars y = grid_bottom - 30*(y_of_column);      ;;; of the column
    current_panel -> rc_current_window_object;     ;;; You are in the GamePanel
    rc_draw_blob(grid_x + 30*(num-1), y, 10, colour);  ;;; Draw a piece
enddefine;





/*
PROCEDURE: book_move (num)
INPUTS:   num is a column number(1 to 7)
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        To make a book move (used only for the computer!)

TESTS:

*/

define book_move(num);
    lvars y_of_column = length_col(num);        ;;; Find the bottom of the col
    lvars y = grid_bottom - 30*(y_of_column);   ;;; Move up by 30 every time

    unless y_of_column >= 6 then        ;;; Carry out actions unless
                                        ;;; you reach the top
        move(num, comp_piececolour);    ;;; Move in the column number given
        store(1, num);                  ;;; Store 1 in your database
                                        ;;; to remember your move
    endunless;
enddefine;





/*
PROCEDURE: play ()
INPUTS:   NONE
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        To enable the user to play second (since currently, s/he
                always plays first!)

TESTS:

*/

define play();
    lvars answer;
    ;;; Pop up the following message
    rc_popup_query(
        533, 348, query1<>[^nullstring^nullstring], options1, true, 2, 55, 25,
        '10x20', 'firebrick', 'ivory', panel_col, false) -> answer;

    if answer == "NO" then           ;;; If the user selects 'No', then
        book_move(4);                ;;; move first in column 4
    else                             ;;; otherwise
        ;;; Do nothing!              ;;; .......wait......
    endif;
enddefine;





/*
PROCEDURE: lookout (badmoves, column) -> moved
INPUTS:   badmoves, column
  Where:
    badmoves is a list of numbers(column-numbers) that must be avoided
    column is just one of the column-numbers
OUTPUTS:  moved is a value that returns true in case a move was made,
          false otherwise (i.e., the column under consideration is one
          that has been found a bad move)
CREATION DATE:  25 Aug 1997
PURPOSE:        To ensure that a move will not be made, if found to be
                leading in loss shortly after.

TESTS:

*/

define lookout(badmoves, column) -> moved;

    if member(column, badmoves) then      ;;; If the column you thought of is a
        false -> moved;                   ;;; bad idea, don't move there!
    else                                  ;;; If not
        true -> moved;                    ;;; then do it!
        move(column, comp_piececolour);   ;;; Move your piece in that column
        store(1, column);                 ;;; Don't forget your move!
    endif;

enddefine;





/*
PROCEDURE: tryadd (item, badmoves) -> badmoves
INPUTS:   item, badmoves
  Where:
    item is a number representing the column considered
    badmoves is a list of column-numbers
OUTPUTS:  badmoves is a list(same as above)
CREATION DATE:  25 Aug 1997
PURPOSE:        To check before adding a column in the badmoves list that it
                is not already there

TESTS:

*/

define tryadd(item, badmoves) -> badmoves;
    unless member(item, badmoves) then      ;;; Unless you have already found
                                            ;;; a move to be a bad idea(!)...
        [^item ^^badmoves] -> badmoves;     ;;; keep it in mind! Make a note
                                            ;;; of it in your badmoves list
    endunless;
enddefine;





/*
PROCEDURE: tryaddall (items, badmoves) -> badmoves
INPUTS:   items, badmoves
  Where:
    items is list of column numbers noted as bad moves
    badmoves is a list of column numbers(same as above)
OUTPUTS:  badmoves is a list(same as above)
CREATION DATE:  25 Aug 1997
PURPOSE:        To check if any of the elements in the first list of badmoves
                do not already exist in the final list. If not, they are
                added to that last one.

TESTS:

*/

define tryaddall(items, badmoves) -> badmoves;
lvars item;
    for item in items do                    ;;; Look at all the contents in
                                            ;;; your badmoves list
        tryadd(item, badmoves) -> badmoves; ;;; Check them one by one. If not
                                            ;;; already there, note them!
    endfor;
enddefine;





/*
PROCEDURE: findThreeVertical_Rule (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following vertical pattern:
                piece-piece-piece-space. Move.

TESTS:

*/

define findThreeVertical_Rule(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i)(j+1) = who and
    full_status(i)(j+2) = who and full_status(i)(j+3) = 0 then
        true -> foundMove;
        move(i, comp_piececolour);
        store(1, i);
    endif;
enddefine;





/*
PROCEDURE: findThreeHorizontal_Rule (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a move_status of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following horizontal pattern:
                space-piece-piece-space
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findThreeHorizontal_Rule(i, j, who, badmoves) -> foundMove;
    badmoves -> foundMove;
    if full_status(i)(j) = 0 and full_status(i+1)(j) = who and
    full_status(i+2)(j) = who and full_status(i+3)(j) = who then
        if j - length(move_status(i)) = 1 then
            true -> foundMove;
            move(i, comp_piececolour);
            store(1, i);
        elseif j - length(move_status(i)) = 2 then
            tryadd(i, badmoves) -> foundMove;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findThreeHorizontal_Rule1 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following horizontal pattern:
                piece-piece-piece-space
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findThreeHorizontal_Rule1(i, j, who, badmoves) -> foundMove;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j) = who
    and full_status(i+2)(j) = who and full_status(i+3)(j) = 0 then
        if j - length(move_status(i+3)) = 1 then
            true -> foundMove;
            move(i+3, comp_piececolour);
            store(1, i+3);
        elseif j - length(move_status(i+3)) = 2 then
            tryadd(i+3, badmoves) -> foundMove;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findThreeHorizontal_Rule2 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following horizontal pattern:
                piece-space-piece-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findThreeHorizontal_Rule2(i, j, who, badmoves) -> foundMove;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j) = 0
    and full_status(i+2)(j) = who and full_status(i+3)(j) = who then
        if j - length(move_status(i+1)) = 1 then
            true -> foundMove;
            move(i+1, comp_piececolour);
            store(1, i+1);
        elseif j - length(move_status(i+1)) = 2 then
            tryadd(i+1, badmoves) -> foundMove;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findThreeHorizontal_Rule3 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following horizontal pattern:
                piece-piece-space-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findThreeHorizontal_Rule3(i, j, who, badmoves) -> foundMove;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j) = who and
    full_status(i+2)(j) = 0 and full_status(i+3)(j) = who then
        if j - length(move_status(i+2)) = 1 then
            true -> foundMove;
            move(i+2, comp_piececolour);
            store(1, i+2);
        elseif j - length(move_status(i+2)) = 2 then
            tryadd(i+2, badmoves) -> foundMove;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findThreeRightDiag_Rule (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following right diagonal pattern:
                space-piece-piece-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findThreeRightDiag_Rule(i, j, who, badmoves) -> foundMove;
    badmoves -> foundMove;
    if full_status(i)(j) = 0 and full_status(i+1)(j+1) = who
    and full_status(i+2)(j+2) = who and full_status(i+3)(j+3) = who then
        if (j+1) - length(move_status(i)) = 2 then
            true -> foundMove;
            move(i, comp_piececolour);
            store(1, i);
        elseif (j+1) - length(move_status(i)) = 3 then
            tryadd(i, badmoves) -> foundMove;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findThreeRightDiag_Rule1 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following right diagonal pattern:
                piece-piece-piece-space
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findThreeRightDiag_Rule1(i, j, who, badmoves) -> foundMove;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j+1) = who
    and full_status(i+2)(j+2) = who and full_status(i+3)(j+3) = 0 then
        if (j+2) - length(move_status(i+3)) = 0 then
            true -> foundMove;
            move(i+3, comp_piececolour);
            store(1, i+3);
        elseif (j+2) - length(move_status(i+3)) = 1 then
            tryadd(i+3, badmoves) -> foundMove;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findThreeRightDiag_Rule2 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following right diagonal pattern:
                piece-space-piece-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findThreeRightDiag_Rule2(i, j, who, badmoves) -> foundMove;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j+1) = 0
    and full_status(i+2)(j+2) = who and full_status(i+3)(j+3) = who then
        if j - length(move_status(i+1)) = 0 then
            true -> foundMove;
            move(i+1, comp_piececolour);
            store(1, i+1);
        elseif j - length(move_status(i+1)) = 1 then
            tryadd(i+1, badmoves) -> foundMove;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findThreeRightDiag_Rule3 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following right diagonal pattern:
                piece-piece-space-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findThreeRightDiag_Rule3(i, j, who, badmoves) -> foundMove;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j+1) = who
    and full_status(i+2)(j+2) = 0 and full_status(i+3)(j+3) = who then
        if (j+1) - length(move_status(i+2)) = 0 then
            true -> foundMove;
            move(i+2, comp_piececolour);
            store(1, i+2);
        elseif (j+1) - length(move_status(i+2)) = 1 then
            tryadd(i+2, badmoves) -> foundMove;
        endif;
    endif;
enddefine;




/*
PROCEDURE: findThreeLeftDiag_Rule (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following left diagonal pattern:
                space-piece-piece-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findThreeLeftDiag_Rule(i, j, who, badmoves) -> foundMove;
    badmoves -> foundMove;
    if full_status(i)(j) = 0 and full_status(i+1)(j-1) = who
    and full_status(i+2)(j-2) = who and full_status(i+3)(j-3) = who then
        if (j-1) - length(move_status(i)) = 0 then
            true -> foundMove;
            move(i, comp_piececolour);
            store(1, i);
        elseif (j-1) - length(move_status(i)) = 1 then
            tryadd(i, badmoves) -> foundMove;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findThreeLeftDiag_Rule1 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following left diagonal pattern:
                piece-piece-piece-space
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findThreeLeftDiag_Rule1(i, j, who, badmoves) -> foundMove;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j-1) = who
    and full_status(i+2)(j-2) = who and full_status(i+3)(j-3) = 0 then
        if (j-2) - length(move_status(i+3)) = 2 then
            true -> foundMove;
            move(i+3, comp_piececolour);
            store(1, i+3);
        elseif (j-2) - length(move_status(i+3)) = 3 then
            tryadd(i+3, badmoves) -> foundMove;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findThreeLeftDiag_Rule2 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following left diagonal pattern:
                piece-space-piece-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findThreeLeftDiag_Rule2(i, j, who, badmoves) -> foundMove;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j-1) = 0
    and full_status(i+2)(j-2) = who and full_status(i+3)(j-3) = who then
        if j - length(move_status(i+1)) = 2 then
            true -> foundMove;
            move(i+1, comp_piececolour);
            store(1, i+1);
        elseif j - length(move_status(i+1)) = 3 then
            tryadd(i+1, badmoves) -> foundMove;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findThreeLeftDiag_Rule3 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following left diagonal pattern:
                piece-piece-space-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findThreeLeftDiag_Rule3(i, j, who, badmoves) -> foundMove;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j-1) = who
    and full_status(i+2)(j-2) = 0 and full_status(i+3)(j-3) = who then
        if (j-1) - length(move_status(i+2)) = 2 then
            true -> foundMove;
            move(i+2, comp_piececolour);
            store(1, i+2);
        elseif (j-1) - length(move_status(i+2)) = 3 then
            tryadd(i+2, badmoves) -> foundMove;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findTwoVertical_Rule (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following vertical pattern:
                piece-piece-space. Move.

TESTS:

*/

define findTwoVertical_Rule(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i)(j+1) = who
    and full_status(i)(j+2) = 0 then
        lookout(badmoves, i) -> moved;
        if moved == true then true -> foundMove; endif;
    endif;
enddefine;





/*
PROCEDURE: findTwoHorizontal_Rule (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following horizontal pattern:
                space-piece-piece-space
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoHorizontal_Rule(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = 0 and full_status(i+1)(j) = who
    and full_status(i+2)(j) = who and full_status (i+3)(j) = 0 then
        if j - length(move_status(i)) = 1 then
            lookout(badmoves, i) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif j - length(move_status(i+3)) = 1 then
            lookout(badmoves, (i+3)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findTwoHorizontal_Rule1 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following horizontal pattern:
                piece-space-space-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoHorizontal_Rule1(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j) = 0
    and full_status(i+2)(j) = 0 and full_status(i+3)(j) = who then
        if j - length(move_status(i+1)) = 1 then
            lookout(badmoves, (i+1)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif j - length(move_status(i+2)) = 1 then
            lookout(badmoves, (i+2)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findTwoHorizontal_Rule2 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following horizontal pattern:
                piece-space-piece-space
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoHorizontal_Rule2(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j) = 0
    and full_status(i+2)(j) = who and full_status(i+3)(j) = 0 then
        if j - length(move_status(i+1)) = 1 then
            lookout(badmoves, (i+1)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif j - length(move_status(i+3)) = 1 then
            lookout(badmoves, (i+3)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;




/*
PROCEDURE: findTwoHorizontal_Rule3 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following horizontal pattern:
                space-piece-space-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoHorizontal_Rule3(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = 0 and full_status(i+1)(j) = who
    and full_status(i+2)(j) = 0 and full_status(i+3)(j) = who then
        if j - length(move_status(i)) = 1 then
            lookout(badmoves, (i)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif j - length(move_status(i+2)) = 1 then
            lookout(badmoves, (i+2)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;




/*
PROCEDURE: findTwoHorizontal_Rule4 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following horizontal pattern:
                space-space-piece-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoHorizontal_Rule4(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = 0 and full_status(i+1)(j) = 0
    and full_status(i+2)(j) = who and full_status(i+3)(j) = who then
        if j - length(move_status(i)) = 1 then
            lookout(badmoves, (i)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif j - length(move_status(i+1)) = 1 then
            lookout(badmoves, (i+1)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;




/*
PROCEDURE: findTwoHorizontal_Rule5 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following horizontal pattern:
                piece-piece-space-space
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoHorizontal_Rule5(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j) = who
    and full_status(i+2)(j) = 0 and full_status(i+3)(j) = 0 then
        if j - length(move_status(i+2)) = 1 then
            lookout(badmoves, (i+2)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif j - length(move_status(i+3)) = 1 then
            lookout(badmoves, (i+3)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;




/*
PROCEDURE: findTwoRightDiag_Rule (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following right diagonal pattern:
                space-piece-piece-space
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoRightDiag_Rule(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = 0 and full_status(i+1)(j+1) = who
    and full_status(i+2)(j+2) = who and full_status (i+3)(j+3) = 0 then
        if (j+1) - length(move_status(i)) = 2 then
            lookout(badmoves, i) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif (j+2) - length(move_status(i+3)) = 0 then
            lookout(badmoves, (i+3)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findTwoRightDiag_Rule1 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following right diagonal pattern:
                piece-space-space-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoRightDiag_Rule1(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j+1) = 0
    and full_status(i+2)(j+2) = 0 and full_status(i+3)(j+3) = who then
        if j - length(move_status(i+1)) = 0 then
            lookout(badmoves, (i+1)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif (j+3) - length(move_status(i+2)) = 2 then
            lookout(badmoves, (i+2)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findTwoRightDiag_Rule2 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following right diagonal pattern:
                piece-space-piece-space
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoRightDiag_Rule2(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j+1) = 0
    and full_status(i+2)(j+2) = who and full_status(i+3)(j+3) = 0 then
        if j - length(move_status(i+1)) = 0 then
            lookout(badmoves, (i+1)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif (j+2) - length(move_status(i+3)) = 0 then
            lookout(badmoves, (i+3)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;




/*
PROCEDURE: findTwoRightDiag_Rule3 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following right diagonal pattern:
                space-piece-space-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoRightDiag_Rule3(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = 0 and full_status(i+1)(j+1) = who
    and full_status(i+2)(j+2) = 0 and full_status(i+3)(j+3) = who then
        if (j+1) - length(move_status(i)) = 2 then
            lookout(badmoves, (i)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif (j+3) - length(move_status(i+2)) = 2 then
            lookout(badmoves, (i+2)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findTwoRightDiag_Rule4 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following right diagonal pattern:
                space-space-piece-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoRightDiag_Rule4(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = 0 and full_status(i+1)(j+1) = 0
    and full_status(i+2)(j+2) = who and full_status(i+3)(j+3) = who then
        if (j+2) - length(move_status(i+1)) = 2 then
            lookout(badmoves, (i+1)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif (j+2) - length(move_status(i)) = 3 then
            lookout(badmoves, (i)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;




/*
PROCEDURE: findTwoRightDiag_Rule5 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following right diagonal pattern:
                piece-piece-space-space
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoRightDiag_Rule5(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j+1) = who
    and full_status(i+2)(j+2) = 0 and full_status(i+3)(j+3) = 0 then
        if (j+1) - length(move_status(i+2)) = 0 then
            lookout(badmoves, (i+2)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif (j+1) - length(move_status(i+3)) = -1 then
            lookout(badmoves, (i+3)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;




/*
PROCEDURE: findTwoLeftDiag_Rule (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following left diagonal pattern:
                space-piece-piece-space
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoLeftDiag_Rule(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = 0 and full_status(i+1)(j-1) = who
    and full_status(i+2)(j-2) = who and full_status(i+3)(j-3) = 0 then
        if (j-1) - length(move_status(i)) = 0 then
            lookout(badmoves, i) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif (j-2) - length(move_status(i+3)) = 2 then
            lookout(badmoves, (i+3)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findTwoLeftDiag_Rule1 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following left diagonal pattern:
                piece-space-space-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoLeftDiag_Rule1(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j-1) = 0
    and full_status(i+2)(j-2) = 0 and full_status(i+3)(j-3) = who then
        if j - length(move_status(i+1)) = 2 then
            lookout(badmoves, (i+1)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif (j-3) - length(move_status(i+2)) = 0 then
            lookout(badmoves, (i+2)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;





/*
PROCEDURE: findTwoLeftDiag_Rule2 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following left diagonal pattern:
                piece-space-piece-space
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoLeftDiag_Rule2(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j-1) = 0
    and full_status(i+2)(j-2) = who and full_status(i+3)(j-3) = 0 then
        if j - length(move_status(i+1)) = 2 then
            lookout(badmoves, (i+1)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif (j-2) - length(move_status(i+3)) = 2 then
            lookout(badmoves, (i+3)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;




/*
PROCEDURE: findTwoLeftDiag_Rule3 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following left diagonal pattern:
                space-piece-space-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoLeftDiag_Rule3(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = 0 and full_status(i+1)(j-1) = who
    and full_status(i+2)(j-2) = 0 and full_status(i+3)(j-3) = who then
        if (j-1) - length(move_status(i)) = 0 then
            lookout(badmoves, (i)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif (j-3) - length(move_status(i+2)) = 0 then
            lookout(badmoves, (i+2)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;




/*
PROCEDURE: findTwoLeftDiag_Rule4 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following left diagonal pattern:
                space-space-piece-piece
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoLeftDiag_Rule4(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = 0 and full_status(i+1)(j-1) = 0
    and full_status(i+2)(j-2) = who and full_status(i+3)(j-3) = who then
        if (j-2) - length(move_status(i)) = -1 then
            lookout(badmoves, (i)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif (j-2) - length(move_status(i+1)) = 0 then
            lookout(badmoves, (i+1)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;




/*
PROCEDURE: findTwoLeftDiag_Rule5 (i, j, who, badmoves) -> foundMove
INPUTS:   i, j, who, badmoves
  Where:
    i is a column number
    j is a row number
    who is one of the two players
    badmoves is a list of numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        Look for the following left diagonal pattern:
                piece-piece-space-space
                Check for desirable depth and move.
                If, though, the depth is dangerous, note it (if you hadn't
                already done so)

TESTS:

*/

define findTwoLeftDiag_Rule5(i, j, who, badmoves) -> foundMove;
    lvars moved;
    badmoves -> foundMove;
    if full_status(i)(j) = who and full_status(i+1)(j-1) = who
    and full_status(i+2)(j-2) = 0 and full_status(i+3)(j-3) = 0 then
        if (j-1) - length(move_status(i+2)) = 2 then
            lookout(badmoves, (i+2)) -> moved;
            if moved == true then true -> foundMove; endif;
        elseif (j-1) - length(move_status(i+3)) = 3 then
            lookout(badmoves, (i+3)) -> moved;
            if moved == true then true -> foundMove; endif;
        endif;
    endif;
enddefine;




/*
PROCEDURE: vertical (who, whichRule, badmoves) -> foundMove
INPUTS:   who, whichRule, badmoves
  Where:
    who is one of the two players (number)
    whichRule is one of the pattern-rules (procedure)
    badmoves is a list of column numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        To search vertically in the database(full-status) for the pattern
                specified by the whichRule(procedure). If it can't find a move
                it updates (if necessary) and returns the list of badmoves.

TESTS:

*/

define vertical(who, whichRule, badmoves) -> foundMove;
    lvars i, j;
    for i from 1 to 7 do
        for j from 1 to 3 do
            whichRule(i, j, who, badmoves) -> foundMove;
            if foundMove == true then
                return();
            else
                tryaddall(foundMove, badmoves) -> badmoves;
            endif;
        endfor;
    endfor;
    badmoves -> foundMove;
enddefine;





/*
PROCEDURE: horizontal (who, whichRule, badmoves) -> foundMove
INPUTS:   who, whichRule, badmoves
  Where:
    who is one of the two players (number)
    whichRule is one of the pattern-rules (procedure)
    badmoves is a list of column numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        To search horizontally in the database(full-status) for the pattern
                specified by the whichRule(procedure). If it can't find a move
                it updates (if necessary) and returns the list of badmoves.

TESTS:

*/

define horizontal(who, whichRule, badmoves) -> foundMove;
    lvars i, j;
    for i from 1 to 4 do
        for j from 1 to 6 do
            whichRule(i, j, who, badmoves) -> foundMove;
            if foundMove == true then
                return();
            else
                tryaddall(foundMove, badmoves) -> badmoves;
            endif;
        endfor;
    endfor;
    badmoves -> foundMove;
enddefine;





/*
PROCEDURE: rightDiagonal (who, whichRule, badmoves) -> foundMove
INPUTS:   who, whichRule, badmoves
  Where:
    who is one of the two players (number)
    whichRule is one of the pattern-rules (procedure)
    badmoves is a list of column numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        To search diagonally(to the right) in the database(full-status)
                for the pattern specified by the whichRule(procedure). If it
                can't find a move it updates (if necessary) and returns
                the list of badmoves.

TESTS:

*/

define rightDiagonal(who, whichRule, badmoves) -> foundMove;
    lvars i, j;
    for i from 1 to 4 do
        for j from 1 to 3 do
            whichRule(i, j, who, badmoves) -> foundMove;
            if foundMove == true then
                return();
            else
                tryaddall(foundMove, badmoves) -> badmoves;
            endif;
        endfor;
    endfor;
    badmoves -> foundMove;
enddefine;





/*
PROCEDURE: leftDiagonal (who, whichRule, badmoves) -> foundMove
INPUTS:   who, whichRule, badmoves
  Where:
    who is one of the two players (number)
    whichRule is one of the pattern-rules (procedure)
    badmoves is a list of column numbers
OUTPUTS:  foundMove: it can be either true, or a list of numbers(badmoves)
CREATION DATE:  25 Aug 1997
PURPOSE:        To search diagonally(to the left) in the database(full-status)
                for the pattern specified by the whichRule(procedure). If it
                can't find a move it updates (if necessary) and returns
                the list of badmoves.

TESTS:

*/

define leftDiagonal(who, whichRule, badmoves) -> foundMove;
    lvars i, j;
    for i from 1 to 4 do
        for j from 4 to 6 do
            whichRule(i, j, who, badmoves) -> foundMove;
            if foundMove == true then
                return();
            else
                tryaddall(foundMove, badmoves) -> badmoves;
            endif;
        endfor;
    endfor;
    badmoves -> foundMove;
enddefine;




/*
PROCEDURE: compulsiveMove ()
INPUTS:   NONE
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        The program is now cornered. This procedure checks if there
                are any moves considered to be bad for itself (i.e., if it
                moves there, its opponent is going to block it) and it prefers
                that over a badmove that is going to result to the opponent's
                immediate victory.

TESTS:

*/

define compulsiveMove();
    lvars i, j, minimumHarm;                                  ;;; Congratulate
    rc_message(522, 520, [' Very good! '                      ;;; the user for
            ^nullstring], 0, true, '12x24', 'DarkSlateBlue',  ;;; putting you
        'LightSteelBlue') -> ;                                ;;; in a difficult
                                                              ;;; position
    lvars badmoves = [];
    if (horizontal(1, findThreeHorizontal_Rule, badmoves)->>badmoves) == true
    or (horizontal(1, findThreeHorizontal_Rule1, badmoves)->>badmoves) == true
    or (horizontal(1, findThreeHorizontal_Rule2, badmoves)->>badmoves)  == true
    or (horizontal(1, findThreeHorizontal_Rule3, badmoves)->>badmoves)  == true
    or (rightDiagonal(1, findThreeRightDiag_Rule, badmoves)->>badmoves) == true
    or (rightDiagonal(1, findThreeRightDiag_Rule1, badmoves)->>badmoves) == true
    or (rightDiagonal(1, findThreeRightDiag_Rule2, badmoves)->>badmoves) == true
    or (rightDiagonal(1, findThreeRightDiag_Rule3, badmoves)->>badmoves) == true
    or (leftDiagonal(1, findThreeLeftDiag_Rule, badmoves)->>badmoves) == true
    or (leftDiagonal(1, findThreeLeftDiag_Rule1, badmoves)->>badmoves) == true
    or (leftDiagonal(1, findThreeLeftDiag_Rule2, badmoves)->>badmoves) == true
    or (leftDiagonal(1, findThreeLeftDiag_Rule3, badmoves)->>badmoves) == true
    or (vertical(1, findThreeVertical_Rule, badmoves)->>badmoves)  == true then
        return();
    else
        if badmoves == [] then
            for i from 1 to 7 do
                for j from 1 to 6 do                    ;;; If you have no
                    if full_status(i)(j) = 0 then       ;;; three-piece patterns
                        move(i, comp_piececolour);      ;;; to sacrifice, move
                        store(1, i);                    ;;; anywhere
                        quitloop(2);
                    endif;
                endfor;
            endfor;
        else                                            ;;; Otherwise
            hd(badmoves) -> minimumHarm;                ;;; Move to the first
            move(minimumHarm, comp_piececolour);        ;;; pattern of your own
            store(1, minimumHarm);                      ;;; that you 'll find
        endif;
    endif;
enddefine;




/*
PROCEDURE: findSafeMove (badmoves)
INPUTS:   badmoves is a list of column-numbers
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        Provides five book-moves. The first whose conditions are
                satisfied, is made.
TESTS:

*/

define findSafeMove(badmoves);
    lvars i, j, moved;
    for i from 1 to 6 do
        for j from 1 to 6 do                    ;;; Move to your left
            if full_status(i+1)(j) = 1 then
                if full_status(i)(j) = 0 then
                    lookout(badmoves, i) -> moved;
                    if moved == true then return(); endif;
                endif;
            endif;
        endfor;
    endfor;
    for i from 1 to 7 do
        for j from 1 to 5 do                    ;;; Move on top of your piece
            if full_status(i)(j) = 1 then
                if full_status(i)(j+1) = 0 then
                    lookout(badmoves, i)-> moved;
                    if moved == true then return(); endif;
                endif;
            endif;
        endfor;
    endfor;
    for i from 1 to 6 do
        for j from 1 to 6 do                    ;;; Move to your opponent's left
            if full_status(i+1)(j) = 2 then
                if full_status(i)(j) = 0 then
                    lookout(badmoves, i) -> moved;
                    if moved == true then return(); endif;
                endif;
            endif;
        endfor;
    endfor;
    for i from 1 to 7 do
        for j from 1 to 5 do                    ;;; Move on top of your opponent
            if full_status(i)(j) = 2 then
                if full_status(i)(j+1) = 0 then
                    lookout(badmoves, i) -> moved;
                    if moved == true then return(); endif;
                endif;
            endif;
        endfor;
    endfor;
    for i from 1 to 7 do
        for j from 1 to 6 do                    ;;; Move anywhere available
            if full_status(i)(j) = 0 then
                lookout(badmoves, i) -> moved;
                if moved == true then return(); endif;
            endif;
        endfor;
    endfor;

    if moved == false then
        compulsiveMove();
    endif;
enddefine;




/*
PROCEDURE: cutoff (badmoves)
INPUTS:   badmoves is a list of column-numbers
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        To find the opponent's two-piece-patterns and cut them off (move in).

TESTS:

*/

define cutoff(badmoves);
    if (horizontal(2, findTwoHorizontal_Rule, badmoves)->>badmoves) == true
    or (horizontal(2, findTwoHorizontal_Rule1, badmoves)->>badmoves) == true
    or (horizontal(2, findTwoHorizontal_Rule2, badmoves)->>badmoves) == true
    or (horizontal(2, findTwoHorizontal_Rule3, badmoves)->>badmoves) == true
    or (horizontal(2, findTwoHorizontal_Rule4, badmoves)->>badmoves) == true
    or (horizontal(2, findTwoHorizontal_Rule5, badmoves)->>badmoves) == true
    or (rightDiagonal(2, findTwoRightDiag_Rule, badmoves)->>badmoves) == true
    or (rightDiagonal(2, findTwoRightDiag_Rule1, badmoves)->>badmoves) == true
    or (rightDiagonal(2, findTwoRightDiag_Rule2, badmoves)->>badmoves) == true
    or (rightDiagonal(2, findTwoRightDiag_Rule3, badmoves)->>badmoves) == true
    or (rightDiagonal(2, findTwoRightDiag_Rule4, badmoves)->>badmoves) == true
    or (rightDiagonal(2, findTwoRightDiag_Rule5, badmoves)->>badmoves) == true
    or (leftDiagonal(2, findTwoLeftDiag_Rule, badmoves)->>badmoves) == true
    or (leftDiagonal(2, findTwoLeftDiag_Rule1, badmoves)->>badmoves) == true
    or (leftDiagonal(2, findTwoLeftDiag_Rule2, badmoves)->>badmoves) == true
    or (leftDiagonal(2, findTwoLeftDiag_Rule3, badmoves)->>badmoves) == true
    or (leftDiagonal(2, findTwoLeftDiag_Rule4, badmoves)->>badmoves) == true
    or (leftDiagonal(2, findTwoLeftDiag_Rule5, badmoves)->>badmoves) == true
    or (vertical(2, findTwoVertical_Rule, badmoves)->>badmoves) == true then
        return();
    else
        findSafeMove(badmoves);
    endif;
enddefine;




/*
PROCEDURE: advance (badmoves)
INPUTS:   badmoves is a list of column-numbers
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        To find its own two-piece-patterns and advance (move in).

TESTS:

*/

define advance(badmoves);
    if (horizontal(1, findTwoHorizontal_Rule, badmoves)->>badmoves) == true
    or (horizontal(1, findTwoHorizontal_Rule1, badmoves)->>badmoves) == true
    or (horizontal(1, findTwoHorizontal_Rule2, badmoves)->>badmoves) == true
    or (horizontal(1, findTwoHorizontal_Rule3, badmoves)->>badmoves) == true
    or (horizontal(1, findTwoHorizontal_Rule4, badmoves)->>badmoves) == true
    or (horizontal(1, findTwoHorizontal_Rule5, badmoves)->>badmoves) == true
    or (rightDiagonal(1, findTwoRightDiag_Rule, badmoves)->>badmoves) == true
    or (rightDiagonal(1, findTwoRightDiag_Rule1, badmoves)->>badmoves) == true
    or (rightDiagonal(1, findTwoRightDiag_Rule2, badmoves)->>badmoves) == true
    or (rightDiagonal(1, findTwoRightDiag_Rule3, badmoves)->>badmoves) == true
    or (rightDiagonal(1, findTwoRightDiag_Rule4, badmoves)->>badmoves) == true
    or (rightDiagonal(1, findTwoRightDiag_Rule5, badmoves)->>badmoves) == true
    or (leftDiagonal(1, findTwoLeftDiag_Rule, badmoves)->>badmoves) == true
    or (leftDiagonal(1, findTwoLeftDiag_Rule1, badmoves)->>badmoves) == true
    or (leftDiagonal(1, findTwoLeftDiag_Rule2, badmoves)->>badmoves) == true
    or (leftDiagonal(1, findTwoLeftDiag_Rule3, badmoves)->>badmoves) == true
    or (leftDiagonal(1, findTwoLeftDiag_Rule4, badmoves)->>badmoves) == true
    or (leftDiagonal(1, findTwoLeftDiag_Rule5, badmoves)->>badmoves) == true
    or (vertical(1, findTwoVertical_Rule, badmoves)->>badmoves) == true then
        return();
    else
        cutoff(badmoves);
    endif;
enddefine;




/*
PROCEDURE: block (badmoves)
INPUTS:   badmoves is a list of column-numbers
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        To find the opponent's three-piece-patterns and
                block them (move in).

TESTS:

*/

define block(badmoves);
    if (horizontal(2, findThreeHorizontal_Rule, badmoves)->>badmoves) == true
    or (horizontal(2, findThreeHorizontal_Rule1, badmoves)->>badmoves) == true
    or (horizontal(2, findThreeHorizontal_Rule2, badmoves)->>badmoves)  == true
    or (horizontal(2, findThreeHorizontal_Rule3, badmoves)->>badmoves)  == true
    or (rightDiagonal(2, findThreeRightDiag_Rule, badmoves)->>badmoves) == true
    or (rightDiagonal(2, findThreeRightDiag_Rule1, badmoves)->>badmoves) == true
    or (rightDiagonal(2, findThreeRightDiag_Rule2, badmoves)->>badmoves) == true
    or (rightDiagonal(2, findThreeRightDiag_Rule3, badmoves)->>badmoves) == true
    or (leftDiagonal(2, findThreeLeftDiag_Rule, badmoves)->>badmoves) == true
    or (leftDiagonal(2, findThreeLeftDiag_Rule1, badmoves)->>badmoves) == true
    or (leftDiagonal(2, findThreeLeftDiag_Rule2, badmoves)->>badmoves) == true
    or (leftDiagonal(2, findThreeLeftDiag_Rule3, badmoves)->>badmoves) == true
    or (vertical(2, findThreeVertical_Rule, badmoves)->>badmoves)  == true then
        return();
    else
        advance(badmoves);
    endif;
enddefine;




/*
PROCEDURE: computerMove ()
INPUTS:   NONE
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        To find its own three-piece-patterns and win (move in).

TESTS:

*/

define computerMove();
    lvars badmoves = [];
    if (horizontal(1, findThreeHorizontal_Rule, badmoves)->>badmoves) == true
    or (horizontal(1, findThreeHorizontal_Rule1, badmoves)->>badmoves) == true
    or (horizontal(1, findThreeHorizontal_Rule2, badmoves)->>badmoves)  == true
    or (horizontal(1, findThreeHorizontal_Rule3, badmoves)->>badmoves)  == true
    or (rightDiagonal(1, findThreeRightDiag_Rule, badmoves)->>badmoves) == true
    or (rightDiagonal(1, findThreeRightDiag_Rule1, badmoves)->>badmoves) == true
    or (rightDiagonal(1, findThreeRightDiag_Rule2, badmoves)->>badmoves) == true
    or (rightDiagonal(1, findThreeRightDiag_Rule3, badmoves)->>badmoves) == true
    or (leftDiagonal(1, findThreeLeftDiag_Rule, badmoves)->>badmoves) == true
    or (leftDiagonal(1, findThreeLeftDiag_Rule1, badmoves)->>badmoves) == true
    or (leftDiagonal(1, findThreeLeftDiag_Rule2, badmoves)->>badmoves) == true
    or (leftDiagonal(1, findThreeLeftDiag_Rule3, badmoves)->>badmoves) == true
    or (vertical(1, findThreeVertical_Rule, badmoves)->>badmoves)  == true then
        return();
    else
        block(badmoves);
    endif;
enddefine;




/*
PROCEDURE: connect4 ()
INPUTS:   NONE
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        Create the main panel, setting all updated(if updated!)
                values to their original(default) state.

TESTS:

*/

define connect4();

    ;;; Move_status consists of 7 empty lists, each one representing a column
    ;;; This is where the data from the game are originaly stored
    [ [] [] [] [] [] [] [] ] -> move_status;

    ;;; Full_status consists of 7 lists, each representing a colum. The list
    ;;; contain originally 6 nought each (to show the empty squares in the
    ;;; board) which are later (in the game) substituted by the game-data
    [[0 0 0 0 0 0]
        [0 0 0 0 0 0]
        [0 0 0 0 0 0]                       ;;; Empty the two
        [0 0 0 0 0 0]                       ;;; data representations
        [0 0 0 0 0 0]
        [0 0 0 0 0 0]
        [0 0 0 0 0 0]] ->full_status;

    ;;; Make the panel
    rc_control_panel(430, 180, panel_specs, 'Game Panel') -> current_panel;

    user_piececolour_def -> user_piececolour;   ;;; Set the default colours in
    comp_piececolour_def -> comp_piececolour;   ;;; the beggining of each game
    panel_depth + row(xx)*30 -> grid_bottom;    ;;; Also reset the depth of
                                                ;;; the panel
enddefine;





/*
PROCEDURE: new ()
INPUTS:   NONE
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        To end a game at any point (by killing the active window)
                and start a new one!

TESTS:          Is invoked by an action button - can't really be tested!

*/

define new();
    rc_kill_window_object(current_panel);   ;;; Kill the current GamePanel
    connect4();                             ;;; Re-load the game
enddefine;





/*
PROCEDURE: win_message (who) -> choice
INPUTS:   who is one of the two players
OUTPUTS:  choice is a the value returned form selected one of the two options
          provided in the message
CREATION DATE:  25 Aug 1997
PURPOSE:        To pop up one of two available messages, each for one of the
                two players, in the case s/he (or it!) has won.

TESTS:

*/

define win_message(who) -> choice;
;;;lvars choice;
    if who = 2 then         ;;; If the user has won, pop up this message
        rc_popup_query(
            320, 500, query2, options1, true, 2, 55, 25,
            '10x20', 'SteelBlue', 'ivory', panel_col, false) -> choice;

    else                    ;;; If it 's you who won, say something different
        rc_popup_query(
            745, 500, query3, options1, true, 2, 55, 25,
            '10x20', 'DarkSlateBlue', 'ivory', panel_col, false) -> choice;

    endif;
enddefine;





/*
PROCEDURE: draw_message ();
INPUTS:   NONE
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        To pop up a message with the option to continue the game
                or not, after a draw has been reached.

TESTS:

*/

define draw_message();
    lvars continue;
    rc_popup_query(
        528, 520, query4, options1, true, 2, 55, 25,
        '10x20', 'RosyBrown', 'ivory', panel_col, false) -> continue;

    if continue == "YES" then
        rc_kill_window_object(current_panel);
        connect4();
    else
        rc_kill_window_object(current_panel);
    endif;
enddefine;




/*
PROCEDURE: draw()-> finished
INPUTS:   NONE
OUTPUTS:  finished is a value that returns true to signify if it has
CREATION DATE:  25 Aug 1997
PURPOSE:        To look if there is no more space for another move.

TESTS:

*/

define draw() -> finished;
    if length(move_status(1)) = 6 and length(move_status(2))= 6
    and length(move_status(3))= 6 and length(move_status(4))= 6
    and length(move_status(5))= 6  and length(move_status(6))= 6
    and length(move_status(7))= 6 then
        true -> finished;
    endif;

    if finished == true then
        rc_mousepic(current_panel, false);
        draw_message();
    endif;

enddefine;



/*
PROCEDURE: win (who) -> result
INPUTS:   who is one of the two players
OUTPUTS:  result returns true (if a condtion is satisfied), false otherwise
CREATION DATE:  25 Aug 1997
PURPOSE:        To determine if someone has won or not. If yes, it provides
                with an option for another game. If the user wants to
                continue, it kills the active window and re-loads the game.
                If not, it just kills the active window.

TESTS:          Has to be tested in conjunction with some instaces of full_status.

*/

define win(who) -> result;
    lvars i, j, finished;
    for i from 1 to 7 do
        for j from 1 to 3 do
            if full_status(i)(j)=who and full_status(i)(j+1)=who
            and full_status(i)(j+2)=who and full_status(i)(j+3)=who then
                true -> result;
            endif;
        endfor;
    endfor;
    for i from 1 to 4 do
        for j from 1 to 6 do
            if full_status(i)(j)=who and full_status(i+1)(j)=who
            and full_status(i+2)(j)=who and full_status(i+3)(j)=who then
                true -> result;
            endif;
        endfor;
    endfor;
    for i from 1 to 4 do
        for j from 1 to 3 do
            if full_status(i)(j)=who and full_status(i+1)(j+1)=who
            and full_status(i+2)(j+2)=who and full_status(i+3)(j+3)=who then
                true -> result;
            endif;
        endfor;
    endfor;
    for i from 1 to 4 do
        for j from 4 to 6 do
            if full_status(i)(j)=who and full_status(i+1)(j-1)=who
            and full_status(i+2)(j-2)=who and full_status(i+3)(j-3)=who then
                true -> result;
            endif;
        endfor;
    endfor;
    if result == true then                  ;;; If someone has won then

        rc_mousepic(current_panel, false);  ;;; Make the GamePanel insensitive
                                            ;;; to mouse selection(de-activate)
        if win_message(who) == "YES" then           ;;; If the user wants
                                                    ;;; another game, then
            rc_kill_window_object(current_panel);   ;;; kill the Panel and
            connect4();                             ;;; re-load the game

        else                                        ;;; Otherwise

            rc_kill_window_object(current_panel);   ;;; just kill the Panel!

        endif;
    else
        draw()->finished;
    endif;
enddefine;




/*
PROCEDURE: col (num)
INPUTS:   num is a number which relates to one of the 7 columns of the panel
OUTPUTS:  NONE
CREATION DATE:  25 Aug 1997
PURPOSE:        This procedure is the main action-invoking process in
                the program. Every time a number is selected, it draws
                a piece for the user. In doing so, it looks at the depth
                of every column (i.e., how many pieces has it got in it),
                to calculate where the new piece should go. If the column
                is already full(i.e., has already got six pieces), nothing
                happens. Then, it checks if the user has won. If not, it
                selects a move for itself and looks if it won.

TESTS:          Can't really be tested as a single procedure, since it inolves
                interaction with the interface (the Game Panel).

*/

define col(num);
    lvars y_of_column = length_col(num), result;
    unless y_of_column >= 6 then        ;;; Carry out actions unless you reach
                                        ;;; the top of a column
        move(num, user_piececolour);    ;;; Draw a piece for the user in the
                                        ;;; column number clicked
        store(2, num);              ;;; Store 2 in your database to remember
                                    ;;; the move your opponent made!
        win(2) -> result;           ;;; Check if the user has won

        unless result == true do    ;;; If s/he has won...not much can you can
            computerMove();         ;;; do! If not, check the state of the
        endunless;                  ;;; grid. Then...Play!

        win(1) -> result;           ;;; Did you win?

    endunless;
enddefine;




/*
sysobey('xwd -name win1 > win1.xwd');
unix xv win1.xwd
connect4();
*/
