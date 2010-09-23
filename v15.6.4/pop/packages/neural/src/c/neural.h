/* *** Copyright Integral Solutions Ltd 1993. All rights reserved ***
   File:          neural.h
   Purpose:       Feed forward networks with back propagation learning
   Author:        David Watkins, Feb 1994
   Documentation  neurals help/backprop
   Related Files  backprop.c complearn.c ranvecs.c
*/

#include <stdlib.h>

#ifndef RAND_MAX
#ifdef sun
#define RAND_MAX    2147483647
#else
#define RAND_MAX    32767
#endif
#endif
