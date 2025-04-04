#include <stdio.h>

//#define DEBUG_LEVEL 1

int main()
{
#if (DEBUG_LEVEL==1)
	printf("Debug Level 1\n");
#elif (DEBUG_LEVEL==2)
	printf("Debug Level 2\n");
#elif (DEBUG_LEVEL==3)
	printf("Debug Level 3\n");
#endif 
	return 0;
}
