/* *** Copyright Integral Solutions Ltd 1993. All rights reserved ***
   File:          backprop.c
   Purpose:       Feed forward networks with back propagation learning
   Author:        David Watkins, Mar 1993
                  Modified for all UNIX systems by Julian Clinton, Aug 1993
   Documentation  neurals help/backprop
   Related Files  backprop.p backcdef.p
*/


/* *** WIDELY USED VARIABLES ***
activs   : <array double> avtivations of each unit excluding inputs
alpha    : <double>       momentum rate for backprop training
biases   : <array double> thresholds for each unit excluding inputs
bschange : <array double> threshold change used for momentum training
eta      : <double>       learning rate for backprop training
ifail    : <int>          flag to signal inconsistent variables
negs     : <int>          number of different training examples
nin      : <int>          number of input units
niter    : <int>          number of iterations during training
nlevels  : <int>          number of layers in network excluding inputs
ntarg    : <int>          number of units in output layer
ntunits  : <int>          number of units in network excluding inputs
nunits   : <array int>    units in each layer excluding input layer
nweights : <int>          total number of weights in network
outvec   : <array double> activations in output layer
stims    : <array double> inputs to be presented for training or results
targs    : <array double> required outputs for use in training
weights  : <array double> 1-d array of all weights; ordered 1st input to
                          1st hidden unit, 2nd input to 1st hidden unit...
wtchange : <array double> weight changes used for momentum training
*/




/* *** Standard Library Routines *** */

#include <math.h>
#include <stdio.h>
#include "neural.h"


/* *** Define macros for the activation and its derivative *** */

#define LOGFUNC(x) (1.0/(1.0+exp((double) -(x))))
#define LDERIV(y)  ((y) * (1.0 - (y)))



/* *** Check the consistency of the data   *** */
/* *** Returns 0 for OK, +ve int otherwise *** */

int checkns(nunits,
            nlevels,
            nin,
            nout,
            ntunits,
            nweights)
int *nunits;
int  nlevels,
     nin,
     nout,
     ntunits,
     nweights;
{
  int nlower, ncurrent;

  if (nout!=nunits[nlevels-1]) return 1;
  ncurrent=nin;
  while(nlevels--)
  {
    nlower=ncurrent;
    ncurrent = *nunits++;
    ntunits -= ncurrent;
    nweights -= nlower * ncurrent;
  }
  if (ntunits) return 2;
  if (nweights) return 3;
  return 0;
}



/* *** FORWARD PROPAGATION ROUTINES *** */

/* *** Does one level of forward propagation *** */

void fprop1(invec,
            nin,
            outvec,
            nout,
            biases,
            weights)
double *invec;
int    nin;
double *outvec;
int    nout;
double *biases;
double *weights;

{
  int    count;
  double  sum;
  double *itemp;

  while(nout--)
  {
    sum = *biases++;
    itemp = invec;
    for(count=nin; count; count--)
      sum += *itemp++ * *weights++;
    *outvec++ = LOGFUNC(sum);
  }
}


/* *** Forward propagates the whole network *** */

void fprop(invec,
           nin,
           nunits,
           nlevels,
           activs,
           biases,
           ntunits,
           weights,
           nweights,
           outvec,
           nout,
           ifail)
double *invec;
int    nin;
int    *nunits;
int    nlevels;
double *activs;
double *biases;
int    ntunits;
double *weights;
int    nweights;
double *outvec;
int    nout;
int   *ifail;
{
  int    nlower, ncurrent;
  double *lact;

/* Check the variables are consistent if required */

  if (*ifail)
    if (*ifail=checkns(nunits, nlevels, nin, nout, ntunits, nweights))
      return;

/* Activate the lowest layer */

  ncurrent = *nunits++;
  nlower = nin;
  fprop1(invec, nlower, activs, ncurrent, biases, weights);

/* Activate the remaining layers */

  while(--nlevels)
  {
    weights += ncurrent * nlower;
    lact = activs;
    activs += ncurrent;
    biases += ncurrent;
    nlower = ncurrent;
    ncurrent = *nunits++;
    fprop1(lact, nlower, activs, ncurrent, biases, weights);
  }

/* Copy the top activities into the output array */

  while(nout--)
    *outvec++ = *activs++;
}


