/*
TEACH NEWTEST.P
Temporary help file defining and demonstrationg changes
made during August and September 2002
See HELP RCLIB_NEWS

Many of the ideas came from Mark Gemmell

FIX setting of ident to initial value in SOMEOF buttons
*/

;;; give warning if some panel item still stores ident as
;;; rc_informant_value

;;;global vars panel_field_warning = true;

/*
NB
	see uses of {itemlabel <label>}

<label> can be a word, string, list or other item but not a number.

GETTING INFORMATION FROM A PANEL:
-- rc_panelcontents(<panel> <panelpath>) -> result;

<panelpath> is a list of labels or special keywords.

It can be
	[<fieldlabel>]
		returns a panel field
	[all_fields]
		returns a list of panel fields
	[<fieldlabel> <itemlabel>]
		returns an item in a panel field
	[<fieldlabel> all_items]
		returns a list of items in a panel field
	[<fieldlabel> all_values]
		returns a list of informant_values of items in a panel field
	[<fieldlabel> all_labels]
		returns a list of informant_labels of items in a panel field
	[<fieldlabel> all_true]
		returns a list of items in a panel field whose rc_informant_value
		== true (not just non-false)
	[<fieldlabel> all_false]
		returns a list of items in a panel field whose rc_informant_value
		== false
	[<fieldlabel> labels_true]
		returns a list of labels of items in a panel field whose
		rc_informant_value is non-false
	[<fieldlabel> labels_false]
		returns a list of labels of items in a panel field whose
		rc_informant_value is false


-- rc_panel_field_value(<panel> <panelpath>) -> val
   val	-> rc_panel_field_value(<panel> <panelpath>)
	returns or updates the value of an item in a panel field
	(where appropriate: may mishap in some cases, e.g. action
	buttons).
	<panelpath> is a list of labels
	It can be
		[<fieldlabel> <itemlabel>]


SETTING A PANEL ITEM: USE THE UPDATER

val  -> rc_panel_field_value(<panel> <panelpath>)
   sets the value of the panel item.

	<panelpath> is a list of labels or special keywords.

	It can be
		[<fieldlabel> <itemlabel>]
			Update informant value of the relevant item with val

		[<fieldlabel> all_items]
			Updates all items in the panel field with val. Can be used
			to make them all true, all false, or all 0, etc.

(Don't yet have a notion of re-setting default values. Still to come.)

Other cases, for turning off or turning on some or all of someof buttons.
are illustrated below.

*/


vars
	;;; Variables linked to counter and toggle buttons
	num_val = 0, test_flag = false,
	;;; Variables linked to text input and number input fields.
	;;; textin,
	textin1, textin2, numberin1,
    ;;; Variables to be associated with sliders in the panel
    Sval1, Sval2,
    ;;; Variable corresponding to a RADIO field
    the_colour = undef,
    ;;; Variable corresponding to a SOMEOF field
    all_moods = undef,
	;;; variables corresponding to three dials
	dial1, dial2, dial3,
	;;; variables holding the lines selected in scroll text fields
	poem_line1, poem_line2,
	;;; the panel
	demo_panel6,
;



define panel_reactor(pic, val);
	;;; Set output to go to a file output.p
    vededit('output.p');
	vedendfile();
    dlocal cucharout = vedcharinsert;
	0 -> pop_charout_col;
	
	[Reacting ^pic ^val]=>
enddefine;

define slider_reactor(slider,val);
	;;; a procedure to react to slider changes
    vededit('Reactor_out', vedhelpdefaults);
    vedendfile();
    dlocal cucharout = vedcharinsert;
	0 -> pop_charout_col;
    ['Slider' %rc_informant_ident(slider)% 'now set to:' ^val ]==>
enddefine;
;;; A reactor procedure to report movement of dials

define dial_reactor(dial, val);
	;;; a procedure to react to dial changes
    vededit('Reactor_out', vedhelpdefaults);
    vedendfile();
    dlocal cucharout = vedcharinsert;
    ['Dial changed:' ^(rc_informant_ident(dial)) 'New value:' ^val ] ==>
enddefine;

