$usepop/pop/packages/rclib/AREADME.txt
RC_GRAPHIC EXTENSIONS TO POP-11
Aaron Sloman
Last Updated 4 Jul 2009
School of Computer Science, The University of Birmingham
http://www.cs.bham.ac.uk/~axs/


CONTENTS

 -- Overview
 -- If using a PC running Windows
 -- There are several demonstration libraries
 -- The rcmenu package
 -- The main RCLIB documentation files
 -- Installing the package
 -- -- Installation in $poplocal/local
 -- -- Installation anywhere else
 -- -- Exploring the system, after installation
 -- Other facilities available based on Propsheet
 -- Article posted to comp.lang.pop 16 jan 1997
 -- Article posted 18 April 1997

-- Overview -----------------------------------------------------------

This package contains extensions to the Pop-11 RC_GRAPHIC (Relative
Coordinate Graphic) package. It is based on Objectclass, the object
oriented extension to Pop-11 made available since the release of Poplog
Version 15.0

The package aims to make graphical interface facilities in Pop-11 (and
through it the other Poplog languages, Prolog, Common lisp, Standard ML)
independent of Motif and OpenLook, and more general than either, by
providing a range of facilities for producing static or movable, passive
or active, graphical objects of many shapes and types within a Pop-11
RC_GRAPHIC window, whilst using the relative coordinates facilities to
make programming easy.

RCLIB supports creation of windows, moving them hiding or showing them,
changing their size, adding pictures that can be moved under mouse or
program control, text fields, text-input fields, buttons of various
kinds (e.g action buttons, buttons to toggle a boolean variable, buttons
to increment or decrement a numerical variable), popup menus with a text
field and a row of answer buttons to choose from (either one, or a
subset), scrolling text panels, sliders of various kinds, movable
picture objects linked to several different windows in which they are
visible, automatically formatted control panels (approximately replacing
and superseding propsheet), etc.

Event types supported are mouse button up or down, drag, move, leave
or enter window, use of keyboard, use of modifier keys with mouse
buttons.

An introductory overview with many examples is in:
    rclib/teach/rclib_demo.p

The main replacement for propsheet (in some ways more general, but
not all propsheet facilities are supported yet) is  rc_control_panel,
described in rclib/help/rc_control_panel

Movable objects can have their movement constrained by functions you
define, so you can make a "slider", but it can be constrained to
move diagonally, on a circle, etc. not just horizontally or
vertically.

Anyone who doesn't like the collection of default styles (e.g. for
various kinds of buttons) should find it easy to copy and edit the code
to make buttons look different.

Objectclass makes it very easy to produce new sub-classes which
override the defaults, so everything is designed to be very
tailorable.

