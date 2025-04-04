#include <stdio.h>
#include <sys/types.h>
#include <utmp.h>
#include <fcntl.h>
#include <stdlib.h>
#include <time.h>

#define SHOWHOST

int utmp_open(char *);
void utmp_close();
void show_info(struct utmp*);
void showtime(time_t);

void show_info(struct utmp *utbufp){
	if(utbufp->ut_type != USER_PROCESS)
		return;

	printf("%-8.8s",utbufp->ut_name);
	printf(" ");
	printf("%-12.12s",utbufp->ut_line);
	printf(" ");
	showtime(utbufp->ut_time);
#ifdef SHOWHOST
	if(utbufp->ut_host[0] != '\0')
		printf("(%s)",utbufp->ut_host);
#endif
	printf("\n");
}

void showtime(long timeval){
	struct tm* cp;
	cp =localtime(&timeval);
	if(cp->tm_mon > 10) printf("%d-%d-%d %d:%d",cp->tm_year + 1900, cp->tm_mon + 1, cp->tm_mday,cp->tm_hour,cp->tm_min);
	else printf("%d-0%d-%d %d:%d",cp->tm_year + 1900, cp->tm_mon + 1, cp->tm_mday, cp->tm_hour,cp->tm_min);
}

int main(){
	struct utmp *utbufp, *utmp_next();

	if((utmp_open (UTMP_FILE)) == -1){
		perror(UTMP_FILE);
		exit(1);
	}

	while((utbufp=utmp_next())!=((struct utmp*)NULL))
		show_info(utbufp);
	utmp_close();
	return 0;
}
