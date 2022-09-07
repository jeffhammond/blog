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
  
[MPI-4](https://www.mpi-forum.org/docs/mpi-4.0/mpi40-report.pdf)
imposes the following constraints on opaque objects:

> All named constants, with the exceptions noted below for Fortran, can be used in
> initialization expressions or assignments, but not necessarily in array declarations or as
> labels in C `switch` or Fortran `select`/`case` statements. This implies named constants
> to be link-time but not necessarily compile-time constants. The named constants listed
> below are required to be compile-time constants in both C and Fortran. These constants
> do not change values during execution. Opaque objects accessed by constant handles are
> defined and do not change value between MPI initialization (MPI_INIT) and MPI completion
> (MPI_FINALIZE). The handles themselves are constants and can be also used in initialization
> expressions or assignments

We will see below that MPICH has elected to provide compile-time constants, even though
they are not required.  This allows the implementation source code to do some things efficiently,
although portable applications cannot rely on this behavior.

## The `MPI_Status` object

Let's look at three different implementations of the `MPI_Status` object:

### New MPICH

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

### Old MPICH

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

### Open-MPI

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

The wi4mpi ABI for the status object is the same as Open-MPI's:
```c
struct CCC_mpi_status_struct {
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
typedef struct CCC_mpi_status_struct MPI_Status;
```

### Analysis

We see here that all variants have the required fields, `MPI_SOURCE`, `MPI_TAG` and `MPI_ERROR`,
and the old MPICH ABI matched the Open-MPI ABI in having both a dedicated `int` field for the cancelled
state plus a count field that supports at least 63b values.

Apparently, the Intel MPI team decided to save 32 bits of space in their status object and distribute
63 bits of count and 1 bit of cancelled boolean across two `int` fields, plus they eliminated the ABI
slush fund that would have allowed MPICH to adapt to future changes in the MPI standard that would
have required new fields in the status object.

There isn't anything wrong with the Intel MPI ABI (aka new MPICH ABI).
Testing the cancelled field involves testing a single bit rather than a 32b field,
but since very few MPI programs cancel receives (and cancelling sends has been deprecated),
the relative costs of these does not matter at all.
The needs of the request object seem to be relatively stable over time, and in hindsight it seems
like the ABI slush might have been unnecessarily conservative.

In any case, it seems like either the new MPICH or Open-MPI ABI would be fine for standardization.
Some will argue that Open-MPI wastes 31 bits, but perhaps those bits can be used for other things
in some implementations.  As this state isn't user-visible it doesn't matter how implementations use
it, as long as they use it consistently.

If I was going to standardize an ABI for the status object, I'd put the public fields first and use
24 bytes total, which is sufficient for what both of the major ABIs do right now.
I'm not aware of any architectural advantage of the 20 bytes Intel MPI uses.
One could be conservative and round up to 32 bytes, which has some architectural advantages,
since many modern CPUs have 256-bit data paths.
```c
typedef struct MPI_Status {
    int MPI_SOURCE;
    int MPI_TAG;
    int MPI_ERROR;
    int extra[3];
} MPI_Status;
```

## MPI datatypes

MPI datatypes are opaque objects, which means implementations can represent them however they want.
Here we see different philosophies in MPICH and Open-MPI.

### MPICH

MPICH's [mpi.h](https://github.com/pmodels/mpich/blob/main/src/include/mpi.h.in) contains the following:
```c
typedef int MPI_Datatype;                                                                
#define MPI_CHAR           ((MPI_Datatype)0x4c000101)                                    
#define MPI_SIGNED_CHAR    ((MPI_Datatype)0x4c000118)                                    
#define MPI_UNSIGNED_CHAR  ((MPI_Datatype)0x4c000102)                                    
#define MPI_BYTE           ((MPI_Datatype)0x4c00010d)                                    
#define MPI_WCHAR          ((MPI_Datatype)0x4c00040e)                                    
#define MPI_SHORT          ((MPI_Datatype)0x4c000203)                                    
#define MPI_UNSIGNED_SHORT ((MPI_Datatype)0x4c000204)                                    
#define MPI_INT            ((MPI_Datatype)0x4c000405)                                    
#define MPI_UNSIGNED       ((MPI_Datatype)0x4c000406)                                    
#define MPI_LONG           ((MPI_Datatype)0x4c000807)                                    
#define MPI_UNSIGNED_LONG  ((MPI_Datatype)0x4c000808)                                    
#define MPI_FLOAT          ((MPI_Datatype)0x4c00040a)                                    
#define MPI_DOUBLE         ((MPI_Datatype)0x4c00080b)                                    
#define MPI_LONG_DOUBLE    ((MPI_Datatype)0x4c00080c)                                    
#define MPI_LONG_LONG_INT  ((MPI_Datatype)0x4c000809)  
```
These values are obviously special, but how?
One feature is that they encode the size of built-in datatypes
such that these can be queried trivially with this macro:
```c
#define MPIR_Datatype_get_basic_size(a) (((a)&0x0000ff00)>>8)
```
There are a bunch of other macros that take advantage of the
hidden structure of the `MPI_Datatype` handle that the reader
can study in [mpir_datatype.h](https://github.com/pmodels/mpich/blob/main/src/include/mpir_datatype.h)

### Open-MPI

Open-MPI's [mpi.h](https://github.com/open-mpi/ompi/blob/master/ompi/include/mpi.h.in)
defines the datatype handle to be a pointer, which means that built-in datatypes
cannot be compile-time constants, although they are link-time constants, which ends
up being similarly efficient with modern toolchains, for most purposes.
```c
typedef struct ompi_datatype_t *MPI_Datatype;
...
/* C datatypes */
#define MPI_DATATYPE_NULL OMPI_PREDEFINED_GLOBAL(MPI_Datatype, ompi_mpi_datatype_null)   
#define MPI_BYTE OMPI_PREDEFINED_GLOBAL(MPI_Datatype, ompi_mpi_byte)                     
#define MPI_PACKED OMPI_PREDEFINED_GLOBAL(MPI_Datatype, ompi_mpi_packed)                 
#define MPI_CHAR OMPI_PREDEFINED_GLOBAL(MPI_Datatype, ompi_mpi_char)                     
#define MPI_SHORT OMPI_PREDEFINED_GLOBAL(MPI_Datatype, ompi_mpi_short)                   
#define MPI_INT OMPI_PREDEFINED_GLOBAL(MPI_Datatype, ompi_mpi_int)                       
#define MPI_LONG OMPI_PREDEFINED_GLOBAL(MPI_Datatype, ompi_mpi_long)                     
#define MPI_FLOAT OMPI_PREDEFINED_GLOBAL(MPI_Datatype, ompi_mpi_float)                   
#define MPI_DOUBLE OMPI_PREDEFINED_GLOBAL(MPI_Datatype, ompi_mpi_double) 
...
```

In contrast to MPICH, Open-MPI has to lookup the size of the datatype
inside of a [352-byte `struct`](https://github.com/open-mpi/ompi/blob/master/opal/datatype/opal_datatype.h#L145),
which is not a concerning overhead
since the type of MPI code that will notice such an overhead is going
to pass the same datatype over and over, in which case, the CPU is going
to cache and correctly branch-predict the lookup and associated usage
every time.
```
static inline int32_t opal_datatype_type_size(const opal_datatype_t *pData, size_t *size)
{
    *size = pData->size;
    return 0;
}
```

### wi4mpi

wi4mpi defines all the opaque handles to be `size_t`, which ensures they are at
least as big as MPICH's `int` handles and Open-MPI's pointer handles,
although I don't know if this is the reason.
```
typedef size_t MPI_Comm;
typedef size_t MPI_Datatype;
typedef size_t MPI_Errhandler;
typedef size_t MPI_File;
typedef size_t MPI_Group;
typedef size_t MPI_Info;
typedef size_t MPI_Op;
typedef size_t MPI_Request;
typedef size_t MPI_Message;
typedef size_t MPI_Win;
```

wi4mpi defines the built-in datatypes to be sequential integers,
which means they are not attempting to encode useful information
the way MPICH's do, although they are compile-time constants,
unlike Open-MPI's.
I do not know if compile-time constancy is important in wi4mpi.
```c
/* C datatypes */
#define MPI_DATATYPE_NULL 0
#define MPI_BYTE 1
#define MPI_PACKED 2
#define MPI_CHAR 3
#define MPI_SHORT 4
#define MPI_INT 5
#define MPI_LONG 6
#define MPI_FLOAT 7
#define MPI_DOUBLE 8
```

### Analysis

There are advantages to both approaches.  MPICH optimizes for the common case of built-in types,
and does a lookup for others, while Open-MPI always does a pointer lookup, but then has what
it needs in both cases.

The other advantage of the MPI approach is with Fortran.  In Fortran, handles are `INTEGER`,
or handles are a type with a single member that is an `INTEGER`.  MPICH conversions between
C and Fortran are trivial (ignoring the case where Fortran `INTEGER` is larger than C `int`,
which is a terrible idea anyways).  Open-MPI has to maintain a lookup table to go between
C and Fortran.

The easy solution here is to use `intptr_t` for handles and change the Fortran 2008 handle
definition to use `intptr_t` for `MPI_VAL`.  This allows for trivial conversions between
C and Fortran 2008, for MPICH to continue use magic values for built-ins, and for Open-MPI
to use pointers.  Open-MPI will still need a lookup table for the older Fortran interfaces,
but one of these should be [deprecated](https://github.com/mpi-forum/mpi-issues/issues/561) 
in MPI-5 anyways.

## Disclaimer and license

The opinions expressed in this post are exclusively the author's and not those of his current and past co-workers, co-authors, friends or family members.

(c) Copyright Jeff Hammond, 2021. No reuse permitted except by permission from the author.
