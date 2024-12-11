# MPI Fortran ABI Challenges and Solutions

This article focuses on the Fortran aspects of the MPI ABI.
The first thing to note is that the Fortran language and compiler ecosystem
does not allow for a standard ABI in the general sense, because Fortran
modules and calling conventions are not standard and known to differ --
often significantly -- between implementations.
When we discuss the MPI Fortran ABI, we are only referring to the parts
of the MPI C ABI that interact with Fortran.

# Handle conversion and `MPI_Fint`

The most obvious interaction between Fortran and the MPI C ABI is `MPI_Fint`
and functions that use it.  Sadly, it is allowed for Fortran compilers to
change the size of the type `INTEGER` using compiler flags (e.g., `-i8`),
hence the `MPI_Fint` type in C code has to know what Fortran compiler flags
were used.  Thus, there is no way to make this type definition part of the
MPI C ABI, and therefore all of the `MPI_<Handle>_{f2c,c2f}` functions are
ill-defined.

One solution to the `MPI_Fint` problem would be to define it to C `int`
and disallow MPI Fortran support from using an `INTEGER` that is not
equivalent.  Instead, we will add new functions that are nearly identical
to f2c/c2f that do not depend on the Fortran compiler.  These functions
are `MPI_<Handle>_{toint,fromint}`.
As long as Fortran `INTEGER` is not smaller than C `int`, which is true
in all reasonable environments, these functions can be used to implement
f2c/c2f in the MPI Fortran API.

Why bother with these functions at all?  Are they strictly necessary?
Once we have the MPI C ABI, the handle types will be known to be C pointers,
which could be stored in Fortran via CFI (C-Fortran interoperability).
Unfortunately, all of the MPI Fortran API assumes handles are `INTEGER`,
or a type that contains an `INTEGER`.

In an implementation of the MPI Fortran API, 
such as [Vapaa](https://github.com/jeffhammond/vapaa), 
it is necessary to convert handles from Fortran to and from C quickly.
For predefined handles, the MPI ABI makes this trivial, since all the
constant values are small and one can cast with truncation.
For user handles, the forward conversion (from Fortran to C) is often
on the critical path, which can implemented using an array of handles.
However, one of the most performance critical parts of MPI will involve
the back conversion from C to Fortran of requests.  It is possible to
implement this mapping in Vapaa but not easy to do efficiently.
It is expected that implementations can provide a more efficient implementation.

Because the C status object (`MPI_Status`) is now fully specified, no
new conversion functions are required.

# Fortran types and their MPI datatypes

When we call a reduction from Fortran with, e.g., `MPI_REAL`,
a user-defined callback will get a datatype argument.
If the C implementation of MPI doesn't know what `MPI_REAL` is,
it's going to detect this as an invalid datatype.
We can't just work around this by translating Fortran types
to C types and passing `MPI_FLOAT`, because this means that
datatype logic inside of user callbacks written in Fortran will
not work.
Thus, the MPI C implementation needs to know that `MPI_REAL` is
valid and to preserve it throughout the program.
At the same time, it also needs to know how to implement built-in
reductions and other features correctly.

The solution to this problem is a function to inform MPI of the
C equivalents of all Fortran types.  This way, the MPI library can
implement `(MPI_REAL,MPI_SUM)` reductions with `MPI_FLOAT` and get
native performance.  Otherwise, a library like Vapaa would have to
implement all the built-in reductions manually, which is not optimal.

The other issue here is that MPI may need to implement logical reductions
like `MPI_LAND`, `MPI_LOR` and `MPI_LXOR` in C.  This requires it to know
how Fortran `LOGICAL` works.  For historical reasons, going back to the
VAX platform, Fortran `LOGICAL` may not behave like C.  It may, for example,
use the sign bit to represent booleans, rather than 0 and non-zero.
Even if 0 is `.FALSE.`, `.TRUE.` could be 1 or `0xFFFFFFFF`.

As before, we need a function to tell MPI what the literal values of
Fortran `.TRUE.` and `.FALSE.` are.

# Sentinels


# Callbacks

This one is more difficult, and is not part of the current proposal for the standard.