define demo6_field_specs() -> panel_fields;
	;;; Now specify the fields in the panel.
	lvars panel_fields=

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
        {bg 'gray75'} ;;; try other colours, e.g. 'pink', 'ivory'
        {fg 'gray20'} ;;; try {fg 'red'}

        ;;; Try uncommenting these to to change minimal size
        ;;; {width 500}
        ;;; {height 900}
        [TEXT {offset 5} {margin 0}
            {font '10x20'}
            {gap 0} :
            'Demonstration of' 'rc_control_panel'
        ]
        [ACTIONS {label actions}
			{spacing 2} {margin 1}
			{width 120} {height 20}
			{font '8x13'} {cols 0}:
			;;; {font '6x13'} {cols 0}:
        	;;; A counter button, with num_val constrained to be >= 0
        	{counter 'Counter' ^(ident num_val) {5 0}
					{textbg 'gray90' itemlabel counter1 constrain round}}
        	;;; A toggle button controlling the variable test_flag
        	{toggle 'ON/OFF' ^(ident test_flag) {itemlabel toggle1}}
			;;; a button to kill the panel
            ['KILL PANEL' rc_kill_panel {itemlabel killbutton font '10x20'}]
        ]


		[TEXT :
			'Now a multi-input field'
		]

        [TEXTIN	;;; this is a multitextin field
			;;; note a field label can be a word or a string
			;;; or list, etc. but not a number
            {label 'multitext'}
            ;;; {label [a b c]}
            ;;;{labelfont '9x15bold'}
			{font '6x13'}
			;;; offset will be adjusted if necessary
            {align left} {offset 1}
            ;;;{align centre}
            {gap 0} {margin 2}
			{spacing 3}
            {width 200} {height 22}
			{activebg 'white'}
            {fieldbg 'gray40'}:
			;;; Since there are multiple buttons, use a list for each
            [ 'Message1:'  'Hello1'
				{bg 'yellow'}
				{fg 'blue'}
				{font '10x20'}
                {labelcolour 'yellow'}
                ;;;{labelfont '9x15bold'}
				;;;{reactor ^panel_reactor}
				;;; note this label also used above:
				{itemlabel 'mess1'}
				{ident textin1}
			]

            [ 'Message2:'  'Hello2'
				{bg 'pink'}
				{fg 'blue'}
			  	{font '12x24'}
              	{labelcolour 'white'}
              	;;;{labelfont '8x13'}
			  	;;;{reactor panel_reactor}
				{itemlabel mess2}
				{ident textin2}
			]
            [ 'Number:'  55
				{bg 'gray60'}
				{fg 'blue'}
			  	{font '10x20'}
              	;;;{labelfont '9x15bold'}
              	{labelcolour 'ivory'}
			  	;;; {reactor panel_reactor}
				{ident numberin1}
			  	{itemlabel 'num1'}
			]

		]
        [TEXT
            {gap 1}
            {margin 2}  ;;; space above and below the text
            {font '8x13'} {bg 'gray90'} {fg 'black'}:
            'Move slider blobs, then try'
            'Pop-11 command:   Sval1, Sval2 =>'
        ]

        	[SLIDERS
            	;;; Label for this field
            	{label sliders}
				{align centre}
            	{gap 1} {width 300} {height 28} {margin 0}
            	{fieldbg 'pink'}
            	{barcol 'white'}    ;;; colour of slider bar
            	{radius 4}      ;;; diameter of slider blob
            	;;; try uncommenting this
            	;;; {framewidth 2} {framecol 'black'}
            	;;; try uncommenting this
            	;;; {type panel}
            	;;; Try uncommenting the following to see what difference
            	;;; it makes to the sliding blob
            	;;; {type square}
            	{spacing 4}:
            	;;; Slider, range -100 to 100 default 0, values rounded,
            	;;; value associated with variable Sval1
            	[Sval1
                	{-100 100 0} round [{-8 10 'Range -100 to 100'}]
					{itemlabel Slider1}
            	]
        		;;; The next slider has range 0 to 10 but does not round values
        		;;; its default value is 5, and changes are allowed only in
        		;;; 0.25 steps. Consequently the value will always be a decimal
        		[Sval2 {0 10 5 0.25} noround
            		;;; labels on left and right
            		['9x15bold'    ;;; override default labelfont
                		[{-8 8 'Lo Slider2'}] [{-15 10 'Hi'}]]
            		{reactor slider_reactor itemlabel ss2}
        			]
            	;;; For additional examples of sliders see
            	;;; TEACH rc_control_panel TEACH rclib_demo.p
            	;;; TEACH rc_constrained_panel
        	]

        	[TEXT
            	{font '9x15bold'}
            	{fg 'yellow'}:
            	'"Radio" buttons: choose one at a time.'
            	'Then try command: the_colour =>'
        	]

        	;;; Now some radio buttons in two columns, centred by default
        	[RADIO
            	{label radio1}
            	{cols 4} {spacing 4}
            	{margin 4} {width 55}
            	{gap 0}
            	;;; Colour for selected button
				{textfg 'black'} {textbg 'gray80'}
            	{chosenbg 'white'}
            	;;; The variable the_colour will show the selected colour
            	{ident the_colour}
            	{fieldbg 'orange'}
            	;;; The default selected value
            	{default 'blue'} :
            	'red' 'orange'  'yellow' 'green' 'blue' 'pink'
            	'black' 'white'
        	]

        	[TEXT
            	{font '10x20'}
            	{bg 'brown'} {fg 'yellow'} :
            	'"Someof" buttons.' 'Toggle them on and off'
            	'Then try: all_moods =>'
        	]

        	;;; Some "someof" buttons (toggle buttons) in two columns
        	[SOMEOF
            	{label someof1}
            	{margin 5}{cols 3} {spacing 2} {width 70}
            	{fieldbg 'orange'}
            	;;; the variable all_moods will show selected values
            	{ident all_moods}
            	;;; Colour for selected buttons
				{textfg 'black'} {textbg 'gray80'}
            	{chosenbg 'white'}
            	;;; Turn on two features by default
            	{default ['happy' 'smug']}:
            	;;; the full set of defaults
            	'happy' 'sad' 'elated' 'smug' 'angry' 'amused'
        	]

    		[DIALS
        		{label threedials}
				{align left}
				{offset 60}
        		{fieldbg 'grey95'}{spacing 5}{fieldheight 40}
        		{dialwidth 90} {dialheight 100} {dialbase 30}
        		{margin 4}{gap 3}:

        		[dial1 0 0 180 180 {0 10 5 1} 40 15 'yellow' 'blue'
            		[MARKS
                		;;; {extra radius, angular gap, mark width, length, colour}
                		{5 18 2 8 'blue'}
                		{8 90 2 10 'black'}]
            		[LABELS
                		;;; {extra radius, angular gap, initial value, increment,
                		;;;         colour font}
                		{44 18 180 -18 'red' '6x13'}
                		{20 18 0 1 'blue' '6x13'}]
            		[CAPTIONS
                		;;; {relative location, string, colour, font}
                		{-100 20 'Degrees shown in red' 'red' '9x15'}
                		{-80 40 'Values in blue' 'blue' '10x20'}]
            		{itemlabel D1}
        		]

        		;;; Offset 60 units to right of default location.
        		;;; This dial has a reactor
        		[dial2 60 -40 -90.0 180 {0 50 25 1} 40 15 ^false ^false
            		[LABELS
                		{15 36 0.0 10 'blue' '6x13'}]
            		{reactor dial_reactor
            			itemlabel D2}
        		]

        		[dial3 -10 -40 90 180 {0 50 40 1} 40 15 ^false ^false
            		[LABELS
                		{15 18 0 5 'blue' '6x13'}]
            		{itemlabel D3}
        		]
    		]

        	[SCROLLTEXT
				{rows 4} {cols 30}
				{font '9x15bold'}
            	{label scroller}
            	;;; Also try uncommenting the next line out.
            	;;; to replace the default
            	;;; {slidertype blob}
				{align left}
				;;;{align right}
				;;; experiment withis if panels don't fit in field.
				;;; {fieldheight 200}
				;;; {offset 60}
            	{fieldbg 'purple'} :
            	[ {'     THE POEM'
            		'Mary had a little lamb'
            		'Its fleece was white as snow'
            		'and everywhere that Mary went'
            		'the lamb was sure to go.'
            		'It followed her to school one day'
            		'and made the children laugh and play.'
            		'Another child had a dog,'
            		'and two of them had pet boa constrictors.'
            		'This poem rambles on and on,'
					'but only to demonstrate scrolling.'
            	 }
            	{ident poem_line1 label scroll1}
				]

            	[{'ANOTHER Poem'
            		'Suzie had a little sheep'
            		'Its fleece was red as blood'
            		'and everywhere that Mary went'
            		'she found a raging flood.'
            		'It followed her to school one day'
            		'and made the children laugh and play.'
            		'Another child had a dog,'
            		'and two of them had pet boa constrictors'
            	}
            	{ident poem_line2} {label scroll2} {rows 5} {cols 25}
				{font '6x13'}
				{bg 'yellow'} {fg 'red'}
				]

        	]

    	];

