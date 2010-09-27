/*
TEACH INDUCE_RULES.P                              Aaron Sloman, Feb 1995
Modified Nov 2000
to prevent clash with "instance" in Objectclass

         CONTENTS - (Use <ENTER> g to access required sections)

 -- Introduction
 -- Generalising beyond the binary case
 -- This teach file
 -- Specifying induce_rules
 -- -- A simple example
 -- -- Another example: classifying animals
 -- More general definition of the inputs of induce_rules
 -- An example run of induce_rules
 -- Using the induced tree to generate tests for a new instance
 -- The program code starts here
 -- The main procedure: induce_rules
 -- A program to turn the decision tree into an expert system
 -- Further exercises

-- Introduction -------------------------------------------------------

This file introduces a procedure induce_rules to create a decision tree
from a set of instances. It is a simplified version of the ID3 algorithm
due to J. R. Quinlan, described in most text books of AI.

The version described below is close to that expounded in

    G.F.Luger and W.A. Stubblefield,
    Artificial Ingelligence: Structures and strategies for complex
        problem solving. (2nd Edition).
    Benjamin/Cummings Publishing Company, 1993

Most books on AI write as if the objective of the ID3 algorithm is to
create a decision tree to solve a binary classification problem, e.g.
the problem of deciding whether an object is or is not an X on the basis
of a set of yes-no questions Q1, Q2, Q3, etc.

-- Generalising beyond the binary case --------------------------------

The case of a binary decision tree with a binary outcome is a special
case of a more general problem, which is to take a set of facts about
individuals and their properties and see whether a decision tree can be
constructed which at each node performs a test which can have any of a
range of answers, and which allows any number of final categories to be
used to classify instances, instead of just yes/no or +/-
classifications.

For instance if the test is: "check colour" then the answers might be
any of "red", "orange", "yellow", "green", etc. If the test is "check
weight" the result may be any number in the continuous range of possible
numbers from 0 upwards. Thus instead of having only two branches at each
decision point the decision tree could have several branches, one for
each possible answer to the test at that point. Where the test allows
continuous results there is theoretically an infinite set of possible
test values, though usually the set will be quantized, i.e. broken down
into a finite set of intervals, e.g. 0-5, 5-10, 10-15, etc... (We'll
ignore details concerning boundary values.)

Similarly, instead of the tree having only two possible classifications
as its output, e.g. safe/unsafe, yes/no, +/-, or whatever, a tree might
have several possible classifications.

E.g. the game of twenty questions can end up with a wide range of
possible answers. Similarly a system for diagnosing bacterial infections
might end up with a range of possible answers:

    no infection, bacteriumA, bacteriumB, bacteriumC, etc.

A still more general system could end up by classifying each object with
a SET of final labels, not just a single label. E.g. tests on a patient
might show that there are TWO (or more) different bacterial infections
present.


-- This teach file ----------------------------------------------------

This teach file focuses on the case where the decision tree has
 o multi-way branches
    (e.g. each test may allow several possible outcomes,
    not just two),

 o multiple final categories, which are mutually exclusive.

I.e. the final result of using the tree to classify a new problem
instance is a SINGLE label to be applied to the instance, not a SET of
labels.

In other words, we are interested in decision trees that are

    a. multi-branch
    b. multi-category
    c. exclusive-category

-- Specifying induce_rules --------------------------------------------

Our task is to define a procedure

    induce_rules(tests, instances) -> tree;

which is given:

    1. a set of test specifications (described below)
    2. a set of instances, each described in terms of outcomes of those
       tests and the ultimate categorisation for that instance

and which and produces as output:

    3. a new decision tree for classifying instances on the basis
       of asking questions about it.

I.e. given a list of test types, and a list of instances having
different combinations of values of those test types, rule_instance will
create a decision tree induced from those instances.

-- -- A simple example

For example, suppose you have some boxes which are red or green and
square or oblong, and they are used to store small and large screws and
nails.

Given this list of two test types, each allowing two test answers:

    [[colour 1 red green ]
     [shape 2 square oblong]]

and the instance list:

    [[[red square] SmallScrew]
    [[red oblong] BigScrew]
    [[green square] SmallNail]
    [[green oblong] BigNail]]

induce_rules can be applied to them thus

    induce_rules(
        [[colour 1 red green ] [shape 2 square oblong]],
        [[[red square] SmallScrew] [[red oblong] BigScrew]
         [[green square] SmallNail] [[green oblong] BigNail]]) ==>

Do
    ENTER l1
to load this file, then mark and load the above command (which is not
compiled by ENTER l1, because it is inside a comment).

It will infer the following decision tree for classifying boxes
according to their content.

    ** [colour [red [shape [square SmallScrew] [oblong BigScrew]]]
               [green [shape [square SmallNail] [oblong BigNail]]]]

I.e. in order to classify an object first ask about the colour. If the
answer is red then ask about the shape, if the answer is square then the
category is "SmallScrew". Similarly for other answers.

The output of induce_rules is a decision tree which is recursively
defined as having a test name as its top node, and below that N
branches, where N is the number of possible values for that test. Each
branch is a decision tree that starts with the name of the test value
and then either has a subnode which is a final classification, or else
has a subnode which is itself a decision tree.

For example a subtree in the above output is

    [shape [square SmallScrew] [oblong BigScrew]]

and another is

    [shape [square SmallNail] [oblong BigNail]]

Each starts with the test type "shape", and then specifies the outcome
for each test value "square" or "oblong".


-- -- Another example: classifying animals

;;; Consider the following set of tests for identifying animals.
;;; Each test in the list of tests has the form
;;; [TEST_TYPE N value1 value2 value3 value4 ...]

;;; Each animal description (see below) is a list of values for tests,
;;; and N, the index, for the type, is an integer which indicates that
;;; this test_type always has its value in position  N.

vars animal_tests =
  [
    ['Number of legs' 1 0 2 4 6 8]
        ;;; The first 1 means that the value for this test must be the
        ;;; first item in an instance description. I.e. the index is 1.
    ['Number of wings' 2 0 2 4]
        ;;; The index is 2.
    ['External skeleton' 3 yes no]
    ['Lives in water' 4 yes no]
    ['Can fly' 5 yes no]
    ['Can talk' 6 yes no]
  ];


;;; You could consider how many additional tests would be needed for
;;; identifying animals, e.g. insects of different types.


;;; Now some biological data (not very realistic!)

vars animal_instances =
  [;;;legs wings ext  water fly  talk
    [[ 0    0    no   yes   no   no]  fish]
    [[ 0    0    no   yes   no   yes] mermaid]
    [[ 2    0    no   no    no   yes] human]
    [[ 2    2    no   yes   no   no] penguin]
    [[ 6    4    yes  no    yes  no] insect]
    [[ 6    4    yes  no    no   no] beetle]
    [[ 8    0    yes  no    no   no] spider]
    [[ 6    0    yes  no    no   no] damaged_spider]  ;;; don't believe this.
  ];

    induce_rules(animal_tests, animal_instances) ==>
    ** [Number of legs
        [0 [Can talk [yes mermaid] [no fish]]]
        [2 [Number of wings [0 human] [2 penguin]]]
        [6 [Number of wings
            [0 damaged_spider]
            [4 [Can fly [yes insect] [no beetle]]]]]
        [8 spider]]

The order of the test types in the list animal_tests determines the
structure of the tree. The test at the top of the tree is always the
first test in the list of test types. Which tests are used below the top
node depends on which ones are needed to discriminate instances sorted
by the previous question. But the order of tests as you go down the tree
is always the order in the list animal_tests.

Thus, the induced tree here says: first ask about the number of legs,
and depending whether the answer is 0, 2, 6, or 8 go to the
corresponding sub-tree. E.g. if the number of legs is 6, then the next
question will be to ask about the number of wing. Notice that some of
the tests are never invoked in this tree: e.g. is there an external
skeleton. (The algorithm for inducing the tree is in the procedure
definition for induce_tree, below.)

Now use induce rules with the list of test types given in the REVERSE
order, so that what was previously the first test now becomes the last,
and so on:

    induce_rules(rev(animal_tests), animal_instances) ==>

    ** [Can talk [yes [Lives in water [yes mermaid] [no human]]]
                 [no [Can fly [yes insect]
                              [no [Lives in water
                                   [yes [Number of wings
                                         [0 fish]
                                         [2 penguin]]]
                                   [no [Number of wings
                                        [0 [Number of legs
                                            [6 damaged_spider]
                                            [8 spider]]]
                                        [4 beetle]]]]]]]]

Notice that this second decision tree, derived from the same data as the
first, has a different shape. I.e. it is a deeper tree. It also uses
different tests. E.g. the first tree does not use the 'Lives in water'
test, whereas the second tree does. The first tree uses all possible
values for numbers of legs, whereas the second uses only values 6 and 8.

What can you conclude from this about the information provided for
inducing the rules?

Which tree is better for identifying animals (given the data provided)
originally?

Compare the two induced trees using showtree to produce graphical
output:

    uses showtree
    showtree(induce_rules(animal_tests, animal_instances))

    showtree(induce_rules(rev(animal_tests), animal_instances));

Showtree, when given a tree represented as a list structure, produces a
VED file with a graphical display of the tree. The file will have a name
like 'tree.t', 'tree1.t', 'tree2.t', etc. depending how many such
showtree files you have.

You can examine the showtree file just as if it were any other VED file.
To make it take up the full window use "ESC w". You can use
vedfileselect (ESC 3) to switch between files. (Or "ENTER rb" to
"rotate" the VED buffers.)

Try the above comands with the instances in different orders, and the
tests in different orders. Try adding more animals, e.g. a type of bird
that flies, insects that don't fly.

We'll now give a more general explanation of the inputs to
induce_rules.


-- More general definition of the inputs of induce_rules --------------

The procedure induce_rules has two lists as arguments.

tests:
    is a list of test specifications, e.g. colour, temperature, shape,
    clinical test, etc.

    We assume each test allows a discrete, finite set of values. Any
    continuous-valued tests will have to be quantized into sub-ranges.

    Each test specification in the list has the form

            [name INDEX val1 val2 val3...]
        e.g.
            [colour 1 red blue green orange ...]
            [shape 2 square oblong triangle ...]

    Where INDEX is an integer specifying the location of the value for
    this test in the list comprising an individual instance description.

    E.g. in the above examples each instance has colour first (INDEX = 1),
    then shape second (INDEX = 2), etc.,

    E.g. given the above test list, an instance may look like this:
            [[red square] screws]
    but not
            [[square red] screws]


instances:
    This is a list of instances, where each instance is of
    the following form:
        [[fv1, fv2, fv3, .. fvN] category]
    where
            fvi is the value of this instance for test i.
            category is the classification category assigned
            to this instance. For example it might be the result
            of a postmortem analysis or some other definitive
            investigation of test cases. This is the label that we
            wish to be able to predict in new instances, by using
            the generated decision tree.

For single concept induction there will be only two categories, i.e .
[+ -] or [yes no] or [true false].

For multiple classifications there may be several categories,
e.g. several diseases, several faults, several biological
categories.

-- An example run of induce_rules -------------------------------------

;;; AN EXAMPLE TO PROVIDE A TEST OF THE PROCEDURE INDUCE_RULES
;;; Do ENTER l1 to load the procedures in this file

;;; The classification is in terms of bugs causing an infection,
;;; i.e. bug1, bug2, bug3, etc.

;;; First specify the test types and then give a list of instances

vars
    ;;; The tests are got from three tests, which may have varying
    ;;; values
    tests =
      [
        [test1 1 t11 t12 t13]   ;;; a test with three possible outcomes
        [test2 2 t21 t22]       ;;; a test with only two
        [test3 3 t31 t32 t33 t34]   ;;; a test with four possibilities
      ],

    ;;; now some examples of instances, where each instance is a patient
    ;;; with some recorded test values and a bug found in that patient
    instances =
      [
        [[t11 t21 t31] bug1]
        [[t11 t21 t32] bug2]
        [[t12 t22 t33] bug3]
        [[t12 t22 t34] bug4]
        [[t13 t21 t31] bug1]
        [[t13 t21 t32] bug3]
        [[t13 t22 t33] bug3]
      ];

    ;;; You could try adding more data, keeping the instances
    ;;; consistent. Or more test types, or test values.

    ;;; Now induce some rules
    induce_rules(tests, instances) ==>
    ** [test1 [t11 [test3 [t31 bug1] [t32 bug2]]]
              [t12 [test3 [t33 bug3] [t34 bug4]]]
              [t13 [test2 [t21 [test3 [t31 bug1] [t32 bug3]]]
                          [t22 bug3]]]]

;;; We can make a prettier display, using the showtree library

    uses showtree;
    showtree( induce_rules(tests, instances) );

;;; Use ESC x, then ESC w to see the full tree produced by showtree.
;;; Use ESC x to come back here.

;;; Now try with some inconsistent data
vars
    tests2 =
    [
        [test1 1 t11 t12 t13]
        [test2 2 t21 t22]
    ],
    instances2=
    [
        [[t11 t21] bug1]
        [[t11 t21] bug3]   ;;; inconsistent with previous case
        [[t11 t22] bug2]
        [[t12 t22] bug3]
    ];

    induce_rules(tests2, instances2) ==>
    ** [test1 [t11 [test2 [t21 [INCONSISTENT
                                {[[t11 t21] bug1] [[t11 t21] bug3]}]]
                          [t22 bug2]]]
              [t12 bug3]]


;;; Notice that if the result of test1 is t12 there is no problem,
;;; whereas if the result is t11 then there could be a problem if the
;;; the result of test2 is t21.
;;; Inconsistent data are presented by a vector containing the data,
;;; under a node labelled with the word "INCONSISTENT"


;;; We can make a prettier display
    showtree(induce_rules(tests2, instances2));

;;; try it with the tests reversed:
    showtree(induce_rules(rev(tests2), instances2));

;;; To see what is going on try tracing some or all of the procedures
trace all_same_category getall induce_rules;
untrace all_same_category getall induce_rules;


-- Using the induced tree to generate tests for a new instance --------

The procedure classify_instance defined below can be given an induced
tree and it will use it to ask questions about test values for a new
instance which it will try to classify on the basis of the user's
answers. It behaves like a fairly rigid expert system.

You can try classify_instance out on the results of induce_rules for the
examples given above. Try inventing answers to the questions. If it can
infer the category of the instance it will return that as result,
otherwise the value false. Try each of these several times. You could
also trace classify_instance to see what is going on.

Example 1:

    classify_instance(
        induce_rules(
            [[colour 1 red green ] [shape 2 square oblong]],
            [[[red square] SmallScrew] [[red oblong] BigScrew]
                [[green square] SmallNail] [[green oblong] BigNail]])) =>

Example 2:

    classify_instance(induce_rules(tests, instances)) =>

Example 3:

This was the example with inconsistent data. See what happens if you get
down to the node of the tree for which data were inconsistent. Is this
satisfactory behaviour?

    classify_instance(induce_rules(tests2, instances2)) =>

Example 4:

    classify_instance(induce_rules(animal_tests, animal_instances)) =>

trace classify_instance;
untrace classify_instance;

*/


