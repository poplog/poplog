/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:           $popneural/src/pop/nn_defs.p
 > Purpose:        global constant and variable declarations
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:
 */

define testpopneural();
    lvars machine;
    npr('Poplog-Neural Test Program');
    nl(1);
    npr('Creating network...');
    make_bpnet(2 , {2 1}, 1.0, 0.5, 0.9) -> nn_neural_nets("xor_net");
    "xor_net" -> nn_current_net;
    npr('OK. Now creating example set...');
    nn_make_egs("xor_set",
                [[in bit in1] [in bit in2] [out bit out]],
                [[0 0 0] [1 0 1] [0 1 1] [1 1 0]]);
	nn_generate_egs("xor_set");
    npr('OK. Now training network (may take up to half a minute or so)...');
    nn_learn_egs("xor_set", "xor_net", 2000, true);
    if nn_test_egs("xor_set", "xor_net", false) /= [[0] [1] [1] [0]] then
        npr('The network failed to learn. Recreating network...');
        make_bpnet(2 ,{2 1}, 2.0, 0.5,0.9) -> nn_neural_nets("xor_net");
        npr('OK. Now trying to train network...');
        nn_learn_egs("xor_set", "xor_net", 2000, true);
        if nn_test_egs("xor_set", "xor_net", false) /= [[0] [1] [1] [0]] then
            npr('Still failed to learn. Please try rebuilding Poplog-Neural');
            npr('If this does not work, please consult your supplier.');
        else
            npr('Network succeeded in learning.');
            npr('Installation OK.');
        endif;
    else
        npr('Network succeeded in learning.');
        npr('Installation OK.');
    endif;
enddefine;

testpopneural();

/*  --- Revision History --------------------------------------------------
Julian Clinton, 29/5/92
    Added explicit sectioning.
*/
