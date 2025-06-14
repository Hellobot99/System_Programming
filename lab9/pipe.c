#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

#define MAX_ARGS 16

void parse_command(char* input, char** argv) {
    int i = 0;
    char* token = strtok(input, " ");
    while (token != NULL && i < MAX_ARGS - 1) {
        argv[i++] = token;
        token = strtok(NULL, " ");
    }
    argv[i] = NULL;
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <command1> <command2>\n", argv[0]);
        fprintf(stderr, "Example: %s \"ls -l\" \"sort\"\n", argv[0]);
        exit(1);
    }

    char cmd1_buf[256], cmd2_buf[256];
    strncpy(cmd1_buf, argv[1], sizeof(cmd1_buf));
    strncpy(cmd2_buf, argv[2], sizeof(cmd2_buf));

    char* cmd1_argv[MAX_ARGS];
    char* cmd2_argv[MAX_ARGS];

    parse_command(cmd1_buf, cmd1_argv);
    parse_command(cmd2_buf, cmd2_argv);

    int pipefd[2];
    if (pipe(pipefd) == -1) {
        perror("pipe");
        exit(1);
    }

    pid_t pid1 = fork();
    if (pid1 == 0) {
        close(pipefd[0]);
        dup2(pipefd[1], STDOUT_FILENO);
        close(pipefd[1]);

        execvp(cmd1_argv[0], cmd1_argv);
        perror("execvp cmd1 failed");
        exit(1);
    }

    pid_t pid2 = fork();
    if (pid2 == 0) {
        close(pipefd[1]);
        dup2(pipefd[0], STDIN_FILENO);
        close(pipefd[0]);

        execvp(cmd2_argv[0], cmd2_argv);
        perror("execvp cmd2 failed");
        exit(1);
    }

    close(pipefd[0]);
    close(pipefd[1]);
    waitpid(pid1, NULL, 0);
    waitpid(pid2, NULL, 0);

    return 0;
}
