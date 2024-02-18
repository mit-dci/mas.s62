#ifndef FUNCTIONS_H_INCLUDED
#define FUNCTIONS_H_INCLUDED

class xorshiftPRNG
{
private:
    struct xorshift_state
    {
        uint64_t a32;
    };
    xorshift_state state;

public:
    xorshiftPRNG(int seed)
    {
        state.a32 = seed;
    }

    uint32_t xorshift32(int max)
    {
        uint32_t x = state.a32;
        x ^= x << 17;
        x ^= x >> 7;
        x ^= x << 5;
        state.a32 = x;
        return (x % max);
    }
};
// Block definition
struct Block
{
    unsigned char data[32];
    std::string ToHex();
    Block Hash();
    bool operator==(const Block &other);
    unsigned char &operator[](int idx);
    bool IsPreimage(Block &b);
};

// message definition
typedef Block Message;

Message GetMessageFromString(std::string s);

struct SecretKey
{
    Block ZeroPre[256];
    Block OnePre[256];
    std::string ToHex();
};

struct PublicKey
{
    Block ZeroHash[256];
    Block OneHash[256];
    std::string ToHex();
    bool operator==(const PublicKey &other);
};

struct Key
{
    SecretKey sec;
    PublicKey pub;
};

struct Signature
{
    Block Preimage[256];
    std::string ToHex();
    bool operator==(const Signature &other);
};

PublicKey HexToPublickey(std::string hex);

Signature HexToSignature(std::string hex);

Block HexToBlock(std::string hex);

std::string BlockToHex(Block &b);

// Generate Random keys
Key GenerateKey();

// Generate Random Block
Block GenerateRandomBlock();

Signature Sign(Message &msg, SecretKey &sec);

bool Verify(Message &msg, PublicKey &pub, Signature &sig);

std::string GenerateRandomString(int n);

std::string GenerateRandomStringXorshift(int n, xorshiftPRNG &xorprng);
#endif