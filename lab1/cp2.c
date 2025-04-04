#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/stat.h>

#define BUFFERSIZE 4096
#define COPYMODE 0644

void oops(char *, char *);

int main(int ac, char *av[])
{
	int in_fd, out_fd, n_chars;
	char buf[BUFFERSIZE];
	struct stat file1, file2;

	if(ac != 3){
		fprintf(stderr, "usage: %s source destination\n", *av);
		exit(1);
	}

	if((in_fd = open(av[1], O_RDONLY)) == -1)
		oops("Cannot open ", av[1]);

	if((out_fd = creat(av[2], COPYMODE)) == -1)
		oops("Cannot creat", av[2]); 	

	while((n_chars = read(in_fd, buf, BUFFERSIZE)) > 0)
		if(write(out_fd, buf, n_chars) != n_chars)
			oops("Write error to", av[2]);
	if(n_chars == -1)
		oops("Read error form ", av[1]);

	if(close(in_fd) == -1 || close(out_fd) == -1)
		oops("Error closing files", "");

	if(stat(av[1], &file1) != 0)
		oops("error", av[1]);

	if(stat(av[2], &file2) != 0)
		oops("error", av[2]);

	if(file1.st_dev == file2.st_dev) {
		fprintf(stderr, "cp: \'%s\' and \'%s\' are the same file\n", av[1], av[2]);
		exit(1);
	}

	return 0;
}

void oops(char *s1, char *s2){
	fprintf(stderr, "Error: %s ", s1);
	perror(s2);
	exit(1);
}
