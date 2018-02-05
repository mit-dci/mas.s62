// Problem set 01: Hash based signatures.

// A lot of this lab is set up and templated for you to get used to
// what may be an unfamiliar language (Go).  Go is syntactically
// similar to C / C++ in many ways, including comments.

// In this pset, you need to build a hash based signature system.  We'll use sha256
// as our hash function, and Lamport's simple signature design.

// Currently this compiles but doesn't do anything.  For the first lab
// the whole thing can live in just one package and one file: main.go.

package main

import (
	"crypto/sha256"
	"fmt"
)

func main() {

	// Define your message
	textString := "Hello there,"
	fmt.Printf("%s\n", textString)

	// convert message into a block
	m := GetMessageFromString(textString)
	fmt.Printf("%x\n", m[:])

	// generate keys
	sec, pub, err := GenerateKey()
	if err != nil {
		panic(err)
	}

	// sign message
	sig := Sign(m, sec)

	// verify signature
	worked := Verify(m, pub, sig)

	// done
	fmt.Printf("Verify worked? %v\n", worked)
	return
}

// Signature systems have 3 functions: GenerateKey(), Sign(), and Verify().
// We'll also define the data types: SecretKey, PublicKey, Message, Signature.

// --- Types

// A block of data is always 32 bytes long; we're using sha256 and this
// is the size of both the output (defined by the hash function) and our inputs
type Block [32]byte

type SecretKey struct {
	ZeroPre [256]Block
	OnePre  [256]Block
}

type PublicKey struct {
	ZeroHash [256]Block
	OneHash  [256]Block
}

// A message to be signed is just a block.
type Message Block

// --- Methods on the Block type

// Hash returns the sha256 hash of the block.
func (self Block) Hash() Block {
	return sha256.Sum256(self[:])
}

// IsPreimage returns true if the block is a preimage of the argument.
// For example, if Y = hash(X), then X.IsPreimage(Y) will return true,
// and Y.IsPreimage(X) will return false.
func (self Block) IsPreimage(arg Block) bool {
	return self.Hash() == arg
}

// A signature consists of 32 blocks.  It's a selective reveal of the private
// key, according to the bits of the message.
type Signature struct {
	Preimage [256]Block
}

// ToHex returns a hex string of a signature
func (self Signature) ToHex() string {
	var s string
	for _, b := range self.Preimage {
		s += fmt.Sprintf("%x", b[:])
	}
	s += fmt.Sprintf("\n")
	return s
}

// GetMessageFromString returns a Message which is the hash of the given string.
func GetMessageFromString(s string) Message {
	return sha256.Sum256([]byte(s))
}

// --- Functions

// GenerateKey takes no arguments, and returns a keypair and potentially an
// error.  It gets randomness from the OS via crypto/rand
// This can return an error if there is a problem with reading random bytes
func GenerateKey() (SecretKey, PublicKey, error) {
	// initialize SecretKey variable 'sec'.  Starts with all 00 bytes.
	var sec SecretKey
	var pub PublicKey

	// Your code here

	return sec, pub, nil
}

// Sign takes a message and secret key, and returns a signature.
func Sign(msg Message, sec SecretKey) Signature {
	var sig Signature

	// Your code here

	return sig
}

// Verify takes a message, public key and signature, and returns a boolean
// describing the validity of the signature.
func Verify(msg Message, pub PublicKey, sig Signature) bool {

	// Your code here

	return false
}
