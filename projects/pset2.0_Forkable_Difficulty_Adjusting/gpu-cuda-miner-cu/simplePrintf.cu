/*-256 tests: %s\n", sha256_test() ? "SUCCEEDED" : "FAILED");

 * Copyright 1993-2015 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */


// System includes
#include <stdio.h>
#include <assert.h>

// CUDA runtime
#include <cuda_runtime.h>

// helper functions and utilities to work with CUDA
#include <helper_functions.h>
#include <helper_cuda.h>
#include <timer.h>

// TCP
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#define BUFSIZE 1024

#ifndef MAX
#define MAX(a,b) (a > b ? a : b)
#endif


typedef unsigned int  WORD;             // 32-bit word, change to "long" for 16-bit machines

typedef struct {
	unsigned char data[64];
	WORD datalen;
	unsigned long long bitlen;
	WORD state[8];
} SHA256_CTX;

#define SHA256_BLOCK_SIZE 32            // SHA256 outputs a 32 byte digest

/*********************************************************************
* Filename:   sha256.c
* Author:     Brad Conte (brad AT bradconte.com)
* Copyright:
* Disclaimer: This code is presented "as is" without any guarantees.
* Details:    Implementation of the SHA-256 hashing algorithm.
              SHA-256 is one of the three algorithms in the SHA2
              specification. The others, SHA-384 and SHA-512, are not
              offered in this implementation.
              Algorithm specification can be found here:
               * http://csrc.nist.gov/publications/fips/fips180-2/fips180-2withchangenotice.pdf
              This implementation uses little endian byte order.
*********************************************************************/

/*************************** HEADER FILES ***************************/
#include <memory.h>

/****************************** MACROS ******************************/
#define ROTLEFT(a,b) (((a) << (b)) | ((a) >> (32-(b))))
#define ROTRIGHT(a,b) (((a) >> (b)) | ((a) << (32-(b))))

#define CH(x,y,z) (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x,y,z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define EP0(x) (ROTRIGHT(x,2) ^ ROTRIGHT(x,13) ^ ROTRIGHT(x,22))
#define EP1(x) (ROTRIGHT(x,6) ^ ROTRIGHT(x,11) ^ ROTRIGHT(x,25))
#define SIG0(x) (ROTRIGHT(x,7) ^ ROTRIGHT(x,18) ^ ((x) >> 3))
#define SIG1(x) (ROTRIGHT(x,17) ^ ROTRIGHT(x,19) ^ ((x) >> 10))

