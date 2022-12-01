# Dealing with Imperfect Fortran Compilers, Part 1

TL;DR You can build your Fortran application with two different compilers to get
the best of both worlds when it comes to coarrays and GPU parallelism, for example.
This is not the easiest thing to do, but it's better than the bucket of tears
you're living with right now.

This post describes the motivation.  [Part 2](https://github.com/jeffhammond/blog/blob/main/Dealing_with_imperfect_Fortran_compilers_2.md) has the technical details.

## The Current State of Fortran Compilers

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
  2. Pragmatists, who write to the widely supported common subset of Fortran language support, 
     which can be approximated by Fortran 2003, and definitely does not include coarrays.
     These folks also don't care about coarrays because MPI is better and 
     has been universally available since before the `gfortran` project began.
  3. Purists, who insist that, if WG5 can imagine it, then it should be usable, 
     at least within a few years of the ISO ink drying.
     Such users either have very business relationships or are willing to compromise
     on at least one of performance and portability.

In a CPU-only HPC universe, particularly one dominated by x86, most programmers
could live relatively comfortably within one of these categories.
However, we haven't lived in a CPU-only HPC universe since at least 2012,
when ORNL's Titan Cray XK7 ushered in the beginning of the GPU era of HPC.
Furthermore, x86 domination in HPC streadily eroded as numerous ARM-based
alternatives have emerged, ranging from the exotic Fujitsu A64fx processor
to awesome-yet-boring cloud-oriented offerings from Ampere and AWS.

Now, our purists are far less happy than before and likely have at least one of the following grievances:

  1. My system does not support coarays properly or at all.
  2. My system does not support OpenACC, CUDA Fortran, or StdPar (i.e. `DO CONCURRENT` on GPUs).
  3. My system does not support an feature-complete OpenMP 5 GPU compiler.
  4. My system does not support Fortran 2018 features not related to parallelism.
  5. The only good Fortran compiler on my system is not mainstream and not supported by important HPC software.
  6. The only good Fortran compiler I can use has no well-defined support model.

Even the pragmatists are starting to get impatient and would like more of the post-2003 features
than are universally available.

Fortunately, there is a solution to these problems, but it requires a bit of software gymnastics.
On the other hand, if you can actually use most of the features in Fortran 2003+, you're more than
smart enough to deal with the back handspring I'm going to describe next.

## A Brief Digression about Application-Binary Interfaces (ABIs)

None of the aforementioned problems exist in the C world because
- with a small number of reasonable caveats -
C compilers are interoperable, and there's no issue mixing objects
from GCC, Clang and a vendor C compiler based on EDG.
This is because C supports ABI stability on a given platform
and very few users want to mix C standard libraries, which
is the one thing one cannot do.
Similarly, in C++, one can mix GCC and Clang or a EDG-based vendor compiler
as long as they use the same STL.

Unfortunately, Fortran offers nothing in the way of ABI stability.
Each Fortran compiler can have its own convention for passing
`CHARACTER*(*)` strings and arrays, with the latter often including
a non-standard descriptor format, which may not be well-documented.
Finally, I/O statements and all the intrinsics are a based on
a compiler-specific runtime library, which is tighly bound
to the aforementioned calling conventions.

However, starting in Fortran 2003, there has been standardized
interoperability between Fortran and C, and this feature set
became almost magical in Fortran 2018, with the introduction
of `CFI_cdesc_t` and other features.

Extended C-Fortran interoperability (CFI) in Fortran 2018 is the magic
that is going to allow us to break free from the limitations
of a single imperfect compiler, to realize the features provided
by TWO imperfect compilers, so long as there are clean boundaries
between the Fortran code called by each.

## The Luddites Might be Right

Amusingly, the luddites who stopped reading already have been able
to rely on the almost-ABI stability of legacy Fortran
(which is erroneously called "Fortran 77" by many,
but is more accurately Fortran ~85).
Because `integer A(*)` behaves like C99's `int a[restrict]`,
and the infrequent use of proper strings in Fortran,
Fortran libraries like the BLAS and LAPACK are mostly compiler-agnostic.
For example, one does not need to handle the string length in
`DGEMM` because exactly 1 character is read per argument.
There is an issue with complex number return values, 
but I'm going to ignore that one.  Not today, Satan.

So basically, if you are willing to write Fortran with REO Speedwagon
playing in the background, and your idea of a complicated datatype
is `DOUBLE PRECISION A(LDA,*)` then you don't need to know what
comes next.

## Getting to the Point

You've waited long enough.
The trick we are going to use to make all of our Fortran dreams come true
is to split Fortran applications into pieces that can be compiled with 
different Fortran compilers, and to connect them using CFI features.

Pictorially, this can be described as follows [2]:

![72lgcj](https://user-images.githubusercontent.com/406118/204720665-04588b4e-36d1-40d5-bf61-32e9928bc94a.jpg)

The overall effect of this is as if we turn 1 application into
1 application and N libraries, where the libraries have C linkage.
All of this is possible in a strictly standard-compliant way
as of Fortran 2018, although it is a bit tricky to implement,
and there are some limitations.

One of the more obvious applications of this technique is to build
a program that uses coarrays for distributed-memory parallelism
and `DO CONCURRENT` with GPU parallelism.
Currently, this is not possible on any interesting platform,
since the NVIDIA HPC Fortran compiler does not support coarrays
and neither GCC or Cray has GPU support for `DO CONCURRENT`
right now.  Intel Fortran supports coarrays and recently released
GPU support for `DO CONCURRENT`, but Intel has not shipped a
proper HPC GPU, hence the "interesting platform" caveat.

A less exciting application of this method is to build libraries
that are implemented using modern Fortran that are usable from
any language that supports C calling conventions / linkage.
For example, one could rewrite the BLAS and LAPACK without
disrupting user experience for those accustomed to the legacy
Fortran APIs, or event ship an implementation of CBLAS that
contains zero C code.

The technical details of this are described in a [follow-up post](https://github.com/jeffhammond/blog/blob/main/Dealing_with_imperfect_Fortran_compilers_2.md).

## References

  1. [Doctor Fortran in "Military Strength"](https://stevelionel.com/drfortran/2020/05/16/doctor-fortran-in-military-strength/)
  2. [Aquarium Leaking Slap Meme Generator](https://imgflip.com/memegenerator/194158970/Aquarium-Leaking-Slap)
  3. Intel recently released a compiler that has `DO CONCURRENT` GPU support but it has a few issues that need to be addressed.

## Disclaimer and license

The opinions expressed in this post are exclusively the author's 
and not those of his current and past co-workers, co-authors, friends or family members.

(c) Copyright Jeff Hammond, 2022. No reuse permitted except by permission from the author.
