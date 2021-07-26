program main
  use numerot
  implicit none
  real :: A(100), B(100), C(100)
  real :: R
  
  A = 1
  B = 1
  C = 1
  
  if (num_images().ne.3) STOP
  
  if (this_image().eq.1) R = yksi(A)
  if (this_image().eq.2) R = kaksi(A)
  if (this_image().eq.3) R = kolme(A)
  
  SYNC ALL()
  
  call co_sum(R)
  if (this_image().eq.1) print*,R
end program main
