module jstringbuffer

! A stringbuffer for storing variable-length strings.

   use jtypes, only: String
   use jassert, only: assert
   implicit none
   private
   integer, parameter :: INITIAL_CAPACITY = 8

   public :: StringBuffer

   type :: StringBuffer
      integer, private :: size = 0  ! number of elems
      integer, private :: capacity = INITIAL_CAPACITY  ! initial capacity
      type(String), private, allocatable :: data(:)
   contains
      procedure :: append, debug, number_of_elems, total_length, join, to_string, &
         equals, clear, get
   end type StringBuffer

contains

   subroutine clear(self)
      !# Resets the stringbuffer to its initial state.
      !# This way, you can reuse the same object.
      class(StringBuffer), intent(inout) :: self
      self%size = 0
      self%capacity = INITIAL_CAPACITY
      if (allocated(self%data)) then
         deallocate (self%data)
      end if
   end subroutine

   function total_length(self) result(result)
      !# Sum of the length of every element in the stringbuffer.
      !# If we call to_string(), we get a string of this length.
      class(StringBuffer), intent(in) :: self
      integer :: i, result

      result = 0
      do i = 1, self%size
         result = result + len(self%data(i)%s)
      end do
   end function

   function number_of_elems(self) result(result)
      !# Number of elements (boxes) in the stringbuffer.
      !# This is NOT equivalent to the total length!
      class(StringBuffer), intent(in) :: self
      integer :: result
      result = self%size
   end function

   subroutine append(self, value)
      !# Append a string (in boxed format) to the end.
      class(StringBuffer), intent(inout) :: self
      character(len=*), intent(in) :: value
      type(String), allocatable :: temp(:)

      if (self%size == 0) then
         allocate (self%data(self%capacity))
      end if
      self%size = self%size + 1
      if (self%size > self%capacity) then
         self%capacity = self%capacity * 2
         allocate (temp(self%capacity))
         temp(1:self%size - 1) = self%data(1:self%size - 1)
         call move_alloc(temp, self%data)
      end if
      self%data(self%size) = String(value)
   end subroutine

   subroutine debug(self)
      !# Print the content to the stdout. For debug purposes.
      class(StringBuffer), intent(in) :: self
      integer :: i

      do i = 1, self%size
         print '(*(g0))', i, ": ", "'", self%data(i)%s, "'"
      end do
   end subroutine

   function get(self, i) result(result)
      !# Returns the string at position `i`
      class(StringBuffer), intent(in) :: self
      integer, intent(in) :: i
      character(len=:), allocatable :: result

      call assert(1 <= i .and. i <= self%size, "IndexError: index out of range")
      result = self%data(i)%s
   end function

   function to_string(self) result(result)
      !# Get the content of the stringbuffer as a string.
      class(StringBuffer), intent(in) :: self
      character(len=:), allocatable :: result
      integer :: i, j, length

      if (.not. allocated(self%data)) then
         result = ""
      else
         allocate (character(len=self%total_length()) :: result)
         j = 1
         do i = 1, self%size
            associate (s => self%data(i)%s)
               length = len(s)
               result(j:j + length - 1) = s
               j = j + length
            end associate
         end do
      end if
   end function

   function join(self, sep) result(result)
      !# Join the elements by a delimiter.
      !# The result is a string.
      class(StringBuffer), intent(in) :: self
      character(len=*), intent(in), optional :: sep
      character(len=:), allocatable :: result
      integer :: i, j, length, extra, len_alloc
      character(len=:), allocatable :: sep_val

      sep_val = ""  !# default value
      if (present(sep)) sep_val = sep

      if (.not. allocated(self%data)) then
         result = ""
      else
         extra = max(0, self%number_of_elems() - 1) * len(sep_val)
         len_alloc = self%total_length() + extra
         ! allocate (character(len=self%total_length() + extra) :: result)  ! compiler error
         allocate (character(len=len_alloc) :: result)  ! it's OK
         j = 1
         do i = 1, self%size
            associate (s => self%data(i)%s)
               if (i > 1) then
                  length = len(sep_val)
                  result(j:j + length - 1) = sep_val
                  j = j + length
               end if
               length = len(s)
               result(j:j + length - 1) = s
               j = j + length
            end associate
         end do
      end if
   end function

   function equals(self, other) result(result)
      !# Check if two stringbuffers have the same content.
      !# Returns true or false.
      class(StringBuffer), intent(in) :: self
      type(StringBuffer), intent(in) :: other
      logical :: result
      integer :: i

      if (self%number_of_elems() /= other%number_of_elems()) then
         result = .false.
         return
      end if
      !# else
      do i = 1, self%number_of_elems()
         if (self%data(i)%s /= other%data(i)%s) then
            result = .false.
            return
         end if
      end do
      result = .true.
   end function

end module jstringbuffer
