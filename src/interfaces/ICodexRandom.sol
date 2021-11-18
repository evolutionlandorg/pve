pragma solidity ^0.6.7;

interface ICodexRandom {
    function d100(uint _s) external view returns (uint);
}