/*
-- The program code starts here ---------------------------------------
*/

;;; First some utility procedures.

define instance_category(item) -> category;
    ;;; the second element of an instance (item) is its category.
    ;;; could be redefined.
    lvars item, category;
    item(2) -> category
enddefine;


define instance_values(item) -> vals;
    ;;; Given an instance extract its list of test values
    lvars item, vals;
    hd(item) -> vals;
enddefine;

define instance_value(item, index) -> val;
    ;;; given an instance and a test index, return the value of
    ;;; that test for that instance.
    lvars item, index, val;
    instance_values(item)(index) -> val;
enddefine;

define index_of(test) -> index;
    ;;; the second element of a test specification is its index
    lvars test, index;
    test(2) -> index
enddefine;

define test_name(test) -> name;
    lvars test, name;
    hd(test) -> name
enddefine;

define test_values(test) -> vals;
    ;;; the test values come after the first two elements
    lvars test, vals;
    tl(tl(test)) -> vals
enddefine;


define all_same_category(instances) -> category;
    ;;; Does every instance get assigned to the same category?
    ;;; If so return the category, otherwise false

    lvars instances, category, item;

    destpair(instances) -> (item, instances);
    instance_category(item) -> category;
    for item in instances do
        unless instance_category(item) = category do
            false -> category; return;
        endunless;
    endfor;

