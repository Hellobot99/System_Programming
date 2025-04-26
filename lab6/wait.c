#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

#define DELAY 5

void child_code(int delay);
void parent_code(int childpid);

int main() {
    int newpid;

    printf("Before: my pid is %d\n", getpid());
    
    if((newpid = fork()) == -1){
        perror("fork failed");
        exit(1);
    }
    else if(newpid == 0) {
        child_code(DELAY);
    } else {
        parent_code(newpid);
    }

    return 0;
}

void child_code(int delay) {
    printf("Child %d here. Will sleep for %d seconds.\n", getpid(), delay);
    sleep(delay);
    printf("Child done. About to exit.\n");
    exit(17);
}

void parent_code(int childpid) {
    int wait_rv;
    int child_status;
    int high_8, low_7, bit_7;

    wait_rv = wait(&child_status);
    printf("Done waiting for %d. wait() returned: %d\n", childpid, wait_rv);

    printf("Child status (binary): ");
    for(int i = 15; i >= 0; i--) {
        int mask = 1 << i;
        printf("%d", (child_status & mask) ? 1 : 0);
        if (i % 8 == 0) printf(" ");
    }
    printf("\n");

    high_8 = (child_status >> 8) & 0xFF;
    low_7 = child_status & 0x7F;
    bit_7 = (child_status & 0x80) ? 1 : 0;

    printf("Status: exit=%d, signal=%d, core dumped=%d\n", high_8, low_7, bit_7);
}