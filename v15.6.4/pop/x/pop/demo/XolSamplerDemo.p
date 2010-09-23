/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            C.x/x/pop/demo/XolSamplerDemo.p
 > Purpose:         Sampler for the OpenLook widgetset
 > Author:          Jonathan Meyer, Dec  5 1990 (see revisions)
 > Documentation:   HELP *OPENLOOK TEACH *OPENLOOK
 > Related Files:   XolTutorial.p
 */

/*
This sampler contains at least one of each of the widgets in the OpenLook
widgetset (Xol). It is based closely on the s_sampler.c found in the
tutorial directory of examples for OpenWindows 2.0. It illustrates the
use of each of the widgets, as well as demonstrating how to achieve many
operations from Poplog. It also serves as a useful comparison between the
C and the Poplog Idiom. The Pop-11 version is more compact than its C
counterpart, and often allows more elegant solutions.

Differences between this sampler and the C one:

	o   Support for both colour and monochrome systems has been added
	o   The window layout and colours are simplified/beautified
	o   More labels have been added to describe the contents of the windows
	o   The stub widget has no graphics in it. The *XpwGraphic widget
		supports graphics operations in Poplog.
	o   The caption widget button does not activate the stub widget,
		but rotates the location of the caption text
	o   The slider changes the background of whole form, not just its parent
	o   callback output is sent to a ved buffer
	o   Varargs were used to get colours for form (using resource convertors)

*/

uses popxdemo;
uses XolDemoUtils.p;

/*************************************************************************
 * Variable Declarations
 *************************************************************************/

section ; ;;; $-xol_demo;

vars

	sampler = false,
	form,
	abbmenubutton,abbmenupane,
	controlarea, caprompt, exitbutton,
	exclusives,
	bulletinboard,
	caption,capbutton,
	footerpanel, fpprompt
	menubutton,menupane,mexclusives, mbprompt
	nonexclusives,nebutton = false,
	noticeshell,noticebox,noticetext,
	popupshell,popupbutton,popupca1,popupca2,popupfooter,
	scrollbar,
	scrolledwindow,
	slprompt, scrollinglist,  scrollinglist_items,
	slider,
	stub,
	statictext,
	text,
	textfield,tfprompt,
	titlebutton,

	form_colours,
;

constant
	macro (XOFFSET = 20, YOFFSET = 20),
;

constant swstring = '\
This text is in a\
statictext widget\
in a scrolled window.\
You can move it up \
and down or left and\
right with the\
two scrollbars.\n';


/*************************************************************************
 * Callback Handling Routines
 *************************************************************************/

define generic_callback(w, client, call);
	lvars w, client, call;
	;;; used by many widgets
	output(client, 'CALLBACK: %p');
enddefine;

define checkbox_callback(w, client, call);
	lvars w, client, call, pos;
	XptValue(w, XtN position, "short") -> pos;
	if pos == OL_LEFT then
		OL_RIGHT -> XptValue(w, XtN position, "short");
	else
		OL_LEFT -> XptValue(w, XtN position, "short");
	endif;
enddefine;

define exclusives_callback(w, client, call);
	lvars w, client, call, layout, parent;
	;;; change the orientation of the widget from horizontal to vertical

	output(client, 'Exclusives callback for button %p');
	XtParent(w) -> parent;
	XptValue(parent, XtN layoutType, "short") -> layout;

	if client == 2 and layout == OL_FIXEDROWS then
		;;; Set orientation vertical
		OL_FIXEDCOLS -> XptValue(parent, XtN layoutType, "short");
	elseif client  == 3 and layout == OL_FIXEDCOLS then
		;;; Set orientation horizontal
		OL_FIXEDROWS -> XptValue(parent, XtN layoutType, "short");
	endif;

enddefine;

define menu_select_callback(w, client, call);
	lvars w, client, call;
	output(client, 'Button %p selected');
enddefine;

define menu_unselect_callback(w, client, call);
	lvars w, client, call;
	output(client, 'Button %p unselected');
enddefine;

