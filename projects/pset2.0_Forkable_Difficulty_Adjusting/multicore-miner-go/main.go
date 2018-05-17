package main

import (
	"encoding/hex"
	"fmt"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/minio/sha256-simd"
)

// A hash is a sha256 hash, as in pset01
type Hash [32]byte

// ToString gives you a hex string of the hash
func (self Hash) ToString() string {
	return fmt.Sprintf("%x", self)
}

// Blocks are what make the chain in this pset; different than just a 32 byte array
// from last time.  Has a previous block hash, a name and a nonce.
type Block struct {
	PrevHash   Hash
	Name       string
	Nonce      string
	TargetWork float64
}

// ToString turns a block into an ascii string which can be sent over the
// network or printed to the screen.
func (self Block) ToString() string {
	return fmt.Sprintf("%x %s %s", self.PrevHash, self.Name, self.Nonce)
}

// Hash returns the sha256 hash of the block.  Hopefully starts with zeros!
func (self Block) Hash() Hash {
	return sha256.Sum256([]byte(self.ToString()))
}

// BlockFromString takes in a string and converts it to a block, if possible
func BlockFromString(s string) (Block, error) {
	var bl Block
	// check string length
	if len(s) < 66 || len(s) > 100 {
		fmt.Println("invalid length")
		return bl, fmt.Errorf("Invalid string length %d, expect 66 to 100", len(s))
	}
	// split into 3 substrings via spaces
	subStrings := strings.Split(s, " ")

	if len(subStrings) != 3 {
		return bl, fmt.Errorf("got %d elements, expect 3", len(subStrings))
	}

	hashbytes, err := hex.DecodeString(subStrings[0])
	if err != nil {
		return bl, err
	}
	if len(hashbytes) != 32 {
		return bl, fmt.Errorf("got %d byte hash, expect 32", len(hashbytes))
	}

	copy(bl.PrevHash[:], hashbytes)

	bl.Name = subStrings[1]

	// remove trailing newline if there; the blocks don't include newlines, but
	// when transmitted over TCP there's a newline to signal end of block
	bl.Nonce = strings.TrimSpace(subStrings[2])

	// TODO add more checks on name/nonce ...?

	return bl, nil
}

func main() {
	cpus := runtime.NumCPU() - 7
	fmt.Printf("Avery's Miner v1.0\n")
	argsWithoutProg := os.Args[1:]
	fmt.Println(argsWithoutProg)
	if len(argsWithoutProg) == 4 {
		cachedServerBlock = new(ServerBlock)
		cachedServerBlock.PreviousHash = argsWithoutProg[0]
		targetWork, err := strconv.ParseFloat(argsWithoutProg[1], 64)
		if err != nil {
			panic(err)
		}
		cachedServerBlock.TargetWork = targetWork
		cachedName = argsWithoutProg[2]

		cpus, err = strconv.Atoi(argsWithoutProg[3])
	} else if len(argsWithoutProg) == 1 {
		cachingEnable = false
		cpus, _ = strconv.Atoi(argsWithoutProg[0])
	}
	// Your code here!

	currentTipChannels := make([]chan Block, cpus)
	calculatedBlockChannel := make(chan Block)
	for i := 0; i < cpus; i++ {
		currentTipChannels[i] = make(chan Block)
	}

	for j := 0; j < cpus; j++ {
		go func(coreNum int, totalCPUS int, tipChannel chan Block) {
			var currentTip Block
			var count = coreNum
			var firstTip = true
			for {

				select {
				case newTip := <-tipChannel:
					// fmt.Println("received new Tip on Thread:", coreNum, ", ", newTip.ToString())
					currentTip = newTip
					count = coreNum
					firstTip = false
				default:
					if firstTip == true {
						time.Sleep(20 * time.Millisecond)
						continue
					}
					// fmt.Print(currentTip.ToString())
					stringToCheck := fmt.Sprintf("%x %v %d", currentTip.PrevHash, cachedName, count)
					// fmt.Println(stringToCheck)
					generatedBlock, err := BlockFromString(stringToCheck)
					if err != nil {
						fmt.Println(err)
					}
					if count%10000000 == 0 {
						fmt.Println(generatedBlock.ToString())
					}
					if generatedBlock.ValidMine(currentTip.TargetWork) {
						fmt.Println("Submitting block from ", coreNum)
						calculatedBlockChannel <- generatedBlock
						fmt.Println("Submitting block from ", coreNum)
					}
					count += totalCPUS
				}
			}
		}(j, cpus, currentTipChannels[j])
	}
	var currentTip Block

	for {

		select {
		case calculatedBlock := <-calculatedBlockChannel:
			tip, err := GetTipFromServer()
			if err != nil {
				fmt.Print("Error getting tip from server ")
			}
			if currentTip == tip {
				fmt.Println("Submitting block " + calculatedBlock.ToString())
				SendBlockToServer(calculatedBlock)
			}
			break
		case <-time.After(1000 * time.Millisecond):
			break
		}
		//fmt.Println("Fetching Tip")
		tip, err := GetTipFromServer()
		if err != nil {
			fmt.Print("Error getting tip from server ")
		}
		if currentTip != tip {
			fmt.Println("New tip found ")
			for i := 0; i < cpus; i++ {
				select {
				case x := <-calculatedBlockChannel: // Clears double blocks
					fmt.Printf("Value %d was read.\n", x)

				default:
					break
				}
			}

			currentTip = tip
			for i := 0; i < cpus; i++ {
				// fmt.Println("Sending tip to ", i)
				currentTipChannels[i] <- currentTip
			}
		} else {
			//fmt.Println("Did not find new tip")
		}
	}

	// Basic idea:
	// Get tip from server, mine a block pointing to that tip,
	// then submit to server.
	// To reduce stales, poll the server every so often and update the
	// tip you're mining off of if it has changed.

	return
}
