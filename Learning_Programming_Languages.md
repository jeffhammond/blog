# Summary

Talking to computers is different than talking to humans for a bunch of reasons, but I think there are some similarities.  I recently watched a video by professional language teachers about gaining language proficiency and apply those ideas to my own experiences with programming languages.

# Context
 
Professor [Jeffery Brown](https://www.linkedin.com/in/jeffery-brown-a14b8430/) has a [video](https://youtu.be/illApgaLgGA) on how to gain language proficiency.  He puts a lot of emphasis on the difference between the words "acquire" and "learn", which I dislike.  What he's really saying is, natural/organic/immersive language education is superior to formal, grammar-oriented language education.  I agree with this, but I don't know why we can't call it "learning naturally".

Some of the key ideas in Professor Brown's video are:

  1. Babies learn to communicate verbally without knowing how to read and with total disregard for language rules and grammar.
  2. Comprehensible language input is the key to learning how language works.
  3. When beginning to learn a language, focus on listening.  Listen to someone who is fluent speak.  You should look for a "language parent" that serves a similar role to the parent of a baby learning a language.
  4. Only study grammar when you are fluent in the language.
  
Professor Brown espouses the [natural approach](https://en.wikipedia.org/wiki/Natural_approach) of Krashen and Terrell, which is widely used today.  I recognize the methods from my German classes in high school, which would have been a lot more effective if I had not been utterly lazy.
  
# Learning Fortran

My first experience becoming proficient in a programming language when I was an intern at PNNL in 2006 ([details](https://github.com/jeffhammond/blog/blob/main/Career_Trajectory.md#doe-csgf-and-pnnl)), when I started working on NWChem, which is written primarily in old-school Fortran (I will define this later).  At the time, I had never written any Fortran and I was unable to modify existing programs, which represents 0% fluency.  I was familiar with Fortran-style loops from Matlab programming, but Matlab is much simpler than Fortran for a bunch of reasons.

It has been a little over 14 years, but I'm pretty sure the first thing I had to do as an intern was modify https://github.com/nwchemgit/nwchem/blob/master/src/tce/tce_energy.F, which is an 11K-line subroutine.  Back then, it was probably twice as long, but I refactored it for my own sanity after a year or two of experience.  The first thing I remember was trying to compile my modifications and getting an unhelpful error (compiler error messages weren't great in those days).  I asked the only other person in the room at the time, and [he](https://scholar.google.com/citations?user=1w1T9HYAAAAJ&hl=en) said "you need to indent six spaces.  It seemed arbitrary to me, but it worked.  So the first thing I learned about Fortran was: indent six spaces.

During that summer and in the years to follow, I wrote thousands of lines of Fortran.  What I have never done in all my years as a programmer are (1) take a course on Fortran programming or (2) engage in any serious study of Fortran grammar.  While I own at least three books on Fortran, none of them have been even the slighest bit useful to me.  I will admit that I have referenced Fortran documentation on the internet from time to time, especially regarding formatted I/O, the primary methods I used to become proficient in Fortran are:

  1. Reading code.
  2. Writing code and seeing if it (a) compiles and (b) does the thing I want it to do.
  
I recognized that these behaviors are very similar to the language acquisition noted above.  While I was recompiling NWChem with my latest modifications -- a multi-hour process until I understood the build system and header files better -- I would read the rest of the code, and a lot of other code, too.  **The first key point here is that reading code is hugely important but not something I see practiced much.**  Programmers love to point out everything that is wrong with code that already exists and don't seem to see the value in learning from imperfect code.  Babies learn to speak the language used at home even when their parent(s) do not speak properly.  NWChem is full of of kinds of Fortran but it wasn't hard to figure out the difference between good and bad style from its inherent comprehensibility.

The second thing I learned to do is stop looking up answers and just answer questions experimentally.  You know those Twitter polls asking "without testing it, is this code (a) correct, (b) undefined behavior, (c) blah blah, (d) show me results"?  I hate them with the burning passion of [VY Canis Majoris](https://en.wikipedia.org/wiki/VY_Canis_Majoris).  I guess those polls are for ISO language lawyers and compiler developers, but they are useless to me.  I care about what works, and if something gives me the right answer and passes strict compiler checking and sanitizers, that's all I need to know.  Over the years, I've kept a [programmer diary](https://github.com/jeffhammond/HPCInfo) of random tests I've written to see what works.  Many of those tests involve things that aren't covered by one of those ISO-blessed APIs anyways, and when it comes to what vendors ship on exotic supercomputers, the only thing that matters is what produces the correct results (vendor documentation is rarely perfect).

It turns out that this is how babies learn to speak.  My kids didn't read a book to know how to ask for food.  Toddlers emit semi-random sounds until they get what they want, and over time, they get better at it.  They get a banana and I get `$?==0`. 

# Learning C

Later in grad school, I tried to learn C.  It turns out this is rather hard coming from Fortran, because Fortran passes everything by reference, and C passes everything by value, I spent a lot of time during my first year with C wondering why I could modify `a` with `void foo(int)`.  But eventually I learned, not because I read the Kernighan and Ritchie book or [ISO/IEC 9899](http://www.iso-9899.info/wiki/The_Standard) but because I read thousands of lines of C code that I was able to determine was some form of good.  For example, [PSI](https://psicode.org/) isn't perfect -- it was created by a bunch of [3+ star programmers](https://wiki.c2.com/?ThreeStarProgrammer) -- but it was a lot better than the C I knew how to write at the time, and working C is better than C that either doesn't work or doesn't exist.

# Learning Java

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