The program detects whether you are using a terminal like Suns
(where white = 0 and black = 1) or like DEC alphas (where it's the
other way round and also PCs running X I think) and automatically
decides whether to use xor or equiv for moving pictures (actually
it's a lot more complicated than that.)

At present it works only with 8 bit colour displays. I don't know what
is needed to make the colours work on 24 bit displays. Suggestions
welcome.

-- If using a PC running Windows --------------------------------------

These and other graphical facilities are not avaiable in Windows
Poplog (at least not up to July 2009 -- the situation may change).

For windows users there are several options.

1. Use a windows version of Poplog and do without the graphical
facilities. See

    http://www.cs.bham.ac.uk/research/projects/poplog/freepoplog.html#pcwinversion

If you do that you will not be able to use the Pop-11 graphical
facilities.

2. Run Linux using a 'virtual' operating system, based on vmware or
something similar. You should then be able to install poplog and run
it.

3. Use a Windows package that supports the Xwindow system
requirements for local displays, then run Pop-11 on a remote machine
running Linux or Unix which includes graphics, as described in

    http://www.cs.bham.ac.uk/research/projects/poplog/freepoplog.html#currentversions

Packages that support remote programs using graphical facilities of
the X window system include Hummingbird's eXceed, which is a
commercial product,

    http://www.cl.cam.ac.uk/local/sys/microsoft/putty-exceed/exceed.html

and Xming, which offers a free version that appears to work
perfectly (though you need to install a secure shell package, e.g.
PuTTY, Xming, and the unix/linux fonts for Xming:

    http://www.straightrunning.com/XmingNotes/

Detaied installation instructions are given here

    http://gears.aset.psu.edu/hpc/guides/xming/

Note the importance of setting PuTTY (or SSH) to do X11 forwarding,
as demonstrated there.


-- There are several demonstration libraries -------------------------

One of the demonstration libraries shows how to create a painting easel,
with a collection of coloured paint pots on one side, a collection of
brushes, to use, etc. (It would be nice to extend it so as to store the
picture produced for redisplay, but I have not yet done that.) This is
in

    rclib/demo/painting_demo.p

Another shows a lot of moving "ants" with buttons to increase or
decrease the number of ants, or quit, in

    rclib/demo/rc_ant_demo.p

The programs in the demo libraries can be examined using the
    ENTER rcdemo

command, e.g.

    ENTER rcdemo painting_demo.p
    ENTER rcdemo rc_ant_demo.p

There is a graphical version of the old Pop-11 LIB MSBLOCKS which allows
English questions and commands to be used relating to a world of red
green and blue blocks on a table, with a hand to move them around. This
is in
    rclib/lib/rc_blocks.p
    rclib/lib/rc_hand.p

A shell script is provided which can be used to create a saved image
with that demonstration already loaded. It is
    rclib/mkgblocks

It puts a saved image gblocks.psv in $poplocalbin, which can then
be run with the command
    pop11 +gblocks

or
    pop11 +gblocks %x

to use Xved.

An elaborate demonstration of rc_control_panel can be found in
    rclib/lib/rc_polypanel.p

-- The rcmenu package -------------------------------------------------

A collection of facilities is provided for creating control panels for
driving VED and doing other things. At Birmingham these can be made
avilable, after "uses rclib",  with the command

    uses rcmenulib

The rcmenu package can be fetched by FTP from:

    ftp://ftp.cs.bham.ac.uk/pub/dist/poplog/rcmenu.tar.gz

That package has its own documentation and demonstration files.

-- The main RCLIB documentation files ---------------------------------

For more information, see the online documentation designed to fit
in with the standard Poplog VED-based documentation mechanisms.

(For Emacs users an extension developed by Brian Logan and others
is available in ftp://ftp.cs.bham.ac.uk/pub/dist/poplog/emacs.tar.gz)

In particular, see these files:

help/rclib
    An overview of the Pop-11 RC_GRAPHIC libraries and the RCLIB
    extensions in this directory

help/rclib_news
    A reverse chronological listing of main changes

teach/rclib_demo.p
    A "quick" tutorial overview of most of the main facilities, with
    examples which users can run, then modify and run again. Should
    take about 30 minutes.

teach/rc_control_panel
help/rc_control_panel
    Shows how to build up complex control panels containing various
    kinds of text and button fields, sliders, images, menus, etc.

help/rc_buttons
    For an overview of button and popup creation procedures with
    lots of examples

help/rc_linepic
    For an overview of the main picture drawing and manipulating
    facilities. Describes the main event handling facilities.

teach/rc_linepic
    For a detailed collection of tutorial examples of static and
    moving and draggable picture objects.

teach/rc_async_demo
    Shows how to create control panels which asynchronously change a
    running program.

teach/popcontrol
    How to build a control panel for altering the Pop-11 compilation
    environment.

-- Installing the package ---------------------------------------------

The most convenient form of access is in $poplocal/local, especially if
the package is to be used by many people on the same system. But it is
designed to work anywhere.

-- -- Installation anywhere else

If the package is untarred into directory <dir> it will create

    <dir>/rclib

Then, to make everything accessible after running Pop-11 do

    load <dir>/rclib/rclib.p;

or
    compile('<dir>/rclib/rclib.p');

This will extend all the relevant search lists used by Pop-11 and VED so
that thereafter all the documentation and libraries are available.

-- -- Exploring the system, after installation

Try the following, for example:

    teach rclib_demo.p
        For a rapid tutorial overview

    teach rc_control_panel
    help rc_control_panel
        For a demonstration of automatically formatted control
        panel facilities.

    teach rc_linepic
        for an introduction to some of the main building blocks
        of the package

    help rc_buttons
        for an overview of the types of buttons provided

    help rc_linked_pic
        shows how to make the same picture object appear in different
        windows, with the ability to drag it in any of the windows,
        with automatic motion in the other windows.

    help rc_showtree
        A generalisation of LIB SHOWTREE, using a graphical display

    help rc_text_input
        How to use and program text input fields.

    help rclib_problems
        Possible problems regarding colours, etc.


See the other files in the help/ and teach/ subdirectories for more
information.

Some of the documentation files are still being written.

The indexes in these files may be useful:

    rclib/*/*index*

-- Other facilities available based on Propsheet ----------------------

NOTE: the popuptool and control panel facilities at Birmingham
can be used to create propsheet-based applications very easily.
They are not included in this directory. See
    ftp://ftp.cs.bham.ac.uk/pub/dist/poplog/menutar.gz


-- Article posted to comp.lang.pop 16 jan 1997 ----------------------

article: 1564 in comp.lang.pop
Path: bhamcs!news
Newsgroups: comp.lang.pop
Sender: pop-forum-local-owner@cs.bham.ac.uk
Message-ID: <5bl3hu$7v5@percy.cs.bham.ac.uk>
X-Relay-Info: Relayed through cs.bham.ac.uk MAIL->NEWS gateway
Date: 16 Jan 1997 11:31:10 GMT
Organization: cs.bham.ac.uk MAIL->NEWS gateway
Subject: new graphical and menu facilities based on RC_GRAPHIC
From: A.Sloman@cs.bham.ac.uk

Last April I announced a package of object-oriented extensions to
the Pop-11 RC_GRAPHIC library. [See below]

This made it possible to create static and moving pictures defined
declaratively (almost), with associated event handlers of various types.

This package has now been extended significantly, with bugs in the event
handling removed so that dragging works properly (thanks to help from
John Gibson) and with automatic detection of the difference between
colour handling on Suns and DEC Alphas (and maybe others) and a host of
further extensions including

    A new window object class, so that a whole RC_GRAPHIC window can be
    treated as an object, its size or location changed, hidden, exposed,
    etc. Making such an object the current one automatically makes its
    coordinate frame and other things current, so that LIB RC_CONTEXT
    becomes redundant. (I suspect I have not done this optimally: help
    welcome.)

    A much richer picture description language, including specification
    of colours for sub-pictures or individual print strings, and also
    different fonts in the same picture.

    A class of buttons, making it easy to create control panels with
    buttons for invoking arbitrary Pop-11 or unix events or process
    asynchronously (I shall eventually make this replace my previously
    announced ved_menu package based on propsheet)

    A class of constrained mover objects, which can be constrained to
    move vertically, or horizontally, or on the line between two
    specified points, etc.

    A demonstration of how to use these mechanisms in a toy "interactive
    painting" package, with mouse selectable colours and mouse
    selectable brush shapes.

This package is freely available to Poplog users from the Birmingham
Poplog ftp site

    ftp://ftp.cs.bham.ac.uk/pub/dist/poplog

Later I hope to combine it with some of the powerful image manipulating
facilities in David Young's popvision package available from Sussex.

The RCLIB package is in the rclib/ subdirectory and the complete package
is also in compressed a tar file rctar.gz, i.e. get it as
    ftp://ftp.cs.bham.ac.uk/pub/dist/poplog/rctar.gz

Other things available in that directory are described in the README
file, including a lot of AI teaching materials based on Pop-11, e.g.
in the teach/ subdirectory, the poprulebase library in the prb/
subdirectory, and the sim_agent toolkit in the sim/ subdirectory.

I hope eventually to produce new teaching materials based on sim_agent
and the rclib facilities, which will be useful for introducing students
to the design of interacting agents with various sorts of architectures,
reactive, deliberative, reflective, etc.

All offers of cooperation, suggestions for improvement, etc. welcome.

Note: "Poplog" is a trade mark of the University of Sussex.

Aaron
---
Aaron Sloman, ( http://www.cs.bham.ac.uk/~axs )
School of Computer Science, The University of Birmingham, B15 2TT, England
EMAIL   A.Sloman@cs.bham.ac.uk
Phone: +44-121-414-4775 (Sec 3711)       Fax:   +44-121-414-4281


-- Article posted 18 April 1997 ---------------------------------------
[The next message now gives a very incomplete overview. AS 29 Apr 1997]

article: 1461 in comp.lang.pop
Newsgroups: comp.lang.pop
Message-ID: <4l57hj$k7j@percy.cs.bham.ac.uk>
Date: 18 Apr 1996 11:03:15 GMT
Organization: School of Computer Science, University of Birmingham, UK
Subject: Interactive graphics extensions to rc_graphic
From: A.Sloman@cs.bham.ac.uk (Aaron Sloman)

I previously wrote
> Does anyone have any code for adding keyboard event handler to
> a graphic window?

Thanks to help from Adrian Howard and Chris Thornton I have
found out how to do that, and also to find out which modifier
keys (Contrl, Meta, Shift) are pressed when a mouse event happens.

So now I have a first draft version of my new package available for
anyone who wishes to try it out. If there is any interest, let me know
and I'll put it into a tar file in the Birmingham ftp Poplog directory.

It is an extension to rc_graphic, combined with objectclass, which has
two main components:

(a) LIB RC_LINEPIC enables you to create static or moving (including
    rotating) pictures in a Pop-11 graphical window, where picture parts
    may use different line thicknesses or line styles, and where each
    object corresponds to an objectclass instance, with associated
    methods for drawing and moving. The pictures are specified in a
    declarative notation using coordinates relative to the centre of
    the object. Drawing and un-drawing involves interpreting the
    picture specification, in an rc_graphic coordinate frame located
    at the centre of the object. Strings can be included but cannot
    be rotated. A set of mixins is provided, which can be combined with
    classes of various sorts:
         define :mixin rc_linepic;
         define :mixin rc_linepic_movable; is rc_linepic;
         define :mixin rc_rotatable; is rc_linepic_movable;

    E.g. part of a picture specification may be two rotatable squares
    using linewidth 3, slanted at an angle of 45 degrees relative to
    the object's internal frame
            [ANGLE 45 WIDTH 3 RSQUARE {5 -5 10} {0 50 20}]
    Each triple defines a square, with the first two numbers giving
    the location of the "top left" corner in the object's frame, and
    the third its side. The description language is user extendable.

(b) LIB RC_MOUSEPIC adds "mouse sensitivity" to a graphical window and
    to objects that it contains. This considerably extends the features
    provided in LIB RC_MOUSE described in TEACH RC_GRAPHIC and HELP
    RC_GRAPHIC. For example picture objects can be created which can
    then be selected for action, such as interrogating the object or
    dragging it to a new location. The following are provided
         define :mixin rc_selectable;
         define :mixin rc_keysensitive; is rc_selectable;
         define :class rc_live_window; is rc_selectable  rc_keysensitive;

    with associated methods, such as these

 define :method rc_button_1_down(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_1_down(pic:rc_live_window, x, y, modifiers);
 define :method rc_button_2_down(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_3_down(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_1_up(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_2_up(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_3_up(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_1_drag(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_1_drag(pic:rc_live_window, x, y, modifiers);
 define :method rc_button_2_drag(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_2_drag(pic:rc_live_window, x, y, modifiers);
 define :method rc_button_3_drag(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_3_drag(pic:rc_live_window, x, y, modifiers);
 define :method rc_move_mouse(pic:rc_selectable, x, y, modifiers);
 define :method rc_handle_keypress(pic:rc_selectable, x, y, modifiers, key);

If a mouse or keyboard event happens with the mouse cursor in a blank
part of the picture the event is handled by a pic:rc_live_window
method. Otherwise by the first rc_selectable object containing the
mouse location in its square of sensitivity.

Handlers can create propsheet objects, produce graphical events, drag
things, select things for subsequent action, etc. The modifiers argument
is possibly empty string containing any subset of the characters
`c`,`s`,`m`, indicating which of Control, Shift and Meta keys happens to
be down.

All objects inherit the default handlers, but individual objects can be
given specialised handlers, as can subclasses.

The library needs Poplog > V15.0 as it uses objectclass a lot, though
it should work with linux poplog if you can fit it into the available
heap space. I have not tried.

Planned extensions include much easier facilities for using propsheet to
create control panels and popup menus (more in the style of pop-11
rather than the current propsheet language).

It will be easy to add a procedure to dump the current window into
an editable text file giving a description of the objects and locations,
in a formalism that can be compiled and run to recreate the window.
So this can be used for interface design.

I don't yet have linked objects, but the existing mixins and the event
handlers should make it easy to have special attachment points, and the
fact that objects have their own coordinate frames should make things
like stretching and rotating of a link straight forward.
    [See LIB rc_polyline for some initial ideas.]

I would like to share the continued development of this package with
others, and have a common library (which could perhaps be donated to
Poplog, or at least made freely available by ftp, etc.?).

I have not yet had time to look closely enough at the GO (Graphical
Objects) library in Poplog version 15, to see what scope there is for
combining the approaches. It offers things I don't, e.g. filled objects
that partially cover other objects, etc.

All my drawing and moving of objects uses the "xor" function (except for
static objects) which occasionally produces strange effects (e.g.
unexpected colours on coloured or grey level windows). But that's the
price of the wonderful convenience "xor" offers for moving objects. I
don't want to have to handle bit maps and exposure events.
(Static rc_linepic objects are not drawn with "xor".)

Aaron
--
Aaron Sloman, ( http://www.cs.bham.ac.uk/~axs )
School of Computer Science, The University of Birmingham, B15 2TT, England
EMAIL   A.Sloman@cs.bham.ac.uk

--- $poplocal/local/rclib/README
--- Copyright University of Birmingham 2009. All rights reserved. ------
