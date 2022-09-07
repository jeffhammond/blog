# MPI ABI Part 3: Launchers

This is a follow-up to [It's past time for MPI to have a standard ABI](MPI_Needs_ABI.md)
and [MPI ABI Technical Details](MPI_Needs_ABI_Part_2.md).

## What's a launcher?

A launcher is how one causes MPI programs to start running.
It is one of the least specified aspects of MPI, for various reasons.
In MPI 4.1 11.5 "Portable MPI Process Startup", a syntax for a launcher
named `mpiexec` is suggested, and how ones uses it for SPMD and MPMD cases.
However, even though `mpiexec` is standardized, many users use the command
`mpirun` or some other platform- or implementation-specific launcher.
For example, on machines with [Slurm](https://slurm.schedmd.com/documentation.html),
`srun` is often a recommended command.

Regardless of what command is actually used to launch an MPI parallel job, the
interesting parts from an implementation compatibility perspective are unseen.
Using a variety of system commands, the launcher needs to broadcast the binary 
and its inputs to every compute node, and execute that binary on every node at least
once.  Once all these programs are running, they need to figure out that they need
to connect to each other, no later than in `MPI_Init`.  Standard output needs
to be handles properly, which might involve forwarding to the node on which the job
was launched.  And finally, while no one wants their MPI programs to fail, if
they do, the launcher needs to clean up the mess and make sure there are no
zombie processes or file handles to clog up the system for subsequent users.

One way to do this, which is roughly how MPICH Hydra does things, is
to spawn a proxy on every node that will manage everything within its node.
In this respect, it is a parent that takes its MPI program children outside
and has to clean up after them when they make a mess.  For example, if you
SIGKILL an MPI process, you probably want the whole ensemble to go down,
rather than have N-1 processes running along forever until they deadlock.

## How to not standardize launchers

Last time I looked, there are more launchers than there are MPI ABIs,
so standardizing a launcher is at least as hard as getting everyone to agree
on an ABI.  However, it may not be necessary, so let's try this.

In the case of Slurm or other launchers associated not with MPI
implementations but with resource managers, there is no problem.
If the MPI library is compiled with Slurm support, then it knows how
to wire-up inside of `MPI_Init` based on environment variables that Slurm
defines.  Both Open-MPI and MPICH support all of the major schedulers.

For users who expect to use `mpirun` or `mpiexec`, a hack is to
figure out what launcher the program expects and then invoke it.
In this design, `mpiexec` can be a shell script that calls `strings`
or some other introspection method on the binary and figures out if
it's MPICH or Open-MPI or Intel MPI or MVAPICH2, and then calls
the implementation specific `mpiexec`.  This is not an elegant
method but it probably works for a lot of users, and isn't any worse
than the mess we have right now.

## Disclaimer and license

The opinions expressed in this post are exclusively the author's and not those of his current and past co-workers, co-authors, friends or family members.

(c) Copyright Jeff Hammond, 2021. No reuse permitted except by permission from the author.
