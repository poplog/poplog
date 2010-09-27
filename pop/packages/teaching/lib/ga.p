/* --- Copyright University of Birmingham 2009. All rights reserved. ------
 > File:			$usepop/pop/packages/teaching/lib/ga.p
 > Purpose:			Introduction to basic Genetic Algorithms in POP11
 > Author:			Riccardo Poli Nov 1994 (see revisions)
 > 					Modified Aaron Sloman, Sep  1 2009
 > Documentation:   TEACH GA
 > Related Files:
 */

;;;
;;; Program:        ga.p
;;;
;;; Author:         Riccardo Poli
;;;
;;; Creation date:  Nov 1994
;;;
;;; Description:    Basic Genetic Algorithms in POP11
;;;
;;; Modified:       Jan 1996 - Fixed bug in fitness proportionate selection
;;;

section;

uses bitvectors;
lib datafile;

;;;
;;; Chromosome definition (fitness value + bit string)
;;;

defclass chromosome
{
  fitness,
  bit_string,
  bit_number
  };

;;;
;;; One point crossover
;;;

define cross( chromosome1, chromosome2, crossover_site ) -> offspring;
    lvars chromosome1, chromosome2, crossover_site;
    lvars offspring = conschromosome(undef,undef,undef);
    lvars counter;

    bit_number(chromosome1) -> bit_number(offspring);
    undef -> fitness(offspring);
    cons_with consbitvector
    {%
      for counter to bit_number(chromosome1) do
	  if ( counter <= crossover_site ) then
	      bit_string(chromosome1)(counter);
	  else
	      bit_string(chromosome2)(counter);
	  endif;
      endfor;
      %} -> bit_string(offspring);
enddefine;

/*
vars c1 = conschromosome( 0, {1 1 1 1 1 1 1 1}, 8 ),
     c2 = conschromosome( 0, {0 0 0 0 0 0 0 0}, 8 );
c1 ==>
c2 ==>
vars i;
for i from 0 to 8 do
    cross( c1, c2, i) ==>
endfor;
*/


;;;
;;; Revert a bit (0-->1, 1-->0)
;;;

define revert( bit ) -> reverted;
    lvars bit, reverted;

    if ( bit = 0 ) then
	1 -> reverted;
    else
	0 -> reverted;
    endif;
enddefine;

/*
revert( 1 ) ==>
revert( 0 ) ==>
*/


;;;
;;; One site mutation
;;;

define mutate( chromosome, mutation_site ) -> offspring;
    lvars chromosome, mutation_site;
    lvars offspring = conschromosome(undef,undef,undef);
    lvars counter;

    bit_number(chromosome) -> bit_number(offspring);
    cons_with consbitvector
    {%
      for counter to bit_number(chromosome) do
	  if ( counter = mutation_site ) then
	      revert(bit_string(chromosome)(counter));
	  else
	      bit_string(chromosome)(counter);
	  endif;
      endfor;
      %} -> bit_string(offspring);
enddefine;

/*
vars c1 = conschromosome( 0, {1 1 1 1 1 1 1 1}, 8 ),
     c2 = conschromosome( 0, {0 0 0 0 0 0 0 0}, 8 );
c1 ==>
c2 ==>
vars i;
for i from 1 to 8 do
    mutate( c1, i) ==>
endfor;
for i from 1 to 8 do
    mutate( c2, i) ==>
endfor;
*/

;;;
;;; Generate a random chromosome
;;;

define make_random_chromosome( chromosome_len ) -> chrom;
    lvars  chromosome_len, chrom = conschromosome(undef,undef,undef);

    chromosome_len -> bit_number(chrom);
    cons_with consbitvector
    {%
      repeat chromosome_len times
	  oneof([0 1]);
      endrepeat;
      %} -> bit_string(chrom);
enddefine;

/*
repeat 20 times bit_string(make_random_chromosome( 5 )) endrepeat ==>
make_random_chromosome( 5 ) =>
make_random_chromosome( 5 ) =>
make_random_chromosome( 10 ) =>
make_random_chromosome( 200 ) =>
*/

