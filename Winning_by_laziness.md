# Winning via Laziness

This post describes my life philosophy of never doing things myself that
can be done better by others.

# Background on Tensors

As a quantum chemist focused on coupled-cluster theory in graduate school,
I found myself looking at a lot of tensor contractions.
For the uninitiated, tensor contractions are a class of linear algebra operation
that look like matrix multiplication, but with more indices.
Here is an example of a tensor contraction:
```
for all i,j,k,a,b,c:
    R(i,j,a,b) = T(i,k,a,c) * V(j,k,b,c)
```
This example might be found in CCSD (coupled-cluster singles and doubles).

This can be contrasted wtih the simpler but similar case of matrix-matrix multiplication:
```
for all i,j,k:
    R(i,j) = T(i,k) * V(j,k)
```
The well-known libraries for the latter are called the BLAS
(Basic Linear Algebra Subroutines)
and the specific procedure is `_GEMM`, where `_` is a letter
associated with numerical type used.

In the BLAS `_GEMM`, there are 4 possible index permutations
support, two for each input matrix, depending on whether one
contracts over the row or column indices.
The permutation on the output matrix can be handled implicitly
by swapping the input matrices, because `(AB)^T=B^T A^T`.

In the first example, there are many more possibilities.
One can access each tensor in 24 different ways, ranging from
1234 to 4321.  There are thus 24x24x24=13824 distinct implementations
of that single tensor contraction, which is one of many possibilities.

There is one obvious simplification possible here, which is to 
not try to optimize all the contractions directly, but to first
rearrange the 4D tensors into cases that are handled directly
by the BLAS.
The simplest approach is to rearrange all 24 cases into a single
canonical one, in which case, implementation all 13824 cases boils
down to the application of 23 (24 minus the identity permutation)
permutations to each of the 24 cases of 4D tensors,
and one type of BLAS call.

However, as has been shown previously
(cite dissertation and Paul's papers),
tensor permutations are expensive, and may be the bottleneck if
used excessively.
It is therefore prudent to both optimize permutations and to call
the least expensive ones.
One way to reduce the need for expensive permutations is to observe
that the BLAS can perform the canonical matrix transpose permutation
internally, at negligible cost.
Thus, one should be able to use only 11 permutations, and do the
`(12)<->(34)` part of any permutation inside of the BLAS.
There are additional reductions possible, by breaking up contractions
into multiple BLAS calls, including matrix-vector products, not
just matrix-matrix products.
Edoardo de Nipolini and coworkers have studied this.

This is another way for one to optimize these operations,
which is to convince other people to do it.

# Outsourcing hard problems

Many quantum chemists over the years have tried to be smart
and solve hard computational problems with tensor contractions.
I won't name all of them.
I played around with optimization tensor permutations,
which led to a modest success that made it into my dissertation,
but I knew that there were much better implementations possible,
and, more importantly, that I did not know how to produce them.

Supercomputing 2007 (?) was in Austin, Texas, which is home
to the research group of Robert van de Geijn.
Robert's group knows a bit about dense linear algebra.
I met Robert during Supercomputing, and asked him about tensors.
He invited me to his office later in the week, and I spent a
day with Robert and Maggie, talking about everything that was
right and wrong about linear algebra software.
We did not solve any tensor contraction problems that day.
However, I did manage to convince Robert that I had mildly interesting
computational problems to solve.

I will not go into detail but the long-term result of that discussion,
and many others that 


