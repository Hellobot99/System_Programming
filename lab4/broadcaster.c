#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#define PTS_PATH "/dev/pts/"
#define MAX_PATH 256

int main(int argc, char *argv[]){
    if(argc < 2){
        fprintf(stderr, "Usage: %s <message>\n",argv[0]);
        exit(EXIT_FAILURE);
    }
    char *message = argv[1];

    DIR* D = opendir(PTS_PATH);
    if(!D){
        perror("error");
        exit(EXIT_FAILURE);
    }

    struct dirent *dp;
    for(dp = readdir(D); dp!=NULL; dp = readdir(D)){
        
        if(strcmp(dp->d_name,".") == 0 || strcmp(dp->d_name,"..") == 0 || strcmp(dp->d_name,"ptmx") == 0){
            continue;
        }

        char send_message[100] = "[Broadcast] ";
        char m[100];
        strcpy(m,message);
        strcat(send_message,m);
        strcat(send_message,"\n\r");

        char path[MAX_PATH] = PTS_PATH;
        strcat(path,dp->d_name);

        int fd = open(path, O_WRONLY);
        if(fd==-1){
            continue;
        }
       
        write(fd,send_message,strlen(send_message));

        close(fd);
    }

    closedir(D);
    
    return 0;
}