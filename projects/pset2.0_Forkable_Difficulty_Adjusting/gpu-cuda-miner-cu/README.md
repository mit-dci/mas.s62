## Cuda Miner 

This is an implementation of a simple Cuda Miner originally made for the released pset 2.  
The code started with the Nvidia simplePrintf sample code, which can be found in any cuda samples package.  
The filenames still have not been changed to reflect the changes in the code.
The implementation also has not updated how it interacts with the server, so it will need to be updated before being used for the new python server implementation


Original Spec
Sample: simplePrintf
Minimum spec: SM 2.0

This CUDA Runtime API sample is a very basic sample that implements how to use the printf function in the device code. Specifically, for devices with compute capability less than 2.0, the function cuPrintf is called; otherwise, printf can be used directly.

Key concepts:
Debugging

