A pattern I often use in MPI applications that is not directly supported by the MPI standard is consensus, meaning "does every rank have the same value for a variable?"  There are a few different ways to do this - this blog will discuss them.

An important property of consensus is that, for it to be true, every pairwise comparison must be true.  If even a single comparison is false, there is no consensus.  This fact can be used to optimize the implementation in some cases.

Let's start with the simplest and probably fastest option for a scalar:
```c
int MPIX_Consensus(int * input_value, int count, MPI_Datatype type, int * logical_result, MPI_Comm comm)
{
  if (!logical_result) return MPI_ERR_ARG;

  /* T is whatever C type corresponds to the MPI datatype, the implementation of which we omit here for simplicity */
  T global_min_value = INT_MAX;

  int rc = MPI_Allreduce(&input_value, &global_min_value, 1, type, MPI_MIN, comm);
  if (rc != MPI_SUCCESS) return rc;

  *logical_result = (input_value == global_min_value);
  return MPI_SUCCESS;
}
```
This implementation can be done with `MPI_MAX` just as easily.  The performance is ideal for scalar datatypes because the logical result of any comparison has the same communication cost as the datatype used in the reduction (I am not aware of a network where 1 bit is cheaper to move than the 16 bytes in the largest real scalar MPI supports).

The above code works for integer and real floating-point types supported by MPI, but it doesn't support complex numbers.  For those, one would just treat a scalar as two real numbers and the comparison is the same.  The implementation of this is left as an exercise for the reader.

The other issue with this code is that `NaN` equality comparisons always return false, even for `(NaN==NaN)`, which might be counterintuitive for some users, but I can't think of a use case for knowing that all ranks hold `NaN`.

What happens for non-scalar types?  Let's say we have a vector of configuration settings for an application that we want to validate is consistent across the job - should we do a min/max on the vector?  That certainly works, but it's no longer optimal, because the information we need to exchange is one bit, while the vector is presumably much larger.

The optimization for the vector (or any multi-element datatype) is rather simple and relies on the above property of consensus.  We simply do a pairwise comparison between all nearest neighbors and then allreduce the results.

