#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>
#include <signal.h>

#define MAXARGS 20
#define ARGLEN 100

void execute(char *arglist[]);
char *makestring(char *buf);

int main(){
    char * arglist[MAXARGS + 1];
    int numargs = 0;
    char argbuf[ARGLEN];

    signal(SIGINT, SIG_IGN);

    while(numargs < MAXARGS){
        printf("Arg[%d]? ", numargs);
        if(fgets(argbuf,ARGLEN,stdin) && *argbuf != '\n'){
            char *temp = makestring(argbuf);
            if(strcmp(temp, "exit") == 0){
                printf("Exiting shell.\n");
                exit(0);
            }
            else arglist[numargs++] = temp;
        }            
        else {
            if(numargs > 0){
                arglist[numargs] = NULL;
                execute(arglist);
                numargs = 0;
            }
        }
    }
    return 0;
}

void execute(char * arglist[]) {
    pid_t pid;
    int exitstatus;

    pid = fork();
    if(pid < 0){
        perror("fork failed");
        exit(1);
    }
    else if(pid == 0){
        signal(SIGINT, SIG_DFL);
        execvp(arglist[0], arglist);
        perror("execvp failed");
        exit(1);
    }
    else{
        while(wait(&exitstatus) != pid)
            ;
        printf("Child exited with status %d, signal %d\n", exitstatus >> 8, exitstatus & 0xFF);
    }    
}

char *makestring(char *buf) {
    buf[strcspn(buf, "\n")] = '\0';
    char *cp = malloc(strlen(buf) + 1);
    if(cp == NULL){
        fprintf(stderr, "no memory\n");
        exit(1);
    }
    strcpy(cp, buf);
    return cp;
}