pragma solidity ^0.6.7;

import "zeppelin-solidity/proxy/Initializable.sol";
import "zeppelin-solidity/introspection/ERC165.sol";
import "zeppelin-solidity/utils/EnumerableSet.sol";
import "ds-auth/auth.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/ITokenUse.sol";

contract PveTeam is Initializable, ERC165, DSAuth {
    using EnumerableSet for EnumerableSet.UintSet;
    
    event Join(address user, uint256 teamId, uint256 tokenId);
    event Exit(address user, uint256 teamId, uint256 tokenId);

    bytes4 internal constant InterfaceId_IActivity = 0x6086e7f8; 

    // 0x434f4e54524143545f544f4b454e5f5553450000000000000000000000000000
    bytes32 public constant CONTRACT_TOKEN_USE = "CONTRACT_TOKEN_USE";

    uint256 public constant TEAM_ID = 1; 

    uint256 public constant MAX_TEAM_SIZE = 4;
    

    ISettingsRegistry public registry;

    // owner => (teamId => set of team member)
    mapping (address => mapping(uint256 => EnumerableSet.UintSet)) private teams;

    function initialize(address _registry) public initializer {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
        registry = ISettingsRegistry(_registry);

        _registerInterface(InterfaceId_IActivity);
    }

    function joins(uint256[] calldata tokenIds) external {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            join(tokenIds[i]);
        }
    }

    function join(uint256 tokenId) public {
        address tokenuse = registry.addressOf(CONTRACT_TOKEN_USE);
        ITokenUse(tokenuse).addActivity(tokenId, msg.sender, 0);
        teams[msg.sender][TEAM_ID].add(tokenId);
        require(teams[msg.sender][TEAM_ID].length() <= MAX_TEAM_SIZE, "Team: FULL_TEAM");
        emit Join(msg.sender, TEAM_ID, tokenId);
    }

    function exits(uint256[] calldata tokenIds) external {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            exit(tokenIds[i]);
        }
    }

    function _exit(uint256 tokenId) internal {
        teams[msg.sender][TEAM_ID].remove(tokenId);
        emit Exit(msg.sender, TEAM_ID, tokenId);
    }

    function exit(uint256 tokenId) public {
        _exit(tokenId);
        address tokenuse = registry.addressOf(CONTRACT_TOKEN_USE);
        ITokenUse(tokenuse).removeActivity(tokenId, msg.sender);
    }

    function swap(uint256 oldTokenId, uint256 newTokenId) public {
        exit(oldTokenId);
        join(newTokenId);
    }

    function evict(uint256 tokenId) public {
        _exit(tokenId);
        address tokenuse = registry.addressOf(CONTRACT_TOKEN_USE);
        ITokenUse(tokenuse).removeTokenUseAndActivity(tokenId);
    }

    function activityStopped(uint256 tokenId) public auth {
    }

    function length(address owner) public view returns (uint256) {
        require(owner != address(0), "Tram: ZERO_ADDRESS");
        return teams[owner][TEAM_ID].length();
    }

    function at(address owner, uint256 index) public view returns (uint256) {
        return teams[owner][TEAM_ID].at(index);
    }

    function exist(address owner, uint256 tokenId) public view returns (bool) {
        return teams[owner][TEAM_ID].contains(tokenId);
    }
}
