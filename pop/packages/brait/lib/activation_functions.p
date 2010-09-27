/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/lib/activation_functions.p
 > Purpose:         Mathematical functions to calculate the output of logic
units in the vehicles given its activation level.
    Complex activation functions are built up by the overall activation
function being a list of constituent mathematical functions, each with upper
and lower bounds (and the config values needed to describe it).
 > Author:          Duncan K Fewkes, 16 Jan 2000 (see revisions)
 > Documentation:
 > Related Files:


         CONTENTS - (Use <ENTER> gg to access required sections)

 define straight_func(value, gradient, intercept);
 define threshold_rise_func(value, threshold_value, upper_value);
 define threshold_drop_func(value, threshold_value, upper_value);
 define normal_dist_func(x, max_loc, spread);

 */


/*
PROCEDURE: straight_func (value, gradient, intercept)
INPUTS   : value, gradient, intercept
  Where  :
    value is the input to the logic unit
    gradient is the gradient of the straight-line function
    intercept is the y-intercept of the function.
OUTPUTS  : returns calculated unit output value
USED IN  : vehicle internal processing method
CREATED  : 16 Jan 2000
PURPOSE  : one of the small mathematical functions which will be used to build
            up larger, more complex unit activation functions.
        Models a straight-line graph (as the input value increases. the output
    value varies according to the gradient of the graph).

TESTS:

straight_func(30, 2, 15)==>;
straight_func(25, 2, 15)==>;
straight_func(17, -7, 92)==>;
straight_func(3, 90, -290)==>;

draw_graph([[%straight_func% 0 100 1 10]]);
draw_graph([[straight 0 100 2 -30]]);
draw_graph([[straight 0 100 -1 19.76]]);


*/

define straight_func(value, gradient, intercept);

    return((gradient*value) + intercept);

enddefine;




/*
PROCEDURE: threshold_rise_func (value, threshold_value, upper_value)
INPUTS   : value, threshold_value, upper_value
  Where  :
    value is the unit input value
    threshold_value is the value at which the unit sitches output
    upper_value is the units output when the input is over the threshold
OUTPUTS  : returns calculated unit output value
USED IN  : vehicle internal processing method
CREATED  : 16 Jan 2000
PURPOSE  : as above. Models a threshold where, if the input value is high
        enough the unit outputs a fixed value. If the input is not high enough,
        the unit outputs nothing.

TESTS:
threshold_rise_func(20, 14, 49)==>;
threshold_rise_func(13, 14, 409)==>;
threshold_rise_func(14, 14, 56)==>;
threshold_rise_func(69, 30.0, 12)==>;


*/

define threshold_rise_func(value, threshold_value, upper_value);

    if value >= threshold_value then
        return(upper_value);
    else
        return(0);
    endif;

enddefine;



/*
PROCEDURE: threshold_drop_func (value, threshold_value, upper_value)
INPUTS   : value, threshold_value, upper_value
  Where  :
    value is the unit input value
    threshold_value is the value at which the unit sitches output
    upper_value is the units output when the input is under the threshold
OUTPUTS  : returns calculated unit output value
USED IN  : vehicle internal processing method
CREATED  : 16 Jan 2000
PURPOSE  : as above. Models a threshold where, if the input value is high
enough the unit's output is zero. If the input is not high enough,
        the unit outputs a fixed value.


TESTS:

threshold_drop_func(20, 14, 76)==>;
threshold_drop_func(7, 14, 76)==>;
threshold_drop_func(14.0, 14.1, 76)==>;

draw_graph([[threshold_drop 0 100 50 70]]);

*/

define threshold_drop_func(value, threshold_value, upper_value);

    if value >= threshold_value then
        return(0);
        else
        return(upper_value);
    endif;

enddefine;




/*
PROCEDURE: normal_dist_func (value, max_loc, spread)
INPUTS   : value, max, spread
  Where  :
    value is the unit input value
    max_loc is the x location of the peak(100 value) of the distribution curve
    spread is the spreading of the bell-curve between the zero values
OUTPUTS  : returns calculated unit output value
USED IN  : vehicle internal processing method
CREATED  : 14 Mar 2000
PURPOSE  : To calculate a normal distribution curve for activation function.

TESTS:

normal_dist_func(90, 30, 180) ==>;
normal_dist_func(100, 0, 100) ==>;
normal_dist_func(3, 10, 10) ==>;

draw_graph([[normal_dist 0 100 50 3.9899]]);
draw_graph([[%normal_dist_func% 0 100 50 7.975]]);
draw_graph([[normal_dist 0 100 50 10]]);


*/

define normal_dist_func(x, max_loc, spread);

    ;;;return( maximum * sin(value*(180/spread)) );
    ;;; OLD approximation using sin

    return((250.657 * spread)* (1/(spread*sqrt(2*pi))) * exp( -0.5*(((x-max_loc)/spread)**2) ) );


enddefine;



;;; Convenient abbreviations. Removes need for %% when declaring functions used
global vars
    straight = "straight_func",
    threshold_rise = "threshold_rise_func",
    threshold_drop = "threshold_drop_func",
    normal_dist = "normal_dist_func";

;;; for "uses"
global constant activation_functions = true;

/* --- Revision History ---------------------------------------------------
--- Duncan K Fewkes, Aug 30 2000
converted to lib format
 */
