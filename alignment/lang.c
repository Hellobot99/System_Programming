#include <stdio.h>

#ifdef EN
#define HELLO_MESSAGE "Hello"
#elif defined KO
#define HELLO_MESSAGE "안녕하세요"
#elif defined FR
#define HELLO_MESSAGE "Bonjour"
#endif

int main()
{
	printf("%s\n", HELLO_MESSAGE);
	return 0;
}
