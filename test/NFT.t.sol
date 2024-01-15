// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/NFT.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";


contract NFTContract is Test {
    using stdStorage for StdStorage;

    NFT private nft;

    function setUp() public {
        // _disableInitializers();
        nft = new NFT("Token Tmey", "TT", "http://testopts.org", address(this));
        // console.log(address(1));
        // console.log(address(this));
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
        uint256 ownerTokenSlot = stdstore.target(address(nft)).sig(nft.balanceOf.selector).with_key(address(5)).find();
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

    function test_SafeContractReceiver() public {
        Receiver receiver = new Receiver();
        nft.mintNFT{value: 0.08 ether}(address(receiver));
        uint256 balanceReceiverSlot = stdstore
            .target(address(nft))
            .sig(nft.balanceOf.selector)
            .with_key(address(address(receiver)))
            .find();
        uint256 balanceReceiver = uint256(vm.load(address(nft), bytes32(balanceReceiverSlot)));
        assertEq(balanceReceiver, 1);
    }

    function test_RevertUnSafeConractReceiver() public {
        vm.etch(address(123), bytes("mock up contract"));
        vm.expectRevert(bytes(""));
        nft.mintNFT{value: 0.08 ether}(address(address(123)));
    }

    function test_WithDrawalSuccessAsOwner() public {
    // Mint an NFT, sending eth to the contract
        Receiver receiver = new Receiver();
        address payable payee = payable(address(7));
        uint256 priorPayeeBalance = payee.balance;
        nft.mintNFT{value: nft.MINT_PRICE()}(address(receiver));
        // Check that the balance of the contract is correct
        assertEq(address(nft).balance, nft.MINT_PRICE());
        uint256 nftBalance = address(nft).balance;
        // Withdraw the balance and assert it was transferred
        // console.log("owner of contract: ", );
        nft.withDrawPayment(payee);
        assertEq(payee.balance, priorPayeeBalance + nftBalance);
    }
}

contract Receiver is IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 id, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }
}
