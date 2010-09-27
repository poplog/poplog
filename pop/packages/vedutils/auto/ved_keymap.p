/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/auto/ved_keymap.p
 > Purpose:         Find keybindings for all current keys
 > Author:          Steve Knight (Hewlett Packard), Feb  1 1995
 > Documentation:	Below
 > Related Files:
 */

/*
From pop-forum-local-request@cs.bham.ac.uk Tue Jan 31 19:20:08 1995
From: Steve Knight <sfk@hplb.hpl.hp.com>
Subject: Re: finding out what keys do
To: popforum@hplb.hpl.hp.com
Date: Tue, 31 Jan 95 19:05:30 GMT

Hi,

Following on from Aaron's posting
> Ever wondered what those keys do in VED that you never use?

Here's a somewhat improved version of a procedure I wrote a while
back.  It prints out a table of the current VED keybindings.  It
is rather messy as it uses lots of undocumented details (*sigh*)
in order to get the information required.  However, the results
look good and it (well, its progenitor) has worked for years.

Try ENTER keymap RETURN.

Steve
*/
;;; Save this file in an autoloadable directory as ved_keymap.p
compile_mode :pop11 +strict;

section;

include vedscreendefs;

define lconstant make_attr( s, attr ); lvars s, attr;
    consdstring(#| appdata( s, nonop || (% attr %) ) |#)
enddefine;

define lconstant make_bold =
    make_attr(% VEDCMODE_BOLD %)
enddefine;

define lconstant make_italic =
    make_attr(% VEDCMODE_ALTFONT %)
enddefine;

define lconstant fix_pr( x, n );
    dlvars x, n;    ;;; Do not want these variables to be type-3.

    ;;; We define this syntax word because the pop compiler
    ;;; attempts to autoload labels.  This is an error in the
    ;;; design of the compiler (and language).
    define lconstant syntax label;
        sysLABEL( readitem() )
    enddefine;

    unless n.isinteger do
        mishap( n, 1, 'INTEGER NEEDED' )
    endunless;
    dlvars count = 0;  ;;; N.B. count is an integer from 0 to n.

    ;;; Save the old value of cucharout.
    lvars procedure cu = cucharout;

    define dlocal cucharout( ch ); lvars ch;
        if count fi_< n do
            count fi_+ 1 -> count;
            cu( ch );
        else
            goto done
        endif;
    enddefine;

    pr( x );

    label done;

    fast_repeat
        n - count       ;;; This is always a fixnum because 0 <= count <= n.
    times
        cu( ` ` )       ;;; Use the old value of cucharout!
    endrepeat
enddefine;

define lconstant prchar( ch ); lvars ch;
    if ch == 0 then
        '^@'
    elseif ch < 27 then
        consstring(#| `^`, ch+64 |#)
    elseif ch < 32 then
        {'ESC' '^\\' '^]' '^^' '^_'}(ch - 26)
    elseif ch == 127 then
        'DEL'
    else
        consstring(#| ch |#)
    endif;
enddefine;

define lconstant prchars( x ); lvars x;
    dlocal cucharout = identfn;
    pr( x );
enddefine;

define lconstant prpart( x, more ); lvars x, procedure more;
    if x == "undef" or x.isundef then
        false
    elseif x == vedinsertvedchar then
        'insert character'
    elseif x.isword then
        x
    elseif x.isprocedure and pdprops(x).isword do
        pdprops( x )
    elseif x.isident then
        prpart( idval( x ), more )
    elseif x.isvector or x.islist then
        lvars n = more( x );
        make_italic( 'See table ' >< n )
    else
        false
    endif
enddefine;

;;; Ignores all the control characters -- those are dealt with
;;; separately.
define lconstant self_inserting();
    lvars weird = [];
    [%
        lvars i;
        for i from 33 to vednormaltable.length do
            if i.vednormaltable == vedinsertvedchar then
                i
            else
                [ ^i ^^weird ] -> weird
            endif
        endfor;
    %],
    weird.rev
enddefine;

define lconstant prtable( t, codes, more ); lvars t, codes, procedure more;
    vedinsertstring( '\{b}Ascii   Char    VED procedure\n' );
    lvars i;
    for i in codes do
        lvars it = t( i );
        lvars pt = prpart( it, more );
        nextunless( pt );
        fix_pr( i, 8 );
        fix_pr( i.prchar, 8 );
        vedinsertstring( pt );
        vednextline();
    endfor;
enddefine;

define lconstant upto( n ); lvars n;
    [%
        lvars i;
        fast_for i from 1 to fi_check( n, 0, false ) do i endfor
    %]
enddefine;

define lconstant convert_to_vector( t ); lvars t;
    lvars biggest = 0;
    lvars u = t;
    until u.null do
        lvars char = u.dest -> u;
        max( char, biggest ) or char -> biggest;
        u.tl -> u;
    enduntil;

    lvars v = initv( biggest );
    lvars u = t;
    until u.null do
        lvars ( char, action ) = u.dest.dest -> u;
        action -> v( char )
    enduntil;
    return( v )
enddefine;

define write_table( n, t, more ); lvars n, t, more;
    vedinsertstring( make_bold( 'Table ' >< n ) );
    vednextline();

    if t.isvector then
        prtable( t, upto( length( t ) ), more )
    elseif t.islist then
        if length( t ) mod 2 == 1 then
            allbutlast( 1, t ) -> t
        endif;
        convert_to_vector( t ) -> t;
        if t.isvector then
            prtable( t, upto( length( t ) ), more )
        else
            vedinsertstring( 'Empty' )
        endif
    else
        mishap( 'UNHANDLED TABLE FORMAT', [ ^t ] )
    endif;

    nl( 1 );
enddefine;

define write_tables( others, more ); lvars others, more;
    lvars i = 0;
    repeat
        i + 1 -> i;
        lvars it = others( i );
    quitunless( it );
        write_table( i, it, more )
    endrepeat;
enddefine;


define lconstant write_map();

    vedinsertstring( '\{b}NORMAL CHARACTERS (type to insert)\n' );
    lvars ( normal, weird ) = self_inserting();
    while length( normal ) > 32 do
        sp( 4 );
        repeat 32 times
            pr( prchar( normal.dest -> normal ) );
        endrepeat;
        nl( 1 );
    endwhile;
    sp( 4 );
    applist( normal, prchar <> pr );
    nl( 2 );

    lvars others = newproperty( [], 20, false, "perm" );

    lvars moreN = 0;
    define lconstant more( ch ); lvars ch;
        ch -> others( moreN + 1 ->> moreN );
        moreN
    enddefine;

    vedinsertstring( '\{b}CONTROL CHARACTERS\n' );
    prtable( vednormaltable, delete( vedescape, upto( 31 ) ), more );
    nl( 2 );

    unless weird.null do
        vedinsertstring( '\{b}OTHER CHARACTERS\n' );
        prtable( vednormaltable, weird, more );
        nl( 2 );
    endunless;


    vedinsertstring( '\{b}ESCAPE TABLE\n' );
    prtable( vedescapetable, delete( vedquery, upto( vedescapetable.length ) ), more );
    nl( 2 );

    if vedquerytable.isvector then
        vedinsertstring( '{\b}QUERY TABLE' );
        prtable( vedquerytable, upto( vedquerytable.length ), more );
        nl( 2 );
    endif;

    write_tables( others, more );
enddefine;

define ved_keymap();
    vededitor( vedhelpdefaults, systmpfile( false, 'keymap', '.txt' ) );
    dlocal cucharout = vedcharinsert;
    vedinsertstring( '\{bu}Current VED Key Map\n\n' );
    write_map();
    vedtopfile();
enddefine;

endsection;