;;;
;;; Population definition
;;;

defclass population
{
  average_fitness,
  min_fitness,
  max_fitness,
  fitness_function,
  chromosomes,
  chromosome_number,
  best_chromosome,
  worst_chromosome
  };

;;;
;;; Generate random bit-string population
;;;

define make_random_population( chromosome_num, chromosome_parms,
			       fitness_func ) -> pop;
    lvars chromosome_num, chromosome_parms,
	 fitness_func, pop = conspopulation(undef,undef,undef,undef,
					    undef,undef,undef,undef);

    chromosome_num -> chromosome_number(pop);
    fitness_func -> fitness_function(pop);

    {%
      repeat chromosome_num times
	  make_random_chromosome( chromosome_parms );
      endrepeat;
      %} -> chromosomes(pop);
enddefine;

;;;
;;; Read a parameter encoded as part of a bit string
;;;

define get_bit_string_parameter( bit_str, start_position, len,
			     	 lower_limit, scale ) -> parameter;
    lvars bit_str, start_position, len, lower_limit, scale, parameter;
    lvars counter, int_value = 0, multiplier = 1,
	 end_position = start_position + len - 1;

    ;;; Evaluate the integer representation of the bit-string field
    for counter from start_position to end_position do
	int_value + bit_str(counter) * multiplier -> int_value;
	multiplier * 2 -> multiplier;
    endfor;

    ;;; Evaluate the parameter
    int_value / (multiplier - 1) * scale + lower_limit -> parameter;
enddefine;

/*
vars bv = consbitvector(0, 1, 0, 0, 0, 5);
get_bit_string_parameter( bv, 1, 5, 0.0, 1.0 ) ==>
consbitvector(1, 1, 1, 1, 1, 5) -> bv;
get_bit_string_parameter( bv, 1, 5, 0.0, 1.0 ) ==>
consbitvector(1, 0, 0, 0, 0, 5) -> bv;
bv ==>
get_bit_string_parameter( bv, 1, 5, 0.0, 1.0 ) ==>
get_bit_string_parameter( bv, 1, 5, 0, 1 ) ==>
*/

;;;
;;; Write a parameter encoded as part of a bit string
;;;

define set_bit_string_parameter( bit_str, start_position, len,
			     	 lower_limit, scale, parameter );
    lvars bit_str, start_position, len, lower_limit, scale, parameter;
    lvars counter, int_value, divisor = 2 ** len,
	 end_position = start_position + len - 1;

    ;;; Evaluate the integer representation of the parameter
    round(( parameter - lower_limit ) / scale * (divisor-1)) -> int_value;

    ;;; Evaluate the integer representation of the bit-string field
    for counter from end_position by -1 to start_position do
	divisor / 2 -> divisor;
	int_value // divisor -> (int_value,bit_str(counter));
    endfor;
enddefine;

/*
vars bv = consbitvector(0, 0, 0, 0, 0, 5);
set_bit_string_parameter( bv, 1, 5, 0.0, 1.0, 0.0 ); bv ==>
set_bit_string_parameter( bv, 1, 5, 0.0, 1.0, 0.52 ); bv ==>
set_bit_string_parameter( bv, 1, 5, 0.0, 1.0, 1.0 ); bv ==>
set_bit_string_parameter( bv, 1, 5, 0.0, 1.0, 0.33 ); bv ==>
get_bit_string_parameter( bv, 1, 5, 0.0, 1.0 ) ==>
*/

;;;
;;; A simple function that evaluates the number of
;;; 0->1 and 1->0 transitions in the bit_string contained in a
;;; chromosome and assigns such a value to the fitness slot of the
;;; chromosome
;;;

