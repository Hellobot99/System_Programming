#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>
#include<fcntl.h>
#include <ctype.h>

#define MAX_LINE 1024
#define MAX_ARGS 64
#define MAX_BLOCK_LINES 32
#define MAX_VARS 64

typedef struct {
    char name[64];
    char value[256];
} Variable;

Variable local_vars[MAX_VARS];
int local_var_count = 0;

Variable global_vars[MAX_VARS];
int global_var_count = 0;

const char* get_var_value(const char* name) {
    for(int i=0;i<local_var_count;i++){
        if(strcmp(local_vars[i].name, name) == 0){
            return local_vars[i].value;
        }
    }
    for(int i=0;i<global_var_count;i++){
        if(strcmp(global_vars[i].name, name) == 0){
            return global_vars[i].value;
        }
    }
    const char* env = getenv(name);
    return env ? env : "";
}

void set_local_var(const char* name, const char* value) {
    for(int i=0;i<local_var_count;i++){
        if(strcmp(local_vars[i].name, name) == 0){
            strncpy(local_vars[i].value, value, sizeof(local_vars[i].value));
            return;
        }
    }
    if(local_var_count < MAX_VARS) {
        strncpy(local_vars[local_var_count].name, name, sizeof(local_vars[local_var_count].name));
        strncpy(local_vars[local_var_count].value, value, sizeof(local_vars[local_var_count].value));
        local_var_count++;
    } else {
        fprintf(stderr, "Error: Too many local variables (max %d)\n", MAX_VARS);
    }
}

void set_global_var(const char* name, const char* value) {
    if(value == NULL) value = "";
    setenv(name, value, 1);
    for(int i=0;i<global_var_count;i++){
        if(strcmp(global_vars[i].name, name) == 0){
            strncpy(global_vars[i].value, value, sizeof(global_vars[i].value));
            return;
        }
    }
    if(global_var_count < MAX_VARS) {
        strncpy(global_vars[global_var_count].name, name, sizeof(global_vars[global_var_count].name));
        strncpy(global_vars[global_var_count].value, value, sizeof(global_vars[global_var_count].value));
        global_var_count++;
    } else {
        fprintf(stderr, "Error: Too many global variables (max %d)\n", MAX_VARS);
    }
}

void expand_variables(char* line) {
    char buffer[MAX_LINE];
    int bi = 0;
    for(int i=0;line[i] != '\0';) {
        if(line[i] == '$') {
            i++;
            char varname[64];
            int vi = 0;
            while(isalnum(line[i]) || line[i] == '_') {
                varname[vi++] = line[i++];
            }
            varname[vi] = '\0';
            const char* val = get_var_value(varname);
            for(int j=0;val[j] != '\0';j++) {
                buffer[bi++] = val[j];
            }
        } 
        else {
            buffer[bi++] = line[i++];
        }
    }
    buffer[bi] = '\0';
    strncpy(line, buffer, MAX_LINE);
}

void parse_command(char *line, char **args) {
    expand_variables(line);
    int i=0;
    char *token = strtok(line, " \t\n");
    while(token != NULL && i < MAX_ARGS - 1) {
        args[i++] = token;
        token = strtok(NULL, " \t\n");
    }
    args[i] = NULL;

    if(token != NULL)
        fprintf(stderr, "Warning: too many arguments (max %d); some were ignored\n", MAX_ARGS - 1);
}

int execute_external_command(char **args) {
    int input_fd = -1, output_fd = -1;
    char *clean_args[MAX_ARGS];
    int j = 0;

    for (int i = 0; args[i] != NULL; i++) {
        if (strcmp(args[i], "<") == 0 && args[i + 1]) {
            input_fd = open(args[i + 1], O_RDONLY);
            if (input_fd < 0) {
                perror("open for input");
                return -1;
            }
            i++;
        } else if (strcmp(args[i], ">") == 0 && args[i + 1]) {
            output_fd = open(args[i + 1], O_WRONLY | O_CREAT | O_TRUNC, 0644);
            if (output_fd < 0) {
                perror("open for output");
                return -1;
            }
            i++;
        } else {
            clean_args[j++] = args[i];
        }
    }
    clean_args[j] = NULL;

    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        return -1;
    } else if (pid == 0) {
        if (input_fd != -1) {
            dup2(input_fd, STDIN_FILENO);
            close(input_fd);
        }
        if (output_fd != -1) {
            dup2(output_fd, STDOUT_FILENO);
            close(output_fd);
        }
        execvp(clean_args[0], clean_args);
        fprintf(stderr, "%s: command not found\n", clean_args[0]);
        exit(1);
    } else {
        int status;
        waitpid(pid, &status, 0);
        return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
    }
}

