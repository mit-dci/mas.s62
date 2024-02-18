
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <iostream>
#include <cstdio>
#include <iomanip>
#include <chrono>
#include <cmath>
#include <thread>
#include <unordered_map>
#include <string>
#include <cassert>
#include <cstring>
#include <vector>

#include "forge_cuda.h"
#include "sha256.cuh"
#include "lamport.h"
#include "signatures.h"

#define SHOW_INTERVAL_MS 2000
#define BLOCK_SIZE 128
#define SHA_PER_ITERATIONS 8388608
#define NUMBLOCKS (SHA_PER_ITERATIONS + BLOCK_SIZE - 1) / BLOCK_SIZE

using std::cout;
using std::endl;
using std::string;
using namespace std::chrono;

// Output string by the device read by host
char *g_out = nullptr;
unsigned char *g_hash_out = nullptr;
int *g_found = nullptr;

static uint64_t nonce = 0;
static uint64_t user_nonce = 0;
static uint64_t last_nonce_since_update = 0;

// Last timestamp we printed debug infos
static std::chrono::high_resolution_clock::time_point t_last_updated;

__device__ bool checkForge(
	unsigned char *sha,
	int *zeroConstraints,
	int *oneConstraints,
	int zeroSize,
	int oneSize)
{
	for (int i = 0; i < zeroSize; i++)
	{
		if ((sha[zeroConstraints[i] / 8] >> (7 - (zeroConstraints[i] % 8)) & 0x01) == 1)
		{
			return false;
		}
	}
	for (int i = 0; i < oneSize; i++)
	{
		if ((sha[oneConstraints[i] / 8] >> (7 - (oneConstraints[i] % 8)) & 0x01) == 0)
		{
			return false;
		}
	}
	return true;
}

// Does the same as sprintf(char*, "%d%s", int, const char*) but a bit faster
__device__ uint8_t nonce_to_str(uint64_t nonce, unsigned char *out)
{
	uint64_t result = nonce;
	uint8_t remainder;
	uint8_t nonce_size = nonce == 0 ? 1 : floor(log10((double)nonce)) + 1;
	uint8_t i = nonce_size;
	while (result >= 10)
	{
		remainder = result % 10;
		result /= 10;
		out[--i] = remainder + '0';
	}

	out[0] = result + '0';
	i = nonce_size;
	out[i] = 0;
	return i;
}

extern __shared__ char array[];
__global__ void forge_kernel(char *out_input_string_nonce,
							 unsigned char *out_found_hash,
							 int *out_found,
							 const char *in_input_string,
							 size_t in_input_string_size,
							 int *zeroConstraints,
							 int *oneConstraints,
							 int zeroSize,
							 int oneSize,
							 uint64_t nonce_offset)
{
	// use shared memory to store string_pre, zero and one constraints and output
	// If this is the first thread of the block, init the input string in shared memory
	// copy the unknown bits after input string
	char *in = (char *)&array[0];
	size_t const minArray0 = static_cast<size_t>(ceil((in_input_string_size) / 8.f) * 8);
	int *zeroConstraints_s = (int *)&array[minArray0];
	int *oneConstraints_s = (int *)&array[minArray0 + 256];
	size_t const minArray = minArray0 + 512;
	uintptr_t sha_addr = threadIdx.x * (64) + minArray;
	uintptr_t nonce_addr = sha_addr + 32;
	unsigned char *sha = (unsigned char *)&array[sha_addr];
	unsigned char *out = (unsigned char *)&array[nonce_addr];

	size_t maxSize = max(oneSize, zeroSize);
	for (size_t tid = threadIdx.x; tid < max(in_input_string_size, maxSize); tid += blockDim.x)
	{
		if (tid < in_input_string_size)
			in[tid] = in_input_string[tid];
		if (tid < zeroSize)
			zeroConstraints_s[tid] = zeroConstraints[tid];
		if (tid < oneSize)
			oneConstraints_s[tid] = oneConstraints[tid];
	}
	__syncthreads(); // Ensure the input string has been written in SMEM

	uint64_t idx = blockIdx.x * blockDim.x + threadIdx.x;
	uint64_t nonce = idx + nonce_offset;

	// The first byte we can write because there is the input string at the begining
	// Respects the memory padding of 8 bit (char).
	long long trialCnt = 0;
	while (true)
	{
		uint8_t size = nonce_to_str(nonce, out);

		assert(size <= 32);
		{
			SHA256_CTX ctx;
			sha256_init(&ctx);
			sha256_update(&ctx, (unsigned char *)in, in_input_string_size);
			sha256_update(&ctx, out, size);
			sha256_final(&ctx, sha);
		}

		if (checkForge(sha, zeroConstraints_s, oneConstraints_s, zeroSize, oneSize) && atomicExch(out_found, 1) == 0)
		{
			memcpy(out_found_hash, sha, 32);
			memcpy(out_input_string_nonce, in, in_input_string_size);
			memcpy(out_input_string_nonce + in_input_string_size, out, size);
			atomicAdd(out_found, 1);
			break;
		}
		else
		{
			nonce += gridDim.x * blockDim.x;
			trialCnt++;
		}
		if ((trialCnt % 5) == 0 && (*out_found != 0))
			break;
	}
}

