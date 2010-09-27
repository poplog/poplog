/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/lib/decay_functions.p
 > Purpose:         Mathematical functions for the decay of stimuli with
	increased distance from the stimulus source.
 > Author:          Duncan K Fewkes, Dec 3 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/*

CONTENTS - (Use <ENTER> gg to access required sections)

 define exponential_decay_func(dist, strength, configure) -> result;
 define decrement_func(dist, strength, configure) -> result;
 define decay_test(funct, configure);

*/

/*
PROCEDURE: exponential_decay_func (dist, strength, configure) -> result
INPUTS   : dist, strength, configure
  Where  :
    dist is a floating point number
    strength is an integer between 0 and 100
    configure is a value to tailor the math function for different sources and
              diffferent environments.
OUTPUTS  : Result is a value for the strength of the stimulus at the distance
USED IN  : Vehicle and source objects. Manipulated by sim_run_sensor of active
            agents.
CREATED  : 3 Dec 1999
PURPOSE  : To allow general procedures for calculating stimulus strength at
            different distance. This allows stimuli to decay in different
            manners and also facilitates addition of new decay functions. Also,
            each source can configure the decay function it uses for different
            rates of stimulus decay, i.e. the stimulus spread is wider or more
            localised.

        This particular decay function decreases the stimulus strength
        proportionally to the square of the distance, i.e fast drop off near
        start and rate of decay slows as you get further out.

TESTS:
exponential_decay_func -> function;
function(300.0 ,100, 1000.0)==>;
function(3.0 ,100, 100)==>;
function(670.0 ,100, 100)==>;
function(150.0 , 100, 100)==>;
function(20.0 , 56, 100)==>;

[%exponential_decay_func% 200.0]-> list;
list==>;
list(1) -> function;

isprocedure(function);
datakey(function);

function==>;

decay_test(function, 200);

*/



define exponential_decay_func(dist, strength, configure) -> result;

    (strength / ( (dist/configure) **2) ) -> result ;

    if result > 100 then
        100 -> result;
    endif;

        ;;; Dist is divided by configure to allow greater spreading etc.,
        ;;; whilst keeping the value of the stimulus between 0 and 100.

enddefine;




/*
PROCEDURE: decrement_func (dist, strength, configure) -> result
INPUTS   : dist, strength, configure
  Where  :
    dist is a ???
    strength is a ???
    configure is a ???
                        see above header

OUTPUTS  : see above
USED IN  : see above
CREATED  : 3 Dec 1999
PURPOSE  : Decrements by value proportional to dist. Decrements strength by
            'configure' units every pixel away from source.

TESTS:
decrement_func -> function;
function(300.0 ,100, 100.0)==>;
function(3.0 ,100, 100)==>;
function(670.0 ,100, 100)==>;
function(150.0 , 100, 100)==>;
function(20.0 , 56, 100)==>;

decay_test(decrement, 6.0 );


*/

define decrement_func(dist, strength, configure) -> result;

    (strength - (dist * configure) ) -> result;

    if result > 100 then
        100 -> result;
    endif;

    if result < 0 then
        0 -> result;
    endif;

enddefine;






/***************************** TOOLS ***************************************/





/*
PROCEDURE: decay_test (funct, configure)
INPUTS   : funct, configure
  Where  :
    funct is a decay function
    configure is a config value
OUTPUTS  : NONE
USED IN  : above
CREATED  : 3 Dec 1999
PURPOSE  : testing decay functions and config values. prints out a list of
            stimuli strengths at different distances (from 1 to 1000, in steps
            of 100).
TESTS:

*/

define decay_test(funct, configure);

lvars d;

    for d from 1.0 by 100.0 to 1000 do
        funct(d, 100, configure)==>;
    endfor;

enddefine;




;;; Convenient abbreviations. Removes need for %% when declaring functions used
global vars
    exponential_decay = "exponential_decay_func",
    decrement = "decrement_func";


;;; for uses.
global constant decay_functions = true;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Oct  8 2000
	fixed header and added "define" index

--- Duncan K Fewkes, Aug 30 2000
converted to lib format
 */
