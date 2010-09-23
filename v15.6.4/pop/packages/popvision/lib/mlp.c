/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 * File:            $popvision/lib/mlp.c
 * Purpose:         Multi-layer perceptron neural nets
 * Author:          David S Young, Aug 14 1998 (see revisions)
 * Documentation:   HELP * MLP
 * Related Files:   LIB MLP
 */

#include <stdlib.h>
#include <math.h>

/*
-- Interface to random number generator -------------------------------

Use a local seed to avoid interactions with other uses of rand48.
*/

static unsigned short seed[3] = {1, 1, 1};

void mlp_random_set(unsigned short *s)
{
    seed[0] = s[0];
    seed[1] = s[1];
    seed[2] = s[2];
}

void mlp_random_get(unsigned short *s)
{
    s[0] = seed[0];
    s[1] = seed[1];
    s[2] = seed[2];
}

/*
-- Simple utilities ---------------------------------------------------
*/

float mlp_sumsquares(float *arr, int n)
{
    float a, sum = 0.0, *arrend = arr + n;
    while (arr < arrend) {
        a = *arr++;
        sum += a * a;
    }
    return sum;
}

void mlp_randomvec(float *arr, int n, float x0, float x1)
{
    float *arrend = arr+n, x1mx0 = x1-x0;
    while (arr < arrend) *arr++ = x0 + x1mx0 * erand48(seed);
}

void mlp_scalevec(float factor, float *arr, int n)
{
    float *arrend = arr + n;
    while (arr < arrend) *arr++ = *arr * factor;
}

void mlp_fillvec(float value, float *arr, int n)
{
    float *arrend = arr + n;
    while (arr < arrend) *arr++ = value;
}

/*
-- Activation function  1 ---------------------------------------------

This is simply the identity function - i.e. a linear, non-scaling unit -
and so is omitted.

The derivative is just the constant 1, and so is omitted.

*/

/*
-- Activation function  2 --------------------------------------------
*/

static float logfunc(float x)
/* The "logistic" transfer function */
{
    return 1.0 / (1.0 + exp(-x));
}

static float lderiv(float y)
/* returns the derivative of the logistic function for a given output */
{
    return y * (1.0 - y);
}

/*
-- Activation function  3 --------------------------------------------
 - is tanh, so does not need defining
*/

static float tderiv(float y)
/* returns the derivative of the tanh function for a given output */
{
    return 1.0 - y * y;
}

/*
-- Activation function  4 --------------------------------------------
 - is the fast approximate version of the logistic function, which
   relies on the hardware representation of floats.

    See N.N. Schraudolph (1998) 'A fast, compact approximation of the
    exponential function', Technical report IDSIA-07-98, IDSIA, Lugano,
    Switzerland, submitted to Neural Computation. */

static union
{
    double d;
    struct {int i, j; } n;
} _eco;

#define EXP_A (1048576/M_LN2)
#define EXP_C 60801

#define EXP(y) (_eco.n.i = EXP_A*(y) + (1072693248 - EXP_C), _eco.d)

static float fast_logfunc(float x)
/* The "logistic" transfer function */
{
    return 1.0 / (1.0 + EXP(-x));
}

/* The derivative is lderiv */

/*
-- fprop0 -------------------------------------------------------------
*/

static float fprop0(
    int tranfn,
    float* invec,
    int nin,
    float bias,
    float* weights)
 /* Produces the activation for a single unit with the given
 weights vector and input. */
 {
    float sum = bias, *invecend = invec+nin;
    while (invec < invecend) sum += *invec++ * *weights++;

    switch (tranfn) {
        case 1: return sum;
        case 2: return logfunc(sum);
        case 3: return tanh(sum);
        case 4: return fast_logfunc(sum);
    }
}

/*
-- fprop0in -----------------------------------------------------------
*/
static float fprop0in(
    int tranfn,
    float *invec,
    int *stimoffs,
    int nin,
    float bias,
    float *weights)
 /* Produces the activation for a single unit with the given
 weights vector and input, using explicit offsets into the
 input vector */
 {
    float sum = bias;
    int *stmend = stimoffs + nin;
    while (stimoffs < stmend) sum += *(invec + *stimoffs++) * *weights++;

    switch (tranfn) {
        case 1: return sum;
        case 2: return logfunc(sum);
        case 3: return tanh(sum);
        case 4: return fast_logfunc(sum);
    }
}

