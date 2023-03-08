# Dealing with Imperfect Fortran Compilers, Part 2

TL;DR You can build your Fortran application with two different compilers to get
the best of both worlds when it comes to coarrays and GPU parallelism, for example.
This is not the easiest thing to do, but it's better than the bucket of tears
you're living with right now.

## The Goal

What we want to build here is a bridge between two Fortran compilers.
The most general bridge is the standard C-Fortran interoperability (CFI)
feature set found in Fortran 2018, but we will also describe
a bridge that uses the implenentation-specific array descriptor
of the NVIDIA (nee PGI) Fortran compiler, because that was original
motivation for this project.

## Fortran Type-Checking

Fortran is a strongly type language, although legacy Fortran
compilers had no good way to enforce this, so users regularly
abused the fact that Fortran compilers (almost?) always pass
arguments by reference.
This has allowed functions like `MPI_Bcast` to work for any 
Fortran buffer input, since the underlying implementation only
cares about the number of bytes that need to fly around the
machine.
Starting in Fortran 90, compilers used modules and the 
interfaces contained therein to check types, which was
a problem for MPI [4] although it was mitigated with the
use of non-standard directives
(usually containing `IGNORE_TKR`, which means "ignore Type, Kind and Rank").

In part because of MPI, Fortran added a way to do type-agnostic
arguments, which is sort of like C's `void *`, but it
imposes more rules of what users can do with it.

## How CFI Works

In a Fortran program, one can declare a dummy argument that is
assumed-type (`TYPE(*)`) and assumed-rank (`DIMENSION(..)`).
Within a Fortran program, one can decode such an argument
using `SELECT TYPE` and `SELECT RANK`.
You can look up how those works but they are not important here.
When such arguments are used in the context of CFI,
the C function sees a special argument of the type
`CFI_cdesc_t` that contains all of the information required
to reconstitute the Fortran array details.

For example, if I pass a 1D array of double precision elements,
which technically should use `real(c_double)` but I can cheat 
if I'm sure that a C `double` and a Fortran `double precision`
are the same thing,
my C code will use the following members of `CFI_cdesc_t`:

```c
void * base_addr = <memory location of the array data>
size_t elem_len  = sizeof(double) = 8
CFI_rank_t rank  = 1
CFI_type_t type  = CFI_type_double
CFI_dim_t dim[1] = { .. }
```
The last listed memory, `dim`, contains the size information
for each array dimension.
For contiguous array arguments, it's easy to understand this,
while for non-contiguous array arguments, one has to be a bit
more careful.

Please see Ref. [1,2,3] for details.
This blog post is not meant to be a complete tutorial on CFI.

## Duct Tape, Part 1

Unfortunately, CFI is only a standard API, and the ABI is not specified.
Implementations are permitted to use different integer types
for the various members, e.g. `CFI_rank_t`, and can choose
their own order of the struct members, with the exception of
`base_addr`, `elem_len`, and `version`, which must come first.
This means that one has to compile C code for each Fortran
compiler using the correct `ISO_Fortran_binding.h` header file.

There is a simple but annoying solution to this.
If I define my own implementation of `CFI_cdesc_t`
(with a different name, of course)
then I can convert from one compiler's ABI to anothers as follows.
Note that the code below was written directly into this
blog and has never been compiled or tested.
Implementing a correctly functioning version of this
is left as an exercise to the reader (for now).