define test_fitness_function( chrom );
    lvars chorm, bit_str = bit_string(chrom), fit = 0, counter;

    for counter from 2 to bit_number(chrom) do
	if ( bit_str(counter-1) /= bit_str(counter) ) then
	    fit + 1 -> fit;
	endif;
    endfor;
    fit -> fitness(chrom);
enddefine;
	
/*
vars c = conschromosome( undef, { 1 0 1 0 }, 4 );
test_fitness_function( c );
c ==>
make_random_population( 10, 10, "test_fitness_function" ) ==>
*/

;;;
;;; Evaluate the fitness of each chromosome of a population
;;; and related population parameters
;;;

vars procedure population_stats;

define evaluate_population( pop );
    lvars pop, counter;
    lvars fit_func = recursive_valof(fitness_function(pop));

    fast_for counter to chromosome_number(pop) do
	if ( fitness(chromosomes(pop)(counter)) == undef ) then
	    fit_func( chromosomes(pop)(counter) );
	endif;
    endfor;

    population_stats(pop);
enddefine;

define population_stats( pop );
    lvars pop, counter, pop_fitness = 0;
    lvars min_fit = 1e30, max_fit = -1e30, fit;
    lvars best_chrom = 1, worst_chrom = 1;

    fast_for counter to chromosome_number(pop) do
 	fitness(chromosomes(pop)(counter)) -> fit;
	fit + pop_fitness -> pop_fitness;
	if ( fit > max_fit ) then
	    fit -> max_fit;
	    counter -> best_chrom;
	endif;
	if ( fit < min_fit ) then
	    fit -> min_fit;
	    counter -> worst_chrom;
	endif;
    endfor;
    pop_fitness / chromosome_number(pop) -> average_fitness(pop);
    min_fit -> min_fitness(pop);
    max_fit -> max_fitness(pop);

    best_chrom -> best_chromosome(pop);
    worst_chrom -> worst_chromosome(pop);
enddefine;
	
	
	
/*
vars p = make_random_population( 10, 20, "test_fitness_function" );
evaluate_population(p);
average_fitness( p ) ==>
min_fitness( p ) ==>
max_fitness( p ) ==>
best_chromosome( p ) ==>
chromosomes(p)(best_chromosome( p )) ==>
mutate((chromosomes(p)(1)),1) -> chromosomes(p)(1);
evaluate_population(p);
average_fitness( p ) ==>
min_fitness( p ) ==>
max_fitness( p ) ==>
best_chromosome( p ) ==>
chromosomes(p)(best_chromosome( p )) ==>
*/

;;;
;;; Roulette wheel selection procedure
;;; A random chromosome of a population is returned (the selection is biased
;;; so that better chromosomes have a higher probability of being returned)
;;;

define roulette_wheel_select( pop ) -> chrom;
    lvars pop, chrom, sum = 0, threshold, counter;

    random0(number_coerce(chromosome_number(pop)*average_fitness(pop),1.0)) -> threshold;
    for counter to chromosome_number(pop) do
	sum + fitness(chromosomes(pop)(counter)) -> sum;
	if ( threshold <= sum ) then
	    chromosomes(pop)(counter) -> chrom;
	    ;;; npr(counter);
	    return;
	endif;
    endfor;
    chromosomes(pop)(chromosome_number(pop)) -> chrom;
enddefine;

/*
vars p = make_random_population( 10, 20, "test_fitness_function" );
evaluate_population(p);
p ==>
repeat 10 times roulette_wheel_select(p) ==> endrepeat;
*/

;;;
;;; Tournament selection procedure
;;; A random chromosome of a population is returned (the selection is biased
;;; so that better chromosomes have a higher probability of being returned)
;;;

define tournament_select( pop, num ) -> chrom;
    lvars pop, chrom, sum = 0, threshold, counter, tournament;

    [%
      repeat num times
    	chromosomes(pop)(random(number_coerce(chromosome_number(pop),1)))
    endrepeat
    %] -> tournament;
    syssort(tournament,false,
	    procedure(x,y);
		lvars x,y;
		return (fitness(x) > fitness(y) );
	    endprocedure ) -> tournament;

    hd(tournament) -> chrom;
