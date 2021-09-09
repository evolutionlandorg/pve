pragma solidity ^0.6.7;

import "ds-auth/auth.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/ITokenUse.sol";

contract Pve is DSAuth {
    event Join(uint256 tokenId);
    event Exit(uint256 tokenId);

    // 0x434f4e54524143545f544f4b454e5f5553450000000000000000000000000000
    bytes32 public constant CONTRACT_TOKEN_USE = "CONTRACT_TOKEN_USE";

    ISettingsRegistry public registry;

    constructor(address _registry) public {
        registry = ISettingsRegistry(_registry);
    }

    function join(uint256 _tokenId) public {
        address tokenuse = registry.addressOf(CONTRACT_TOKEN_USE);
        ITokenUse(tokenuse).addActivity(_tokenId, msg.sender, 0);
        emit Join(_tokenId);
    }

    function exit(uint256 _tokenId) public {
        address tokenuse = registry.addressOf(CONTRACT_TOKEN_USE);
        ITokenUse(tokenuse).removeActivity(_tokenId, msg.sender);
    }

    function evict(uint256 _tokenId) public {
        address tokenuse = registry.addressOf(CONTRACT_TOKEN_USE);
        ITokenUse(tokenuse).removeTokenUseAndActivity(_tokenId);
    }

    function activityStopped(uint256 _tokenId) public auth {
        emit Exit(_tokenId);
    }

    function setRegistry(address _registry) public auth {
        registry = ISettingsRegistry(_registry);
    }
}
