#include "kernel/types.h"
#include "user/user.h"

// Inline assembly syscall wrapper
long
my_syscall(int syscall_num)
{
  long ret;
  asm volatile (
      "mv a7, %1\n"
      "ecall\n"
      "mv %0, a0\n"
      : "=r"(ret)
      : "r"(syscall_num)
      : "a0", "a7"
      );
  return ret;
}

int
main(void)
{
  // ---- Normal syscalls ----
  long begin = my_syscall(23); // +1
  getpid(); // +1
  sleep(1); // +1
  int fds[2];
  if (pipe(fds) < 0) { // +1
    printf("pipe() failed\n");
    exit(1);
  }
  write(fds[1], "X", 1); // +1
  char buf[1];
  read(fds[0], buf, 1); // +1

  // ----- Invalid syscalls (should NOT increase counter) -----
  long before_invalid = my_syscall(23); // +1
  my_syscall(999);
  my_syscall(1000);
  my_syscall(42);
  long after_invalid = my_syscall(23); // +1

  // ----- More getsyscallcount() calls (each should add 1) -----
  long c1 = my_syscall(23); // +1
  long c2 = my_syscall(23); // +1
  long c3 = my_syscall(23); // +1

  printf("Total syscall count: %ld\n", c3 - begin); // expect 10
  printf("Test 1: %ld\n", before_invalid - begin); // expect 6
  printf("Test 2: %ld\n", after_invalid - before_invalid); // expect 1
  printf("Test 3: %ld\n", c2 - c1); // expect 1
  printf("Test 4: %ld\n", c3 - c2); // expect 1

  exit(0);
}
