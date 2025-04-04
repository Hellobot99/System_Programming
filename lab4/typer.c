#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>
#include <termios.h>

#define MAX_INPUT 1024
#define RED "\033[31m"
#define RESET "\033[0m"

int main(int argc, char *argv[]){
    int index = 0;
    char ch;

    if(argc!=2){
        fprintf(stderr,"Usage: %s \"target sentence\"\n",argv[0]);
        exit(EXIT_FAILURE);
    }

    const char *target = argv[1];
    char input [MAX_INPUT];
    
    printf("Type the following sentence:\n%s\n",target);
    printf("\nStart typing: ");
    fflush(stdout);

    // 세팅 바꾸기 
    struct termios new_attr, old_attr;
    tcgetattr(STDIN_FILENO, &old_attr);
    new_attr = old_attr;
    new_attr.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO,TCSANOW,&new_attr);

    struct timeval start,end;
    gettimeofday(&start,NULL);

    while(index < MAX_INPUT - 1){
        ch = getchar();
        if(ch == '\n' || ch == '\r'){
            break;
        }
        
        //백스페이스 들어오면 뒤로가서 " "으로 채우고 다시 뒤로가기
        if(ch == 127 || ch == 8){
            if(index > 0){
                index--;
                printf("\b \b");
                fflush(stdout);
            }
        }
        else{
            input[index] = ch;
            if(input[index] == target[index]){
                printf("%c",ch);
            }
            else{
                printf("%s%c%s",RED,ch,RESET);
            }

            index++;
            fflush(stdout);
        }
    }
    gettimeofday(&end,NULL);

    tcsetattr(STDIN_FILENO,TCSANOW,&old_attr);

    double elapsed = (double)(end.tv_sec - start.tv_sec) +
                     (double)(end.tv_usec - start.tv_usec) / 1e6;


    int target_len = strlen(target);
    int correct = 0;
    for(int i=0;i<index && i<target_len;i++){
        if(input[i] == target[i]) correct++;
    }

    double accuracy = 100.0*correct/target_len;
    double speed = index/elapsed;

    printf("\n\n=== Result ===\n");
    printf("Time taken: %.2f chars/sec\n",elapsed);
    printf("Typing speed: %.2f chars/sec\n",speed);
    printf("Acurracy: %.2f%%\n",accuracy);

    return 0;
}