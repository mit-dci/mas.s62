package main

import (
	"strings"
	"testing"
)

// TestForgery tests the Forge() function to see that it produces a valid
// signature from the hardcoded public key.
// If this test passes along with the other tests, the forgery has worked.
func TestForgery(t *testing.T) {

	// get pubkey from global variable
	pub, err := HexToPubkey(hexPubkey1)
	if err != nil {
		t.Fatal(err)
	}

	// Note that this tests calls forge which can take quite a while.
	// One way to make this a lot faster is that once you find a forged signature,
	// you can change the code in Forge() to start right before it hits the
	// forgery, so that runtime of Forge() is very quick.
	// The fact that you know to stat at iteration 2 billion or so is good
	// evidence that you've already done the CPU work before.
	forgedString, forgedSig, err := Forge()
	if err != nil {
		t.Fatal(err)
	}

	// make sure that the message for the forged signature contains the string
	// "forge" in it.  This ensures that it's different from the 4 signed
	// messages provided.  It should also have the forger's name in it, but
	// we don't check that here.

	if !strings.Contains(forgedString, "forge") {
		t.Fatalf("Error: Forged message:\n%s\n does not contain substring 'forge'",
			forgedString)
	}

	// report the correct string here
	t.Logf("Forged message string:\n%s\n cointains substring 'forge'; OK",
		forgedString)

	forgedMsg := GetMessageFromString(forgedString)

	// verify signature
	worked := Verify(forgedMsg, pub, forgedSig)

	if !worked {
		t.Fatalf("Verify returned false, expected true")
	}

}
