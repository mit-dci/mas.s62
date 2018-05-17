# pset2.0 (forkable, difficulty adjusting, simulation ready)
Made by Avery Lamp and Faraz Nadeem

In this folder there is a backend server that functions similarly to the backend used for pset 2, 
with many added features detailed below.  

We have also added a visualizer for the blockchain created by mining on the server. 

Finally we have included a couple different implementations of different miners to use on the server
or explore.

### Quick Redirects

[Python Server](server-python/)

[Visualization Code (Python)](blockchain-visualizer/)

[Multicore Miner (Golang)](multicore-miner-go/)

[Singlecore Miner (Python)](singlecore-miner-python/)

[Multicore Miner (Python)](multicore-miner-python/)

[Cuda Miner (c, cu)](gpu-cuda-miner-cu/)


## Server

Built with python, this flask server supports a centralized blockchain with a couple of basic features.

A full readme for the server [can be found here](server-python/)

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

#### Block Difficulty

To modify how the server adjust block difficulty, modify the function `calculate_target_work_for_block` (line 165) 
that gets called after every new block.  There are two sample implementations `monero_difficulty` and `bitcoin_difficulty` that can be used to test out monero-like and bitcoin-like difficulty adjustments with different parameters.  

(note) - difficulty is in number of leading zeros plus the geometric sum of the next 10 inverted bits multiplied by their term in the geometric series `1 / 2^n`.  

The complete implementation of difficulty checking can be found in the `hash_block_information` function (line 286).

#### Forkable

To fork a chain, simply add blocks pointing to any hash that already exists in the chain.

## Multicore Golang Miner

The full readme for the miner [can be found here](multicore-miner-go/)

The multi-core Golang miner that we made to test out the server utilizes many different configurations with command-line arguments to run.  

#### Installation

`go build main.go miner.go client.go`

The buildscript will create an executable file `main`, that can be run with the command line arguments

#### Usage 

(note) - default miner name is specified in code and needs to be updated

Mine from the main tip single core (query for new tips continuously) 
`./main`

Mine from the main tip multi-core (<num of cores>)
`./main <num of cores>`
 
Mine from specified block
`./main <Block Hash> <Target Difficulty> <Miner Name> <num of cores>
> @params `Block Hash` - The hash of the block to start mining from
> @params `Target Difficulty` - The target difficulty of the block (must match with the server's target difficulty)
> @params `Miner Name` - Specify a different miner name
> @params `num of cores` - The number of cores to mine with


