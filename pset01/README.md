# Problem Set 1

In the first part of this problem set, you'll implement Lamport signatures.  In the second part, you'll take advantage of incorrect usage to forge signatures.

## Getting started

You'll implement all labs in Go. The [Go website](https://golang.org/) contains a lot of useful information including a tutorial for learning Go if you're not already familiar with it.

You will probably find it most convenient to install Go 1.9 on your own computer, but you can also use it on Athena.

You can use a regular editor like vim / emacs / notepad.exe.  There is also a go-specific open source IDE that Tadge recommends & uses, [LiteIDE](https://github.com/visualfc/liteide) which may make things easier.

In order to submit your lab, you'll need to use git.  You can read about [git here](https://www.kernel.org/pub/software/scm/git/docs/user-manual.html).

## Collaboration Policy

You must write all of the code you hand in, except for what we give you with the assignment.  You may discuss the assignments with other students, but you should not look at or copy each other's code.

## Part 1

In this problem set, you will build a hash-based signature system.  It will be helpful to read about [Lamport signatures](https://en.wikipedia.org/wiki/Lamport_signature).

Implement the `GenerateKey()`, `Sign()` and `Verify()` functions in `main.go`.  When you have done so correctly, the program should print `Verify worked? true`.  You can test this by doing the following:

```
go build
./pset01
```

Hint: You will need to look at the bits in each byte in a hash.  You can use [bit operators](https://medium.com/learning-the-go-programming-language/bit-hacking-with-go-e0acee258827) in order to do so.

Make sure your code passes the tests by running:

```
go test
```

## Part 2

There is a public key and 4 signatures provided in the signatures.go file.  Given this data, you should be able to forge another signature of your choosing.  Make the message which you sign have the word "forge" in it, and also your name or email address.  There is a forge_test.go file which will check for the term 'forge' in the signed message.

Note that this may take a decent amount of CPU time even on a good computer.  We're not talking days or anything though; 4 signatures is enough to make it so that an efficient implementation is relatively quick.

To make sure you're in the right ballpark: On an AMD Ryzen 7 1700 CPU, using 8 cores, my (adiabat / Tadge) implementation could create a forgery in about 3 minutes of real time.  An equally efficient signle core implementation would take about 25 minutes.  On slower CPUs or with less efficient code it may take longer.

If you use CUDA or AVX-512 or AES-NI or something crazy like that and get it to run in 5 seconds, cool!  It should still run in go and pass the tests here, but note that you can do all the "work" in a different program and import the solution to this code if you want.

That's certainly not necessary though as it shouldn't take that long on most computers.  A raspberry pi might be too slow though.  If you get the forge_test.go test to pass, you're probably all set!  just run

```
go test
```
and see what fun errors you get! :)

## Testing and Timeouts

To run tests,
```
$ go test
```
will work, but by default it will give up after 10 minutes.  If your functions need more time to complete, you can change the timeout by typing
```
$ go test -timeout 30m
```
to timeout after 30 minutes instead of 10.

## Submission
