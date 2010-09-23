;;;
;;; File:       texture_demo.p
;;; Author:     Julian Clinton, Dec 1992
;;; Purpose:    Recognising Different Textures Using Neural Networks
;;;


;;; Each texture pattern is a 10 x 10 grid
;;;
vars X_DIM = 10, Y_DIM = 10;


;;; Number of "pixels" per line
;;;
vars LINE_LEN = 5;


;;; Number of lines generated per texture
;;;
vars N_LINES = 10;




;;; We'll generate the patterns automatically into GEN_ARRAY.
;;; The contents of the array can then be written to disk
;;;
global vars GEN_ARRAY = newarray([1 ^X_DIM 1 ^Y_DIM], 0);

;;; after each pattern, we need to reset each cell in the array to 0
;;;
define reset_array();
lvars x y;

    fast_for x from 1 to X_DIM do
        fast_for y from 1 to Y_DIM do
            0 -> GEN_ARRAY(x,y);
        endfast_for;
    endfast_for;
enddefine;


;;; take the array and "draw" a line LINE_LEN pixels long at the appropriate
;;; point and extending in the appropriate direction. If the line gets
;;; extended off the "edge" of the array, it gets clipped.
;;;
define gen_len(x_delta, y_delta, x_pos, y_pos);
lvars  x_delta y_delta x_start y_start;

    repeat LINE_LEN times
        1 -> GEN_ARRAY(x_pos, y_pos);
        x_pos + x_delta -> x_pos;
        y_pos + y_delta -> y_pos;

        ;;; clip the location
        if x_pos > X_DIM then
            1 -> x_pos;
        elseif x_pos < 1 then
            X_DIM -> x_pos;
        endif;
        if y_pos > Y_DIM then
            1 -> y_pos;
        elseif y_pos < 1 then
            Y_DIM -> y_pos;
        endif;
    endrepeat;
enddefine;


