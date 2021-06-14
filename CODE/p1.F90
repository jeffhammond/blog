module numerot
  contains
    function yksi(X) result(R)
      implicit none
      real :: X(100), R
      R = norm2(X)
    end function yksi
    function kaksi(X) result(R)
      implicit none
      real :: X(100), R
      R = 2*norm2(X)
    end function kaksi
    function kolme(X) result(R)
      implicit none
      real :: X(100), R
      R = 3*norm2(X)
    end function kolme
end module numerot

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
