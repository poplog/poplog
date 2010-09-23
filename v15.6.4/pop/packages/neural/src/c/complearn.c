/* *** Copyright Integral Solutions Ltd 1993. All rights reserved ***
   File:          complearn.c
   Purpose:       Feed forward networks with competitive learning
   Author:        David Watkins, Mar 1993
                  Modified for all UNIX systems by Julian Clinton, Aug 1993
   Documentation: neurals help/complearn
   Related Files: complearn.p, compcdef.p
*/

#include <math.h>
#include "neural.h"


/* *** WIDELY USED VARIABLES ***
activs    : <array double> activies in each unit excluding inputs
biases    : <array double> holds thresholds of units excluding inputs
clusters  : <array int>    number of units in each cluster
clustlev  : <array int>    number of clusters in each level
gl        : <double>       learning rate for losing units
gw        : <double>       learning rate for winning units
ifail     : <int>          flag to signal inconsistent variables
nclusters : <int>          total number of clusters
nin       : <int>          number of input units
niter     : <int>          number of iterations for training
nlevels   : <int>          number of layers in network excluding inputs
ntunits   : <int>          total number of units in network
nunits    : <array int>    number of units in each layer excluding inputs
nweights  : <int>          number of weights in network
rl        : <double>       decrease in sensitivity of winning units
rw        : <double>       increase in sensitivity of losing units
stims     : <array double> inputs to be presented for training or results
weights   : <array double> 1-d array of all weights; ordered 1st input to
                           1st hidden unit, 2nd input to 1st hidden unit...
*/


/* *** Add the components of a vector *** */

double clsumvec(vec,
                n)
double *vec;
int     n;
{
  double sum=0.0;

  while(n--)
    sum += *vec++;
  return sum;
}


/* *** Produces the activation for a single unit *** */

double cprop0(invec,
              nin,
              bias,
              weights)
double *invec;
int     nin;
double  bias;
double *weights;
{
  while(nin--)
    bias += *invec++ * *weights++;
  return bias;
}


/* *** Sets the activations in one cluster and returns the winner *** */

int cprop2(invec,
            nin,
            outvec,
            nout,
            biases,
            weights)
double *invec;
int     nin;
double *outvec;
int     nout;
double *biases;
double *weights;
{
  int    winner,
         unito;
  double current,
         biggest;

  *outvec = 0.0;
  winner = 0;
  biggest = cprop0(invec, nin, *biases, weights);
  for(unito=1; unito<nout; unito++)
  {
    outvec[unito] = 0.0;
    weights += nin;
    current = cprop0(invec, nin, biases[unito], weights);
    if(current>biggest)
    {
      biggest=current;
      winner=unito;
    }
  }
  outvec[winner]=1.0;
  return(winner);
}


/* *** Sets activations in a whole layer *** */

void cprop1(invec,
            nin,
            outvec,
            nout,
            biases,
            weights,
            clusters,
            nclusters)
double *invec;
int     nin;
double *outvec;
int     nout;
double *biases;
double *weights;
int    *clusters;
int     nclusters;
{
  int istart=0, iwin;

  while(nclusters--)
  {
    iwin = cprop2(invec,nin,outvec+istart,*clusters,
                 biases+istart,weights+istart*nin) + istart;
    istart += *clusters++;
  }
}


/* *** Activates the entire network; top layer values into outvec *** */

void cprop(invec,
           nin,
           nunits,
           nlevels,
           activs,
           biases,
           ntunits,
           weights,
           nweights,
           clusters,
           nclusters,
           clustlev,
           outvec,
           nout,
           ifail)
double *invec;
int     nin;
int    *nunits;
int     nlevels;
double *activs;
double *biases;
int     ntunits;
double *weights;
int     nweights;
int    *clusters;
int     nclusters;
int    *clustlev;
double *outvec;
int     nout;
int    *ifail;
{
  int lpos,
      cpos=0,
      ncurrent,
      nlower,
      ncluslev;

/* check for consistent variables if required */

  if(*ifail)
    if(*ifail=ccheckns(nunits,nlevels,nin,ntunits,
                       nweights,clusters,nclusters,clustlev))
      return;

/* set the lowest hidden units */

  ncluslev = *clustlev++;
  ncurrent = *nunits++;
  nlower = nin;
  cprop1(invec,nlower,activs,ncurrent,biases,weights,clusters,ncluslev);

/* set the rest of the hidden units */

  while(--nlevels)
  {
    lpos=cpos;
    cpos += ncurrent;
    weights += ncurrent * nlower;
    clusters += ncluslev;
    ncluslev = *clustlev++;
    nlower = ncurrent;
    ncurrent = *nunits++;
    cprop1(activs+lpos,nlower,activs+cpos,ncurrent,
           biases+cpos,weights,clusters,ncluslev);
  }

/* copy the top activations into the output array */

  activs += ntunits - nout;
  while(nout--)
    *outvec++ = *activs++;
}


/* *** As cprop but for a sequence of inputs held in stims *** */

void cpropseq(stims,
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
              clusters,
              nclusters,
              clustlev,
              outvecs,
              nout,
              ifail)