/*
-- fprop1 -------------------------------------------------------------
*/
static void fprop1(
    float *invec,
    int nin,
    int *tranfns,
    float *outvec,
    int nout,
    float *biases,
    float *weights)
/* Does one level of forward propagation. */
{
    int *tranfend = tranfns + nout;
    while (tranfns < tranfend) {
        *outvec++ = fprop0(*tranfns++, invec, nin, *biases++, weights);
        weights += nin;
    }
}

/*
-- fprop1in -----------------------------------------------------------
*/
static void fprop1in(
    float *invec,
    int *stimoffs,
    int nin,
    int *tranfns,
    float *outvec,
    int nout,
    float *biases,
    float *weights)
/* Does one level of forward propagation with specified offsets. */
{
    int *tranfend = tranfns + nout;
    while (tranfns < tranfend) {
        *outvec++ = fprop0in(
            *tranfns++, invec, stimoffs, nin, *biases++, weights);
        weights += nin;
    }
}

/*
-- checkns ------------------------------------------------------------
*/
static int checkns(
    int *nunits, int nlevels, int nin, int nout, int ntunits, int nweights
    )
/* for checking consistency */
{
    int level, nu, nw, nlower, ncurrent;
    if (nout != *(nunits+nlevels-1)) return 1;
    for (level=0, nu=0, nw=0, nlower=nin; level < nlevels; level++) {
        ncurrent = *nunits++;
        nu += ncurrent;
        nw += nlower * ncurrent;
        nlower = ncurrent;
    }
    if (nu != ntunits) return 2;
    if (nw != nweights) return 3;
    return 0;
}

/*
-- fprop --------------------------------------------------
*/
static void fprop (
    float *invec,           /* input vector */
    int *stimoffs,          /* integer array of offsets into invec */
    int nin,                /* no of input units */
    int *nunits,            /* array giving no of units in each level
                            (not including input units - nunits(1) is
                            the no in the lowest hidden layer) */
    int nlevels,            /* no of layers not counting input layer but
                            including output layer */
    int *tranfns,           /* transfer functions to be used. See list at start
                            of program for what the integers mean. */
    float *activs,          /* array that will be filled with the activities.
                            Units in lowest hidden layer come first. */
    float *biases,          /* array of biases */
    int ntunits,            /* total no of units (not counting input layer) */
    float *weights,         /* array of weights, starting with weight from
                            first input unit to first unit in lowest hidden
                            layer, then from second input unit to this hidden
                            unit, and so on */
    int nweights            /* total no of weights */
)
/* Does the forward propagation part.
   Does no checking of dimensions */
{
    /* set the lowest hidden units */
    int *nunitsend = nunits + nlevels, ncurrent = *nunits++, nlower = nin;
    float *actlower;

    fprop1in(invec,stimoffs,nin,tranfns,activs,ncurrent,biases,weights);

    /* set the rest of the hidden units */
    while (nunits < nunitsend) {
        actlower = activs;
        activs += ncurrent;
        tranfns += ncurrent;
        biases += ncurrent;
        weights += ncurrent * nlower;
        nlower = ncurrent;
        ncurrent = *nunits++;
        fprop1(actlower, nlower, tranfns, activs, ncurrent, biases, weights);
    }
}

/*
-- fcopout ------------------------------------------------------------
*/
static void fcopout(
    float *activs,
    float *outs,
    int *outoffs,
    int nout)
/* Copy data from activs array into output array */
{
    float *activend = activs + nout;
    while (activs < activend) *(outs + *outoffs++) = *activs++;
}

/*
-- mlp_arrindex -------------------------------------------------------
*/
static int mlp_arrindex(
    int ndim,
    int *coords,
    int *dimprod)
/* For an ndim-dimensional array with dimension products
   specified in dimprod (i.e. dimprod(i) is the product of all the dimensions
   before i in the dimension list - dimprod(1) should be 1),
   returns the position in the equivalent array 1-D of
   the element specified in the coords argument.
   Coordinates are all taken to be 0-based. */
{
    int ind=0, *coordsend = coords + ndim;
    while (coords < coordsend) ind += *dimprod++ * *coords++;
    return ind;
}

/*
-- mlp_nextsample -----------------------------------------------------
*/
static int mlp_nextsample(
    int ndim,
    int *sample,
    int *sampspec)