void pre_sha256_error_check()
{
	// cuda error check
	checkCudaErrors(cudaMemcpyToSymbol(dev_k, host_k, sizeof(host_k), 0, cudaMemcpyHostToDevice));
}

// Prints a 32 bytes sha256 to the hexadecimal form filled with zeroes
void print_hash(const unsigned char *sha256)
{
	for (uint8_t i = 0; i < 32; ++i)
	{
		std::cout << std::hex << std::setfill('0') << std::setw(2) << static_cast<int>(sha256[i]);
	}
	std::cout << std::dec << std::endl;
}

Signature forgeSig(Message forge_msg,
				   int sigIndex[],
				   std::vector<Signature> &sigs,
				   std::vector<Message> &msgs)
{
	Signature sig;
	for (int i = 0; i < 256; i++)
	{
		if ((forge_msg[i / 8] >> (7 - (i % 8)) & 0x01) == 1 && sigIndex[i + 256] != -1)
		{
			sig.Preimage[i] = sigs[sigIndex[i + 256]].Preimage[i];
		}
		else if ((forge_msg[i / 8] >> (7 - (i % 8)) & 0x01) == 0 && sigIndex[i + 256] != -1)
		{
			sig.Preimage[i] = sigs[sigIndex[i]].Preimage[i];
		}
		else
		{
			std::cout << "Won't be able to forge signature with the given message" << std::endl;
			break;
		}
	}
	return sig;
}

// for debug purpose
void print_bits(unsigned char block[])
{
	for (int cur_byte = 0; cur_byte < 32; ++cur_byte)
	{
		unsigned char bk = block[cur_byte];
		for (int j = 7; j >= 0; j--)
		{
			unsigned char mask = 1 << j;
			if (((bk & mask) >> j) == 0)
				std::cout << "0";
			if (((bk & mask) >> j) == 1)
				std::cout << "1";
		}
	}
	std::cout << std::endl;
}

