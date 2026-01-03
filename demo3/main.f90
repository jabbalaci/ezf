program example_jsys
   use jsys, only: argc, argv
   implicit none
   integer :: i

   do i = 0, argc()
      print '(*(g0))', i, ": ", argv(i)
   end do
end program
