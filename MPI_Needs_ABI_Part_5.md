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
MPI file offsets are for a single file, so it is not a question of how large the underlying
filesystem is, but the size and extent of a single MPI file that matters here.

The limit of a 64-bit offset, or rather a 63-bit offset if we are dealing with signed integers,
is 2^63 = 8 * (1024)^6 = >8 billion gigabytes.  Let's look at what it would take to exceed this
limit, in terms of money, time and energy.

# Money

According to https://diskprices.com/, a reasonable quality disk drive costs approximately $10/TB,
so if one bought a filesystem to store exactly one file that requires more than a 63-bit offset,
it's going to cost at least $90M, and that is making very aggressive assumptions about how much
extra gear is required to connect more than a million multi-terabyte drives together such that
they actually work as a filesystem that will hold such a file.

Obviously, as with everything in computing, prices go down over time, until physical limits are
reached.  Based on https://ourworldindata.org/grapher/historical-cost-of-computer-memory-and-storage,
there was a very nice exponential decrease in storage cost between 1990 and 2010, but since then the
exponent has changed and prices have decreased only ~3x in the past 10 years.
Let's assume that trend continues, which means storage costs will go down 10x every 20 years.
That means some time in the 2040s, one might be able to build a filesystem for a single >8 EiB file
that costs around $10M.  This is more than most HPC systems cost today...

The cost problem is much worse once we observe that the $10/TB pricing is for the _cheapest_
large-capacity storage media available, not for the fast media required to satisfy the time
requirements established below.  High-end storage media is at least 3x more expensive than 
7200 RPM drives.  That 3x means we need to add another decade in order to have our exafile
cost anywhere near $10M.

# Time

Right now, the mean time to interrupt (MTTI) on a large supercomputer is less than a day 
and not expected to improve any time soon.  Let's assume that we need to write our >8 EiB file
in less than a day.  That's already pretty unreasonable, but it gives a way to establish some
conservative bounds.  What sort of I/O bandwidth is required to write such a file in a day?
One day is 86,400 seconds.  At an I/O speed of 1 TB/s, we can write 86.4 PB/day.
We would need an aggregate I/O speed of 100 TB/s to write the 8.64 EB/day required to populate
the gigantic file in question.

One current I/O standard is PCIe 5.0, which supports 64 GB/s (unidirectional).
PCIe 6.0 is [expected](https://www.theverge.com/2022/1/12/22879732/pcie-6-0-final-specification-bandwidth-speeds) 
to support twice that, i.e. 128 GB/s, with x16.  It seems we need around 1000 I/O devies
to drive this filesystem, but we will probably use a lot more than 1000 drives
to store the exafile, so the speed limit is the storage media, not the I/O into it.

Right now, state-of-the-art storage media supports approximately 10 GB/s of write
bandwidth.  That bandwidth goes down as an SSD gets full, as it will when writing
the exafile, but let's ignore that.  Right now, the best SSDs max out PCIE with only x4,
and it's likely that only change for the better.  If PCIe doubles a few more times
in the next decade, which is optimistic, then we might expect to be able to write 
at 256 GB/s to the most expensive SSDs in the future.
This means that we might be able to write the exafile in less than a day,
assuming we can build a filesystem with thousands of drives and the interconnect
requires to move the bytes where they need to go.

# Energy

Writing to storage costs approximately 1 nanojoule/bit according to 
[this](http://large.stanford.edu/courses/2018/ph240/jiang2/).
Our exafile requires writing 2^66 bits, or approximately 74 gigajoules.
A watt is defined to be a joule per second.  So we expend 74 gigajoules
in 86400 seconds, which is 854 kW.  That's a lot of power but not
unreasonable for data center operations, where large systems routinely
require many megawatts.

It doesn't look like power is the limit to storing the exafile.

# Conclusion

I am not an expert at these things, but it certainly seems like we have
approximately 30 years before anybody is going to be able afford
to write a file that requires `MPI_Offset` to be more than 63 bits.

Right now, OLCF's [Orion filesystem](https://community.hpe.com/t5/servers-systems-the-right/meet-the-world-s-largest-and-fastest-parallel-file-system/ba-p/7155645)
has a capacity of 690 PB and an aggregate bandwidth of 10 TB/s.
The most aggressive use case for this filesystem is:

> Each of simulations consisted of 2 trillion particles and more than 1,000 steps.
> The data generated by ONE simulation could total a whopping 200 PB,

which one can reasonable assume requires approximately 1000 files of
200 TB each, which is consistent with our assumptions.
In theory, users could insist on using exactly one file, in which
case they are within 40x of the 63-bit limit, but 40x more data
depends on at least 40x more simulation, which is likely three
generations of supercomputers away, or more than a decade away.

# Disclaimer and license

The opinions expressed in this post are exclusively the author's and not those of his current and past co-workers, co-authors, friends or family members.

(c) Copyright Jeff Hammond, 2023. No reuse permitted except by permission from the author.