enddefine;
/*
;;; tests

all_same_category( [ [[1 2] A] [[2 3] A] [[4 5] A]]) =>
    ** A

all_same_category( [ [[1 2] A] [[2 3] A] [[4 5] B]]) =>
    ** <false>


*/

define getall(test, test_val, instances) ->(this_branch, rest);
    ;;; For a given test, e.g. test3 and its possible value e.g. t3a,
    ;;; find all the instances that have that value for that test,
    ;;; and return a list of them as this_branch, leaving the remaining
    ;;; instances in the list rest, which is also returned

    lvars test, test_val, instances,
        this_branch = [],
        rest = [] ;

    lvars item, index = index_of(test);

    for item in instances do
        ;;; Get the test value in position index in this instance,
        ;;; and compare it with test_value, then decide which list
        ;;; to put the the instance into
        if instance_values(item)(index) == test_val then
            [^item ^^this_branch] -> this_branch
        else
            [^item ^^rest] -> rest
        endif
    endfor;

    ;;; Above, We built the lists up from the left end for efficiency,
    ;;; so the items will be in reverse order.
    ;;; Now restore the original order by reversing the lists.
    ;;; It is safe to use fast_ncrev (to save garbage collections) when
    ;;; we know we have built up properly constructed lists.
    fast_ncrev(this_branch) -> this_branch;
    fast_ncrev(rest) -> rest