```c
#include <ISO_Fortran_binding.h>

// the symbols need to be disambiguity
#define MANGLE(x) FORTRAN_COMPILER_NAME ## _ ## x

// DT = Duct Tape
// use int64_t under the assumption that it is big enough for any implementation ABI. 
// this assumption should be verified in production code.
typedef DT_cdesc_t {
  void * base_addr;
  size_t elem_len;
  int64_t rank;
  int64_t type;
  ...
}

// define a DT_type_t enum etc.

// convert a CFI descriptor to a DT one
void MANGLE(CFI_to_DT)
(const CFI_cdesc_t * i, DT_cdesc_t * o)
{
  o->base_addr = i->base_addr;
  o->elem_len  = i->elem_len;
  o->rank      = i->rank;
  
  // because the values of CFI_type_t can be different between implementations,
  // we need to have our set of DT_type_t values and translate them in both directions.
  o->type      = translate_type_t_CFI_to_DT(i->type);
  
  // more stuff...
}

// convert a DFT descriptor to a CFI one
void MANGLE(DT_to_CFI)
(const DT_cdesc_t * i, CFI_cdesc_t * o)
{
  o->base_addr = i->base_addr;
  o->elem_len  = i->elem_len;
  o->rank      = i->rank;
  
  // because the values of CFI_type_t can be different between implementations,
  // we need to have our set of DT_type_t values and translate them in both directions.
  o->type      = translate_type_t_DT_to_CFI(i->type);
  
  // more stuff...
}
```

This file needs to be compiled for every Fortran compiler.

Then I can write another C function that uses e.g.
`Intel_Fortran_CFI_to_DT` and `Cray_Fortran_DT_to_CFI`
to send an array from an Intel Fortran subroutine
to a Cray Fortran subroutine.

## Duct Tape, Part 2

Unfortunately, not all Fortran compilers support Fortran 2018 CFI right now.
Fortunately, it's actually easier to implement the equivalent of the above
duct tape in this case, because there is no ABI conflict between CFI
descriptors and non-standard ones.

Now I'm going to describe how to call NVIDIA Fortran from another Fortran
compiler that supports Fortran 2018, particularly both CFI and coarrays.
The motivation is that there are people out there who want to use 
GPU `DO CONCURRENT` support in the NVIDIA Fortran compiler along with
existing coarray applications.

