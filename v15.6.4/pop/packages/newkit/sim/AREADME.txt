$usepop/pop/packages/newkit/sim/AREADME.txt
http://www.cs.bham.ac.uk/research/projects/poplog/newkit/sim/AREADME.txt

This replaces the README file, whose old contents are below.

Since Poplog was reorganised for version 15.6, around 2005, this
package, which used to be installed separately in a $local directory
has become part of the standard Poplog distribution, and is included
in
    $usepop/pop/packages/newkit/

in the sim/ directory.

If you use it, I would be very grateful if you could send comments
and suggestions, or at least a note that you have it, to
A.Sloman@cs.bham.ac.uk

If the package is used for research or development, please acknowledge
use of the Birmingham University SimAgent toolkit. It used to be
called SIM_AGENT.

=======================================================================

If these programs are revised/extended the changes will be included
in

    http://www.cs.bham.ac.uk/research/projects/poplog/sim/help/sim_agent_news
    http://www.cs.bham.ac.uk/research/projects/poplog/prb/help/prb_news

The simulation package sim_agent normally resides in

    $usepop/pop/packages/sim

which is actually a link to

    $usepop/pop/packages/newkit/sim

         CONTENTS

 -- PRECONDITIONS
 -- CONTENTS OF THIS PACKAGE
 -- LOADING THE SIM_AGENT LIBRARY
 -- What to read

-- PRECONDITIONS

To use the SIM_AGENT toolkit you need to be fairly fluent in Pop-11.

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

The SimAgent toolkit makes use of

1. Objectclass

The package uses the objectclass library, located at

    $usepop/pop/lib/objectclass/

Which includes source code, example libraries, teaching, help, and
reference documentation.

with the main startup file in

    $usepop/pop/lib/objectclass/objectclass.p

2. Poprulebase

The SimAGent package also uses the poprulebase library. This is
normally resident in

    $usepop/pop/packages/prb/

which is actually a link to

    $usepop/pop/packages/newkit/prb/

which contains source code, example programs, and teaching, and help
files.


-- CONTENTS OF THIS PACKAGE

    sim/README
        This file

    sim/auto/
        Directory containing autoloadable files

    sim/demo/
        Directory containin demonstrations. Expected to grow
        sim/demo/rib
            The robot in a box demo prepared by Riccardo Poli and
            Aaron Sloman to illustrate a subsumption architecture

    sim/doc/
        Printable postscript papers

    sim/help/
        Directory containing help files especially
            sim/help/sim_agent_news

    sim/install_sim
        Shell script to install links to local libraries and build
        indexes

    sim/lib/
        Directory containing files to be loaded via "lib" or "uses"

    sim/mksim
        Shell script to build a saved image with the library
        precompiled.

    sim/mktarfile
        Shell script to build tar file

    sim/ref/
        Directory for REF files, when available.

    sim/simlib.p
        Pop-11 program to set up extensions to the Poplog search lists
        for autoloadable, library, and documentation files. Loading this
        does not load the full package: it merely makes the directories
        browsable.

    sim/teach/
        Directory containing teach files

    sim/test/
        Directory containing test files. Can probably be removed.


-- LOADING THE SIM_AGENT LIBRARY

Because you cannot use SimAgent without poprulebase, you need two
commands:

    uses prblib
    uses simlib

or give a single command that achieves both:

    uses newkit

Otherwise try
    load $usepop/pop/packages/newkit/newkit.p

The above commands should compile prblib.p and simlib.p, which
extend the search lists for HELP, TEACH, SHOWLIB, LIB, USES, etc.

Then do
    lib sim_agent

This will load the main sim_agent procedures. Some of the
autoloadable extensions included in sim/auto/ may not be loaded by
this, to save initial compilation time.

If objectclass and poprulebase had not previously been compiled the
libraries will be compiled by that command.

The script
    $usepop/pop/packages/sim/mksim

can create a saved image including SimAgent, poprulebase, etc., to
save compilation time. This used to be more useful in the days when
computers were much slower.

-- What to read

After compiling simlib.p try

    TEACH SIM_AGENT
    HELP SIM_AGENT
    TEACH SIM_DEMO

Also
    TEACH RULEBASE
    TEACH POPRULEBASE
    HELP POPRULEBASE

===================================================================
Old contents of $poplocal/local/sim/README

README file for the SIM_AGENT package         Aaron Sloman - Dec 18 1994

Last: updated 11 Jan 1998
Aaron Sloman, ( http://www.cs.bham.ac.uk/~axs/ )
School of Computer Science, The University of Birmingham, B15 2TT, UK
EMAIL   A.Sloman@cs.bham.ac.uk
Phone: +44-121-414-4775 (Sec 3711)       Fax:   +44-121-414-4281

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
