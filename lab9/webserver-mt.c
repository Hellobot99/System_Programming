#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <limits.h>
#include <pthread.h>
#include <errno.h>

#define PORT 8080
#define BUF_SIZE 4096
#define MAX_QUEUE 16
#define THREAD_POOL_SIZE 4

int queue[MAX_QUEUE];
int front = 0, rear = 0, count = 0;
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t cond_nonempty = PTHREAD_COND_INITIALIZER;
pthread_cond_t cond_nonfull = PTHREAD_COND_INITIALIZER;

void enqueue(int client_fd);
int dequeue();
void* worker_thread(void* arg);
void handle_request(int client_fd);

int main() {
    int server_fd, client_fd;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_len = sizeof(client_addr);

    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;
    bind(server_fd, (struct sockaddr*)&server_addr, sizeof(server_addr));

    listen(server_fd, 10);
    printf("Thread-Pool Web Server running at http://localhost:%d\n", PORT);

    pthread_t threads[THREAD_POOL_SIZE];
    for (int i = 0; i < THREAD_POOL_SIZE; i++) {
        pthread_create(&threads[i], NULL, worker_thread, NULL);
    }

    while (1) {
        client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &client_len);
        if (client_fd < 0) {
            perror("accept");
            continue;
        }

        enqueue(client_fd);
    }

    close(server_fd);
    return 0;
}

void enqueue(int client_fd) {
    pthread_mutex_lock(&mutex);
    while (count == MAX_QUEUE)
        pthread_cond_wait(&cond_nonfull, &mutex);

    queue[rear] = client_fd;
    rear = (rear + 1) % MAX_QUEUE;
    count++;

    pthread_cond_signal(&cond_nonempty);
    pthread_mutex_unlock(&mutex);
}

int dequeue() {
    pthread_mutex_lock(&mutex);
    while (count == 0)
        pthread_cond_wait(&cond_nonempty, &mutex);

    int client_fd = queue[front];
    front = (front + 1) % MAX_QUEUE;
    count--;

    pthread_cond_signal(&cond_nonfull);
    pthread_mutex_unlock(&mutex);
    return client_fd;
}

void* worker_thread(void* arg) {
    while (1) {
        int client_fd = dequeue();
        handle_request(client_fd);
    }
    return NULL;
}

void handle_request(int client_fd) {
    char buffer[BUF_SIZE];
    int bytes = read(client_fd, buffer, BUF_SIZE - 1);
    if (bytes <= 0) {
        close(client_fd);
        return;
    }

    buffer[bytes] = '\0';
    printf("Received request:\n%s\n", buffer);

    char method[8], path[256];
    sscanf(buffer, "%s %s", method, path);

    if (strcmp(method, "GET") != 0) {
        const char* error = "HTTP/1.1 405 Method Not Allowed\r\n\r\n";
        write(client_fd, error, strlen(error));
        close(client_fd);
        return;
    }

    if (strcmp(path, "/") == 0)
        strcpy(path, "/index.html");

    char full_path[512];
    snprintf(full_path, sizeof(full_path), "./www%s", path);
    int file_fd = open(full_path, O_RDONLY);
    if (file_fd < 0) {
        const char* not_found =
            "HTTP/1.1 404 Not Found\r\n\r\n"
            "<h1>404 Not Found</h1>\n";
        write(client_fd, not_found, strlen(not_found));
        close(client_fd);
        return;
    }

    const char* header = "HTTP/1.1 200 OK\r\n\r\n";
    write(client_fd, header, strlen(header));

    char file_buf[BUF_SIZE];
    int n;
    while ((n = read(file_fd, file_buf, BUF_SIZE)) > 0) {
        write(client_fd, file_buf, n);
    }

    close(file_fd);
    close(client_fd);
}