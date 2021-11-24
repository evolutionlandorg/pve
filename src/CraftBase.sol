pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "zeppelin-solidity/proxy/Initializable.sol";
import "zeppelin-solidity/token/ERC1155/IERC1155.sol";
import "zeppelin-solidity/token/ERC721/IERC721.sol";
import "zeppelin-solidity/token/ERC20/IERC20.sol";
import "ds-stop/stop.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/IObjectOwnership.sol";
import "./interfaces/ICodexEquipment.sol";
import "./interfaces/IMetaDataTeller.sol";
import "./interfaces/ICodexRandom.sol";
import "./interfaces/IRevenuePool.sol";
import "./interfaces/IMaterial.sol";
import "./interfaces/ILandBase.sol";

contract CraftBase is Initializable, DSStop {
	event Crafted(address to, uint256 tokenId, uint256 obj_id, uint256 rarity, uint256 timestamp);
    event Enchanced(uint256 id, uint8 class, uint256 timestamp);

    bytes32 private constant CONTRACT_MATERIAL = "CONTRACT_MATERIAL";
	bytes32 private constant CONTRACT_LAND_BASE = "CONTRACT_LAND_BASE";
	bytes32 private constant CONTRACT_SWORD_CODEX = "CONTRACT_SWORD_CODEX";
	bytes32 private constant CONTRACT_SHIELD_CODEX = "CONTRACT_SHIELD_CODEX";
	bytes32 private constant CONTRACT_RANDOM_CODEX = "CONTRACT_RANDOM_CODEX";
	bytes32 private constant CONTRACT_OBJECT_OWNERSHIP = "CONTRACT_OBJECT_OWNERSHIP";
	bytes32 private constant CONTRACT_RING_ERC20_TOKEN = "CONTRACT_RING_ERC20_TOKEN";
    bytes32 private constant CONTRACT_REVENUE_POOL = "CONTRACT_REVENUE_POOL";
	bytes32 private constant CONTRACT_METADATA_TELLER = "CONTRACT_METADATA_TELLER";
	bytes4 private constant _SELECTOR_TRANSFERFROM = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    struct Attr {
        uint8 obj_id;
        uint8 rarity;
        uint8 class;
        uint8 prefer;
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

    function _pay_materails(uint256[] memory materials, uint256[] memory mcosts) private {
        address m = registry.addressOf(CONTRACT_MATERIAL);
        uint256[] memory ids = new uint256[](materials.length);
        for (uint256 i = 0; i < materials.length; ++i) {
            ids[i] = IMaterial(m).encode(uint128(materials[i]));
        }
        IERC1155(m).safeBatchTransferFrom(msg.sender, address(this), ids, mcosts, "");
    }

    function _craft_check(uint _srate) private view returns (bool) {
        address random = registry.addressOf(CONTRACT_RANDOM_CODEX);
        return ICodexRandom(random).d100(lastEquipmentId) < _srate;
    }

    function _pay_element(address element, uint256 value) private returns (uint8 prefer) {
        uint256 ele = ILandBase(registry.addressOf(CONTRACT_LAND_BASE)).resourceToken2RateAttrId(element);
		require(ele > 0 && ele < 6, "!element");
		prefer = uint8(1 << ele);
        require(IERC20(element).transferFrom(msg.sender, address(this), value));
    }

    function _craft_obj(address _to, uint8 _obj_id, uint8 _rarity, uint8 _prefer) private returns (uint) {
        require(lastEquipmentId < uint128(-1), "overflow");
        lastEquipmentId += 1;
		uint256 tokenId = IObjectOwnership(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).mintObject(_to, uint128(lastEquipmentId));
        attrs[tokenId] = Attr(_obj_id, _rarity, 0, _prefer);
		emit Crafted(_to, tokenId, _obj_id, _rarity, block.timestamp);
		return tokenId;
    }

    function _increase_class(uint id) private {
        attrs[id].class += 1;
        emit Enchanced(id, attrs[id].class, block.timestamp);
    }

    // crafting
    function craft(uint8 _obj_id, uint8 _rarity, address _element) external stoppable returns (bool crafted, uint tokenId) {
        require(isValid(_obj_id, _rarity), "!valid");
        ICodexEquipment.equipment memory e = get_obj(_obj_id, _rarity);
        _pay_materails(e.materials, e.mcosts);
        uint8 prefer = _pay_element(_element, e.ecost);
        crafted = _craft_check(e.srate);
        if (crafted) {
            tokenId = _craft_obj(msg.sender, _obj_id, _rarity, prefer);
        }
    }

    function isValid(uint _obj_id, uint _rarity) public pure returns (bool) {
        return (1 <= _obj_id && _obj_id <= 2 && _rarity >=1 && _rarity <=3);
    }

    function get_obj(uint _obj_id, uint _rarity) public view returns (ICodexEquipment.equipment memory _e) {
        if (_obj_id == 1) {
            _e = ICodexEquipment(registry.addressOf(CONTRACT_SWORD_CODEX)).obj_by_rarity(_rarity);
        } else if (_obj_id == 2) {
            _e = ICodexEquipment(registry.addressOf(CONTRACT_SHIELD_CODEX)).obj_by_rarity(_rarity);
        }
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function getMetaData(uint id) external view returns (uint, uint, uint, uint) {
        Attr memory attr = attrs[id];
        return (attr.obj_id, attr.rarity, attr.class, attr.prefer);
    }

    function isValidClass(uint class) public pure returns (bool) {
        return (0 <= class && class <=1);
    }

    // enchanting
    function enchant(uint id, address _token) external returns (bool) {
		require(msg.sender == IERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(id), "!owner");
        Attr memory attr = attrs[id];
        require(isValidClass(attr.class), "!valid");
        ICodexEquipment.formula memory fml = get_formula(attr.obj_id, attr.class);
		uint256 element = IMetaDataTeller(registry.addressOf(CONTRACT_METADATA_TELLER)).getPrefer(fml.minor, _token);
		require(element > 0 && element < 6, "!token");
		uint8 prefer = uint8(1 << element);
        require(attr.prefer & prefer > 0, "!ele");
        require(IERC20(_token).transferFrom(msg.sender, address(this), fml.cost));
        _increase_class(id);
    }

    function get_formula(uint _obj_id, uint _class) public view returns (ICodexEquipment.formula memory _f) {
        if (_obj_id == 1) {
            _f = ICodexEquipment(registry.addressOf(CONTRACT_SWORD_CODEX)).formula_by_class(_class);
        } else if (_obj_id == 2) {
            _f = ICodexEquipment(registry.addressOf(CONTRACT_SHIELD_CODEX)).formula_by_class(_class);
        }
    }

    // buy
    function buy(uint8 _obj_id, uint256 _ele) public returns (uint) {
		require(_ele > 0 && _ele < 6, "!ele");
        require(isValid(_obj_id, 1), "!valid");
        uint256 price = get_price();
        address ring = registry.addressOf(CONTRACT_RING_ERC20_TOKEN);
        require(IERC20(ring).transferFrom(msg.sender, address(this), price));
        address pool = registry.addressOf(CONTRACT_REVENUE_POOL);
        IERC20(ring).approve(pool, price);
        IRevenuePool(pool).reward(ring, price, msg.sender);
		uint8 prefer = uint8(1 << _ele);
        return _craft_obj(msg.sender, _obj_id, 1, prefer);
    }

    function get_price() public pure returns (uint) {
        return 1000e18;
    }
}
