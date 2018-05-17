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
        work = 0.0
        block_hash_value = int(block_hash, 16)
        first_one = True
        first_one_count = 0
        print(block_hash)
        print(block_hash_value)
        for i in range(len(squares)):
            if block_hash_value - squares[i] < 0: # Case bit is a 0
                if first_one:
                    work += 1
                else:
                    work += 1 / squares[255 - first_one_count]
                    first_one_count += 1
            else: # Case bit is 1
                block_hash_value =  block_hash_value - squares[i]
                if first_one:
                    first_one = False
                    first_one_count += 1
                else:
                    first_one_count += 1
            if first_one_count >= 10:
                break
        if work >= targetWork:
            r = requests.get("http://localhost:5000/addblock/{}/{}/{}".format(blockHash, name, "{}".format(i)))
            print(r.json())
            break
        i += 1