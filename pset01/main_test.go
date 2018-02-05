// You should not need to modify this file.  We will replace
// main_test.go after submission, so all changes will be lost.

package main

import (
	"fmt"
	"testing"
)

// TestSig generates, signs, and verifies to make sure that flow works
func TestGoodSig(t *testing.T) {

	// generate message (hash of good)
	msg := GetMessageFromString("good")

	// generate keys
	sec, pub, err := GenerateKey()
	if err != nil {
		t.Fatal(err)
	}

	// sign message
	sig := Sign(msg, sec)

	// verify signature
	worked := Verify(msg, pub, sig)

	if !worked {
		t.Fatalf("Verify returned false, expected true")
	}
}

// TestBadSig signs, but then modifies the signature by hashing one of the
// blocks in it.  This should break the signature with overwhelming probability.
// Also tries to apply the signature to a completely different message
func TestBadSig(t *testing.T) {
	// generate message (hash of 1)

	msg := GetMessageFromString("bad")

	// generate keys
	sec, pub, err := GenerateKey()
	if err != nil {
		t.Fatal(err)
	}

	// sign message
	sig := Sign(msg, sec)

	// alter signature.  Hashing a part should break it except with 2^-256 chance
	sig.Preimage[16] = sig.Preimage[26].Hash()

	// verify signature
	worked := Verify(msg, pub, sig)

	if worked {
		t.Fatalf("Verify returned true, expected false")
	}

	// try with completely different message
	msg = GetMessageFromString("worse")
	worked = Verify(msg, pub, sig)

	if worked {
		t.Fatalf("Verify returned true, expected false")
	}
}

// TestGoodMany tests 1000 signatures that all should work.
func TestGoodMany(t *testing.T) {
	for i := 0; i < 1000; i++ {
		s := fmt.Sprintf("good %d", i)
		msg := GetMessageFromString(s)
		// generate keys
		sec, pub, err := GenerateKey()
		if err != nil {
			t.Fatal(err)
		}
		// sign message
		sig := Sign(msg, sec)
		// verify signature
		worked := Verify(msg, pub, sig)
		if !worked {
			t.Fatalf("Verify returned false, expected true")
		}
	}
}

// TestBadMany tests 1000 signatures, modifying all of them so that they should
// fail.
func TestBadMany(t *testing.T) {
	for i := 0; i < 1000; i++ {
		s := fmt.Sprintf("bad %d", i)
		msg := GetMessageFromString(s)
		// generate keys
		sec, pub, err := GenerateKey()
		if err != nil {
			t.Fatal(err)
		}
		// sign message
		sig := Sign(msg, sec)
		sig.Preimage[i%10] = sig.Preimage[i%11].Hash()
		// verify signature
		worked := Verify(msg, pub, sig)
		if worked {
			t.Fatalf("Verify returned true, expected false")
		}
	}
}
