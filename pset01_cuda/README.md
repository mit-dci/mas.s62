## The code here is the cpp and cuda cpp version of pset01

A makefile is used to help with build and run the code. The forge siganture process takes minutes of run in golang and cpp, but takes a few seconds on cuda cpp. 

```
# run cpp version 
make run_forge
```

```
# compile cuda cpp version. Make sure you have cuda driver and cpp compilter installed. 
make forge_cuda
# run the cuda version 
./forge_cuda.out

```