/**************************** VARIABLES *****************************/
__device__ static const WORD k[64] = {
	0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
	0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
	0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
	0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
	0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
	0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
	0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
	0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

static const WORD h_k[64] = {
	0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
	0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
	0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
	0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
	0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
	0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
	0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
	0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

/*********************** FUNCTION DEFINITIONS ***********************/
 __device__ void sha256_transform(SHA256_CTX *ctx, const unsigned char data[])
{
	WORD a, b, c, d, e, f, g, h, i, j, t1, t2, m[64];

	for (i = 0, j = 0; i < 16; ++i, j += 4)
		m[i] = (data[j] << 24) | (data[j + 1] << 16) | (data[j + 2] << 8) | (data[j + 3]);
	for ( ; i < 64; ++i)
		m[i] = SIG1(m[i - 2]) + m[i - 7] + SIG0(m[i - 15]) + m[i - 16];

	a = ctx->state[0];
	b = ctx->state[1];
	c = ctx->state[2];
	d = ctx->state[3];
	e = ctx->state[4];
	f = ctx->state[5];
	g = ctx->state[6];
	h = ctx->state[7];
	for (i = 0; i < 64; ++i) {
                t1 = h + EP1(e) + CH(e,f,g) + k[i] + m[i];
		t2 = EP0(a) + MAJ(a,b,c);
		h = g;
		g = f;
		f = e;
		e = d + t1;
		d = c;
		c = b;
		b = a;
		a = t1 + t2;
	}
	ctx->state[0] += a;
	ctx->state[1] += b;
	ctx->state[2] += c;
	ctx->state[3] += d;
	ctx->state[4] += e;
	ctx->state[5] += f;
	ctx->state[6] += g;
	ctx->state[7] += h;
}

 __host__ void h_sha256_transform(SHA256_CTX *ctx, const unsigned char data[])
{
	WORD a, b, c, d, e, f, g, h, i, j, t1, t2, m[64];

	for (i = 0, j = 0; i < 16; ++i, j += 4)
		m[i] = (data[j] << 24) | (data[j + 1] << 16) | (data[j + 2] << 8) | (data[j + 3]);
	for ( ; i < 64; ++i)
		m[i] = SIG1(m[i - 2]) + m[i - 7] + SIG0(m[i - 15]) + m[i - 16];

	a = ctx->state[0];
	b = ctx->state[1];
	c = ctx->state[2];
	d = ctx->state[3];
	e = ctx->state[4];
	f = ctx->state[5];
	g = ctx->state[6];
	h = ctx->state[7];
	for (i = 0; i < 64; ++i) {
                t1 = h + EP1(e) + CH(e,f,g) + h_k[i] + m[i];
		t2 = EP0(a) + MAJ(a,b,c);
		h = g;
		g = f;
		f = e;
		e = d + t1;
		d = c;
		c = b;
		b = a;
		a = t1 + t2;
	}
	ctx->state[0] += a;
	ctx->state[1] += b;
	ctx->state[2] += c;
	ctx->state[3] += d;
	ctx->state[4] += e;
	ctx->state[5] += f;
	ctx->state[6] += g;
	ctx->state[7] += h;
}
__device__ void sha256_init(SHA256_CTX *ctx)
{
	ctx->datalen = 0;
	ctx->bitlen = 0;
	ctx->state[0] = 0x6a09e667;
	ctx->state[1] = 0xbb67ae85;
	ctx->state[2] = 0x3c6ef372;
	ctx->state[3] = 0xa54ff53a;
	ctx->state[4] = 0x510e527f;
	ctx->state[5] = 0x9b05688c;
	ctx->state[6] = 0x1f83d9ab;
	ctx->state[7] = 0x5be0cd19;
}

__device__ void sha256_update(SHA256_CTX *ctx, const char data[], size_t len)
{
	WORD i;

	for (i = 0; i < len; ++i) {
		ctx->data[ctx->datalen] = data[i];
		ctx->datalen++;
		if (ctx->datalen == 64) {
			sha256_transform(ctx, ctx->data);
			ctx->bitlen += 512;
			ctx->datalen = 0;
		}
	}
}

__device__ void sha256_final(SHA256_CTX *ctx, char hash[])
{
	WORD i;

	i = ctx->datalen;

	// Pad whatever data is left in the buffer.
	if (ctx->datalen < 56) {
		ctx->data[i++] = 0x80;
		while (i < 56)
			ctx->data[i++] = 0x00;
	}
	else {
		ctx->data[i++] = 0x80;
		while (i < 64)
			ctx->data[i++] = 0x00;
		sha256_transform(ctx, ctx->data);
		memset(ctx->data, 0, 56);
	}

	// Append to the padding the total message's length in bits and transform.
	ctx->bitlen += ctx->datalen * 8;
	ctx->data[63] = ctx->bitlen;
	ctx->data[62] = ctx->bitlen >> 8;
	ctx->data[61] = ctx->bitlen >> 16;
	ctx->data[60] = ctx->bitlen >> 24;
	ctx->data[59] = ctx->bitlen >> 32;
	ctx->data[58] = ctx->bitlen >> 40;
	ctx->data[57] = ctx->bitlen >> 48;
	ctx->data[56] = ctx->bitlen >> 56;
	sha256_transform(ctx, ctx->data);

	// Since this implementation uses little endian byte ordering and SHA uses big endian,
	// reverse all the bytes when copying the final state to the output hash.
	for (i = 0; i < 4; ++i) {
		hash[i]      = (ctx->state[0] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 4]  = (ctx->state[1] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 8]  = (ctx->state[2] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 12] = (ctx->state[3] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 16] = (ctx->state[4] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 20] = (ctx->state[5] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 24] = (ctx->state[6] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 28] = (ctx->state[7] >> (24 - i * 8)) & 0x000000ff;
	}
}


__host__ void h_sha256_init(SHA256_CTX *ctx)
{
	ctx->datalen = 0;
	ctx->bitlen = 0;
	ctx->state[0] = 0x6a09e667;
	ctx->state[1] = 0xbb67ae85;
	ctx->state[2] = 0x3c6ef372;
	ctx->state[3] = 0xa54ff53a;
	ctx->state[4] = 0x510e527f;
	ctx->state[5] = 0x9b05688c;
	ctx->state[6] = 0x1f83d9ab;
	ctx->state[7] = 0x5be0cd19;
}

__host__ void h_sha256_update(SHA256_CTX *ctx, const char data[], size_t len)
{
	WORD i;

	for (i = 0; i < len; ++i) {
		ctx->data[ctx->datalen] = data[i];
		ctx->datalen++;
		if (ctx->datalen == 64) {
			h_sha256_transform(ctx, ctx->data);
			ctx->bitlen += 512;
			ctx->datalen = 0;
		}
	}
}

__host__ void h_sha256_final(SHA256_CTX *ctx, char hash[])
{
	WORD i;

	i = ctx->datalen;

	// Pad whatever data is left in the buffer.
	if (ctx->datalen < 56) {
		ctx->data[i++] = 0x80;
		while (i < 56)
			ctx->data[i++] = 0x00;
	}
	else {
		ctx->data[i++] = 0x80;
		while (i < 64)
			ctx->data[i++] = 0x00;
		h_sha256_transform(ctx, ctx->data);
		memset(ctx->data, 0, 56);
	}

	// Append to the padding the total message's length in bits and transform.
	ctx->bitlen += ctx->datalen * 8;
	ctx->data[63] = ctx->bitlen;
	ctx->data[62] = ctx->bitlen >> 8;
	ctx->data[61] = ctx->bitlen >> 16;
	ctx->data[60] = ctx->bitlen >> 24;
	ctx->data[59] = ctx->bitlen >> 32;
	ctx->data[58] = ctx->bitlen >> 40;
	ctx->data[57] = ctx->bitlen >> 48;
	ctx->data[56] = ctx->bitlen >> 56;
	h_sha256_transform(ctx, ctx->data);

	// Since this implementation uses little endian byte ordering and SHA uses big endian,
	// reverse all the bytes when copying the final state to the output hash.
	for (i = 0; i < 4; ++i) {
		hash[i]      = (ctx->state[0] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 4]  = (ctx->state[1] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 8]  = (ctx->state[2] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 12] = (ctx->state[3] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 16] = (ctx->state[4] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 20] = (ctx->state[5] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 24] = (ctx->state[6] >> (24 - i * 8)) & 0x000000ff;
		hash[i + 28] = (ctx->state[7] >> (24 - i * 8)) & 0x000000ff;
	}
}


__host__ __device__ void print_hash(unsigned char * buf)
{
   for (int i = 0; i < 32; i++){
      unsigned int hexnum = (unsigned int) buf[i];
      printf("%02x", hexnum);
   } 
   printf("\n");
   return;
}
__host__ int strlength(char * str)
{

   int count = 0;
   while (str[count] != '\n')
       count ++;
   return count;
}


__device__ int strlengthzero(char * str)
{
   int count = 0;
   while (str[count] != '\0')
       count ++;
   return count;
}

__device__ void get_ending(unsigned char * buf, int threadID, int offset, int d_num)
{
   int n = 0;
   char name[9] = {" turtle "};
   bool first = true;
   for (int i = 0; i < 8; i++){
       buf[n] = name[i];
       n++;
   }
   buf[n] = '0' + d_num;
   n++;
   buf[n] = '/';
   n++;
   while (threadID != 0 || first){
       first = false;
       int nextNum = threadID % 10;
       unsigned char nextChar = '0' + nextNum;
       buf[n] = nextChar;
       n++;
       threadID = threadID / 10;
   } 
   buf[n] = '/';
   n++;
   first = true;
   while (offset != 0 || first) {
      first = false;
      int nextNum = offset % 10;
      unsigned char nextChar = '0' + nextNum;
      buf[n] = nextChar;
      n++;
      offset = offset / 10;
   }
   buf[n] = '\0';
}

__device__ void sha256_hash(unsigned char * str, unsigned char * result, int threadNum, int offset, int d_num)
{
      	unsigned char buf[SHA256_BLOCK_SIZE];
	SHA256_CTX ctx;

        //printf("Starting sha hash with string -%s-\n", str);
        //print_hash(str);
        char hash_str[100];
        int n_len = 64;
        for (int n = 0; n < 32; n++)
        {
            unsigned int fullBits = (unsigned int) str[n];
            unsigned int leftBit = (fullBits >> 4);
            unsigned int rightBit = (fullBits & 0xF);
            if (leftBit < 10)
                hash_str[n * 2] = '0' + leftBit;
            else
                hash_str[n * 2] = 'a' - 10 + leftBit;
            if (rightBit < 10)
                hash_str[n * 2 + 1] = '0' + rightBit;
            else
                hash_str[n * 2 + 1] = 'a' - 10 + rightBit;
        }
        
        char ending[36];
        get_ending((unsigned char*) ending, threadNum, offset, d_num);
        for (int i = 0; i < strlengthzero(ending); i++){
            hash_str[64 + i] = ending[i];
            n_len ++;
        }
//        printf("Here is the hash_str: %s\n", hash_str);
        sha256_init(&ctx);
	sha256_update(&ctx, hash_str, n_len);
	sha256_final(&ctx, (char *) buf);
        int difficulty = 33;
        //int difficulty = 20;
        bool invalid = false;
	for (int i = 0; i < 32; i ++){
           unsigned int hexnum = (unsigned int) buf[i];
           for (int j = 128; j >= 1; j= j / 2){
              if (((int)hexnum & j) != 0){
                 invalid = true;
              } else {
                 difficulty --;
                 if (difficulty == 0)
                      break;
              }
              if (invalid || difficulty == 0)
                  break;
           }
           if (invalid || difficulty == 0)
                break;
        }
        if (offset % 100 == 0 && threadNum == 0)
            printf("%s\n",hash_str);
        if (invalid){
             //printf("Not enough work done %d\n", difficulty);
             buf[0] = '\0';
        }else{
             printf("YAY you found one: %s\n", hash_str);

             memcpy(result, hash_str, n_len);
        }
}


__host__ void h_sha256_hash(char * str)
{
      	unsigned char buf[SHA256_BLOCK_SIZE];
	SHA256_CTX ctx;
	h_sha256_init(&ctx);
	h_sha256_update(&ctx, str, strlength(str));
	h_sha256_final(&ctx, (char *) buf);
        int difficulty = 33;
        bool invalid = false;
	for (int i = 0; i < 32; i ++){
           unsigned int hexnum = (unsigned int) buf[i];
           for (int j = 128; j >= 1; j= j / 2){
              if (((int)hexnum & j) != 0){
                 invalid = true;
              } else {
                 difficulty --;
                 if (difficulty == 0)
                      break;
              }
              if (invalid || difficulty == 0)
                  break;
           }
           if (invalid || difficulty == 0)
                break;
        }
        if (invalid){
             buf[0] = '\0';
             memcpy(str, buf, SHA256_BLOCK_SIZE);
        }else{
             //printf("enough work done to satisfy difficulty \n");
             memcpy(str, buf, SHA256_BLOCK_SIZE);
        }
}


__global__ void testKernel(unsigned char *var, unsigned char * result, int offset, int d_num)
{   
    bool first = true; 
    while (offset % 100 != 0 || first)
    {
        first = false;
        int threadNum = blockDim.x * blockIdx.x + threadIdx.x;
        //printf("Yay in gpu mode, Thread: %d\n", threadNum);
        sha256_hash(var, result, threadNum,  offset, d_num);
        offset ++;
        if (result[0] != '\0')
            break;
    }
}

/* 
 * error - wrapper for perror
 */
void error(char *msg) {
    perror(msg);
    exit(0);
}

void sendBlock(char * block)
{

    int sockfd, portno, n;
    struct sockaddr_in serveraddr;
    struct hostent *server;
    char *hostname;
    char buf[BUFSIZE];

    /* check command line arguments */
//    if (argc != 3) {
//       fprintf(stderr,"usage: %s <hostname> <port>\n", argv[0]);
      // exit(0);
//    }
//    hostname = argv[1];
    hostname = (char*) "localhost\0";
    hostname = (char*) "hubris.media.mit.edu\0";
//    portno = atoi(argv[2]);
    portno = 6262;

    /* socket: create the socket */
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0)
        error((char *) "ERROR opening socket");
    printf("Opened socket\n");
    /* gethostbyname: get the server's DNS entry */
    server = gethostbyname(hostname);
    if (server == NULL) {
        fprintf(stderr,"ERROR, no such host as %s\n", hostname);
        exit(0);
    }

    /* build the server's Internet address */
    bzero((char *) &serveraddr, sizeof(serveraddr));
    serveraddr.sin_family = AF_INET;
    bcopy((char *)server->h_addr,
          (char *)&serveraddr.sin_addr.s_addr, server->h_length);
    serveraddr.sin_port = htons(portno);

    /* connect: create a connection with the server */
    if (connect(sockfd, (struct sockaddr *) &serveraddr, sizeof(serveraddr)) < 0)
      error((char *) "ERROR connecting");

    /* get message line from the user */
//    printf("Please enter msg: ");
    //fgets(buf, BUFSIZE, stdin);
    /* send the message line to the server */
    bzero(buf, BUFSIZE);  
    sprintf(buf, "%s\n", block);
    printf("Wrote result to buf\n");
    n = write(sockfd, buf, strlen(buf));
    if (n < 0)
      error((char *) "ERROR writing to socket");

    /* print the server's reply */
    bzero(buf, BUFSIZE);
    n = read(sockfd, buf, BUFSIZE);
    if (n < 0)
      error((char *) "ERROR reading from socket");
    printf("Returned tip: %s-----------", buf);
    close(sockfd);
    return;




}

int getScore()
{
    int sockfd, portno, n;
    struct sockaddr_in serveraddr;
    struct hostent *server;
    char *hostname;
    char buf[BUFSIZE];

    /* check command line arguments */
//    if (argc != 3) {
//       fprintf(stderr,"usage: %s <hostname> <port>\n", argv[0]);
      // exit(0);
//    }
//    hostname = argv[1];
    hostname = (char*) "localhost\0";
    hostname = (char*) "hubris.media.mit.edu\0";
//    portno = atoi(argv[2]);
    portno = 6299;

    /* socket: create the socket */
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0)
        error((char *) "ERROR opening socket");

    /* gethostbyname: get the server's DNS entry */
    server = gethostbyname(hostname);
    if (server == NULL) {
        fprintf(stderr,"ERROR, no such host as %s\n", hostname);
        exit(0);
    }

    /* build the server's Internet address */
    bzero((char *) &serveraddr, sizeof(serveraddr));
    serveraddr.sin_family = AF_INET;
    bcopy((char *)server->h_addr,
          (char *)&serveraddr.sin_addr.s_addr, server->h_length);
    serveraddr.sin_port = htons(portno);

    /* connect: create a connection with the server */
    if (connect(sockfd, (struct sockaddr *) &serveraddr, sizeof(serveraddr)) < 0)
      error((char *) "ERROR connecting");

    /* get message line from the user */
//    printf("Please enter msg: ");
    bzero(buf, BUFSIZE);
    //fgets(buf, BUFSIZE, stdin);
    sprintf(buf, "\n");
    /* send the message line to the server */
    n = write(sockfd, buf, strlen(buf));
    if (n < 0)
      error((char *) "ERROR writing to socket");

    /* print the server's reply */
    bzero(buf, BUFSIZE);
    n = read(sockfd, buf, BUFSIZE);
    if (n < 0)
      error((char *) "ERROR reading from socket");
    //printf("Returned tip: %s", buf);
    printf("Current Score: ");
    for (int i = 51; i < 55; i++)
        printf("%c", buf[i]);
    printf("\n");
    close(sockfd);
    if (buf[51] == '1' && buf[52] == '3' && buf[53] == '3' && buf[54] == '7')
        return 1;

    return 0;

}

