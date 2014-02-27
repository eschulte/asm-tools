#include <stdio.h>
#include <stdlib.h>

int main(){
  char *line = NULL;
  int i;
  size_t size;
  while(getline(&line, &size, stdin) != -1){
    /* Prepare to print up to but not including the ':' */
    for(i=0; line[i]!=':'; i++){}
    line[i] = '\0';
    i++;
    /* print the remaining 4-byte integers on the line */
    printf("%s %d %d %d %d %d %d %d %d %d %d %d\n", line,
           (int)line[i+1+4],
           (int)line[i+1+8],
           (int)line[i+1+12],
           (int)line[i+1+16],
           (int)line[i+1+20],
           (int)line[i+1+24],
           (int)line[i+1+28],
           (int)line[i+1+32],
           (int)line[i+1+36],
           (int)line[i+1+40],
           (int)line[i+1+44]);
  }
  return 0;
}
