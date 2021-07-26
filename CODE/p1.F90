module numerot
  contains
    pure real function yksi(X)
      implicit none
      real, intent(in) :: X(100)
      !real, intent(out) :: R
      yksi = norm2(X)
    end function yksi
    pure real function kaksi(X)
      implicit none
      real, intent(in) :: X(100)
      kaksi = 2*norm2(X)
    end function kaksi
    pure real function kolme(X)
      implicit none
      real, intent(in) :: X(100)
      kolme = 3*norm2(X)
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
