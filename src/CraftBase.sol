pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "zeppelin-solidity/proxy/Initializable.sol";
import "zeppelin-solidity/token/ERC1155/IERC1155.sol";
import "zeppelin-solidity/token/ERC1155/IERC1155Receiver.sol";
import "ds-auth/auth.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/IObjectOwnership.sol";
import "./interfaces/ICodexEquipment.sol";
import "./interfaces/ICodexRandom.sol";
import "./interfaces/IMaterial.sol";
import "./interfaces/ILandBase.sol";

contract CraftBase is Initializable, DSAuth {
	event Crafted(address to, uint256 tokenId, uint256 obj_id, uint256 grade, uint256 timestamp);

    bytes32 private constant CONTRACT_MATERIAL = "CONTRACT_MATERIAL";
	bytes32 private constant CONTRACT_LAND_BASE = "CONTRACT_LAND_BASE";
	bytes32 private constant CONTRACT_SWORD_CODEX = "CONTRACT_SWORD_CODEX";
	bytes32 private constant CONTRACT_SHIELD_CODEX = "CONTRACT_SHIELD_CODEX";
	bytes32 private constant CONTRACT_RANDOM_CODEX = "CONTRACT_RANDOM_CODEX";
	bytes32 private constant CONTRACT_OBJECT_OWNERSHIP = "CONTRACT_OBJECT_OWNERSHIP";
	bytes4 private constant _SELECTOR_TRANSFERFROM = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    struct Attr {
        uint256 prefer;
    }

	/*** STORAGE ***/
	ISettingsRegistry public registry;
    uint256 public lastEquipmentId;
    mapping(uint256 => Attr) public attrs;

	function initialize(address _registry) public initializer {
		owner = msg.sender;
		emit LogSetOwner(msg.sender);

		registry = ISettingsRegistry(_registry);
	}

	function _safeTransferFrom(address token, address from, address to, uint256 value) private {
		(bool success, bytes memory data) =
			token.call(abi.encodeWithSelector(_SELECTOR_TRANSFERFROM, from, to, value)); // solhint-disable-line
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"Furnace: TRANSFERFROM_FAILED"
		);
	}

    function _pay_materails(uint256[] memory materials, uint256[] memory mcosts) private {
        address m = registry.addressOf(CONTRACT_MATERIAL);
        uint256[] memory ids = new uint256[](materials.length);
        for (uint256 i = 0; i < materials.length; ++i) {
            ids[i] = IMaterial(m).encode(uint128(materials[i]));
        }
        IERC1155(m).safeBatchTransferFrom(msg.sender, address(this), ids, mcosts, "");
    }

    function _craft_check(uint _srate) private view returns (bool) {
        address random = registry.addressOf(CONTRACT_LAND_BASE);
        return ICodexRandom(random).d100(lastEquipmentId) < _srate;
    }

    function _pay_element(address element, uint256 value) private returns (uint prefer) {
        uint256 ele = ILandBase(registry.addressOf(CONTRACT_LAND_BASE)).resourceToken2RateAttrId(element);
		require(ele > 0 && ele < 6, "!element");
		prefer |= 1 << ele;
		_safeTransferFrom(element, msg.sender, address(this), value);
    }

    function _craft_obj(address _to, uint _obj_id, uint _grade, uint _prefer) private  returns (uint) {
        require(lastEquipmentId < uint112(-1), "overflow");
        lastEquipmentId += 1;
		uint256 objectId = _obj_id << 120 + _grade << 112 + lastEquipmentId;
        // [6.1.1, 6.1.3] sword
        // [6.2.1, 6.2.3] shield
		uint256 tokenId = IObjectOwnership(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).mintObject(_to, uint128(objectId));
        attrs[tokenId] = Attr(_prefer);
		emit Crafted(_to, tokenId, _obj_id, _grade, block.timestamp);
		return tokenId;
    }

    function craft(uint8 _obj_id, uint8 _grade, address _element) external returns (bool crafted, uint tokenId) {
        require(isValid(_obj_id, _grade), "!valid");
        ICodexEquipment.equipment memory e = get_obj(_obj_id, _grade);
        _pay_materails(e.materials, e.mcosts);
        uint prefer = _pay_element(_element, e.ecost);
        crafted = _craft_check(e.srate);
        if (crafted) {
            tokenId = _craft_obj(msg.sender, _obj_id, _grade, prefer);
        }
    }

    function isValid(uint _obj_id, uint _grade) public pure returns (bool) {
        return (1 <= _obj_id && _obj_id <= 2 && _grade >=1 && _grade <=3);
    }

    function get_obj(uint _obj_id, uint _grade) public view returns (ICodexEquipment.equipment memory _e) {
        if (_obj_id == 1) {
            _e = ICodexEquipment(registry.addressOf(CONTRACT_SWORD_CODEX)).obj_by_id(_grade);
        } else if (_obj_id == 2) {
            _e = ICodexEquipment(registry.addressOf(CONTRACT_SHIELD_CODEX)).obj_by_id(_grade);
        }
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}
