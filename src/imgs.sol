// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract imgs {
  error InvalidTokenId();
  error IndexOutOfBounds();
  error ZeroAddress();
  error InvalidPostId();
  error InsufficientPayment();
  error TransferFailed();
  error ReentrantCall();
  
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
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
  uint256 public postCount;

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
    if (_tokenId >= totalSupply) revert InvalidTokenId();
    return tokenIdToUrl[_tokenId];
  }
  function tokenByIndex(uint256 _index) external view returns (uint256) {
    if (_index >= totalSupply) revert IndexOutOfBounds();
    return _index;
  }
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
    if (_owner == address(0)) revert ZeroAddress();
    if (_index >= tokenIdsByOwner[_owner].length) revert IndexOutOfBounds();
    return tokenIdsByOwner[_owner][_index];
  }
  function post(string memory url, uint256 price) external returns (uint256) {
    uint256 postId = postCount;
    posts.push(Post({
      creator: msg.sender,
      url: url,
      price: price
    }));
    postCount++;
    return postId;
  }
  function mint(uint256 postId) external payable returns (uint256) {
    if (locked) revert ReentrantCall();
    locked = true;
    if (postId >= posts.length) revert InvalidPostId();
    Post memory _post = posts[postId];
    if (msg.value < _post.price) revert InsufficientPayment();
    
    uint256 tokenId = totalSupply;
    totalSupply++;
    
    ownerOf[tokenId] = msg.sender;
    tokenIdsByOwner[msg.sender].push(tokenId);
    tokenIdToUrl[tokenId] = _post.url;
    
    emit Transfer(address(0), msg.sender, tokenId);
    
    if (_post.price > 0) {
      (bool success, ) = payable(_post.creator).call{value: _post.price}("");
      if (!success) revert TransferFailed();
    }
    
    locked = false;
    return tokenId;
  }
  
  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return
      interfaceId == 0x01ffc9a7 || // ERC165
      interfaceId == 0x80ac58cd || // ERC721
      interfaceId == 0x5b5e139f || // ERC721Metadata
      interfaceId == 0x780e9d63;   // ERC721Enumerable
  }
}
