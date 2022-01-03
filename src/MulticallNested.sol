pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @title MulticallNested - Fork of Multicall2 to aggregate results from multiple read-only function calls with nested callData.

contract MulticallExtra {
    struct Call {
        address target;
        bytes callData;
    }
    struct Result {
        bool success;
        bytes returnData;
    }

    struct NestedCall {
        address target;
        bytes sig;
        NestedCallParameter[] memory parameters;
    }
    struct NestedCallParameter {
        bool isStatic;
        bytes staticParam; 
        address target;
        bytes callData;
        uint256 dataLength;
        uint256 offset;
    }

    function aggregateNested(NestedCall[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            bytes memory resolvedCallData;
            for (uint256 ii = 0; ii < calls[i].parameters.length; ii++) {
              if (calls[i].parameters[ii].isStatic == true) {
                if (ii > 0) {
                  resolvedCallData = abi.encode(resolvedCallData, calls[i].parameters[ii].staticParam);
                } else {
                  resolvedCallData = abi.encode(calls[i].parameters[ii].staticParam);
                }
              } else {
                (bool successA, bytes memory retA) = calls[i].parameters[ii].target.call(calls[i].parameters[ii].callData);
                require(successA, "Multicall aggregate nested: call failed A");
                bytes memory resultValue = new bytes(calls[i].parameters[ii].dataLength);
                for (uint256 iii = 0; iii < calls[i].parameters[ii].offset; iii++) {
                    resultValue[iii] = retA[calls[i].parameters[ii].offset + iii];
                } 
                if (ii > 0) {
                  resolvedCallData = abi.encode(resolvedCallData, resultValue);
                } else {
                  resolvedCallData = abi.encode(resultValue);
                }
              }
            }
            (bool successB, bytes memory retB) = calls[i].target.call(resolvedCallData);
            require(successB, "Multicall aggregate nested: call failed B");
            returnData[i] = retB;
        }
    }

    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success, "Multicall aggregate: call failed");
            returnData[i] = ret;
        }
    }
    function blockAndAggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData) {
        (blockNumber, blockHash, returnData) = tryBlockAndAggregate(true, calls);
    }
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }
    function getBlockNumber() public view returns (uint256 blockNumber) {
        blockNumber = block.number;
    }
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }
    function tryAggregate(bool requireSuccess, Call[] memory calls) public returns (Result[] memory returnData) {
        returnData = new Result[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);

            if (requireSuccess) {
                require(success, "Multicall2 aggregate: call failed");
            }

            returnData[i] = Result(success, ret);
        }
    }
    function tryBlockAndAggregate(bool requireSuccess, Call[] memory calls) public returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData) {
        blockNumber = block.number;
        blockHash = blockhash(block.number);
        returnData = tryAggregate(requireSuccess, calls);
    }
}
