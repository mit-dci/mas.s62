#include <iostream>
#include <ctime>
#include <chrono>
#include <unordered_set>
#include <bits/stdc++.h>
#include <thread> // std::thread
#include <mutex>  // std::mutex
#include "lamport.h"

std::mutex mtx;
using std::cout;
using std::endl;
using std::string;

void test_Block()
{
    Block b;
    std::string hex_string = b.ToHex();
    std::string block_hex_string = BlockToHex(b);
    if (hex_string == block_hex_string)
    {
        std::cout << "Block ToHex equal BlockToHex, passed" << endl;
    }
    else
    {
        std::cout << "Block ToHex equal BlockToHex, failed" << endl;
    }

    Block b2 = HexToBlock(hex_string);
    if (b2 == b)
    {
        std::cout << "HexToBlock test  passed " << endl;
    }
    else
    {
        std::cout << "HexToBlock test  failed " << endl;
    }
    if (b2[10] == b2.data[10])
    {
        std::cout << "Block indexing test  passed " << endl;
    }
    else
    {
        std::cout << "Block indexing test  failed " << endl;
    }

    Block b_hash = b.Hash();
    bool is_preimage = b.IsPreimage(b_hash);
    if (is_preimage)
    {
        std::cout << "IsPreimage test passed " << endl;
    }
    else
    {
        std::cout << "IsPreimage test failed" << endl;
    }
}

void test_Message()
{
    Message msg;
    std::string msg_hex = msg.ToHex();
    std::cout << "Message test passed" << endl;
}

void test_PublicKey()
{
    PublicKey pub;
    std::string hex = pub.ToHex();
    PublicKey pub2 = HexToPublickey(hex);
    if (pub == pub2)
    {
        std::cout << "Pubkey to hex and back passed" << std::endl;
    }
    else
    {
        std::cout << "Pubkey to hex and back failed" << std::endl;
    }
}

void test_Signature()
{
    Signature sig;
    std::string hex = sig.ToHex();
    Signature sig2 = HexToSignature(hex);
    if (sig == sig2)
    {
        std::cout << "Signature to hex and back passed" << std::endl;
    }
    else
    {
        std::cout << "Signature to hex and back failed" << std::endl;
    }
}

void test_GenerateRandomBlock()
{
    Block b1 = GenerateRandomBlock();
    Block b2 = GenerateRandomBlock();
    if (b1 == b2)
    {
        std::cout << "GenerateRandomBlock failed" << std::endl;
    }
    else
    {
        std::cout << "GenerateRandomBlock passed" << std::endl;
    }
}

void test_GenerateKey()
{
    Key key = GenerateKey();
    bool passed = true;
    for (int i = 0; i < 256; i++)
    {
        if ((key.sec.ZeroPre[i].Hash() == key.pub.ZeroHash[i]) == false)
        {
            passed = false;
        }
        if ((key.sec.OnePre[i].Hash() == key.pub.OneHash[i]) == false)
        {
            passed = false;
        }
    }
    if (passed)
    {
        std::cout << "GenerateKey passed" << std::endl;
    }
    else
    {
        std::cout << "GenerateKey failed" << std::endl;
    }
}

void test_Sign()
{
    Message msg;
    msg = GenerateRandomBlock();
    SecretKey sec;
    Signature sig = Sign(msg, sec);
    bool passed = true;
    for (int i = 0; i < 256; i++)
    {
        if ((msg[i / 8] >> (7 - (i % 8)) & 0x01) == 0)
        {
            if (!(sig.Preimage[i] == sec.ZeroPre[i]))
            {
                std::cout << "sign failed Zero at " << i << " " << (msg[i / 8] >> (7 - (i % 8)) & 0x01) << std::endl;
                passed = false;
            }
        }
        else
        {
            if (!(sig.Preimage[i] == sec.OnePre[i]))
            {
                std::cout << "sign failed One at " << i << " " << (msg[i / 8] >> (7 - (i % 8)) & 0x01) << std::endl;
                passed = false;
            }
        }
    }
    if (passed)
    {
        std::cout << "Sign test passed" << std::endl;
    }
    else
    {
        std::cout << "Sign test failed" << std::endl;
    }
}

