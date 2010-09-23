This file is
        http://www.cs.bham.ac.uk/research/poplog/linux-cd/AREADME.motifcheck.txt
        $poplocal/local/ftp/linux-cd/AREADME.motifcheck.txt
Aaron Sloman
http://www.cs.bham.ac.uk/~axs/
Last updated: 3 Apr 2007

    NB: This file is probably out of date and it may be better to
    rely on other things.

THIS IS PART OF A SET OF FILES ON HOW TO INSTALL LINUX POPLOG ON A PC

The things to check described in this file are done automatically  by
the new script

    CHECK_LINUX_FACILITIES

available from

        http://www.cs.bham.ac.uk/research/poplog/linux-cd/CHECK_LINUX_FACILITIES

After downloading you can make it executable and run it.

If it reports no problems you can ignore the rest of this file.

The most convenient way to install poplog is described in the file
    http://www.cs.bham.ac.uk/research/poplog/linux-cd/SHORT-CUT-INSTALLATION.txt


CONTENTS

 -- INTRODUCTION
 -- CHECK IF MOTIF IS ALREADY INSTALLED
 -- IF YOU ONLY HAVE LESSTIF
 -- INSTALLING MOTIF
 -- CHECK MOTIF LINKS
 -- NOTES

-- INTRODUCTION

Poplog can be run with or without motif. If you install poplog with
motif enabled (the default) you can later disable motif, though that
will mean that some useful though not essential facilities are disabled,
e.g. scroll bars and menu buttons on the editor XVed, and a motif file
browser. Using poplog with motif is recommended if you are in doubt and
if you have or are willing to get motif. Motif is included in recent
RedHat linux distributions, and possibly others also. If for any reason
it was not installed you may be able to find it in the distribution CD.
Otherwise it is readily available on the internet.

-- CHECK IF MOTIF IS ALREADY INSTALLED

The shell script mentioned above is provided to see whether a linux
motif library is installed.

    CHECK_LINUX_FACILITIES

If it reports that motif is not found you should read the rest of this
file. If it finds motif and makes appropriate links, you need read
no further.

In order to run poplog with motif you will need to have
motif installed. You can check whether you have it installed
by doing this on a Redhat linux system.

    rpm -q openmotif

If it prints out something like
    openmotif-2.1.30-8

(possibly with different numbers) you can then proceed without
installing motif.

The above test is specified for RedHat Linux. For other versions you may
have to get expert help.

You also need to install openmotif-devel
Check if it is already installed

    rpm -qa | grep motif

If the 'rpm' test does not show motif, you may have it anyway. On many
versions of Linux you can check whether you have it by giving one of
these commands:

    ls /usr/X11R6/lib/libXm.so*
    ls /usr/lib/libXm.so*

It may print out two or three file names, e.g. something like this, for
Openmotif version 2,

       /usr/X11R6/lib/libXm.so.2
       /usr/X11R6/lib/libXm.so.2.1

or, if you have a different version of motif, there may be different
numbers, e.g. (on RedHat 9) Openmotif version 3:

    /usr/X11R6/lib/libXm.so.3
    /usr/X11R6/lib/libXm.so.3.0.1

It may also include this file without a version number, which should be
a symbolic link to one of the other files:
       /usr/X11R6/lib/libXm.so

If the above are present then you should be able to install poplog
linked with motif.

-- IF YOU ONLY HAVE LESSTIF
If you have only Lesstif installed, some of the motif utilities used by
Poplog will work, but there may be minor problems. Using openmotif
is preferable.

You can check if you have Lesstif using the command

    ls -l /usr/X11R6/lib/libXm.so*

or

    ls -l /usr/lib/libXm.so*

If that shows only files indicating version 1, e.g.
    /usr/X11R6/lib/libXm.so.1

they will probably be linked to a Lesstif sub-directory.
Poplog will work with that, but not perfectly.

If you can't find motif and motif-devel you need lesstif and
lesstif-devel.


-- INSTALLING MOTIF

If you don't have motif installed you check if it is included in one of
the CDs that came with your linux distribution.

Failing that you can use google (TM) to search for openmotif (which is
the free version of motif) and download it.

As superuser (root) you can install the openmotif rpm file as follows.

    Change to the directory containing the file,
    if you are not already in it:

    Become superuser (root), if you are not already superuser,
    using the "su -" command, and root password.

    Give this command to install motif.

    rpm -i <openmotif-rpm-file-name>
        (use the exact name of the openmotif file that you have).

If you have Lesstif installed and the rpm command gives an
error, you are advised to replace Lesstif with motif, as there
may be some motif features not yet implemented in Lesstif.

To force an installation of motif use '--force', e.g.

    rpm -i --force openmotif-2.1.30-8.i386.rpm

-- CHECK MOTIF LINKS

Check whether motif is now where poplog expects to find it:

Give this command

    ls /usr/X11R6/lib/libXm.so*

It may print out two or three file names, e.g. something like:

    /usr/X11R6/lib/libXm.so.2
    /usr/X11R6/lib/libXm.so.2.1

or posssibly something with a '3' instead of the '2' if you have motif
version 3.

If only one of those files exist, and you do not have either
libXm.so.2 or libXm.so.3, only one with additional numbers after
the '2' or the '3' (indicating a later version), then you should
make a symbolik link for the missing file.

E.g. as super-user do

    ln -s libXm.so.2.1 /usr/X11R6/lib/libXm.so.2

That will create libXm.so.2 as a link to libXm.so.2.1

Likewise for libXm.so.3

If you don't have the X11 files in /usr/X11R6/lib they may be
in
    /usr/lib/

-- NOTES

If you don't have any version of motif or you have one and the poplog
installation fails, ask an expert for help. E.g. post a message to the
    comp.lang.pop news group

or send email to
    pop-forum  AT cs.bham.ac.uk

describing EXACTLY what you have done and what is printed out when you
do

    ls -l /usr/X11R6/lib/libXm.so*

    ls -l /usr/lib/libXm.so*


If all has gone well you should now be ready to install Poplog.

NB if you fail to install motif, or do not wish to install motif, you
will find an option to install Poplog without Motif.

Now turn back to the AREADME.txt file, or the SHORT-CUT-INSTALLATION.txt
file.
