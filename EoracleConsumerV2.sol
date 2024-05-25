// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEOFeedRegistry {
    struct PriceFeed {
        uint256 value;
        uint256 timestamp;
    }
    function getLatestPriceFeed(uint16 symbol) external view returns (PriceFeed memory);
    function getLatestPriceFeeds(uint16[] calldata symbols) external view returns (PriceFeed[] memory);
}

contract EoracleConsumerV2 {
    IEOFeedRegistry public _feedRegistry;
    address public owner;

    struct Price {
        uint16 symbol;  
        uint256 timestamp;
        uint256 value;  
    }

    mapping(uint16 => Price[]) public priceData; // Mapping from symbol to array of prices

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    /**
     * Network: Holesky
     * FeedRegistry: 0x60552f63d8d29a4e6e74032e405a5a834c1f5860
     */
    constructor(address feedRegistry) {
        _feedRegistry = IEOFeedRegistry(feedRegistry);
        owner = msg.sender;
    }

    // Internal function to get the latest price feed for a symbol.
    function getPrice(uint16 symbol) internal view returns (IEOFeedRegistry.PriceFeed memory) {
        return _feedRegistry.getLatestPriceFeed(symbol);
    }

    // Save the latest price data for a given symbol.
    function saveData(uint16 symbol) external {
        IEOFeedRegistry.PriceFeed memory data = getPrice(symbol);
        priceData[symbol].push(Price({
            symbol: symbol, 
            timestamp: data.timestamp, 
            value: data.value
        }));
    }

    // Return the price value for a given symbol and index.
    function getData(uint16 symbol, uint16 index) external view returns (uint256) {
        require(index < priceData[symbol].length, "Index out of range");
        return priceData[symbol][index].value;
    }

    // Set a new feed registry address (restricted to the owner).
    function setFeedRegistry(address newFeedRegistry) external onlyOwner {
        _feedRegistry = IEOFeedRegistry(newFeedRegistry);
    }

    // Get the current size of the array for a given symbol.
    function getIndex(uint16 symbol) external view returns (uint256) {
        return priceData[symbol].length;
    }

    // Get the last index for a given symbol.
    function getLastIndexForSymbol(uint16 symbol) external view returns (int256) {
        int256 size = int256(priceData[symbol].length);
        return size - 1;
    }

    // Get data collected within a specific time range for a given symbol.
    function getDataByTimeRange(uint16 symbol, uint256 startTime, uint256 endTime) external view returns (Price[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < priceData[symbol].length; i++) {
            if (priceData[symbol][i].timestamp >= startTime && priceData[symbol][i].timestamp <= endTime) {
                count++;
            }
        }

        Price[] memory results = new Price[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < priceData[symbol].length; i++) {
            if (priceData[symbol][i].timestamp >= startTime && priceData[symbol][i].timestamp <= endTime) {
                results[index] = priceData[symbol][i];
                index++;
            }
        }

        return results;
    }
}
