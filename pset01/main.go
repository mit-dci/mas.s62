/* This is problem set 01: Hash based signatures.
A lot of this lab is set up and templated for you to get used to
what may be an unfamiliar language (golang).
Golang is syntactically similar to c / c++ in many ways, including comments.
There are some good golang tutorials if you want to learn more.

In this pset, you need to build a hash based signature system.  We'll use sha256
as our hash function, and Lamports simple signature design.

*/

/*

Currently this compiles but doesn't do anything.
For the first lab the whole thing can live in just one package and one file:
main.go.

*/

package main

import (
	"crypto/sha256"
	"fmt"
)

func main() {
	fmt.Printf("hi\n")
}

// Signature systems have 3 functions: GenerateKey(), Sign(), and Verify().
// We'll also define the data types: SecretKey, PublicKey, Message, Signature.

// --- Types

// A block of data is always 32 bytes long; we're using sha256 and this
// is the size of both the output (defined by the hash function) and our inputs
type Block [32]byte

type SecretKey struct {
	ZeroPre [32]Block
	OnePre  [32]Block
}

type PublicKey struct {
	ZeroHash [32]Block
	OneHash  [32]Block
}

// A message to be signed is just a block.
type Message Block

// A signature consists of 32 blocks.  It's a selective reveal of the private
// key, according to the bits of the message.
type Signature struct {
	Preimage [32]Block
}

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

// --- Functions

// GenerateKey takes no arguments, and returns a keypair and potentially an
// error.  It gets randomness from the OS via crypto/rand
func GenerateKey() (SecretKey, PublicKey, error) {
	// initialize SecretKey variable 'sec'.  Starts with all 00 bytes.
	var sec SecretKey

	var pub PublicKey

	return sec, pub, nil
}

// Sign takes a message and secret key, and returns a signature.
func Sign(Message, SecretKey) Signature {
	var sig Signature

	return sig
}

// Verify takes a message, public key and signature, and returns a boolean
// describing the validity of the signature.
func Verify(Message, PublicKey, Signature) bool {
	return false
}
