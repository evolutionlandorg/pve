pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

contract codex {
    string constant public index = "Equipment";
    string constant public class = "Shield";

    struct shield {
        uint256 id;
        uint256[] materials;
        uint256[] mcosts;
        uint256 ecost;
        uint256 srate;
        string name;
    }

    function obj_by_id(uint rarity) public pure returns (shield memory _s) {
        if (rarity == 1) {
            return shield1();
        } else if (rarity == 2) {
            return shield2();
        } else if (rarity == 3) {
            return shield3();
        }
    }

    function shield1() public pure returns (shield memory _s) {
        _s.id = 1;
        _s.name = "Shield, normal";
        _s.materials = new uint256[](2);
        _s.materials[0] = 1;
        _s.materials[1] = 4;
        _s.mcosts = new uint256[](2);
        _s.mcosts[0] = 100e18;
        _s.mcosts[1] = 30e18;
        _s.ecost = 80e18;
        _s.srate = 90;
    }

    function shield2() public pure returns (shield memory _s) {
        _s.id = 2;
        _s.name = "Shield, rare";
        _s.materials = new uint256[](2);
        _s.materials[0] = 1;
        _s.materials[1] = 4;
        _s.mcosts = new uint256[](2);
        _s.mcosts[0] = 200e18;
        _s.mcosts[1] = 60e18;
        _s.ecost = 160e18;
        _s.srate = 60;
    }

    function shield3() public pure returns (shield memory _s) {
        _s.id = 3;
        _s.name = "Shield, epic";
        _s.materials = new uint256[](2);
        _s.materials[0] = 2;
        _s.materials[1] = 5;
        _s.mcosts = new uint256[](2);
        _s.mcosts[0] = 100e18;
        _s.mcosts[1] = 30e18;
        _s.ecost = 320e18;
        _s.srate = 30;
    }
}