/* Returns an index into a 1-D array for the next sample, and updates
   sample, which specifies the current coordinates in ndim dimensions.

 The columns of sampspec have these meanings:
     0: the dimension products of the array
     1: the lowest indices allowed for a sample
     2: the increment to the next sample
     3: the highest indices allowed

 Wraps round when it gets to the end. */
 {
    int *sampend = sample+ndim, *samp = sample, *smpspc = sampspec;
    for ( ; samp < sampend; samp++, smpspc++) {
        int s = *samp + *(smpspc+2*ndim);
        if (s > *(smpspc+3*ndim))
            *samp = *(smpspc+ndim);
        else {
            *samp = s;
            break;
        }
    }
    return mlp_arrindex(ndim,sample,sampspec);
}

/*
-- mlp_randsample -----------------------------------------------------
*/
static int mlp_randsample(
    int ndim,
    int *sample,
    int *sampspec)
/* Returns an index into a 1-D array for a randomly selected sample,
 with sampspec having the same meaning as above. sample returns
 the selected coordinates in ndim dimensions. */
{
    int *sampend = sample+ndim, *samp = sample, *smpspc = sampspec;
    for ( ; samp < sampend; samp++, smpspc++) {
        int base = *(smpspc+ndim),
            inc = *(smpspc+2*ndim),
            nsamp = (*(smpspc+3*ndim) - base)/inc + 1;
        *samp = (int)(erand48(seed)*nsamp) * inc + base;
    }
    return mlp_arrindex(ndim, sample, sampspec);
}

/*
-- mlp_correspout -----------------------------------------------------
*/
static int mlp_correspout(
    int ndim,
    int *sampin,
    int *sampspecin,
    int *sampout,
    int *sampspecout)
 /* Sets up sampout to be the point in the output array that
 corresponds to the point sampin in the input array */
 {
    int *sampinend=sampin+ndim, *smpo=sampout, *smpspco=sampspecout;
    for ( ; sampin < sampinend;
            sampin++, smpo++, sampspecin++, smpspco++) {
        int off = (*sampin - *(sampspecin+ndim)) / *(sampspecin+2*ndim);
        *smpo = *(smpspco+ndim) + off * *(smpspco + 2*ndim);
    }
    return mlp_arrindex(ndim, sampout, sampspecout);
}

/*
-- mlp_getsample ------------------------------------------------------
*/
static int mlp_getsample(
    int ndim,
    int *stimstarts,
    int ransel)
/* Returns the index for the next sample */
{
    if (ransel)
        return mlp_randsample(ndim, stimstarts+4*ndim, stimstarts);
    else
        return mlp_nextsample(ndim, stimstarts+4*ndim, stimstarts);
}

/*
-- mlp_getoutsample ---------------------------------------------------
*/
static int mlp_getoutsample(
    int ndim,
    int *stimsin,
    int *stimsout)
{
    return mlp_correspout(ndim, stimsin+4*ndim, stimsin,
            stimsout+4*ndim, stimsout);
}


/*
-- mlp_forward --------------------------------------------------------
*/
int mlp_forward(
    float *stims,
    int *stimstarts,
    int ndim,
    int negs,
    int *stimoffs,
    int nin,
    int *nunits,
    int nlevels,
    int *tranfns,
    float *activs,
    float *biases,
    int ntunits,
    float * weights,
    int nweights,
    float *outs,
    int *outstarts,
    int *outoffs,
    int nout)
/* Iterates fprop, storing the results from each iteration.

 Data for the i'th iteration are taken from
 stims[stimstarts[i-1]+stimoffs[0]], stims[stimstarts[i-1]+stimoffs[1]]
 ... stims[stimstarts[i-1]+stimoffs[nin-1]].

 Results are stored in a similar manner in outs.

 Arguments in between are as for fprop. */
{
    float *activout;

    /* check inputs to avoid having to do so on each iteration */
    int ifail = checkns(nunits,nlevels,nin,nout,ntunits,nweights);
    if (ifail) return ifail;

    activout = activs + ntunits - nout;

    if (ndim == 0) {
        /* The case where stimstarts is just a 1-D array of possible
            starting points. */
        int *stimstartsend = stimstarts + negs;
        /* forward propagate */
        while (stimstarts < stimstartsend) {
            fprop (stims + *stimstarts++, stimoffs, nin,
                nunits, nlevels, tranfns, activs,
                biases, ntunits, weights, nweights);
            /* copy outputs into output array (do this here rather than in
                fprop so that mlp_forback need not provide output array) */
            fcopout(activout, outs + *outstarts++, outoffs, nout);
        }
    }
    else {
        /* The case where stimstarts is an ndim-dimensional array of
            start, increment and end coordinates. */
        int eg;
        for (eg=0; eg<negs; eg++) {
            /* forward propagate */
            int s = mlp_getsample(ndim, stimstarts, 0);
            fprop (stims + s, stimoffs, nin, nunits, nlevels, tranfns, activs,
                    biases, ntunits, weights, nweights);
            s = mlp_getoutsample(ndim, stimstarts, outstarts);
            fcopout(activout, outs+s, outoffs, nout);
        }
    }
    return 0;
}

