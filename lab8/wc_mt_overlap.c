#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <string.h>
#include <ctype.h>
#include <sys/time.h>

#define CHUNK_SIZE (64 * 1024) // Size of each chunk (64KB)
#define BUFFER_CAPACITY 64     // Number of chunks that can be stored in the buffer
#define MAX_CONSUMERS 32       // Maximum number of consumer threads

// Struct to represent each chunk of data passed from producer to consumers
typedef struct
{
    char *data;             // Pointer to dynamically allocated memory for the chunk
    size_t size;            // Actual size of the chunk
    int starts_inside_word; // 1 if this chunk starts in the middle of a word
} Chunk;

// Shared buffer and counters for producer-consumer communication
Chunk buffer[BUFFER_CAPACITY];
int in = 0, out = 0, count = 0; // Circular buffer indexes
int total_word_count = 0;
int num_consumers = 1;
int is_done = 0; // Flag to indicate producer is done

// Synchronization primitives
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t not_empty = PTHREAD_COND_INITIALIZER;
pthread_cond_t not_full = PTHREAD_COND_INITIALIZER;

// Check if character is part of a word
int is_word_char(char c)
{
    return isalnum(c);
}

// Count words in a chunk, with optional skipping of initial partial word
int count_words_in_chunk(char *buf, size_t size, int starts_inside_word)
{
    int count = 0;
    int in_word = 0;
    size_t i = 0;

    // If the chunk starts in the middle of a word, skip initial partial word
    if (starts_inside_word)
    {
        while (i < size && is_word_char(buf[i]))
            i++;
    }

    for (; i < size; i++)
    {
        if (is_word_char(buf[i]))
        {
            if (!in_word)
            {
                count++;
                in_word = 1;
            }
        }
        else
        {
            in_word = 0;
        }
    }

    return count;
}

// Producer thread function: reads file in chunks and pushes them to the buffer
void *producer(void *arg)
{
    FILE *fp = fopen((char *)arg, "r");
    if (!fp)
    {
        perror("fopen");
        exit(1);
    }

    int prev_ends_in_word = 0;

    while (1)
    {
        // Allocate space for chunk
        char *buf = malloc(CHUNK_SIZE + 256); // Extra for word boundary extension
        if (!buf)
        {
            perror("malloc");
            exit(1);
        }

        // Read up to CHUNK_SIZE bytes from file
        size_t size = fread(buf, 1, CHUNK_SIZE, fp);
        if (size == 0)
        {
            free(buf);
            break;
        }
        // If the last character is part of a word, extend until the word ends
        int c;
        while (size > 0 && is_word_char(buf[size - 1]) && (c = fgetc(fp)) != EOF)
        {
            buf[size++] = (char)c;
        }

        // Prepare chunk metadata
        Chunk chunk = {
            .data = buf,
            .size = size,
            .starts_inside_word = prev_ends_in_word};

        // Determine if this chunk ends in a word (for next chunk's metadata)
        prev_ends_in_word = is_word_char(buf[size - 1]);

        // Place chunk into buffer
        pthread_mutex_lock(&mutex);
        while (count == BUFFER_CAPACITY)
        {
            pthread_cond_wait(&not_full, &mutex);
        }
        buffer[in] = chunk;
        in = (in + 1) % BUFFER_CAPACITY;
        count++;
        pthread_cond_signal(&not_empty);
        pthread_mutex_unlock(&mutex);
    }

    // Cleanup
    fclose(fp);

    // Notify all consumers that production is complete
    pthread_mutex_lock(&mutex);
    is_done = 1;
    pthread_cond_broadcast(&not_empty);
    pthread_mutex_unlock(&mutex);

    return NULL;
}

void *consumer(void *arg)
{
    while (1)
    {
        pthread_mutex_lock(&mutex);
        while (count == 0 && !is_done)
        {
            pthread_cond_wait(&not_empty, &mutex);
        }

        // If buffer is empty and producer is done, exit loop
        if (count == 0 && is_done)
        {
            pthread_mutex_unlock(&mutex);
            break;
        }

        // Get chunk from buffer
        Chunk chunk = buffer[out];
        out = (out + 1) % BUFFER_CAPACITY;
        count--;
        pthread_cond_signal(&not_full);
        pthread_mutex_unlock(&mutex);

        // Count words in chunk
        int wc = count_words_in_chunk(chunk.data,
                                      chunk.size,
                                      chunk.starts_inside_word);

        // Accumulate result into global total
        pthread_mutex_lock(&mutex);
        total_word_count += wc;
        pthread_mutex_unlock(&mutex);

        free(chunk.data);
    }

    return NULL;
}

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        printf("Usage: %s <filename> <num_consumers>\n", argv[0]);
        return 1;
    }

    num_consumers = atoi(argv[2]);
    if (num_consumers <= 0 || num_consumers > MAX_CONSUMERS)
    {
        printf("Number of consumers must be between 1 and %d\n", MAX_CONSUMERS);
        return 1;
    }

    // Start timer
    struct timeval start, end;
    gettimeofday(&start, NULL);

    // Launch producer and consumers
    pthread_t prod;
    pthread_t consumers[MAX_CONSUMERS];

    pthread_create(&prod, NULL, producer, argv[1]);
    for (int i = 0; i < num_consumers; i++)
    {
        pthread_create(&consumers[i], NULL, consumer, NULL);
    }
    // Wait for all threads to complete
    pthread_join(prod, NULL);
    for (int i = 0; i < num_consumers; i++)
    {
        pthread_join(consumers[i], NULL);
    }

    gettimeofday(&end, NULL);
    double elapsed = (end.tv_sec - start.tv_sec) * 1000.0 +
                     (end.tv_usec - start.tv_usec) / 1000.0;

    // Output result
    printf("Total words: %d\n", total_word_count);
    printf("Elapsed time (total): %.2f ms\n", elapsed);
    return 0;
}