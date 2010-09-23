$poplocal/local/com/startup/AREADME-DEMOS.txt

THIS PROVIDES A SIMPLE DEMONSTRATION OF SOME FEATURES OF POP-11 THE CORE
LANGUAGE OF THE FREE OPEN-SOURCE POPLOG[tm] SYSTEM DESCRIBED HERE:
    http://www.cs.bham.ac.uk/research/poplog/poplog-info.html
    http://www.cs.bham.ac.uk/research/poplog/primer/START.html
    http://www.cs.bham.ac.uk/research/poplog/freepoplog.html

AND THE BIMRINGHAM SIM_AGENT TOOLKIT, DESCRIBED MORE FULLY HERE:
    http://www.cs.bham.ac.uk/research/cogaff/talks/#simagent
    http://www.cs.bham.ac.uk/~axs/cogaff/simagent.html


This directory contains, among other things, three scripts for running
demos after poplog has been installed.

They may be run as follows, provided that they are run in a directory
containing a copy of the file poplog.sh created when the poplog system
was installed.

 ./run-eliza
    Run pop11 with eliza (non-serious simulation of a non-directive
    Rogerian psychotherapist).
    This will run the code in
       $poplocal/local/lib/elizaprog.p
    invoked via
       $usepop/pop/lib/auto/eliza.p

    Edit the elizaprog.p program to change the rules.

    End by typing
       bye
    or interrupt with Control-C


 ./run-eliza-nonstop
    As above except that it automatically re-starts run-eliza every
    time the program finishes.
    This means that the only way to stop this is to suspend (CTRL-Z) and
    kill the suspended process (kill %1) or kill it from another shell


 ./simagent-demo
    This starts pop11, compiles the SimAgent toolkit (located in
        $poplocal/local/newkit

    then compiles the demonstration program in

        $poplocal/local/newkit/sim/teach/sim_feelings

    then runs it.

    This produces a control panel on the left, and on the right a
    display of two moving agents, one red and one blue, each represented
    by a small square, each constantly heading for its target, a red or
    blue circle, respectively, in an environment where there are some
    obstacles that don't move. represented by green circles.

    When one of the moving agents encounters an obstacle it tries to
    veer round it but may be blocked by other obstacles.
    When it gets close to its target it sits still.

    The moving agents have crude, simple 'emotional reactions' (not to
    be taken seriously except as a programming demonstration). Each can
    have one of the following emotions

        glum, surprised, neutral, happy

    It is glum if the closest item in its field of view is
    one of the green obstacles.

    It is suprised if one of these is true:

        the closest object is the other mover

        it has just been moved to a new location

        its target has been moved to a new location

    It is neutral if there is nothing close enough to be seen
    within its field of view.

    It is happy if the closest thing in its field of view is its
    target.

    Surprise overrides all the other states.

Agents move slowest when they are glum, fastest when they are happy,
except that when close to their target they stop moving, despite being
happy.


Please report problems to
Aaron Sloman
http://www.cs.bham.ac.uk/~axs/
A.Sloman@cs.bham.ac.uk
