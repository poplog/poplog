$usepop/bin/demos/AREADME-DEMOS.txt
Updated: 4 Feb 2008

There can be problems caused by security mechanisms that require
poplog to be run using the 'setarch' command. For details see

http://www.cs.bham.ac.uk/research/projects/poplog/freepoplog.html#selinuxproblems

In order to get round the problems the installation scripts test
your selinux settings, and if appropriate redefine the commands
pop11, prolog, ved etc. to use the 'setarch' prefix.

See
    ../poplog.sh
        for users of bash, ksh, setc.

    ../poplog
        for users of tcsh csh

==================================================================
18 Jan 2005

FILES IN THIS DIRECTORY PROVIDE INFORMATION ON RUNNING POPLOG
AND SOME SHELL SCRIPTS GIVE SIMPLE DEMONSTRATIONS OF SOME FEATURES OF
POP-11 THE CORE LANGUAGE OF THE FREE OPEN-SOURCE POPLOG[tm] SYSTEM
DESCRIBED HERE:
    http://www.cs.bham.ac.uk/research/poplog/poplog-info.html
    http://www.cs.bham.ac.uk/research/poplog/primer/START.html
    http://www.cs.bham.ac.uk/research/poplog/freepoplog.html

AND THE BIMRINGHAM SIM_AGENT TOOLKIT, DESCRIBED MORE FULLY HERE:
    http://www.cs.bham.ac.uk/research/cogaff/talks/#simagent
    http://www.cs.bham.ac.uk/~axs/cogaff/simagent.html

18 Jan 2005

There are four files for users, depending on whether your shell is bash
or tcsh and whether you installed poplog in the default directory
(i.e. /usr/local/poplg) or somewhere else:

    bash-users-default-dir
    bash-users-nondefault-dir
    tcsh-users-default-dir
    tcsh-users-nondefault-dir

Read the appropriate one.

The following scripts are provided for running a few test demos
after poplog has been installed. If these work, then it is very
likely that everthing else will work.

They may be run as follows, provided that they are run in a directory
containing a link to the file poplog.sh created when the poplog system
was installed.

 ./run-eliza
OR
 ./run-speaking-eliza
    (The second produces spoken output if you have the espeak
    library installed.)
    Run pop11 with eliza (non-serious simulation of a non-directive
    Rogerian psychotherapist).
    This will run the code in
       $usepop/pop/packages/teaching/lib/elizaprog.p
    invoked via
       $usepop/pop/packages/teaching/auto/eliza.p

    Edit the elizaprog.p program to change the rules.

    End by typing
       bye
    or interrupt with Control-C


 ./run-eliza-nonstop
    As above except that it automatically re-starts run-eliza every
    time the program finishes.
    This means that the only way to stop this is to suspend (CTRL-Z) and
    kill the suspended process (kill %1) or kill it from another shell
    (Suitable as a demo for 'open days')

 ./simagent-demo
    This starts pop11, compiles the SimAgent toolkit (located in
        $usepop/pop/packages/newkit )

    then compiles the demonstration program in

        $usepop/pop/packages/newkit/sim/teach/sim_feelings

    then runs it.

    This produces a control panel on the left, and on the right a
    display of two moving agents, one red and one blue, each represented
    by a small square, each constantly heading for its target, a red or
    blue circle, respectively, in an environment where there are some
    obstacles that don't move spontaneously. represented by green
    circles.

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

    You can use the mouse to move the objects in the window on the
    right. E.g. the red and blue agents, their targets and the
    obstacles are all movable.

    You can use the control panel to speed up, slow down or abort
    the demo.

Agents move slowest when they are glum, fastest when they are happy,
except that when close to their target they stop moving, despite being
happy.


Please report problems to
Aaron Sloman
http://www.cs.bham.ac.uk/~axs/
A.Sloman@cs.bham.ac.uk
