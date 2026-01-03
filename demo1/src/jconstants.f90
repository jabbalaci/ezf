module jconstants

! Some useful constants.

   use jtypes, only: dp
   implicit none

   real(dp), parameter :: PI = acos(-1.0_dp)
   real(dp), parameter :: M_PI = PI
   !# see https://jabbalaci.github.io/teaching-assets/hun/python/ascii/asciichart.png
   character, parameter :: NUL = achar(0)    !# '\0'
   character, parameter :: BS = achar(8)     !# backspace
   character, parameter :: TAB = achar(9)    !# '\t'
   character, parameter :: LF = achar(10)    !# '\n'
   character, parameter :: CR = achar(13)    !# '\r'
   character, parameter :: ESC = achar(27)   !#
   character(len=*), parameter :: WHITESPACE = " "//TAB//LF//CR
   character(len=*), parameter :: DIGITS = "0123456789"
   character(len=*), parameter :: ASCII_LETTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
   character(len=*), parameter :: ASCII_LOWERCASE = "abcdefghijklmnopqrstuvwxyz"
   character(len=*), parameter :: ASCII_UPPERCASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

end module jconstants
