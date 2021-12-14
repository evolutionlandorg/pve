pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

interface ICodexEquipment {
    struct equipment {
        uint256 id;
        uint256[] materials;
        uint256[] mcosts;
        uint256 ecost;
        uint256 srate;
        string name;
    }

    struct formula {
        bytes32 minor;
        uint256 cost;
        uint256 srate;
        uint256 lrate;
    }

    function obj_by_rarity(uint rarity) external pure returns (equipment memory _e);
    function formula_by_class(uint id) external pure returns (formula memory _f);
}
