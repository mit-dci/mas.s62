## Server

Built with python, this flask server supports a centralized blockchain with a couple of basic features.

### Usage

To start the server, simply run

`python3 server.py`

### Serialization notes

The server implements simple serialization of the blockchain to disk in order to allow it to continue on a blockchain where it left off.  The two files created with server searlization are `block_information.pickle` and `highest_block.pickle`.  These file can be deserialized and used in the visualizer as well as kept around for analysis.  The server currently is scheduled to write to disk every minute.  

*To restart the server with just the genesis block* - simply delete the `block_information.pickle` and `highest_block.pickle` files that are created

### Block Difficulty

To modify how the server adjust block difficulty, modify the function `calculate_target_work_for_block` (line 165) 
that gets called after every new block.  There are two sample implementations `monero_difficulty` and `bitcoin_difficulty` that can be used to test out monero-like and bitcoin-like difficulty adjustments with different parameters.  

(note) - difficulty is in number of leading zeros plus the geometric sum of the next 10 inverted bits multiplied by their term in the geometric series `1 / 2^n`.  

The complete implementation of difficulty checking can be found in the `hash_block_information` function (line 286).

#### Forkable

To fork a chain, simply add blocks pointing to any hash that already exists in the chain.


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

