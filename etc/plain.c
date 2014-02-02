#include <stdio.h>

int main(int argc, char *argv[])
{
  int a,b;
  a = 1;
  b = 2;
  if (b > a) { printf("right %d\n", a + b); }
  else       { printf("left  %d\n", a + b); }
  return 0;
}
