package main

import (
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
)

type ServerBlock struct {
	PreviousHash string  `json:"blockHash"`
	TargetWork   float64 `json:"targetWork"`
	Height       int64   `json:"height"`
}

var cachedServerBlock *ServerBlock
var cachedName = "avery"
var lastSubmittedHeight *int
var cachingEnable = true

// GetTipFromServer connects to the server and gets the tip of the blockchain.
// Can return an error if the connection doesn't work or the server is sending
// invalid data that doesn't look like a block.
func GetTipFromServer() (Block, error) {
	var bl Block
	if cachedServerBlock != nil && cachingEnable {
		hashbytes, err := hex.DecodeString(cachedServerBlock.PreviousHash)
		if err != nil {
			return bl, err
		}
		if len(hashbytes) != 32 {
			return bl, fmt.Errorf("got %d byte hash, expect 32", len(hashbytes))
		}
		copy(bl.PrevHash[:], hashbytes)
		bl.Name = cachedName
		bl.TargetWork = cachedServerBlock.TargetWork
		return bl, nil
	}

	response, err := http.Get("http://localhost:5000/getlatest")
	if err != nil {
		fmt.Println("%s", err)
		return bl, err
	}

	defer response.Body.Close()
	contents, err := ioutil.ReadAll(response.Body)
	if err != nil {
		fmt.Printf("%s", err)
		os.Exit(1)
	}
	// fmt.Printf("%s\n", string(contents))

	if err := json.Unmarshal(contents, &cachedServerBlock); err != nil {
		panic(err)
	}

	hashbytes, err := hex.DecodeString(cachedServerBlock.PreviousHash)
	if err != nil {
		return bl, err
	}
	if len(hashbytes) != 32 {
		return bl, fmt.Errorf("got %d byte hash, expect 32", len(hashbytes))
	}
	copy(bl.PrevHash[:], hashbytes)
	bl.Name = cachedName
	bl.TargetWork = cachedServerBlock.TargetWork
	return bl, nil
}

// SendBlockToServer connects to the server and sends a block.  The server won't
// respond at all! :(  But you can check for the tip by connecting again to see
// if the server updated it's blockchain
func SendBlockToServer(bl Block) error {
	response, err := http.Get(fmt.Sprintf("http://localhost:5000/addblock/%x/%v/%s", bl.PrevHash, bl.Name, bl.Nonce))
	if err != nil {
		fmt.Printf("%s", err)
		os.Exit(1)
	}
	defer response.Body.Close()
	contents, err := ioutil.ReadAll(response.Body)
	if err != nil {
		fmt.Printf("%s", err)
		os.Exit(1)
	}
	fmt.Printf("%s\n", string(contents))
	if err := json.Unmarshal(contents, &cachedServerBlock); err != nil {
		fmt.Printf("%s", err)
	}

	return err
}
