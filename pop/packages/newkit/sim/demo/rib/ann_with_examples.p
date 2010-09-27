/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/newkit/sim/demo/rib/ann_with_examples.p
 > Purpose:
 > Author:          Riccardo Poli Dec 1994
 > Documentation:
 > Related Files:
 */

;;;
;;; Program:        ann_with_examples.p
;;;
;;; Author:         Riccardo Poli
;;;
;;; Creation date:  Oct 1994
;;;
;;; Description:    Arficial Neural Networks in POP11
;;;
;;;

;;; A sample neural network


;;;
;;; Artificial Neural Network in POP11
;;; Created by rmp with net2pop
;;; Date: Mon Nov 7 12:13:31 GMT 1994
;;; Original Network Name: driver.net
;;;

/*
vars driver =
     [
      ;;; Kind of network/learning

      [network [driver [network_type backpropagation ]]]

      ;;; Learning rate

      [network [driver [epsilon 0.1 ]]]

      ;;; Max absolute value of random weights/biases used for initialization

      [network [driver [random_scale 0.5 ]]]

      ;;; If present, do not (re)initialize the network

      [network [driver [already_taught]]]

      ;;; Parameters controlling the iterations of a learning method

      [network [driver [iterations_number 1000 1000 100 ]]]

      ;;; Current Total Sum of Squares (TSS) of the errors

      [network [driver [tss 3.40282e+38 ]]]

      ;;; Stopping criterion on TSS

      [network [driver [tss_limit 1e-05 ]]]

      ;;; Definition of neurons.
      ;;; Parameters:
      ;;;     name,
      ;;;     kind,
      ;;;     kind of activation,
      ;;;     activation,
      ;;;     error (delta),
      ;;;     input,
      ;;;     bias.
      ;;; WARNING: Order is crucial!! If the output of neuron X
      ;;;     is connected to the input of neuron Y, then neuron
      ;;;     X *MUST* be defined before neuron Y

      [network [driver [unit me input sigmoid 0 0 0 0 ]]]
      [network [driver [unit him input sigmoid 0 0 0 0 ]]]
      [network [driver [unit myv input sigmoid 0 0 0 0 ]]]
      [network [driver [unit hisv input sigmoid 0 0 0 0 ]]]
      [network [driver [unit h1 hidden sigmoid 0 0 0 -0.187497 ]]]
      [network [driver [unit h2 hidden sigmoid 0 0 0 -0.061306 ]]]
      [network [driver [unit h3 hidden sigmoid 0 0 0 -0.0708755 ]]]
      [network [driver [unit h4 hidden sigmoid 0 0 0 0.146287 ]]]
      [network [driver [unit mya output sigmoid 0 0 0 1.13602 ]]]
      [network [driver [connection h1 [me him myv hisv] [1.53379 -1.50684 0.0536133 0.0214338] ]]]

      ;;; Definition of synapses.
      ;;; Parameters:
      ;;;     name of receiving neuron,
      ;;;     list of sending neurons,
      ;;;     list of weights
      ;;; Note: there may be more than one entry in the database for the connections
      ;;;       that reach a given unit

      [network [driver [connection h2 [me him myv hisv]
			[1.65499 -1.57139 -0.161387 0.0683813] ]]]
      [network [driver [connection h3 [me him myv hisv]
			[1.30891 -1.27802 0.125115 -0.388425] ]]]
      [network [driver [connection h4 [me him myv hisv]
			[-1.87426 1.96488 -0.494167 0.339656] ]]]
      [network [driver [connection mya [h1 h2 h3 h4]
 			[-2.16141 -2.28568 -1.77478 3.37857] ]]]

      ;;; Definition of examples.
      ;;; Parameters:
      ;;;     list of activations for input neurons,
      ;;;     list of teaching activations for output neurons

      [network [driver [example [0 1 0 0] [1] ]]]
      [network [driver [example [1 0 0 0] [0] ]]]
      [network [driver [example [0 1 1 0] [1] ]]]
      [network [driver [example [1 0 1 0] [0] ]]]
      [network [driver [example [0 1 0 1] [1] ]]]
      [network [driver [example [1 0 0 1] [0] ]]]
      [network [driver [example [0 1 1 1] [1] ]]]
      [network [driver [example [1 0 1 1] [0] ]]]
      [network [driver [example [1 1 0 0] [0.5] ]]]
      [network [driver [example [1 1 1 0] [0.4] ]]]
      [network [driver [example [1 1 0 1] [0.6] ]]]
      [network [driver [example [1 1 1 1] [0.5] ]]]
      [network [driver [example [0 0 0 0] [0.5] ]]]
      [network [driver [example [0 0 1 0] [0.4] ]]]
      [network [driver [example [0 0 0 1] [0.6] ]]]
      [network [driver [example [0 0 1 1] [0.5] ]]]
      ];

     ;;;
     ;;; Artificial Neural Network in POP11
     ;;; Created by rmp with net2pop
     ;;; Date: Mon Nov 7 12:24:18 GMT 1994
     ;;; Original Network Name: robot.net
     ;;;

     vars robot =
	  [
 	   [network [robot [network_type backpropagation ]]]
 	   [network [robot [epsilon 0.5 ]]]
 	   [network [robot [random_scale 0.5 ]]]
 	   [network [robot [already_taught]]]
 	   [network [robot [iterations_number 10000 10000 100 ]]]
 	   [network [robot [tss 1.00606 ]]]
 	   [network [robot [tss_limit 0.001 ]]]
 	   [network [robot [unit in1 input sigmoid 0 0 0 0 ]]]
 	   [network [robot [unit in2 input sigmoid 0 0 0 0 ]]]
 	   [network [robot [unit in3 input sigmoid 0 0 0 0 ]]]
 	   [network [robot [unit in4 input sigmoid 0 0 0 0 ]]]
 	   [network [robot [unit in5 input sigmoid 0 0 0 0 ]]]
 	   [network [robot [unit in6 input sigmoid 0 0 0 0 ]]]
 	   [network [robot [unit in7 input sigmoid 0 0 0 0 ]]]
 	   [network [robot [unit in8 input sigmoid 0 0 0 0 ]]]
 	   [network [robot [unit hid1 hidden sigmoid 0 0 0 2.02509 ]]]
 	   [network [robot [unit hid2 hidden sigmoid 0 0 0 -3.97371 ]]]
 	   [network [robot [unit hid3 hidden sigmoid 0 0 0 -0.664199 ]]]
 	   [network [robot [unit hid4 hidden sigmoid 0 0 0 -2.4641 ]]]
 	   [network [robot [unit out1 output sigmoid 0 0 0 4.2977 ]]]
 	   [network [robot [unit out2 output sigmoid 0 0 0 -4.7661 ]]]
 	   [network [robot [unit out3 output sigmoid 0 0 0 -6.39415 ]]]
 	   [network [robot [unit out4 output sigmoid 0 0 0 -3.81816 ]]]
 	   [network [robot [threshold out1 0.7 ]]]
 	   [network [robot [threshold out2 0.7 ]]]
 	   [network [robot [threshold out3 0.7 ]]]
 	   [network [robot [threshold out4 0.7 ]]]
 	   [network [robot [connection hid1 [in1 in2 in3 in4 in5 in6 in7 in8] [-5.09873 -0.299104 5.84031 5.37842 0.710461 -9.67387 -5.12095 -9.65697] ]]]
 	   [network [robot [connection hid2 [in1 in2 in3 in4 in5 in6 in7 in8] [5.98406 5.34389 -2.42444 6.88658 -6.03678 0.216472 1.33844 1.0098] ]]]
 	   [network [robot [connection hid3 [in1 in2 in3 in4 in5 in6 in7 in8] [3.27399 7.83451 5.46345 2.46087 -4.43878 -2.99069 -0.572822 -0.990682] ]]]
 	   [network [robot [connection hid4 [in1 in2 in3 in4 in5 in6 in7 in8] [0.288599 -3.34813 0.780455 -1.09771 4.46592 -1.86496 7.21859 4.73541] ]]]
 	   [network [robot [connection out1 [hid1 hid2 hid3 hid4] [7.28923 -6.705 -14.7134 -8.22489] ]]]
 	   [network [robot [connection out2 [hid1 hid2 hid3 hid4] [-11.8416 10.7207 0.620431 -0.785414] ]]]
 	   [network [robot [connection out3 [hid1 hid2 hid3 hid4] [9.86573 -2.57715 4.74645 -11.294] ]]]
 	   [network [robot [connection out4 [hid1 hid2 hid3 hid4] [-9.97808 -7.74123 -3.78862 10.2219] ]]]
 	   [network [robot [example [0 0 0 0 0 0 0 1] [0 0 0 1] ]]]
 	   [network [robot [example [0 0 0 0 0 0 1 0] [0 0 0 1] ]]]
 	   [network [robot [example [0 0 0 0 0 1 0 0] [1 0 0 0] ]]]
 	   [network [robot [example [0 0 0 0 1 0 0 0] [1 0 0 0] ]]]
 	   [network [robot [example [0 0 0 1 0 0 0 0] [0 0 1 0] ]]]
 	   [network [robot [example [0 0 1 0 0 0 0 0] [0 0 1 0] ]]]
 	   [network [robot [example [0 1 0 0 0 0 0 0] [0 0 1 0] ]]]
 	   [network [robot [example [1 0 0 0 0 0 0 0] [0 1 0 0] ]]]
 	   [network [robot [example [0 0 0 0 0 1 1 0] [0 0 0 1] ]]]
 	   [network [robot [example [0 0 0 0 1 0 0 1] [0 0 0 1] ]]]
 	   [network [robot [example [0 0 0 1 0 0 0 1] [0 1 0 0] ]]]
 	   [network [robot [example [0 0 0 1 0 1 0 0] [0 1 0 0] ]]]
 	   [network [robot [example [0 0 0 1 1 0 0 0] [1 0 0 0] ]]]
 	   [network [robot [example [0 0 1 0 1 0 0 0] [0 1 0 0] ]]]
 	   [network [robot [example [0 1 0 0 0 0 0 1] [0 1 0 0] ]]]
 	   [network [robot [example [0 1 0 0 0 0 1 0] [0 1 0 0] ]]]
 	   [network [robot [example [0 1 0 0 1 0 0 0] [0 0 1 0] ]]]
 	   [network [robot [example [0 1 0 1 0 0 0 0] [0 0 1 0] ]]]
 	   [network [robot [example [0 1 1 0 0 0 0 0] [0 0 1 0] ]]]
 	   [network [robot [example [1 0 0 0 0 0 0 1] [0 1 0 0] ]]]
 	   [network [robot [example [1 0 0 0 0 0 1 0] [0 1 0 0] ]]]
 	   [network [robot [example [1 0 0 0 1 0 0 0] [0 0 0 1] ]]]
 	   [network [robot [example [1 0 0 1 0 0 0 0] [0 0 1 0] ]]]
 	   [network [robot [example [1 0 1 0 0 0 0 0] [0 0 1 0] ]]]
 	   [network [robot [example [1 1 0 0 0 0 0 0] [0 1 0 0] ]]]
	   ];
*/     	

