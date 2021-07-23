# It's past time for MPI to have a standard ABI

## Introduction

[MPI](https://www.mpi-forum.org/) has always been API standard.
Implementations are not constrained in how they define opaque types (e.g. `MPI_Comm`),
which means they compile into different binary representations.
This is fine for users who only use one implementation, or are content to recompile their software for each of these.
Many users, including those building both traditional C/C++/Fortran libraries and new languages that use MPI via the C ABI,
are tired of the duplication of effort required because MPI lacks a standard ABI.

- API = Application Programming Interface, i.e. the signature `MPI_Barrier(MPI_Comm)`.
- ABI = Application Binary Interface, i.e. the binary representation of `MPI_Comm` in memory (e.g. `int` vs a pointer).

## Motivating example

The MPI Forum has often espoused the view that MPI is designed for building libraries.
Many of the APIs in the MPI standard are specifically designed for this purpose, and don't have much use in other contexts,
since attaching state to MPI communications, for example, isn't necessary if the code that calls MPI is monolithic;
in that case, such state can be managed directly by the application.

Let's consider a trivial library that implements a dot product using MPI:
```c
// Please ignore the lack of support for vectors longer than `MPI_INT` or 
// error handling - this code is not intended to be used in production.
double parallel_ddot(MPI_Comm comm, double * x, double * y, int length)
{
  double z = 0.0;
  for (int i=0; i<length; ++i) {
    z += x[i] * y[i];
  }
  
  double result = 0.0;
  MPI_Allreduce(&z, &result, MPI_DOUBLE, MPI_SUM, comm);
  
  return result;
}
```


## 

