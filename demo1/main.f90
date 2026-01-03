program main
   use jstringbuffer, only: StringBuffer
   use jstring, only: split, startswith
   implicit none

   character(len=300) :: buffer
   character(len=:), allocatable :: line, name, ssn, number
   character(len=*), parameter :: fname = "data.csv"
   integer :: unit, ios
   type(StringBuffer) :: sb

   number = "3"

   open (newunit=unit, file=fname, status="old", action="read")
   do
      read (unit, '(a)', iostat=ios) buffer
      if (ios /= 0) then
         exit  !# break
      end if
      line = trim(buffer)
      sb = split(line, ";")
      name = sb%get(6)
      ssn = sb%get(9)
      if (startswith(ssn, number)) then
         print '(*(g0))', name, ";", ssn
      end if
   end do
   close (unit)
end program main
