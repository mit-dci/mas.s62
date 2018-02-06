package main

import "fmt"

// code for forging signatures to fill in

// Geordi
func Forge() {
	// decode pubkey, all 4 signatures into usable structures from hex strings
	pub, err := HexToPubkey(hexPubkey1)
	if err != nil {
		panic(err)
	}

	sig1, err := HexToSignature(hexSignature1)
	if err != nil {
		panic(err)
	}
	sig2, err := HexToSignature(hexSignature2)
	if err != nil {
		panic(err)
	}
	sig3, err := HexToSignature(hexSignature3)
	if err != nil {
		panic(err)
	}
	sig4, err := HexToSignature(hexSignature4)
	if err != nil {
		panic(err)
	}

	var marr []Message

	marr = append(marr, GetMessageFromString("1"))
	marr = append(marr, GetMessageFromString("2"))
	marr = append(marr, GetMessageFromString("3"))
	marr = append(marr, GetMessageFromString("4"))

	fmt.Printf("ok 1: %v\n", Verify(marr[0], pub, sig1))
	fmt.Printf("ok 2: %v\n", Verify(marr[1], pub, sig2))
	fmt.Printf("ok 3: %v\n", Verify(marr[2], pub, sig3))
	fmt.Printf("ok 4: %v\n", Verify(marr[3], pub, sig4))

	// your code here!
	// ==

	// ==

}