enddefine;

/*
;;; test

vars
    test1 = [A 1 a1 a2 a3],
    test2 = [B 2 b1 b2 b3],
    data =
    [
        [[a1 b1] X]
        [[a2 b1] Y]
        [[a3 b1] Y]
        [[a1 b2] X]
        [[a2 b2] Y]
        [[a3 b2] X]
        [[a1 b3] X]
        [[a2 b3] Y]
        [[a3 b3] Y]
    ];

;;; NB rest will print first in these two tests. Get all with "a2"
getall(test1, "a2", data) ==> ==>
    ** [[[a1 b1] X]
        [[a3 b1] Y]
        [[a1 b2] X]
        [[a3 b2] X]
        [[a1 b3] X]
        [[a3 b3] Y]]
    ** [[[a2 b1] Y] [[a2 b2] Y] [[a2 b3] Y]]

;;; get all whose outcome for test2 has value "b3"
getall(test2, "b3", data) ==> ==>
    ** [[[a1 b1] X]
        [[a2 b1] Y]
        [[a3 b1] Y]
        [[a1 b2] X]
        [[a2 b2] Y]
        [[a3 b2] X]]
    ** [[[a1 b3] X] [[a2 b3] Y] [[a3 b3] Y]]

*/

/*
-- The main procedure: induce_rules -----------------------------------
*/

