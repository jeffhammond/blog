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
