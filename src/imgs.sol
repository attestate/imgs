// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract imgs {
  error InvalidTokenId();
  error IndexOutOfBounds();
  error ZeroAddress();
  error InvalidPostId();
  error InsufficientPayment();
  error TransferFailed();
  error ReentrantCall();
  struct Post {
    address creator;
    string url;
    uint256 price;
  }
  bool private locked;
  mapping(uint256 => string) public tokenIdToUrl;
  mapping(uint256 => address) public ownerOf;
  mapping(address => uint256[]) public tokenIdsByOwner;
  Post[] public posts;
  uint256 public totalSupply;

  function name() external view returns (string memory _name) {
    return "imgs";
  }
  function symbol() external view returns (string memory _symbol) {
    return "IMGS";
  }
  function balanceOf(address owner) external view returns (uint256) {
    return tokenIdsByOwner[owner].length;
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
  function post(string memory url, uint256 price) external returns (uint256) {
    posts.push(Post({
      creator: msg.sender,
      url: url,
      price: price
    }));
    return posts.length - 1;
  }
  function mint(uint256 postId) external payable returns (uint256) {
    if (locked) throw ReentrantCall();
    locked = true;
    if (postId >= posts.length) throw InvalidPostId();
    Post memory _post = posts[postId];
    if (msg.value < _post.price) throw InsufficientPayment();
    
    uint256 tokenId = totalSupply;
    totalSupply++;
    
    ownerOf[tokenId] = msg.sender;
    tokenIdsByOwner[msg.sender].push(tokenId);
    tokenIdToUrl[tokenId] = _post.url;
    
    if (_post.price > 0) {
      (bool success, ) = payable(_post.creator).call{value: _post.price}("");
      if (!success) throw TransferFailed();
    }
    
    locked = false;
    return tokenId;
  }
}
