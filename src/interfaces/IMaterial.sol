pragma solidity ^0.6.7;

interface IMaterial {
    function mintObjectBatch(address account, uint128[] calldata ids, uint256[] calldata amounts, bytes calldata data) external returns(uint256[] memory);
}
