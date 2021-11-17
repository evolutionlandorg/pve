pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "zeppelin-solidity/proxy/Initializable.sol";
import "zeppelin-solidity/token/ERC1155/IERC1155.sol";
import "zeppelin-solidity/token/ERC1155/IERC1155Receiver.sol";
import "ds-auth/auth.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/codex_equipment.sol";
import "./interfaces/IMaterial.sol";

contract CraftBase is Initializable, DSAuth {

    bytes32 private constant CONTRACT_MATERIAL = "CONTRACT_MATERIAL";
	bytes32 private constant CONTRACT_SWORD_CODEX = "CONTRACT_SWORD_CODEX";
	bytes32 private constant CONTRACT_SHIELD_CODEX = "CONTRACT_SHIELD_CODEX";

	/*** STORAGE ***/
	ISettingsRegistry public registry;
    // mapping(uint16 => uint128) public ids;

	function initialize(address _registry) public initializer {
		owner = msg.sender;
		emit LogSetOwner(msg.sender);

		registry = ISettingsRegistry(_registry);
	}

    function _pay_materails(uint256[] memory materials, uint256[] memory mcosts) internal {
        address m = registry.addressOf(CONTRACT_MATERIAL);
        uint256[] memory ids = new uint256[](materials.length);
        for (uint256 i = 0; i < materials.length; ++i) {
            ids[i] = IMaterial(m).encode(uint128(materials[i]));
        }
        IERC1155(m).safeBatchTransferFrom(msg.sender, address(this), ids, mcosts, "");
    }

    function craft(uint8 _base_type, uint8 _obj_id, uint16 _grade, address element) external returns (bool) {
        require(isValid(_base_type, _obj_id, _grade), "!valid");
        codex_equipment.equipment memory e = get_obj(_base_type, _obj_id, _grade);
        _pay_materails(e.materials, e.mcosts);
    }

    function isValid(uint _base_type, uint _obj_id, uint _grade) public pure returns (bool) {
        // Item
        if (_base_type == 1) {
            return false;
        // Equipment
        } else if (_base_type == 2) {
            return (6 <= _obj_id && _obj_id <= 7 && _grade >=1 && _grade <=3);
        }
        return false;
    }

    function get_type(uint _type_id) public pure returns (string memory _type) {
        if (_type_id == 1) {
            _type = "Item";
        } else if (_type_id == 2) {
            _type = "Equipment";
        }
    }

    function get_obj(uint _base_type, uint _obj_id, uint _grade) public view returns (codex_equipment.equipment memory _e) {
        if (_base_type == 1) {
            revert("!base_type");
        } else if (_base_type == 2) {
            if (_obj_id == 6) {
                _e = codex_equipment(registry.addressOf(CONTRACT_SWORD_CODEX)).obj_by_id(_grade);
            } else if (_obj_id == 7) {
                _e = codex_equipment(registry.addressOf(CONTRACT_SHIELD_CODEX)).obj_by_id(_grade);
            }
        }
        revert("!base_type");
    }

    function onERC1155Received(
        address ,
        address ,
        uint256 ,
        uint256 ,
        bytes calldata
    )
        external
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address ,
        address ,
        uint256[] calldata ,
        uint256[] calldata ,
        bytes calldata
    )
        external
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}
