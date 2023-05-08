# In Defense of Fortran

Fortran is a programming language that people love to hate.
Hating programming languages isn't rare, and most programming languages have haters,
but it seems particularly popular for serious people in the software community to
criticize Fortran, often in ways that are logically or factually flawed.

The fact is, I don't love Fortran, certainly not like some people love Fortran.
There are people who write everything in Fortran, and believe that it's the best
programming language for just about everything.
While I used Fortran during grad school and have worked on NWChem -
a mostly pre-modern Fortran chemistry application - my entire career,
I am more proficient in C and it is the default language I use when writing new code.
I've also written a nontrivial anount of C++ and Python, and have spent enough
time writing other languages to appreciate the diversity of design choices that exist.
Thus, I think I'm qualified to write objectively about why Fortran is a good language,
and certainly why some of the criticisms of it are bogus.

One of the common fallacies in programming language evaluation is to argue that
because one language does better at a subset of features, it is therefore an
objectively better language overall.
The second fallacy is to ignore the experience and goals of the programmer using
the language.
Most criticisms of Fortran rely heavily on at least one of these.

Now let's look at some of the good and bad features of Fortran.

## Fortran doesn't have a standard library

*Fortran afficianados will of course shout at their computer that I have
ignored https://github.com/fortran-lang/stdlib.  I have not.
An open-source project isn't the same as an ISO standard, and WG5 has not
ratified anything resembling the C++ STL.
Furthermore, that project is only fully supported by recent versions of
two compilers, which means it's standard neither in theory nor in practice.*

C++ is well-known for its standard library of containers and algorithms,
and many useful primitives.
On the other hand, Fortran has very few built-in algorithms, and the only
data structure in Fortran is an array.
This isn't too different from C, except that Fortran's strong typing and
more restrictive pointer semantics make it harder to implement a
linked-list than in C.

Standard libraries are great, and if the C++ STL is a great match for your
application or library, then you should probably use C++.
This does not mean that Fortran is an inferior programming language.
A large number of applications have no need for a linked-list, a dequeue,
or a hash map, and when Fortran applications need something like this,
they either implement it directly or call out to another language.
In NWChem, we implement distributed block sparse arrays with a map,
where the map data structure is a 2xN dimensional array of integers.
It works and, more importantly was a lot simpler than rewriting the
application in C++.

On the other hand, the Fortran intrinsics that are standard are quite
useful to Fortran applications.  Fortran has `MATMUL`, `TRANSPOSE`,
`DOT_PRODUCT`, and many other common operations for arrays, which are
useful to the applications for which Fortran is used.
C++20 doesn't even have proper multidimensional arrays, and it appears
that the equivalent of `MATMUL` may appear in C++26.
Does this mean that C++ is useful for linear algebra?
Of course not, because just like Fortran programmers, C++ programmers
are capable of using more than one-liner solutions.

In conclusion, if you are looking for a programming language ecosystem
with lots of turnkey library routines, C++ and Python are great options.
Fortran and C are not, and that's okay.

## Fortran compilers are imperfect

