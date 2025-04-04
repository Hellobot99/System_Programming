#include <stdio.h> 

#ifdef _32BIT 
typedef unsigned int uint32; 
typedef int int32; 
typedef unsigned long long uint64; 
typedef long long int64; 
#else 
typedef unsigned int uint32; 
typedef int int32; 
typedef unsigned long uint64; 
typedef long int64; 
#endif 

void main() 
{ 
#if defined (LINUX) || defined (OSX) 
    printf("Unix machine\n"); 
#elif defined (WINDOWS) && defined(_32BIT) 
    printf("Windows machine 32bit\n");
    printf("sizeof(int64)= %ld\n", sizeof(int64));
#elif defined (WINDOWS) && !defined(_32BIT) 
    printf("Windows machine 64bit\n"); 
#else 
    printf("Unknown machine\n"); 
#endif 
}

