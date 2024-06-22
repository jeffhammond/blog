# MPI Fortran ABI Challenges and Solutions

This article focuses on the Fortran aspects of the MPI ABI.
The first thing to note is that the Fortran language and compiler ecosystem
does not allow for a standard ABI in the general sense, because Fortran
modules and calling conventions are not standard and known to differ --
often significantly -- between implementations.
When we discuss the MPI Fortran ABI, we are only referring to the parts
of the MPI C ABI that interact with Fortran.

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
are `MPI_<Handle>_{to_int,from_int}` (names could be changed later).
As long as Fortran `INTEGER` is not smaller than C `int`, which is true
in all reasonable environments, these functions can be used to implement
f2c/c2f in the MPI Fortran API.

 


