#include <stdlib.h>
#include <stdio.h>
#include <time.h>

void main(int argc, char *argv[]){
  srand(time(NULL));
  int i, a, b;
  for(i=1; i < (argc - 1); i+=2){
    a = atoi(argv[i]);
    b = atoi(argv[i+1]);
    printf("%d %d ", a, b);
    if(a < b){puts("<--");}else{puts("-->");}
  }
}
