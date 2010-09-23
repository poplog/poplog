/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/lib/matrix_functions.p
 > Purpose:         Matrix manipulation methods; specific to vehicle agent as
	defined in vehicle.agent.p.
 > Author:          Duncan K Fewkes, Jan 14 2000 (see revisions)
 > Documentation:
 > Related Files: vehicle.agent.p
 */

/*

CONTENTS - (Use <ENTER> gg to access required sections)

 define parity_check(matrix);
 define multiply_with_matrix(list, matrix);

*/

/*
PROCEDURE: parity_check (matrix)
INPUTS   : matrix is a list of lists
OUTPUTS  : result is the number of elements in each list. For it to be a proper
            matrix, this number must match the number of lists in the top list.
                If this does not hold, result is 'false'.
USED IN  : matrix creation and multiplication procedures.
CREATED  : 14 Jan 2000
PURPOSE  : check that matrices are proper matrices and for checking prior to
            matrix multiplication.

TESTS:

[[1 2 3]
 [3 2 1]
 [9 3 4]] -> matr;

[[12 2 3 4]
 [1 4 6 7]
 [4 6 8 2]
 [6857 324 654 234]] -> matr;

[[12 2 3 4]
 [1 4 6 7]
 [4 8 2]
 [6857 324 654 234]] -> matr;


parity_check(matr) ==>;
*/


define parity_check(matrix);

    lvars row;

    for row from 1 to length(matrix) do
        if length(matrix(row)) /= length(matrix)
        then
            [%'PARITY ERROR IN ROW', row%] ==>;
            return(false);
        endif;
    endfor;

    return(length(matrix));

enddefine;



/*
PROCEDURE: multiply_with_matrix (list, matrix)
INPUTS   : list, matrix
  Where  :
    list is a list to be multiplied into the matrix (list length must match
        the parity of the matrix).
    matrix is a list of lists (where the length of each list must match the
        number of lists).
OUTPUTS  : returns a list or false
USED IN  : calculating the activity of each unit in the vehicle
CREATED  : 14 Jan 2000
PURPOSE  : to multiply a list into a matrix (giving the result as another
                list)

TESTS:

[[2 2 3]
 [3 2 5]
 [1 3 4]] -> matr;

[2 3 5] -> lis;

multiply_with_matrix(lis, matr) -> result;
result ==>;


[[2 2 3]
 [3 2 5]
 [1 3 4 6]] -> matr;

[2 3 5 6] -> lis;

multiply_with_matrix(lis, matr) -> result;
result ==>;


[[2 2 3]
 [3 2 5]
 [1 3 4]] -> matr;

[2 3 5 6 7] -> lis;

multiply_with_matrix(lis, matr) -> result;
result ==>;



*/



define multiply_with_matrix(list, matrix);

    lvars parity, column, row, sum;
    lvars result = [];


    parity_check(matrix) -> parity;

    if not(parity) then
        ['MATRIX PARITY ERROR'] ==>;
        return(false);

    elseif parity /= length(list) then
        ['PARITY ERROR'] ==>;
        [%'MATRIX PARITY ', parity%] ==>;
        [%'LIST PARITY ', length(list)%] ==>;
        return(false);

    else

        for column from 1 to parity do
            0 -> sum;
            for row from 1 to parity do
                (list(row) * matrix(row)(column)) + sum -> sum;
            endfor;

            result <> [%sum%] -> result;

        endfor;

        return(result);

    endif;

enddefine;


;;; for "uses"
global constant matrix_functions = true;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Oct  8 2000
	Fixed header.
	Introduced "define" index

--- Duncan K Fewkes, Aug 30 2000
converted to lib format
 */
