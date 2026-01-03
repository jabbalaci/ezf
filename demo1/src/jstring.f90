! useful functions in Fortran:
! scan()            - Finds FIRST occurrence of ANY character in a set
! verify(text, set) - Finds FIRST character NOT in a set (optional: back)
!                     return values: 0 - OK, not 0 - first char not in the set

module jstring

! Working with strings and characters.

   use jconstants
   use jassert
   use jsys, only: stderr
   use jstringbuffer, only: StringBuffer
   implicit none
   private

   public :: islower, isupper, isspace, isdigit, isascii, &
             lower, upper, find, rfind, is_in, strip, lstrip, rstrip, &
             startswith, endswith, replace, slice, rev, &
             split

contains

   function is_in(sub, text) result(result)
      !# Check if a substring is in a text.
      !# Returns true or false.
      !# Like in Python: if "sub" in "subprogram": ...
      character(len=*), intent(in) :: sub
      character(len=*), intent(in) :: text
      logical :: result

      if (len(sub) == 0) then
         result = .true.
         return
      end if

      result = index(text, sub) > 0
   end function

   function find(text, sub) result(result)
      !# Find the position of a substring in a string.
      !# Returns 0 if not found.
      character(len=*), intent(in) :: text
      character(len=*), intent(in) :: sub
      integer :: result

      result = index(text, sub)
   end function

   function rfind(text, sub) result(result)
      !# Find the *last* position of a substring in a string.
      !# Returns 0 if not found.
      character(len=*), intent(in) :: text
      character(len=*), intent(in) :: sub
      integer :: result

      result = index(text, sub, back=.true.)
   end function

   function isdigit(s) result(result)
      !# Are all the characters digits?
      character(len=*), intent(in) :: s
      logical :: result

      if (len(s) == 0) then
         result = .false.
         return
      end if

      result = (verify(s, DIGITS) == 0)
   end function

   function isascii(s) result(result)
      !# Return true if the string is empty or all characters in the string are ASCII,
      !# false otherwise. ASCII characters have code points in the range [0, 127].
      character(len=*), intent(in) :: s
      logical :: result
      integer :: i

      do i = 1, len(s)
         if (iachar(s(i:i)) > 127) then
            result = .false.
            return
         end if
      end do
      result = .true.
   end function

   function isspace(s) result(result)
      !# Is the string/character a whitespace?
      !# Whitespaces: SPACE, TAB, LF (newline), CR (carriage return)
      character(len=*), intent(in) :: s
      logical :: result
      character :: c
      integer :: i

      if (len(s) == 0) then
         result = .false.
         return
      end if

      do i = 1, len(s)
         c = s(i:i)
         if (.not. (c == ' ' .or. c == TAB .or. c == LF .or. c == CR)) then
            result = .false.
            return
         end if
      end do
      result = .true.
   end function

   function islower(s) result(result)
      !# Is the string/character lowercased?
      !# It only works with ASCII text.
      character(len=*), intent(in) :: s
      logical :: result
      integer :: code  !# ASCII code of a character
      integer :: i

      if (len(s) == 0) then
         result = .false.
         return
      end if

      do i = 1, len(s)
         code = iachar(s(i:i))
         if ((code < 97) .or. (code > 122)) then
            result = .false.
            return
         end if
      end do
      result = .true.
   end function

   function isupper(s) result(result)
      !# Is the string/character uppercased?
      !# It only works with ASCII text.
      character(len=*), intent(in) :: s
      logical :: result
      integer :: code  !# ASCII code of a character
      integer :: i

      if (len(s) == 0) then
         result = .false.
         return
      end if

      do i = 1, len(s)
         code = iachar(s(i:i))
         if ((code < 65) .or. (code > 90)) then
            result = .false.
            return
         end if
      end do
      result = .true.
   end function

   function upper(s) result(t)
      !# Returns string `s` in uppercase.
      !# It only works with ASCII text.
      character(len=*), intent(in) :: s
      character(len=len(s)) :: t
      integer :: i, code

      t = s
      do i = 1, len(t)
         code = iachar(t(i:i))
         if ((code >= 97) .and. (code <= 122)) then
            t(i:i) = achar(iachar(t(i:i)) - 32)
         end if
      end do
   end function

   function lower(s) result(t)
      !# Returns string `s` in lowercase.
      !# It only works with ASCII text.
      character(len=*), intent(in) :: s
      character(len=len(s)) :: t
      integer :: i, code

      t = s
      do i = 1, len(t)
         code = iachar(t(i:i))
         if ((code >= 65) .and. (code <= 90)) then
            t(i:i) = achar(iachar(t(i:i)) + 32)
         end if
      end do
   end function

   function strip(s) result(result)
      !# Remove leading and trailing whitespaces.
      character(len=*), intent(in) :: s
      character(len=:), allocatable :: result
      integer :: left, right

      left = verify(s, WHITESPACE)
      right = verify(s, WHITESPACE, back=.true.)

      if (left == 0 .or. right == 0) then
         result = ""
         return
      end if

      result = s(left:right)
   end function

   function lstrip(s) result(result)
      !# Remove leading whitespaces (from the beginning).
      character(len=*), intent(in) :: s
      character(len=:), allocatable :: result
      integer :: left, right

      left = verify(s, WHITESPACE)
      right = len(s)

      if (left == 0 .or. right == 0) then
         result = ""
         return
      end if

      result = s(left:right)
   end function

   function rstrip(s) result(result)
      !# Remove trailing whitespaces (from the end).
      character(len=*), intent(in) :: s
      character(len=:), allocatable :: result
      integer :: left, right

      left = 1
      right = verify(s, WHITESPACE, back=.true.)

      if (right == 0) then
         result = ""
         return
      end if

      result = s(left:right)
   end function

   function startswith(text, sub) result(result)
      !# Check if the string starts with a given substring.
      character(len=*), intent(in) :: text
      character(len=*), intent(in) :: sub
      logical :: result

      result = (index(text, sub) == 1)
   end function

   function endswith(text, sub) result(result)
      !# Check if the string ends with a given substring.
      character(len=*), intent(in) :: text
      character(len=*), intent(in) :: sub
      logical :: result
      integer :: pos

      pos = index(text, sub, back=.true.)
      if (pos == 0) then  !# not found
         result = .false.
         return
      end if
      !# else
      result = (pos == len(text) - len(sub) + 1)
   end function

   function replace(s, old, new, count) result(t)
      !# In `s`, replace every occurrence of `old` with `new`.
      !# `count` (optional): number of replaces
      !# Like Python's str.replace()
      !# Not efficient for very long strings (it has lots of slicings and concatenations).
      character(len=*), intent(in) :: s, old, new
      character(len=:), allocatable :: t
      integer, intent(in), optional :: count
      integer :: i, old_len, s_len, limit, counter
      logical :: do_changes

      limit = -1
      if (present(count)) limit = count

      if (limit == 0) then
         t = s
         return
      end if

      t = ""
      s_len = len(s)
      old_len = len(old)

      do_changes = .true.
      counter = 0
      i = 1
      do while (i <= s_len)
         if (do_changes .and. s(i:min(s_len, i + old_len - 1)) == old) then
            t = t//new
            i = i + old_len
            if (limit > 0) then  !# taking `count` into account
               counter = counter + 1  !# number of replaces
               if (counter >= limit) then
                  do_changes = .false.
               end if
            end if
         else
            t = t//s(i:i)
            i = i + 1
         end if
      end do
   end function

   function slice(s, start, end, step) result(t)
      !# String slicing similar to Python.
      !# Start and end positions must be positive. Step can be negative.
      !# If `end` is too big, then it'll be truncated to the string's length.
      !# Not efficient for very long strings (it has lots of concatenations).
      character(len=*), intent(in) :: s
      integer, intent(in), optional :: start, end, step
      character(len=:), allocatable :: t
      integer :: start_val, end_val, step_val
      integer :: i, s_len

      t = ""
      s_len = len(s)

      step_val = 1          !# default value
      if (present(step)) step_val = step
      call assert(step_val /= 0, "ValueError: slice step cannot be zero")

      if (step_val > 0) then
         start_val = 1      !# default value
         end_val = len(s)   !# default value
      else
         !# negative step
         start_val = len(s) !# default value
         end_val = 1        !# default value
      end if

      if (present(start)) start_val = start
      call assert(start_val >= 1, "ValueError: slice start position must be positive")
      if (present(end)) end_val = end
      call assert(end_val >= 1, "ValueError: slice end position must be positive")

      if (step_val > 0) then
         !# positive step
         i = start_val
         do while (i <= min(s_len, end_val))
            t = t//s(i:i)
            i = i + step_val
         end do
      else
         !# negative step
         i = min(start_val, s_len)
         do while (i >= max(1, end_val))
            t = t//s(i:i)
            i = i + step_val  !# step is negative, so `i` will be decremented
         end do
      end if
   end function

   function rev(s) result(t)
      !# Returns the reversed string, e.g. "abc" -> "cba"
      !# Works with ASCII only.
      character(len=*), intent(in) :: s
      character(len=len(s)) :: t
      character tmp
      integer :: i, j

      t = s
      i = 1; j = len(t)
      do while (i < j)
         tmp = t(i:i)
         t(i:i) = t(j:j)
         t(j:j) = tmp
         i = i + 1
         j = j - 1
      end do
   end function

   ! function number_of_tokens_with_whitespaces(s) result(counter)  !# private, helper function
   !    character(len=*), intent(in) :: s
   !    integer :: counter
   !    integer, parameter :: OUTSIDE = 0
   !    integer, parameter :: INSIDE = 1
   !    integer :: i, state, start

   !    counter = 0
   !    state = OUTSIDE
   !    do i = 1, len(s)
   !       if (.not. isspace(s(i:i))) then
   !          if (state == OUTSIDE) then
   !             state = INSIDE
   !             start = i
   !          end if
   !       else
   !          !# if isspace
   !          if (state == INSIDE) then
   !             state = OUTSIDE
   !             counter = counter + 1
   !             ! write (stderr, '(*(g0))') "'", s(start:i - 1), "'"
   !          end if
   !       end if
   !    end do
   !    if (state == INSIDE) then
   !       counter = counter + 1
   !       ! write (stderr, '(*(g0))') "'", s(start:len(s)), "'"
   !    end if
   ! end function

   ! function number_of_tokens(s, delimiter) result(counter)
   !    character(len=*), intent(in) :: s
   !    character(len=*), intent(in), optional :: delimiter
   !    integer :: i, counter, len_s, len_delimiter, state, start
   !    integer, parameter :: OUTSIDE = 0
   !    integer, parameter :: INSIDE = 1

   !    if (.not. present(delimiter)) then
   !       !# consider whitespaces between the tokens
   !       counter = number_of_tokens_with_whitespaces(s)
   !       return
   !    end if
   !    !# else, a delimiter is present
   !    len_delimiter = len(delimiter)
   !    call assert(len_delimiter > 0, "ValueError: empty separator")

   !    counter = 0
   !    len_s = len(s)
   !    state = INSIDE
   !    start = 1
   !    i = 1
   !    do while (i <= len_s)
   !       if (s(i:min(len_s, i + len_delimiter - 1)) == delimiter) then
   !          state = OUTSIDE
   !          counter = counter + 1
   !          ! write (stderr, '(*(g0))') "'", s(start:i - 1), "'"
   !          i = i + len_delimiter
   !          start = i
   !       else
   !          !# `i` doesn't stand at the beginning of a delimiter
   !          if (state == OUTSIDE) then
   !             state = INSIDE
   !             start = i
   !          end if
   !          i = i + 1
   !       end if
   !    end do
   !    if (endswith(s, delimiter)) then
   !       state = INSIDE
   !    end if
   !    if (state == INSIDE) then
   !       counter = counter + 1
   !       ! write (stderr, '(*(g0))') "'", s(start:len(s)), "'"
   !    end if
   ! end function

   function split_with_whitespaces(s) result(sb)  !# private, helper function
      !# When no delimiter is provided.
      !# Like in Python: result = s.split()
      character(len=*), intent(in) :: s
      type(StringBuffer) :: sb
      integer :: counter
      integer, parameter :: OUTSIDE = 0
      integer, parameter :: INSIDE = 1
      integer :: i, state, start

      counter = 0
      state = OUTSIDE
      do i = 1, len(s)
         if (.not. isspace(s(i:i))) then
            if (state == OUTSIDE) then
               state = INSIDE
               start = i
            end if
         else
            !# if isspace
            if (state == INSIDE) then
               state = OUTSIDE
               counter = counter + 1
               ! write (stderr, '(*(g0))') "'", s(start:i - 1), "'"
               call sb%append(s(start:i - 1))
            end if
         end if
      end do
      if (state == INSIDE) then
         counter = counter + 1
         ! write (stderr, '(*(g0))') "'", s(start:len(s)), "'"
         call sb%append(s(start:len(s)))
      end if
   end function

   function split(s, delimiter) result(sb)
      !# Similar to Python's str.split() method.
      !# It returns a StringBuffer, which is like a list of strings.
      character(len=*), intent(in) :: s
      character(len=*), intent(in), optional :: delimiter
      type(StringBuffer) :: sb
      integer :: i, counter, len_s, len_delimiter, state, start
      integer, parameter :: OUTSIDE = 0
      integer, parameter :: INSIDE = 1

      if (.not. present(delimiter)) then
         !# consider whitespaces between the tokens
         sb = split_with_whitespaces(s)
         return
      end if
      !# else, a delimiter is present
      len_delimiter = len(delimiter)
      call assert(len_delimiter > 0, "ValueError: empty separator")

      counter = 0
      len_s = len(s)
      state = INSIDE
      start = 1
      i = 1
      do while (i <= len_s)
         if (s(i:min(len_s, i + len_delimiter - 1)) == delimiter) then
            state = OUTSIDE
            counter = counter + 1
            ! write (stderr, '(*(g0))') "'", s(start:i - 1), "'"
            call sb%append(s(start:i - 1))
            i = i + len_delimiter
            start = i
         else
            !# `i` doesn't stand at the beginning of a delimiter
            if (state == OUTSIDE) then
               state = INSIDE
               start = i
            end if
            i = i + 1
         end if
      end do
      if (endswith(s, delimiter)) then
         state = INSIDE
      end if
      if (state == INSIDE) then
         counter = counter + 1
         ! write (stderr, '(*(g0))') "'", s(start:len(s)), "'"
         call sb%append(s(start:len(s)))
      end if
   end function

end module jstring
