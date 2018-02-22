
# pset02 : NameChain

Mine your name into the blockchain.  This pset will use a mock blockchain which you can mine blocks into.  

Due on the last second of the month of February: 2018-02-28 23:59:59 EST

# Warning: centralized server

There is a server component to this pset, which might go down or crash.  This is not a decentralized network hardened by 9 years of open source improvements and worth hundreds of billions of dollars.  It's a server I coded just for this pset.  If it goes down, bug me on IRC and I'll try to fix it quickly so that you can increase your mining score.

The server, at hubris.media.mit.edu, should be up and running from the 20th to the 28th. 

Server is back up on 2018-02-22 10:45 EST

## Block specifications

Blocks are ASCII strings, with a maximum lenght of 100 characters. The block format is:

prevhash name nonce

prevhash: the ascii hexidecimal representation of the previous block hash.  Must be lowercase and in hex; do not use raw bytes.
example:

00000000c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b

name: the name you want to credit nameChain points to. Case sensitive.
example:

miner2049

nonce: a random nonce to satisfy the work requirement.
example:

TWFuI3GlzIGR

Note that names and nonces must be in the base64 character set:

ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/

which is just caps, lowercase, numbers and + and /.  Can't have spaces; spaces separate the 3 different elements of the block.
This is to make everthing easy to run through terminals, let people use shell scripts and so on.

## Client / Server connections

This pset has a server.  It's not a real decentralized system, as that's too much work to deal with for this early assignment.  There is a NameChain server which listens on a TCP port, and when a TCP connection is made to it, it sends the current blockchain tip.  Connected clients can send a new block to it, which, if valid, will be appended to the end of the blockchain.

The server is hard-coded into the pset code and lives at hubris.media.mit.edu.  It will probably go down for some time during this pset epoch, due to the fact that the DCI is moving to a new office this week.  We'll try to minimize downtime.  

The required work is 2^33, which is twice as difficult as the initial target for the Bitcoin network. (But nowhere near as difficult as the current Bitcoin target)

## What to do:

A bunch is already written for you.  The network functions are GetTipFromServer() and SendBlockToServer() and already implemented, so you don't have to deal with TCP.  

You need to write the Mine() function, and then SendBlockToServer() once you have mined a block.

You may need to poll the server for new blocks occasionally so that you don't submit "stale" blocks, where someone else submitted a block before you did with the same parent.  To not DDoS our server, please keep requests to 1 per second maximum.

Using go concurrency features is reccomended for this problem set.  The amount of work required to find a block is fairly high, and if you're mining using only 1 CPU core you will be at a disadvantage compared to multi-threaded, multi-core miners.

Here is a [simple tutorial](https://gobyexample.com/channels) on go channels; they're not too hard to use, even if you haven't done multi-threaded programming before.  They allow you to pass messages between functions which are running at the same time.  There are also other possible methods like sync.WaitGroup, or in fact it's quite possible to mine without any synchronization between threads at all.

There will be a "high score" ranking with the number of blocks in the chain made by each user.  This is the same as getting more coins by mining more blocks.  To get a high score, mine a bunch of blocks with the same name.  We're using names instead of public keys which is not as decentralized but we know who you are already :)

The entire current blockchain can be downloaded from the server at port 6299.  Example code:

```
$ nc hubris.media.mit.edu 6299

00000000722a3b3cabaac078bd4e15ce361312895cfef0494c9ffc75bedb82db adiabat 19579781213
```

This if if you want to check how the blockchain is progressing.

If there are other server features wanted, let me know and I can code them up.  The server code is not public now, but I'll make it public after the assignment is over.

Having a server makes this pset somewhat more fragile so bear with us :)  We hope this assignment is fun and people can optimize and speed up their code, while getting the basics of blockchain design.