enddefine;

define ved_p6();
	rc_control_panel("right", "top", demo6_field_specs(), 'DEMO PANEL6')
		-> demo_panel6
enddefine;

;;; CREATE panel with ENTER p6, or:
ved_p6();

;;; checking  redraw method:
SETWINDOW demo_panel6
rc_start();	;;; clear (most of) panel
rc_redraw_panel(demo_panel6);

;;; Then select buttons etc and check these out

;;; counter and toggle values
num_val, test_flag =>
;;; Variables linked to text input and number input fields.
textin1, textin2, numberin1 =>

;;; Variables associated with sliders in the panel
Sval1, Sval2 =>

;;; Variables corresponding to RADIO and SOMEOF fields
the_colour,all_moods =>

;;; Variables associated with dials in the panel
dial1, dial2, dial3 =>

;;; Variables associated with scrolltext fields
;;; click on the panels to alter selected fields
;;; drag the text up and down with mouse to view hidden lines
;;; drag left and right to view hidden parts of lines.
poem_line1,newline,poem_line2 =>

;;; We can get contents of fields. Note that not all are lists
;;; (Perhaps the single text item field should be phased out)


;;; First check that we can get panel field records using their labels

;;; increase printing level for now.
3 -> pop_pr_level;

;;; Print out the field with label "actions"
rc_panelcontents(demo_panel6, [actions]) =>

;;; print items in its field contents list
applist(rc_field_contents(rc_panelcontents(demo_panel6, [actions])), npr);
;;; or alternatively, use the word "all_items" to get a list of
;;; all the items
applist(rc_panelcontents(demo_panel6, [actions all_items]), npr);

;;; the next field has a string as label, not a word
rc_panelcontents(demo_panel6, ['multitext']) =>

;;; get a list of all items in the field with label 'multitext'
rc_panelcontents(demo_panel6, ['multitext' all_items]) ==>

;;; this prints out the individual components of the multitext field:
applist(rc_panelcontents(demo_panel6, ['multitext' all_items]), npr);
;;; It is also possible to use rc_field_contents, as above.

;;; using "all_values" gives a list of values of items in the field
rc_panelcontents(demo_panel6, ['multitext' all_values]) ==>
;;; try editing the fields and repeat that, or this

	textin1, textin2, numberin1 =>

;;; Note: rc_panelcontents automatically "consolidates"
;;; edited text/number input fields.

