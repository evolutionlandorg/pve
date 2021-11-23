pragma solidity ^0.6.7;

interface IMetaDataTeller {
    //0x7999a5cf
	function getPrefer(bytes32 _minor, address _token) external view returns (uint256);
}