define induce_rules(tests, instances) -> tree;
    ;;; for specification see top of file

    lvars tests, instances, tree;

    lvars test, category, test_val, this_branch;
    if all_same_category(instances) ->> category then
        category -> tree;
    elseif tests == [] then
        ;;; A set of instances have come out with the same results for
        ;;; all tests, yet they don't have the same category label. so
        ;;; they are inconsistent.
        ;;; We could cause an error message, but it is more interesting
        ;;; not to.
        ;;; Return a special sub tree with the inconsistent instances
        ;;; collected in a vector (useful for showtree)
        [INCONSISTENT  {^^instances} ] -> tree;
    else
        ;;; Start building the tree. Recursion will do the main work
        [%
            ;;; Get the first test, and divide the instances according
            ;;; to the values they have for that test, and handle
            ;;; other tests by recursion
            hd(tests) -> test;

            ;;; Put test label at top of tree
            test_name(test),

            ;;; build subtrees for each possible test value
            for test_val in test_values(test) do
                quitif(instances == []);
                getall(test, test_val, instances) ->(this_branch,instances);
                unless this_branch == [] then
                    ;;; Build a partial tree for items having this
                    ;;; test_val for this test
                    [%test_val, induce_rules(tl(tests), this_branch)%]
                endunless;
            endfor
        %] -> tree;

        ;;; If the tree has only one branch the test used is spurious.
        ;;; so pull up the lower level sub tree and return that, except
        ;;; where the tree has the label "INCONSISTENT"
        ;;; Try commenting out the next three lines and see what difference
        ;;; it makes to the tests above!
        while islist(tree)
        and hd(tree) /== "INCONSISTENT"
        and listlength(tl(tree)) == 1
        do
            hd(tl(tree)) -> tree
        endwhile;
        ;;; check that all the instances got used!
        if instances /== [] then
            mishap('Unrecognized instance value?',[^test ^instances])
        endif
    endif
