from flask import Flask, jsonify, request
import threading
import operator
import hashlib
import pickle
import time
from flask_cors import CORS
import math

app = Flask(__name__)
CORS(app)
block_information = dict()
highest_block = []
def write_information_to_memory():
    global block_information
    print("Writing to memory")
    pickle_out = open("block_information.pickle","wb")
    pickle.dump(block_information, pickle_out)
    pickle_out.close()

    pickle_out = open("highest_block.pickle","wb")
    pickle.dump(highest_block, pickle_out)
    pickle_out.close()
    print("Finished writing to memory")
    # Periodically writes all block information to memory
    threading.Timer(60.0, write_information_to_memory).start()
 
@app.route('/addblock/<previousHash>/<name>/<nonce>', methods =["GET"])
def add_block(previousHash, name, nonce, seed = False):
    global block_information
    block_data = {
            "previousHash":previousHash,
            "name":name,
            "nonce":nonce
    }
    hashed_block_information = hash_block_information(block_data, seed)

    blockHash = hashed_block_information["blockHash"]
    work = hashed_block_information["work"]
    height = -1
    workTarget = 0
    current_time = time.time()
    blockTime = 0
    if not seed:
        
        try:
            previousBlock = block_information[previousHash]
            height = previousBlock["height"] + 1
            workTarget = previousBlock["targetWork"]
            blockTime = current_time - previousBlock["timestamp"]
        except:
            raise ValueError("Previous block hash does not exist")
    else:
        height = 0

    
    block =  {
        "height": height,
        "timestamp": current_time,
        "blockTime": blockTime, 
        "blockHash": blockHash,
        "work" : work,
        "blockInformation":block_data
    }

    block["targetWork"] = calculate_target_work_for_block(block)

    if work >= workTarget:
        print("Adding block to blockchain")
        add_checked_block(block)
        if seed:
            return block
        return jsonify(block)
    else:
        raise ValueError("Not enough work to satisfy target: {} / {}".format(work, workTarget))

def add_checked_block(block):
    global block_information
    global highest_block
    if block["blockHash"] in block_information:
        raise ValueError("Block already exists")
    block_information[block["blockHash"]] = block
    higher = True
    equal_height = False # Enable tied heights
    for b in highest_block:
        if block["height"] < b["height"]:
            higher = False
            equal_height = False
        elif block["height"] == b["height"]:
            higher = False
    if higher:
        highest_block = [block]
        print("New Highest Block")
    elif equal_height:
        highest_block.append(block)
        print("Equal Height Block")

def monero_difficulty(block):
    global block_information
    target = 25.0
    targetInterval = 60.0 #interval in seconds
    number_of_previous_block_to_look_at = 20
    extremes_to_strip = 3
    previousBlockTimes = []
    previousBlockHash = block["blockInformation"]["previousHash"]
    if previousBlockHash in block_information:
        previousBlock = block_information[previousBlockHash]
        target = previousBlock["targetWork"]
    
    while len(previousBlockTimes) < number_of_previous_block_to_look_at:
        if previousBlockHash in block_information:
            previousBlock = block_information[previousBlockHash]
            previousBlockTimes.append((previousBlock["blockTime"], previousBlock["targetWork"]))
            previousBlockHash = previousBlock["blockInformation"]["previousHash"]
        else:
            break

    if len(previousBlockTimes) > extremes_to_strip * 2 + 1:
        
        block_times = sorted(previousBlockTimes)[extremes_to_strip:][:-extremes_to_strip]
        print(block_times)
        total_time = sum(blockTime[0] for blockTime in block_times)
        average_difficulty = sum(blockTime[1] for blockTime in block_times) / len(block_times)

        expected_difference = targetInterval * len(previousBlockTimes)
        difficulty_change = math.log(total_time / expected_difference, 2.0)

        target = average_difficulty - difficulty_change
        print("Time {} vs {}, average_difficulty {}, change {}, new_target {}".format(total_time, expected_difference, average_difficulty, difficulty_change, target))

    return target

def bitcoin_difficulty(block):
    global block_information
    target = 25.0
    targetInterval = 60.0 #interval in seconds
    number_of_previous_block_to_look_at = 10
    number_of_blocks_to_recalculate_on = 10
    previousBlockTimes = []
    previousBlockHash = block["blockInformation"]["previousHash"]
    if previousBlockHash in block_information:
        previousBlock = block_information[previousBlockHash]
        target = previousBlock["targetWork"]
    if block["height"] % number_of_blocks_to_recalculate_on == 0:
        while len(previousBlockTimes) < number_of_previous_block_to_look_at:
            if previousBlockHash in block_information:
                previousBlock = block_information[previousBlockHash]
                previousBlockTimes.append((previousBlock["timestamp"], previousBlock["targetWork"]))
                previousBlockHash = previousBlock["blockInformation"]["previousHash"]
            else:
                break

        if len(previousBlockTimes) > 0:
            previousTarget = previousBlockTimes[0][1]
            
            time_difference = block["timestamp"] - previousBlockTimes[-1][0] #difference in seconds

            expected_difference = targetInterval * len(previousBlockTimes)

            difficulty_change = math.log(time_difference / expected_difference, 2.0)
            target = previousTarget - difficulty_change

    return target

