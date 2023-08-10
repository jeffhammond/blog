# Will we ever need 128-bit offsets?

One of the challenges that has come up in the course of designing the MPI standard ABI is how to define the 
MPI integer types.  For reference, these are:
 - `MPI_Aint` (address integer, but sometimes gets used in other ways)
 - `MPI_Offset` (file offset integer)
 - `MPI_Count` (large count integer, but also used to hold both of the former)
 - `MPI_Fint` (Fortran integer, i.e. the C type equivalent to Fortran's default `INTEGER`)

It is straightforward to see that `MPI_Aint` should be C `intptr_t`, because this is the
only C type guarenteed to be interconvertible with a pointer (and is signed, since we
can't use unsigned types because those don't exist in Fortran).

Right now, on both 32- and 64-bit platforms (meaning those with 32- or 64-bit addressing, i.e. pointers)
filesystems are usually 64-bits.  The [LFS](https://en.wikipedia.org/wiki/Large-file_support) initiative
was created to allow larger than 2 GiB files on 32-bit platforms.

There have been efforts to define 128-bit filesystems, but this post is going to explain why MPI
does not need to have 128-bit offsets even if the underlying filesystem uses 128-bit offsets.

The limit of a 64-bit offset, or rather a 63-bit offset if we are dealing with signed integers,
is 2^63 = 8 * (1024)^6 = >8 billion gigabytes.  Let's look at what it would take to exceed this
limit, in terms of money, time and energy.

According to https://diskprices.com/, a reasonable quality disk drive costs approximately $10/TB,
so if one bought a filesystem to store exactly one file that requires more than a 63-bit offset,
it's going to cost at least $90M, and that is making very aggressive assumptions about how much
extra gear is required to connect more than a million multi-terabyte drives together such that
they actually work as a filesystem that will hold such a file.


# Disclaimer and license

The opinions expressed in this post are exclusively the author's and not those of his current and past co-workers, co-authors, friends or family members.

(c) Copyright Jeff Hammond, 2023. No reuse permitted except by permission from the author.
