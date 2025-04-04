#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

typedef unsigned char u8;
typedef unsigned int u32;
//#pragma pack(push, 1)
typedef struct  {
	u8 id;
	u32 count;
} PACKET;
//#pragma pack(pop)

void error_handling(char *message);

int main(int argc, char* argv[])
{
	int sock;
	struct sockaddr_in serv_addr;
	char message[30];
	int len;
	PACKET send_packet;

	if(argc!=3){
		printf("Usage : %s <IP> <port>\n", argv[0]);
		exit(1);
	}
	
	memset(&send_packet, 0, sizeof(PACKET));

	sock=socket(PF_INET, SOCK_STREAM, 0);
	if(sock == -1)
		error_handling("socket() error");
	
	memset(&serv_addr, 0, sizeof(serv_addr));
	serv_addr.sin_family=AF_INET;
	serv_addr.sin_addr.s_addr=inet_addr(argv[1]);
	serv_addr.sin_port=htons(atoi(argv[2]));
	// 연결 요청 
	if(connect(sock, (struct sockaddr*)&serv_addr, 
				sizeof(serv_addr))==-1) 
		error_handling("connect() error!");
	
	send_packet.id = 0x01;
	send_packet.count = 0x12345678;

	len = write(sock, &send_packet, sizeof(PACKET));

	printf("Client: no alignment\n");
	printf("[Tx] %d bytes\n", len);
	printf("id: 0x%0x\n", send_packet.id);
	printf("count: 0x%0x (%d)\n", send_packet.count, send_packet.count);

	close(sock);
	return 0;
}

void error_handling(char *message)
{
	fputs(message, stderr);
	fputc('\n', stderr);
	exit(1);
}

