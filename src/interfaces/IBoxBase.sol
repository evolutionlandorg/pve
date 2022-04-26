pragma solidity ^0.6.7;

interface IBoxBase {
    enum Box {
        NaN,
        Gold,
        Silver
    }
	function createBox(Box typ, address to, address token, uint256 price) external returns (uint256);
}
