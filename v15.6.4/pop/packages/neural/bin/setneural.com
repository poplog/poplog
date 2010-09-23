$ define NEURAL_F77 "yes"
$! neural :== 'pop11' /popneural:[bin.vax]neural
$! xneural :== 'neural' \%x
$! mkneural :== "@popneural:[bin]mkneural"
$ neural :== "@popneural:[bin]neural
