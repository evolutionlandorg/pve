pragma solidity ^0.6.7;

interface IMaterial {
    function mintObject(address account, uint128 id, uint256 amount, bytes calldata data) external returns(uint256);
}
