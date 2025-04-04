[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/dEAeNIGC)
# Lab #2 (Total: 10 points)

## Note for Lab #2  
- **Do not create a new directory** in this repository.  
- Push your code directly to the **root path** of this repo.  
- Example:  
    ```sh
    $ cd $(git rev-parse --show-toplevel)
    $ vi ls3.c
    $ vi cpdr.c
    ```

---

## Lab #2-1: Writing `ls3` (4 points)

### Instructions  
- The current `ls2` (which was covered in the lecture) does not handle directories correctly.  
- In the example below, `ls2` fails to retrieve information about `tmp/testfile` and incorrectly prints **"No such file or directory."**  
    ```sh
    $ mkdir tmp
    $ touch tmp/testfile
    $ ./ls2 tmp
    tmp:
    testfile: No such file or directory
    drwxr-xr-x   6 mhan     mhan         4096 Mar 20 01:39 ..
    drwxr-xr-x   3 mhan     mhan         4096 Mar 20 03:38 .
    ```
- The goal of **Lab #2-1** is to fix this issue.  
- Specifically, your task is to:  
    - Modify `ls2.c` to handle directories correctly.  
    - Skip the current directory (`.`) and parent directory (`..`) when calling `stat`.  

### Testing  
- Run the following command:  
    ```sh
    $ bash test.sh ls3
    ```
- If the output is **"SUCCESS: All tests passed!"**, you will receive full points.  

### Submission  
- Submit `ls3.c`:  
    ```sh
    $ cd $(git rev-parse --show-toplevel)
    $ git add ls3.c
    $ git commit -m "<your commit message>"
    $ git push
    ```
- After pushing, use **GitHub Actions** to verify that your submitted code works correctly.  

---

## Lab #2-2: Writing `cpdr` (6 points)

### Instructions  
- The goal of **Lab #2-2** is to implement `cpdr`, a recursive version of `cp` for directories.  
- Your `cpdr` should **recursively** copy all files and subdirectories from the source to the destination.  
- When copying, ensure that all file **permissions are preserved**, maintaining the same permissions as the source.  

### Testing  
- Run the following command:  
    ```sh
    $ bash test.sh cpdr
    ```
- If the output is **"SUCCESS: All tests passed!"**, you will receive full points.  

### Submission  
- Submit `cpdr.c`:  
    ```sh
    $ cd $(git rev-parse --show-toplevel)
    $ git add cpdr.c
    $ git commit -m "<your commit message>"
    $ git push
    ```
- After pushing, use **GitHub Actions** to verify that your submitted code works correctly.  