rc_panelcontents(demo_panel6, [sliders]) =>
;;; what that returns is a slider field in the panel
datakey(rc_panelcontents(demo_panel6, [sliders])) =>

rc_panelcontents(demo_panel6, [sliders all_values]) =>

rc_panelcontents(demo_panel6, [radio1]) =>
rc_panelcontents(demo_panel6, [radio1 all_values]) =>
rc_panelcontents(demo_panel6, [radio1 all_labels]) =>
rc_panelcontents(demo_panel6, [radio1 all_true]) =>
rc_panelcontents(demo_panel6, [radio1 labels_true]) =>
rc_panelcontents(demo_panel6, [radio1 labels_false]) =>

rc_panelcontents(demo_panel6, [someof1]) =>
rc_panelcontents(demo_panel6, [someof1 all_values]) =>
rc_panelcontents(demo_panel6, [someof1 all_labels]) =>
;;; just give those that have a true value (turned on)
rc_panelcontents(demo_panel6, [someof1 all_true]) =>
rc_panelcontents(demo_panel6, [someof1 labels_true]) =>
all_moods =>
rc_panelcontents(demo_panel6, [someof1 labels_false]) =>

rc_panelcontents(demo_panel6, [threedials]) =>

rc_panelcontents(demo_panel6, [scroller]) =>

rc_field_contents(rc_panelcontents(demo_panel6, [scroller])) ==>
maplist(rc_panelcontents(demo_panel6, [scroller all_items]),datakey) ==>
rc_field_contents(rc_panelcontents(demo_panel6, [scroller])) ==>
true -> pop_pr_quotes;
rc_panelcontents(demo_panel6, [scroller all_values]) =>


;;; we can also ask for the list of all the fields of the whole panel
rc_panelcontents(demo_panel6, [all_fields]) =>

;;; This is the same as
rc_panel_fields(demo_panel6) ==>

rc_panel_fields(demo_panel6) == rc_panelcontents(demo_panel6, [all_fields]) =>

;;; Now we go a bit deeper, selecting an individual item from
;;;   the list of items in a field, using as second argument
;;;   to rc_panelcontents  a list
;;; [<fieldlabel> <itemlabel> ]

;;; Get the counter, toggle and action buttons
rc_panelcontents(demo_panel6, [actions counter1]) =>

;;; that produced a counter button, one of the contents of the
;;; actions field
datakey(rc_panelcontents(demo_panel6, [actions counter1])) =>

;;; The variable num_val is associated with that button.
;;; Use button 3 to increment, button 1 to decrement, and
;;; print this
num_val =>
rc_panelcontents(demo_panel6, [actions counter1]) =>

;;; there are two more action buttons, the first a toggle button
;;; associated with test_flag
rc_panelcontents(demo_panel6, [actions toggle1]) =>
test_flag =>
;;; Click with button 1 on the toggle button and reprint
;;; that value

;;; This button kills the whole panel if selected.
rc_panelcontents(demo_panel6, [actions killbutton]) =>

;;; Or we can get a list of all the components of the field
;;; labelled "actions"
rc_panelcontents(demo_panel6, [actions all_items]) =>
;;; we can use datakey to identify their data-types
maplist(rc_panelcontents(demo_panel6, [actions all_items]), datakey) =>


;;; The next field, with several input panels has a string as itemlabel
rc_panelcontents(demo_panel6, ['multitext' 'mess1']) =>
rc_panelcontents(demo_panel6, ['multitext' mess2]) =>
rc_panelcontents(demo_panel6, ['multitext' 'num1']) =>
rc_panelcontents(demo_panel6, ['multitext' all_items]) =>
rc_panelcontents(demo_panel6, ['multitext' all_values]) =>

;;; now sliders
rc_panelcontents(demo_panel6, [sliders Slider1]) =>
rc_panelcontents(demo_panel6, [sliders ss2]) =>
rc_panelcontents(demo_panel6, [sliders all_items]) =>
rc_panelcontents(demo_panel6, [sliders all_values]) =>
rc_panelcontents(demo_panel6, [sliders all_labels]) =>

;;; Radio buttons. One has value true, and the rest false.
rc_panelcontents(demo_panel6, [radio1 'red']) =>
rc_panelcontents(demo_panel6, [radio1 'yellow']) =>
the_colour =>
rc_panelcontents(demo_panel6, [radio1 'blue']) =>
rc_panelcontents(demo_panel6, [radio1 all_items]) ==>
rc_panelcontents(demo_panel6, [radio1 all_values]) ==>
rc_panelcontents(demo_panel6, [radio1 all_labels]) ==>
rc_panelcontents(demo_panel6, [radio1 labels_true]) ==>

;;; The someof buttons
rc_panelcontents(demo_panel6, [someof1 'happy']) =>
rc_panelcontents(demo_panel6, [someof1 'sad']) =>
;;; Use mouse button 1 to turn individual buttons on and off
;;; and print a list of the values
all_moods =>
rc_panelcontents(demo_panel6, [someof1 all_items]) =>
rc_panelcontents(demo_panel6, [someof1 all_values]) =>
rc_panelcontents(demo_panel6, [someof1 all_true]) =>
rc_panelcontents(demo_panel6, [someof1 all_false]) =>
maplist(rc_panelcontents(demo_panel6, [someof1 all_true]), rc_informant_label) =>
rc_panelcontents(demo_panel6, [someof1 labels_true]) =>
rc_panelcontents(demo_panel6, [someof1 labels_false]) =>

