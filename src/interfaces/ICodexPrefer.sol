pragma solidity ^0.6.7;

interface ICodexPrefer {
    function getPrefer(bytes32 minor, address token) external view returns (uint256);
    function getElement(bytes32 minor, uint256 prefer) external view returns (address);
}
