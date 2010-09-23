/*  --- Copyright University of Sussex 1989. All Rights Reserved --------
 > File:           $popneural/demos/dipole.p
 > Purpose:        learn grid layout
 > Author:         David Young, 1989
 > Documentation:
 > Related Files:
 */

uses complearn;

define gendipoles(n) -> stim;
    lvars n stim;
    lvars x1 y1 x2 y2 dir i;
    array_of_double([1 4 1 4 1 ^n],0.0) -> stim;
    for i from 1 to n do
        repeat
            random(4) ->> x1 -> x2;
            random(4) ->> y1 -> y2;
            random(4) -> dir;
            switchon dir ==
            case 1 then x2 + 1 -> x2
            case 2 then x2 - 1 -> x2
            case 3 then y2 + 1 -> y2
            case 4 then y2 - 1 -> y2
            endswitchon;
        quitif ((x2 > 0) and (x2 < 5) and (y2 > 0) and (y2 < 5)) endrepeat;
        1.0 ->> stim(x1,y1,i) -> stim(x2,y2,i);
    endfor;
    newanyarray([1 16 1 ^n],stim) -> stim
enddefine;

define printresdip(m);
    lvars m;
    lvars w1 w2 x y stim stim1 wts outvec;
    hd(hd(m.clweights)) -> wts;
    newanyarray([1 4 1 4],wts,0) -> w1;
    newanyarray([1 4 1 4],wts,16) -> w2;
    array_of_double([1 4 1 4]) -> stim;
    newanyarray([1 16],stim) -> stim1;
    array_of_double([1 2]) -> outvec;
    for y from 1 to 4 do
        pr(newline);
        for x from 1 to 4 do
            if w1(x,y) > w2(x,y) then
                pr('X ')
            else
                pr('O ')
            endif;
            if x /== 4 then
                1.0 ->> stim(x,y) -> stim(x+1,y);
                cl_response(stim1,m,outvec);
                0.0 ->> stim(x,y) -> stim(x+1,y);
                if outvec(1) > outvec(2) then
                    pr('= ')
                else
                    pr('- ')
                endif
            endif
        endfor;
        pr(newline);
        if y/== 4 then
            for x from 1 to 4 do
                1.0 ->> stim(x,y) -> stim(x,y+1);
                cl_response(stim1,m,outvec);
                0.0 ->> stim(x,y) -> stim(x,y+1);
                if outvec(1) > outvec(2) then
                    pr('I')
                else
                    pr('|')
                endif;
                pr('   ');
            endfor
        endif;
    endfor;
    pr(newline);
enddefine;

define dipoledemo;

    dlocal pop_readline_prompt;
    lvars switchedscreen;

    lvars machine;
    lvars g = 0.04;

    nl(1);
    if (vedediting and (vedscreenlength /== vedwindowlength)) ->> switchedscreen then
        vedsetwindow();
    endif;
    npr('Competitive learning of 2-D structure');
    npr('See Rumelhart & McClelland, p.170 et seq.');
    nl(1);
    npr('Results are shown as in the diagrams on p. 173');
    npr(' - at vertices X or O identify which unit won;');
    npr(' on dipoles I and = mean the X unit won, | and - mean');
    npr(' the O unit won');
    nl(1);
    make_clnet(16,{{2}},g,false,false,false) -> machine;
    npr('Initial state of the machine:');
    printresdip(machine);
    vars stims = gendipoles(400);

    'Type <return> to start' -> pop_readline_prompt;
    readline().erase;

    npr('Now doing 200 learning presentations (one dipole per presentation)');
    cl_learn_set(stims, false, 200, false, machine, false);
    npr('Results after 200 iterations');
    printresdip(machine);
    npr('Now doing another 500 presentations');
    cl_learn_set(stims, false, 500, false, machine, false);
    npr('Results after 500 iterations');
    printresdip(machine);

    'Type <return> to finish' -> pop_readline_prompt;
    readline().erase;

    if switchedscreen then vedsetwindow() endif;

enddefine;


/* --- Revision History ---------------------------------------------------
Julian Clinton, Aug  5 1993
    Changed array_of_real to array_of_double so example can be used
    with C version of complearn.
 */