enddefine;

/*
vars p = make_random_population( 10, 20, "test_fitness_function" );
evaluate_population(p);
p ==>
repeat 10 times tournament_select(p,4) ==> endrepeat;
*/

;;;
;;; Build an intermediate population containing
;;; chromosomes of the previous one, selected with a
;;; probability proportional to their fitness
;;; (fitness-proportionate selection)
;;;

define fitness_proportionate_selection( current_pop ) -> selected_pop;
    lvars current_pop, selected_pop = conspopulation(undef,undef,undef,undef,
					    undef,undef,undef,undef);

    ;;; Copy some slots from the previous population to the new one
    chromosome_number(current_pop) -> chromosome_number(selected_pop);
    fitness_function(current_pop) -> fitness_function(selected_pop);

    ;;; Select the chromosomes for the new population
    {%
      repeat chromosome_number(current_pop) times
	  copydata(roulette_wheel_select(current_pop));
      endrepeat;
      %} -> chromosomes(selected_pop);
enddefine;

/*
vars q, p = make_random_population( 10, 20, "test_fitness_function" );
evaluate_population( p );
stats( '0', p, undef );
fitness_proportionate_selection( p ) -> q;
evaluate_population( q );
stats( '0.5', q, undef );
*/

;;;
;;; Build an intermediate population containing
;;; chromosomes of the previous one, selected with a
;;; tournament selection
;;;

global vars tournament_size = 7;

define tournament_selection( current_pop ) -> selected_pop;
    lvars current_pop, selected_pop = conspopulation(undef,undef,undef,undef,
					    undef,undef,undef,undef);

    ;;; Copy some slots from the previous population to the new one
    chromosome_number(current_pop) -> chromosome_number(selected_pop);
    fitness_function(current_pop) -> fitness_function(selected_pop);

    ;;; Select the chromosomes for the new population
    {%
      repeat chromosome_number(current_pop) times
	  copydata(tournament_select(current_pop,tournament_size));
      endrepeat;
      %} -> chromosomes(selected_pop);
enddefine;

/*
vars q, p = make_random_population( 10, 20, "test_fitness_function" );
evaluate_population( p );
stats( '0', p, undef );
tournament_selection( p ) -> q;
evaluate_population( q );
stats( '0.5', q, undef );
*/

;;;
;;; Apply the crossover operator to pairs of chromosomes
;;; of the intermediate population so as to build a certain
;;; quantity of "offspring" chromosomes. The remain part of the
;;; population is made up of "parents"
;;;

define recombination( intermediate_pop, cross_probability ) -> recombined_pop;
    lvars intermediate_pop, cross_probability, parent1, parent2,
	 recombined_pop  = conspopulation(undef,undef,undef,undef,
					    undef,undef,undef,undef),
	 chrom_num = chromosome_number(intermediate_pop);
    lvars cross_number = round(cross_probability * chrom_num),
 	 clone_number = chrom_num - cross_number,
	 cross_site_num = bit_number(chromosomes(intermediate_pop)(1)) - 1;

    ;;; Copy some slots from the previous population to the new one
    chromosome_number(intermediate_pop) -> chromosome_number(recombined_pop);
    fitness_function(intermediate_pop) -> fitness_function(recombined_pop);

    ;;; Select the chromosomes for the new population
    {%
      ;;; Cloning part of the parents
      repeat clone_number times
	  copydata(chromosomes(intermediate_pop)(random(chrom_num)));
      endrepeat;

      ;;; Crossing part of the parents to get offspring chromosomes
      repeat cross_number times

	  ;;; Select two parents (no check for parent1 == parent2)
	  chromosomes(intermediate_pop)(random(chrom_num)) -> parent1;
	  chromosomes(intermediate_pop)(random(chrom_num)) -> parent2;
	
	  ;;; Mate them
	  cross( parent1, parent2, random(cross_site_num) );
      endrepeat;
      %} -> chromosomes(recombined_pop);
