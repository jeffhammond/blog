module m
    use iso_c_binding, only: c_intptr_t
    type, bind(C) :: handle
        integer(kind=c_intptr_t) :: val
    end type handle

end module m

program p
    use m
    implicit none
    type(handle) :: h
    print*,'LOC: ',LOC(h),LOC(h%val)
end program p