/*
-- berrset ------------------------------------------------------------
*/
static void berrset(
    int *tranfnsout,
    float *errsin,
    int nerrsin,
    float *errsout,
    int nerrsout,
    float *weights)
/* Does one layer of error setting. Note that the weights array gives
 the weights for the layer above the current layer. In and out
 refer to the direction of error propagation (downwards!) */
{
    float *errsoutend = errsout+nerrsout, *errsinend = errsin+nerrsin;
    for ( ; errsout < errsoutend; errsout++) {
        float sum = 0.0, *errs = errsin, *wts = weights++;
        while (errs < errsinend) {
            sum += *errs++ * *wts;
            wts += nerrsout;
        }
        switch (*tranfnsout++) {
            case 1: *errsout = sum; break;
            case 2: *errsout = lderiv(*errsout) * sum; break;
            case 3: *errsout = tderiv(*errsout) * sum; break;
            case 4: *errsout = lderiv(*errsout) * sum; break;
        }
    }
}

/*
-- bwtset -------------------------------------------------------------
*/
static void bwtset(
    float *errors,
    int nerrs,
    float *activs,
    int nactivs,
    float *biases,
    float *bschange,
    float *weights,
    float *wtchange,
    float *etas,
    float *etbs,
    float alpha)
/* Does one layer of weight updating given its errors, the previous
 change in the weights, the present weights and the constants
 eta and alpha.

 activs is the activity in the layer below the weights.

 Note that eta can be given separately for each weight - so
 zero eta can be used to clamp weights. If eta is suddenly set to
 zero, the current weight change will continue to be added until
 it decays. If eta is made negative, the weight is clamped sharply,
 and some computation is saved also. */
{
    float *errsend = errors + nerrs;
    for ( ; errors < errsend; errors++, biases++, bschange++) {
        float eta, etb, err = *errors, *act = activs,
              *wtend = weights+nactivs;
        for ( ; weights < wtend; act++, wtchange++, weights++)
            if ((eta = *etas++) >= 0.0)
                *weights += *wtchange
                          = err * eta * *act + alpha * *wtchange;
        if ((etb = *etbs++) >= 0.0)
            *biases += *bschange = etb * err + alpha * *bschange;
    }
}

/*
-- bwtsetin -----------------------------------------------------------
*/
static void bwtsetin(
    float *errors,
    int nerrs,
    float *activs,
    int *actpts,
    int nactivs,
    float *biases,
    float *bschange,
    float *weights,
    float *wtchange,
    float *etas,
    float *etbs,
    float alpha)
/* Like bwtset but with arbitrary offsets into the input vector */
{
    float *errsend = errors + nerrs;
    for ( ; errors < errsend; errors++, biases++, bschange++) {
        float eta, etb, err = *errors, *wtend = weights+nactivs;
        int *actp = actpts;
        for ( ; weights < wtend; actp++, wtchange++, weights++)
            if ((eta = *etas++) >= 0.0)
                *weights += *wtchange
                     = err * eta * *(activs + *actp) + alpha * *wtchange;
        if ((etb = *etbs++) >= 0.0)
            *biases += *bschange = etb * err + alpha * *bschange;
    }
}

/*
-- decaywts -----------------------------------------------------------
*/
static void decaywts(
    float *biases,
    int ntunits,
    float *weights,
    int nweights,
    float *etas,
    float *etbs,
    float decay)
