[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/TcH5b3Et)
# Lab #3 (Total: 10 points)

**Objective:**  
Gain hands-on experience by implementing custom system calls in a Unix-like OS.

**Platform:**  
We will use **xv6**, a teaching operating system developed at MIT.

- Minimal and well-structured — ideal for understanding OS internals  
- Designed for education and OS experimentation  
- Easy to add and test new system calls with low overhead  

**Target architecture:** RISC-V  
We use **QEMU** to emulate RISC-V on our development machines.

---

## Setup

**Install required packages:**
```bash
$ sudo apt update
$ sudo apt install -y build-essential expect qemu-system-misc gcc-riscv64-unknown-elf
```

**Build xv6:**
```bash
$ cd xv6-riscv
$ make
```

**Run xv6:**
```bash
$ make qemu
```
- xv6 will boot and display a shell prompt.  
- Basic utilities (e.g., `ls`) are available.  
- To quit xv6: press `Ctrl-a`, then `x`.

---

## Lab #3-1: Hello System Call (4 pts)

**Task:**  
Add a new system call `SYS_hello` to xv6.

**Guidance:**  
Refer to lab PDF slides for details.

**Requirements:**
- Assign system call number **22** to `SYS_hello`.
- Implement the kernel-side handler function `sys_hello()` as follows:
```c
uint64
sys_hello(void)
{
  printf("Hello from xv6 kernel!");
  return 46201;
}
```

**Test:**  
```bash
$ bash test.sh hello
```

---

## Lab #3-2: System Call Counting (6 pts)

**Task:**  
Implement a new system call `SYS_getsyscallcount` that returns the number of **valid** system calls made by the **current process**.

**Requirements:**
- Assign system call number **23** to `SYS_getsyscallcount`.
- Add a new counter field to the `proc` structure (`kernel/proc.h`).
- Increment this counter **only** when a valid system call is invoked.
- Do **not** count invalid system call numbers.
- The counter should be incremented **after** the system call is executed.
- The new system call should return the **current value** of this counter.

**Test:**  
```bash
$ bash test.sh count
```

---

## Submission

- **Deadline:** 08:59:59 AM on **Thursday, April 3, 2025**
- Submit your work via GitHub using the provided `submit.sh` script.  
  *(Alternatively, you may submit manually using `git add`, `commit`, and `push`.)*
- After pushing your code, use **GitHub Actions** to verify that your submission passes all tests.
