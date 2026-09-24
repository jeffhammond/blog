# Experiences with Agentic Development of MPI and Beyond

*Edited narrative based on the MUG Day 3 talk and audience Q&A*  
[Watch the original recording](https://www.youtube.com/watch?v=Hf2z2rmYFkI)

AI edited this so it's not exactly my voice, but it's better than nothing, and I haven't had time to write a better version manually.

## What I wanted to learn

The good news is that none of us are out of a job. If anything, working with coding agents has made my job much more interesting.

I have worked on MPI for a long time, along with a number of other projects in high-performance computing. NVIDIA has a strong interest in AI, of course, and management encouraged us to experiment with agentic software development. The question for me was how to evaluate it seriously.

There was only one sensible way to do that: use it on problems where I already knew what a correct answer looked like. If I asked an agent to build an iPhone application, I would have no reliable way to judge the result. I do not know that ecosystem well enough to recognize all the security problems, design mistakes, or failure modes. MPI and quantum chemistry are different. Those are areas where I can evaluate both the design and the implementation.

That expertise matters because agentic development works only until the agent gets stuck or heads in the wrong direction. At that point, a human has to understand the problem well enough to intervene. The experience reminds me of working with talented interns: much of the time, you can give them a goal and iterate quickly, but sometimes you have to sit down with them, explain the missing concept, and guide them through the next step.

I primarily used Claude and OpenAI Codex. They are generally the same, with some differences in cost and terminal interaction, although I find Claude slightly better for the hardest problems. No matter what agent you use, don't waste time telling it "yes" every time it needs permission.  Create a Docker sandbox with all your dependencies in it and use that in "YOLO" mode.  This allowed me to let the agent work autonomously for long periods of time, e.g., "work on message rate; I am going to bed," and return in the morning to find that it had spent several hours testing and improving the implementation.

_Editor's note: I now find that Claude "auto" mode is sufficient, i.e. `--dangerously-skip-permissions` is no longer required to be productive._

## Why MPI was the right experiment

I called the project **VibeMPI**, although it was not really vibe coded. The name survived because it was provocative and I was too lazy to find another name. In practice, I did a substantial amount of design, testing, and debugging.

My day job is in NVIDIA's NCCL team, where I am interested in whether agents can help develop communication software for NCCL, NVSHMEM, and related systems. MPI was the best way to evaluate that question because it is the gold standard for communication software. It has a formal specification, several high-quality open-source implementations, vendor-optimized implementations that can serve as performance references, and a large collection of tests.

Even with all those resources, the MPI specification alone is not sufficient to create an implementation with an agent. It is an excellent specification for humans who share decades of context, but it is not a machine-readable implementation recipe, nor should it be. The existing tests are valuable, but they are not sufficient either.

Agentic development is, in my experience, a form of test-driven development. Without tests, you have nothing. Anything that is not tested is probably wrong, sometimes in ways a human expert would never anticipate. At one point, the agent allocated 8GB of eager buffers because doing so improved a benchmark. No MPI graduate student or experienced developer would need to be told why that is unacceptable, but the agent happily optimized the objective it had been given.

## Building a foundation of MPI knowledge

Before I started working on VibeMPI, I began by assembling a large body of MPI material: mailing-list archives, papers, existing implementations, and test suites. Downloading all of it even got me temporarily banned by my internet service provider.

I did not put an artificial wall between the agent and the source code for MPICH or Open MPI. The agent was allowed to read those implementations, including their comments and design choices. It could not simply copy them because Vibe MPI was written in modern C++, but it could learn from them. That is consistent with how the MPI community has always worked. The implementations use permissive licenses, and reading code is often the only way to understand techniques that were never fully documented in papers.

I also biased the AI knowledge base toward sources I trusted. A random statement on a mailing list should not carry the same weight as work from established MPI experts. Agents can become fixated on a confidently written but incorrect comment, so curation matters.

My first experiment was to have the agent write a book about MPI. It produced a mediocre book that could probably be turned into a decent one, but writing prose about MPI does not demonstrate a real understanding of MPI. As Feynman's dictum suggests, if you cannot build it, you do not truly understand it. I therefore decided to build an MPI implementation instead. That would test both the agent and me.

I had always wanted to write an MPI library, but a serious implementation normally requires a group of people working for years. The agent gave me a way to generate roughly 100,000 lines of code while I concentrated on architecture, experiments, and review.

## Designing Vibe MPI

The design was not generated from a single prompt. I drew on years of conversations with MPI implementers and members of the MPI Forum, then used agents to turn design ideas into prototypes and experiments.

Message matching was the hardest part. Despite MPI's enormous API surface, receiving messages with wildcard sources or tags is more difficult than implementing hundreds of routine entry points. I proposed alternative matching algorithms, had the agent implement each one, generated microbenchmarks, and compared the results empirically. This made it cheap to explore ideas that would otherwise require a great deal of manual coding.

I made no attempt to compete with production implementations on portability or backward compatibility. Vibe MPI uses C++20 and the standard library extensively. Some choices were too optimistic -- `std::vector`, for example, is not necessarily ideal for eager buffers -- but modern C++ saved a great deal of work that would otherwise have gone into recreating basic infrastructure in C.

I wanted broad feature coverage, including less popular features such as `MPI_THREAD_MULTIPLE` and remote memory access. The library was compatible with the MPI ABI from the beginning because it used the [MPI ABI stubs header](https://github.com/mpi-forum/mpi-abi-stubs) as its `mpi.h`.

The configure-compile-test loop turned out to be critical. An agent can generate code far faster than a person, which means build and test latency quickly becomes the bottleneck. I personally dislike CMake, but CMake with Ninja made this loop dramatically faster than an Autotools-based build. More importantly, the agent was good enough at writing and debugging CMake that I rarely had to become involved. I am happy to use a tool I dislike when the agent can handle it reliably.

The first transports were shared memory and TCP. I later added OFI and UCX simply because I had reached a useful point with TCP and wanted to see how far the experiment could go. Supporting hardware tag matching required a substantial redesign. MPICH's CH4 architecture went through a comparable co-design process with vendors over a much longer period. With a design already forming in my head and an agent generating the implementation, I completed my redesign in roughly two days and had the new transports working within a week.

## How fast the project moved

I began the implementation on May 26, 2026. By June 15, Vibe MPI had working single-node TCP and shared-memory transports and passed the applicable MPICH tests, along with many others. It was not perfect, but it was already a credible MPI implementation.

I worked grad student hours: seven days a week, checking the agent first thing in the morning and again before going to bed. I did not work around the clock, but the agent often did. During one month I reached my $10,000 usage limit on the twenty-eighth day. My estimate is that Vibe MPI consumed about $25,000 in model tokens. That is a substantial personal expense, but it is small by industrial software-development standards and perhaps a thousand times less than the estimated cost of developing a conventional production MPI implementation.

After returning from vacation, I gained access to an InfiniBand system through the HPC Advisory Council cluster. Real multi-node testing exposed many bugs that virtual-node TCP testing had not. I brought TCP, OFI, and UCX to multi-node operation in a little over a week, including launcher work and the usual InfiniBand wire-up issues.

When I was invited to discuss the work with HPE, I attempted a Slingshot port. That took two days to get partially working and exposed a major weakness in my top-down approach, which I will return to later.

## What the implementation contained

At the time of the talk, the project contained approximately 100,000 lines: about 60,000 lines of C++ implementation, 20,000 lines of tests, and another 20,000 lines of supporting material. Much of the last category consisted of scripts, agent wrappers, test harnesses, and a CMake system that incorporated the major external MPI test suites.

Vibe MPI implemented the full MPI 5.0 API. I had relatively high confidence in core areas such as datatypes and collectives. Dynamic process management and sessions remained more brittle. The implementation could select among its transports at runtime, including OFI and UCX, which was important to me because I did not want to compile separate MPI libraries for every transport on a system.

The project also became a platform for design experiments. It included several message-matching algorithms and an optimization for communicators that do not use wildcard receives. It implemented RMA through both active messages and native transport operations. I assumed communication threads because I value asynchronous progress, although that choice has a latency cost.

I implemented a wide range of collective algorithms, including research algorithms that production libraries may avoid because they are highly workload-dependent. In Vibe MPI, such an algorithm can simply be exposed as an option and enabled when the user knows it matches the application.

One of my favorite design choices was making nearly every tuning parameter adjustable at runtime through environment variables, MPI_T, or MPI Info objects on communicators and windows. That let me build once and repeat design experiments by switching protocols and parameters at runtime. It was also valuable for testing because the same binary could exercise many different internal paths.

## Testing was the most important result

I used the MPICH, OSU, Intel, and IBM/Open MPI test suites, along with tests from DOE projects and my own work. In total, the Vibe MPI test bucket contained roughly 2,000 tests. I was passing all the tests that a generic implementation could reasonably pass, apart from a few MPICH-specific behaviors available through a compatibility mode.

The existing suites were still not enough. I wrote hundreds of additional tests based on my knowledge of the standard, failures I observed, and coverage analysis. These tests were interesting in their own right because many had never existed before. Production MPI implementations may already behave correctly because human designers made sound choices, but Vibe MPI needed explicit tests to prevent the agent from choosing something superficially plausible and fundamentally wrong.

I integrated GNU code-coverage analysis into the agent's workflow. If datatype coverage was 71 percent, for example, I told the agent to keep writing datatype tests until every meaningful branch was covered. The MPI standard defines behavior whether or not a typical application relies on it, so code that implements that behavior should be tested. In most major components, this process drove coverage to approximately 99 percent.

I intend to release the new tests independently of Vibe MPI so that the rest of the community can use them. ARMCI-MPI has long been useful for breaking RMA implementations, but even it did not cover everything I needed. The new RMA tests are unusually aggressive, and it will be interesting to see what they reveal in other implementations.

## Performance: good results and revealing failures

On the InfiniBand cluster, I used HPC-X over UCX as the primary performance reference. Vibe MPI over UCX was competitive on send/receive bandwidth and came close on small-message latency. Its RMA latency was worse, largely because of the communication-thread and asynchronous-progress design. Accumulate performance was also weaker than I wanted, although it was adequate for some Global Arrays workloads.

The performance curves provided a perfect example of an agent doing exactly what it was told. I separately asked the agent to optimize latency, peak bandwidth, and message rate. It did well at those objectives, but I had never asked it to optimize the entire range of intermediate message sizes. The result was a large bandwidth drop over a particular range, probably caused by a protocol transition. The likely fix is straightforward: redefine the objective to include every message size, then let the agent develop and test an additional protocol. The point is not that the agent failed mysteriously. It optimized the stated objective and ignored the unstated one.

I also ran LULESH because I wanted an application result for a discussion with Lawrence Livermore National Laboratory. At small scale -- four and sixteen nodes -- Vibe MPI was competitive with HPC-X and occasionally a little faster, probably because of its shared-memory all-reduce. These were not showcase-scale HPC results, and the project had been optimized mostly at small scale, but they showed that the implementation was usable for LULESH and several other mini-applications.

## The Slingshot failure and what it taught me

The OFI port exposed an important limitation. OFI providers are not interchangeable. The InfiniBand, TCP, and CXI providers behave very differently, and an MPI implementation cannot treat OFI as a single uniform abstraction.

I knew this in principle, but initially chose to see what the agent could do without enough provider-specific guidance. It did poorly. After two days, it had only begun to understand the CXI provider, and the Slingshot implementation still had serious performance and scaling problems.

The solution was to start over with a separate agent and a bottom-up task. I asked it to read the manuals, write native OFI tests, and conduct small design experiments for an MPI-style protocol over CXI. That work produced a focused knowledge base, which I then fed back into the Vibe MPI effort. Basic features began to work, but performance remained poor and the implementation still hung at scale because CXI is unforgiving about protocol and resource-management decisions that other providers tolerate.

The lesson was simple: when neither the human nor the agent understands the underlying network, top-down code generation is not enough. Build the primitives, measure them, establish the abstractions, and only then compose them into the larger system.

## Agents as MPI quality tools

Vibe MPI is a research project. I plan to open-source it, publish the results, and then retire it rather than turn it into a product. Its purpose is to demonstrate what expert-guided agents can do and to help other developers apply the same ideas to production software.

The techniques are useful even if nobody wants another MPI implementation. I used agents to perform a major ARMCI-MPI update involving request-based RMA and then to test it on InfiniBand. In short order, that effort uncovered nine bugs across major MPI implementations and across both OFI and UCX paths.

The agents drove the tests, collected debugger backtraces, analyzed failures, and drafted Markdown bug reports. I reviewed the reports and removed unhelpful generated commentary before submitting them. When an Open MPI developer was unavailable, I asked an agent to clone Open MPI, locate the reported issues, and fix them. It produced patches for several subtle bugs, some of which were merged quickly.

Within roughly a week, agent-driven testing materially improved the quality of MPI RMA implementations. This may be the most immediately useful conclusion from the project. Even if you do not trust an agent to write production code, testing and debugging are unusually verifiable uses. If the agent produces a small reproducer that crashes MPI, determining whether the bug is real is not a matter of opinion.

## Why the open-source MPI ecosystem still matters

Vibe MPI was possible only because the community has two high-quality open-source MPI implementations. They provided both an intellectual foundation and a behavioral oracle. Neither the written specification nor the existing tests were sufficient on their own.

This is important for funding agencies and engineering managers. Agentic development does not eliminate the need to invest in expert-maintained open-source software. It depends on that software. If those implementations and their communities disappear, projects like Vibe MPI become far less practical.

Agents can also help existing MPI libraries fill feature gaps. Implementing the long tail of MPI 5.0 features is relatively easy when an expert can define the intended behavior and build the right tests. Quality assurance is another clear opportunity. What the agent did not provide was expertise. It amplified expertise I already had.

AI is a power tool for MPI experts. It can make them extraordinarily productive and remove a great deal of tedious work, but it will not make an inexperienced person competent in MPI.

## Beyond MPI: NCCL, NVLink, and GPU-initiated networking

My day job is closer to NCCL and GPU communication. The same approach applies there, although the documentation and examples are not yet as rich as they are for MPI.

My workflow is to collect the available documentation, source code, and tests, then have the agent read all of it. After completing one successful project, I use that project as context for the next one. Knowledge compounds.

The agents repeatedly displayed a very human-looking blind spot. They could produce good latency for a communication operation, but bandwidth over NVLink was terrible. The reason was that they tried to drive a roughly 450 GB/s link from a single streaming multiprocessor. A single GPU core or SM cannot generate enough load/store parallelism to saturate NVLink. The agent and I rediscovered this fact more than once. In a mature workflow, it belongs in a reusable skill for NVIDIA communication-stack development.

I am not a CUDA optimization specialist, but an agent was able to run Nsight Compute, analyze register usage and kernel occupancy, and iterate on the kernels. That produced order-of-magnitude improvements in some GPU communication operations. I was also able to experiment with GPU-initiated networking and rail-based communication on an NVL72, despite the limited number of public examples.

In one comparison, my agent-assisted implementation came within roughly 20 percent of NCCL's native performance. That is not a replacement for the NCCL team. NCCL embodies the accumulated expertise of dozens of people over many years. What is exciting is that one domain expert, working with an agent, can get close enough to make useful custom experiments feasible. I also implemented and debugged several NVLink barrier algorithms, reaching approximately five to ten microseconds for barriers across more than fifty GPUs.

## What agentic development is good for

Agentic development improved dramatically between 2024 and 2026. In 2024, I found it almost comically bad. In 2025, it was interesting but not compelling. By May 2026, it had become a genuine change in how I work.

Agents are especially good at work many developers dislike: resolving Git rebase conflicts, maintaining build files, driving GDB or Valgrind, measuring coverage, submitting Slurm jobs, varying benchmark configurations, and generating plots. I know how to do all of those things, but I do not need to spend my time on them anymore.

This comes with operational risks. HPC centers will need policies and safeguards for agents running on login nodes and shared filesystems. We have always had users who make mistakes, but autonomous agents can make mistakes faster and at a larger scale.

An agent will also listen when you are wrong. It can be brilliant and pathologically foolish in successive moments. Vibe MPI deadlocked. It allocated absurd amounts of eager-buffer memory. It optimized isolated benchmark points while ignoring the gaps between them. You have to test everything. "Trust but verify" is not strong enough: if something is not tested, assume it is broken, possibly in a spectacular way.

Even after accounting for those limitations, I estimate that agents increased my productivity on this research by somewhere between 100 and 1,000 times. I wrote more code in two months than I had in the previous ten years. That number needs context: this was research software, not a product, and it was not security-sensitive. More conservative environments need more review and stronger guardrails. Even with those costs, I believe a tenfold gain is realistic for many expert-driven research tasks.

## The right mental model

Think about constructing a building. The project needs an architect, an engineer, and a construction manager, as well as the people who perform the physical work. Today's coding agents are very good carpenters. They can produce thousands of lines of code quickly, but they are not reliable architects and they do not assume responsibility for engineering safety or project management.

The human remains the architect, engineer, and manager. The agent hammers the nails. With the right design, interfaces, tests, and supervision, a small group can build things that once required a much larger team. But a thousand carpenters without a sound design will not produce a building you should trust.

## Audience Q&A

### Would you approach a hypothetical "Vibe NCCL" differently?

Yes. Vibe MPI was developed largely from the top down because I did not want to become an expert in TCP/IP socket programming. For a Vibe NCCL project, I would work from the bottom up.

I would begin with communication microbenchmarks for NVLink and InfiniBand, then build a set of reusable skills and components: semaphores, messaging primitives, synchronization mechanisms, and the interfaces between them. Only after validating those layers would I compose them into a larger system.

That is what the Slingshot experience taught me. Neither the agent nor I initially understood the network well enough, and two days of top-down work produced very little. Conventional software architecture still applies. Well-designed building blocks constrain the search space and help the agent reason effectively.

### What happens when the source code for the target application is unavailable?

I also tried building a quantum chemistry package from scratch without initially showing the agent NWChem. The result was impressive but extremely slow.

Quantum chemistry is relatively favorable for this experiment because there is a large body of literature explaining the mathematics and algorithms. I was able to make substantial progress from papers and equations alone, but eventually reached a point where that material was not enough and source code became necessary. English and mathematical notation are imperfect ways to specify all the details of software behavior.

### Will agents produce better software, or simply more software that is 20 percent worse?

I believe the overall result can be better software because high-quality implementation is a bottleneck in almost every simulation and AI organization. Scientific users still depend on codes that are decades old, not because nobody knows what a better design might look like, but because translating that knowledge into a tested implementation is enormously expensive.

Agents change that equation. A researcher can define an algorithm on a whiteboard, write down the equations, describe the design, generate an implementation, and then test and probe it. When that loop becomes one hundred times faster, experiments that were previously impractical become routine.

There will also be mountains of bad generated software. The opportunity depends on scientific and engineering discipline: careful objectives, strong tests, expert review, and responsible use of computing resources. Used well, agents can allow graduate students and researchers to spend more time doing research and less time typing.

---

*Editorial note: This version removes timestamps, verbal fillers, setup delays, and repeated phrases. It lightly condenses the talk while preserving its argument, technical substance, estimates, caveats, and audience discussion. Terminology and names garbled by automatic transcription have been corrected where the intended reference was clear.