void execute_command(char **args) {
    if (args[0] == NULL) return;

    if (strchr(args[0], '=') && args[0][0] != '=') {
        char *eq = strchr(args[0], '=');
        *eq = '\0';
        set_local_var(args[0], eq + 1);
        return;
    }

    if (strcmp(args[0], "exit") == 0) {
        exit(0);
    }

    if (strcmp(args[0], "export") == 0) {
        for (int i = 1; args[i]; i++) {
            char *eq = strchr(args[i], '=');
            if (eq) {
                *eq = '\0';
                set_global_var(args[i], eq + 1);
            } else {
                const char* val = get_var_value(args[i]);
                set_global_var(args[i], val);
            }
        }
        return;
    }

    if (strcmp(args[0], "set") == 0) {
        for (int i = 0; i < local_var_count; i++) {
            printf("%s=%s\n", local_vars[i].name, local_vars[i].value);
        }
        for (int i = 0; i < global_var_count; i++) {
            printf("export %s=%s\n", global_vars[i].name, global_vars[i].value);
        }
        return;
    }

    execute_external_command(args);
}

int is_blank_line(const char *line) {
    while (*line) {
        if (!isspace(*line)) return 0;
        line++;
    }
    return 1;
}

void handle_if_block(char *if_line, FILE *input) {
    char cond_line[MAX_LINE];
    strncpy(cond_line, if_line + 3, MAX_LINE);
    cond_line[MAX_LINE - 1] = '\0';

    char line[MAX_LINE];
    if (!fgets(line, sizeof(line), input)) {
        fprintf(stderr, "Syntax error: expected 'then'\n");
        return;
    }
    char *trimmed = strtok(line, " \t\n");
    if (!trimmed || strcmp(trimmed, "then") != 0) {
        fprintf(stderr, "Syntax error: expected 'then'\n");
        return;
    }

    char block[MAX_BLOCK_LINES][MAX_LINE];
    int count = 0;
    int found_fi = 0;

    while (fgets(line, sizeof(line), input)) {
        if (is_blank_line(line)) continue;
        char tmp[MAX_LINE];
        strncpy(tmp, line, MAX_LINE);
        tmp[MAX_LINE - 1] = '\0';
        char *first_token = strtok(tmp, " \t\n");
        if (first_token && strcmp(first_token, "fi") == 0) {
            found_fi = 1;
            break;
        }
        if (count >= MAX_BLOCK_LINES) {
            fprintf(stderr, "Error: too many lines in if block\n");
            return;
        }
        strncpy(block[count], line, MAX_LINE);
        block[count][MAX_LINE - 1] = '\0';
        count++;
    }

    if (!found_fi) {
        fprintf(stderr, "Syntax error: missing 'fi'\n");
        return;
    }

    char *args[MAX_ARGS];
    parse_command(cond_line, args);
    int cond_result = execute_external_command(args);
    if (cond_result == 0) {
        for (int i = 0; i < count; i++) {
            parse_command(block[i], args);
            execute_command(args);
        }
    }
}

void process_line(char *line, FILE *input) {
    char *args[MAX_ARGS];
    if (is_blank_line(line)) return;
    if (strncmp(line, "if ", 3) == 0) {
        handle_if_block(line, input);
    } else {
        parse_command(line, args);
        execute_command(args);
    }
}

int main(int argc, char *argv[]) {
    char line[MAX_LINE];

    if (argc == 2) {
        FILE *fp = fopen(argv[1], "r");
        if (!fp) {
            perror("fopen");
            return 1;
        }
        while (fgets(line, sizeof(line), fp))
            process_line(line, fp);
        fclose(fp);
        return 0;
    }

    while (1) {
        printf("mini-shell> ");
        fflush(stdout);
        if (fgets(line, sizeof(line), stdin) == NULL)
            break;
        process_line(line, stdin);
    }

    return 0;
}