double *stims;
int     nstims;
int     nstep;
int     nin;
int     negs;
int    *nunits;
int     nlevels;
double *activs;
double *biases;
int     ntunits;
double *weights;
int     nweights;
int    *clusters;
int     nclusters;
int    *clustlev;
double *outvecs;
int     nout;
int    *ifail;
{

/* check if variables are consistent if required */

  if(*ifail=ccheckns(nunits,nlevels,nin,ntunits,nweights,
                     clusters,nclusters,clustlev))
    return;

/* Another check for the stimulations */

  if(*ifail=(nstims<(negs-1) * nstep +nin)*11)
    return;

/* Propogate the network for the various stimulations */

  while(negs--)
  {
    cprop(stims,nin,nunits,nlevels,activs,biases,ntunits,weights,
          nweights,clusters,nclusters,clustlev,outvecs,nout,ifail);
    stims += nstep;
    outvecs += nout;
  }
}


/* *** Causes a single unit to learn *** */

void wtadj0(invec,
            nin,
            sumin,
            weights,
            g)
double *invec;
int     nin;
double  sumin;
double *weights;
double  g;
{
  double a1, a2;

  a1 = 1.0 - g;
  a2 = g / sumin;
  for(; nin--; weights++)
    *weights = a1 * *weights + a2  * *invec++;
}


/* *** Adjust weights of every unit in a layer as a cheap leaky learning *** */

void wtadj1(invec,
            nin,
            sumin,
            weights,
            nout,
            g)
double *invec;
int     nin;
double  sumin;
double *weights;
int     nout;
double  g;
{
  for(; nout--; weights += nin)
    wtadj0(invec,nin,sumin,weights,g);
}


/* *** Adjust the bias of a winning unit ***
   *** rd & ru are downward & upward rates for winning and losing units *** */

void bsadj0(bias,
            rd,
            ru)
double *bias;
double  rd;
double  ru;
{
  *bias = ((*bias - rd * *bias) -ru)/(1.0 -ru);
}


/* *** Adjust the biases of the whole network *** */

void bsadj1(biases,
            ntunits,
            ru)
double *biases;
int     ntunits;
double  ru;
{
  double  crate;

  crate = 1.0 - ru;
  for(; ntunits--; biases++)
    *biases = ru + crate * *biases;
}


/* *** Set activations in a whole layer and do the learning *** */

void clearn1(invec,
             nin,
             sumin,
             outvec,
             nout,
             biases,
             weights,
             clusters,
             nclusters,
             gw,
             gl,
             rw,
             rl)
double *invec;
int     nin;
double  sumin;
double *outvec;
int     nout;
double *biases;
double *weights;
int    *clusters;
int     nclusters;
double  gw;
double  gl;
double  rw;
double  rl;
{
  int ninclus,
      iwin,
      istart=0;

  while(nclusters--)
  {
    ninclus = *clusters++;
    iwin=cprop2(invec,nin,outvec+istart,ninclus,
                 biases+istart,weights+istart*nin)+istart;

/* winning units learn here */

    if(gw>0.0)
      wtadj0(invec,nin,sumin,weights+iwin*nin,gw);
    if(rw>0.0)
      bsadj0(biases+iwin,rw,rl);
    istart += ninclus;
  }

/* losing units learn here */

  if(gl>0.0)
    wtadj1(invec,nin,sumin,weights,nout,gl);
  if(rl>0.0)
    bsadj1(biases,nout,rl);
}


/* *** Checks for consistency in the networks variables *** */

int ccheckns(nunits,
             nlevels,
             nin,
             ntunits,
             nweights,
             clusters,
             nclusters,
             clustlev)
int    *nunits;
int     nlevels;
int     nin;
int     ntunits;
int     nweights;
int    *clusters;
int     nclusters;
int    *clustlev;
{
  int cluster,
      ncurrent,
      ncl;

  while(nlevels--)
  {
    ncurrent = *nunits++;
    ntunits-= ncurrent;
    nweights-= nin * ncurrent;
    nin = ncurrent;
    ncl = *clustlev++;
    nclusters-= ncl;
    while(ncl--)
      ncurrent-= *clusters++;
    if(ncurrent) return 4;        /* No. of units in disagreement */
  }
  if(nclusters) return 5;         /* No. of clusters in disagreement */
  if(ntunits) return 2;           /* Total no. of units -"--------"- */
  if(nweights) return 3;          /* No of weights wrong */
  return 0;                       /* Variables are consistent */
}


/* *** Activates the network and the learning *** */

void clearn(invec,
            nin,
            nunits,
            nlevels,
            activs,
            biases,
            ntunits,
            weights,
            nweights,
            clusters,
            nclusters,
            clustlev,
            gw,
            gl,
            rw,
            rl,
            ifail)
