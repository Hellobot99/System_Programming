#include <stdio.h>

//#define BUF_SIZE 1024

int main()
{
#ifdef BUF_SIZE
	int array[100];
#else
#error BUF_SIZE is not defined
#endif
	return 0;
}


