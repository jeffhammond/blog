# The Andrew Jones Challenge (Pentadecathlon)

From https://lnkd.in/p/dmedpE8g

Think you’re a real #supercomputing expert?

Time for my annual pre-SC #HPC community fun game post. How will you score?

How many of the following could you *credibly* talk about on a panel at #SC26?

1. Why does an HPC cluster have separate login nodes and compute nodes?

The requirements are different.
Login nodes are for building software (compiling), small-scale data analysis, etc.
These processes tend to do lots of fine-grain I/O and spawn dozens of processes and threads, neither of which resemble a traditional HPC workload.
In extreme cases, compute nodes run a different OS or architecture, one that is not suitable for an interactive Linux experience, the most obvious example of which were the IBM Blue Gene systems, which I spend many years of my life supporting.

2. Why was transition to multi-core seen as such a disruptive transition at the time?

Frankly, it wasn't, at least among application developers.
I was there when IBM Power4 came out and cut my teeth on an Itanium2 dual-core system, neither of which were disruptive.
Computer scientists made a lot of noise about multicore programming models, but they were not necessary until many years later, because MPI worked (and works) just fine with one process per core.
It was not core counts but the desire to not scale DRAM capacity with core count that drove the adoption of OpenMP and related mutlicore programming models as CPUs got more than 32 cores per node.

3. Why PUE is limited as a metric for environmentally responsible supercomputing?

PUE is about how well a data center uses electricity, but it says nothing about the performance efficiency of a system.
If you have a data center that has a PUE of 1.0 (perfect) that delivers 100 GF/W and a data center than has a PUE of 1.5 (terrible) that delivers 1000 GF/W, the latter is delivering _significantly_ more performance per unit of power.
Useful work per power is the right measure for environmentally responsible supercomputing.
Unfortunately, workload efficiency is very complicated and hard to measure.
Nonetheless, PUE is a great goal for data center operators because, given a fixed performance efficiency, we want the best PUE possible.

5. What are the pros and cons of pure MPI vs MPI+X parallel models?

In the context of GPUs, the question is MPI+X versus NCCL+X, and GPUs are normative now, so this question is no longer particularly interesting unless we limit the scope to CPU-only systems.
As noted in answer 2, pure MPI works just fine at one process per core in many cases, but applications that do not use interprocess shared memory effectively may struggle with memory capacity requirements or unnecessary intranode data movement if they treat a core as a node.
As has been noted in the past, e.g. by Bill Gropp, there are design challenges within MPI+X due to the difficulty of composing MPI with threaded or tasking models, both due to low-quality implementations of `MPI_THREAD_MULTIPLE` and the inept forward progress rules of OpenMP tasks (https://github.com/mpi-forum/mpi-issues/issues/75).

6. What are some other examples of Amdahl’s law effects in HPC other than on parallelisation of compute?
7. What are good and bad practices in acceptance testing for supercomputers?
8. Why and how should #Top500 be used in procurement contexts?

The Top500 is a list of supercomputers ranked based on their performance on the LINPACK benchmark, which is essentially a wrapper around gigantic DGEMM calls, so it measures two things: the aggregate FP64 throughput of a node and the MTBF of the system, although the latter only implicitly, because a system that crashes every 15 minutes can't scale to a big enough matrix dimension to saturate FP64 throughput.
No procurement should ever prioritize the LINPACK rating of a system or the rank on the list.
Doing so forces system architects to make design choices that are bad for scientific capability.
No HPC workload, whether simulation, data analysis or AI, looks anything like the LU factorization of a 73 billion by 73 billion matrix with IEEE FP64, so designing for this forces the reallocation of silicon and other resources from things would be useful for real workload purposes.

9. What are 5 often forgotten costs in Total Cost of Ownership (TCO) models for supercomputers?
10. What have been top 1 good and 1 bad impact of #AI infrastructure in the traditional HPC community and why?
11. Compare the days when we had Cray, SGI, IBM, Bull, etc all competing for HPC deals with today’s era - what’s different, what’s the same, etc?
12. What are I/O requirements so hard to define for HPC systems?
13. Is “private #cloud” a real thing or just good marketing?
14. Why is it so hard for new chip ideas/products/suppliers to gain market traction?
15. What is the most important training HPC users need and why?
16. What are the top 3 ways HPC sysadmin is different to general IT?

Your Scores Rated:

15 : liar (did you see the caveat of “credibly”??)
10-14 : Fire - either unusually battle hardened across HPC aspects, or spectacular HPC BS gamer, or are an AI model
5-9 : Earth - perfect panel member, covers a range of topics well, but doesn’t pretend to know everything!
0-4 : Water - could be in marketing? (😜) or specialist who knows one area really deeply, or what our HPC community always needs ie fresh talent with new ideas unencumbered by history?

How did you score?

PS - I still have two panel places to fill at various SC26 events, so I might come calling!
