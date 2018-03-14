package main

import (
	"fmt"

	"github.com/btcsuite/btcd/chaincfg"
)

var (
	// we're running on testnet3
	testnet3Parameters = &chaincfg.TestNet3Params
)

func main() {
	fmt.Printf("mas.s62 pset03 - utxohunt\n")

	// Task #1 make an address pair
	// Call AddressFrom PrivateKey() to make a keypair

	// Task #2 make a transaction
	// Call EZTxBuilder to make a transaction

	// task 3, call OpReturnTxBuilder() the same way EZTxBuilder() was used

	return
}