;;;
;;; Function like add(), but adding things at the end of the database
;;; (and much less efficient)
;;;

define backadd(item);
    item -> it;
    database nc_<> [^item] -> database
enddefine;

;;;
;;; Sigmoid activation function
;;; (transforms the net input of a neuron into its output)
;;;

define activation_function( input ) -> activation;
    lvars input, activation;

    if input > 10.0 then
	1.0 -> activation;
    elseif input < -10.0 then
	0.0 -> activation;
    else
    	1.0 / ( 1.0 + exp( - input ) ) -> activation;
    endif;
enddefine;


;;;
;;; Functions to access unit input
;;;

define access_input(unit) -> value;
    lvars unit, value;

    unit(2)(2)(7) ->value;
enddefine;

define set_input(value,unit);
    lvars value, unit;

    value -> unit(2)(2)(7);
enddefine;

set_input -> updater(access_input);

;;;
;;; Functions to access unit activation (output)
;;;

define access_activation(unit) -> value;
    lvars unit, value;

    unit(2)(2)(5) -> value;
enddefine;

define set_activation(value,unit);
    lvars value, unit;

    value -> unit(2)(2)(5);
enddefine;

set_activation -> updater(access_activation);

;;;
;;; Evaluate the activation (i.e. the output) of a
;;; neuron in the database given its name
;;; (the input of the neuron should have been already
;;; evaluated by calling eval_unit_input())
;;;

