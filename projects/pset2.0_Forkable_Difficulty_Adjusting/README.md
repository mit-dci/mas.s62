# pset2.0 (forkable, difficulty adjusting, simulation ready)
Made by Avery Lamp and Faraz Nadeem

In this folder there is a backend server that functions similarly to the backend used for pset 2, 
with many added features detailed below.  

We have also added a visualizer for the blockchain created by mining on the server. 

Finally we have included a couple different implementations of different miners to use on the server
or explore.

### Quick Redirects

[Python Server]()

[Visualization Code (Python)]()

[Multicore Miner (Golang)]()

[Singlecore Miner (Python)]()

[Multicore Miner (Python)]()

[Cuda Miner (c, cu)]()


## Server

Built with python, this flask server supports a centralized blockchain with a couple of basic features.

A full readme for the server [can be found here](../server-python/README.md)

### Server Endpoints

**Add Block -** `/addblock/<Previous Hash>/<name>/<nonce>`
>  @param `Previous Hash` - The string hash to mine off of
>  @param `name` - The string miner name
>  @param `nonce` - The varied nonce 
>  Blocks are hashed as the string sha256("<Previous Hash> <name> <nonce>")
>  - Attempts to add a block pointing to Previous Hash.  
>  - Will return error messages for different kinds of invalid blocks

**Get Tip -** `/getlatest/`
>  - Returns the tip of the main chain

**Get Block -** `/getblock/<Block Hash>/`
>  @param `Block Hash` - The string hash of the block to return
>  - Returns the information included in the block specified

**Get All Blocks -** `/getallblocks/`
>  - Returns a list of all blocks in the system, sorted by timestamp (most recent)

**Get All Tips -** `/getalltips/`
>  - Returns a list of all blocks that do not have any other block pointing to it, sorted by height
>  - Allows a user to find all existing chains

**Get Main Chain -** `/getchain/`
>  - Returns the main chain in a simplified format

**Get Specific Chain -** `/getchain/<Block Hash>`
>  @param `Block Hash` - The string hash of the chain to return
>  - Returns the chain from the orign to the specified block with `Block Hash`


