import hashlib
import time
import multiprocessing
import sys
import requests
current_tip_hash = None
current_tip_work = None
kill = False
def send_block(block):
    blockHash = block["blockHash"]
    name = block["name"]
    nonce = block["nonce"]
    r = requests.get("http://localhost:5000/addblock/{}/{}/{}".format(blockHash, name, "{}".format(nonce)))
    print(r.json())
    global current_tip_hash
    global current_tip_work
    current_tip_hash = r.json()["blockHash"]
    current_tip_work = r.json()["targetWork"]
    print("{}, {}".format(current_tip_hash, current_tip_work))
    return r.json()

def mine_block(thread_num, total_threads,targetWork, block, name):
    global q
    result = q
    i = thread_num
    while True:
        hashStr = "{} {} {}".format(block, name, "{}".format(i))
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
        if i % 10000 == 0:
            print("i = {}".format(i))
        if work >= targetWork:
            block = send_block({"blockHash":block, "name": name, "nonce": i})
            # q.put((block["blockHash"], block["targetWork"]))
            global kill
            kill = True
            break
        i += total_threads

        if kill:
            print("Killing thread {}".format(thread_num))
            break
    return

def get_tip():
    global current_tip_hash
    global current_tip_work

    if current_tip_hash is None and current_tip_work is None:
        r = requests.get("http://localhost:5000/getlatest")
        result = r.json()
        blockHash = result["blockHash"]
        current_tip_hash = blockHash
        targetWork = result["targetWork"]
        current_tip_work = targetWork
        return (blockHash, targetWork)
    else:
        print("Using cached")
        return (current_tip_hash, current_tip_work)

q =  multiprocessing.Queue()
def main():
    global current_tip_hash
    global current_tip_work
    global kill
    global q
    n = 0
    try:
        n = int(sys.argv[1])
    except:
        raise ValueError("No number of cores to use selected (enter afer multiThreadedMiner.py #")
    name = ""
    try:
        name = sys.argv[2]
    except:
        raise ValueError("Enter miner name as the second argument")
    if len(sys.argv) > 4:
        try:
            current_tip = sys.argv[3]
            current_target_difficult = int(sys.argv[4])
            current_tip_hash = current_tip
            current_tip_work = current_target_difficult
        except:
            raise ValueError("Either hash or target difficult is bad")
    
    current_tip = None
    print(sys.argv)
    cpu_num = multiprocessing.cpu_count()
    if n > cpu_num:
        raise ValueError("You are using more cores than exist {}/{}".format(n, cpu_num))
    cpu_num = n

    active_threads = []
    new_tip, targetWork = get_tip()
    q.put((new_tip, targetWork))

    while True:
        new_tip, targetWork = q.get()
        print("HEREEE")
        print("Checking for tip, {}, {}".format(new_tip, targetWork))
        current_tip = new_tip
        print("New Tip")
        print(current_tip)
        for thread in active_threads:
            thread.stop()
        active_threads = []
        for i in range(cpu_num):
            new_thread = multiprocessing.Process(target=mine_block, args=(i, cpu_num, targetWork, current_tip, name))
            active_threads.append(new_thread)
            new_thread.start()
        print("Running Threads")




if __name__ == "__main__":
    main()