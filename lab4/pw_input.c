#include <stdio.h>
#include <termio.h>
#include <unistd.h>
#include <string.h>

#define MAX_PASSWORD_LENGTH 128

int main(){
    char password[MAX_PASSWORD_LENGTH];
    int index = 0;
    char ch;

    struct termios old_attr, new_attr;

    //나중에 다시 복구 해야되서 현재꺼 저장
    tcgetattr(STDIN_FILENO, &old_attr);
    new_attr = old_attr;

    new_attr.c_lflag &= ~(ICANON | ECHO);
    //한개 씩 입력받고 에코 끈 세팅으로 설정
    tcsetattr(STDIN_FILENO, TCSANOW, &new_attr);
    printf("Enter your password: ");
    fflush(stdout);

    //입력받음
    while(index < MAX_PASSWORD_LENGTH - 1){
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
            password[index++] = ch;
            printf("*");
            fflush(stdout);
        }
    }
    password[index] = '\0';

    //터미널 세팅 다시 복구
    tcsetattr(STDIN_FILENO, TCSANOW, &old_attr);

    printf("\nPassword entered: %s\n", password);

    return 0;
}