;;; THE DIALS

rc_panelcontents(demo_panel6, [threedials D1]) =>
rc_panelcontents(demo_panel6, [threedials D2]) =>
rc_panelcontents(demo_panel6, [threedials D3]) =>

;;; the word "all_items" can be used instead of an item label to get
;;; list of all the items that are in the field.
rc_panelcontents(demo_panel6, [threedials all_items]) ==>

;;; This is the same as
rc_field_contents(rc_panelcontents(demo_panel6, [threedials])) ==>

;;; we can also get all the values
rc_panelcontents(demo_panel6, [threedials all_values]) ==>


;;; THE SCROLLTEXT PANELS
rc_panelcontents(demo_panel6, [scroller scroll1]) =>
rc_panelcontents(demo_panel6, [scroller scroll2]) =>
;;; select different strings from those panels and print out
;;; the above again.
rc_panelcontents(demo_panel6, [scroller all_items]) ==>
maplist(rc_panelcontents(demo_panel6, [scroller all_items]), datakey) =>

;;; NOW GET INDIVIDUAL VALUES instead of ITEMS in the panel fields.
rc_panelcontents(demo_panel6, [scroller all_values]) ==>


;;; USING rc_panel_field_value TO ACCESS OR UPDATE COMPONENTS
;;; Get values for the counter and toggle buttons
rc_panel_field_value(demo_panel6, [actions counter1]) =>
rc_panel_field_value(demo_panel6, [actions toggle1]) =>

;;; setting values
;;; the value for counter1 should be rounded
4.8 -> rc_panel_field_value(demo_panel6, [actions counter1]);
88.343 -> rc_panel_field_value(demo_panel6, [actions counter1]);
num_val =>
rc_panel_field_value(demo_panel6, [actions counter1]) =>
;;; Direct assignments give values not obtainable by right
;;; clicking from default value
2 -> rc_panel_field_value(demo_panel6, [actions counter1]);
;;; note clicking with button 3 adds 5.
50 -> rc_panel_field_value(demo_panel6, [actions counter1]);
num_val =>


rc_panel_field_value(demo_panel6, [actions toggle1]) =>

;;; changing toggle value
not(test_flag) -> rc_panel_field_value(demo_panel6, [actions toggle1]);
true -> rc_panel_field_value(demo_panel6, [actions toggle1]);
test_flag =>
false -> rc_panel_field_value(demo_panel6, [actions toggle1]);
test_flag =>

;;; this should mishap, as an ordinary action button has no value
rc_panel_field_value(demo_panel6, [actions killbutton]) =>

;;; Perhaps this should mishap ????. Currently does not.
99 -> rc_panel_field_value(demo_panel6, [actions killbutton]);

;;; The next field has a string as itemlabel
;;; These instructions consolidate all the partially edited
;;; text input or number input fields
rc_panel_field_value(demo_panel6, ['multitext' 'mess1']) =>
rc_panel_field_value(demo_panel6, ['multitext' mess2]) =>
rc_panel_field_value(demo_panel6, ['multitext' 'num1']) =>
'silly' -> rc_panel_field_value(demo_panel6, ['multitext' 'mess1']);
'doggie' -> rc_panel_field_value(demo_panel6, ['multitext' mess2]);
33.255 -> rc_panel_field_value(demo_panel6, ['multitext' 'num1']);


;;; now sliders
rc_panel_field_value(demo_panel6, [sliders Slider1]) =>
rc_panel_field_value(demo_panel6, [sliders ss2]) =>

;;; this value will be rounded because of the "round" spefication.
-27.456 -> rc_panel_field_value(demo_panel6, [sliders Slider1]);
rc_panel_field_value(demo_panel6, [sliders Slider1]) =>
Sval1 =>
8.33 -> rc_panel_field_value(demo_panel6, [sliders ss2]);
Sval2 =>
8.38 -> rc_panel_field_value(demo_panel6, [sliders ss2]);
Sval2 =>
rc_panel_field_value(demo_panel6, [sliders ss2]) =>

;;; This will update the slider and trigger the reactor set up
;;; for slider labelled "ss2"
2.745 -> rc_panel_field_value(demo_panel6, [sliders ss2]);
4 -> rc_panel_field_value(demo_panel6, [sliders ss2]);

;;; This will make the slider step through a range of values.
vars x;
for x from -100 by 5 to 100 do
	x -> rc_panel_field_value(demo_panel6, [sliders Slider1]);
	syssleep(10);
endfor;			
Sval1 =>

;;; radio buttons.
rc_panel_field_value(demo_panel6, [radio1 'red']) =>
rc_panel_field_value(demo_panel6, [radio1 'yellow']) =>
the_colour =>
rc_panel_field_value(demo_panel6, [radio1 'blue']) =>
rc_panel_field_value(demo_panel6, [radio1 'green']) =>