enddefine;

/*
vars q, p = make_random_population( 10, 20, "test_fitness_function" );
evaluate_population( p );
stats( 'original', p, undef );
recombination( p, 0.7 ) -> q;
evaluate_population( q );
stats( 'recombined', q, undef );
*/


;;;
;;; Apply mutation operator to a part of some chromosomes
;;; of the recombined population
;;;

define mutation( recombined_pop, mut_probability ) -> mutated_pop;
    lvars recombined_pop, mut_probability,  parent,
	 mutated_pop = conspopulation(undef,undef,undef,undef,
					    undef,undef,undef,undef);
    lvars total_pop_bits = chromosome_number(recombined_pop) *
	 bit_number(chromosomes(recombined_pop)(1)),
	 total_mutations = round(total_pop_bits * mut_probability);
    lvars chrom_num = chromosome_number(recombined_pop),
	 bit_num = bit_number(chromosomes(recombined_pop)(1));

    ;;; First, create a copy of the input population
    copydata(recombined_pop) -> mutated_pop;

    ;;; Then, mutate its bits in place
    repeat total_mutations times
	
	;;; Select a random chromosome and mutate a random bit of it
	random(chrom_num) -> parent;
	mutate(chromosomes(mutated_pop)(parent),random(bit_num))
	-> chromosomes(mutated_pop)(parent);
    endrepeat;
enddefine;

/*
vars q, p = make_random_population( 10, 20, "test_fitness_function" );
evaluate_population( p );
stats( 'original', p, undef );
mutation( p, 0.1 ) -> q;
evaluate_population( q );
stats( 'mutated', q, undef );
*/

;;;
;;; Print some generation statistics
;;;

define stats( generation, pop, solution_printer );
    lvars generation, pop;

    pr('Generation: '); pr(generation); nl(1);
    pr('  Avg. Fitness: '); pr(number_coerce(average_fitness( pop ),1.0));
    pr('  Min Fitness: '); pr(min_fitness( pop )); pr('  Max Fitness: ');
    pr(max_fitness( pop )); nl(1);
    pr('  Best chrom. number: '); pr(best_chromosome( pop )); nl(1);
    pr('  Best chrom.: ');
    pr(chromosomes(pop)(best_chromosome( pop ))); nl(1);
    if ( solution_printer /= undef ) then
	recursive_valof(solution_printer)(chromosomes(pop)
					  (best_chromosome( pop ))); nl(1);
    endif;
    nl(1);
enddefine;

/*
vars p = make_random_population( 10, 20, "test_fitness_function" );
evaluate_population(p);
stats( 10, p, undef );
*/

;;;
;;; Stopping criterion for GAP
;;;

define stopping_criterion( prev_pop, new_pop, epsilon,
			   best_chrom ) -> stop_please;
    lvars prev_pop, new_pop, epsilon, stop_please, best_chrom;

    if ( average_fitness( new_pop ) == 0 or
	 abs( ( average_fitness( prev_pop ) - average_fitness( new_pop ) ) /
	      average_fitness( new_pop ) ) < epsilon ) then
	true -> stop_please;
    else;
	false -> stop_please;
    endif;
enddefine;

/*
vars q, p = make_random_population( 10, 20, "test_fitness_function" );
evaluate_population(p);
copydata(p) -> q;
stopping_criterion(p,q) ==>
mutate(chromosomes(q)(1),1)->chromosomes(p)(1);
evaluate_population(p);
stopping_criterion(p,q) ==>
*/

;;;
;;; Converts a chromosome in a set of FP params (pushed into the stack)
;;;

define standard_float_converter( chrom, bits, parms );
    lvars chorm, bit_str = bit_string(chrom), bits, parms, counter, beginning = 1;

    for counter to parms do
    	get_bit_string_parameter( bit_str,  beginning, bits, -10.0, 20.0 );
	beginning + bits -> beginning;
    endfor;