The following code implements this for arbitrary datatypes, assuming bit-wise comparisons are effective for consensus determiniation.  It optimizes for common cases like contiguous and "fits into 4KiB" but supports the completely arbitrary case.  It does not support large counts but this code is easy to extend for that purpose if one has a use case.
```c
#include <mpi.h>
#include <limits.h>
#include <string.h>

enum {
    MPIX_CONSENSUS_STACK_BYTES = 4096,
    MPIX_CONSENSUS_PAYLOAD_TAG = 17422
};

int MPIX_Consensus(void* input, int count, MPI_Datatype datatype,
                   int* result, MPI_Comm comm) {
    int rc = MPI_SUCCESS;
    unsigned char packed_stack[MPIX_CONSENSUS_STACK_BYTES];
    unsigned char peer_stack[MPIX_CONSENSUS_STACK_BYTES];
    unsigned char* packed_heap = NULL;
    unsigned char* peer_heap = NULL;

    if (!result) {
        rc = MPI_ERR_ARG;
        goto fn_fail;
    }
    *result = 0;
    if (count < 0) {
        rc = MPI_ERR_COUNT;
        goto fn_fail;
    }

    int rank = 0, size = 0;
    rc = MPI_Comm_rank(comm, &rank);
    if (rc != MPI_SUCCESS) goto fn_fail;
    rc = MPI_Comm_size(comm, &size);
    if (rc != MPI_SUCCESS) goto fn_fail;

    if (size == 1) {
        *result = 1;
        goto fn_exit;
    }

    int type_size = 0;
    rc = MPI_Type_size(datatype, &type_size);
    if (rc != MPI_SUCCESS) goto fn_fail;

    /* this only happens if type_size = MPI_UNDEFINED, which means we have a large-count issue */
    if (type_size < 0) {
        rc = MPI_ERR_TYPE;
        goto fn_fail;
    }

    /* while the empty set is unique, we don't want to confuse users
       who don't understand this, so empty inputs are erroneous. */
    if (count == 0 || type_size == 0) {
        rc = MPI_ERR_ARG;
        goto fn_fail;
    }

    int packed_len = count * type_size;

    MPI_Aint lb = 0, extent = 0;
    rc = MPI_Type_get_extent(datatype, &lb, &extent);
    if (rc != MPI_SUCCESS) goto fn_fail;
    (void)lb;

    MPI_Aint true_lb = 0, true_extent = 0;
    rc = MPI_Type_get_true_extent(datatype, &true_lb, &true_extent);
    if (rc != MPI_SUCCESS) goto fn_fail;

    /* true_extent == type_size means one datatype instance has no holes internally.
       count == 1 || extent == type_size means either there is only one instance,
                                         so repetition stride does not matter,
                                         or repeated instances are packed back-to-back with no gaps/overlap. */
    const int dense = (true_extent == (MPI_Aint)type_size &&
                       (count == 1 || extent == (MPI_Aint)type_size));

    const unsigned char* send_bytes = NULL;
    if (dense) {
        send_bytes = (const unsigned char*)input + true_lb;
    } else {
        int pack_upper = 0;
        rc = MPI_Pack_size(count, datatype, comm, &pack_upper);
        if (rc != MPI_SUCCESS) goto fn_fail;
        unsigned char* packed_tmp = packed_stack;
        if (pack_upper > MPIX_CONSENSUS_STACK_BYTES) {
            void* base = NULL;
            rc = MPI_Alloc_mem((MPI_Aint)pack_upper, MPI_INFO_NULL, &base);
            if (rc != MPI_SUCCESS) goto fn_fail;
            packed_heap = (unsigned char*)base;
            packed_tmp = packed_heap;
        }
        int position = 0;
        rc = MPI_Pack(input, count, datatype, packed_tmp, pack_upper,
                      &position, comm);
        if (rc != MPI_SUCCESS) goto fn_fail;
        packed_len = position;
        send_bytes = packed_tmp;
    }

    const int left = (rank - 1 + size) % size;
    const int right = (rank + 1) % size;
    unsigned char* peer = peer_stack;
    if (packed_len > MPIX_CONSENSUS_STACK_BYTES) {
        void* base = NULL;
        rc = MPI_Alloc_mem((MPI_Aint)packed_len, MPI_INFO_NULL, &base);
        if (rc != MPI_SUCCESS) goto fn_fail;
        peer_heap = (unsigned char*)base;
        peer = peer_heap;
    }

    rc = MPI_Sendrecv(send_bytes, packed_len, MPI_BYTE, right,
                      MPIX_CONSENSUS_PAYLOAD_TAG,
                      peer, packed_len, MPI_BYTE, left,
                      MPIX_CONSENSUS_PAYLOAD_TAG,
                      comm, MPI_STATUS_IGNORE);
    if (rc != MPI_SUCCESS) goto fn_fail;

    int local_ok = (memcmp(send_bytes, peer, (size_t)packed_len) == 0) ? 1 : 0;
    int global_ok = 0;
    rc = MPI_Allreduce(&local_ok, &global_ok, 1, MPI_INT, MPI_MIN, comm);
    if (rc != MPI_SUCCESS) goto fn_fail;
    *result = global_ok ? 1 : 0;

fn_exit:
    if (peer_heap) (void)MPI_Free_mem(peer_heap);
    if (packed_heap) (void)MPI_Free_mem(packed_heap);
    return rc;

fn_fail:
    goto fn_exit;
}
```

Bit-wise comparison using `memcpy` works just fine for integers and strings, but may not always work for floating-point types.  Unfortunately, in the case of arbitrary datatypes, it's rather complicated to walk through every element and do a floating-point comparison using `fabs(in-out)<tolerance` for every scalar, so we omit that.

Do you find yourself writing MPI consensus in your code regularly?  How do you do it?  If your implementation is better than mine, please create an issue and tell me about it.
