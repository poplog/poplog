/*  --- Copyright University of Sussex 1989. All Rights Reserved --------
 > File:           $popneural/demos/verthorz.p
 > Purpose:        learn grid layout
 > Author:         David Young, 1989
 > Documentation:
 > Related Files:
 */

uses complearn;

define genlines(n) -> stim;
    lvars n stim;
    lvars x y i;
    array_of_double([1 12 1 6 1 ^n],0.0) -> stim;
    for i from 1 to n do
        if random(2) == 1 then
            random(6) -> x;
            for y from 1 to 6 do
                1.0 -> stim(y,1,i);
                1.0 -> stim(y+6,x,i)
            endfor
        else
            random(6) + 6 -> y;
            for x from 1 to 6 do
                1.0 -> stim(1,x,i);
                1.0 -> stim(y,x,i)
            endfor
        endif
    endfor;
    newanyarray([1 72 1 ^n],stim) -> stim
enddefine;

define printresvh(m);
    lvars m;
    lvars x y stim stim1 winners outvec;
    array_of_double([1 ^(m.clnoutunits)]) -> outvec;
    npr('Horizontal lines');
    for x from 1 to 6 do
        pr(x); pr(': ');
        array_of_double([1 12 1 6],0.0) -> stim;
        newanyarray([1 72],stim) -> stim1;
        for y from 7 to 12 do
            1.0 -> stim(y,x)
        endfor;
        cl_response(stim1, m, outvec);
        cl_activunits(m) -> winners;
        pr('layer 2 units: '), pr(winners(1)(1)), pr(' '),
        pr(winners(1)(2));
        pr(';  layer 3 unit: '),npr(winners(2)(1));
    endfor;
    npr('Vertical lines');
    for y from 7 to 12 do
        pr(y-6); pr(': ');
        array_of_double([1 12 1 6],0.0) -> stim;
        newanyarray([1 72],stim) -> stim1;
        for x from 1 to 6 do
            1.0 -> stim(y,x)
        endfor;
        cl_response(stim1, m, outvec);
        cl_activunits(m) -> winners;
        pr('layer 2 units: '), pr(winners(1)(1)), pr(' '),
        pr(winners(1)(2));
        pr(';  layer 3 unit: '),npr(winners(2)(1));
    endfor
enddefine;

vars h1v2=0, h2v1=0, nowinner=0;

define checkresvh(m);
    lvars m;
    lvars x y stim stim1 h1 h2 v1 v2 outvec;
    array_of_double([1 ^(m.clnoutunits)]) -> outvec;
    array_of_double([1 12 1 6],0.0) -> stim;
    newanyarray([1 72],stim) -> stim1;
    for x from 1 to 6 do
        for y from 7 to 12 do 1.0 -> stim(y,x) endfor;
        cl_response(stim1, m, outvec);
        for y from 7 to 12 do 0.0 -> stim(y,x) endfor;
        if cl_activunits(m)(2)(1) == 1 then
            h1 + 1 -> h1
        else
            h2 + 1 -> h2
        endif
    endfor;
    for y from 7 to 12 do
        for x from 1 to 6 do 1.0 -> stim(y,x) endfor;
        cl_response(stim1, m, outvec);
        for x from 1 to 6 do 0.0 -> stim(y,x) endfor;
        if cl_activunits(m)(2)(1) == 1 then
            v1 + 1 -> v1
        else
            v2 + 1 -> v2
        endif
    endfor;
    if h2 == 0 and v1 == 0 then
        h1v2 + 1 -> h1v2
    elseif h1 == 0 and v2 == 0 then
        h2v1 + 1 -> h2v1
    else
        nowinner + 1 -> nowinner
    endif;
enddefine;

define verthorzdemo;

    dlocal pop_readline_prompt;
    lvars switchedscreen;

    dlocal popmemlim = max(popmemlim,200000);
    lvars machine stim;

    nl(1);  ;;; this should put ved into the output file
    if (vedediting and (vedscreenlength /== vedwindowlength)) ->> switchedscreen then
        vedsetwindow();
    endif;
    npr('Competitive learning of vertical and horizontal lines.');
    npr('See Rumelhart & McClelland, p. 184 et seq.');
    nl(1);
    npr('The results show which unit in each cluster wins on each of');
    npr(' the 12 possible stimuli (without the training cue).');
    npr(' See the diagram on p. 189 for the layout of units.');
    nl(1);
    npr('The machine should end up with one of the layer 3 units');
    npr(' responding only to horizontal lines and the other only to');
    npr(' vertical lines. It is inevitable that not all trials will');
    npr(' succeed as the process relies on the layer 2 clusters\'');
    npr(' responding differently to each other. Procedure -vhstats-');
    npr(' is available to give statistics for success, but takes some');
    npr(' time to run');
    nl(1);
    make_clnet(72,{{4 4} {2}},0.02,false,0.02,0.001) -> machine;
    npr('Initial state of the machine:');
    printresvh(machine);
    genlines(2000) -> stim;

    'Type <return> to start' -> pop_readline_prompt;
    readline().erase;
    npr('Now doing 500 learning presentations (one line per presentation)');
    cl_learn_set(stim, false,  500, true, machine,
                 array_of_double([%1, machine.clnoutunits%],0.0s0));
    npr('Results after 500 presentations');
    printresvh(machine);
    npr('Now doing another 1500 presentations');
    cl_learn_set(stim, false, 1500, true, machine,
                 array_of_double([%1, machine.clnoutunits%],0.0s0));
    npr('Results after 1000 presentations');
    printresvh(machine);

    'Type <return> to finish' -> pop_readline_prompt;
    readline().erase;

    if switchedscreen then vedsetwindow() endif;

enddefine;

define vhstats;
    lvars machine stim;
    vars h1v2=0, h2v1=0, nowinner=0;
    dlocal popmemlim = max(popmemlim,200000);
    genlines(2000) -> stim;
    repeat 100 times
        make_clnet(72,{{4 4} {2}},0.02,false,0.02,0.001) -> machine;
        cl_learn_set(stim, false,  2000, true, machine,
                     array_of_double([%1, machine.clnoutunits%],0.0s0));
        checkresvh(machine);
    endrepeat;
    pr('Out of 100 runs of 200 presentations, perfect discrimination');
    pr (' was achieved in ');
    npr(100-nowinner);
enddefine;

/* --- Revision History ---------------------------------------------------
Julian Clinton, Aug  5 1993
    Changed array_of_real to array_of_double so example can be used
    with C version of complearn.
 */
