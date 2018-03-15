package main

import (
	"bytes"
	"fmt"

	"github.com/btcsuite/btcd/btcec"
	"github.com/btcsuite/btcd/chaincfg/chainhash"
	"github.com/btcsuite/btcd/txscript"
	"github.com/btcsuite/btcd/wire"
	"github.com/btcsuite/btcutil"
)

// TxToHex takes a transaction and outputs the serialized tx in hex.
// Provided to make things easier.  Returns an empty string if there's an error.
func TxToHex(tx *wire.MsgTx) string {
	if tx == nil {
		return ""
	}
	buf := new(bytes.Buffer)
	tx.Serialize(buf)
	return fmt.Sprintf("%x", buf.Bytes())
}

func EZTxBuilder() *wire.MsgTx {

	// create a new, empty transaction, set version to 2
	tx := wire.NewMsgTx(2)

	// we need to add at least one input and one output.  Lets build the input first
	// inputs consist of a previous output point, and a witness (signature data)
	// output points (out points) are a transaction hash (txid) and an index number
	// indicating which output for that transaction is being consumed.
	// since txids are unique, this will not be replayable.  pick a tx output
	// that has not yet been consumed by someone else.

	hashStr := "" // put the input txid here

	// it'll work
	// also note that in bitcoin, all the 32-byte strings are displayed backwards.
	// who knows why.
	outpointTxid, err := chainhash.NewHashFromStr(hashStr)
	if err != nil {
		panic(err)
	}
	// let's try to spend output index 7
	outPoint := wire.NewOutPoint(
		outpointTxid, 0) // replace 0 with the output you want to spend

	// create the TxIn, with empty sigscript field
	input := wire.NewTxIn(outPoint, nil, nil)

	// Next, we create the output.  Outputs are [amount, address] pairs, where
	// amounts are 64-bit signed integers, and addresses are scripts that run on the
	// bitcoin stack interpreter

	// Put your wallet address as a string here, and it will be decoded into a 20-byte
	// hash.  That hash is used in the standard "pay to pubkey hash" (p2pkh) script

	sendToAddressString := "" // put the address you're sending to here
	sendToAddress, err := btcutil.DecodeAddress(sendToAddressString, testnet3Parameters)
	if err != nil {
		panic(err)
	}

	// this builds an output script.

	sendToScript, err := txscript.PayToAddrScript(sendToAddress)

	// amounts in bitcoin are integers, but "one bitcoin" is actually 100 million of the
	// base unit, often called "satoshis".  If the output amount is greater than the
	// input amount, the transaction is invalid (because it's creating more coins)
	// ( this check is performed over the sum of the inputs and outputs.  There is an
	// exception for the coinbase transaction.)
	output := wire.NewTxOut(0, sendToScript) // replace 0 with the output value

	// put the inputs and outputs into the transaction

	tx.AddTxIn(input)
	tx.AddTxOut(output)

	// the transaction now has the inputs and outputs, but is missing the signature.
	// We need a private key to sign with
	// Hash any phrase to make a private key
	phraseHash := chainhash.DoubleHashB([]byte("secret phrase here"))

	// make a new private key struct.  Private key structs also have a pubkey in them
	priv, _ := btcec.PrivKeyFromBytes(btcec.S256(), phraseHash)

	fmt.Printf("my pubkey: %x\n", priv.PubKey().SerializeCompressed())
	// we also need the script from the previous transaction.  This is redundant as it
	// is covered by the txid

	prevAddressString := "" // put the address you're sending "from" here
	prevAddress, err := btcutil.DecodeAddress(prevAddressString, testnet3Parameters)
	if err != nil {
		panic(err)
	}

	spendFromScript, err := txscript.PayToAddrScript(prevAddress)

	// SignatureScript takes a bunch of arguments.  In this case:
	// tx: transaction itself
	// hcahce: the hash cache
	// 0: which input to sign
	// spendFromScript: the previous output script (redundant, covered by input txid)
	// txscript.SigHashAll: the signature hash type.  usually "all", meaning the
	// signature covers all inputs and outputs in the transaction.
	// true: the previous script has a compressed public key hash.

	pubSig, err := txscript.SignatureScript(
		tx, 0, spendFromScript, txscript.SigHashAll, priv, true)
	if err != nil {
		panic(err)
	}
	// once the signature has been created, we put the signature onto the
	// "witness stack" of the input.

	tx.TxIn[0].SignatureScript = pubSig

	return tx
}