define eval_unit_activation( unit_name, network );
    lvars unit_name;
    ;;; vars network; ;;; changed A.S. Sat Dec 10 13:34:27 GMT 1994
    lvars network;

    lvars activation, unit_type;

    ;;; Find the neuron in the database
    present( ! [network [^network [unit ^unit_name ?unit_type = ?activation ==]]] ) ->;
    if (unit_type == "input") then
    	;;; If it is an input neuron simply copy
        ;;; the input into the activation slot
    	access_input(it) -> access_activation(it);
    else
        ;;; Otherwise, use the activation function
        activation_function( access_input(it) ) -> access_activation(it);
    endif;
enddefine;

;;;
;;; Evaluate the input of a neuron in the database given its name
;;; (the output of the neurons sending signals to such a neuron
;;; should have been already evaluated by calling eval_unit_output()
;;;

;;; A.S. changed network etc. to lvars Sat Dec 10 20:34:31 GMT 1994
define eval_unit_input( unit_name, network );
    lvars unit_name, input, network;
    lvars
		from_units, from_weights,
		from_unit, from_weight, current_neuron;

    lvars bias, unit_type;

    ;;; Find the current neuron in the database
    present( ! [network [^network [unit ^unit_name ?unit_type == ?bias]]] ) ->;
    it -> current_neuron;

    ;;; For hiddend and output neurons, the net input is the sum
    ;;; of the weighted outputs of the neurons connected to the
    ;;; present neuron plus the bias of the present neuron
    bias -> input;
    foreach ! [network [^network [connection ^unit_name ?from_units ?from_weights]]] do
    	for from_unit, from_weight in from_units, from_weights do
			;;; A.S. this cannot do anything as there are no variables set
			;;; bug??? No. It uses "it", which is set.
            present( [network [^network [unit ^from_unit ==]]] ) ->;
            input + from_weight * access_activation(it) -> input;
    	endfor;
    endforeach;

    ;;; Save the just evaluated input
    ;;; in the proper slot of the neuron
    input -> access_input(current_neuron);
enddefine;

;;;
;;; Function that ask the user to provide an example for some form
;;; of example-based learning mechanism
;;;

define default_user_interactor(input_list, network) -> output_list;
    lvars input_list, network, output_list;

    pr('Artificial Neural Network:'); pr([^network]); nl(1);
    pr('This is the input pattern:'); pr(input_list); nl(1);
    pr('Please provide the correct output pattern:');
    readline() -> output_list;
enddefine;

;;;
;;; Function that applies a set of inputs to the network and
;;; returns the network outputs
;;;

define eval_network( input_list, network ) -> output_list;
    lvars unit_name, unit_type, activation;
    lvars user_interactor;

    ;;;
    ;;; If an example matching the present input is present, use it
    ;;;

    if present( ! [network [^network [example ^input_list ?output_list]]] ) then
        return;

        ;;;
        ;;; otherwise, if the network has been trained, use it
        ;;;
        /**/
	
    elseif present( [network [^network [already_taught]]] ) then
        ;;; Consider each unit in turn
        foreach ! [network [^network [unit ?unit_name ?unit_type ==]]] do
            if unit_type == "input" then
            	
            	;;; Feed the input data in the input slot of input neurons and
            	;;; evaluate their activation
            	hd(input_list) -> access_input(it);
            	tl(input_list) -> input_list;
            	eval_unit_activation( unit_name, network );
    	    else
        	
        	;;; Evaluate the input and the activation of hidden/output neurons
        	eval_unit_input( unit_name, network );
        	eval_unit_activation( unit_name, network );
    	    endif;
    	endforeach;
    	
    	;;; Return a list of the activations of the output neurons
    	[%
      	  foreach ! [network [^network [unit ?unit_name output = ?activation ==]]] do
              activation;
      	  endforeach;
  	  %] -> output_list;
    	
    	;;;
    	;;; otherwise, if the USER has been trained, use her/him :)
    	;;;
    	/**/

    else
	if present( ! [network [^network [user_interactor ?user_interactor]]]) then
	    recursive_valof(user_interactor)(input_list, network) -> output_list;
        else
	    default_user_interactor(input_list, network) -> output_list;
	endif;
        backadd( [network [^network [example ^input_list ^output_list]]] );
    endif;
