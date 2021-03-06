This was originally part of [Mentoring Interns](Mentoring_Interns.md) and some of the CSGF references are explained in [Career Trajectory](Career_Trajectory.md), although I will eventually write a post dedicated to CSGF.

# The Summer of 2011

I've been asked about this before, so I might as well write it down here.  In the summer of 2010, I had started talking to Devin Matthews and Edgar Solomonik about doing their DOE-CSGF practica (i.e. internships) with me at Argonne.  At the time, Edgar was a student of Jim Demmel's at Berkeley, working on efficient algorithms for matrix computations.  Devin was a chemistry graduate student at Texas wtih John Stanton, working on efficient formulations of coupled-cluster theory and their applications to spectroscopy.

Edgar and I came up with a plan to do something related to dynamic load-balancing in quantum chemistry, which was closer to his undergraduate research with Sanjay Kale in the Charm++ group.  The idea was to add better task scheduling to [MPQC](https://mpqc.org/), which was a C++ code that did some of the same things as NWChem, but was a lot simpler to get working on Blue Gene/P.

Devin's project was going to be something that would expose him to more modern programming methods, since his work at Texas involved [CFOUR](http://www.cfour.de/), which is the closest thing to a genuine Fortran 77 code as I have ever seen.  Given Devin's experience with CFOUR, I figured we'd learn Fortran 95 together, and do something interesting along the way.

As it turned out, neither of these project ideas worked out.  After a week or two, Edgar found that he couldn't get past a bug in the IBM C++ compiler for Blue Gene/P, and given the rate at which those got fixed (2-3 months), we'd lose the entire summer waiting to merely compile the code.  Around the same time, Devin decided that Fortran 95 dynamic memory management was just too stupid and he was not going to continue with modern Fortran.  (I think Edgar put Devin onto C++ -- Devin is now one of the most talented C++ programmers I know, although he's still fluent in Fortran 77 for CFOUR purposes).

The other thing that was happening around that time -- this was May -- was that my wife was about to give birth to our first child and I was planning to be absent from the office for a while.  Knowing that I was not going to be available to help as much as normally would and the absence of any promising leads on either of their planned activities, I decided that the prudent thing was to come up with something new that they could do together while I was away.

The problem that I had been chewing on for a few years was how to do distributed tensor contractions efficiently, particularly on Blue Gene systems.  This mean using MPI collectives, not one-sided communication (while Blue Gene/P and /Q were really good at one-sided communication, they were utterly magical when it came to MPI collectives).  This project was closer to both of their dissertation projects and would not have been approved by the CSGF program stewards as a planned activity, but our plans were not going well.

We met in a conference room around the first week of June and I sketched out the problem statement.  We agreed it was a worthwhile thing to try to solve, and it was ideally suited for the two of them, since Edgar was a master of distributed linear algebra and Devin was a master of tensors in the context of coupled-cluster theory.  I left the lab shortly thereafter and didn't come back for about a month.  I was accessible via email and chat, but I don't recall much communication from them.

By the time I got back to the lab in July, they had solved the problem.  They hadn't implemented everything yet, but the ideas were all there.  Edgar created the [Cyclops Tensor Framework](https://solomon2.web.engr.illinois.edu/ctf/) (CTF) and Devin wrote what would become [AQUARIOUS](https://github.com/devinamatthews/aquarius).  Devin wrote CCSD and CCSDT using CTF, and along the way created a prototype of a Cholesky-decomposition based SCF code.  The CCSD and CCSDT codes based on CTF were faster than the NWChem TCE, which was at the time the highest performance massively parallel implementaiton of those methods.  Furthermore, CTF was based entirely on simple MPI primitives that were highly optimized on every supercomputer, which ensured portable parallel performance without any special effort, which has never been true of NWChem because of its reliance on one-sided communication.

Once CTF was published, it became the new standard for other researchers to beat.  Some have improved on CTF by improving the design, but the core idea that tensor contractions, even ones involving highly symmetric tensors, can and should be done using communication-optimal matrix algorithms combined with collective tensor transposes.  Furthermore, CTF showed that no code generation is required and that all of the operations of coupled-cluster theory, even higher-order methods like CCSDTQ, can be expressed in simple notation that translates efficiently to a small number of back-end functions.

# Details

If you want to know more about this project, please read the following:
* [An Overview of Cyclops Tensor Framework](https://solomonik.cs.illinois.edu/talks/molssi-monterey-may-2017.pdf) - Edgar's overview slides.
* [A preliminary analysis of Cyclops Tensor Framework](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2012/EECS-2012-29.html) - The first paper.
* [Cyclops Tensor Framework: reducing communication and eliminating load imbalance in massively parallel contractions
](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2012/EECS-2012-210.html) - The second paper.
* [A massively parallel tensor contraction framework for coupled-cluster computations](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2014/EECS-2014-143.html) - The third paper.

[CTF on GitHub](https://github.com/cyclops-community/ctf) has references to additional applications and publications.

(c) Copyright Jeff Hammond, 2020. No reuse permitted except by permission from the author.
