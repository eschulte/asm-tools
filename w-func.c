#include <stdio.h>

void a_function(){
  int a,b;
  a = 3;
  b = 4;
  if (b > a) { printf("right in func %d\n", a + b); }
  else       { printf("left in func  %d\n", a + b); }
}

int main(int argc, char *argv[])
{
  int a,b;
  a = 1;
  b = 2;
  if (b > a) { printf("right %d\n", a + b); }
  else       { printf("left  %d\n", a + b); }
  a_function();
  return 0;
}
