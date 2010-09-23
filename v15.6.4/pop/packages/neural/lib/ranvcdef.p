section;

vars ranvcdef = true;
uses cload;

external declare ranvecs in c;

void ranuvec(vec, n, x0, x1)
double vec[];
int n;
double x0;
double x1;
{}

void ranivec(vec, n ,m0, m1)
int vec[];
int n;
int m0;
int m1;
{}

void rangvec(vec, n, mean, sd)
double vec[];
int n;
double mean;
double sd;
{}


void randinit(i)
int i;
{}


void rrandinit(i)
int i;
{}

endexternal;

cload ranvecs;

endsection;
