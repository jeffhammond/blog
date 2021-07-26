program main
  use numerot
  implicit none
  real :: A(100), B(100), C(100)
  real :: RA, RB, RC
  integer :: k
  
  A = 1
  B = 1
  C = 1

  do concurrent (k=1:3)

    if (k.eq.1) RA = yksi(A)
    if (k.eq.2) RB = kaksi(B)
    if (k.eq.3) RC = kolme(C)

  end do
  
  print*,RA+RB+RC
end program main
