/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/demo/rc_neural.p
 > Purpose:			Demonstrate simple neural nets
 > Author:          Riccardo Poli, October 1997 (see revisions)
 > Documentation:
 > Related Files:
 */



/*
  rc_neural.p

  Artificial Neuron Simulator in Pop-11

  This is based on workshop5.p (the answers to the exercises in
  SEM1A9 workshop 5) plus a graphical interface.

  To use this program, just compile this file and execute one of the
  train_net(...) commands at the end of this file. A graphical panel
  will appear. This represents the weights, bias, output and inputs of
  an artificial neuron with step activation function.

  You will see that the weights and the bias change during the learning
  phase.

  After the training is completed you can use the network
  by changing weights, bias or inputs and then activating the network
  pressing the "propagate"  button.
*/

uses rclib;
uses rc_control_panel;

vars rc_neural_panel = false, rc_neural_ninputs = 0;

/*
  Solution to Exercise A
*/

define activation(net) -> result;
    if net > 0 then
	1 -> result;
    else
	0 -> result;
    endif;
enddefine;

/*
activation(2.5) =>
activation(0.0) =>
activation(-1.0) =>
*/

/*
  Solution to Exercise B
*/

define net_input(inputs,weights,bias) -> result;
    lvars i, w;
    bias -> result;

    for i, w in inputs, weights do
	i * w + result -> result;
    endfor;
enddefine;

/*
net_input([1 0],[1 1],-1) =>
net_input([1 0 1],[1 1 -1],1) =>
*/

/*
 Solution to Exercise C
*/

define neuron(inputs,weights,bias) -> result;
    activation(net_input(inputs,weights,bias)) -> result;
enddefine;

/*
neuron([1 0],[1 1],-1) =>
neuron([1 1],[1 1],1) =>
neuron([1 0 1],[1 1 -1],1) =>
neuron([1 0 1],[1 1 -1],-1) =>
*/

/*
 Solution to Exercise D
*/

define error(inputs,weights,bias,target) -> result;
    neuron(inputs,weights,bias) - target -> result;
enddefine;

/*
error([1 0],[1 1],-1,1) =>
error([1 1],[1 1],1,0) =>
error([1 1],[1 1],1,1) =>
error([1 0 1],[1 1 -1],1,0) =>
error([1 0 1],[1 1 -1],-1,0) =>
*/


/*
 Solution to Exercise E
*/

define train(inputs,weights,bias,target) -> ( new_weights, new_bias );
    lvars e, w, i;

    error(inputs,weights,bias,target) -> e;

    if e == 0 then
		weights -> new_weights;
		bias -> new_bias;
    elseif e > 0 then
		bias - 1 -> new_bias;
		[%
	  		for w, i in weights, inputs do
	      		if i == 1 then
		  			w - 1;
	      		else
		  			w;
	      		endif;
	  		endfor;
		%] -> new_weights;
    else
		bias + 1 -> new_bias;
		[%
	  		for w, i in weights, inputs do
	      		if i == 1 then
		  			w + 1;
	      		else
		  			w;
	      		endif;
	  		endfor;
		%] -> new_weights;
    endif;
enddefine;

/*
train([1 0],[1 1],-1,1) =>
train([1 1],[1 1],1,0) =>
train([1 1],[1 1],1,1) =>
train([1 0 1],[1 1 -1],1,0) =>
train([1 0 1],[1 1 -1],-1,0) =>
*/

/*
 Solution to Exercise F
*/

define train_all(training_set,weights,bias) -> (new_weights,new_bias);
    lvars example;

    weights -> new_weights;
    bias -> new_bias;

    for example in training_set do
 		train(example(1),new_weights,new_bias,example(2)) ->
		(new_weights, new_bias);
    endfor;
enddefine;

/*
train_all([[[1 0] 1][[0 1] 1]],[1 1],-1) =>
train_all([[[1 0] 1][[0 1] 0]],[1 1],-1) =>
train_all([[[1 0] 1][[0 1] 0][[1 1] 0]],[1 1],-1) =>
train_all([[[0 0] 0][[1 0] 1][[0 1] 0][[1 1] 0]],[1 1],-1) =>
*/