/* *** Forward propagate the network with the consecutive ***
   *** inputs presented in a 1-d array                    *** */

void fpropseq(stims,
              nstims,
              nstep,
              nin,
              negs,
              nunits,
              nlevels,
              activs,
              biases,
              ntunits,
              weights,
              nweights,
              outvecs,
              nout,
              ifail)
double *stims;
int    nstims;
int    nstep;
int    nin;
int    negs;
int   *nunits;
int    nlevels;
double *activs;
double *biases;
int    ntunits;
double *weights;
int    nweights;
double *outvecs;
int    nout;
int   *ifail;

{

/* Check the variables are consistent if required */

  if(*ifail=checkns(nunits,nlevels,nin,nout,ntunits,nweights)) return;

/* Another check on the stimulations array */

  if(*ifail=(nstims<(negs-1)*nstep+nin)*11) return;

/* Propagate the network for the whole stimulations array */

  while(negs--)
  {
    fprop(stims,nin,nunits,nlevels,activs,biases,ntunits,
          weights,nweights,outvecs,nout,ifail);
    stims += nstep;
    outvecs += nout;
  }
}



/* *** BACK PROPAGATION ROUTINES *** */

/* *** Adjust weights and biases between two levels *** */

void bwtset1(errors,
             nerrs,
             activs,
             nactivs,
             biases,
             bschange,
             weights,
             wtchange,
             eta,
             alpha)
double *errors;
int    nerrs;
double *activs;
int    nactivs;
double *biases;
double *bschange;
double *weights;
double *wtchange;
double  eta;
double  alpha;

{
  int i;
  double *lact;
  double  err;
  register double deltaw;

  while(nerrs--)
  {
    err = *errors++;
    lact = activs;

/* update the weights between two units */

    for(i=nactivs; i; i--)
    {
      deltaw=eta * err * *lact++ + alpha * *wtchange;
      *wtchange++ = deltaw;
      *weights++ -= deltaw;
    }

/* Update the threshold of the upper unit */

    deltaw = eta * err + alpha * *bschange;
    *bschange++ = deltaw;
    *biases++ -= deltaw;
  }

}


/* *** Back Propagate the entire network ***/

void bprop(targvec,
           ntarg,
           nunits,
           nlevels,
           activs,
           biases,
           bschange,
           ntunits,
           weights,
           wtchange,
           nweights,
           eta,
           alpha,
           invec,
           nin,
           ifail)
double *targvec;
int    ntarg;
int   *nunits;
int    nlevels;
double *activs;
double *biases;
double *bschange;
int    ntunits;
double *weights;
double *wtchange;
int    nweights;
double  eta;
double  alpha;
double *invec;
int    nin;
int   *ifail;

{
  int count, ncurrent, nlower, iunit, i;
  register int cpos, wpos, lpos;
  double *lactivs;
  double sum, temp, a;

/* Check the variables are consistent if required */

  if(*ifail)
    if(*ifail=checkns(nunits,nlevels,nin,ntarg,ntunits,nweights))
      return;

/* Set the errors for the top layer */

  cpos=ntunits;
  ncurrent=ntarg;
  targvec += ntarg;
  while(ntarg--)
  {
    a = activs[--cpos];
    activs[cpos] = LDERIV(a) * (a - *--targvec);
  }

/* Back propagtion for the whole network */

  lpos=cpos;
  wpos=nweights;
  nunits += --nlevels;
  while(nlevels--)
  {

/* Adjust the weights and biases between the current layers */

    nlower = *--nunits;
    cpos=lpos;
    lpos -= nlower;
    wpos -= nlower*ncurrent;
    bwtset1(activs+cpos, ncurrent, activs+lpos, nlower, biases+cpos,
            bschange+cpos, weights+wpos, wtchange+wpos, eta, alpha);

/* Set the errors for the lower layer */

    for(i=0; i<nlower; i++)
    {
      sum=0.0;
      for(count=0; count<ncurrent; count++)
        sum += activs[cpos+count] * weights[count*nlower + i + wpos];
      a=activs[lpos+i];
      activs[lpos+i] = LDERIV(a) * sum;
    }
    ncurrent=nlower;
  }

/* Adjust weights and biases between input layer and 1st hidden layer */

  bwtset1(activs,ncurrent,invec,nin,biases,bschange,
          weights,wtchange,eta,alpha);
}


