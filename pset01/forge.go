package main

import (
	"encoding/hex"
	"fmt"
	"runtime"
	"time"
)

/*
A note about the provided keys and signatures:
the provided pubkey and signature, as well as "HexTo___" functions may not work
with all the different implementations people could built.  Specifically, they
are tied to an endian-ness.  If, for example, you decided to encode your public
keys as (according to the diagram in the slides) up to down, then left to right:
<bit 0, row 0> <bit 0, row 1> <bit 1, row 0> <bit 1, row 1> ...

then it won't work with the public key provided here, because it was encoded as
<bit 0, row 0> <bit 1, row 0> <bit 2, row 0> ... <bit 255, row 0> <bit 0, row 1> ...
(left to right, then up to down)

so while in class I said that any decisions like this would work as long as they
were consistent... that's not actually the case!  Because your functions will
need to use the same ordering as the ones I wrote in order to create the signatures
here.  I used what I thought was the most straightforward / simplest encoding, but
endian-ness is something of a tabs-vs-spaces thing that people like to argue
about :).

So for clarity, and since it's not that obvious from the HexTo___ decoding
functions, here's the order used:

secret keys and public keys:
all 256 elements of row 0, most significant bit to least significant bit
(big endian) followed by all 256 elements of row 1.  Total of 512 blocks
of 32 bytes each, for 16384 bytes.
For an efficient check of a bit within a [32]byte array using this ordering,
you can use:
    arr[i/8]>>(7-(i%8)))&0x01
where arr[] is the byte array, and i is the bit number; i=0 is left-most, and
i=255 is right-most.  The above statement will return a 1 or a 0 depending on
what's at that bit location.

Messages: messages are encoded the same way the sha256 function outputs, so
nothing to choose there.

Signatures: Signatures are also read left to right, MSB to LSB, with 256 blocks
of 32 bytes each, for a total of 8192 bytes.  There is no indication of whether
the provided preimage is from the 0-row or the 1-row; the accompanying message
hash can be used instead, or both can be tried.  This again interprets the message
hash in big-endian format, where
    message[i/8]>>(7-(i%8)))&0x01
can be used to determine which preimage block to reveal, where message[] is the
message to be signed, and i is the sequence of bits in the message, and blocks
in the signature.

Hopefully people don't have trouble with different encoding schemes.  If you
really want to use your own method which you find easier to work with or more
intuitive, that's OK!  You will need to re-encode the key and signatures provided
in signatures.go to match your ordering so that they are valid signatures with
your system.  This is probably more work though and I recommend using the big
endian encoding described here.

*/

