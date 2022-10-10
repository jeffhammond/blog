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

## Other compile-time constants

Right now, all we say about thread levels is:
> These values are monotonic; i.e., MPI_THREAD_SINGLE < MPI_THREAD_FUNNELED < MPI_THREAD_SERIALIZED < MPI_THREAD_MULTIPLE.
MPICH defines them in a very logical way.  There is no reason not to standardize this, or something similar.
```
MPI_THREAD_SINGLE     = 0
MPI_THREAD_FUNNELED   = 1
MPI_THREAD_SERIALIZED = 2
MPI_THREAD_MULTIPLE   = 3
```

There are no rules for how these can be defined, but again, we have to pick something to standardize.
```
MPI_IDENT     = 0
MPI_CONGRUENT = 1
MPI_SIMILAR   = 2
MPI_UNEQUAL   = 3
```

We need to decide on an upper-bound for these, which are currently implementation-specific.
```
MPI_MAX_PROCESSOR_NAME
MPI_MAX_LIBRARY_VERSION_STRING
MPI_MAX_ERROR_STRING
MPI_MAX_DATAREP_STRING
MPI_MAX_INFO_KEY
MPI_MAX_INFO_VAL
MPI_MAX_OBJECT_NAME
MPI_MAX_PORT_NAME
```