enddefine;

;;;
;;; Converts a chromosome in a set of FP params (pushed into the stack)
;;;

define float_converter( chrom, bits, parms, min_val, max_val );
    lvars chorm, bit_str = bit_string(chrom), bits, parms, counter, beginning = 1;

    fast_for counter to parms do
    	get_bit_string_parameter( bit_str,  beginning, bits, min_val,
				  max_val - min_val );
	beginning + bits -> beginning;
    endfor;
enddefine;

;;;
;;; Converts a set of parameters into a chromosome
;;;

define float_encoder( chrom, bits, parms, min_val, max_val, parm_values );
    lvars chorm, bit_str = bit_string(chrom), bits, parms, counter,
	 beginning = 1, parm_values;

    fast_for counter to parms do
    	set_bit_string_parameter( bit_str,  beginning, bits, min_val,
				  max_val - min_val, parm_values(counter) );
	beginning + bits -> beginning;
    endfor;
enddefine;

;;;
;;; Transforms a function to be minimized >=0) in one to be maximized
;;;

define min_to_max_transform( value );
    lvars value;

    return ( - value);
enddefine;

;;;
;;; The opposite transformation
;;;

define max_to_min_transform( value );
    lvars value;

    return ( - value );
enddefine;


;;;
;;; Chromosome reordering procedure
;;;

define reorder_population( pop );
    lvars pop, fitness_list, counter;

    [%
      fast_for counter to chromosome_number(pop) do
	  [%
	    fitness(chromosomes(pop)(counter));
	    counter;
	    %]
      endfor;
      %] -> fitness_list;

    syssort(fitness_list, false, procedure(e1,e2); lvars e1, e2;
		hd(e1) > hd(e2); endprocedure ) -> fitness_list;

    {%
      fast_for counter in fitness_list do
	  chromosomes(pop)(counter(2));
      endfor;
      %} -> chromosomes(pop);
enddefine;

;;;
;;; Function that eliminates some chromosomes from a population
;;; (for overselection)
;;;

define keep_first_chromosomes_only( pop, num );
    lvars pop, num, counter;

    {%
      fast_for counter to num do
	  chromosomes(pop)(counter);
      endfor;
      %} -> chromosomes(pop);
    num -> chromosome_number(pop);
enddefine;


;;;
;;; Genetic Algorithm in Pop11 (GAP)
;;;
;;; Inputs:
;;;    Fitness function,
;;;    Number of chromosomes in the population (or filename if the
;;;           population is in a file),
;;;    Number of bits for each chromosome,
;;;    Maximum nunber of generations,
;;;    Probability of application of crossover operator (per chromosomes),
;;;    Probability of application of mutation operator (per bit),
;;;    Minimum variation of relative change of average population fitness,
;;;    Seed for random number generator,
;;;    Flag for printing stats (true/false)
;;;
;;; Outputs:
;;;    Chromosome with the maximum fitness ever generated
;;;

global vars greedy_overselection_factor = 1, elitist_selection = true,
selection_procedure = tournament_selection, best_chrom;