I've used Fortran compilers from GCC, Intel, PGI->NVIDIA, Cray, IBM,
Fujitsu and Pathscale over the years, and none of them are perfect.
In particular, some of them are inadequate for modern Fortran code.
(Modern Fortran here means Fortran 2008 and later - I'm not aware of
any actively developed compiler that doesn't support Fortran 2003.)
Some people have tried to claim that this means that we have to abandon
Fortran for C++, which has the most amazing compiler support ever,
as long as the only C++ compilers we look at are the latest releases
of GCC and Clang.

I find it especially rich that anyone argues that C++ is better than
Fortran because the compilers are so great.
They seem to forget what using C++ was like before Cray, IBM and Intel
killed off their C++ front-ends in favor of Clang, which happened
because all the C++ programmers were so obsessed with using the latest
language features that their code only compiled with GCC and later Clang.
I don't use Windows so I don't really know about MSVC, but as best I
can tell, there are only two usable C++ compilers for Linux, and
one of them is propelled ever forward by the collective might of
companies with a market capitalization in excess of three trillion dollars,
who contribute at least $100M a year in employee effort to the project.
Yet, when investment of $10M to make Fortran compilers better is proposed,
Fortran users get uncomfortable, and nobody seems to want to spend a
dime on GCC Fortran.

Compilers aren't free, and good compilers are expensive.
While it's true that the HPC community gets a free lunch from 
Big Tech when it comes to modern C++ support, they still have
to pay for OpenMP and GPU support, the maintenance costs of their
parallel C++ frameworks, and an army of people to debug the 
template instantiation error of the day.

The Classic Flang project demonstrated that a multi-vendor open-source
collaboration around Fortran is possible, just like with Clang,
and while the LLVM (new) Flang project isn't finished yet, they
deserve patience in the same way that Clang deserved patience when
it was not yet competitive with GCC.

## Fortran is hard to teach and hard to learn

This one is especially rich coming from the C++ community, a language 
that requires having an entire book written about [move semantics](https://www.cppmove.com/).
However, everybody seems to agree that Python is easy to learn,
so let's compare Numpy - the lingua franca and machine learning - and Fortran.

### 2D Stencil

Below are excerpts from the [Parallel Research Kernels](https://github.com/ParRes/Kernels) (PRK)
implementation of the 2D stencil, which is a common homework program in computational science.
The major differences in the code shown are:
 1. Fortran defaults to base-1 array indexing, whereas Python is 0-based like C.
    Fortran supports 0-based indexing if somebody has a hard time with the default.
 2. Fortran requires `end do`, whereas Python figures this out from indentation.

Other than those two trivial differences, the syntax is the same.
Numpy supports the same expressive array syntax that Fortran 90 had.
We can also look at PRK nstream, transpose and dgemm to see that they are also
1:1 using array expressions and math intrinsics.

```python
b = n-r
for s in range(-r, r+1):
  for t in range(-r, r+1):
    B[r:b,r:b] += W[r+t,r+s] * A[r+t:b+t,r+s:b+s]
```

```fortran
b = n-r
do j=-r,r
  do i=-r,r
    B(r+1:b,r+1:b) = B(r+1:b,r+1:b) + W(i,j) * A(r+i+1:b+i,r+j+1:b+j)
  enddo
enddo
```

Of coures, the big difference is in the code not shown.
Fortran is strongly typed and requires everything to be declared
(because we are not psychopaths and use `implicit none` everywhere),
whereas Python infers types from the first usage of a variable.
However, when using Numpy, it's often prudent to be somewhat explicit,
e.g. `X = numpy.zeros(n,dtype=float)`, so it's unlikely that
`real(kind=REAL64), allocatable ::  A(:,:)` is going to be a showstopper
when learning Fortran.

While Fortran might require slightly more work than Numpy, they
are similarly expressive when it comes to the mathematical code that matters,
so it's hard to argue that Fortran can't be learned, while thousands of
data scientists are learning Numpy every year.

## Memory Safety

Rust is a relatively new programming language that is obsessed with safety
and correctness, but manages to preserve performance in the process.
The Rust community has written quite a bit about memory safety relative
to C and C++, neither of which are memory safe.  One can write a careful
subset and C++ to avoid the flaming chainsaw juggling that is C memory
management, but C++ compilers aren't going to prevent programmers from
doing horrible things the way Rust does.

I haven't seen anybody talk about Fortran being memory safe.  It's certainly
not trying to be memory safe in the way that Rust is, but it is educational
to try and write a memory leak in Fortran, because it's not easy.

##  Optional and named arguments

This is a case where Fortran is just nice, and should be appreciated for it.
Nobody is claiming that C++ is better than Fortran because
of named arguments, because C++ doesn't have named arguments.

## Object-Oriented Fortran






