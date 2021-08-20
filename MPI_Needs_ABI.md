# It's past time for MPI to have a standard ABI

## Introduction

[MPI](https://www.mpi-forum.org/) has always been an API standard.
Implementations are not constrained in how they define opaque types (e.g. `MPI_Comm`),
which means they compile into different binary representations.
This is fine for users who only use one implementation, or are content to recompile their software for each of these.
Many users, including those building both traditional C/C++/Fortran libraries and new languages that use MPI via the C ABI,
are tired of the duplication of effort required because MPI lacks a standard ABI.

Definitions:
- API = Application Programming Interface, i.e. the signature `MPI_Barrier(MPI_Comm)`.
- ABI = Application Binary Interface, i.e. the binary representation of `MPI_Comm` in memory (e.g. `int` versus a pointer).

## Motivating example

The MPI Forum has often espoused the view that MPI is designed for building libraries.
Many of the APIs in the MPI standard are specifically designed for this purpose, and don't have much use in other contexts,
since attaching state to MPI communications, for example, isn't necessary if the code that calls MPI is monolithic;
in that case, such state can be managed directly by the application.

Let's consider a trivial library that implements a dot product using MPI:
```c
// Please ignore the lack of support for vectors longer than `MPI_INT` or 
// error handling - this code is not intended to be used in production.
double parallel_ddot(MPI_Comm comm, const double * x, const double * y, int length)
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

Finally, if I link my application against a specific MPI implementation, I must run the resulting application
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

## The language use case

C/C++ and Fortran applications aren't the only consumers of MPI.
Because of MPI's rich capability for multiprocessing, and standard nature, many developers
would like to use MPI from [Python](https://www.python.org/),
[Julia](https://julialang.org/), [Rust](https://www.rust-lang.org/), etc.

How does one do this?  Because MPI implementations are all written in C, any language
can call MPI via its own mechanism for calling C ABI symbols, which they all have
due to needing to interact with the Linux operating system, etc.
However, unlike e.g. `malloc`, which has a constant ABI on Linux, these languages
need to know the binary representation of all of the MPI types to call those symbols.

What this means is that the effort to build and test these MPI wrappers is O(N).

We see this clearly in the Rust MPI project, [rsmpi](https://github.com/rsmpi/rsmpi),
which reports testing against three different implementations, plus untested user experiences
with a fourth:
> rsmpi is currently tested with these implementations:
>
> * OpenMPI 3.0.4, 3.1.4, 4.0.1
> * MPICH 3.3, 3.2.1
> * MS-MPI (Windows) 10.0.0
>
> Users have also had success with these MPI implementations, but they are not tested in CI:
>
> * Spectrum MPI 10.3.0.1

They furthermore alude to the O(N) effort here:

> Since the MPI standard leaves some details of the C API unspecified (e.g. whether to implement certain constants and even functions using preprocessor macros or native C constructs, the details of most types, ...) rsmpi takes a two step approach to generating functional low-level bindings.
> 
> First, it uses a thin static library written in C (see rsmpi.h and rsmpi.c) that tries to capture the underspecified identifiers and re-exports them with a fixed C API. This library is built from build.rs using the gcc crate.
>
> Second, to generate FFI definitions tailored to each MPI implementation, rsmpi uses rust-bindgen which needs libclang. See the bindgen project page for more information.
>
> Furthermore, rsmpi uses the libffi crate which installs the native libffi which depends on certain build tools. See the libffi project page for more information.

The [libffi](https://en.wikipedia.org/wiki/Libffi) project is used by many projects to call C libraries, so we can expect this pain to reappear over and over.

We see the same duplication of testing effort in [mpi4py](https://github.com/mpi4py/mpi4py/).
The project's [Azure pipelines](https://github.com/mpi4py/mpi4py/blob/master/.azure/pipelines.yml) show
tests for each of four different versions of Python on Linux, MacOS and Windows, where Linux and MacOS
testing is doubled for MPICH and Open-MPI.
It is possible to argue that projects should test against multiple implementations even if there is only
one MPI ABI, but it's not obvious that this testing should be exhaustive in the way it is today,
or that the hunt for implementation-specific bugs needs to be done in automated CI/CD environments
running in shared-memory instances in the cloud.

## How do we solve this problem?

The first step in solving any problem is to admit that there is a problem.
This is nontrivial in this case, because many in the MPI Forum, especially the implementers,
believe that implementation freedom w.r.t. ABI is a feature, not a defect.
Implementations will often argue that their ABI is the best design, which obviously creates
some irreconcilable differences with other implementations, plus at least the MPICH ABI camp
will argue that, even if their ABI isn't perfect, it's stability is an essential feature of
the MPI ecosystem, and the cost of changing it is too great.

As the argument goes on, there will be arguments about how compile-time constants allow
lower latency than link-time constants, because of the potential for one cache miss or
one branch prediction on the critical path.
If these performance arguments are valid, we should be able to see the impact experimentally.
Hemal Shah, Moshe Voloshin, and Devesh Sharma measured MPI latency of MVAPICH2 versus Open-MPI
and presented at [MUG20](http://mug.mvapich.cse.ohio-state.edu/mug/20/).

<img width="594" alt="mv-vs-ompi" src="https://user-images.githubusercontent.com/406118/126758671-5946447f-037f-4761-96f0-164aa9335a2a.png">

If we attribute the entire difference between the two libraries to the ABI choice,
then it is a very small effect, on the order of 100 nanoseconds, out of the 2500+ nanoseconds
required to send a small message.
See the [full presentation](http://mug.mvapich.cse.ohio-state.edu/static/media/mug/presentations/20/sharma-mug-20.pdf) for details.

Perhaps that 100 nanoseconds is due to a cache miss when `MPI_Send` in
Open-MPI dereferences `struct ompi_communicator_t *MPI_Comm`, but it could also be a cache miss
in the guts due to how these libraries represent state that isn't user-visible,
or perhaps it is just the aggregate cost of a few dozen instructions and handful of branches
that MVAPICH2 lacks versus Open-MPI.
The question is whether the MPI user community cares more about these 100 nanoseconds
versus the hours and days it takes humans to build the MPI software ecosystem twice,
three times, or more, because of the lack of a standard ABI.

Once the MPI Forum accepts that this is a problem, we can have all the
arguments about what the right standard ABI is, but we cannot use any of those
arguments to get in the way of deciding that there is, in fact, a problem to solve.
It is the MPI Forum's responsibility to act on behalf of its users, in order
to remain relevant.

## Relevant prior art / best practice

A very useful principal of the MPI Forum is that it does not standardize research, but practice.
In the case of ABI compatibility, the HPC user community at [CEA](http://www-hpc.cea.fr/) has found the ABI
issue to be sufficiently obnoxious that they built [wi4mpi](https://github.com/cea-hpc/wi4mpi)
specifically to solve this problem.  CEA has been shipping this software since 2016, although
the original license prevented its widespread use until now.

It is also known that there is a patent on one particular methods of interoperating different
MPI ABIs that prevents its use by the open-source community, but which demonstrates that
at least one company recognized the value of solving this problem important enough to patent it.
Sadly, the patent holder only managed to prevent others from solving the problem in open-source --
they haven't actually bothered to implement the solution in a commercial product.

## Conclusion

Every rational person in high-performance computing will admit that people are the most valuable
component in our ecosystem.
Furthermore, because MPI is a successful standard, there are hundreds of times more people
using MPI and building software against it than there are implementing it.
It is past time for the MPI Forum to prioritize the needs of its user community over the
needs of its implementaters, or the dubious claims of performance overhead due to pointer chasing.

We need to pay the price of breaking all the ABIs one more time, in order to free our users from the pain
of O(N) build and test of all the code that depends on MPI.

![MPI-ABI](https://user-images.githubusercontent.com/406118/127174807-1cd9676a-eb8b-40d6-8da3-b154121e8182.jpg)

Modern processors are incredibly good at pointer chasing, branch prediction, etc.
We need to let those processors do their jobs and stop prematurely optimizing for something
that isn't even a proven bottleneck on processors built in the past decade.

Furthermore, we need to MPI implementers to get over their petty design arguments about whose
ABI is superior to the other's and put users first.

I added [MPI ABI Technical Details](MPI_Needs_ABI_Part_2.md) for people who are convinced this is
a great idea and want to start thinking about what a good ABI might look like.

## Acknowledgements

Thanks to Gonzalo Brito and Jim Dinan for an inspiring discussion on Slack.

## Disclaimer and license

The opinions expressed in this post are exclusively the author's and not those of his
current and past co-workers, co-authors, friends or family members.

(c) Copyright Jeff Hammond, 2021. No reuse permitted except by permission from the author.
