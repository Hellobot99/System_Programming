#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

typedef unsigned char u8;
typedef unsigned int u32;

#pragma pack(push, 1)
typedef struct {
	u8 id;
	u32 count;
}PACKET;
#pragma pack(pop)

void error_handling(char *message);

int main(int argc, char *argv[])
{
	int serv_sock;
	int clnt_sock;
	
	struct sockaddr_in serv_addr;
	struct sockaddr_in clnt_addr;
	socklen_t clnt_addr_size;
	int len;
	PACKET recv_packet;	
	
	if(argc!=2){
		printf("Usage : %s <port>\n", argv[0]);
		exit(1);
	}

	memset(&recv_packet, 0, sizeof(PACKET));

	/* 서버 소켓(리스닝 소켓) 생성 */
	serv_sock=socket(PF_INET, SOCK_STREAM, 0);
	if(serv_sock == -1)
		error_handling("socket() error");
	
	/* 주소 정보 초기화 */
	memset(&serv_addr, 0, sizeof(serv_addr));
	serv_addr.sin_family=AF_INET;
	serv_addr.sin_addr.s_addr=htonl(INADDR_ANY);
	serv_addr.sin_port=htons(atoi(argv[1]));
	
	/* 주소 정보 할당 */
	if(bind(serv_sock, (struct sockaddr*) &serv_addr, sizeof(serv_addr))==-1 )
		error_handling("bind() error"); 
	
	if(listen(serv_sock, 5)==-1)
		error_handling("listen() error");
	
	clnt_addr_size=sizeof(clnt_addr);  
	clnt_sock=accept(serv_sock, (struct sockaddr*)&clnt_addr,&clnt_addr_size);
	if(clnt_sock==-1)
		error_handling("accept() error");  
	
	len = read(clnt_sock, &recv_packet, sizeof(PACKET));
	printf("Server: 1 byte alignment\n");
	printf("[Rx] %d bytes\n", len);
	printf("id: 0x%0x\n", recv_packet.id);
	printf("count: 0x%0x (%d)\n", recv_packet.count, recv_packet.count);

	//write(clnt_sock, message, sizeof(message));
	close(clnt_sock);	
	close(serv_sock);
	return 0;
}

void error_handling(char *message)
{
	fputs(message, stderr);
	fputc('\n', stderr);
	exit(1);
}