;;; altering radio buttons
true -> rc_panel_field_value(demo_panel6, [radio1 'red']);
rc_panel_field_value(demo_panel6, [radio1 'red']) =>
false -> rc_panel_field_value(demo_panel6, [radio1 'red']);
the_colour =>
true -> rc_panel_field_value(demo_panel6, [radio1 'yellow']);
the_colour =>
true -> rc_panel_field_value(demo_panel6, [radio1 'blue']);

rc_panelcontents(demo_panel6, [radio1 all_true]) =>
;;; This will leave only one button set true, the last
true  -> rc_panel_field_value(demo_panel6, [radio1 all_items]);
the_colour =>

;;; this will make them all false
false  -> rc_panel_field_value(demo_panel6, [radio1 all_items]);
the_colour =>


;;; The someof buttons
rc_panel_field_value(demo_panel6, [someof1 'happy']) =>
rc_panel_field_value(demo_panel6, [someof1 'sad']) =>
rc_panel_field_value(demo_panel6, [someof1 'smug']) =>
all_moods =>

;;; Setting values of the someof buttons
false  -> rc_panel_field_value(demo_panel6, [someof1 'happy']);
true  -> rc_panel_field_value(demo_panel6, [someof1 'happy']);
all_moods =>
rc_panelcontents(demo_panel6, [someof1 all_true]) =>
true -> rc_panel_field_value(demo_panel6, [someof1 'sad']);
true  -> rc_panel_field_value(demo_panel6, [someof1 'elated']);
false  -> rc_panel_field_value(demo_panel6, [someof1 'elated']);
all_moods =>
rc_panelcontents(demo_panel6, [someof1 all_true]) =>
true  -> rc_panel_field_value(demo_panel6, [someof1 all_items]);
all_moods =>
false  -> rc_panel_field_value(demo_panel6, [someof1 all_items]);
all_moods =>

;;; The dials

rc_panel_field_value(demo_panel6, [threedials D1]) =>
rc_panel_field_value(demo_panel6, [threedials D2]) =>
rc_panel_field_value(demo_panel6, [threedials D3]) =>
rc_panelcontents(demo_panel6, [threedials all_values]) =>

;;; ALTERING THE DIALS
;;; note: updater of rc_informant_value does not work properly
;;; FIX XXX meanwhile use updater of rc_pointer_value
;;; or syntax below.

4 -> rc_panel_field_value(demo_panel6, [threedials D1]);
8 -> rc_panel_field_value(demo_panel6, [threedials D1]);
;;; this will round
3.25 -> rc_panel_field_value(demo_panel6, [threedials D1]);
dial1 =>
22.345 -> rc_panel_field_value(demo_panel6, [threedials D2]);
45 -> rc_panel_field_value(demo_panel6, [threedials D2]);
dial2 =>
0.333 -> rc_panel_field_value(demo_panel6, [threedials D3]);
0.533 -> rc_panel_field_value(demo_panel6, [threedials D3]);
44 -> rc_panel_field_value(demo_panel6, [threedials D3]);
dial3 =>
rc_panelcontents(demo_panel6, [threedials all_values]) =>
;;; should mishap, I suppose, but doesn.t
-44 -> rc_panel_field_value(demo_panel6, [threedials D3]);
rc_panelcontents(demo_panel6, [threedials all_values]) =>

;; they can all be set to 0
0 -> rc_panel_field_value(demo_panel6, [threedials all_items]);
rc_panelcontents(demo_panel6, [threedials all_values]) =>


;;; The scrolltext panels

rc_panel_field_value(demo_panel6, [scroller scroll1]) =>
rc_panel_field_value(demo_panel6, [scroller scroll2]) =>
true -> pop_pr_quotes;
rc_panelcontents(demo_panel6, [scroller all_values]) =>
;;; select different strings from those panels and print out
;;; the above again.

;;; ALTERING THE SCROLLTEXT PANELS

;;; Actual strings can be assigned as value (provided that they
;;; are already in the scrolling panel). Otherwise use the
;;; number of the string.
rc_panel_field_value(demo_panel6, [scroller scroll1]) =>
3-> rc_panel_field_value(demo_panel6, [scroller scroll1]);
rc_panel_field_value(demo_panel6, [scroller scroll1]) =>
'and everywhere that Mary went' -> rc_panel_field_value(demo_panel6, [scroller scroll1]);
rc_panel_field_value(demo_panel6, [scroller scroll1]) =>

;;; This unrecognized string causes a mishap
'and everywhere that Sandra went' -> rc_panel_field_value(demo_panel6, [scroller scroll1]);
;;; For inserting new strings: see rc_insert_strings_scrolltext
5-> rc_panel_field_value(demo_panel6, [scroller scroll1]);
poem_line1 =>
6-> rc_panel_field_value(demo_panel6, [scroller scroll1]);
poem_line1 =>


rc_panel_field_value(demo_panel6, [scroller scroll2]) =>
2->rc_panel_field_value(demo_panel6, [scroller scroll2]);
rc_panel_field_value(demo_panel6, [scroller scroll2]) =>
'she found a raging flood.' -> rc_panel_field_value(demo_panel6, [scroller scroll2]);
rc_panel_field_value(demo_panel6, [scroller scroll2]) =>
1->rc_panel_field_value(demo_panel6, [scroller scroll2]);
7->rc_panel_field_value(demo_panel6, [scroller scroll2]);
rc_panel_field_value(demo_panel6, [scroller scroll2]) =>
poem_line2 =>

