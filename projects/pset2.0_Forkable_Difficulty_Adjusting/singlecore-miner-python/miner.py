import requests
import hashlib

while True:
    r = requests.get("http://localhost:5000/getlatest")
    result = r.json()
    blockHash = result["blockHash"]
    targetWork = result["targetWork"]
    print(blockHash)
    print(targetWork)

    name = "avery"
    i = 0
    while True:
        hashStr = "{} {} {}".format(blockHash, name, "{}".format(i))
        block_hash = hashlib.sha256(hashStr.encode("utf-8")).hexdigest()
        work = 0
        for c in block_hash:
            if c <= '0':
                work += 4
            elif c <= '1':
                work += 3
                break
            elif c <= '3':
                work += 2
                break
            elif c <= '7':
                work += 1
                break
            else:
                break
        if work >= targetWork:
            r = requests.get("http://localhost:5000/addblock/{}/{}/{}".format(blockHash, name, "{}".format(i)))
            print(r.json())
            break
        i += 1