define genetic_algorithm( fit_function, pop_size, chrom_parms,
			  max_generations, crossover_probability,
			  mutation_probability, epsilon, seed,
 			  print_stats, solution_printer ) -> ga_result;
    lvars fit_function, pop_size, chrom_parms;
    lvars max_generations, generation;
    lvars current_pop,  new_pop;
    lvars tentatively_best_chrom;
    lvars epsilon, mutation_probability, crossover_probability,
	 seed, print_stats;
    lvars filename = concat_strings(['ga_pop.' ^(sysdaytime()) '.p']),
	 start_time = sys_real_time();

    ;;; Initialize random number gererator
    ;;; (if seed==false sys_real_time is used)
    seed -> ranseed;

    ;;; Initialize the population with random chromosomes (bit strings)
    ;;; and evaluate the fitness of its chromosomes
    ;;; with overselection
    if isnumber(pop_size) then
    	make_random_population( greedy_overselection_factor * pop_size,
			    	chrom_parms, fit_function ) -> current_pop;
    	evaluate_population( current_pop );
    	if greedy_overselection_factor > 1 then
    	    reorder_population( current_pop );
    	    keep_first_chromosomes_only( current_pop, pop_size );
    	    evaluate_population( current_pop );
    	endif;
	current_pop -> datafile(filename);
    elseif isstring(pop_size) then
	pop_size -> filename;
	datafile(filename) -> current_pop;
    elseif islist(pop_size) then
    	make_random_population( greedy_overselection_factor * pop_size(1),
			    	chrom_parms, fit_function ) -> current_pop;
    	evaluate_population( current_pop );
    	if greedy_overselection_factor > 1 then
    	    reorder_population( current_pop );
    	    keep_first_chromosomes_only( current_pop, pop_size(1) );
    	    evaluate_population( current_pop );
    	endif;
    endif;

    ;;; Save best chromosome
    copydata(chromosomes(current_pop)(best_chromosome(current_pop)))
    -> best_chrom;

    ;;; Print some stats for generation 0
    if ( print_stats ) then
	stats( 'Initial', current_pop, solution_printer );
    endif;

    ;;; Main loop of GAP
    for generation to max_generations do

	;;; Build an intermediate population containing
	;;; chromosomes of the previous one, selected with a
	;;; probability proportional to their fitness
	;;; (fitness-proportionate selection)
	selection_procedure( current_pop ) -> new_pop;

	;;; Apply the crossover operator to pairs of chromosomes
	;;; of the intermediate population so as to build a certain
	;;; quantity of "offspring" chromosomes. The remain part of the
	;;; population is made up of "parents"
	recombination( new_pop, crossover_probability )
	-> new_pop;

	;;; Apply the mutation operator on a small number of chromosomes
	;;; to regenerate genetic material that has been possibly lost
	mutation( new_pop, mutation_probability ) -> new_pop;

	;;; Evaluate the new population
	evaluate_population(new_pop);

	;;; Save best chromosome if better than previous best
    	copydata(chromosomes(new_pop)(best_chromosome(new_pop)))
    	-> tentatively_best_chrom;
	if ( fitness(best_chrom) < fitness(tentatively_best_chrom)) then
	    tentatively_best_chrom -> best_chrom;
	else
	    if elitist_selection then
	    	;;; Elitist step
	    	copydata(best_chrom) ->
		chromosomes(new_pop)(worst_chromosome(new_pop));
	    	;;;  Recompute population statistics
	    	population_stats(new_pop);
	    endif;
	endif;

	;;; Print some stats
    	if ( print_stats ) then
	    stats( generation, new_pop, solution_printer );
	endif;
	
	;;; Additional stopping criterion
	if ( stopping_criterion( current_pop, new_pop, epsilon,
				 best_chrom ) ) then
	    best_chrom -> ga_result;
    	    if not(islist(pop_size)) then
		new_pop -> datafile(filename);
	    endif;
	    return;
	endif;

	new_pop -> current_pop;
	;;; Save every 30 minutes or the time required by an iteration (if >)
	if  sys_real_time() - start_time > 1800 then
	    if not(islist(pop_size)) then
		current_pop -> datafile(filename);
	    endif;
	    sys_real_time() -> start_time;
	endif
    endfor;

    if ( print_stats ) then
    	stats( 'Final', new_pop, solution_printer );
    endif;

    best_chrom -> ga_result;
    if not(islist(pop_size)) then
    	new_pop -> datafile(filename);
    endif;
enddefine;

/*
genetic_algorithm( "test_fitness_function", [100], 200, 50, 0.7, 0.01, 0, false, true, undef ) ==>
*/

global vars ga = true;	;;; for uses

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  1 2009
	Added to main poplog distribution. Added header, and changed to use
	datafile, now able to cope with closures and procedures.
 */