enddefine;

;;;
;;; Apply a threshold to the elements of a list,
;;; and build a correponding  list of 1s and 0s
;;;

define apply_threshold( input_list, threshold ) -> output_list;
    lvars input_list, thrshold, output_list, item;

    [%
      fast_for item in input_list do
	  if item >= threshold then
	      1;
          else
	      0;
      	  endif;
      endfor;
      %] -> output_list;
enddefine;

;;;
;;; Find the maximum element of a list
;;;

define find_max( input_list ) -> max_value;
    lvars input_list, max_value = -1e30, item;

    fast_for item in input_list do
		if item > max_value then
	    	item -> max_value;
      	endif;
    endfor;
enddefine;

;;; A.S. bug fixed Sat Dec 10 23:59:36 GMT 1994
define find_min( input_list ) -> min_value;
    lvars input_list, min_value = 1e30, item;

    fast_for item in input_list do
		if item < min_value then
	    	item -> min_value;
      	endif;
    endfor;
enddefine;

;;;
;;; Transform a list of 0s and 1s into a list of <true>s and <false>s
;;;

define binary2boolean( binary_list ) -> boolean_list;
    lvars binary_list, boolean_list;
    maplist( binary_list,
	     procedure;
		 == 1;
	     endprocedure ) -> boolean_list;
