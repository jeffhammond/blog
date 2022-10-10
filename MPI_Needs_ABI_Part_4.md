# MPI ABI Design Ideas and Challenges

This is not intended to be useful to others right now, but is a note-taking space for me...

## Ideas

MPICH handles are `int`.  Open-MPI handles are pointers.
We should standardize handles to be `intptr_t` so that both designs are valid.
This is particularly advantageous for the Fortran 2008 module, as noted below.

### Fortran

We should change this:
```fortran
type, bind(C) :: MPI_Handle
  integer :: MPI_VAL
end type MPI_Handle
```
to this
```fortran
type, bind(C) :: MPI_Handle
  integer(kind=c_intptr_t) :: MPI_VAL
end type MPI_Handle
```
at which point all of the C-Fortran handle interoperability stuff becomes irrelevant.

Right now, Fortran handle conversions are trivial with MPICH but not trivial with Open-MPI.
Widening to `intptr_t` makes everything better.

## Challenges

## `MPI_BSEND_OVERHEAD`

> The MPI constant MPI_BSEND_OVERHEAD provides an upper bound on the additional space consumed by the entry 
> (e.g., for pointers or envelope information).

This is implementation-specific.  We need to agree on an upper-bound so that it can be standardized.
