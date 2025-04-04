/*--------------------------------------------------------------------
 * alignment1.c
 * 
 * 구조체 크기 비교 
 * - Alignment를 수행하기 전의 구조체 크기 
 * - 실제 구조체 멤버의 바이트 수와 sizeof(구조체변수) 연산 결과 비교 
*---------------------------------------------------------------------*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
	char id;  	// 1 byte	
	int num;	// 4 bytes
	char code;	// 1 byte
}PACKET1;

typedef struct {
	char id;	// 1 byte
	long cnt;	// 8 bytes 
}PACKET2;


int main()
{
	PACKET1 packet1;
	PACKET2 packet2;

	memset(&packet1, 0, sizeof(PACKET1));
	packet1.id = 0x01;
	packet1.num = 0x1234;
	packet1.code = 0x03;

	memset(&packet2, 0, sizeof(PACKET2));
	packet2.id = 0x02;
	packet2.cnt = 0x1234;

	printf("sizeof(packet1)= %ld\n", sizeof(packet1));
	printf("sizeof(packet2)= %ld\n", sizeof(packet2));

	return 0;
}


