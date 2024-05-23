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

contract EoracleDataConsumer {
    IEOFeedRegistry public _feedRegistry;
    address public owner;

    struct Price {
        uint16 symbol;  
        uint256 timestamp;
        uint256 value;  
    }

    Price[] public priceData; 

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    //// address as per documentation 
    constructor() {
        _feedRegistry = IEOFeedRegistry(0xf9047e89bb422CC8fB23b8Bec51a26C9A15bbbfd);
        owner = msg.sender;
    }

    function getPrice(uint16 symbol) internal view returns (IEOFeedRegistry.PriceFeed memory) {
        return _feedRegistry.getLatestPriceFeed(symbol);
    }

    function saveData(uint16 symbol) external {
        IEOFeedRegistry.PriceFeed memory data = getPrice(symbol); 
        priceData.push(Price({
            symbol: symbol, 
            timestamp: data.timestamp, 
            value: data.value
        })); 
    }

    function getData(uint16 symbol, uint16 index) external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < priceData.length; i++) {
            if (priceData[i].symbol == symbol) {
                if (count == index) {
                    return priceData[i].value; 
                }
                count++;
            }
        }
        revert("Index out of range");
    }

    function setFeedRegistry(address newFeedRegistry) external onlyOwner {
        _feedRegistry = IEOFeedRegistry(newFeedRegistry);
    }

    function getLastIndexForSymbol(uint16 symbol) external view returns (uint256) {
        for (uint256 i = priceData.length; i > 0; i--) {
            if (priceData[i - 1].symbol == symbol) {
                return i - 1;
            }
        }
        revert("Symbol not found");
    }
}