void test_GetMessageFromString()
{
    std::string test = "test";
    std::string expected_result = "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08";
    Message msg = GetMessageFromString(test);
    std::string test_result = BlockToHex(msg);
    if (test_result == expected_result)
    {
        std::cout << "GetMessageFromString test passed" << std::endl;
    }
    else
    {
        std::cout << "GetMessageFromString test failed" << std::endl;
    }
}

void test_Verify()
{
    std::string text_msg = "HoustonJ2013 signed";
    // std::cout << "Signed text message: " << text_msg << std::endl;
    Message msg = GetMessageFromString(text_msg);
    Key key = GenerateKey();
    // std::cout << "Pub key :" << key.pub.ToHex() << std::endl;
    Signature sig = Sign(msg, key.sec);
    // std::cout << "Signature: " << sig.ToHex() << std::endl;
    if (Verify(msg, key.pub, sig))
    {
        std::cout << "Verify test passed " << std::endl;
    }
    else
    {
        std::cout << "Verify test failed " << std::endl;
    }
}

void generateRandomStringThread(std::unordered_set<std::string> &random_set,
                                const int max_num,
                                const int worker_id)
{
    // auto now = std::chrono::high_resolution_clock::now();
    // auto duration = now.time_since_epoch();
    // auto nanoseconds = std::chrono::duration_cast<std::chrono::nanoseconds>(duration);
    std::srand(worker_id);
    for (int i = 0; i < max_num; i++)
    {

        std::string rstring = GenerateRandomString(10);
        mtx.lock();
        random_set.insert(rstring);
        mtx.unlock();
    }
}

void generateRandomStringXorshiftThread(std::unordered_set<std::string> &random_set,
                                        const int max_num,
                                        const int worker_id)
{
    // auto now = std::chrono::high_resolution_clock::now();
    // auto duration = now.time_since_epoch();
    // auto nanoseconds = std::chrono::duration_cast<std::chrono::nanoseconds>(duration);
    xorshiftPRNG xorrand(worker_id);
    for (int i = 0; i < max_num; i++)
    {

        std::string rstring = GenerateRandomStringXorshift(10, xorrand);
        mtx.lock();
        random_set.insert(rstring);
        mtx.unlock();
    }
}

void test_GenerateRandomString()
{
    std::unordered_set<std::string> random_set;
    std::vector<std::thread> threads;
    int num_threads = 20;
    const int max_num = 100000;
    auto start_time = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < num_threads; i++)
    {
        threads.push_back(std::thread(&generateRandomStringThread,
                                      std::ref(random_set),
                                      max_num,
                                      i));
    }
    for (auto &th : threads)
    {
        th.join();
    }
    auto end_time = std::chrono::high_resolution_clock::now();
    auto milliseconds_dif = std::chrono::duration_cast<std::chrono::milliseconds>(start_time - end_time);
    cout << "RandomString takes " << milliseconds_dif.count() << " ms" << std::endl;
    std::cout << "set size " << random_set.size() << " Max size:" << max_num * num_threads << std::endl;
    std::cout << "Non overlap ratio " << std::setprecision(6) << float(float(random_set.size()) / float(max_num * num_threads)) << std::endl;

    std::unordered_set<std::string> random_set2;
    std::vector<std::thread> threads2;
    auto start_time2 = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < num_threads; i++)
    {
        threads2.push_back(std::thread(&generateRandomStringXorshiftThread,
                                       std::ref(random_set2),
                                       max_num,
                                       i));
    }
    for (auto &th : threads2)
    {
        th.join();
    }
    auto end_time2 = std::chrono::high_resolution_clock::now();
    auto milliseconds_dif2 = std::chrono::duration_cast<std::chrono::milliseconds>(start_time2 - end_time2);
    cout << "RandomStringXorshift takes " << milliseconds_dif2.count() << " ms" << std::endl;

    std::cout << "set size " << random_set2.size() << " Max size:" << max_num * num_threads << std::endl;
    std::cout << "Non overlap ratio " << std::setprecision(6) << float(float(random_set2.size()) / float(max_num * num_threads)) << std::endl;
}

int main(int argc, char *argv[])
{
    test_Block();
    test_Message();
    test_PublicKey();
    test_Signature();
    test_GenerateRandomBlock();
    test_GenerateKey();
    test_Sign();
    test_GetMessageFromString();
    test_Verify();
    test_GenerateRandomString();
}
