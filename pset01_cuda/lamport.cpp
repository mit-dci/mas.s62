#include <iostream>
#include <sstream>
#include <fstream>
#include <cstring>
#include <iomanip>
#include <ctime>
#include "lamport.h"
#include "sha256.h"

std::string Block::ToHex()
{
    std::stringstream ss;
    ss << std::hex;
    for (int i = 0; i < 32; ++i)
        ss << std::setw(2) << std::setfill('0') << (int)data[i];
    return ss.str();
}

Block Block::Hash()
{
    Block hash;
    memset(hash.data, 0, SHA256::DIGEST_SIZE);
    SHA256 ctx = SHA256();
    ctx.init();
    ctx.update(data, 32);
    ctx.final(hash.data);
    return hash;
}

bool Block::IsPreimage(Block &b)
{
    Block block_hash = Hash();
    return std::equal(std::begin(b.data), std::end(b.data), std::begin(block_hash.data));
}

bool Block::operator==(const Block &other)
{
    return std::equal(std::begin(data), std::end(data), std::begin(other.data));
}

unsigned char &Block::operator[](int idx)
{
    return data[idx];
}

std::string BlockToHex(Block &b)
{
    std::stringstream ss;
    ss << std::hex;
    for (int i = 0; i < 32; ++i)
        ss << std::setw(2) << std::setfill('0') << (int)b[i];
    return ss.str();
}

Block HexToBlock(std::string hex)
{
    Block b;
    int n = hex.length();
    if (n != 64)
    {
        std::cout << "the hex string doesn't match the block size: " << hex << std::endl;
    }
    for (int i = 0; i < 32; i++)
    {
        std::string bytestring = hex.substr(i * 2, 2);
        b[i] = (unsigned char)strtol(bytestring.c_str(), NULL, 16);
    }
    return b;
}

std::string SecretKey::ToHex()
{
    std::string s;
    for (auto b : ZeroPre)
    {
        s += b.ToHex();
    }
    for (auto b : OnePre)
    {
        s += b.ToHex();
    }
    return s;
}

PublicKey HexToPublickey(std::string hex)
{
    PublicKey pub;
    int expected_length = 256 * 2 * 64;
    if (hex.length() != expected_length)
    {
        std::cout << "The hex string doesn't match the pubkey size" << std::endl;
    }
    for (int i = 0; i < 256; i++)
    {
        std::string block_hex = hex.substr(i * 64, 64);
        pub.ZeroHash[i] = HexToBlock(block_hex);
    }
    for (int i = 256; i < 512; i++)
    {
        std::string block_hex = hex.substr(i * 64, 64);
        pub.OneHash[i - 256] = HexToBlock(block_hex);
    }
    return pub;
}

std::string PublicKey::ToHex()
{
    std::string s;
    for (auto b : ZeroHash)
    {
        s += b.ToHex();
    }
    for (auto b : OneHash)
    {
        s += b.ToHex();
    }
    return s;
}

bool PublicKey::operator==(const PublicKey &other)
{
    bool pub_equal = false;
    for (int i = 0; i < 256; i++)
    {
        if (ZeroHash[i] == other.ZeroHash[i])
        {
            pub_equal = true;
        }
        else
        {
            return false;
        }
        if (OneHash[i] == other.OneHash[i])
        {
            pub_equal = true;
        }
        else
        {
            return false;
        }
    }
    return pub_equal;
}

std::string Signature::ToHex()
{
    std::string s;
    for (auto b : Preimage)
    {
        s += b.ToHex();
    }
    return s;
}

bool Signature::operator==(const Signature &other)
{
    bool sig_equal = false;
    for (int i = 0; i < 256; i++)
    {
        if (Preimage[i] == other.Preimage[i])
        {
            sig_equal = true;
        }
        else
        {
            return false;
        }
    }
    return sig_equal;
}

Signature HexToSignature(std::string hex)
{
    Signature sig;
    int expected_length = 256 * 64;
    if (hex.length() != expected_length)
    {
        std::cout << "The hex string doesn't match the signature size" << std::endl;
    }
    for (int i = 0; i < 256; i++)
    {
        std::string block_hex = hex.substr(i * 64, 64);
        sig.Preimage[i] = HexToBlock(block_hex);
    }
    return sig;
}

Block GenerateRandomBlock()
{
    Block b;
    for (int i = 1; i < 32; i++)
    {
        int random_int = std::rand() % 256;
        b[i] = char(random_int);
    }
    return b;
}

Key GenerateKey()
{
    Key key;
    for (int i = 0; i < 256; i++)
    {
        key.sec.ZeroPre[i] = GenerateRandomBlock();
        key.sec.OnePre[i] = GenerateRandomBlock();
        key.pub.ZeroHash[i] = key.sec.ZeroPre[i].Hash();
        key.pub.OneHash[i] = key.sec.OnePre[i].Hash();
    }
    return key;
}

Signature Sign(Message &msg, SecretKey &sec)
{
    Signature sig;

    for (int i = 0; i < 256; i++)
    {
        if ((msg[i / 8] >> (7 - (i % 8)) & 0x01) == 1)
        {
            sig.Preimage[i] = sec.OnePre[i];
        }
        else
        {
            sig.Preimage[i] = sec.ZeroPre[i];
        }
    }
    return sig;
}

bool Verify(Message &msg, PublicKey &pub, Signature &sig)
{
    for (int i = 0; i < 256; i++)
    {
        if ((msg[i / 8] >> (7 - (i % 8)) & 0x01) == 0)
        {
            if (!(sig.Preimage[i].Hash() == pub.ZeroHash[i]))
            {
                return false;
            }
        }
        else
        {
            if (!(sig.Preimage[i].Hash() == pub.OneHash[i]))
            {
                return false;
            }
        }
    }
    return true;
}

Message GetMessageFromString(std::string s)
{
    Message msg;
    memset(msg.data, 0, SHA256::DIGEST_SIZE);
    SHA256 ctx = SHA256();
    ctx.init();
    ctx.update((unsigned char *)s.c_str(), s.length());
    ctx.final(msg.data);
    return msg;
}

std::string GenerateRandomString(int n)
{
    const std::string letters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-";
    std::string random_string;
    for (int i = 0; i < n; i++)
    {
        random_string += letters[std::rand() % letters.length()];
    }
    return random_string;
}

std::string GenerateRandomStringXorshift(int n, xorshiftPRNG &xorprng)
{
    const std::string letters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-";
    std::string random_string;
    for (int i = 0; i < n; i++)
    {
        random_string += letters[xorprng.xorshift32(letters.length())];
    }
    return random_string;
}