define nonexclusives_callback(w, client, call);
	lvars w, client, call;
	;;; Add or remove an extra button to the nonexclusives list
	unless nebutton then
		;;; create a button labeled 'Fewer'
		XtCreateManagedWidget('Fewer',
				RectButtonWidget, client, XptArgList([])) -> nebutton;
		XtAddCallback(nebutton, XtN select,
					nonexclusives_callback, nonexclusives);
		nonexclusives -> XptValue(scrollbar, XtN xRefWidget, TYPESPEC(:XptWidget));
	else
		;;; Destroy the 'Fewer' button
		XtDestroyWidget(nebutton);
		false -> nebutton;
		scrollinglist -> XptValue(scrollbar, XtN xRefWidget, TYPESPEC(:XptWidget));
	endunless;
enddefine;

define popup_notice_callback(w, client, call);
	lvars w, client, call;
	;;; Popup the Notice widget, making in emenate from the current widget
	w -> XptValue(noticebox, XtN emanateWidget, TYPESPEC(:XptWidget));
	XtPopup(noticeshell, XtGrabExclusive);
enddefine;

define notice_popdown_callback(w, client, call);
	lvars w, client, call;
	output('Notice Popdown: Exit button clicked');
	XtDestroyWidget(sampler);
enddefine;

define popup_callback(w, client, call);
	lvars w, client, call;
	;;; Make the popup window appear
	XtPopup(client, XtGrabNone);
enddefine;

define caption_callback(w, client, call);
	lvars w, client, call, alignment;
	;;; rotate between possible positions and alignments for caption
	lconstant
		alignments = [%OL_LEFT, OL_CENTER, OL_RIGHT%],
		positions = [%OL_TOP, OL_BOTTOM%];
	;;; make lists circular
	#_< alignments -> back(lastpair(alignments));
		positions -> back(lastpair(positions)); >_#
	XtUnmapWidget(client);
	XptValue(client, XtN alignment, "short") -> alignment;
	if alignment == hd(alignments) then
		fast_lmember(XptValue(client, XtN position, "short"), positions)(2)
			-> XptValue(client, XtN position, "short");
	endif;
	fast_lmember(alignment, alignments)(2) -> XptValue(client, XtN alignment, "short");
	XtMapWidget(client);
enddefine;


define scrollinglist_callback(w, client, call);
	lvars w, client, call;
	;;; Print message showing what scrolling list item is selected
	output(
		exacc :OlListItem (OlListItemPointer(call)).label,
		'Scrolling list item selected: %s'
	);
enddefine;

define scrollbar_callback(w, client, call);
	lvars w, client, call;
	;;; Used for each of the three scrollbars.
	;;; Prints out the scrollbar location

	;;; accept the new scrollbar location
	true -> exacc :OlScrollbarVerify call.ok;
	exacc :OlScrollbarVerify call.new_location,
	if client == 0 then
		'Scrollbar'
	elseif client == 1 then
		'Scrolledwindow Vertical'
	else
		'Scrolledwindow Horizontal'
	endif,
	output('%p scrollbar moved to %p');
enddefine;

define slider_callback(w, client, call);
	lvars w, client, call;
	;;; Change the background colour of the form widget
	exacc :int call -> call;
	call -> XptValue(form, XtN background);
	output(call, 'Slider moved to %p');
enddefine;

define textfield_callback(w, client, call);
	lvars w, client, call, reason;
	;;; Print out the contents of the text field, and the reason for
	;;; the callback
	exacc :OlTextFieldVerify call.string,
	exacc :OlTextFieldVerify call.reason -> reason;
	if reason == OlTextFieldReturn then
		'return'
	elseif reason == OlTextFieldPrevious then
		'previous'
	elseif reason == OlTextFieldNext then
		'next'
	else
		reason
	endif;
	output('TextField User Input (%p): %p ');
	nullstring -> XptValue(w, XtN string, TYPESPEC(:XptString));
enddefine;


/*************************************************************************
 * Code to Create widgets and set callbacks
 *************************************************************************/

