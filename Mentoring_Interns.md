# Summary

I've supervisor more than twenty interns, all of whom were succesful as interns and are -- as best I can tell -- successful in their careers.  This post summarizes my approach to mentoring, which boils down to (1) hire people then find projects that suite them, not the other way way around, and (2) do whatever it takes to make your interns successful, whether that means leaving them alone or sitting with them an hour or two a day.

# Hiring

I have hired 100% of the students who wanted to work for me or who were recommended to me, along with a number of others who I recruited because they had skills and interests that were aligned with my research activities.  As I have never declined to hire an applicant, even an unofficial one, I have no idea to do intern selection.  What I can offer is my experience that everyone who wants to contribute can do so, given the right support, and it's up to the mentor to provide this.  If you are not up to the challenge of making your interns successful no matter what, maybe you aren't ready to be a mentor.

# Selecting a project

It helps to have a rough idea of something you and your intern will do together (and various administrative functions often require it), but the details should be late binding and you should always been open to changing directions even circumstances require.  I'll give an example of this later.

# Defining success

I applied ["Failure is not an option"](https://en.wikipedia.org/wiki/Failure_Is_Not_an_Option) to every one of my interns.  I had a wonderful experience as an intern at PNNL (see [this](https://github.com/jeffhammond/blog/blob/main/Career_Trajectory.md) for details) and a lot of people were incredibly generous of their time to make that possible, and I chose to hold myself to a similar standard as a mentor.

The grading criteria I used for interns was as follows:

  1) Minimum success criteria.  Whatever we need to accomplish for the internship to not be a complete waste of time.  It needs to be something that is entirely within the skills the intern has already and can be achieved with straightforward effort, possibly requiring significant investment from the mentor.  Nobody wants to be a failure, and succeeding at something straightforward gives people the confidence to take on bigger challenges.

  2) Very good results.  This is a pretty standard success criteria, such as publishing a peer-reviewed manuscript to which the intern contributed significantly.  It should be substantial enough that everyone will recognize the intern's contribution.

  3) Intergalactic science god.  Yes, I actually used those words in some cases.  I found that it was useful to provide an aspirational target for my interns that would keep them going if they managed hit level 2 relatively quickly.  More importantly, I wanted them to know they I had a lot of confidence in their abilities and felt that there was a chance to accomplish something so profound that it would make them famous in the scientific community.  It's important to have big dreams, even when you're an intern.

I didn't enumerate these criteria to every intern, but I had them in mind when I was designing their projects.  I'm not sure how other mentors do it, but I like to think that it's somewhat novel to think about 1 and 3, and work really hard to make sure that every intern gets to 1 as quickly as possible, and hopefully to 2.

And if you are wondering, yes, my some of my students hit level 3.  The work some of them did, often with very little help from me, changed their field of science and they are deservedly famous for it.  At one point in my career, I spent a lot of time working on tensor-related things, but I found that some of my former interns are so much better at this topic than I am that I stopped working on it and found new areas to which I can contribute.

# The Summer of 2011

I've been asked about this before, so I might as well write it down here.  In the summer of 2010, I had started talking to Devin Matthews and Edgar Solomonik about doing their DOE-CSGF practica (i.e. internships) with me at Argonne.  At the time, Edgar was a student of Jim Demmel's at Berkeley, working on efficient algorithms for matrix computations.  Devin was a chemistry graduate student at Texas wtih John Stanton, working on efficient formulations of coupled-cluster theory and their applications to spectroscopy.

Edgar and I came up with a plan to do smoething related to dynamic load-balancing in quantum chemistry, which was closer to his undergraduate research with Sanjay Kale in the Charm++ group.  The idea was to add better task scheduling to MPQC, which was a C++ code that did some of the same things as NWChem, but was a lot simpler to get working on Blue Gene/P.

Devin's project was going to be something that would expose him to more modern programming methods, since his work at Texas involved CFOUR, which is the closest thing to a genuine Fortran 77 code as I have ever seen.  Given Devin's experience with CFOUR, I figured we'd learn Fortran 95 togethre, and do something interesting along the way.

As it turned out, neigher of these project ideas worked out.  After a week or two, Edgar found that he couldn't get past a bug in the IBM C++ compiler for Blue Gene/P, and given the rate at which those got fixed (2-3 months), we'd lose the entire summer waiting to merely compile the code.  Around the same time, Devin decided that Fortran 95 dynamic memory management was just too stupid and he was not going to continue.

The other thing that was happening around that time -- this was May -- was that my wife was about to give birth to our first child and I was planning to be absent from the office for a while.  Knowing that I was not going to be available to help as much as normally would and the absence of any promising leads on either of their planned activities, I decided that the prudent thing was to come up with something new that they could do together while I was away.

The problem that I had been chewing on for a few years was how to do distributed tensor contractions efficiently, particularly on Blue Gene systems.  This mean using MPI collectives, not one-sided communication (while Blue Gene/P and /Q were really good at one-sided communication, they were utterly magical when it came to MPI collectives).  This project was closer to both of their dissertation projects and would not have been approved by the CSGF program stewards as a planned activity, but our plans were not going well.

We met in a conference room around the first week of June and I sketched out the problem statement.  We agreed it was a worthwhile thing to try to solve, and it was ideally suited for the two of them, since Edgar was a master of distributed linear algebra and Devin was a master of tensors in the context of coupled-cluster theory.  I left the lab on a Wednesday and didn't come back for about a month.  I was accessible via email and chat, but I don't recall much communication from them.

By the time I got back to the lab in July, they had solved the problem.  They hadn't implemented everything yet, but the ideas were all there.  Edgar created the Cyclops Tensor Framework (CTF) and Devin wrote what would become AQUARIOUS.  Devin wrote CCSD and CCSDT using CTF, and along the way created a prototype of a Cholesky-decomposition based SCF code.  The CCSD and CCSDT codes based on CTF were faster than the NWChem TCE, which was at the time the highest performance massively parallel implementaiton of those methods.  Furthermore, CTF was based entirely on simple MPI primitives that were highly optimized on every supercomputer, which ensured portable parallel performance without any special effort, which has never been true of NWChem because of its reliance on one-sided communication.
