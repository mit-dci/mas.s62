function getTokensTransaction(myaccount, startBlockNumber, endBlockNumber) {
  console.log("Searching for transactions to/from account \"" + myaccount + "\" within blocks "  + startBlockNumber + " and " + endBlockNumber);

  var tokenTransactions = [];
  for (var i = startBlockNumber; i <= endBlockNumber; i++) {
    if (i % 1000 == 0) {
      console.log("Searching block " + i);
    }
    var block = eth.getBlock(i, true);
    if (block != null && block.transactions != null) {
      block.transactions.forEach( function(e) {
        if (myaccount == "*" || myaccount == e.from || myaccount == e.to) {
          tokenTransactions.push(e)
          // console.log(JSON.stringify(e))
          // console.log("  tx hash          : " + e.hash + "\n"
          //   + "   nonce           : " + e.nonce + "\n"
          //   + "   blockHash       : " + e.blockHash + "\n"
          //   + "   blockNumber     : " + e.blockNumber + "\n"
          //   + "   transactionIndex: " + e.transactionIndex + "\n"
          //   + "   from            : " + e.from + "\n"
          //   + "   to              : " + e.to + "\n"
          //   + "   value           : " + e.value + "\n"
          //   + "   time            : " + block.timestamp + " " + new Date(block.timestamp * 1000).toGMTString() + "\n"
          //   + "   gasPrice        : " + e.gasPrice + "\n"
          //   + "   gas             : " + e.gas + "\n"
          //   + "   input           : " + e.input
          // );
        }
      })
    }
    // break
  }
  console.log(JSON.stringify(tokenTransactions))
}

// omisego contract: 0xd26114cd6ee289accf82350c8d8487fedb8a0c07
// 3980733 => 1499306421 => 7/6/2017 2:00:21 AM
// 4064576 => 1500854468 => 7/24/2017 12:01:08 AM

getTokensTransaction("0xd26114cd6ee289accf82350c8d8487fedb8a0c07", 3980733, 4064576)

// req contract: 0x8f8221afbb33998d8584a2b05749ba73c37a938a
// first block = 4345153 => 1507391257 => 10/7/2017 3:47:37 PM
// last block  = 4394210 => 1508482816 => 10/20/2017 7:00:16 AM

// getTokensTransaction("0x8f8221afbb33998d8584a2b05749ba73c37a938a", 4345153, 4394210)