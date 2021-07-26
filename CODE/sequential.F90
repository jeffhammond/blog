program main
  use numerot
  implicit none
  real :: A(100), B(100), C(100)
  real :: RA, RB, RC
  
  A = 1
  B = 1
  C = 1

  RA = yksi(A)
  RB = kaksi(B)
  RC = kolme(C)
  
  print*,RA+RB+RC
end program main
