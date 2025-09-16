// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/imgs.sol";

contract ImgsTest is Test {
    imgs public imgsContract;
    
    function setUp() public {
        imgsContract = new imgs();
    }
    
    // Allow this contract to receive ETH
    receive() external payable {}
    
    function testName() public {
        assertEq(imgsContract.name(), "imgs");
    }
    
    function testSymbol() public {
        assertEq(imgsContract.symbol(), "IMGS");
    }
    
    function testTokenURIThrowsForInvalidToken() public {
        vm.expectRevert(imgs.InvalidTokenId.selector);
        imgsContract.tokenURI(0);
        
        vm.expectRevert(imgs.InvalidTokenId.selector);
        imgsContract.tokenURI(1);
    }
    
    function testTokenByIndexThrowsForOutOfBounds() public {
        vm.expectRevert(imgs.IndexOutOfBounds.selector);
        imgsContract.tokenByIndex(0);
        
        vm.expectRevert(imgs.IndexOutOfBounds.selector);
        imgsContract.tokenByIndex(1);
    }
    
    function testTokenOfOwnerByIndexThrowsForZeroAddress() public {
        vm.expectRevert(imgs.ZeroAddress.selector);
        imgsContract.tokenOfOwnerByIndex(address(0), 0);
    }
    
    function testTokenOfOwnerByIndexThrowsForOutOfBounds() public {
        address owner = address(0x1);
        vm.expectRevert(imgs.IndexOutOfBounds.selector);
        imgsContract.tokenOfOwnerByIndex(owner, 0);
        
        vm.expectRevert(imgs.IndexOutOfBounds.selector);
        imgsContract.tokenOfOwnerByIndex(owner, 1);
    }
    
    function testPost() public {
        string memory url = "https://example.com/image.png";
        uint256 price = 1 ether;
        
        uint256 postId = imgsContract.post(url, price);
        assertEq(postId, 0);
        assertEq(imgsContract.postCount(), 1);
        
        (address creator, string memory storedUrl, uint256 storedPrice) = imgsContract.posts(0);
        assertEq(creator, address(this));
        assertEq(storedUrl, url);
        assertEq(storedPrice, price);
        
        // Test posting another one
        string memory url2 = "https://example.com/image2.png";
        uint256 price2 = 0.5 ether;
        
        uint256 postId2 = imgsContract.post(url2, price2);
        assertEq(postId2, 1);
        assertEq(imgsContract.postCount(), 2);
        
        (address creator2, string memory storedUrl2, uint256 storedPrice2) = imgsContract.posts(1);
        assertEq(creator2, address(this));
        assertEq(storedUrl2, url2);
        assertEq(storedPrice2, price2);
    }
    
    function testPostAndMintEnumerable() public {
        // First create a post
        string memory url = "https://example.com/test.png";
        uint256 price = 0.1 ether;
        uint256 postId = imgsContract.post(url, price);
        
        // Mint from the post
        address minter = address(0x123);
        vm.deal(minter, 1 ether);
        vm.prank(minter);
        uint256 tokenId = imgsContract.mint{value: price}(postId);
        assertEq(tokenId, 0);
        
        // Test balanceOf
        assertEq(imgsContract.balanceOf(minter), 1);
        assertEq(imgsContract.balanceOf(address(this)), 0);
        
        // Test tokenURI
        assertEq(imgsContract.tokenURI(0), url);
        
        // Test tokenByIndex
        assertEq(imgsContract.tokenByIndex(0), 0);
        
        // Test tokenOfOwnerByIndex
        assertEq(imgsContract.tokenOfOwnerByIndex(minter, 0), 0);
        
        // Mint another token from same post
        address minter2 = address(0x456);
        vm.deal(minter2, 1 ether);
        vm.prank(minter2);
        uint256 tokenId2 = imgsContract.mint{value: price}(postId);
        assertEq(tokenId2, 1);
        
        // Test updated balances
        assertEq(imgsContract.balanceOf(minter), 1);
        assertEq(imgsContract.balanceOf(minter2), 1);
        
        // Test tokenURI for second token
        assertEq(imgsContract.tokenURI(1), url);
        
        // Test tokenByIndex for second token
        assertEq(imgsContract.tokenByIndex(1), 1);
        
        // Test tokenOfOwnerByIndex for second minter
        assertEq(imgsContract.tokenOfOwnerByIndex(minter2, 0), 1);
        
        // Test totalSupply
        assertEq(imgsContract.totalSupply(), 2);
    }
    
    function testMintFailsWhenTransferFails() public {
        // Deploy a contract that rejects ETH
        RejectingContract rejecter = new RejectingContract();
        
        // Create a post from the rejecting contract
        vm.prank(address(rejecter));
        uint256 postId = imgsContract.post("https://example.com/reject.png", 0.1 ether);
        
        // Try to mint - should fail because transfer to creator fails
        address minter = address(0x789);
        vm.deal(minter, 1 ether);
        vm.prank(minter);
        vm.expectRevert(imgs.TransferFailed.selector);
        imgsContract.mint{value: 0.1 ether}(postId);
        
        // Verify no NFT was minted
        assertEq(imgsContract.totalSupply(), 0);
        assertEq(imgsContract.balanceOf(minter), 0);
        
        // Verify the minter still has their ETH
        assertEq(minter.balance, 1 ether);
    }
    
    function testFreeMint() public {
        // Create a free post
        uint256 postId = imgsContract.post("https://example.com/free.png", 0);
        
        // Mint for free
        address minter = address(0xABC);
        vm.prank(minter);
        uint256 tokenId = imgsContract.mint{value: 0}(postId);
        
        assertEq(tokenId, 0);
        assertEq(imgsContract.ownerOf(0), minter);
        assertEq(imgsContract.balanceOf(minter), 1);
    }
    
    function testMintWithInsufficientPayment() public {
        uint256 postId = imgsContract.post("https://example.com/expensive.png", 1 ether);
        
        address minter = address(0xDEF);
        vm.deal(minter, 0.5 ether);
        vm.prank(minter);
        vm.expectRevert(imgs.InsufficientPayment.selector);
        imgsContract.mint{value: 0.5 ether}(postId);
        
        // Verify nothing was minted
        assertEq(imgsContract.totalSupply(), 0);
    }
    
    function testMintInvalidPostId() public {
        address minter = address(0x111);
        vm.deal(minter, 1 ether);
        vm.prank(minter);
        vm.expectRevert(imgs.InvalidPostId.selector);
        imgsContract.mint{value: 1 ether}(999); // Non-existent post
        
        assertEq(imgsContract.totalSupply(), 0);
    }
    
    function testMultipleMintsBySameAddress() public {
        uint256 postId = imgsContract.post("https://example.com/multi.png", 0.1 ether);
        
        address minter = address(0x222);
        vm.deal(minter, 1 ether);
        
        // Mint first token
        vm.prank(minter);
        uint256 token1 = imgsContract.mint{value: 0.1 ether}(postId);
        
        // Mint second token
        vm.prank(minter);
        uint256 token2 = imgsContract.mint{value: 0.1 ether}(postId);
        
        assertEq(token1, 0);
        assertEq(token2, 1);
        assertEq(imgsContract.balanceOf(minter), 2);
        assertEq(imgsContract.tokenOfOwnerByIndex(minter, 0), 0);
        assertEq(imgsContract.tokenOfOwnerByIndex(minter, 1), 1);
    }
    
    function testReentrancyProtection() public {
        ReentrantMinter attacker = new ReentrantMinter(imgsContract);
        
        // Create a post from the attacker contract
        uint256 postId = attacker.createPost();
        attacker.setAttackPostId(postId);
        
        // Fund the attacker and try reentrancy attack
        vm.deal(address(attacker), 1 ether);
        
        // The entire transaction should fail because the receive function 
        // tries to reenter, causing the transfer to fail
        vm.expectRevert(imgs.TransferFailed.selector);
        attacker.attack();
        
        // No tokens should have been minted
        assertEq(imgsContract.totalSupply(), 0);
    }
}

// Contract that rejects ETH transfers
contract RejectingContract {
    // No receive or fallback function, so it will reject ETH
}

// Contract that attempts reentrancy attack
contract ReentrantMinter {
    imgs public target;
    uint256 public attackPostId;
    bool attacking;
    
    constructor(imgs _target) {
        target = _target;
    }
    
    // Create a post that will pay back to this contract
    function createPost() external returns (uint256) {
        return target.post("https://example.com/reentrant.png", 0.1 ether);
    }
    
    function attack() external payable {
        // Mint from our own post so we receive the payment
        attacking = true;
        target.mint{value: 0.1 ether}(attackPostId);
    }
    
    function setAttackPostId(uint256 _postId) external {
        attackPostId = _postId;
    }
    
    receive() external payable {
        if (attacking) {
            attacking = false;
            // Try to reenter mint during the payment callback
            target.mint{value: 0.1 ether}(attackPostId);
        }
    }
}
