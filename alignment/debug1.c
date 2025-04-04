#include <stdio.h>

int main()
{
#ifdef PS2
	printf("PS2 mouse driver module\n");
#elif defined USB 
	printf("USB mouse driver module\n");
#else
	printf("Not supported device\n");
#endif
	return 0;
}

