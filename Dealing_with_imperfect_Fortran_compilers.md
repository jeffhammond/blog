# Dealing with Imperfect Fortran Compilers

Most programmers are familiar with imperfect software.
There are few, if any, nontrivial bug-free programs.
However, users of Fortran are likely more familiar with this topic than the average programmer.
It was not too long ago that there was no free compiler that
supported the latest Fortran standard, or even a decent fraction of it.
For example, when I started programming in Fortran in 2006,
the free compilers that existed were g77 and g95, neither
of which resembled a real Fortran 2003 compiler.
Obviously, better Fortran compilers have always been available,
but not necessarily at the right price.
For example, Cray Fortran is an excellent compiler, and the compiler
is free with the purchase of a Cray system, but the minimum
purchasable unit of Cray hardware has historically been a
rack, which costs around a million dollars.
Reportedly, TITECH bought a single Cray XK7 system
so they could use Cray's Fortran OpenACC compiler on
one of the TSUBAME systems.

Regardless of the frustrating history of Fortran compilers,
the situation in 2022 is a lot better.
GCC Fortran covers a large portion of the latest Fortran standard (2018),
Intel's Fortran compiler and NVIDIA's NVHPC (nee PGI) 
Fortran compilers are freely available (without purchase of hardware),
and the LLVM Fortran effort has made significant progress.
The first-generation LLVM Fortran, Flang, was based on PGI's Fortran
compiler and is the basis for Fortran products from AMD and ARM,
although neither can claim to support the majority of Fortran 2008.
The new LLVM Fortran project, F18, is expected to support all the latest
standard features when it reaches production quality.

One area where Fortran compiler support is quite poor is the distributed
memory model known as coarrays.
Cray has a great implementation of coarrays but it's tied to their
high-performance networking hardware.
Intel and GCC Fortran both support coarrays, but one of these
compilers is very good and distributed-memory performance and
the other is very good at shared-memory performance
(which is which is left as an exercise for the reader)
so HPC users at NCAR, for example, are forced to choose
which half of the HPC performance spectrum matters to them.
Right now, none of AMD, ARM, LLVM, or NVIDIA support coarrays
at all, although one hopes that future progress in LLVM F18
will include coarrays and percolate into vendor derivatives.

Fortran programmers fall into a few different categories:

  1. Luddites who haven't left the 20th century,
     don't know that the Fortran language has changed since the mid-1980s [1],
     and whose code compiles everywhere this side of a punchcard reader.
  3. Pragmatists, who write to the widely supported common subset of Fortran language support, 
     which can be approximated by Fortran 2003, and definitely does not include coarrays.
     These folks also don't care about coarrays because MPI is better and 
     has been universally available since before the `gfortran` project began.
  4. Purists, who insist that, if WG5 can imagine it, then it should be usable, 
     at least within a few years of the ISO ink drying.
     Such users either have very business relationships or are willing to compromise
     on at least one of performance and portability.



# References

  1. [Doctor Fortran in "Military Strength"](https://stevelionel.com/drfortran/2020/05/16/doctor-fortran-in-military-strength/)

# Disclaimer and license

The opinions expressed in this post are exclusively the author's 
and not those of his current and past co-workers, co-authors, friends or family members.

(c) Copyright Jeff Hammond, 2022. No reuse permitted except by permission from the author.
