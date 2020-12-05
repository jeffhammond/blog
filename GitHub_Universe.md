# Summary

This blog post accompanies my GitHub Universe video presentation on oneAPI.  I am going to continue to add stuff over the next week so if you find the current state incomplete, you might find it improves on its own.  Alternatively, feel free to contact me to ask for the content you want to see.

* email: it's on my GitHub [home page](https://jeffhammond.github.io/)
* tweet: [science_dot](https://twitter.com/science_dot)
* issue: create a GitHub issue against this repo to ask a question.  

# Direct links

* [Data Parallel C++ Tutorial](https://github.com/jeffhammond/dpcpp-tutorial)
* [Parallel Research Kernels](https://github.com/ParRes/Kernels)
* [Stencil Demo](https://github.com/jeffhammond/stencil-demo)
* [Intel DPC++ Compiler](https://github.com/intel/llvm/)
* [oneAPI GitHub Project](https://github.com/oneapi-src/)
* [oneAPI CI Examples](https://github.com/oneapi-src/oneapi-ci)
* [Jeff's blog about getting oneAPI working on a Tiger Lake laptop](
https://github.com/jeffhammond/blog/blob/main/Dell_Inspiron5000_Linux.md)

# Details

## Compiling DPC++

Download DPC++ from GitHub here: https://github.com/intel/llvm/.  The most common way to download is likely the following:
```sh
git clone https://github.com/intel/llvm.git dpcpp
```

### Intel Processors

You do not need to do this, but you are certainly free to compile DPC++ from source on Intel platforms.  If you do not want to compile DPC++, you can just install via Linux package managers as described on [Installing Intel® oneAPI Toolkits via Linux* Package Managers](https://software.intel.com/content/www/us/en/develop/articles/oneapi-repo-instructions.html).

The build for Intel processors is trivial:
```sh
python ./buildbot/configure.py
python ./buildbot/compile.py [-jN]
```

### CUDA Processors

The build of DPC++ for CUDA (PTX back-end) is straightforward.  You should use CUDA 10.1, 11.0 or 11.1.  I recall that 11.2 is not yet supported.  Version 10.0 is not supported but mostly works (see below for additional comments).
```sh
python ./buildbot/configure.py [--cuda]
python ./buildbot/compile.py [-jN]
```
I have tested DPC++ for CUDA on P100, V100 and A100.  It is possible to have problems due to various CUDA configuration issues on Linux.  If you experience such issues, report them on the [DPC++ GitHub project](https://github.com/intel/llvm/).

### ARM Processors

I ported DPC++ to ARM in September ([PR 2333](https://github.com/intel/llvm/pull/2333)) but unfortunately, there has been a regression in the build system that I have not yet been able to fix, so please use my branch [agx-works](https://github.com/jeffhammond/intel-llvm/tree/agx-works) for now.

The ARM build is straightforward using the buildbot scripts:
```sh
python ./buildbot/configure.py --arm [--cuda]
python ./buildbot/compile.py [-j1]
```

If you build on an ARM+CUDA platform like Xavier AGX, you should add the `--cuda` option.  Note that the current AGX distribution of CUDA is version 10.0, which is technically unsupported (10.1 is) and likely causes an issue with memory deallocation in some programs.  I am optimistic that the upcoming refresh of the AGX software distribution will address this.

If you are building a Raspberry Pi, you need to disable parallelism (`-j1`) because the memory on a Pi is insufficient to do parallel builds of LLVM.  If you do not limit build parallelism, your Pi will almost become unresponsive and require power cycling.

## Tutorials and Demos

TODO

# Questions and Answers

I'll add answers to any questions I receive.  If you ask a question in a public forum, I'll cite that, otherwise I will not attribute your question unless you specifically request it.
