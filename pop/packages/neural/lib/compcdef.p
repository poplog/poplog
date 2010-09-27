section;

vars compcdef  = true;
uses cload;

external declare complearn in c;

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
double invec[];
int     nin;
int    nunits[];
int     nlevels;
double activs[];
double biases[];
int     ntunits;
double weights[];
int     nweights;
int    clusters[];
int     nclusters;
int    clustlev[];
double outvec[];
int     nout;
int     ifail[];
{}


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
double stims[];
int     nstims;
int     nstep;
int     nin;
int     negs;
int    nunits[];
int     nlevels;
double activs[];
double biases[];
int     ntunits;
double weights[];
int     nweights;
int    clusters[];
int     nclusters;
int    clustlev[];
double outvecs[];
int     nout;
int    ifail[];
{}


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
double invec[];
int     nin;
int    nunits[];
int     nlevels;
double activs[];
double biases[];
int     ntunits;
double weights[];
int     nweights;
int    clusters[];
int     nclusters;
int    clustlev[];
double  gw;
double  gl;
double  rw;
double  rl;
int    ifail[];
{}


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
double stims[];
int     nstims;
int     nstep;
int     nin;
int    nunits[];
int     nlevels;
double activs[];
double biases[];
int     ntunits;
double weights[];
int     nweights;
int    clusters[];
int     nclusters;
int    clustlev[];
double  gw;
double  gl;
double  rw;
double  rl;
int    ifail[];
{}






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
double stims[];
int     nstims;
int     nstep;
int     nin;
int    nunits[];
int     nlevels;
double activs[];
double biases[];
int     ntunits;
double weights[];
int     nweights;
int    clusters[];
int     nclusters;
int    clustlev[];
double  gw;
double  gl;
double  rw;
double  rl;
int    ifail[];
{}


void clnorm(wts,
            nweights,
            nin,
            nunits,
            nlevels)
double wts[];
int     nweights;
int     nin;
int    nunits[];
int     nlevels;
{}

endexternal;

cload complearn;

endsection;
