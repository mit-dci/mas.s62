
# Taproot 

Tool to create taproot privkeys/pubkeys that commit to an additional script.

## Building

Simply `cd` into the directory and run `make`.

## Usage
```
./taproot <secret key> <script>
```

The secret key should be a 64-char hex string (32 bytes).
The script can be any valid hex-encoded bitcoin script.

Example:
```
./taproot E9873D79C6D87DC0FB6A5778633389F4453213303DA61F20BD67FC233AA33262 6a4c0a0102030405060708090a
```

## Notes

This tool requires `libsecp256k1` to be built and linked.
SHA256 code (hash.h and hash_impl.h) used from `libsecp256k1`
`hex2bin` and `bin2hex` code attributed to Andrew Poelstra

Given a secret key `j` and its corresponding public key `J`, the tool will compute `c = j + sha256(script, J)` and `C = J + sha256(script, J)G`
