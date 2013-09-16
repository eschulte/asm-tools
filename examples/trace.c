#include <stdio.h>

FILE* __tracer_fd;

int main(int argc, char *argv[])
{
  if (__tracer_fd == NULL) {__tracer_fd = fopen("trace.out","w");}
  fputs("LFB0\n", __tracer_fd);
  int a,b;
  a = 1;
  b = 2;
  printf("hello %d\n", a + b);
  return 0;
}