/* Decay all the weights and biases except those clamped */
{
    if (decay >= 0.0) {
        float eta, etb,
            *etaend = etas + nweights, *etbend = etbs + ntunits;
        for ( ; etas < etaend; weights++)
            if ((eta = *etas++) >= 0.0) *weights *= decay;
        for ( ; etbs < etbend; biases++)
            if ((etb = *etbs++) >= 0.0) *biases *= decay;
    }
}


/*
-- bprop --------------------------------------------------------------
*/
static float bprop(
    float *invec,
    int *stimoffs,
    int nin,
    int *nunits,
    int nlevels,
    int *tranfns,
    float *activs,
    float *biases,
    int ntunits,
    float *weights,
    int nweights,
    float *wtchange,
    float *bschange,
    float *etas,
    float *etbs,
    float alpha,
    float decay,
    float *targvec,
    int *targoffs,
    int nout)
/* Back-propagates the error signal, updating the weights as it goes, and
 also replacing the activities by the error signals.

 Returns the current error. */
{
    int cpos, ncurrent, nlower, nwts, *nlowerp, *trnfn;
    float errsum,
        *act, *actend, *actlower, *weights1, *wtchange1, *etas1;

    /* Point to the output layer */
    cpos = ntunits - nout;
    activs += cpos;     /* starting positions for output layer */
    actlower = activs;
    tranfns += cpos;
    etbs += cpos;
    biases += cpos;
    bschange += cpos;
    weights1 = weights + nweights;    /* weights point above layer */
    wtchange1 = wtchange + nweights;
    etas1 = etas + nweights;

    /* set up the errors for the output units */
    for (trnfn=tranfns, act=activs, actend=act+nout, errsum = 0.0;
         act < actend;
         act++, trnfn++, targoffs++) {
        float a = *act,
            err = *(targvec + *targoffs) - a;
        switch (*trnfn) {
            case 1: *act = err; break;
            case 2: *act = lderiv(a) * err; break;
            case 3: *act = tderiv(a) * err; break;
            case 4: *act = lderiv(a) * err; break;
        }
        errsum += err * err;
    }

    /* Propagate down  - this loop does nlevels-1 iterations */
    for (nlowerp = nunits + nlevels - 1,  ncurrent = nout;
         nlowerp > nunits;
         ) {
        nlower = *(--nlowerp);
        actlower -= nlower;          /* Pointers to next layer down */
        tranfns -= nlower;
        nwts = nlower * ncurrent;
        weights1 -= nwts;
        wtchange1 -= nwts;
        etas1 -= nwts;

        /* update the weights for this level (it's debatable whether or not
         this should be done before working out the errors in the next
         level down, but this way seems to be implied on p.327 of the
         pdp book */
        bwtset(activs, ncurrent, actlower, nlower,
            biases, bschange, weights1, wtchange1, etas1, etbs, alpha);

        /*  set the errors for the next level down */
        berrset(tranfns, activs, ncurrent, actlower, nlower, weights1);

        ncurrent = nlower;
        activs = actlower;     /* move one layer down */
        etbs -= ncurrent;
        biases -= ncurrent;
        bschange -= ncurrent;
    }

    /* finally do the bottom layer (needs the input vector as the input
    units aren't represented in the activs array) */
    bwtsetin(activs, ncurrent, invec, stimoffs, nin,
        biases, bschange, weights, wtchange, etas, etbs, alpha);

    /* Implement decay here, to avoid slowing down operations when decay
    is not required. */
    decaywts(biases, ntunits, weights, nweights, etas, etbs, decay);

    return errsum;
}

/*
-- Backprop routines for batch learning -------------------------------

Like the 3 routines above, but only accumulate the weight corrections.
*/

static void bwtset_batch(
    float *errors,
    int nerrs,
    float *activs,
    int nactivs,
    float *bschange,
    float *wtchange)
{
    float *errsend = errors + nerrs;
    while (errors < errsend) {
        float err = *errors++, *act = activs, *wtchend = wtchange+nactivs;
        while (wtchange < wtchend) *wtchange++ += err * *act++;
        *bschange++ += err;
    }
}

static void bwtsetin_batch(
    float *errors,
    int nerrs,
    float *activs,
    int *actpts,
    int nactivs,
    float *bschange,
    float *wtchange)
{
    float *errsend = errors + nerrs;
    while (errors < errsend) {
        float err = *errors++, *wtchend = wtchange+nactivs;
        int *actp = actpts;
        while (wtchange < wtchend) *wtchange++ += err * *(activs + *actp++);
        *bschange++ += err;
    }
}