The following code is taken from https://github.com/jeffhammond/Cthulhu, 
which has been compiled and works correctly in limited testing.
We use the [Parallel Research Kernels](https://github.com/ParRes/Kernels)
implementations of `nstream` (like STREAM triad) to illustrate how this works.
The goal is to take [nstream-coarray.F90](https://github.com/ParRes/Kernels/blob/default/FORTRAN/nstream-coarray.F90)
and allow the `do concurrent` part to use the NVIDIA Fortran compiler
with GPU support enabled.
The relevant portion of the code is shown below.

```fortran
...
  real(kind=REAL64), allocatable ::  A(:)[:]
  real(kind=REAL64), allocatable ::  B(:)[:]
  real(kind=REAL64), allocatable ::  C(:)[:]
  real(kind=REAL64) :: scalar
...
    do concurrent (i=1:length)
      A(i) = A(i) + B(i) + scalar * C(i)
    enddo
...
```

The first step is to outline the `do concurrent` part
and make it into a subroutine call.
```fortran
    !do concurrent (i=1:length)
    !  A(i) = A(i) + B(i) + scalar * C(i)
    !enddo
    call nstream_colon_trampoline(length,scalar,A,B,C)
```
_Aside: I use `colon` in the name to refer to `(:)`, in contrast
to other dummy argument syntax, `(N)` or `(*)`, that I tried,
not because of any connection to the gastrointestinal system._

The subroutine has the following interface defined in a module.
```fortran
    interface
        subroutine nstream_colon_trampoline(length,scalar,A,B,C) bind(C)
            use, intrinsic :: iso_fortran_env
            integer(kind=INT64), value :: length
            real(kind=REAL64), value :: scalar
            real(kind=REAL64), dimension(:) :: A,B,C
        end subroutine nstream_colon_trampoline
    end interface
```
Having the interface is important if the F90 array descriptor is sufficiently
incompatible with a CFI descriptor so as to not work.
It is possible that some Fortran compilers need to see the
`type(*), dimension(..)` to generate a proper `CFI_cdesc_t`.

The above is implemented in C and looks like this:
```c
void nstream_colon_trampoline(int64_t length, double scalar, 
                              CFI_cdesc_t * dA, CFI_cdesc_t * dB, CFI_cdesc_t * dC)
{
    double * restrict A = dA->base_addr;
    double * restrict B = dB->base_addr;
    double * restrict C = dC->base_addr;
    F90_Desc_la pA={0}, pB={0}, pC={0};
    cfi_to_pgi_desc(dA,&pA);
    cfi_to_pgi_desc(dB,&pB);
    cfi_to_pgi_desc(dC,&pC);
    nstream_colon(length, scalar, A, B, C, &pA, &pB, &pC);
}
```
Here we see the descriptor conversion from CFI to the PGI->NVIDIA descriptor (`F90_Desc_la`),
which is defined in `nvhpc_cuda_runtime.h` that ships with the 
[NVHPC SDK](https://developer.nvidia.com/nvidia-hpc-sdk-downloads).
We copied the relevant parts, which can be seen in
[pgif90.h](https://github.com/jeffhammond/Cthulhu/blob/main/pgif90.h).

The descriptor conversion is done in `cfi_to_pgi_desc`, which can be found in
[trampoline.h](https://github.com/jeffhammond/Cthulhu/blob/main/trampoline.h).
A real implementation of the type id conversion alluded to above is shown there as well.

The C code calls `nstream_colon`, which is a Fortran subroutine compiled with
the NVIDIA compiler, shown below.
```fortran
subroutine nstream_colon(length,scalar,A,B,C) bind(C)
    use, intrinsic :: iso_fortran_env
    integer(kind=INT64), value :: length
    real(kind=REAL64), value :: scalar
    real(kind=REAL64), dimension(:) :: A,B,C
    integer(kind=INT64) :: i
    do concurrent (i=1:length)
      A(i) = A(i) + B(i) + scalar * C(i)
    enddo
end subroutine nstream_colon
```

To glue the C code to the NVIDIA Fortran code,
I needed to know that NVIDIA Fortran passes the buffer address in the expected place
and appends the array descriptors at the end, similar to how Fortran strings are passed.

## Summary

What we just did was write a Fortran program that calls CFI-compatible interface
(using Fortran 2018 features)
to a C function that converts one Fortran compiler array descriptor to another
Fortran compiler array descriptor that calls a C-compatible Fortran subroutine
(using only Fortran 2003 features).

Neither of the Fortran compilers know each other exist as each is talking to C code.
The Fortran coarray code is calling a C function, with a known-compatible interface.
The Fortran `do concurrent` code is called by a C function that passes it the necessary metadata.
All of this is within the scope of why CFI was designed,
although it's not clear if WG5 (the Fortran standards committee) foresaw the
perverse use case show here.
(Most likely, WG5 imagined that one would never need to do this because all
Fortran compilers are perfect implementations of the standard. 😉)

The real hero is, of course, the all-powerful C language, which can communicate with
any other programming languages thanks to its lack of support for the type of
expressive language features that would get in the way.
However, since you are here because you love Fortran enough to try to use the union
of features found in two different compilers, the other hero here is CFI,
which allows Fortran to masquerade as C at the binary object level, thereby
enabling Fortran programmers to create libraries as if they were written in C,
and thus can be called from any other language, including Fortran.

## References

  1. Michael Metcalf, John Reid, Malcolm Cohen. [Modern Fortran Explained: Incorporating Fortran 2018](https://academic.oup.com/book/26799)
  2. Intel Fortran: [C Structures, Typedefs, and Macros for Interoperability](https://www.intel.com/content/www/us/en/develop/documentation/fortran-compiler-oneapi-dev-guide-and-reference/top/compiler-reference/mixed-language-programming/standard-tools-for-interoperability/c-structures-typedefs-macros-for-interoperability.html#c-structures-typedefs-macros-for-interoperability)
  3. GCC Fortran: [Interoperability with C](https://gcc.gnu.org/onlinedocs/gfortran/Interoperability-with-C.html)
  4. C. E. Rasmussen, J. M. Squyres. [A Case for New MPI Fortran Bindings](https://www.open-mpi.org/papers/euro-pvmmpi-2005-fortran/euro-pvm-mpi-2005-fortran.pdf).

## Disclaimer and license

The opinions expressed in this post are exclusively the author's 
and not those of his current and past co-workers, co-authors, friends or family members.

(c) Copyright Jeff Hammond, 2022. No reuse permitted except by permission from the author.