int main()
{
	// Load and check given public key and signatures
	std::unordered_map<std::string, std::string> global_variables = globalVariables();
	PublicKey pub = HexToPublickey(global_variables["hexPubkey1"]);
	Signature sig1 = HexToSignature(global_variables["hexSignature1"]);
	Signature sig2 = HexToSignature(global_variables["hexSignature2"]);
	Signature sig3 = HexToSignature(global_variables["hexSignature3"]);
	Signature sig4 = HexToSignature(global_variables["hexSignature4"]);
	std::vector<Signature> sigs;
	sigs.push_back(sig1);
	sigs.push_back(sig2);
	sigs.push_back(sig3);
	sigs.push_back(sig4);
	Message msg1 = GetMessageFromString(global_variables["msg1_string"]);
	Message msg2 = GetMessageFromString(global_variables["msg2_string"]);
	Message msg3 = GetMessageFromString(global_variables["msg3_string"]);
	Message msg4 = GetMessageFromString(global_variables["msg4_string"]);
	std::vector<Message> msgs;
	msgs.push_back(msg1);
	msgs.push_back(msg2);
	msgs.push_back(msg3);
	msgs.push_back(msg4);

	// verify public keys and signatures
	if (Verify(msg1, pub, sig1))
	{
		std::cout << "sig 1 is verified" << std::endl;
	}
	else
	{
		std::cout << "sig 1 failed to verify" << std::endl;
	}
	if (Verify(msg2, pub, sig2))
	{
		std::cout << "sig 2 is verified" << std::endl;
	}
	else
	{
		std::cout << "sig 2 failed to verify" << std::endl;
	}
	if (Verify(msg3, pub, sig3))
	{
		std::cout << "sig 3 is verified" << std::endl;
	}
	else
	{
		std::cout << "sig 3 failed to verify" << std::endl;
	}
	if (Verify(msg4, pub, sig4))
	{
		std::cout << "sig 4 is verified" << std::endl;
	}
	else
	{
		std::cout << "sig 4 failed to verify" << std::endl;
	}

	// invidividualized message
	std::string msgStringPre = "forge cuda houstonj2013 2024-02-17 ";
	std::cout << "The current message is " << msgStringPre << std::endl;
	std::cout << "Do you want to use new message : (Yes/No)" << std::endl;
	string useNewMsg;
	std::cin >> useNewMsg;
	if (useNewMsg == "Yes" || useNewMsg == "yes")
	{
		std::cout << "Please enter the new message: " << std::endl;
		std::cin >> msgStringPre;
		std::cout << "The new message is : " + msgStringPre << std::endl;
	}
	else
	{
		std::cout << "Still use current message: " << msgStringPre << std::endl;
	}

	std::vector<std::pair<bool, bool>> known_bits(256, {false, false});
	int sigIndex[512] = {-1};
	for (int si = 0; si < msgs.size(); si++)
	{
		Message tempMsg = msgs[si];
		for (int i = 0; i < 256; i++)
		{
			if ((tempMsg[i / 8] >> (7 - (i % 8)) & 0x01) == 1)
			{
				known_bits[i].second = true;
				sigIndex[i + 256] = si;
			}
			else
			{
				known_bits[i].first = true;
				sigIndex[i] = si;
			}
		}
	}
	std::vector<int> zeroConstraints, oneConstraints;
	for (int i = 0; i < 256; i++)
	{
		if (!known_bits[i].first && known_bits[i].second)
			oneConstraints.push_back(i);
		if (known_bits[i].first && !known_bits[i].second)
			zeroConstraints.push_back(i);
	}

	std::cout << "There are " << oneConstraints.size() << " one constraints and " << zeroConstraints.size() << " zero constraints " << std::endl;

	std::string foundMessageString = "forge cuda houstonj2013 2024-02-17 228144973047";

	std::cout << "The saved forge message is " << foundMessageString << std::endl;
	std::cout << "Do you want to use the saved forge: (Yes/No):" << std::endl;
	string useSavedForge;
	std::cin >> useSavedForge;

	if (useSavedForge == "Yes" || useSavedForge == "yes")
	{
		Message foundMsg = GetMessageFromString(foundMessageString);
		std::cout << "The found message is: " << foundMsg.ToHex() << std::endl;
		Signature sig = forgeSig(foundMsg, sigIndex, sigs, msgs);

		if (Verify(foundMsg, pub, sig))
		{
			std::cout << foundMessageString << " was verified to be able to forge signature" << std::endl;
		}
		else
		{
			std::cout << "saved forge " + foundMessageString << " can't be verified" << std::endl;
		}
	}
	else
	{
		cudaSetDevice(0);
		cudaDeviceSetCacheConfig(cudaFuncCachePreferShared);

		t_last_updated = std::chrono::high_resolution_clock::now();

		std::string in = msgStringPre;
		nonce = 1;

		auto start = high_resolution_clock::now();
		const size_t input_size = in.size();

		// Input string for the device
		char *d_in = nullptr;

		// Create the input string for the device
		cudaMalloc(&d_in, input_size + 1); // c string has one more length than cpp string
		cudaMemcpy(d_in, in.c_str(), input_size + 1, cudaMemcpyHostToDevice);

		// create fixed length array for cuda
		int h_zeroConstraints[256] = {-1}, h_oneConstraints[256] = {-1};
		int zeroSize = zeroConstraints.size(), oneSize = oneConstraints.size();
		for (int i = 0; i < zeroSize; i++)
			h_zeroConstraints[i] = zeroConstraints[i];
		for (int i = 0; i < oneSize; i++)
			h_oneConstraints[i] = oneConstraints[i];

		int *d_zeroConstraints = nullptr;
		int *d_oneConstraints = nullptr;
		cudaMalloc(&d_zeroConstraints, 256);
		cudaMalloc(&d_oneConstraints, 256);
		cudaMemcpy(d_zeroConstraints, h_zeroConstraints, 256, cudaMemcpyHostToDevice);
		cudaMemcpy(d_oneConstraints, h_oneConstraints, 256, cudaMemcpyHostToDevice);

		cudaMallocManaged(&g_out, input_size + 32 + 1);
		cudaMallocManaged(&g_hash_out, 32);
		cudaMallocManaged(&g_found, sizeof(int));
		*g_found = 0;

		nonce += user_nonce;
		last_nonce_since_update += user_nonce;

		pre_sha256_error_check();

		size_t dynamic_shared_size = (ceil((input_size + 1) / 8.f) * 8) + (64 * BLOCK_SIZE) + 256 * 2;

		std::cout << "Shared memory is " << dynamic_shared_size / 1024 << "KB" << std::endl;
		std::cout << "Kernel Numblocks: " << NUMBLOCKS << " Block size: " << BLOCK_SIZE << std::endl;

		forge_kernel<<<NUMBLOCKS, BLOCK_SIZE, dynamic_shared_size>>>(g_out,
																	 g_hash_out,
																	 g_found,
																	 d_in,
																	 input_size,
																	 d_zeroConstraints,
																	 d_oneConstraints,
																	 zeroSize,
																	 oneSize,
																	 nonce);

		cudaError_t err = cudaDeviceSynchronize();
		if (err != cudaSuccess)
		{
			throw std::runtime_error("Device error");
		}

		string foundString = g_out;
		Message foundMsg = GetMessageFromString(foundString);
		std::cout << "The found message is: " << foundMsg.ToHex() << std::endl;
		Signature sig = forgeSig(foundMsg, sigIndex, sigs, msgs);

		if (Verify(foundMsg, pub, sig))
		{
			std::cout << foundString << " was verified to be able to forge signature" << std::endl;
		}
		else
		{
			std::cout << "new forged string " + foundString << " can't be verified" << std::endl;
		}

		// if (verifyForge(g_out, known_blocks, pub))
		// {
		// 	std::cout << g_out << " was found to be able to forge signature" << std::endl;
		// }

		cudaFree(g_out);
		cudaFree(g_hash_out);
		cudaFree(g_found);
		cudaFree(d_zeroConstraints);
		cudaFree(d_oneConstraints);
		cudaFree(d_in);

		cudaDeviceReset();

		auto stop = high_resolution_clock::now();
		auto duration = duration_cast<milliseconds>(stop - start);
		cout << "program takes " << duration.count() / 1000.f << " seconds to run" << endl;
	}
	return 0;
}
