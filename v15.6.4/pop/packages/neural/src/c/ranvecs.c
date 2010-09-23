/* *** Copyright Integral Solutions 1993. All rights reserved ***
   File:          ranvecs.c
   Purpose:       Random initialisation for net vectors
   Author:        David Watkins, Mar 1993
                  Modified for all UNIX systems by Julian Clinton, Aug 1993
   Related Files  ranvecs.o, ranvcdef.p
*/

#include <math.h>
#include "neural.h"

void ranuvec(vec, n, x0, x1)
double *vec;
int    n;
double  x0;
double  x1;

{
  while(n--) {
    vec[n] = (((double) rand())/RAND_MAX) * (x1 - x0) + x0;
  };
}


void ranivec(vec, n ,m0, m1)
int   *vec;
int    n;
int    m0;
int    m1;

{
  while(n--) {
    vec[n] = (int) ((((double) rand())/RAND_MAX) * ( m1 - m0) + m0);
  };
}



void rangvec(vec, n, mean, sd)
double *vec;
int    n;
double  mean;
double  sd;

{
  int count;
  double sum;

  while(n--)
  {
    sum=0.0;
    for(count=12; count; count--)
      sum += ((double) rand())/RAND_MAX;
    vec[n] = mean + sd * (sum - 6.0);
  }
}



void randinit(i)
int    i;

{
  srand(i);
}


void rrandinit(i)
int    i;

{
  srand(i);
}