void getTip(char * buf){
    int sockfd, portno, n;
    struct sockaddr_in serveraddr;
    struct hostent *server;
    char *hostname;
    //char buf[BUFSIZE];

    /* check command line arguments */
//    if (argc != 3) {
//       fprintf(stderr,"usage: %s <hostname> <port>\n", argv[0]);
      // exit(0);
//    }
//    hostname = argv[1];
    hostname = (char*) "localhost\0";
    hostname = (char*) "hubris.media.mit.edu\0";
//    portno = atoi(argv[2]);
    portno = 6262;

    /* socket: create the socket */
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0)
        error((char *) "ERROR opening socket");

    /* gethostbyname: get the server's DNS entry */
    server = gethostbyname(hostname);
    if (server == NULL) {
        fprintf(stderr,"ERROR, no such host as %s\n", hostname);
        exit(0);
    }

    /* build the server's Internet address */
    bzero((char *) &serveraddr, sizeof(serveraddr));
    serveraddr.sin_family = AF_INET;
    bcopy((char *)server->h_addr,
          (char *)&serveraddr.sin_addr.s_addr, server->h_length);
    serveraddr.sin_port = htons(portno);

    /* connect: create a connection with the server */
    if (connect(sockfd, (struct sockaddr *) &serveraddr, sizeof(serveraddr)) < 0)
      error((char *) "ERROR connecting");

    /* get message line from the user */
