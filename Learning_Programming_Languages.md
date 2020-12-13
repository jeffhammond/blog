# Summary

Talking to computers is different than talking to humans for a bunch of reasons, but I think there are some similarities.  I recently watched a video by professional language teachers about gaining language proficiency and apply those ideas to my own experiences with programming languages.

# Context
 
Professor [Jeffery Brown](https://www.linkedin.com/in/jeffery-brown-a14b8430/) has a [video](https://youtu.be/illApgaLgGA) on how to gain language proficiency.  He puts a lot of emphasis on the difference between the words "acquire" and "learn", which I dislike.  What he's really saying is, natural/organic/immersive language education is superior to formal, grammar-oriented language education.  I agree with this, but am going to use the word "learn" and just focus on the right way to learn, without trying to associate it with a new term.

Some of the key ideas in Professor Brown's video are:

  1. Babies learn to communicate verbally without knowing how to read and with total disregard for language rules and grammar.
  2. Comprehensible language input is the key to learning how language works.
  3. When beginning to learn a language, focus on listening.  Listen to someone who is fluent speak.  You should look for a "language parent" that serves a similar role to the parent of a baby learning a language.
  4. Only study grammar when you are fluent in the language.
  
# My Experience

My first experience becoming proficient in a programming language when I was an intern at PNNL in 2006 ([details](https://github.com/jeffhammond/blog/blob/main/Career_Trajectory.md#doe-csgf-and-pnnl)), when I started working on NWChem, which is written primarily in old-school Fortran (I will define this later).  At the time, I had never written any Fortran and I was unable to modify existing programs, which represents 0% fluency.  I was familiar with Fortran-style loops from Matlab programming, but Matlab is much simpler than Fortran for a bunch of reasons.



# Appendix

This is unnecessary detail but if you are the type of person who reads my blog posts, particularly ones about computer language acquisition, you might be the type of person who cares about unnecessary details.

## What does "old-school Fortran" mean?

TL;DR old-school Fortran means:

  1. Fixed-source form with 72 columns.
  2. Extensive use of common blocks.
  3. No use of modules, interfaces, polymorphism, user-defined types and other features introduced with Fortran 90/95.
  4. No use of Fortran dynamic memory allocation.  Memory management is done with C and passed using sketchy methods.
  5. No use of any Fortran feature that is not implemented in every relevant compiler.

Steve Lionel, aka "Dr. Fortran" wrote a [blog post](https://stevelionel.com/drfortran/2020/05/16/doctor-fortran-in-military-strength/) that elaborates on a comment I made about the non-existence of actual Fortran 77 codes, which is something I picked up from Jeff Squyres in the MPI Forum during our many discussions of the MPI Fortran bindings (interfaces).

In the case of NWChem, the aversion to Fortran memory management is not just because that feature was added in Fortran 90.  The distributed memory programming model of NWChem, Global Arrays, relies heavily upon interprocess shared memory and one-sided communication, both of which require special memory allocation procedures that are done in C.  To make these efficient, NWChem allocates a large slab at program start and suballocates from that using a stack allocator (explicit push+pop).  This enforces a programmer discipline and makes memory leaks less likely (failure to pop in reverse order of push generates a runtime error).

(c) Copyright Jeff Hammond, 2020. No reuse permitted except by permission from the author.
