#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <dirent.h>
#include <string.h>

#define BUFFERSIZE 4096
#define COPYMODE 0644

void oops(char*, char*);
void check_type(char*, char*);
void copy_file(char*, char*);
void copy_dir(char*, char*);

int main(int ac, char* av[]) {
    if (ac != 3) {
        fprintf(stderr, "usage: %s source destination\n", *av);
        exit(1);
    } 

    check_type(av[1], av[2]);

    return 0;
}

void check_type(char* src, char* dest) {
    struct stat file1;

    if (stat(src, &file1) != 0)
        oops("Cannot stat", src);
    if (S_ISDIR(file1.st_mode)) 
        copy_dir(src, dest);
    else
        copy_file(src, dest);
}

void copy_dir(char* src, char* dest) {
    //printf("copying dir %s -> %s\n", src, dest);
    struct stat file1;
    if (stat(src, &file1) != 0)
        oops("Cannot stat", src);

    mkdir(dest, file1.st_mode);
    DIR* dir_ptr;
    struct dirent* direntp;

    if ((dir_ptr = opendir(src)) == NULL)
        fprintf(stderr, "lsl: cannot open %s\n", src);

    else {
        while ((direntp = readdir(dir_ptr)) != NULL) {
            if (strcmp(direntp->d_name, ".") == 0 || strcmp(direntp->d_name, "..") == 0)
                continue;
            char new_src[100]="",new_dest[100] = "";

            strcat(new_src, src);
            strcat(new_src, "/");
            strcat(new_src, direntp->d_name);

            strcpy(new_dest, dest);
            strcat(new_dest, "/");
            strcat(new_dest, direntp->d_name);

            check_type(new_src, new_dest);
         }
        closedir(dir_ptr);
    }
}

void copy_file(char* src, char* dest) {
    //printf("copying file %s -> %s\n", src, dest);
    int in_fd, out_fd, n_chars;
    char buf[BUFFERSIZE];
    struct stat file1, file2;

    if (stat(src, &file1) != 0)
        oops("Cannot stat", (char*)src);

    if (stat(dest, &file2) == 0 && file1.st_ino == file2.st_ino && file1.st_dev == file2.st_dev) {
        fprintf(stderr, "cp: '%s' and '%s' are the same file\n", src, dest);
        exit(1);
    }

    if ((in_fd = open(src, O_RDONLY)) == -1)
        oops("Cannot open", (char*)src);

    if ((out_fd = creat(dest, COPYMODE)) == -1)
        oops("Cannot creat", (char*)dest);

    while ((n_chars = read(in_fd, buf, BUFFERSIZE)) > 0)
        if (write(out_fd, buf, n_chars) != n_chars)
            oops("Write error to", (char*)dest);
    if (n_chars == -1)
        oops("Read error from", (char*)src);

    if (close(in_fd) == -1 || close(out_fd) == -1)
        oops("Error closing files", "");

    chmod(dest, file1.st_mode);
}

void oops(char* s1, char* s2) {
    fprintf(stderr, "Error: %s ", s1);
    perror(s2);
    exit(1);
}