enddefine;

/*
binary2boolean([1 0 1 0 0 1] )==>
*/

;;;
;;; Transform a list of <true>s and <false>s into a list of 0s and 1s
;;;

define boolean2binary( boolean_list ) -> binary_list;
    lvars binary_list, boolean_list;
    maplist( boolean_list,
	     procedure;
		 if /**/ then 1; else 0; endif;
	     endprocedure ) -> binary_list;
enddefine;

/*
boolean2binary( [^true ^false ^false ^true] ) ==>
*/

;;;
;;; Some examples of neural predicates
;;; (a wapper is needed to convert 1's and 0's in True's and False's and
;;; to make a predicate fail if ALL the output values are 0)
;;;

;;; Any number of 1's can be present in output_list

define ann_predicate( input_list, network ) -> output_list;
    lvars net_output_list;
    lvars prudence;

    ;;; [DEBUG input_list ^input_list]==>
    eval_network( input_list, network ) -> net_output_list;
    unless present( ![prudence ?prudence]) then
		0.5 -> prudence;
    endunless;
    apply_threshold( net_output_list, prudence ) -> output_list;
enddefine;

;;; Only one 1 can be present in output_list

define ann_predicate_only_one( input_list, network ) -> output_list;

    lvars net_output_list, max_value;
    lvars prudence;

    eval_network( input_list, network ) -> net_output_list;
    if not(present( ! [prudence ?prudence])) then
	0.5 -> prudence;
    endif;
    find_max( net_output_list ) -> max_value;
    if max_value >= prudence then
    	apply_threshold( net_output_list, max_value ) -> output_list;
    else
	maplist(net_output_list, procedure(); ->; 0; endprocedure );
    endif;
enddefine;

