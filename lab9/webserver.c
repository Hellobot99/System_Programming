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

#define PORT 8080
#define BUF_SIZE 4096

void handle_request(int client_fd)
{
    char buffer[BUF_SIZE];
    int bytes = read(client_fd, buffer, BUF_SIZE - 1);
    if (bytes <= 0)
    {
        close(client_fd);
        return;
    }

    buffer[bytes] = '\0';
    printf("Received request:\n%s\n", buffer);

    char method[8], path[256];
    sscanf(buffer, "%s %s", method, path);

    if (strcmp(method, "GET") != 0)
    {
        const char *error = "HTTP/1.1 405 Method Not Allowed\r\n\r\n";
        write(client_fd, error, strlen(error));
        close(client_fd);
        return;
    }

    if (strcmp(path, "/") == 0)
        strcpy(path, "/index.html");

    char full_path[512];
    snprintf(full_path, sizeof(full_path), "./www%s", path);

    for (int i = 0; i < strlen(path) - 2; i++)
    {
        if (strncmp(path + i, "../", 3) == 0)
        {
            const char *forbidden =
                "HTTP/1.1 403 Forbidden\r\n\r\n"
                "<h1>403 Forbidden</h1>\n";
            write(client_fd, forbidden, strlen(forbidden));
            close(client_fd);
            return;
        }
    }

    int file_fd = open(full_path, O_RDONLY);
    if (file_fd < 0)
    {
        const char *not_found =
            "HTTP/1.1 404 Not Found\r\n\r\n"
            "<h1>404 Not Found</h1>\n";
        write(client_fd, not_found, strlen(not_found));
        close(client_fd);
        return;
    }

    const char *header = "HTTP/1.1 200 OK\r\n\r\n";
    write(client_fd, header, strlen(header));

    char file_buf[BUF_SIZE];
    int n;
    while ((n = read(file_fd, file_buf, BUF_SIZE)) > 0)
    {
        write(client_fd, file_buf, n);
    }

    close(file_fd);
    close(client_fd);
}

int main()
{
    int server_fd, client_fd;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_len = sizeof(client_addr);

    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;
    bind(server_fd, (struct sockaddr *)&server_addr, sizeof(server_addr));

    listen(server_fd, 5);
    printf("Simple Web Server running at http://localhost:%d\n", PORT);

    while (1)
    {
        client_fd = accept(server_fd, (struct sockaddr *)&client_addr, &client_len);
        if (client_fd < 0)
        {
            perror("accept");
            continue;
        }

        handle_request(client_fd);
    }

    close(server_fd);
    return 0;
}
