pragma solidity ^0.6.7;

interface ITokenUse {
    function addActivity(uint256 _tokenId, address _user, uint256 _endTime) external;
    function removeActivity(uint256 _tokenId, address _user) external;
    function removeTokenUseAndActivity(uint256 _tokenId) external;
}
