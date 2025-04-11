#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>

#define MAX_LINES 100
#define MAX_LINES_LEN 256
#define AUTOSAVE_FILE "autosave.txt"

char *lines[MAX_LINES];
int line_count = 0;
int cur = 0;

//define signal handlers
void save(int);
void quit(int);

int main()
{
    //register signal handlers
    signal(SIGINT, quit);
    signal(SIGALRM, save);
    //start alarm for autosave
    alarm(5);

    printf("Enter txt (Ctrl+C to quit):\n");

    char buffer[MAX_LINES_LEN];
    while(1)
    {
        if(fgets(buffer,MAX_LINES_LEN,stdin)!=NULL){
            if(line_count < MAX_LINES){
                lines[line_count] = strdup(buffer);
                line_count++;
            }
            else printf("Reached maximum number of lines.\n");
        }
    }

    return 0;
}

void save(int signum)
{
    FILE *f;
    if((f = fopen(AUTOSAVE_FILE,"a")) == NULL) {
        printf("Error\n");
        exit(1);
    }
    for(; cur < line_count; cur++){
        fwrite(lines[cur],sizeof(char),strlen(lines[cur]),f);
    }
   

    fclose(f);
    alarm(5);
}

void quit(int signum)
{
    printf("\n[i] Exit signal received. Saving final version...\n");
    save(signum);
    exit(1);
}