define new_sampler();

	[] -> generic_widgets;
	/*
	 *  Create and Initialize all Widgets
	 */


	;;; BASEWINDOW - new application shell

	XtVaAppCreateShell('sampler', 'Demo', BaseWindowShellWidget,
			XptDefaultDisplay,
			XptVaArgList([
				{allowShellResize 0} ;;; ^false}
			])) -> sampler;

	[% if iscolour then

				{background 'skyblue'},
				{foreground 'black'}
	endif % ] -> form_colours;

	;;; FORM - container for sampler

	fast_XtVaCreateManagedWidget('form', FormWidget, sampler,
		XptVaArgList(form_colours)) -> form;

	;;; BUTTON - used to hold title
	XtVaCreateManagedWidget('OpenLook Widgets', ButtonWidget, form,
		XptVaArgList([
			% if iscolour then
				{foreground 'red'},
				{background 'skyblue'}
			endif %
			{labelJustify ^OL_CENTER}
			{xResizable ^true}
			{xAttachRight ^true}
		])) -> titlebutton;

	;;; CONTROLAREA, with a couple of buttons

	XtVaCreateManagedWidget('Control Area with Buttons: ', ButtonWidget, form,
		XptVaArgList(form_colours)) -> caprompt;

	XtVaCreateManagedWidget('controlarea', ControlAreaWidget, form,
		XptVaArgList([])) -> controlarea;

	;;; add a couple of controls:
	XtVaCreateManagedWidget('Command', OblongButtonWidget, controlarea,
		XptVaArgList([])) -> generic_widget;
	XtAddCallback(generic_widget, XtN select, generic_callback,
				'Command');

	XtVaCreateManagedWidget('Toggle', RectButtonWidget, controlarea,
		XptVaArgList([])) -> generic_widget;
	XtAddCallback(generic_widget, XtN select, generic_callback,
			'Toggle');
	XtVaCreateManagedWidget('Quit...', OblongButtonWidget, controlarea,
		XptVaArgList([
			%if iscolour then {background 'red'} endif %
		])) -> exitbutton;

	;;; NOTICE WIDGET, with a quit and a cancel button

	;;; attach callback to popup a notice when exit button is clicked:
	XtAddCallback(exitbutton, XtN select, popup_notice_callback,undef);

	;;; create the popup notice widget
	XtCreatePopupShell('notice', NoticeShellWidget,
			exitbutton, XptArgList([])) -> noticeshell;

	XptValue(noticeshell, XtN textArea, TYPESPEC(:XptWidget)) -> noticetext;
	XptValue(noticeshell, XtN controlArea, TYPESPEC(:XptWidget)) -> noticebox;

	;;; Set text for notice widget:
	'NOTICE WIDGET:\nPlease select Quit to destroy the sampler '
			-> XptValue(noticetext, XtN string, TYPESPEC(:XptString));

	;;; Create quit button:
	XtVaCreateManagedWidget('Quit', OblongButtonWidget, noticebox,
		XptVaArgList([
			%if iscolour then {background 'red'} endif %
		])) -> generic_widget;
	;;; add quit callback
	XtAddCallback(generic_widget, XtN select,
							notice_popdown_callback,noticebox);

	;;; Create cancel button:
	XtCreateManagedWidget('Cancel',OblongButtonWidget, noticebox,
		XptArgList([])) -> generic_widget;


	;;; MENU

	XtVaCreateManagedWidget('Menus and Popups: ', ButtonWidget, form,
		XptVaArgList(form_colours)) -> mbprompt;

	XtVaCreateManagedWidget('Menu Button', MenuButtonWidget, form,
		XptVaArgList([
			{pushpin ^OL_OUT}
			{labelType ^OL_STRING}
			{labelJustify ^OL_LEFT}
			{recomputeSize ^true}
		])) -> menubutton;

	XptValue(menubutton, XtN menuPane, TYPESPEC(:XptWidget)) -> menupane;

	XtVaCreateManagedWidget('exclusives', ExclusivesWidget, menupane,
		XptVaArgList([
			{layoutType ^OL_FIXEDCOLS}
			{measure 1}
		])) -> mexclusives;

	XtVaCreateManagedWidget('Button one', RectButtonWidget, mexclusives,
		XptVaArgList([])) -> generic_widget;

	XtAddCallback(generic_widget,XtN select,menu_select_callback,1);
	XtAddCallback(generic_widget,XtN unselect,menu_unselect_callback,1);

	XtVaCreateManagedWidget('Button two', RectButtonWidget, mexclusives,
		XptVaArgList([])) -> generic_widget;

	XtAddCallback(generic_widget,XtN select,menu_select_callback,2);
	XtAddCallback(generic_widget,XtN unselect,menu_unselect_callback,2);


	;;; ABBREVMENU - similar to above

	XtVaCreateManagedWidget('abbmenubutton', AbbrevMenuButtonWidget, form,
		XptVaArgList([
			% if iscolour then {background 'green'} endif %
		])) -> abbmenubutton;

	XptValue(abbmenubutton, XtN menuPane, TYPESPEC(:XptWidget)) -> abbmenupane;

	XtCreateManagedWidget('Abbreviated Menu', OblongButtonWidget,
			abbmenupane, XptArgList([])) -> generic_widget;

	XtCreateManagedWidget('Another menu button', OblongButtonWidget,
			abbmenupane, XptArgList([])) -> generic_widget;


	;;; POPUP WINDOW

	;;; We need to make some static callback records. This is fairly easy -
	;;; but remember that we need to keep a handle on them so they don't
	;;; become garbage. Hence the lconstant:

	lconstant cbacks =
		{%
			XptCallbackList([{^generic_callback 'Apply'}]),
			XptCallbackList([{^generic_callback 'Reset'}]),
			XptCallbackList([{^generic_callback 'Factory'}]),
			XptCallbackList([{^generic_callback 'Defaults'}]) %};

	XtCreateManagedWidget('Popup...', OblongButtonWidget, form,
		XptArgList([])) -> popupbutton;

	XtVaCreatePopupShell('popupshell', PopupWindowShellWidget, popupbutton,
		XptVaArgList([
			^form_colours
			{apply ^(cbacks(1))} {reset ^(cbacks(2))}
			{resetFactory ^(cbacks(3))} {setDefaults ^(cbacks(4))}
		])) -> popupshell;

	XptValue(popupshell, XtN upperControlArea, TYPESPEC(:XptWidget)) -> popupca1;
	XptValue(popupshell, XtN lowerControlArea, TYPESPEC(:XptWidget)) -> popupca2;
	XptValue(popupshell, XtN footerPanel, TYPESPEC(:XptWidget)) -> popupfooter;

	;;; Popuplate upper control area
	OL_FIXEDCOLS -> XptValue(popupca1, XtN layoutType, "short");

	XtCreateManagedWidget('Upper Control Area', ButtonWidget, popupca1,
		XptArgList([])) -> generic_widget;
	XtCreateManagedWidget('A Toggle', RectButtonWidget, popupca1,
		XptArgList([])) -> generic_widget;
	XtCreateManagedWidget('A Button', OblongButtonWidget, popupca1,
		XptArgList([])) -> generic_widget;
	XtCreateManagedWidget('tf', TextFieldWidget, popupca1,
		XptArgList([{string 'a textfield'}])) -> generic_widget;

	;;; Popuplate lower control area
	XtCreateManagedWidget('Added Button',OblongButtonWidget, popupca2,
		XptArgList([])) -> generic_widget;

	;;; Create footer text:
	XtVaCreateManagedWidget('footer', StaticTextWidget, popupfooter,
		XptVaArgList([
			^form_colours
			{borderWidth 0}
			%consXptArgPtr(XtN string, 'footer widget in popup')%
		])) -> generic_widget;

	;;; add callback to make popup shell appear when popupbutton clicked
	XtAddCallback(popupbutton, XtN select, popup_callback, popupshell);

	;;; realize popup shell - This is needed because trying to destroy
	;;; the sampler without realizing the Popup will cause a BadWindow
	;;; error.

	XtRealizeWidget(popupshell);


	;;; EXCLUSIVES with three buttons

	XtVaCreateManagedWidget('exclusives', ExclusivesWidget, form,
		XptVaArgList([{layoutType ^OL_FIXEDCOLS}])) -> exclusives;

	XtVaCreateManagedWidget('rbutton', RectButtonWidget, exclusives,
		XptVaArgList([
			%consXptArgPtr(XtN label, 'Exclusives')%
		])) -> generic_widget;

	XtAddCallback(generic_widget,XtN select,exclusives_callback, 1);

	XtVaCreateManagedWidget('Vertical', RectButtonWidget, exclusives,
		XptVaArgList([])) -> generic_widget;

	XtAddCallback(generic_widget,XtN select,exclusives_callback, 2);

	XtVaCreateManagedWidget('Horizontal', RectButtonWidget, exclusives,
		XptVaArgList([])) -> generic_widget;

	XtAddCallback(generic_widget, XtN select, exclusives_callback, 3);

	;;; BULLETINBOARD with a checkbox in it

	XtVaCreateManagedWidget('bboard', BulletinBoardWidget, form,
		XptVaArgList([
			% if iscolour then
				{background 'blue'},
				{borderColor 'yellow'}
			endif %
			{borderWidth 2}
		])) -> bulletinboard;

	;;; CHECKBOX
	XtVaCreateManagedWidget('Checkbox in Bulletinboard',
		CheckBoxWidget, bulletinboard,
		XptVaArgList([
			% if iscolour then
				{fontColor 'white'},
				{foreground 'white'}
			else
				;;; for some reason, the default foreground isn't black
				{foreground 'black'}
			endif %
		])) -> generic_widget;

	XtAddCallback(generic_widget, XtN select, checkbox_callback,undef);

	;;; TEXT
	vars red_pixel = XptValue(exitbutton, XtN background);
	XtVaCreateManagedWidget('text', TextEditWidget, form,
		XptVaArgList([
			% if iscolour then {fontColor ^red_pixel} endif %
			% consXptArgPtr(XtN string, 'Text widget: edit me') %
			{height 22}
		])) -> text;

	;;; TEXTFIELD
	XtVaCreateManagedWidget('Textfield widget: click and type below',
		ButtonWidget, form,
		XptVaArgList(form_colours)) -> tfprompt;

	XtVaCreateManagedWidget('textfield', TextFieldWidget, form,
		XptVaArgList([
			% if iscolour then
				{fontColor ^red_pixel},
				{inputFocusColor 'blue'}
			endif %
		]))->textfield;

	;;; callback to verify user input:
	XtAddCallback(textfield, XtN verification, textfield_callback, undef);

	;;; FOOTERPANEL: static text and a slider widget

	XtVaCreateManagedWidget('Footer with static text and a slider',
		ButtonWidget, form,
		XptVaArgList(form_colours)) -> fpprompt;

	XtVaCreateManagedWidget('footerpanel',
		FooterPanelWidget, form,
		XptVaArgList([])) -> footerpanel;

	;;; STATICTEXT
	XtVaCreateManagedWidget('statictext', StaticTextWidget, footerpanel,
		XptVaArgList([
			% consXptArgPtr(XtN string, ' Current form background colour ')%
		])) -> statictext;

	;;; SLIDER
	XtVaCreateManagedWidget('slider', SliderWidget, footerpanel,
		XptVaArgList([
			{orientation ^OL_HORIZONTAL}
			{sliderMax ^(2**screen_depth)}
			{granularity 1}
		])) -> slider;

	XtAddCallback(slider,XtN sliderMoved, slider_callback,undef);

	;;; NONEXCLUSIVES with two buttons
	XtVaCreateManagedWidget('nonexclusives', NonexclusivesWidget, form,
		XptVaArgList([
			{layoutType ^OL_FIXEDROWS}
			{measure 1}
		])) -> nonexclusives;

	XtVaCreateManagedWidget('Nonexclusives',
		RectButtonWidget, nonexclusives, XptVaArgList([]))-> generic_widget;

	XtAddCallback(generic_widget, XtN select,generic_callback,
			'Nonexclusives callback');

	XtVaCreateManagedWidget('More',
		RectButtonWidget, nonexclusives, XptVaArgList([]))-> generic_widget;

	XtAddCallback(generic_widget,XtN select,nonexclusives_callback,
				nonexclusives);

	;;; CAPTION WIDGET
	XtVaCreateManagedWidget('A Caption Widget', CaptionWidget, form,
		XptVaArgList([
			{position ^OL_TOP}
			{alignment ^OL_CENTER}
		])) -> caption;

	XtCreateManagedWidget('Captioned Button', OblongButtonWidget, caption,
		XptArgList([])) -> capbutton;
	XtAddCallback(capbutton, XtN select, caption_callback, caption);

	;;; STUB
	XtVaCreateManagedWidget('stub',StubWidget,form,
		XptVaArgList([
			% if iscolour then {background 'blue'} endif %
			{height 60} {width 100}
		])) -> stub;

	;;; XtAddCallback(capbutton, XtN select, draw_callback, {^stub ^true});

	;;;XtAddEventHandler (stub,ExposureMask,FALSE,SimpleEventHandler,0);


	;;; SCROLLED WINDOW
	XtVaCreateManagedWidget('scrolledwindow', ScrolledWindowWidget, form,
		XptVaArgList([
			{width 150} {height 150}
			{vStepSize 20}
			{hStepSize 20}
		])) -> scrolledwindow;

	XtAddCallback(scrolledwindow, XtN vSliderMoved, scrollbar_callback, 1);
	XtAddCallback(scrolledwindow, XtN hSliderMoved, scrollbar_callback, 2);

	;;; put some text in the scrolled window
	XtVaCreateManagedWidget('statictext', StaticTextWidget, scrolledwindow,
		XptVaArgList([
			{height 150}
			% consXptArgPtr(XtN string, swstring) %
		])) -> generic_widget;

	;;; SCROLLING LIST
	XtVaCreateManagedWidget('Scrolling List: ', ButtonWidget, form,
		XptVaArgList(form_colours)) -> slprompt;

	XtVaCreateManagedWidget('scrollinglist', ScrollingListWidget, form,
		XptVaArgList([
			%consXptArgPtr(XtN title, 'ScrollingList')%
			{viewHeight 7}
		])) -> scrollinglist;


	lvars i;
	[% for i from 1 to 10 do
		'Item ' sys_>< i
	endfor; %] -> XpolListItems(scrollinglist);

	XtAddCallback(scrollinglist,XtN userMakeCurrent,scrollinglist_callback,
		undef);

	;;; SCROLLBAR attached to bottom and right side of form:

	XtVaCreateManagedWidget('scrollbar', ScrollbarWidget, form,
		XptVaArgList([
			% if iscolour then
				{background 'orange'},
				{foreground 'white'}
			endif %
			{proportionLength 1}
			{yResizable ^true}
			{yAttachBottom ^true}
			{xAttachRight ^true}
			{xVaryOffset ^true}
		])) -> scrollbar;

	XtAddCallback(scrollbar,XtN sliderMoved,scrollbar_callback, 0);

	/*
	 * Form layout specification
	 */

	lconstant
		args = XptArgList([
			{xRefWidget undef}
			{yRefWidget undef}
			{xOffset ^XOFFSET}
			{yOffset ^YOFFSET}
			{xAddWidth ^true}
			{yAddHeight ^true}
		])->,
		xref = XptSetArg(%false, args, 1%),
		yref = XptSetArg(%false, args, 2%),
		xoff = XptSetArg(%false, args, 3%),
		yoff = XptSetArg(%false, args, 4%),
		xadd = XptSetArg(%false, args, 5%),
		yadd = XptSetArg(%false, args, 6%),
	;
	define lconstant set_position(widget, xwidget, ywidget);
		lvars widget, xwidget, ywidget;
		lconstant nargs = length(args);
		xwidget -> xref();
		ywidget -> yref();
		XtSetValues(widget, args, nargs);
	enddefine;

	;;; set title bar accross top of form
	0 ->> xoff() -> yoff(); 0 ->> xadd() -> yadd();
	set_position(titlebutton,form,form);

	XOFFSET -> xoff(); YOFFSET -> yoff();
	1 ->> xadd() -> yadd();

	set_position(caprompt, form, titlebutton);
	0 -> yoff();
	set_position(controlarea,form,caprompt);
	YOFFSET -> yoff();

	set_position(mbprompt, form, controlarea);
	0 -> yoff();
	set_position(menubutton,form,mbprompt);
	set_position(abbmenubutton,menubutton,mbprompt);
	set_position(popupbutton,abbmenubutton,mbprompt);
	YOFFSET -> yoff();

	set_position(bulletinboard,form,menubutton);

	set_position(text,form,bulletinboard);

	set_position(tfprompt,form,text);
	0 -> yoff();
	set_position(textfield,form,tfprompt);
	YOFFSET -> yoff();

	set_position(fpprompt, form, textfield);
	0 -> yoff();
	set_position(footerpanel,form,fpprompt);
	YOFFSET -> yoff();

	set_position(exclusives,form,footerpanel);

	XOFFSET +20 -> xoff();
	set_position(nonexclusives,popupbutton,titlebutton);
	set_position(caption,popupbutton,nonexclusives);
	set_position(stub,popupbutton,caption);
	set_position(scrolledwindow,popupbutton,stub);

	0 -> yoff(); 0 -> xadd(); 0 -> xoff();
	set_position(slprompt,scrollinglist,stub);
	YOFFSET+1 -> yoff(); 1 -> xadd(); XOFFSET + 20 -> xoff();
	set_position(scrollinglist,scrolledwindow,stub); ;;; slbutton2);
	0 -> yoff();

	set_position(scrollbar,scrollinglist,titlebutton);


	XtRealizeWidget(sampler);