static float bprop_batch(
    float *invec,
    int *stimoffs,
    int nin,
    int *nunits,
    int nlevels,
    int *tranfns,
    float *activs,
    int ntunits,
    float *weights,
    int nweights,
    float *wtchange,
    float *bschange,
    float *targvec,
    int *targoffs,
    int nout)
{
    int cpos, ncurrent, nlower, nwts, *nlowerp, *trnfn;
    float errsum,
        *act, *actend, *actlower, *weights1, *wtchange1, *etas1;
    cpos = ntunits - nout;
    activs += cpos;
    actlower = activs;
    tranfns += cpos;
    bschange += cpos;
    weights1 = weights + nweights;
    wtchange1 = wtchange + nweights;
    for (trnfn=tranfns, act=activs, actend=act+nout, errsum = 0.0;
         act < actend;
         act++, trnfn++, targoffs++) {
        float a = *act,
            err = *(targvec + *targoffs) - a;
        switch (*trnfn) {
            case 1: *act = err; break;
            case 2: *act = lderiv(a) * err; break;
            case 3: *act = tderiv(a) * err; break;
            case 4: *act = lderiv(a) * err; break;
        }
        errsum += err * err;
    }
    for (nlowerp = nunits + nlevels - 1,  ncurrent = nout;
         nlowerp > nunits;
         ) {
        nlower = *(--nlowerp);
        actlower -= nlower;          /* Pointers to next layer down */
        tranfns -= nlower;
        nwts = nlower * ncurrent;
        weights1 -= nwts;
        wtchange1 -= nwts;
        bwtset_batch(activs, ncurrent, actlower, nlower,
            bschange, wtchange1);
        berrset(tranfns, activs, ncurrent, actlower, nlower, weights1);
        ncurrent = nlower;
        activs = actlower;     /* move one layer down */
        bschange -= ncurrent;
    }
    bwtsetin_batch(activs, ncurrent, invec, stimoffs, nin,
        bschange, wtchange);
    return errsum;
}

static float bwtupd_batch(
    float *biases,
    int ntunits,
    float *weights,
    int nweights,
    float *wtchange,
    float *bschange,
    float *etas,
    float *etbs,
    float decay,
    int nbatch)
/* Updates the weights and resets the wt change arrays after wt change
   accumulation in batch learning. */
{
    float *bs = biases, *bsend = biases + ntunits,
          *wts = weights, *wtend = weights + nweights,
          *etasp = etas, *etbsp = etbs,
          eta, etb, k = 1.0/nbatch;
    for ( ; bs < bsend; bs++) {
        if ((etb = *etbsp++) >= 0.0) *bs += k * etb * *bschange;
        *bschange++ = 0.0;
    }
    for ( ; wts < wtend; wts++) {
        if ((eta = *etasp++) >= 0.0) *wts += k * eta * *wtchange;
        *wtchange++ = 0.0;
    }
    decaywts(biases, ntunits, weights, nweights, etas, etbs, decay);
}

/*
-- mlp_intotarg -------------------------------------------------------
*/
void mlp_intotarg(
    float *weights,
    int nweights,
    float *activs,
    int nactivs,
    int nlowest,
    float *stims,
    int *stimstarts,
    int ndim,
    int negs,
    int *stimoffs,
    int nin)
/* Continues back propagation as it were into the input vector,
 generating a vector that would be a suitable target vector for
 a lower layer of machine.
 nlowest must be the no of units in the lowest layer of the
 machine. */
{
    int *stimst, *stimoffsend=stimoffs+nin, *stimstartsend=stimstarts+negs;
    float *act, *actend = activs + nlowest, *wts, *stms, sum;
    while (stimoffs < stimoffsend) {
        wts = weights++;
        sum = 0.0;
        for (act = activs; act < actend; act++) {
            sum += *act * *wts;
            wts += nin;
        }
        stms = stims + *stimoffs++;
        if (ndim)
            for (stimst = stimstarts; stimst < stimstartsend; stimst++)
                *(stms + mlp_getsample(ndim, stimstarts, 0)) += sum;
        else
            for (stimst = stimstarts; stimst < stimstartsend; stimst++)
                *(stms + *stimst) += sum;
    }
}


