#include <iostream>
#include <ctime>
#include <chrono>
#include "sha256.h"

using std::cout;
using std::endl;
using std::string;

int main(int argc, char *argv[])
{
    string input = "test", output1;
    auto start_time = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < 100000; i++)
    {
        output1 = sha256(input);
    }
    auto end_time = std::chrono::high_resolution_clock::now();
    auto milliseconds_dif = std::chrono::duration_cast<std::chrono::milliseconds>(start_time - end_time);

    cout << "sha256 takes " << milliseconds_dif.count() << " ms" << std::endl;

    cout << "sha256('" << input << "'):" << output1 << endl;
    return 0;
}
