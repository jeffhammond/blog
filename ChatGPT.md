TODO: write a blog post about ChatGPT generates terrible code, so that people stop freaking out.

## Matrix Transpose

Q: Please write a code that transposes a matrix of arbitrary size using CUDA Fortran

A: Here is an example of a Fortran program that transposes a matrix of arbitrary size using CUDA:

```fortran
program matrix_transpose
  use cudafor
  implicit none

  ! Declare variables
  integer, parameter :: m = 1000, n = 1000
  real, dimension(m,n) :: a, b
  integer :: i, j

  ! Initialize input matrix
  do i = 1, m
    do j = 1, n
      a(i,j) = i * j
    end do
  end do

  ! Transfer input matrix to device
  a = a !$cuf

  ! Launch kernel to transpose matrix on device
  call transpose_matrix(m, n, a, b)

  ! Transfer result back to host
  b = b !$cuf

  ! Print transposed matrix
  do i = 1, m
    do j = 1, n
      write(*,*) b(i,j)
    end do
  end do

end program matrix_transpose

! Kernel to transpose matrix on device
attributes(global) subroutine transpose_matrix(m, n, a, b)
  implicit none

  ! Declare variables
  integer, value :: m, n
  real, dimension(m,n) :: a, b
  integer :: i, j

  ! Get thread and block indices
  i = blockIdx%x
  j = threadIdx%x

  ! Compute transposed matrix element
  b(i,j) = a(j,i)

end subroutine transpose_matrix
```
This program defines a matrix_transpose program that initializes an input matrix on the host, transfers it to the device, launches a kernel to transpose the matrix on the device, and then transfers the result back to the host to be printed to the screen. The transpose_matrix kernel uses the thread and block indices to compute the transposed matrix element at the corresponding position in the output matrix. The size of the matrix can be changed by modifying the m and n parameters. Note that this is just one possible way to implement matrix transposition using CUDA Fortran, and there are many other ways to achieve the same result.


## Matrix Multiplication with OpenMP

Q: Please write a Fortran code that does matrix multiplication using OpenMP target offload
A: Here is an example of a Fortran program that performs matrix multiplication using OpenMP target offload:

```fortran
program matrix_multiply
  use omp_lib
  implicit none

  ! Declare variables
  integer, parameter :: m = 1000, n = 1000, p = 1000
  real, dimension(m,n) :: a, b, c
  integer :: i, j, k

  ! Initialize input matrices
  do i = 1, m
    do j = 1, n
      a(i,j) = i * j
    end do
  end do
  do i = 1, n
    do j = 1, p
      b(i,j) = i + j
    end do
  end do

  ! Perform matrix multiplication on device
  !$omp target map(tofrom: a, b, c)
  !$omp parallel do default(none) shared(m,n,p,a,b,c) private(i,j,k)
  do i = 1, m
    do j = 1, p
      c(i,j) = 0
      do k = 1, n
        c(i,j) = c(i,j) + a(i,k) * b(k,j)
      end do
    end do
  end do
  !$omp end parallel do

  ! Print result matrix
  do i = 1, m
    do j = 1, p
      write(*,*) c(i,j)
    end do
  end do

end program matrix_multiply
```
This program defines a matrix_multiply program that initializes two input matrices on the host, then uses OpenMP target offload to perform matrix multiplication on the device. The omp parallel do construct is used to distribute the computation of the matrix multiplication across multiple threads on the device. The result matrix is then printed to the screen on the host. The size of the matrices can be changed by modifying the m, n, and p parameters. Note that this is just one possible way to implement matrix multiplication using OpenMP target offload, and there are many other ways to achieve the same result.

## Matrix Multiplication 2

Q: Please write a matrix multiplication code in Fortran that uses cache and register blocking to achieve a reasonable performance
A: Here is an example of a Fortran program that performs matrix multiplication using cache and register blocking to optimize performance:

```fortran
program matrix_multiply
  implicit none

  ! Declare variables
  integer, parameter :: m = 1000, n = 1000, p = 1000
  real, dimension(m,n) :: a, b, c
  integer :: i, j, k, ii, jj, kk, block_size
  real, dimension(:), allocatable :: a_block, b_block

  ! Set block size
  block_size = 32

  ! Allocate memory for block arrays
  allocate(a_block(block_size*block_size))
  allocate(b_block(block_size*block_size))

  ! Initialize input matrices
  do i = 1, m
    do j = 1, n
      a(i,j) = i * j
    end do
  end do
  do i = 1, n
    do j = 1, p
      b(i,j) = i + j
    end do
  end do

  ! Perform matrix multiplication with blocking
  do ii = 1, m, block_size
    do jj = 1, p, block_size
      do kk = 1, n, block_size

        ! Copy blocks of matrix A and B to registers
        do i = 1, block_size
          do j = 1, block_size
            a_block(i + (j-1)*block_size) = a(ii+i-1, kk+j-1)
            b_block(i + (j-1)*block_size) = b(kk+i-1, jj+j-1)
          end do
        end do

        ! Perform matrix multiplication on block
        do i = 1, block_size
          do j = 1, block_size
            c(ii+i-1, jj+j-1) = 0
            do k = 1, block_size
              c(ii+i-1, jj+j-1) = c(ii+i-1, jj+j-1) + a_block(i + (k-1)*block_size) * b_block(k + (j-1)*block_size)
            end do
          end do
        end do

      end do
    end do
  end do

  ! Print result matrix
  do i = 1, m
    do j = 1, p
      write(*,*) c(i,j)
    end do
  end do

end program matrix_multiply
```
This program defines a matrix_multiply program that initializes two input matrices on the host, then uses cache and register blocking to perform matrix multiplication in an optimized way. The algorithm divides the matrices into blocks of a specified size and performs the multiplication on each block, storing the blocks in registers to reduce access to main memory. This can improve performance by reducing the number of memory accesses and increasing the amount of data that can be kept in cache. The size of the matrices and the block size can be changed by modifying the corresponding parameters. Note that this is just one possible way to implement matrix multiplication using cache and register blocking, and there are many other ways to achieve the same result.