/*
-- mlp_forback --------------------------------------------------------
*/
int mlp_forback(
    float *stims,
    int *stimstarts,
    int ndim,
    int negs,
    int *stimoffs,
    int nin,
    int *nunits,
    int nlevels,
    int *tranfns,
    float *activs,
    float *biases,
    int ntunits,
    float *weights,
    int nweights,
    float *bschange,
    float *wtchange,
    float *etas,
    float *etbs,
    float alpha,
    float decay,
    float *targs,
    int *targstarts,
    int *targoffs,
    int nout,
    int niter,
    int nbatch,
    int ransel,
    float *err,
    float *errvar)
/* Carries out niter learning cycles on the machine, selecting
 stimuli at random from the stims and targs arrays if
 RANSEL is non-zero, otherwise taking them in sequence.
 Other parameters are as in bprop, fprop and mlp_forward, with targs
 etc. instead of outs etc.

 If nbatch is 1, then does continuous learning with momentum governed by
 alpha. If nbatch is greater than 1, then does batch learning, averaging
 errors over nbatch examples before updating. In this case, alpha is ignored.

 - one special case - if niter is 0, just do a single
 backward pass, assuming that the forward pass has already
 been carried out.

 On return activs is set to the latest error signals,
 and an explicit call of fprop is needed to get activations.

 Err returns the mean error, errvar its variance. Returns fail code. */
{
    float anegs = negs, cerr, errsum = 0.0, errsumsqu = 0.0;
    int iter, eg = -1, dofwd = niter > 0, batching = nbatch > 1, si, so;

    /* check inputs to avoid having to do so on each iteration */
    int ifail = checkns(nunits,nlevels,nin,nout,ntunits,nweights);
    if (ifail) return ifail;
    if (nbatch <= 0) return 10;

    /* When batching, niter is given as number of batches - change to
       no of egs and ensure weight change arrays are zeroed */
    if (batching) {
        niter *= nbatch;
        mlp_fillvec(0.0, wtchange, nweights);
        mlp_fillvec(0.0, bschange, ntunits);
    }

    if (niter == 0) niter = 1;  /* Always do a backward pass */

    /* Iterate */
    for (iter = 1; iter <= niter; iter++) {
        if (ndim) {
            /* stimstarts is n-D array giving limits */
            si = mlp_getsample(ndim, stimstarts, ransel);
            so = mlp_getoutsample(ndim, stimstarts, targstarts);
        } else {
            /* stimstarts 1-D array of starting points */
            if (ransel)
                eg = (int)(erand48(seed) * anegs);
            else
                eg = (eg+1) % negs;
            si = *(stimstarts+eg);
            so = *(targstarts+eg);
        }

        if (dofwd)
            fprop(stims+si, stimoffs,nin,nunits,nlevels,tranfns,activs,
                biases,ntunits,weights,nweights);

        if (batching) {
            cerr = bprop_batch(stims+si, stimoffs, nin, nunits, nlevels,
                tranfns, activs, ntunits, weights, nweights, wtchange,
                bschange, targs+so, targoffs, nout);
            if (iter % nbatch == 0)
                bwtupd_batch(biases, ntunits, weights, nweights,
                    wtchange, bschange, etas, etbs, decay, nbatch);
        }
        else
            cerr = bprop(stims+si, stimoffs, nin, nunits, nlevels, tranfns,
                activs, biases, ntunits, weights, nweights, wtchange,
                bschange, etas, etbs, alpha, decay, targs+so, targoffs,
                nout);

        errsum += cerr;
        errsumsqu += cerr * cerr;
    }

    /* Calculate the error and its variance over this set of trials.
     It's divided by 2 because bprop returns a sum of squares, but actually
      uses the derivative with respect to half the sum of squares. */
    *err = errsum/(2*niter);
    *errvar = errsumsqu/(4*niter) - *err * *err;
    return 0;
}

/* --- Revision History ---------------------------------------------------
--- David Young, Mar  2 2000
        Moved from Sussex local vision libraries to popvision.
--- David S Young, Aug 26 1998
        Added batch learning. Tidied various routines.
        Added fast logistic approximation.
        Added weight decay.
--- David S Young, Aug 25 1998
        Fixed bug in fprop
--- David S Young, Aug 17 1998
        Fixed bug in non-random indexing with full offset arrays.
 */
