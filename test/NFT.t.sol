// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/NFT.sol";

contract NFTContract is Test {
    using stdStorage for StdStorage;

    NFT private nft;

    function setUp() public {
        nft = new NFT("Token Tmey", "TT", "http://testopts.org", address(1));
    }

    function test_RevertMintWithoutPrice() public {
        vm.expectRevert(MintPriceNotPaid.selector);
        nft.mintNFT(address(2));
    }

    function test_MintPricePaid() public {
        nft.mintNFT{value: 0.08 ether}(address(2));
    }

    function test_RevertMintToZeroAddress() public {
        vm.expectRevert();
        nft.mintNFT{value: 0.08 ether}(address(0));
    }

    function test_RevertMaxSupply() public {
        uint256 tokenIdSlot = stdstore.target(address(nft)).sig("currentTokenId()").find();
        bytes32 loc = bytes32(tokenIdSlot);
        bytes32 mockTokenId = bytes32(abi.encode(10000));
        vm.store(address(nft), loc, mockTokenId);
        vm.expectRevert(MaxSupply.selector);
        nft.mintNFT{value: 0.08 ether}(address(2));
    }

    function test_MintNFTCheckOwner() public {
        nft.mintNFT{value: 0.08 ether}(address(2));
        uint256 newOwnerSlot = stdstore.target(address(nft)).sig(nft.ownerOf.selector).with_key(1).find();
        uint160 ownerOfTokenIdOne = uint160(uint256(vm.load(address(nft), bytes32(abi.encode(newOwnerSlot)))));
        assertEq(address(ownerOfTokenIdOne), address(2));
    }

    function test_BalanceIncrement() public {
        nft.mintNFT{value: 0.08 ether}(address(5));
        uint256 ownerTokenSlot = stdstore
            .target(address(nft))
            .sig(nft.balanceOf.selector)
            .with_key(address(5))
            .find();
        uint256 numTokenFirst = uint256(vm.load(address(nft), bytes32(ownerTokenSlot)));
        assertEq(numTokenFirst, 1);
        // mint another token for address 5
        nft.mintNFT{value: 0.08 ether}(address(5));
        uint256 numTokenSecond = uint256(vm.load(address(nft), bytes32(ownerTokenSlot)));
        assertEq(numTokenSecond, 2);


    }

    function test_RevertTokenURINotOwner() public {
        nft.mintNFT{value: 0.08 ether}(address(2));
        vm.startPrank(address(0xd3ad));
        vm.expectRevert(NonExistentTokenURI.selector);
        nft.tokenURI(1);
        vm.stopPrank();
    }



    // Contract c;

    // function setUp() public {
    //     c = new Contract();
    // }

    // function testBar() public {
    //     assertEq(uint256(1), uint256(1), "ok");
    // }

    // function testFoo(uint256 x) public {
    //     vm.assume(x < type(uint128).max);
    //     assertEq(x + x, x * 2);
    // }
}
