# Fortran's Missing Parallelism

## Summary

Starting in Fortran 2008, Fortran supports two forms of parallelism:
  1. `DO CONCURRENT`, which supports loop-level data parallelism.
  2. coarrays, which is form of [PGAS](https://en.wikipedia.org/wiki/Partitioned_global_address_space).

This document will describe a third form of parallelism and argue that it should be supported by the Fortran language.
The third form of parallelism is shared-memory task parallelism, which supports a range of use cases not easily covered by 1 and 2.

## Background Reading

The reader may wish to consult the following for additional context on this topic:
  * _Patterns for Parallel Programming_ by Timothy G. Mattson, Beverly Sanders and Berna Massingill
  * _OpenMP	Tasking Explained_ by Ruud	van	der	Pas ([Slides](https://openmp.org/wp-content/uploads/sc13.tasking.ruud.pdf))
  * _The Problem with Threads_ by Edward A. Lee ([Paper](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2006/EECS-2006-1.pdf))
  * _Task Parallelism By Example_ from the Chapel Project ([Slides](https://chapel-lang.org/tutorials/SC14/SC14-4-Chapel-TaskPar.pdf))

## Motivating Example
