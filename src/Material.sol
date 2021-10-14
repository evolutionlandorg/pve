pragma solidity ^0.6.7;

import "zeppelin-solidity/token/ERC1155/ERC1155.sol";
import "zeppelin-solidity/proxy/Initializable.sol";
import "zeppelin-solidity/utils/Pausable.sol";
import "ds-auth/auth.sol";
import "./ERC1155Supply.sol";
import "./interfaces/IInterstellarEncoder.sol";
import "./interfaces/ISettingsRegistry.sol";

contract Material is Initializable, DSAuth, Pausable, ERC1155(""), ERC1155Supply {

    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;
    // 0x434f4e54524143545f494e5445525354454c4c41525f454e434f444552000000
    bytes32 internal constant CONTRACT_INTERSTELLAR_ENCODER = "CONTRACT_INTERSTELLAR_ENCODER";

    ISettingsRegistry public registry;

    function initialize(address _registry) public initializer {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
        registry = ISettingsRegistry(_registry);

        _registerInterface(_INTERFACE_ID_ERC1155);
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    function setURI(string memory newuri) public auth {
        _setURI(newuri);
    }

    function pause() public auth {
        _pause();
    }

    function unpause() public auth {
        _unpause();
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        ERC1155Supply._mint(account, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        ERC1155Supply._mintBatch(to, ids, amounts, data);
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override(ERC1155, ERC1155Supply) {
        ERC1155Supply._burn(account, id, amount);
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override(ERC1155, ERC1155Supply) {
        ERC1155Supply._burnBatch(account, ids, amounts);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        auth
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        auth
    {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(address account, uint256 id, uint256 value)
        public
        auth
    {
        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values)
        public
        auth
    {
        _burnBatch(account, ids, values);
    }

    function mintObject(address account, uint128 id, uint256 amount, bytes memory data)
        public
        auth
        returns (uint256 tokenId)
    {
        address interstellarEncoder = registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER);

        tokenId = IInterstellarEncoder(interstellarEncoder).encodeTokenIdForObjectContract(address(this), msg.sender, id);
        _mint(account, tokenId, amount, data);
    }

    function burnObject(address account, uint128 id, uint256 value)
        public
        auth
        returns (uint256 tokenId)
    {
        address interstellarEncoder = registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER);

        tokenId = IInterstellarEncoder(interstellarEncoder).encodeTokenIdForObjectContract(address(this), msg.sender, id);
        _burn(account, tokenId, value);
    }

    function mintObjectBatch(address account, uint128[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        auth
        returns (uint256[] memory tokenIds)
    {
        address interstellarEncoder = registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER);

        tokenIds = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            tokenIds[i] = IInterstellarEncoder(interstellarEncoder).encodeTokenIdForObjectContract(address(this), msg.sender, ids[i]);
        }
        _mintBatch(account, tokenIds, amounts, data);
    }

    function burnObjectBatch(address account, uint128[] memory ids, uint256[] memory values)
        public
        auth
        returns (uint256[] memory tokenIds)
    {
        address interstellarEncoder = registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER);

        tokenIds = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            tokenIds[i] = IInterstellarEncoder(interstellarEncoder).encodeTokenIdForObjectContract(address(this), msg.sender, ids[i]);
        }
        _burnBatch(account, tokenIds, values);
    }
}