;;; Adding new text to a scrolltext panel
;;; first get hold of the scrottext object
vars scroll2 = rc_panelcontents(demo_panel6, [scroller scroll2]);
scroll2 =>
;;; do this repeatedly to make text scroll up
rc_scrollup(scroll2);

;;; this prints out the current line, associated with pointer
;;; on left
rc_informant_value(scroll2) =>

;;; you can also scroll down left and right
rc_scrolldown(scroll2);
rc_scrollleft(scroll2);
rc_scrollright(scroll2);

;;; the 'select' slider is the one on the left
rc_slider_value(rc_scroll_select_slider(scroll2)) =>
3 ->rc_slider_value(rc_scroll_select_slider(scroll2))
5 ->rc_slider_value(rc_scroll_select_slider(scroll2))

;;; You can make it scroll to a particular row.
;;; That row becomes the first row in the window
rc_scroll_to_row(scroll2, 7);
rc_scroll_to_row(scroll2, 1);
rc_scroll_to_row(scroll2, 3);
;;; if possible the select pointer points to the same
;;; text line while scrolling, unless that line goes off
;;; the window.

;;; Adding text to a scrolltext panel
;;; use LIB rc_insert_strings_scrolltext
;;; Format
;;; rc_insert_strings_scrolltext(obj:rc_scroll_text, strings, loc, mode);
;;; strings is a new vector of strings to be inserted
;;; loc is the insert location in the old vector (an integer)
;;;  	or one of the words "start" "end"
;;; mode is one of "over", "pushup", "pushdown"
;;; "over" means overwrite existing strings. Will extend panel vector if needed.
;;; "pushup" means scroll text up to the end of required locations for new
;;;		text upwards, truncating at the top.
;;; 	only extens the vector if there's not enough space from loc to
;;;		accommodate new text
;;; "pushdown" inserts new text at loc, pushing subequent text down.
;;; 	necessarily extends the vector

;;; create some extra text to insert at the end off scroll2
vars
	vec1 = {'111111111111' '22222222222222222' '333333333333333'},
	vec2 = {'aaaaaaaaaaaa' 'bbbbbbbbbbbbb' 'ccccccccc' 'ddddddddddddd'};

vars scroll2 = rc_panelcontents(demo_panel6, [scroller scroll2]);

;;; save a copy of the original strings
vars vec = copy(rc_scroll_text_strings(scroll2));
vec ==>
rc_scroll_to_row(scroll2, 1);
;;; insert vec1 at the beginning
rc_insert_strings_scrolltext(scroll2, vec1, 1, "over");
;;; insert vec2 at the beginning
rc_insert_strings_scrolltext(scroll2, vec2, 1, "over");

;;; re-insert original
rc_insert_strings_scrolltext(scroll2, vec, 1, "over");
;;; go to the end
rc_scroll_to_row(scroll2, 9);
;;; insert vec1 at the end in "over" mode. Nothing gets pushed up
rc_insert_strings_scrolltext(scroll2, vec1, "end", "over");
;;; look at the beginning
rc_scroll_to_row(scroll2, 1);

;;; re-insert original
rc_insert_strings_scrolltext(scroll2, vec, 1, "over");
rc_scroll_to_row(scroll2, 9);
;;; insert vec1 at the end in "pushup" mode
rc_insert_strings_scrolltext(scroll2, vec1, "end", "pushup");
;;; now look at the beginning: it starts from the fourth line
rc_scroll_to_row(scroll2, 1);

rc_scroll_to_row(scroll2, 9);
;;; insert vec2 at the end in "pushup" mode
rc_insert_strings_scrolltext(scroll2, vec2, "end", "pushup");
;;; now look at the beginning: it starts from the 7th line,
;;; and only has two of the original nine lines left
rc_scroll_to_row(scroll2, 1);



;;; STUFF AFTER HERE USES EARLIER VERSIONS
;;; This may be phased out? May be too convenient?
;;; Finding out which options have been chosen
rc_options_chosen(rc_fieldcontents_of(demo_panel6, "radio1")) =>

;;; It should print the same value as
the_colour =>
;;; get a list of buttons
rc_fieldcontents_of(demo_panel6, "radio1") =>

;;; The following can be used to set the selected button:

;;; perhaps redundant (uses rc_set_radio_buttons)
rc_set_radio_panelfield('green', "radio1", demo_panel6);
the_colour =>
;;; turn them all off
rc_set_radio_panelfield("none", "radio1", demo_panel6);
the_colour =>
;;; this will mishap
rc_set_radio_panelfield("all", "radio1", demo_panel6);

rc_set_radio_panelfield('pink', "radio1", demo_panel6);
the_colour =>
rc_set_radio_panelfield('green', "radio1", demo_panel6);
rc_set_radio_panelfield('blue', "radio1", demo_panel6);

;;; another way to turn them off
rc_set_radio_buttons("none", rc_fieldcontents_of(demo_panel6, "radio1"));
;;; The latest way
false  -> rc_panel_field_value(demo_panel6, [radio1 all_items]);

