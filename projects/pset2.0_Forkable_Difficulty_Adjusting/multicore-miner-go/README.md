
## Multicore Golang Miner

The multi-core Golang miner that we made to test out the server utilizes many different configurations with command-line arguments to run.

The multi-core Golang miner utilizes channels to efficiently use all processing power on a computer and schedule multi-threaded programming tasks

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

`./main <Block Hash> <Target Difficulty> <Miner Name> <num of cores>`

> @params `Block Hash` - The hash of the block to start mining from

> @params `Target Difficulty` - The target difficulty of the block (must match with the server's target difficulty)

> @params `Miner Name` - Specify a different miner name

> @params `num of cores` - The number of cores to mine with