def calculate_target_work_for_block(block):
	"""
	To change how difficulty changes on a block by block basis implement this method

	Sample implementations with added parameters include 
	 - bitcoin_difficulty
	 - monero_difficulty

	The returned target is the number of zero bits needed.
	If the returned target is a decimal, 
	every bit after the first number adds a float of
	1 / 2^(number of bits after first one) if the bit is a zero
	This allows for a simple implementation of difficulties that are not limited by
	the number of zeros needed, as a decimal makes the expected
	number of hashes to be exactly 2^difficulty

	In order to speed up mining, the first 10 bits after the first 1 bit is accounted for.  
	(no need to check every bit)
	"""
    # return monero_difficulty(block)
    # return bitcoin_difficulty(block)
    target = 32
    return target


@app.route('/getlatest/', methods =["GET"])
def get_latest():
    global highest_block
    if len(highest_block) > 0:
        return jsonify(highest_block[0])
    else:
        return "No highest block yet"

@app.route('/getblock/<blockHash>', methods =["GET"])
def get_block(blockHash):
    global block_information
    if blockHash in block_information:
        return jsonify(block_information[blockHash])
    else:
        return "No block with hash {} found".format(blockHash)

@app.route('/getscores/', methods = ["GET"])
def get_scores():
    global block_information
    global highest_block
    blockHash = highest_block[0]["blockHash"]
    scores = dict()
    while True:
        if blockHash in block_information:
            block = block_information[blockHash]
            name = block["blockInformation"]["name"]
            if name != "":
                if name in scores:
                    scores[name] += 1
                else:
                    scores[name] = 1
            blockHash = block["blockInformation"]["previousHash"]
        else:
            break
    sorted_scores = sorted(scores.items(), key=operator.itemgetter(1), reverse=True)
    response = []
    for scoreset in sorted_scores:
        response.append("Score: {},  Name: {}".format(scoreset[1], scoreset[0]))
    return jsonify(response)

@app.route('/getallblocks/', methods = ["GET"])
def get_all_blocks():
    global block_information
    all_blocks = block_information.values()
    
    # print(all_blocks)
    all_blocks = sorted(all_blocks,key= lambda x: x["timestamp"], reverse = True )
    return jsonify(all_blocks)

@app.route('/getalltips/', methods = ["GET"])
def get_all_tips():
    global block_information
    all_blocks = []
    connected_blocks = set()
    for key in block_information:
        block = block_information[key]
        connected_blocks.add(block["blockInformation"]["previousHash"])
    tip_hashes = set(block_information.keys()).difference(connected_blocks)
    print("tip hashes")
    print(tip_hashes)
    for tipHash in tip_hashes:
        all_blocks.append(block_information[tipHash])
    # print(all_blocks)
    all_blocks = sorted(all_blocks,key= lambda x: x["height"], reverse = True )
    return jsonify(all_blocks)

@app.route('/getchain/', methods = ["GET"])
def get_full_chain():
    global block_information
    global highest_block
    blockHash = highest_block[0]["blockHash"]
    blocks = []
    while True:
        if blockHash in block_information:
            block = block_information[blockHash]
            blocks.append("Height - {}, Target Difficulty - {}, Hash - {}, name - {}, nonce - {}".format(block["height"], block["targetWork"], block["blockHash"], block["blockInformation"]["name"], block["blockInformation"]["nonce"]))
            blockHash = block["blockInformation"]["previousHash"]
        else:
            break

    return jsonify(blocks)
@app.route('/getchain/<blockHash>', methods =["GET"])
def get_last_n_blocks(blockHash, n = 100):
    global block_information
    blocks = []
    while len(blocks) < n:
        if blockHash in block_information:
            block = block_information[blockHash]
            blocks.append("Height - {}, Hash - {}, name - {}, nonce - {}".format(block["height"], block["blockHash"], block["blockInformation"]["name"], block["blockInformation"]["nonce"]))
            blockHash = block["blockInformation"]["previousHash"]
        else:
            break

    return jsonify(blocks)
squares = [2**x for x in range(255, -1, -1)]

def hash_block_information(block_data, seed = False):
    global squares
    prevHash = block_data.get("previousHash", None)
    name = block_data.get("name", None)
    nonce = block_data.get("nonce", None)
    if prevHash is None:
        raise ValueError("No preceding hash was found")
    else:
        if len(prevHash) != 64 and not seed:
            raise ValueError("Preceding hash length is incorrect")
    if name is None:
        raise ValueError("Miner name missing")
    if nonce is None:
        raise ValueError("Nonce missing")
    block_string = prevHash + " " + name + " " + nonce
    if len(block_string) > 100:
        raise ValueError("Block string is over 100 characters")
    block_hash = hashlib.sha256(block_string.encode("utf-8")).hexdigest()
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

    return {
        "blockHash": block_hash, 
        "work": work
    }


if __name__ == '__main__':
    try:
        pickle_in = open("block_information.pickle", "rb")
        block_information = pickle.load(pickle_in)
        print("Successful deserialization of cached blockchain")

        pickle_in = open("highest_block.pickle", "rb")
        highest_block = pickle.load(pickle_in)
        print("Successful deserialization of top blocks")

        # print(block_information)
        # print(highest_block)
    except:
        block_information = dict()

        print("Failed deserialization of cached results")
        try:
            blockHash = add_block("", "", "", True)["blockHash"]
        except ValueError as e:
            print(e)
            pass
        pass
    
    threading.Timer(60.0, write_information_to_memory).start()

    app.run(host="127.0.0.1", debug=True)
