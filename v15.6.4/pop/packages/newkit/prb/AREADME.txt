$usepop/pop/packages/newkit/prb/AREADME.txt
http://www.cs.bham.ac.uk/research/projects/poplog/newkit/prb/AREADME.txt

This replaces the README file. If you find one in the same
directory as this file, please ignore it, and read only this file
(AREAME.txt).

Since Poplog was reorganised for version 15.6, around 2005, this
package, which used to be installed separately in a $local directory
has become part of the standard Poplog distribution, and is included
in
    $usepop/pop/packages/newkit/

in the prb/ directory.

===================================================================
EXTRACT FROM HELP POPRULEBASE

Poprulebase is a very flexible package supporting the construction
of single-threaded or multi-threaded mechanisms driven by
condition-action rules, which may invoke or interact with other
sorts of mechanisms. It is the core of the SimAgent toolkit.

Poprulebase extends the programming language Pop-11 to provide a
powerful and flexible forward chaining system for specifying and running
sets of condition-action rules, including conditions and actions with
interfaces to conventional procedural programs, and also to
"sub-symbolic" mechanisms such as neural nets.

Poprulebase forms the "core" of the SimAgent toolkit but can be used
independently of the remainder of the toolkit. The toolkit provides
further mechanisms for defining classes of interacting objects and
agents, some of which have complex internal mechanisms implemented using
poprulebase. Within the toolkit there is support for (simulated)
parallel execution of different rulesets (multi-threading), both within
a single agent, and also in different coexisting agents.

Poprulebase can be combined with the RCLIB package for creating 2-D
graphical interfaces supporting menus, sliders, dials, text input,
moving objects and various kinds of graphical interaction with running
programs. This is done in some of the graphical extensions to SimAgent.

However Poprulebase can also be used on its own with a purely textual
interface, or in connection with other kinds of graphical interfaces
provided that the host language Pop-11 supports them or can connect to
them.

The windows version of poplog does not yet support graphics. But
poprulebase will work in it.

An introduction to the SimAgent toolkit can be found in a file included
with the toolit, TEACH * SIM_AGENT, also accessible at this Web
site:

    http://www.cs.bham.ac.uk/research/poplog/sim/teach

along with additional "TEACH" files.

For more information see

    http://www.cs.bham.ac.uk/research/projects/poplog/packages/simagent.html


===================================================================

This package is freely available and may be used for any purpose,
though there are no warranties as to fitness for purpose. If you use
it, I would be very grateful if you could send comments and
suggestions, or at least a note that you have it, to
A.Sloman@cs.bham.ac.uk

If the package is used for research or development, please acknowledge
use of the Birmingham University Poprulebase toolkit. It is part of
the SimAgent toolkit, which used to be called SIM_AGENT.

=======================================================================

If these programs are revised/extended the changes will be announced
in

    http://www.cs.bham.ac.uk/research/projects/poplog/sim/help/sim_agent_news
    http://www.cs.bham.ac.uk/research/projects/poplog/prb/help/prb_news

===================================================================

The Poprulebase package normally resides in this Poplog directory:

    $usepop/pop/packages/prb

which is actually a link to

    $usepop/pop/packages/newkit/prb

The Pop-11 file prblib.p in that directory, is invoked by the
Pop-11 command

    uses prblib

It is used to extend the library search lists so that the relevant
prb sub-directories are added to popautolist, popuseslist,
vedhelplist, vedteachlist, etc.

===================================================================

Further information about the SimAgent library installed in
    $usepop/pop/packages/sim/
linked to
    $usepop/pop/packages/newkit/sim/

is in the file

    $usepop/pop/packages/newkit/sim/AREADME.txt

===================================================================

    CONTENTS

 -- PRECONDITIONS
 -- CONTENTS OF THIS PACKAGE

-- PRECONDITIONS

To use the Poprulebase tools you need to be fairly fluent in Pop-11.

This is not a toy system for absolute beginners, though it could be
used to build one.

For more on Pop-11 see

    http://www.cs.bham.ac.uk/research/projects/poplog/primer/
        The Pop-11 Primer, avaiable in html or PDF
    http://www.cs.bham.ac.uk/research/projects/poplog/freepoplog.html
    http://www.cs.bham.ac.uk/research/projects/poplog/poplog.info.html
    http://www.poplog.cs.reading.ac.uk/poplog

    http://en.wikipedia.org/wiki/Poplog
    http://en.wikipedia.org/wiki/Pop-11
    http://en.wikipedia.org/wiki/POP-2

And the teaching materials mentioned here:

    http://www.cs.bham.ac.uk/research/projects/poplog/freepoplog.html#teaching

Poprulebase makes use of

1. The Pop-11 pattern matcher

    TEACH MATCHES
    HELP MATCHES
    HELP READPATTERN

2. Properties (each database is stored in a property (hash table),
as a collection of lists.

See
    HELP PROPERTIES
    HELP NEWPROPERTY


Note:

The SimAGent package also uses the poprulebase library. This is
normally resident in

    $usepop/pop/packages/sim/

which is actually a link to

    $usepop/pop/packages/newkit/sim/

which contains source code, example programs, and teaching, and help
files.

-- CONTENTS OF THIS PACKAGE

    prb/AREADME.txt
        This file

    prb/include/
        Directory containing *.ph files for use in macros and
        syntax words.

    prb/auto/
        Autoloadable extensions to Poprulebase. Accessible only after
        compiling prblib.p


    prb/lib/
        Non-autoloadable library files (need the "lib" or "uses"
        command.)


    prb/prblib.p

        Makes the libraries accessible to pop-11 users.
        If this directory is installed somewhere other than
            $usepop/pop/packages/prb/prblib.p
        or
            $usepop/pop/packages/newkit/prb/prblib.p

        then something went wrong with the installation, but
        it can still be compiled using its full path name.

        priblib.p is a Pop-11 program to set up extensions to the
        Poplog search lists for autoloadable, library, and
        documentation files. Loading this does not load the full
        package: it merely makes the directories browsable. It may
        compile an additional startup file.

    prb/test/
        Contains some test programs used for development and testing of
        the system. Delete if unwanted.

    prb/teach/
        Tutorial introductions and examples

    prb/help/
        Directory containing help files especially
            prb/help/prb_news

    prb/ref/
        Directory for REF files, when available. (Not yet written)

    prb/junk
        If this exists, that's a mistake in the distribution. Please
        delete it.

OTHER FILES
    prb/AREADME.txt
        This file

    prb/mkprb
        Shell script to build a saved image with the Poprulebase
        library precompiled.

        It creates a saved image $poplocalbin/prb.psv
        containing objectclass and poprulebase, along with some VED
        tailoring files. (Some may not be needed)

        Remove the objectclass and/or ved instructions if desired.

    prb/mktarfile
        Shell script for making tar file in the directory above this
        one. Check that you don't already have a file called ../prbtar
        that you want preserved. Can be used to make a tar file of this
        directory


===================================================================
This package is freely available to anyone who has a version of Poplog
which supports the current sim_agent facilities (i.e. Poplog version
15.0 or later).

If you obtain it, and especially if you use it, I would be very grateful
if you could send comments and suggestions, or at least a note that you
have it, to A.Sloman@cs.bham.ac.uk

If the package is used for research or development, please acknowledge
use of the Birmingham University SIM_AGENT toolkit.

=======================================================================

The rest of the old file has been merged into the new instructions,
above.

Aaron Sloman
4 Jul 2009
