program main
  use numerot
  implicit none
  real :: A(100), B(100), C(100)
  real :: RA, RB, RC
  
  A = 1
  B = 1
  C = 1
  
  !$omp parallel
  !$omp master
  
  !$omp task
  RA = yksi(A)
  !$omp end task
  
  !$omp task
  RB = kaksi(B)
  !$omp end task
  
  !$omp task
  RC = kolme(C)
  !$omp end task
  
  !$omp end master
  !$omp end parallel
  
  print*,RA+RB+RC
end program main
