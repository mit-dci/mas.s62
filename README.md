# MAS.S62 Spring 2018
# Cryptocurrency Engineering and Design

### NOTE:  This document is a draft and is subject to change.

## Information

Instructors:  Tadge Dryja ([tdryja@media.mit.edu](tdryja@media.mit.edu)) and Neha Narula ([narula@media.mit.edu](narula@media.mit.edu))

Time:  MW 10-11:30 AM 

Place:  E14-341

Contact: [cryptocurrency-sp18-staff@mit.edu](cryptocurrency-sp18-staff@mit.edu)

You are welcome to contact us via email.  However, if you think your
question would be useful for others to see, please file it as [an issue](https://github.com/mit-dci/mas.s62/issues)
in this repository!

Description:

Bitcoin and other cryptographic currencies have gained attention over
the years as the systems continue to evolve.  This course looks at the
design of Bitcoin and other cryptocurrencies and how they function in
practice, focusing on cryptography, game theory, and network
architecture.  Future developments in smart contracts and privacy will
be covered as well.  Programming assignments in the course will give
practical experience interacting with these currencies, so some
programming experience is required.

Office hours: 4-6 PM Tuesdays

Office hours location:  The big table outside E15-357

TA: James Lovejoy [jlovejoy@mit.edu](jlovejoy@mit.edu)

## Schedule

NOTE:  The schedule is in flux and subject to change.


| # | Date | Lecturer | Topic | Readings | Lecture Notes | Labs |
|---|------|----------|-------|----------|---------------|-|
| 1 | 2018-02-07 | Neha and Tadge | Introduction. Signatures, hashing, hash chains, e-cash, and motivation | [Untraceable Electronic Cash](http://www.wisdom.weizmann.ac.il/~/naor/PAPERS/untrace.pdf) | [tadge's slides](https://github.com/mit-dci/mas.s62/tree/master/slides/lec01-tadge.pdf), [neha's slides](https://github.com/mit-dci/mas.s62/tree/master/slides/lec01-neha.ppt) |  |
| 2 | 2018-02-12 | Neha and Tadge | Proof of Work and Mining | [Bitcoin](http://www.bitcoin.org/bitcoin.pdf) | [tadge's slides](https://github.com/mit-dci/mas.s62/tree/master/slides/lec02-tadge.pdf) | |
| 3 | 2018-02-14 | Tadge | Signatures | [Simple Schnorr Multi-Signatures with Applications to Bitcoin](https://eprint.iacr.org/2018/068.pdf) | [tadge's slides](https://github.com/mit-dci/mas.s62/tree/master/slides/lec03-tadge.pdf) | LAB 1 DUE |
| 4 | 2018-02-20 | Neha | Transactions and the UTXO model | [Bitcoin Transactions](https://en.bitcoin.it/wiki/Transaction) | [neha's slides](https://github.com/mit-dci/mas.s62/tree/master/slides/lec04-neha.pptx) | |
| 5 | 2018-02-21 | Tadge | Synchronization process, pruning | | [tadge's slides](https://github.com/mit-dci/mas.s62/blob/master/slides/lec05-tadge.pdf) |
| 6 | 2018-02-26 | Tadge | SPV, wallets, the network | | | |
| 7 | 2018-02-28 | TBD | Hard / Soft Forks | | | LAB 2 DUE |
| 8 | 2018-03-05 | Neha | TBD |  | | |
| 9 | 2018-03-07 | TBD | TBD |  | | |
| 10 | 2018-03-12 | Tadge | Fee estimation, RBF | | | |
| 11 | 2018-03-14 | Tadge | TBD | | | |
| 12 | 2018-03-19 | TBD | TBD | | | |
| 13 | 2018-03-21 | TBD | TBD | | | |
| 14 | 2018-04-02 | TBD | TBD | | | |
| 15 | 2018-04-04 | TBD | TBD | | | |
| 16 | 2018-04-09 | TBD | TBD | | | |
| 17 | 2018-04-11 | TBD | TBD | | | |
| 18 | 2018-04-18 | TBD | TBD | | | |
| 19 | 2018-04-23 | Joseph Bonneau | Ethereum and smart contracts | | | |
| 20 | 2018-04-25 | TBD | NOTE: Class is in E15-359 | | | |
| 21 | 2018-04-30 | TBD | TBD | | | |
| 22 | 2018-05-02 | TBD | TBD | | | |
| 23 | 2018-05-07 | TBD | TBD | | | |
| 24 | 2018-05-09 | TBD | NOTE: Class is in E15-359 | | | |
| 25 | 2018-05-14 | | Final Presentations Day 1 | | | |
| 26 | 2018-05-16 | | NOTE: Class is in E15-359 Final Presentations Day 2 | | | |

## Labs and Problem Sets

| # | Due Date | Assignment | 
|---|------|------------|
| 1 | 2018-02-14 | Hash-based signature schemes.  Code your own signatures and sign with them! In the [pset01](https://github.com/mit-dci/mas.s62/tree/master/pset01) |
| 2 | 2018-02-28 | Mine your name |
| 3 |  | UTXOhunt |

All labs are due by 11:59 PM on the day specified.

## Final Projects

You may form groups of 1-4 students and prepare a
presentation and a 4 page paper on one of the following:

1.  Design and implement an application or system ([project ideas](projects.md))
2.  Add a new feature to an existing system like Bitcoin, Ethereum, or another cryptocurrency or shared ledger implementation
3.  Propose a formalization in this space for a topic that has not been formalized yet  
4.  Pose and solve an interesting problem
