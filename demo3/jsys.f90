module jsys

! Imitating Python's sys module.

   implicit none
   private

   public :: argc, argv

contains

   function argc() result(result)
      !# Number of command-line arguments provided by the user.
      !# $ ./a.out                    # argc() returns 0
      !# $ ./a.out hello              # argc() returns 1
      integer :: result

      result = command_argument_count()
   end function

   function argv(idx) result(result)
      !# Returns the i^{th} command-line argument.
      !# If such an argument doesn't exist (`i` is too high), then it returns an empty string.
      !# argv(0) is the name of the executed program, like in C or Python
      integer, intent(in) :: idx
      character(len=:), allocatable :: result
      character(len=256) :: buffer

      if (idx > command_argument_count()) then
         result = ""
         return
      end if
      !# else
      call get_command_argument(idx, buffer)
      result = trim(buffer)
   end function

end module jsys
