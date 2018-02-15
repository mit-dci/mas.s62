package main

import (
	"bufio"
	"fmt"
	"net"
)

var (
	// note that this server is not up yet!  Will be soon!
	serverHostname = "hubris.media.mit.edu:6262"

	// uncomment for testing & running a server on localhost
	//	serverHostname = "127.0.0.1:6262"
)

// The functions in this file are provided to give connectivity to the
// NameChain server.  They aren't really the best way to transmit & receive
// data over the internet, but it works OK, and we're not focused on the
// network layer right now.  You shouldn't have to modify this code but
// do let me know if it's not working properly.

// GetTipFromServer connects to the server and gets the tip of the blockchain.
// Can return an error if the connection doesn't work or the server is sending
// invalid data that doesn't look like a block.
func GetTipFromServer() (Block, error) {
	var bl Block

	connection, err := net.Dial("tcp", serverHostname)
	if err != nil {
		return bl, err
	}
	fmt.Printf("connected to server %s\n", connection.RemoteAddr().String())

	// send tip request to server
	sendbytes := []byte("TRQ\n")

	// write to server, error out if needed
	_, err = connection.Write(sendbytes)
	if err != nil {
		return bl, err
	}

	// setup to read response
	bufReader := bufio.NewReader(connection)

	// read from TCP
	blockLine, err := bufReader.ReadBytes('\n')
	if err != nil {
		return bl, err
	}

	fmt.Printf("read from server:\n%s\n", string(blockLine))

	// convert to block
	bl, err = BlockFromString(string(blockLine))
	if err != nil {
		return bl, err
	}

	// return block

	return bl, nil
}

// SendBlockToServer connects to the server and sends a block.  The server won't
// respond at all! :(  But you can check for the tip by connecting again to see
// if the server updated it's blockchain
func SendBlockToServer(bl Block) error {
	connection, err := net.Dial("tcp", serverHostname)
	if err != nil {
		return err
	}
	fmt.Printf("connected to server %s\n", connection.RemoteAddr().String())

	// Server will send us data but we can ignore it and just send

	// use newline to indicate end of transmission.  A bit ugly but OK.
	sendbytes := []byte(fmt.Sprintf("%s\n", bl.ToString()))

	_, err = connection.Write(sendbytes)
	if err != nil {
		return err
	}

	// read response from server and print out.
	bufReader := bufio.NewReader(connection)
	ResponseLine, err := bufReader.ReadBytes('\n')
	if err != nil {
		return err
	}

	fmt.Printf("Server resposnse: %s\n", string(ResponseLine))

	return connection.Close()
}