enddefine;

/*
-- A program to turn the decision tree into an expert system

Once you have a decision tree of the sort produced by induce_rules you
can use it with the procedure classify_instance defined below to
interrogate a user about a new instance, by asking a series of
questions, using the answers to traverse the tree, and ending with a
classification of the new instance. The program is fairly rigid as it
does not make use of any "don't know" answers, or any test values other
than those found in data used to create the original tree.

*/

define classify_instance(tree) -> category;
    lvars tree, category;
    if atom(tree) then
        ;;; found the answer, as a result of recursing down the tree
        tree -> category
    else
        ;;; the tree will have a test type and a list of subtrees each
        ;;; with a test-value at its root.
        lvars test_type, subtrees, vals, subtree, answer, count = 1;
        destpair(tree) -> (test_type, subtrees);
        ;;; Make a list of possible test values, with numeric codes
        [%'    ', for subtree in subtrees do
                ;;;
                count sys_>< ":", hd(subtree), '  ', count + 1 -> count;
            endfor,
            ;;; Replace last string with newline
            erase(), newline%] -> vals;
        repeat
            ['For test of type <' ^test_type
                    '> what value does the instance have?'] =>
            'Please type the numeric code for the value in this list'=>

            applist(vals, pr);
            'If you don\'t know or it is not one of these, just press RETURN' =>
            readline() -> answer;
            if answer == [] then
                false -> category;
                return()
            endif;
            if listlength(answer) == 1 then hd(answer) -> answer endif;
        quitif(isnumber(answer)
                and answer > 0
                and answer <= listlength(subtrees));
        'Sorry, that\'s not one of the acceptable numbers. Please try again' =>
        endrepeat;
        ;;; Use the number code to select the subtree and recurse
        ;;; on the head of its tail (because of the structure of the
        ;;; output of induce_rules
        hd(tl(subtrees(answer))) -> subtree;
        if islist(subtree) and hd(subtree) == "INCONSISTENT" then
            'Data for this case inconsistent'
        else
            classify_instance(subtree)
        endif -> category
    endif;
enddefine;

/*

-- Further exercises --------------------------------------------------

1. Create several large data-sets and see how well induce rules performs
with them. Can you construct a set of data and a set of tests such that
induce_rules produces a rather silly decision tree, e.g. one for each
each question only sets a single instance apart from the rest, so that
for identification of some instances you have to ask a great many
questions whereas for others you have to ask very few.

2. Try reading the literature on ID3 and see if you can change the
program so as to produce a more balanced decision tree.

3. Try to decide whether the above algorithm provides a sound basis for
predicting the outcome of new cases on the basis of old examples. Is
there any way you could improve its reliability?

4. How does a program like induce_rules compare with training a neural
net on examples?

5. Under what conditions can a tree produced by induce_rules classify an
instance with features that it has never seen before.

6. Produce a version of classify_instance, which, instead of
interrogating the user is given a decision tree and an instance and
produces a category for the instance (or false if it cannot).

7. As shown by the animals example near the beginning of this file, the
output of induce_rules for the same set of instances can be different
depending on the order in which the test specifications are given.
Sometimes the two decision trees produced for a given set of data and a
given set of test specifications will include different tests, or will
use different subsets of possible values for a given test (like the
animals example above). This can imply that the data show that there are
different sufficient conditions for something to be classified, and the
above procedure induce_rules will not find them all. Can you fix this?

8. Can you extend classify_instance so that if the current decision tree
does not enable you to classify an instance, you can have a little
dialogue in which you say how it should be classified, as a result of
which classify_instance modifies the decision tree? The easiest way
would be to make it add the new instance to the original list
of instances and then recreate the decision tree from the enlarged
list. Is there a better way to extend the decision tree incrementally?

9. Consider how induce_rules deals with inconsistent data. I.e. it
produces a node in the decision tree recording the inconsistency. Are
there better ways it could handle such data? (Presumably it will depend
on the problem domain.)

10. The procedure classify_instances has a very poor user interface.
What is wrong with it? Can you improve it? Would it be better to use
pop-up dialogue boxes ? (See HELP * POPUPTOOL)


*/

/*
--- $poplocal/local/teach/induce_rules.p
--- Copyright University of Birmingham 2000. All rights reserved. ------
*/