double *invec;
int     nin;
int    *nunits;
int     nlevels;
double *activs;
double *biases;
int     ntunits;
double *weights;
int     nweights;
int    *clusters;
int     nclusters;
int    *clustlev;
double  gw;
double  gl;
double  rw;
double  rl;
int    *ifail;
{
  int nlower,
      ncurrent,
      lpos,
      cpos=0,
      ncluslev;
  double sumin;

/* Check variables are consistent if required */

  if(*ifail)
    if(*ifail=ccheckns(nunits,nlevels,nin,ntunits,nweights,
                       clusters,nclusters,clustlev))
      return;

/* Set the lowest hidden units */

  sumin = clsumvec(invec,nin);
  ncluslev = *clustlev++;
  ncurrent = *nunits++;
  nlower = nin;
  clearn1(invec,nlower,sumin,activs,ncurrent,biases,
          weights,clusters,ncluslev,gw,gl,rw,rl);

/* Set the rest of the hidden units */

  while(--nlevels)
  {
    lpos=cpos;
    clusters += ncluslev;
    cpos += ncurrent;
    weights += ncurrent*nlower;
    nlower = ncurrent;
    sumin = ncluslev;
    ncluslev = *clustlev++;
    ncurrent = *nunits++;
    clearn1(activs+lpos,nlower,sumin,activs+cpos,ncurrent,
            biases+cpos,weights,clusters,ncluslev,gw,gl,rw,rl);
  }
}


/* *** Carry out <niter> learning cycles selecting stimulus at random *** */

void clearnseqr(niter,
                stims,
                nstims,
                nstep,
                nin,
                nunits,
                nlevels,
                activs,
                biases,
                ntunits,
                weights,
                nweights,
                clusters,
                nclusters,
                clustlev,
                gw,
                gl,
                rw,
                rl,
                ifail)
int     niter;
double *stims;
int     nstims;
int     nstep;
int     nin;
int    *nunits;
int     nlevels;
double *activs;
double *biases;
int     ntunits;
double *weights;
int     nweights;
int    *clusters;
int     nclusters;
int    *clustlev;
double  gw;
double  gl;
double  rw;
double  rl;
int    *ifail;
{
  int eg, negs, ipos;

/* Check the variables are consistent if required */

  if(*ifail=ccheckns(nunits,nlevels,nin,ntunits,nweights,
                     clusters,nclusters,clustlev))
    return;

/* Another check for the stimulations */

  if(*ifail=(nstims<nin)*11)
    return;

/* Do <niter> cycles selecting stimuli at random */

  negs = (nstims - nin)/nstep;
  while(niter--)
  {
    eg=(int)(((double) rand())/RAND_MAX * negs);
    while(eg>=negs) eg-=negs;
    ipos=eg*nstep;
    clearn(stims+ipos,nin,nunits,nlevels,activs,biases,ntunits,
           weights,nweights,clusters,nclusters,clustlev,gw,gl,rw,rl,ifail);
  }
}


/* *** As above except stimulus chosen in sequence *** */

void clearnseqc(niter,
                stims,
                nstims,
                nstep,
                nin,
                nunits,
                nlevels,
                activs,
                biases,
                ntunits,
                weights,
                nweights,
                clusters,
                nclusters,
                clustlev,
                gw,
                gl,
                rw,
                rl,
                ifail)
int     niter;
double *stims;
int     nstims;
int     nstep;
int     nin;
int    *nunits;
int     nlevels;
double *activs;
double *biases;
int     ntunits;
double *weights;
int     nweights;
int    *clusters;
int     nclusters;
int    *clustlev;
double  gw;
double  gl;
double  rw;
double  rl;
int    *ifail;
{
  int ipos=0,
      mxpos;

/* Check the variables are consistent if required */

  if(*ifail=ccheckns(nunits,nlevels,nin,ntunits,nweights,
                     clusters,nclusters,clustlev))
    return;

/* Another check for the stimulations */

  if(*ifail=(nstims<nin)*11)
    return;

/* Do <niter> cycles selecting stimuli sequentially */

  mxpos=nstims-nin;
  while(niter--)
  {
    clearn(stims+ipos,nin,nunits,nlevels,activs,biases,ntunits,weights,
           nweights,clusters,nclusters,clustlev,gw,gl,rw,rl,ifail);
    ipos += nstep;
    if(ipos>mxpos)
      ipos=0;
  }
}


/* *** Normalises a vector so sum of elements is one *** */

void clunitvec(vec,
               n)
double *vec;
int     n;
{
  double r, sum;

  sum = clsumvec(vec,n);
  if(sum==0.0) return;
  r = 1.0/sum;
  for(; n--; vec++)
    *vec = r * *vec;
}


/* *** Normalises the vectors for one layer *** */

void clnorm1(wts,
              nin,
              nout)
double *wts;
int     nin;
int     nout;
{
  while(nout--)
    clunitvec(wts+nout*nin,nin);
}


/* *** Normalises the vectors in a whole network *** */

void clnorm(wts,
            nweights,
            nin,
            nunits,
            nlevels)
double *wts;
int     nweights;
int     nin;
int    *nunits;
int     nlevels;
{
  int ncurrent;

  while(nlevels--)
  {
    ncurrent = *nunits++;
    clnorm1(wts,nin,ncurrent);
    wts += nin * ncurrent;
    nin = ncurrent;
  }
}
