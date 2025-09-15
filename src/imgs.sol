// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract imgs {
  error InvalidTokenId();
  error IndexOutOfBounds();
  error ZeroAddress();
  mapping(uint256 => string) public tokenIdToUrl;
  mapping(uint256 => address) public ownerOf;
  mapping(address => uint256) public balanceOf;
  mapping(address => uint256[]) public tokenIdsByOwner;
  uint256 public totalSupply;

  function name() external view returns (string memory _name) {
    return "imgs";
  }
  function symbol() external view returns (string memory _symbol) {
    return "IMGS";
  }
  function tokenURI(uint256 _tokenId) external view returns (string memory) {
    if (_tokenId >= totalSupply) throw InvalidTokenId();
    return tokenIdToUrl[_tokenId];
  }
  function tokenByIndex(uint256 _index) external view returns (uint256) {
    if (_index >= totalSupply) throw IndexOutOfBounds();
    return _index;
  }
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
    if (_owner == address(0)) throw ZeroAddress();
    if (_index >= tokenIdsByOwner[_owner].length) throw IndexOutOfBounds();
    return tokenIdsByOwner[_owner][_index];
  }
}