enddefine;

lvars sampler_init_done = false;
define init_sampler();
	returnif(sampler_init_done);
	new_demomenu_entry('Widget Sampler', #_<identof("sampler")>_#,new_sampler);
	true -> sampler_init_done;
enddefine;

if toplevel then
	;;; we are already running the demo, so make the sampler
	init_sampler()
else
	;;; make the sampler when we call XolDemo
	XolDemo <> init_sampler -> XolDemo;
endif;

endsection;

/* --- Revision History ---------------------------------------------------
--- Robert John Duncan, Aug  7 1992
		Uses TextEditWidget rather than the obsolete TextWidget
--- Adrian Howard, Feb 20 1992 : Now uses -OlListItemPointer- in appropriate
		places.
--- Adrian Howard, Oct 31 1991 : Changed to use -XptArgPtr-
--- Integral Solutions Ltd, Oct 22 1991 (Julian Clinton)
	Changed >< to sys_><.
--- Jonathan Meyer, Jun 28 1991
		Changed to use XpolListItems
--- Jonathan Meyer, Jun  5 1991
		Fixed for new XpolListItem structure
--- Jonathan Meyer, Feb  7 1991 fixed bug that made XtDestroyWidget(sampler)
	break - by adding call to XtRealizeWidget(popupshell). Obviously popups
	aren't realized unless XtRealizeWidget is called explicitly or the window
	is popped up.
--- Roger Evans, Feb  7 1991 changed XptPopString to XptString
--- Jonathan Meyer, Feb  6 1991 Changed XptOl to Xpol
--- Roger Evans, Feb  5 1991 changed XptValue coercion specifications
--- Jonathan Meyer, Jan 29 1991
		Changed notes at top, and simplified scrollbar callback.
		Made lconstant cbrecs, using XptCallbackList
 */
