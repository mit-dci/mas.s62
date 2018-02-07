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


## Submission
