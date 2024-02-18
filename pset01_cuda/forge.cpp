#include <iostream>
#include <iomanip>
#include <cstring>
#include <vector>
#include <atomic>
#include <cstdio>
#include <thread>
#include <unordered_map>
#include <chrono>
#include "lamport.h"
#include "signatures.h"
using namespace std::chrono;

using std::cout;
using std::endl;
using std::string;

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

bool verifyforgeSpeed(Message mymsg,
                      std::vector<int> &zeroConstraints,
                      std::vector<int> &oneConstraints)
{
    for (auto zeroIndex : zeroConstraints)
    {
        if ((mymsg[zeroIndex / 8] >> (7 - (zeroIndex % 8)) & 0x01) == 1)
        {
            // std::cout << "zero " << zeroIndex << " failed " << std::endl;
            return false;
        }
    }

    for (auto oneIndex : oneConstraints)
    {
        if ((mymsg[oneIndex / 8] >> (7 - (oneIndex % 8)) & 0x01) == 0)
        {
            // std::cout << "one " << oneIndex << " failed " << std::endl;
            return false;
        }
    }

    return true;
}

void ForgeWorker(
    int worker_id,
    const std::string forge_string_pre,
    std::vector<int> &zeroConstraints,
    std::vector<int> &oneConstraints,
    std::string &forge_string,
    std::atomic<bool> *found_forge)
{
    unsigned long numTries = 0;
    string nounce_pre = "w " + std::to_string(worker_id) + " + ";
    string trial;
    bool foundForge = false;
    Message mymsg;
    std::cout << "start worker " << worker_id << std::endl;

    while (true)
    {

        numTries++;
        if (numTries % 5000000 == 0)
        {
            std::cout << "workder " << worker_id << " reached " << numTries << " trials" << std::endl;
        }

        trial = forge_string_pre + nounce_pre + std::to_string(numTries);
        mymsg = GetMessageFromString(trial);
        foundForge = verifyforgeSpeed(mymsg, zeroConstraints, oneConstraints);
        if (foundForge)
        {
            (*found_forge).store(true);
            forge_string = trial;
            break;
        }

        if (numTries % 100 == 0)
        {
            if ((*found_forge).load())
            {
                break;
            }
        }
    }
}

int main(int argc, char *argv[])
{

    // start time
    auto start = high_resolution_clock::now();

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
    std::string msgStringPre = "forge houstonj2013 2024-02-16 ";
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
    for (auto z : zeroConstraints)
        std::cout << z << " ";
    std::cout << std::endl;
    for (auto z : oneConstraints)
        std::cout << z << " ";
    std::cout << std::endl;

    std::string foundMessageString = "forge houstonj2013 2024-02-16 w 357 + 4278692";

    std::cout << "The saved forge message is " << foundMessageString << std::endl;
    std::cout << "Do you want to use the saved forge: (Yes/No):" << std::endl;
    string useSavedForge;
    std::cin >> useSavedForge;

    if (useSavedForge == "Yes" || useSavedForge == "yes")
    {
        Message foundMsg = GetMessageFromString(foundMessageString);
        std::cout << "The found message is: " << foundMsg.ToHex() << std::endl;
        if (verifyforgeSpeed(foundMsg, zeroConstraints, oneConstraints))
        {
            std::cout << "The found message is verified by speed check" << std::endl;
        }
        Signature sig = forgeSig(foundMsg, sigIndex, sigs, msgs);

        if (Verify(foundMsg, pub, sig))
        {
            std::cout << foundMessageString << " was found to be able to forge signature" << std::endl;
        }
        else
        {
            std::cout << "saved forge " + foundMessageString << " can't be verified" << std::endl;
        }
    }
    else
    {
        // Speed up search
        const int num_threads = 1000;
        std::vector<std::thread> threads;
        std::string forge_string;
        std::atomic<bool> found_forge{false};

        for (int i = 0; i < num_threads; i++)
        {
            threads.push_back(std::thread(&ForgeWorker,
                                          i,
                                          msgStringPre,
                                          std::ref(zeroConstraints),
                                          std::ref(oneConstraints),
                                          std::ref(forge_string),
                                          &found_forge));
        }
        for (auto &th : threads)
        {
            th.join();
        }
        if (found_forge.load())
        {
            Message foundMsg = GetMessageFromString(forge_string);
            Signature sig = forgeSig(foundMsg, sigIndex, sigs, msgs);

            if (Verify(foundMsg, pub, sig))
            {
                std::cout << "forge signature string found: " << forge_string << std::endl;
            }
        }
        auto stop = high_resolution_clock::now();
        auto duration = duration_cast<seconds>(stop - start);
        cout << "program takes " << duration.count() << " seconds to run" << endl;
    }

    return 0;
}
