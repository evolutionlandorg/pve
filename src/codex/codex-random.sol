pragma solidity ^0.6.7;

contract codex {
    string constant public index = "Base";
    string constant public class = "Random";

    function d100(uint _s) external view returns (uint) {
        return dn(_s, 100);
    }

    function dn(uint _s, uint _number) public view returns (uint) {
        return _seed(_s) % _number;
    }

    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function _seed(uint _s) internal view returns (uint rand) {
        rand = _random(
            string(
                abi.encodePacked(
                    block.timestamp,
                    blockhash(block.number - 1),
                    _s,
                    msg.sender
                )
            )
        );
    }
}
