#include "kernel/types.h"
#include "user/user.h"

int main(void) {
  int ret;
  asm volatile(
      "li a7, 22\n"     // 시스템 콜 번호 (SYS_hello)
      "ecall\n"         // 트랩 발생 → 커널 진입
      "mv %0, a0\n"     // 커널 리턴값 a0 → C 변수로 복사
      : "=r"(ret)       // 출력
      :                 // 입력 없음
      : "a7", "a0"      // 변경된 레지스터 명시
      );

  printf("sys_hello() returned %d\n", ret);
  exit(0);
}
