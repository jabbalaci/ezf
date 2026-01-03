program main
   use my_mod
   use jconstants, only: PI
   implicit none

   call hello()
   print *, PI
end program main

module my_mod
   implicit none
   private

   public :: hello

contains

   subroutine hello()
      print *, "hello world"
   end subroutine

end module my_mod