;;; gen_pattern takes the number of lines to be drawn onto the array
;;; the value by which the x and y position should be changed (each
;;; will be either 1, 0 or -1. Note the caller routine has to take
;;; care that at least one of x_delta and y_delta are non-zero.
;;;
define gen_pattern(n, x_delta, y_delta);
lvars n x_delta y_delta x_pos y_pos;

    repeat n times
        random(X_DIM) -> x_pos;
        random(Y_DIM) -> y_pos;
        gen_len(x_delta, y_delta, x_pos, y_pos);
    endrepeat;
enddefine;


;;; Once a pattern has been generated, it has to be written to disk.
;;; This routine is passed a filename and writes the contents of the
;;; array GEN_ARRAY to disk.
;;;
define write_pattern(filename);
lvars filename dev x y;

    discout(filename) -> dev;
    fast_for y from 1 to Y_DIM do
        fast_for x from 1 to X_DIM do
            if GEN_ARRAY(x, y) == 0 then
                dev(`0`);
            else
                dev(`1`);
            endif;
        endfast_for;
        dev(`\n`);
    endfast_for;

    dev(termin);
enddefine;


;;; This routine writes the class of the pattern to disk. The caller
;;; is responsible for ensuring the file numbers are consistent with
;;; the number of the texture file.
;;;
define write_class(filename, class);
dlocal cucharout;
lvars filename class dev;

    discout(filename) -> cucharout;
    npr(class);
    cucharout(termin);
enddefine;


;;; Given the X and Y deltas, work out what class of line. Note that
;;; the diagonal classes appear to be swapped since the grids are
;;; flipped when written to disk (although it doesn't actually make
;;; any difference since the class
define get_class(x_delta, y_delta) -> class;
lvars x_delta y_delta class;


    if sign(x_delta) == 0 then
        "vert"
    elseif sign(y_delta) == 0 then
        "hor"
    elseif sign(x_delta) /== sign(y_delta) then
        "bl_tr"
    else
        "tl_br"
    endif -> class;
enddefine;


;;; gen_patterns is the main routine. It takes the number of texture
;;; pattern files to generate and the base names for the pattern and
;;; class files (these are used as arguments to sprintf). Closures
;;; of gen_pattern are created for generating training and test examples.
;;;
define gen_patterns(n, pattern_names, class_names);
lvars pattern_names class_names count n x_delta y_delta class;

    for count from 1 to n do
        0 ->> x_delta -> y_delta;

        ;;; this loop ensures that at least one of x_delta and y_delta
        ;;; is non-zero.
        ;;;
        while x_delta == 0 and y_delta == 0 do
            random(3) - 2 -> x_delta;
            random(3) - 2 -> y_delta;
        endwhile;

        get_class(x_delta, y_delta) -> class;
        reset_array();
        gen_pattern(N_LINES, x_delta, y_delta);
        write_pattern(sprintf(count, pattern_names));
        write_class(sprintf(count, class_names), class);
    endfor;
enddefine;


vars procedure gen_training_patterns =
    gen_patterns(%'texture_%p.bit', 'texture_class_%p.class'%);

vars procedure gen_test_patterns =
    gen_patterns(%'testtexture_%p.bit', 'test_class_%p.class'%);


;;; Defined but not really needed if using the UI
;;;
define do_training(iterations);
lvars iterations;

    nn_learn_egs("training_textures", "texture_net", iterations, true);
enddefine;


;;; Used to apply an example set to the texture network and display
;;; the results (actual and target).
;;; If send_to is a string, the items will be printed to the file
;;; named by string. Otherwise, results are printed to the screen.
;;;
define do_testing(send_to, egs_name);
dlocal cucharout;
lvars egs_name egs_rec file res targ files results targets send_to;

    nn_apply_egs(egs_name, "texture_net");
    nn_example_sets(egs_name) -> egs_rec;
    eg_gendata(egs_rec)(1) -> files;
    eg_out_examples(egs_rec) -> results;
    eg_targ_examples(egs_rec) -> targets;

    if send_to and isstring(send_to) then
        discout(send_to) -> cucharout;
    endif;

    for file, targ, res in files, targets, results do
        printf(hd(res), hd(targ), file, 'File: %p,    Target: %p,    Actual: %p\n');
    endfor;

    if send_to and isstring(send_to) then
        cucharout(termin);
    endif;
enddefine;


;;; Used to check training data
vars procedure check_train = do_testing(%"training_textures"%);
/*
;;; Call this as:

    check_train(false);

to get info on screen or to send to file 'results.out', do:

    check_train('results.out');

*/


;;; Used to check test data
vars procedure check_test = do_testing(%"test_textures"%);
/*
;;; Call this as:

    check_test(false);

to get info on screen or to send to file 'results.out', do:

    check_test('results.out');

*/


;;; Main demo setup routine. Defines data types, example sets and networks
;;;
define do_setup();

    ;;; classes of lines:
    ;;;     vertical, horizontal,
    ;;;     bottom-left to top-right,
    ;;;     top-left to bottom-right
    ;;;
    nn_declare_set("classification", [vert hor bl_tr tl_br]);

    ;;; a texture file consists of a texture takes a character-based file
    ;;; of 100 bits (10 x 10)
    ;;;
    nn_declare_toggle("char_bit", `1`, `0`);
    nn_declare_file_format("texture_file",
        [% repeat (X_DIM * Y_DIM) times "char_bit"; endrepeat; %], DT_CHAR_FILE);

    nn_declare_file_format("class_file", [ classification ], DT_ITEM_FILE);

    ;;; make our example set. Note that the output field has the same number
    ;;; of units as the is the single group in the BP net.
    ;;;
    nn_make_egs("training_textures", [[in texture_file] [out class_file]],
        EG_FILE, ['texture_*.bit' 'texture_class_*.class'],
        EG_LITERAL, false, eg_default_flags);

    gen_training_patterns(80);
    nn_generate_egs("training_textures");

    ;;; Also set up a series of testing patterns
    nn_make_egs("test_textures", [[in texture_file] [out class_file]],
        EG_FILE, ['testtexture_*.bit' 'test_class_*.class'],
        EG_LITERAL, false, eg_default_flags);

    gen_test_patterns(20);
    nn_generate_egs("test_textures");

    "training_textures" -> nn_current_egs;
    "texture_net" -> nn_current_net;

    ;;; Finally, make the backprop net.
    ;;; Once the example sets etc.
    ;;; have been set up, you can simply mark this routine and
    ;;; compile it
    ;;;
    make_bpnet(eg_in_units(nn_example_sets("training_textures")),
        {49     ;;; units in layer 1
        25      ;;; units in layer 2
        4},     ;;; no. output units (do not modify)
        4,      ;;; initial variance of weights (-2 to +2)
        0.6,    ;;; learning rate (alpha)
        0.7     ;;; momentum (eta)
        ) -> nn_neural_nets("texture_net");

enddefine;


/*
;;; Once the example sets etc. have been set up, you can simply mark
;;; these lines and compile them to rebuild the network.
;;;
make_bpnet(eg_in_units(nn_example_sets("training_textures")),
    {49     ;;; units in layer 1
    25      ;;; units in layer 2
    4},     ;;; no. output units (do not modify)
    4,      ;;; initial variance of weights (-2 to +2)
    0.6,    ;;; learning rate (alpha)
    0.7     ;;; momentum (eta)
    ) -> nn_neural_nets("texture_net");
*/


/*
;;; Once the -do_setup- routine has been run once, you can mark
;;; and compile these lines to regenerate the TRAINING data
;;;
    gen_training_patterns(80);  ;;; generate 80 training patterns
    nn_generate_egs("training_textures");
*/


/*
;;; Once the -do_setup- routine has been run once, you can mark
;;; and compile these lines to regenerate the TEST data
;;;
    gen_test_patterns(20);      ;;; generate 20 test patterns
    nn_generate_egs("test_textures");
*/


/*
;;; Test the network with the test example set with

    check_test(false);
*/
