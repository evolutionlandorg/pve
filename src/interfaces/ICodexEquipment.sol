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

    function obj_by_id(uint id) external pure returns (equipment memory _e);
}
