### Searialized attack data

Here is some serialized blockchains that we produced with different difficulties and different attack percentages.

The blockchains were created by mining with a number of cores (7 usually), waiting a number of blocks for difficulty to adjust, then killing the 7 cores.

After killing the 7 cores that produced the main chain, we split the number of cores to continue on the main chain, to be often 2 or 3, 
while the leftover 5 or 4 cores were instructed to mine a number of blocks behind the main tip.