/* *** Back propagate the network with the inputs ***
   *** presented as a consecutive 1-d array       *** */

void bpin(weights,
          nweights,
          activs,
          nactivs,
          nlowest,
          invec,
          nin)
double *weights;
int    nweights;
double *activs;
int    nactivs;
int    nlowest;
double* invec;
int    nin;

{
  int wpos,i,iunit;
  double sum;

  for(i=0; i<nin; i++)
  {
    wpos=i;
    sum=0.0;
    for(iunit=0; iunit<nlowest; iunit++)
    {
      sum += *(activs+iunit) * *(weights+wpos);
      wpos += nin;
    }
    *invec++ += sum;
  }
}


/* *** Teach the network picking the examples ***
   *** randomly from the training set         *** */

void bplearnseqr(niter,
                 targs,
                 ntarg,
                 negs,
                 stims,
                 nstims,
                 nstep,
                 nin,
                 nunits,
                 nlevels,
                 activs,
                 biases,
                 bschange,
                 ntunits,
                 weights,
                 wtchange,
                 nweights,
                 eta,
                 alpha,
                 outvec,
                 ifail)
int    niter;
double *targs;
int    ntarg;
int    negs;
double *stims;
int    nstims;
int    nstep;
int    nin;
int   *nunits;
int    nlevels;
double *activs;
double *biases;
double *bschange;
int    ntunits;
double *weights;
double *wtchange;
int    nweights;
double  eta;
double  alpha;
double *outvec;
int   *ifail;

{
  int eg, ipos;

/* Check the variables are consistent if required */

  if(*ifail)
    if(*ifail=checkns(nunits,nlevels,nin,ntarg,ntunits,nweights)) return;
  if(*ifail=(nstims<(negs-1) * nstep + nin)*11) return;

/* Do niter cycles selecting stimuli at random */

  while(niter--)
  {
    eg=(int)((((double) rand())/RAND_MAX) * negs);
    while(eg>=negs) eg -= negs;
    ipos=eg * nstep;

/* Forward propagate the network */

    fprop(&stims[ipos],nin,nunits,nlevels,activs,
          biases,ntunits,weights,nweights,outvec,ntarg,ifail);

/* With the results do the back propagation */

    bprop(&targs[eg*ntarg],ntarg,nunits,nlevels,activs,biases,bschange,
          ntunits,weights,wtchange,nweights,eta,alpha,&stims[ipos],nin,ifail);
  }

}


/* *** Teach the network picking the examples ***
   *** consecutively from the training set    *** */

void bplearnseqc(niter,
                 targs,
                 ntarg,
                 negs,
                 stims,
                 nstims,
                 nstep,
                 nin,
                 nunits,
                 nlevels,
                 activs,
                 biases,
                 bschange,
                 ntunits,
                 weights,
                 wtchange,
                 nweights,
                 eta,
                 alpha,
                 outvec,
                 ifail)
int    niter;
double *targs;
int    ntarg;
int    negs;
double *stims;
int    nstims;
int    nstep;
int    nin;
int   *nunits;
int    nlevels;
double *activs;
double *biases;
double *bschange;
int    ntunits;
double *weights;
double *wtchange;
int    nweights;
double  eta;
double  alpha;
double *outvec;
int   *ifail;

{
  int eg, ipos;

/* Check the variables are consistent if required */

  if(*ifail)
    if(*ifail=checkns(nunits,nlevels,nin,ntarg,ntunits,nweights)) return;
  if(*ifail=(nstims<(negs-1) * nstep + nin)*11) return;

/* Do <niter> cycles selecting the stimuli sequentially */

  eg=0;
  ipos=0;
  while(niter--)
  {

/* Fortward propagate the network */

    fprop(stims+ipos,nin,nunits,nlevels,activs,
          biases,ntunits,weights,nweights,outvec,ntarg,ifail);

/* With the results do the back propagation */

    bprop(targs+eg*ntarg,ntarg,nunits,nlevels,activs,biases,bschange,
          ntunits,weights,wtchange,nweights,eta,alpha,stims+ipos,nin,ifail);
    eg++;
    ipos += nstep;
    if(eg==negs)
    {
      eg=0;
      ipos=0;
    }
  }
}