define rc_neural_setup(ninputs );
    lvars
		x,
      	slider_specs =
      	[
		  {width panel} {radius 6}
		  {fieldfg 'blue'}
		  {offset 15} {gap 0}
		  {barcol 'blue'}
		  {blobcol 'red'}
		  {framewidth 4}],

      	panel_specs =
      	[
       		{width 300}
	   		{bg 'black'}
        	[TEXT
            	{margin 5}
            	{align centre} :
            	'Artificial Neuron Demo' 'Inputs']
			
       		[SLIDERS
	    		^slider_specs
				{framecol 'green'}
	    		{label inputs}:
	    		%
	    		for x to ninputs do
	    			[{0 1 0} indentfn [{-5 12 %'i'><x%}] ];
    	    	endfor; %
	    	]
           	[TEXT
            	{margin 5}
            	{align centre} :
            	'Weights and Bias']
       	   	[SLIDERS
	    		^slider_specs
				{framecol 'pink'}
	    		{label weights} :
	    		%
	    		for x to ninputs do
	    			[{-10 10 0} identfn [{-5 12 %'w'><x%}] ];
    	    	endfor; %
	    	]
       	   	[SLIDERS
	    		^slider_specs
				{framecol 'yellow'}
	    		{label bias}:
	    		[{-10 10 0} identfn [{-5 12 'bias'}] ]	
	    	]
           	[TEXT
            	{margin 5}
            	{align centre} :
            	'Output']
			
       		[SLIDERS
	    		^slider_specs
				{framecol 'red'}
	    		{label output} :
	    		[{0 1 0} identfn [{-5 12 'output'}] ]	
	    	]
			
        	[TEXT
            	{margin 5}
            	{align centre} :
            	'Delay between Updates (1/100s)']

       		[SLIDERS
				^slider_specs
				{framecol 'grey50'}
	    		{label delay} :
	    		[{0 500 100} round [{-5 12 'delay'}] ]	
	    	]

        	[ACTIONS
            	{width 100}
            	{align center} {gap 10} :
	    		['PROPAGATE' rc_neural_propagate]
        		['KILL PANEL'
					[POPNOW rc_kill_menu(); false -> rc_neural_panel]]
            ]
        ];

/*
		dlocal
		;;; Make the blobs fit in the slider bars
			rc_slider_blob_bar_ratio = 1;
*/

   		rc_control_panel(10, 10, panel_specs,
		    'Artificial Neuron Demo') -> rc_neural_panel;
   		ninputs -> rc_neural_ninputs;

enddefine;

/*
rc_neural_setup( 5 );
*/

define rc_neural_propagate();
    lvars x, bias, inputs, weights;


    slider_value_of_name(rc_neural_panel,"bias", 1) -> bias;
    [%
      for x to rc_neural_ninputs do
 	  slider_value_of_name(rc_neural_panel,"weights", x);
      endfor;	
      %] -> weights;
    [%
      for x to rc_neural_ninputs do
 	  slider_value_of_name(rc_neural_panel,"inputs", x);
      endfor;	
      %] -> inputs;

    neuron(inputs,weights,bias) ->
    slider_value_of_name(rc_neural_panel,"output", 1);
enddefine;

define rc_neural_set_weights(weights, bias);
    lvars x;

    if not(rc_neural_panel) or length(weights) /== rc_neural_ninputs then
	rc_neural_setup( length(weights) )
    endif;

    bias -> slider_value_of_name(rc_neural_panel,"bias", 1);
    for x to rc_neural_ninputs do
 	weights(x) -> slider_value_of_name(rc_neural_panel,"weights", x);
    endfor;	
enddefine;

/*
rc_neural_set_weights([1 1 2 3],1);
*/

/*
 Solution to Exercise G
*/

define train_net(training_set) -> (new_weights,new_bias);
    lvars weights,
	  	bias,
    	ninputs = length(hd(hd(training_set)));

    [%
       	repeat ninputs times
	   		random(11)-5;
       	endrepeat;
	%] -> weights;

    random(11) - 5 -> bias;

    repeat 100 times
    	pr('w='); pr(weights); pr('   b='); npr(bias);
		rc_neural_set_weights(weights, bias);
		syssleep(slider_value_of_name(rc_neural_panel,"delay", 1));
		train_all(training_set,weights,bias) -> (new_weights,new_bias);
		if  weights = new_weights and bias == new_bias then
	    	return
		endif;
		(new_weights,new_bias) -> (weights,bias);
    endrepeat;
    ( false, false ) -> (new_weights,new_bias);
enddefine;
	
/*
train_net([[[1 0] 1][[0 1] 1]]) =>
train_net([[[1 0] 1][[0 1] 0]]) =>
train_net([[[1 0] 1][[0 1] 0][[1 1] 0]]) =>
train_net([[[0 0] 0][[1 0] 1][[0 1] 0][[1 1] 0]]) =>
;;; OR function
train_net([[[0 0] 0][[0 1] 1][[1 0] 1][[1 1] 1]]) =>
;;; AND function
train_net([[[0 0] 0][[0 1] 0][[1 0] 0][[1 1] 1]]) =>
;;; XOR function
train_net([[[0 0] 0][[0 1] 1][[1 0] 1][[1 1] 0]]) =>
;;; MAJORITY function (3 inputs)
train_net([[[0 0 0] 0]
	   [[0 0 1] 0]
	   [[0 1 0] 0]
	   [[0 1 1] 1]
	   [[1 0 0] 0]
	   [[1 0 1] 1]
	   [[1 1 0] 1]
	   [[1 1 1] 1]]);
;;; EVEN-3 Parity function
train_net([[[0 0 0] 1]
	   [[0 0 1] 0]
	   [[0 1 0] 0]
	   [[0 1 1] 1]
	   [[1 0 0] 0]
	   [[1 0 1] 1]
	   [[1 1 0] 1]
	   [[1 1 1] 0]]);
*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul  4 2000
	Changed colours, because of new slider facilities: slider backgrounds
	no longer need to be white.
--- Aaron Sloman, Apr 19 1999
	Slightly modified slider specs again
--- Aaron Sloman, Feb  6 1998
	Altered to use new slider specs
 */
