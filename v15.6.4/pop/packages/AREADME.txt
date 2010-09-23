This is
    $usepop/pop/packages

Subdirectories of this directory can include packages such as have for
some time been included in subdirectories of $poplocal/local

The default popuseslist (defined in $popautolib/popuseslist.p)
has been extended to include

    $usepop/pop/packages/lib

so that package startup files can have links in there, to be
found by the pop11 command:

    uses <packagename>

See HELP USES

A new list has been added to pop11: poppackagelist

This is autoloaded from
    $usepop/pop/lib/auto/poppackagelist.p

At present its default value is [].

The packages in this directory have startup files in their 'top level'
directories, which add those directories to poppackagelist

The gz directory is a convenient location in which to install gzipped
tar files containing new packages that can be installed by using
this script

    com/install_package

There are some 'packages' that have been separated out from the core
of pop11 in the past, including

    $usepop/pop/lib/database/
    $usepop/pop/lib/flavours/
    $usepop/pop/lib/lr_parser/
    $usepop/pop/lib/objectclass/
    $usepop/pop/lib/proto/
        (provides GO a 'Graphical Objects' package whose development
        was never completed.)
    $usepop/pop/lib/turtle/

    $usepop/pop/lib/obsolete/

At some later stage this situation may be rationalised.

Aaron Sloman
http://www.cs.bham.ac.uk/~axs/
8 Jan 2005


--- $usepop/pop/packages/AREADME.txt
--- Copyright University of Birmingham 2005. All rights reserved.
