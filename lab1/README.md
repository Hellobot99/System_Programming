# Lab #1 (Total 10 points)

## Basic Setup 
Before starting the lab, install the required development tools by running the following commands:
```sh
$ sudo apt update
$ sudo apt install -y build-essential strace
```

## Lab #1-1: Writing who3 (2 points)
### Instructions
- Implement who3.c & utmplib.c as discussed in the lecture.
- Use **NRECS 16** in utmplib.c

### Test
- Run the following command.
    ```sh
    $ bash test_who3.sh
    $ All tests passed!
    ```
- You will receive full points if the output is "All tests passed!"

### Submission
- Submit `who3.c` and `utmplib.c`


## Lab #1-2: Writing who4 (4 points)
### Instructions
- Enhance `who3.c` to **exactly match** the output format of the original who command.
- To make who4, just copy and modify the code of who3.c

### Hint
- To print the TTY name, use:  
    ```C
    printf("%-12.12s", utbufp->ut_line);
    ```
- You need to modify the time display format.
  - Look into the `localtime()` and `strftime()` functions for formatting time.

### Test
- Run the following command.
    ```sh
    $ bash test_who4.sh
    $ All tests passed!
    ```
- You will receive full points if the output is "All tests passed!"

### Submission
- Submit `who4.c` and `utmplib.c` (unmodified from Lab #1-1)


## Lab #1-3: Writing cp2 (4 points)
### Instructions
- What happens when the standard cp command tries to copy a file onto itself? (e.g., cp file1 file1).
- Write cp2.c to ensure it **properly handles this case**.
- The error message format **must match** the original cp command:
    ```sh
    $ cp file1 file1
    cp: 'file1' and 'file1' are the same file
    ```

### Hint
- Look into the `stat` system call.

### Test
- Run the following command.
    ```sh
    $ bash test_cp2.sh
    $ All tests passed!
    ```
- You will receive full points if the output is "All tests passed!"

### Submission
- Submit `cp2.c`
  
