# System Programming Practice

경북대학교 컴퓨터학부 **시스템 프로그래밍(System Programming)** 실습 과제 저장소입니다.
리눅스/유닉스 환경에서 C 언어를 사용하여 시스템 콜, 프로세스 관리, 쉘 구현, 멀티스레딩 및 네트워크 프로그래밍을 학습하고 구현한 코드가 포함되어 있습니다.

## 📂 Repository Structure

이 저장소는 주차별 실습(Lab)으로 구성되어 있으며, 각 디렉토리는 다음과 같은 주제를 다룹니다.

| Lab | Topic | Description | Key Files |
|:---:|:---:|:---|:---|
| **Lab 1** | **File I/O & System Info** | 리눅스 기본 명령어(`cp`, `who`) 구현을 통한 파일 입출력 및 유저 정보 조회 학습 | `cp2.c`, `who3.c` |
| **Lab 2** | **Directory Handling** | 디렉토리 구조 이해 및 `ls` 명령어, 재귀적 복사(`cp -r`) 기능 구현 | `ls3.c`, `cpdr.c` |
| **Lab 3** | **Operating System (xv6)** | 교육용 OS인 **xv6-riscv** 커널 분석 및 시스템 콜 추가 실습 | `xv6-riscv/` |
| **Lab 4** | **Terminal I/O** | 터미널 속성 제어(Canonical/Non-canonical mode), 비밀번호 입력 처리 등 | `typer.c`, `pw_input.c` |
| **Lab 5** | **Screen Control** | 터미널 제어 코드를 활용한 텍스트 에디터 및 스네이크 게임 구현 | `editor.c`, `snake.c` |
| **Lab 6** | **Process Control** | `fork`, `exec`, `wait` 시스템 콜을 활용한 프로세스 생성 및 제어 기초 | `psh2.c`, `wait.c` |
| **Lab 7** | **Shell Implementation** | 리다이렉션, 파이프, 시그널 처리, Job Control을 지원하는 **Mini Shell** 구현 | `mini-shell.c` |
| **Lab 8** | **Concurrency (Threads)** | Pthread를 이용한 멀티스레딩 프로그래밍 및 Mutex를 활용한 동기화 (Word Count) | `wc_mt.c` |
| **Lab 9** | **IPC & Network** | 파이프(Pipe) 통신 및 멀티스레드 기반의 웹 서버(Web Server) 구현 | `webserver.c` |

## 🛠 Environment

- **OS**: Linux (Ubuntu/CentOS via WSL or VM)
- **Language**: C
- **Compiler**: GCC
- **Tools**: Make, GDB, bash

## 🚀 How to Run

각 실습 디렉토리로 이동하여 `submit.sh` 또는 `test.sh` 스크립트를 실행하거나, `gcc`를 통해 직접 컴파일할 수 있습니다.

```bash
# 예시: Lab 1의 cp2 컴파일 및 실행
cd lab1
gcc -o cp2 cp2.c
./cp2 source_file target_file
