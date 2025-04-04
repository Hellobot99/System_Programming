#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#pragma pack(push, 1)
typedef struct
{
    char id;   // 1 byte
    int num;   // 4 bytes
    char code; // 1 byte
} PACKET1;
#pragma pack(pop)
#pragma pack(push, 1)
typedef struct
{
    char id;   // 1 byte
    long cnt;  // 8 bytes
} PACKET2;
#pragma pack(pop)

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

    printf("sizeof(packet1)= %d\n", (int)sizeof(packet1));
    printf("sizeof(packet2)= %d\n", (int)sizeof(packet2));

    return 0;
}
