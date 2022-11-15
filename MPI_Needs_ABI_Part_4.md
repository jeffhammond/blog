# MPI ABI Design Ideas and Challenges

This is not intended to be useful to others right now, but is a note-taking space for me...


## Context

This is important:

> All named constants, with the exceptions noted below for Fortran, can be used in initialization expressions or assignments, 
> but not necessarily in array declarations or as labels in C switch or Fortran select/case statements. 
> This implies named constants to be link-time but not necessarily compile-time constants. 
> The named constants listed below are required to be compile-time constants in both C and Fortran. 
> These constants do not change values during execution. Opaque objects accessed by constant handles are defined 
> and do not change value between MPI initialization (MPI_INIT) and MPI completion (MPI_FINALIZE). 
> The handles themselves are constants and can be also used in initialization expressions or assignments.

## Ideas

MPICH handles are `int`.  Open-MPI handles are pointers. 
We could standardize handles to be `intptr_t` so that both designs are valid, but we can do better.
One issue with both approaches is the lack of type checking.
For example, [this bug](https://github.com/ParRes/Kernels/commit/ee5e5fb09019bd78325d9680cd93f52858812aa4)
existed for years because the developers only tested with MPICH-based implementations.
More generally, C compilers have no way to distinguish between different `typedef`-to-`int` handles,
and thus in calls where it is possible to transpose handles, compilers may struggle to detect these mistakes
with some implementations (e.g. MPICH).

We can learn from the Fortran 2008 design here, and make handles a C `struct`, which contains
a single value, `intptr_t`.  This allows C compilers to check handles for type-correctness,
but adds no overhead, because there is no overhead to accessing the first element
of a struct.

Furthermore, since the exact same type can be defined in Fortran 2003, we can eliminate
handle conversion functions altogether.
Handle conversions will remain required for `use mpi` (`mpif.h` should be deleted in MPI-5)
but that's a necessary evil for legacy Fortran users.

Today, handle conversion overhead is nontrivial in operations like `MPI_Waitall`, because
a temporary vector must be allocated (unless the implementation "cheats" in some way).
The proposed ABI definition of handles will eliminate this.

### C handles

This is how a handle should be defined:
```c
typedef struct {
  intptr_t val;
} MPI_Handle;
```
The name of the member of the `struct` does not matter, because users should not access them.
There is not a lot of value in obfuscating the contents, and some of the methods for doing
that make type checking impossible.
Having type checking for well-behaved users is far more important than trying to prevent
users who want to violate the standard from writing illegal code.

### Fortran handles

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
No implemenation will have overhead with the MPI-5 ABI.

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

## String-related constants

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

## Other constants

These are also compile-time constants:
```
MPI_VERSION
MPI_SUBVERSION
MPI_F_STATUS_SIZE (C only)
MPI_STATUS_SIZE (Fortran only)
MPI_ADDRESS_KIND (Fortran only)
MPI_COUNT_KIND (Fortran only)
MPI_INTEGER_KIND (Fortran only)
MPI_OFFSET_KIND (Fortran only)
```

`MPI_VERSION` and `MPI_SUBVERSION` remain specified based on the library features, at compile-time.
Users can use `MPI_Get_version` to verify consistency with run-time support.

`MPI_F_STATUS_SIZE` and `MPI_STATUS_SIZE` are fixed as soon as the ABI of `MPI_Status` is defined.

`MPI_*_KIND` follow from standardization of the associated C types.

## Fortran compiler support

These depend on the Fortran compiler, and how the library deals with `CFI_cdesc_t`.
These should be deprecated and replaced with run-time queries, if possible, although
some applications may need to be able to rely on them at compile-time.
```
MPI_SUBARRAYS_SUPPORTED (Fortran only) 
MPI_ASYNC_PROTECTS_NONBLOCKING (Fortran only)
```
These features are associated with Fortran 2018 support, and should be widely supported
by the time we are going to vote on an ABI anyways.
It made sense to make them optional in 2012, but by 2024, they should be required.

## Disclaimer and license

The opinions expressed in this post are exclusively the author's and not those of his 
current and past co-workers, co-authors, friends or family members.

(c) Copyright Jeff Hammond, 2021. No reuse permitted except by permission from the author.
