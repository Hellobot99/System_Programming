[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/uN_CqfN_)
# Lab #4 (Total: 10 points)  

In this lab, you will gain hands-on experience with Linux terminal programming. You will explore low-level I/O behavior by interacting directly with terminal devices such as `/dev/pts`, and implement practical features such as hidden password input and terminal-based messaging. These exercises will strengthen your understanding of terminal-based applications and the fundamentals of user interaction and communication in Unix-like systems.

---

## Setup

Before starting the lab, install the required packages used by the testing scripts:

```bash
$ sudo apt update
$ sudo apt install -y expect socat
```

---

## Lab #4-1: Secure Password Input with Terminal Control (2 pts)

- Write `pw_input.c`  
- Refer to the lab PDF slides for implementation details.

**To test your program:**

```bash
$ bash test.sh pw_input
```

---

## Lab #4-2: Linux Message Broadcasting via /dev/pts (4 pts)

- Write `broadcaster.c`  
- Refer to the lab PDF slides for instructions.

**To test your program:**

```bash
$ bash test.sh broadcaster
```

---

## Lab #4-3: Build a Simple Terminal-Based Typer (4 pts)

- Write `typer.c`  
- Refer to the lab PDF slides for guidance.

**To test your program:**

```bash
$ bash test.sh typer
```

---

## Submission

- **Deadline:** *Thursday, April 10, 2025, 08:59:59 AM*
- Submit your code via GitHub using the provided `submit.sh` script.  
*(Alternatively, you may use `git add`, `commit`, and `push` manually.)*
- After pushing, use **GitHub Actions** to verify that your submission passes all tests.

---
