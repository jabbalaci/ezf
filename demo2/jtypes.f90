module jtypes

! Various useful types.

   use iso_fortran_env, only: sp => real32, dp => real64
   implicit none
   private

   public :: sp, dp, String

   type :: String
      !# wrapper type (box) for variable-length strings
      character(len=:), allocatable :: s
   end type String

end module jtypes
