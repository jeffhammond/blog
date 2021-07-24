# MPI ABI Technical Details

This is a follow-up to [It's past time for MPI to have a standard ABI](MPI_Needs_ABI.md),
which includes more technical details about how MPI ABIs work.

As noted in the first article, the first step in solving a problem is admitting that there
is one, so one should not look at this post unless one has already committed to solving
the problem.

## Overview of MPI ABIs

There are multiple aspects to an MPI ABI.  Here are a few:

- The `MPI_Status` object.  This is an object with transparent members, and MPI requires it to have specific fields.
- Opaque objects, including `MPI_Comm`, `MPI_Datatype`, `MPI_Win`, etc.
  As these are opaque, implementations can define them to be anything.
  
### The `MPI_Status` object

Let's look at three different implementations of the `MPI_Status` object:

#### New MPICH

This is the status object after [this commit](https://github.com/pmodels/mpich/commit/4b516e886aa3aa51379e0c3806c911c9333c2cc3),
which made MPICH consistent with Intel MPI, in order to establish the [MPICH ABI initiative](https://www.mpich.org/abi/).
This meant that applications and libraries compiled against Intel MPI could be run using many implementations.

```c
typedef struct MPI_Status {
    int count_lo;
    int count_hi_and_cancelled;
    int MPI_SOURCE;
    int MPI_TAG;
    int MPI_ERROR;
} MPI_Status;
```

#### Old MPICH

Prior to being consistent with Intel MPI, MPICH had the following status object.

```c
// dnl    EXTRA_STATUS_DECL     - Any extra declarations that the device
// dnl                            needs added to the definition of MPI_Status.
...
typedef struct MPI_Status {
    int MPI_SOURCE;
    int MPI_TAG;
    int MPI_ERROR;
    MPI_Count count;
    int cancelled;
    int abi_slush_fund[2];
    @EXTRA_STATUS_DECL@
} MPI_Status;
```

#### Open-MPI

This is from Open-MPI as of [65bb9e6](https://github.com/open-mpi/ompi/blob/65bb9e6b4cffd1cafa23f73b2faf7817c5323ab8/ompi/include/mpi.h.in).
I have not attempted to track the history of the Open-MPI status object.

```c
typedef struct ompi_status_public_t MPI_Status;
...
struct ompi_status_public_t {
    /* These fields are publicly defined in the MPI specification.
       User applications may freely read from these fields. */
    int MPI_SOURCE;
    int MPI_TAG;
    int MPI_ERROR;
    /* The following two fields are internal to the Open MPI
       implementation and should not be accessed by MPI applications.
       They are subject to change at any time.  These are not the
       droids you're looking for. */
    int _cancelled;
    size_t _ucount;
};
typedef struct ompi_status_public_t ompi_status_public_t;
```

#### Analysis