/*
driver -> database;
eval_network([1 1 0 0], "driver" ) ==>
eval_network([1 0.3 0 0], "driver" ) ==>
ann_predicate( [1 1 0 0], "driver") ==>
robot -> database;
flush([prudence =]);add([prudence 0.9]);
ann_predicate( [1 1 0 0 0 0 0 0], "robot") ==>
ann_predicate( [1 1 0 0 0 0 0 0], "robot") ==>
ann_predicate( [1 1 1 0 0 0 0 0], "robot") ==>
ann_predicate( [1 1 1 1 0 0 0 0], "robot") ==>
ann_predicate( [1 1 1 1 1 0 0 0], "robot") ==>
flush([prudence =]);add([prudence 0.01]);
ann_predicate( [1 1 1 0 0 0 0 0], "robot") ==>
ann_predicate_only_one( [1 1 1 0 0 0 0 0], "robot") ==>
*/


;;;
;;; Function that prints a network in the NNCF format
;;;

;;; A.S. Changed network to lvars Sat Dec 10 20:29:53 GMT 1994
define ann_print_for_nncf( network );

    lvars  net_element;
    lvars count_net_element, len_net_element, item, len_item, count_item;
    dlocal pop_pr_quotes = false;

    foreach ! [network [^network ?net_element]] do
	length(net_element) -> len_net_element;
	pr(net_element(1));
	unless net_element(1) == "already_taught" then pr('('); endunless;
	
	for count_net_element from 2 to len_net_element do
	    net_element(count_net_element) -> item;
	    if islist( item ) then
		length(item) -> len_item;
		pr('[');
		for count_item to len_item do
		    pr(item(count_item));
	    	    if count_item /= len_item then
			pr(',');
	    	    endif;
		endfor;
		pr(']');
	    else;
	    	pr(item);
	    endif;
	    if count_net_element /= len_net_element then
		pr(',');
	    endif;
	endfor;
	unless net_element(1) == "already_taught" then pr(')'); endunless;
	nl(1);
    endforeach;
enddefine;

/*
robot -> database;
ann_print_for_nncf( "robot" );
*/

;;;
;;; Function that writes a network in the NNCF format into a file,
;;; calls the nncf program to train/test it and read the modified version
;;; into the database

define ann_train( network, iterations, restart_training ) -> rmse;

    lconstant
		fname1 = '/tmp/ann_train.tmp.net',
	 	fname2 = '/tmp/ann_train.tmp.p';
    lvars tmp_ui = false, counter, rmse;
    dlocal pop_pr_ratios = false;

    flush([network [^network [network_type ==]]]);

    if restart_training then
	flush([network [^network [already_taught]]]);
    endif;

    if present([network [^network [user_interactor =]]]) then
	it -> tmp_ui;
	flush([network [^network [user_interactor =]]]);
    endif;

    flush([network [^network [iterations_number == ]]]);
    add([network [^network [iterations_number 0 ^iterations ^iterations]]]);

    save(fname1, ann_print_for_nncf(% network %));
    sysobey('nice -5 /tmp_mnt/home/staff/rmp/bin/nncf '<>fname1<>' '<>fname1<>' > /dev/null');
    sysobey('~rmp/bin/net2raw_pop '<>fname1<>' '<>fname2<>' '<>consstring(destword(network)), 33 );

    flush([network [^network  == ]]);

    if tmp_ui then
	add(tmp_ui);
    endif;

    lvars reader = pdtolist(incharitem(discin(fname2))), net_item;
    dlocal proglist = reader;

    until null(proglist) do
	listread() -> net_item;
	backadd(net_item);
    enduntil;

    sysobey('/bin/rm -f '<>fname1<>' '<>fname2, 33 );

    0 -> counter;
    foreach [network [^network [example ==]]] do
    	counter fi_+ 1 -> counter;
    endforeach;
	
	lvars tss;
    present(! [network [^network [tss ?tss]]]) -> ;

    sqrt( tss / counter) -> rmse;
enddefine;

/*
robot -> database;
ann_train( "robot", 200, true ) ==>
ann_train( "robot", 200, false ) ==>
ann_train( "robot", 200, false ) ==>
ann_train( "robot", 2000, false ) ==>
*/
