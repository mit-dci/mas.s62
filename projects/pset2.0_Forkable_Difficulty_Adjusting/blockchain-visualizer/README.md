## Visualization

The blockchain visualizer allows you to create graphs and plots of different blockchains/chains and their growth in height over time.

The blockchain visuzlizer uses the pickle file that is serialized by the server every minute for data to be saved.  

The path to the pickle file *must be updated* to the directory of the server to graph the latest data.

To graph a secondary chain (attacker chain), the tip of the chain must be added to the variable forked_block before running the script
