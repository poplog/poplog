section;

vars backcdef = true;
uses cload;

external declare backprop in c;

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
double invec[];
int    nin;
int    nunits[];
int    nlevels;
double activs[];
double biases[];
int    ntunits;
double weights[];
int    nweights;
double outvec[];
int    nout;
int   ifail[];
{}


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
double stims[];
int    nstims;
int    nstep;
int    nin;
int    negs;
int   nunits[];
int    nlevels;
double activs[];
double biases[];
int    ntunits;
double weights[];
int    nweights;
double outvecs[];
int    nout;
int   ifail[];
{}


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
double targvec[];
int    ntarg;
int   nunits[];
int    nlevels;
double activs[];
double biases[];
double bschange[];
int    ntunits;
double weights[];
double wtchange[];
int    nweights;
double  eta;
double  alpha;
double invec[];
int    nin;
int   ifail[];
{}


void bpin(weights,
          nweights,
          activs,
          nactivs,
          nlowest,
          invec,
          nin)
double weights[];
int    nweights;
double activs[];
int    nactivs;
int    nlowest;
double  invec[];
int    nin;
{}


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
double targs[];
int    ntarg;
int    negs;
double stims[];
int    nstims;
int    nstep;
int    nin;
int   nunits[];
int    nlevels;
double activs[];
double biases[];
double bschange[];
int    ntunits;
double weights[];
double wtchange[];
int    nweights;
double  eta;
double  alpha;
double outvec[];
int   ifail[];
{}


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
double targs[];
int    ntarg;
int    negs;
double stims[];
int    nstims;
int    nstep;
int    nin;
int   nunits[];
int    nlevels;
double activs[];
double biases[];
double bschange[];
int    ntunits;
double weights[];
double wtchange[];
int    nweights;
double  eta;
double  alpha;
double outvec[];
int   ifail[];
{}

endexternal;

cload backprop;

endsection;
