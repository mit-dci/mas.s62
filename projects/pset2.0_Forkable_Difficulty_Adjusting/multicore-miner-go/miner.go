package main

import (
	"math"
)

// This file is for the mining code.
// Note that "targetBits" for this assignment, at least initially, is 33.
// This could change during the assignment duration!  I will post if it does.

// Mine mines a block by varying the nonce until the hash has targetBits 0s in
// the beginning.  Could take forever if targetBits is too high.
// Modifies a block in place by using a pointer receiver.
func (self *Block) ValidMine(targetBits float64) bool {
	// your mining code here
	// also feel free to get rid of this method entirely if you want to
	// organize things a different way; this is just a suggestion
	totalCount := 0.0
	firstOne := true
	pastFirstOneCount := 0.0

	for i := 0; i < 32; i++ {
		currentByte := self.Hash()[i]
		for j := 128; j >= 1; j = j / 2 {
			if pastFirstOneCount >= 10 {
				break
			}
			if int(currentByte)&j != 0 {
				if firstOne == true {
					firstOne = false
					pastFirstOneCount += 1
				} else {
					pastFirstOneCount += 1
				}
			} else {
				if firstOne == true {
					totalCount += 1
				} else {
					totalCount += 1 / math.Pow(2.0, pastFirstOneCount)
					pastFirstOneCount += 1
				}

			}

		}
		if pastFirstOneCount >= 10 {
			break
		}
	}
	// fmt.Println(self.Hash())
	// fmt.Println(totalCount)
	if totalCount >= targetBits {
		return true
	}
	return false
}
