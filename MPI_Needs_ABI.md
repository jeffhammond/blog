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

Now, I compile this code for my system:
```sh
mpicc -O2 -c parallel_ddot.c -o parallel_ddot.o
```
Since MPI is a standard portable interface, the resulting object file is portable, right?  No!

When I invoked `mpicc`, I chose a specific implementation of MPI, and that means that the object file I produced
will only work properly with object files compiled with the same implementation, or an ABI-compatible one (more on this later).
Furthermore, if I built a library, such as `libparallel_math.a` that contains a bunch of object files like this one,
I can only link that library with an application that is compiled with the same MPI implementation.
And if I go completely nuts and use dynamic libraries, any `libparallel_math.so` I create can only be linked and loaded
alongside compatible shared objects and applications.

Finally, if I link my application against against a specific MPI implemntation, I must run the resulting application
with a compatible `mpirun`.

All of this would be irrelevant if everyone used the same MPI implementation, similar to how (almost) everyone uses glibc on Linux,
which means that all the binary applications shipped by Apt or Yum just work, because every single one of them relies on the same
C runtime library.

In contrast, in the MPI world, there are at least two common MPI implementations, Open-MPI and the MPICH family.
Here I say "MPICH family" because, while MPICH, MVAPICH2 and Intel MPI are technically different, they are all mutually
compatible in practice (https://www.mpich.org/abi/ demonstrates this is often intentional).
And to make matters worse, Open-MPI has not committed to a standard ABI, so one must treat different major versions
of Open-MPI as if they are different from an ABI perspective.

The practical consequence of this is that I, the library author, or the downstream packagers, need to build N copies of my library.
This is a real issue and wastes human effort, validation time and storage space.
Here's the MKL distribution of BLACS, the communication library for ScaLAPACK, distributed by Intel:
```sh
$ ll /opt/intel/oneapi/mkl/2021.2.0/lib/intel64/libmkl_blacs*so
lrwxrwxrwx 1 root 32 Mar 25 04:50 /opt/intel/oneapi/mkl/2021.2.0/lib/intel64/libmkl_blacs_intelmpi_ilp64.so -> libmkl_blacs_intelmpi_ilp64.so.1
lrwxrwxrwx 1 root 31 Mar 25 04:50 /opt/intel/oneapi/mkl/2021.2.0/lib/intel64/libmkl_blacs_intelmpi_lp64.so -> libmkl_blacs_intelmpi_lp64.so.1
lrwxrwxrwx 1 root 31 Mar 25 04:50 /opt/intel/oneapi/mkl/2021.2.0/lib/intel64/libmkl_blacs_openmpi_ilp64.so -> libmkl_blacs_openmpi_ilp64.so.1
lrwxrwxrwx 1 root 30 Mar 25 04:50 /opt/intel/oneapi/mkl/2021.2.0/lib/intel64/libmkl_blacs_openmpi_lp64.so -> libmkl_blacs_openmpi_lp64.so.1
lrwxrwxrwx 1 root 30 Mar 25 04:50 /opt/intel/oneapi/mkl/2021.2.0/lib/intel64/libmkl_blacs_sgimpt_ilp64.so -> libmkl_blacs_sgimpt_ilp64.so.1
lrwxrwxrwx 1 root 29 Mar 25 04:50 /opt/intel/oneapi/mkl/2021.2.0/lib/intel64/libmkl_blacs_sgimpt_lp64.so -> libmkl_blacs_sgimpt_lp64.so.1
```
There is one BLACS build for each of MPICH, Open-MPI and SGI MPT, plus one build for each flavor of Fortran ABI.
The Fortran ABI issue is similar but not one we are going to solve in the MPI Forum.
Plus, the Fortran standard experts will explain that this issue is the result of improper use of Fortran
compilers and can be avoided just by using features that already exist in the Fortran standard.

## 

