pragma solidity ^0.6.7;

import "zeppelin-solidity/proxy/Initializable.sol";
import "zeppelin-solidity/introspection/ERC165.sol";
import "ds-auth/auth.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/ITokenUse.sol";

contract PveEntry is Initializable, ERC165, DSAuth {
    event Join(uint256 tokenId);
    event Exit(uint256 tokenId);

    bytes4 internal constant InterfaceId_IActivity = 0x6086e7f8; 

    // 0x434f4e54524143545f544f4b454e5f5553450000000000000000000000000000
    bytes32 public constant CONTRACT_TOKEN_USE = "CONTRACT_TOKEN_USE";

    ISettingsRegistry public registry;

    function initialize(address _registry) public initializer {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
        registry = ISettingsRegistry(_registry);

        _registerInterface(InterfaceId_IActivity);
    }

    function joins(uint256[] calldata _tokenIds) external {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            join(_tokenIds[i]);
        }
    }

    function exits(uint256[] calldata _tokenIds) external {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            exit(_tokenIds[i]);
        }
    }

    function join(uint256 _tokenId) public {
        address tokenuse = registry.addressOf(CONTRACT_TOKEN_USE);
        ITokenUse(tokenuse).addActivity(_tokenId, msg.sender, 0);
        emit Join(_tokenId);
    }

    function exit(uint256 _tokenId) public {
        address tokenuse = registry.addressOf(CONTRACT_TOKEN_USE);
        emit Exit(_tokenId);
        ITokenUse(tokenuse).removeActivity(_tokenId, msg.sender);
    }

    function evict(uint256 _tokenId) public {
        address tokenuse = registry.addressOf(CONTRACT_TOKEN_USE);
        emit Exit(_tokenId);
        ITokenUse(tokenuse).removeTokenUseAndActivity(_tokenId);
    }

    function activityStopped(uint256 _tokenId) public auth {
    }
}