//    printf("Please enter msg: ");
    bzero(buf, BUFSIZE);
    //fgets(buf, BUFSIZE, stdin);
    sprintf(buf, "TRQ\n");
    /* send the message line to the server */
    n = write(sockfd, buf, strlen(buf));
    if (n < 0)
      error((char *) "ERROR writing to socket");

    /* print the server's reply */
    bzero(buf, BUFSIZE);
    n = read(sockfd, buf, BUFSIZE);
    if (n < 0)
      error((char *) "ERROR reading from socket");
    printf("Returned tip: %s", buf);
    close(sockfd);
    return;
}

int main(int argc, char **argv)
{
    int GPU_N;
    checkCudaErrors(cudaGetDeviceCount(&GPU_N));
    printf("CUDA-capable device count: %i\n", GPU_N);
    if(argc < 2)
    {
        printf("Missing argument, use -device to set gpu slot\n");
        exit(-1);
    }

    int devID;
    cudaDeviceProp props;

    // This will pick the best possible CUDA capable device
    devID = findCudaDevice(argc, (const char **)argv);
    printf("Device: %d\n", devID);
    //Get GPU information
    checkCudaErrors(cudaGetDevice(&devID));
    checkCudaErrors(cudaGetDeviceProperties(&props, devID));
    printf("Device %d: \"%s\" with Compute %d.%d capability\n",
           devID, props.name, props.major, props.minor);
    int counter = 0;

    int offset = 0;
    char *lastTip = (char*) malloc(BUFSIZE);
    bzero(lastTip, BUFSIZE);
  while(true){
    counter ++;
    if (counter % 5 == 0){
        if (getScore())
            exit(0);
    }
    char *tip = (char*) malloc(BUFSIZE);
    unsigned char * h_tip = (unsigned char*) malloc(SHA256_BLOCK_SIZE);
    getTip(tip);
    if (tip[14] != lastTip[14])
    {
        printf("Last tip - %s\n", lastTip);
        printf("New tip  - %s\n", tip);
        offset = 0;
        printf("Got new Tip \n ");
    }
    strcpy(lastTip, tip);
    h_sha256_hash(tip);

    memcpy(h_tip, tip, SHA256_BLOCK_SIZE);
    unsigned char* d_tip = NULL;
    cudaError_t err = cudaSuccess;    
    err = cudaMalloc((void **)&d_tip, SHA256_BLOCK_SIZE);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to allocate device vector A (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }    

    err = cudaMemcpy(d_tip, h_tip, SHA256_BLOCK_SIZE, cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy vector A from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    unsigned char * result = NULL;
    unsigned char *h_result = (unsigned char*) malloc(100);
    bzero(h_result, 100);
    err = cudaMalloc((void **)&result, 100);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to allocate device vector A (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }    
    
    err = cudaMemcpy(result, h_result, 100, cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy vector A from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    StartTimer();
    testKernel<<<1024,1024>>>(d_tip, result, offset, devID);
    offset += 100;
    cudaDeviceSynchronize();
    printf("  GPU Processing time: %f (ms)\n\n", GetTimer());
    
    bzero(h_result, 100);
    err = cudaMemcpy(h_result, result, 100, cudaMemcpyDeviceToHost);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy vector A from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    if (h_result[0] != '\0')
    {
        printf("result detected: %s\n", h_result);
        sendBlock((char*) h_result);
    }
  }
}