;;; Another way of setting radio buttons
rc_set_radio_buttons('black', rc_fieldcontents_of(demo_panel6, "radio1"));
the_colour =>
rc_set_radio_buttons('red', rc_fieldcontents_of(demo_panel6, "radio1"));
rc_set_radio_buttons("none", rc_fieldcontents_of(demo_panel6, "radio1"));
the_colour =>


;;; The radio panel has been given an associated identifier: the_colour
;;; by default identifiers print showing their contents. They don't
;;; know their associated word!
rc_informant_ident(hd(rc_fieldcontents_of(demo_panel6, "radio1")))=>
ident the_colour =>
	

;;; another way of setting fields, using current window for drawing
;;; Some drawing commands require rc_current_window_object to be set
rc_current_window_object =>
rc_current_window_object -> demo_panel6;

;;; This is a shorthand for the above assignment:
SETWINDOW demo_panel6

'red' -> rc_options_chosen(rc_fieldcontents_of(demo_panel6, "radio1"));
rc_fieldcontents_of(demo_panel6, "radio1") ==>
'yellow' -> rc_options_chosen(rc_fieldcontents_of(demo_panel6, "radio1"));
rc_fieldcontents_of(demo_panel6, "radio1") ==>
'black' -> rc_options_chosen(rc_fieldcontents_of(demo_panel6, "radio1"));
rc_fieldcontents_of(demo_panel6, "radio1") ==>

the_colour =>


;;; THIS DOES NOT ALL WORK IGNORE FIX
;;; We can do the same for the someof field
;;; first turn off all the labels
SETWINDOW demo_panel6
[] -> rc_options_chosen(rc_fieldcontents_of(demo_panel6, "someof1"));
all_moods =>
rc_options_chosen(rc_fieldcontents_of(demo_panel6, "someof1"))=>
;;; Turn on some buttons
['happy' 'smug'] -> rc_options_chosen(rc_fieldcontents_of(demo_panel6, "someof1"));
all_moods =>
['angry'] -> rc_options_chosen(rc_fieldcontents_of(demo_panel6, "someof1"));
all_moods =>

;;;; containers
;;; a button has a field as a container
rc_button_container(rc_panelcontents(demo_panel6, [radio1 'blue'])) =>
;;; a field has a window as container
rc_field_container(
	rc_button_container(
		rc_panelcontents(demo_panel6, [radio1 'blue']))) =>


;;;; getting a button given its label
rc_button_with_label('blue', rc_fieldcontents_of(demo_panel6, "radio1")) =>
maplist(rc_panelcontents(demo_panel6, [radio1 all_items]), rc_button_label) ==>

;;;; This should cause a mishap
'purple' -> rc_options_chosen(rc_fieldcontents_of(demo_panel6, "radio1"));


SETWINDOW demo_panel6
rc_fieldcontents_of(demo_panel6, "someof1") ==>
rc_button_value(rc_fieldcontents_of(demo_panel6, "someof1")(1)) =>


rc_set_someof_buttons(['happy' 'angry'], rc_fieldcontents_of(demo_panel6, "someof1"));
rc_options_chosen(rc_fieldcontents_of(demo_panel6, "someof1")) =>
all_moods =>
rc_unset_someof_buttons(['happy' 'angry'], rc_fieldcontents_of(demo_panel6, "someof1"));
rc_options_chosen(rc_fieldcontents_of(demo_panel6, "someof1")) =>
all_moods =>
rc_unset_someof_buttons("all", rc_fieldcontents_of(demo_panel6, "someof1"));
rc_options_chosen(rc_fieldcontents_of(demo_panel6, "someof1")) =>
all_moods =>
rc_set_someof_buttons(['happy' 'angry' 'amused'], rc_fieldcontents_of(demo_panel6, "someof1"));
all_moods =>
rc_unset_someof_buttons([], rc_fieldcontents_of(demo_panel6, "someof1"));
rc_set_someof_buttons([], rc_fieldcontents_of(demo_panel6, "someof1"));

;;;; this will mishap: wrong label
rc_set_someof_buttons(['black'], rc_fieldcontents_of(demo_panel6, "someof1"));

rc_set_someof_buttons("all", rc_fieldcontents_of(demo_panel6, "someof1"));

rc_set_someof_buttons("none", rc_fieldcontents_of(demo_panel6, "someof1"));
all_moods =>
rc_unset_someof_buttons("all", rc_fieldcontents_of(demo_panel6, "someof1"));

rc_set_someof_buttons(['happy' 'angry' 'amused'], rc_fieldcontents_of(demo_panel6, "someof1"));
all_moods =>

rc_change_someof_buttons(['sad' 'smug'], rc_fieldcontents_of(demo_panel6, "someof1"));
all_moods =>

rc_options_chosen(rc_fieldcontents_of(demo_panel6, "someof1")) =>


;;; Setting everything on or everything off
true  -> rc_panel_field_value(demo_panel6, [someof1 all_items]);
false  -> rc_panel_field_value(demo_panel6, [someof1 all_items]);
rc_set_someof_panelfield("all", "someof1", demo_panel6);
all_moods =>
rc_unset_someof_panelfield(['happy' 'smug'], "someof1", demo_panel6);
all_moods =>

rc_unset_someof_panelfield("all", "someof1", demo_panel6);
all_moods =>


--- $poplocal/local/rclib/teach/newtest.p
--- Copyright University of Birmingham 2002. All rights reserved.
