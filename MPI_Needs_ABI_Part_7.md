# MPI ABI Status Report

As of December 2024, the MPI ABI proposals, one for C support
and one for partial Fortran support, have passed the
[first vote](https://www.mpi-forum.org/meetings/2024/12/votes)
by the MPI Forum.

There will be a second vote followed by a vote to approve the entire
release of the standard containing the ABI, but it is unlikely
that future votes will fail, given the lack of substantial objections
to the current content of the proposal.

As noted in the previous blog
([part 6](https://github.com/jeffhammond/blog/blob/main/MPI_Needs_ABI_Part_6.md))
there is still work left to be done to solve the Fortran problem.
In order to get these parts right, we need to wait until the first phase
of the ABI is done and then implement standalone Fortran bindings on
top of it, as [Vapaa](https://github.com/jeffhammond/vapaa/) is doing.
So far, Vapaa is focused only on `MPI_F08` support, but we will also
prototype the legacy API to verify that nothing is lost if the
MPI Fortran API is implemented separately from the MPI C API.