// Forge is the forgery function, to be filled in and completed.  This is a trickier
// part of the assignment which will require the computer to do a bit of work.
// It's possible for a single core or single thread to complete this in a reasonable
// amount of time, but may be worthwhile to write multithreaded code to take
// advantage of multi-core CPUs.  For programmers familiar with multithreaded code
// in golang, the time spent on parallelizing this code will be more than offset by
// the CPU time speedup.  For programmers with access to 2-core or below CPUs, or
// who are less familiar with multithreaded code, the time taken in programming may
// exceed the CPU time saved.  Still, it's all about learning.
// The Forge() function doesn't take any inputs; the inputs are all hard-coded into
// the function which is a little ugly but works OK in this assigment.
// The input public key and signatures are provided in the "signatures.go" file and
// the code to convert those into the appropriate data structures is filled in
// already.
// Your job is to have this function return two things: A string containing the
// substring "forge" as well as your name or email-address, and a valid signature
// on the hash of that ascii string message, from the pubkey provided in the
// signatures.go file.
// The Forge function is tested by TestForgery() in forge_test.go, so if you
// run "go test" and everything passes, you should be all set.
func Forge() (string, Signature, error) {
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

	var sigslice []Signature
	sigslice = append(sigslice, sig1)
	sigslice = append(sigslice, sig2)
	sigslice = append(sigslice, sig3)
	sigslice = append(sigslice, sig4)

	var msgslice []Message

	msgslice = append(msgslice, GetMessageFromString("1"))
	msgslice = append(msgslice, GetMessageFromString("2"))
	msgslice = append(msgslice, GetMessageFromString("3"))
	msgslice = append(msgslice, GetMessageFromString("4"))

	fmt.Printf("ok 1: %v\n", Verify(msgslice[0], pub, sig1))
	fmt.Printf("ok 2: %v\n", Verify(msgslice[1], pub, sig2))
	fmt.Printf("ok 3: %v\n", Verify(msgslice[2], pub, sig3))
	fmt.Printf("ok 4: %v\n", Verify(msgslice[3], pub, sig4))

	msgStringPre := "forge houstonj2013 2024-02-16 "

	startTime := time.Now()

	var useNewMsg string
	fmt.Printf("The current message is %s", msgStringPre)
	fmt.Println("Do you want to use new message: (Yes/No):")
	fmt.Scanln(&useNewMsg)
	if useNewMsg == "Yes" || useNewMsg == "yes" {
		fmt.Println("Please enter the new message: ")
		fmt.Scanln(&msgStringPre)
		fmt.Println("The new message is :" + msgStringPre)
	} else {
		fmt.Println("Still use current message:" + msgStringPre)
	}

	// your code here!
	// ==
	// Get the secret keys from known signature
	// Randomly guess the unknown secret keys and verify the message and public keys
	// Add nounces into my message as a variance in the random guess

	// get the known screate keys and save in a map; map key from 0 - 511,

	known_bits := make([][]bool, 256)
	sig_index := make([]int, 512)
	for i := 0; i < 512; i++ {
		sig_index[i] = -1
	}
	for i := 0; i < 256; i++ {
		known_bits[i] = make([]bool, 2)
		known_bits[i][0] = false
		known_bits[i][1] = false
	}
	for mi, Imsg := range msgslice {
		for i := 0; i < 256; i++ {
			if Imsg[i/8]>>(7-(i%8))&0x01 == 1 {
				known_bits[i][1] = true
				sig_index[i+256] = mi
			} else {
				known_bits[i][0] = true
				sig_index[i] = mi
			}
		}
	}
	var zeroConstraints []int
	var oneConstraints []int
	for i := 0; i < 256; i++ {
		if known_bits[i][0] == false && known_bits[i][1] == true {
			oneConstraints = append(oneConstraints, i)
		} else if known_bits[i][1] == false && known_bits[i][0] == true {
			zeroConstraints = append(zeroConstraints, i)
		}
	}
	fmt.Printf("zero constaints %d and one constraints %d \n", len(zeroConstraints), len(oneConstraints))
	fmt.Println(zeroConstraints)
	fmt.Println(oneConstraints)

	// Explore the unknown secret keys and messages to forge a signature
	foundMessageString := "forge houstonj2013 2024-02-16 w 357 + 4278692"
	var sig Signature
	var useSavedForge string
	fmt.Printf("The current saved forge is %s \n", foundMessageString)
	fmt.Println("Do you want to use the saved forge: (Yes/No):")
	fmt.Scanln(&useSavedForge)
	if useSavedForge == "Yes" || useSavedForge == "yes" {
		foundmsg := GetMessageFromString(foundMessageString)
		for i := 0; i < 256; i++ {
			if foundmsg[i/8]>>(7-(i%8))&0x01 == 1 && sig_index[i+256] != -1 {
				sig.Preimage[i] = sigslice[sig_index[i+256]].Preimage[i]
			} else if foundmsg[i/8]>>(7-(i%8))&0x01 == 0 && sig_index[i] != -1 {
				sig.Preimage[i] = sigslice[sig_index[i]].Preimage[i]
			} else {
				break
			}
		}
		duration := time.Since(startTime)
		fmt.Println(duration)
		if Verify(foundmsg, pub, sig) {
			fmt.Printf("%s is verified  %v\n", hex.EncodeToString(foundmsg[:]), true)
			return foundMessageString, sig, nil
		} else {
			return "wrong forge", sig, nil
		}
	} else {
		var newString string
		const numJobs = 1000
		sigString := make(chan string, numJobs)
		fmt.Printf("lanching %v rountines to forge the signature \n", numJobs)
		fmt.Println("Version", runtime.Version())
		fmt.Println("NumCPU", runtime.NumCPU())
		fmt.Println("GOMAXPROCS", runtime.GOMAXPROCS(0))
		for w := 1; w <= numJobs; w++ {
			go forgeworker(w, zeroConstraints, oneConstraints, msgStringPre, sigString)
		}
		// hold until the any gorountine return the channel values
		newString = <-sigString
		foundmsg := GetMessageFromString(newString)
		for i := 0; i < 256; i++ {
			if foundmsg[i/8]>>(7-(i%8))&0x01 == 1 && sig_index[i+256] != -1 {
				sig.Preimage[i] = sigslice[sig_index[i+256]].Preimage[i]
			} else if foundmsg[i/8]>>(7-(i%8))&0x01 == 0 && sig_index[i] != -1 {
				sig.Preimage[i] = sigslice[sig_index[i]].Preimage[i]
			} else {
				break
			}
		}
		duration := time.Since(startTime)
		fmt.Println(duration)
		if Verify(foundmsg, pub, sig) {
			fmt.Printf("%s is verified  %v\n", newString, true)
			return newString, sig, nil
		} else {
			return "wrong forge", sig, nil
		}
	}

}

func forgeworker(
	workderId int,
	zeroConstraints []int,
	oneConstraints []int,
	msgStringPre string,
	sigString chan<- string) {
	nounce_pre := fmt.Sprintf("w %d + ", workderId)
	fmt.Printf("Start worker %v \n", workderId)
	var numTries uint64 = 0
	for {
		numTries++
		if numTries%5000000 == 0 {
			fmt.Printf("Worker %v has tried %v times \n", workderId, numTries)
		}

		nouncesS := nounce_pre + fmt.Sprintf("%d", numTries)
		msgString := msgStringPre
		msgString = msgStringPre + nouncesS
		// fmt.Printf("Current string %s \n", msgString)
		mymsg := GetMessageFromString(msgString)

		foundforge := true
		for _, zeroIndex := range zeroConstraints {
			if mymsg[zeroIndex/8]>>(7-(zeroIndex%8))&0x01 == 1 {
				foundforge = false
				break
			}
		}
		if !foundforge {
			continue
		}
		for _, oneIndex := range oneConstraints {
			if mymsg[oneIndex/8]>>(7-(oneIndex%8))&0x01 == 0 {
				foundforge = false
				break
			}
		}
		if foundforge {
			// return the verified string and signature
			fmt.Printf("Find a verified signature and message %s \n", msgString)
			sigString <- msgString
			break
		}

	}
}

// hint:
// arr[i/8]>>(7-(i%8)))&0x01
