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
import "./interfaces/ICodexRandom.sol";
import "./interfaces/ICodexPrefer.sol";
import "./interfaces/IRevenuePool.sol";
import "./interfaces/IMaterial.sol";

contract CraftBase is Initializable, DSStop {
    event Crafted(address to, uint256 tokenId, uint256 obj_id, uint256 rarity, uint256 prefer, uint256 timestamp);
    event Enchanced(uint256 id, uint8 class, uint256 timestamp);
    event Disenchanted(uint256 id, uint8 class, uint256 timestamp);

    bytes32 private constant CONTRACT_MATERIAL = "CONTRACT_MATERIAL";
    bytes32 private constant CONTRACT_LAND_BASE = "CONTRACT_LAND_BASE";
    bytes32 private constant CONTRACT_SWORD_CODEX = "CONTRACT_SWORD_CODEX";
    bytes32 private constant CONTRACT_SHIELD_CODEX = "CONTRACT_SHIELD_CODEX";
    bytes32 private constant CONTRACT_RANDOM_CODEX = "CONTRACT_RANDOM_CODEX";
    bytes32 private constant CONTRACT_PREFER_CODEX = "CONTRACT_PREFER_CODEX";
    bytes32 private constant CONTRACT_OBJECT_OWNERSHIP = "CONTRACT_OBJECT_OWNERSHIP";
    bytes32 private constant CONTRACT_RING_ERC20_TOKEN = "CONTRACT_RING_ERC20_TOKEN";
    bytes32 private constant CONTRACT_REVENUE_POOL = "CONTRACT_REVENUE_POOL";
    bytes32 private constant CONTRACT_METADATA_TELLER = "CONTRACT_METADATA_TELLER";
    bytes32 private constant CONTRACT_ELEMENT_TOKEN = "CONTRACT_ELEMENT_TOKEN";
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

    modifier isHuman() {
        require(msg.sender == tx.origin, "robot is not permitted");
        _;
    }

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

    function _craft_check(uint _srate, uint _offset) private view returns (bool) {
        address random = registry.addressOf(CONTRACT_RANDOM_CODEX);
        return ICodexRandom(random).d100(lastEquipmentId + _offset) < _srate;
    }

    function _pay_element(address element, uint256 value) private returns (uint8 prefer) {
        prefer = uint8(ICodexPrefer(registry.addressOf(CONTRACT_PREFER_CODEX)).getPrefer(CONTRACT_ELEMENT_TOKEN, element));
        require(prefer > 0, "!prefer");
        require(IERC20(element).transferFrom(msg.sender, address(this), value));
    }

    function _craft_obj(address _to, uint8 _obj_id, uint8 _rarity, uint8 _prefer) private returns (uint) {
        require(lastEquipmentId < uint128(-1), "overflow");
        lastEquipmentId += 1;
        uint256 tokenId = IObjectOwnership(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).mintObject(_to, uint128(lastEquipmentId));
        attrs[tokenId] = Attr(_obj_id, _rarity, 0, _prefer);
        emit Crafted(_to, tokenId, _obj_id, _rarity, _prefer, block.timestamp);
        return tokenId;
    }

    function _increase_class(uint id) private {
        attrs[id].class += 1;
        emit Enchanced(id, attrs[id].class, block.timestamp);
    }

    function _decrease_class(uint id) private {
        attrs[id].class -= 1;
        emit Disenchanted(id, attrs[id].class, block.timestamp);
    }

    function craft_batch(uint8[] calldata _obj_ids, uint8[] calldata _raritys, address[] calldata _elements) external {
        require(_obj_ids.length == _raritys.length, "!len");
        require(_obj_ids.length == _elements.length, "!len");
        for(uint i=0; i< _obj_ids.length; i++) {
            _craft(_obj_ids[i], _raritys[i], _elements[i], i);
        }
    }

    // crafting
    function craft(uint8 _obj_id, uint8 _rarity, address _element) public stoppable isHuman returns (bool crafted, uint tokenId) {
        return _craft(_obj_id, _rarity, _element, 0);
    }

    function _craft(uint8 _obj_id, uint8 _rarity, address _element, uint256 offset) private returns (bool crafted, uint tokenId) {
        require(isValid(_obj_id, _rarity), "!valid");
        ICodexEquipment.equipment memory e = get_obj(_obj_id, _rarity);
        _pay_materails(e.materials, e.mcosts);
        uint8 prefer = _pay_element(_element, e.ecost);
        crafted = _craft_check(e.srate, offset);
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
    function enchant(uint id, address _token) external stoppable returns (bool) {
        require(msg.sender == IERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(id), "!owner");
        Attr memory attr = attrs[id];
        require(isValidClass(attr.class), "!valid");
        ICodexEquipment.formula memory fml = get_formula(attr.obj_id, attr.class);
        uint8 prefer = uint8(ICodexPrefer(registry.addressOf(CONTRACT_PREFER_CODEX)).getPrefer(fml.minor, _token));
        require(prefer > 0, "!prefer");
        require(attr.prefer == prefer, "!ele");
        _increase_class(id);
        require(IERC20(_token).transferFrom(msg.sender, address(this), fml.cost));
    }

    function disenchant(uint256 id) external stoppable returns (bool) {
        require(msg.sender == IERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(id), "!owner");
        Attr memory attr = attrs[id];
        require(attr.class > 0, "!class");
        ICodexEquipment.formula memory fml = get_formula(attr.obj_id, attr.class - 1);
        address ele = ICodexPrefer(registry.addressOf(CONTRACT_PREFER_CODEX)).getElement(fml.minor, attr.prefer);
        _decrease_class(id);
        uint256 value = fml.cost * fml.lrate / 100;
        require(IERC20(ele).transfer(msg.sender, value));
    }

    function get_formula(uint _obj_id, uint _class) public view returns (ICodexEquipment.formula memory _f) {
        if (_obj_id == 1) {
            _f = ICodexEquipment(registry.addressOf(CONTRACT_SWORD_CODEX)).formula_by_class(_class);
        } else if (_obj_id == 2) {
            _f = ICodexEquipment(registry.addressOf(CONTRACT_SHIELD_CODEX)).formula_by_class(_class);
        }
    }

    function claimTokens(address _token) public auth {
        if (_token == address(0x0)) {
            payable(owner).transfer(address(this).balance);
            return;
        }
        IERC20 token = IERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
    }
}
