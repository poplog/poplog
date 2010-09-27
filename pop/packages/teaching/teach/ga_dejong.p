/*----------------------------------------------------------------------
  TEACH GA_DEJONG
                                              Riccardo Poli Nov 1995


             More examples on how to use LIB GA to optimise
             some of De Jong test functions

----------------------------------------------------------------------*/

uses ga;

;;;
;;; A simple function that evaluates x1*x1 + x2*x2 + x3*x3
;;;

define problem1_fitness( chrom );
    lvars chorm, x1, x2, x3;

    standard_float_converter( chrom, 10, 3 ) -> (x1, x2, x3);

    min_to_max_transform( x1*x1 + x2*x2 + x3*x3 ) -> fitness(chrom);
enddefine;

;;;
;;; A printer function for the solutions of the problem
;;;

define problem1_printer( chrom );
    lvars chorm, bit_str = bit_string(chrom), x1, x2, x3;

    standard_float_converter( chrom, 10, 3 ) -> (x1,x2,x3);

    pr('Best solution: '); pr([ x1= ^x1 x2= ^x2 x3= ^x3]);
    pr('Function value ='); pr(max_to_min_transform(fitness(chrom)));nl(1);
enddefine;

/*
problem1_printer(genetic_algorithm( "problem1_fitness", [200], 30,
                                      50, 0.7, 0.01,
                                      0, false, true,"problem1_printer"));
*/




;;;
;;; A simple function that evaluates
;;; 100*(x1*x1 - x2)*(x1*x1 - x2)*(x1*x1 - x2) + (1.0 - x1)*(1.0 - x1)
;;;

define problem2_fitness( chrom );
    lvars chorm, x1, x2;

    standard_float_converter( chrom, 20, 2 ) -> (x1, x2);

    min_to_max_transform( 100*(x1*x1 - x2)*(x1*x1 - x2)*(x1*x1 - x2) + (1.0 - x1)*(1.0 - x1))
    -> fitness(chrom);
enddefine;

;;;
;;; A printer function for the solutions of the problem
;;;

define problem2_printer( chrom );
    lvars chorm, bit_str = bit_string(chrom), x1, x2;

    standard_float_converter( chrom, 20, 2 ) -> (x1,x2);

    pr('Best solution: '); pr([ x1= ^x1 x2= ^x2]);
    pr('Function value ='); pr(max_to_min_transform(fitness(chrom)));nl(1);
enddefine;

/*
problem2_printer(genetic_algorithm( "problem2_fitness", [200], 40,
                                      50, 0.7, 0.01,
                                      0, false, true,"problem2_printer"));
*/





;;;
;;; A simple function that evaluates
;;; sin(x) * (x-15) + 20
;;;

true -> popradians;

define problem3_fitness( chrom );
    lvars chorm, x;

    standard_float_converter( chrom, 20, 1 ) -> x;

    sin(x) * (x-15) + 20 -> fitness(chrom);
enddefine;

define problem4_fitness( chrom );
    lvars chorm, x;

    standard_float_converter( chrom, 20, 1 ) -> x;

    sin(1.0/(x+0.01)) * (x-15) + 20 -> fitness(chrom);
enddefine;

;;;
;;; A printer function for the solutions of the problem
;;;

define problem3_printer( chrom );
    lvars chorm, bit_str = bit_string(chrom), x;

    standard_float_converter( chrom, 20, 1 ) -> x;

    pr('Best solution: '); pr([ x= ^x]);
    pr(' Function value ='); pr(fitness(chrom));nl(1);
enddefine;



/*
problem3_printer(genetic_algorithm( "problem3_fitness", [20], 20,
                                      50, 0.7, 0.01,
                                      0, false, true,"problem3_printer"));
problem3_printer(genetic_algorithm( "problem4_fitness", [20], 20,
                                      20, 0.7, 0.01,
                                      0, false, true,"problem3_printer"));
*/

/*
--- $poplocal/local/teach/ga_dejong.p
--- Copyright University of Birmingham 1995. All rights reserved. ------
*/
